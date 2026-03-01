/**
 * Aider CLI Coder
 *
 * Uses Aider (https://aider.chat) as an AI pair programmer to apply code changes.
 * Aider is an open-source CLI tool that works with Claude, GPT-4, and local models.
 *
 * Flow:
 *   1. Build instruction prompt from remediation plans
 *   2. Spawn `aider` with --message flag (non-interactive single-turn)
 *   3. Aider reads files, applies changes, creates git commits
 *   4. Parse output for modified files
 *
 * Requirements:
 *   - Aider installed: pip install aider-chat
 *   - An API key configured (ANTHROPIC_API_KEY or OPENAI_API_KEY)
 */

import * as fs from 'fs';
import * as path from 'path';
import { spawn } from 'child_process';
import type {
  Coder,
  CoderConfig,
  CoderRequest,
  CoderResult,
  FileChange,
} from './base';
import { buildRemediationPrompt, FORBIDDEN_FILES } from './base';

export class AiderCoder implements Coder {
  readonly backend = 'aider' as const;
  readonly displayName = 'Aider (AI Pair Programmer)';

  async applyFixes(
    request: CoderRequest,
    config: CoderConfig
  ): Promise<CoderResult> {
    const startTime = Date.now();
    const timeoutMs = config.timeout_ms ?? 300000;
    const maxFiles = config.max_files ?? 10;
    const warnings: string[] = [];

    const allPlans = buildRemediationPrompt(request.remediation_plans);

    // Identify target files from remediation plans
    const targetFiles = this.extractTargetFiles(
      request.remediation_plans,
      request.codebase_path
    );

    const message = `Apply these code remediation plans. Focus on highest-severity findings first. Maximum ${maxFiles} file modifications. Do NOT modify: ${FORBIDDEN_FILES.join(', ')}.

${allPlans}`;

    try {
      const output = await this.runAider(
        message,
        targetFiles,
        request.codebase_path,
        timeoutMs,
        config.model
      );

      // Parse aider output for modified files
      const filesModified = this.parseAiderOutput(output);

      const fileChanges: FileChange[] = filesModified.map((f) => ({
        file_path: f,
        new_content: '',
        change_description: 'Modified by Aider',
      }));

      const changesSummary =
        filesModified.length > 0
          ? `Aider modified ${filesModified.length} files:\n${filesModified.map((f) => `  - ${f}`).join('\n')}`
          : 'Aider ran but no files were modified.';

      return {
        files_modified: filesModified,
        changes_summary: changesSummary,
        file_changes: fileChanges,
        executed: true,
        backend: 'aider',
        duration_ms: Date.now() - startTime,
        warnings,
      };
    } catch (err) {
      return {
        files_modified: [],
        changes_summary: `Aider failed: ${(err as Error).message}`,
        file_changes: [],
        executed: false,
        backend: 'aider',
        duration_ms: Date.now() - startTime,
        warnings: [(err as Error).message],
      };
    }
  }

  async isAvailable(): Promise<boolean> {
    return new Promise((resolve) => {
      const proc = spawn('aider', ['--version'], {
        shell: true,
        timeout: 5000,
      });
      let output = '';
      proc.stdout?.on('data', (d) => {
        output += d.toString();
      });
      proc.on('close', (code) => resolve(code === 0 && output.length > 0));
      proc.on('error', () => resolve(false));
    });
  }

  setupInstructions(): string {
    return [
      'Install Aider: pip install aider-chat',
      'Set ANTHROPIC_API_KEY or OPENAI_API_KEY in your environment',
      'Verify: aider --version',
      'Docs: https://aider.chat',
    ].join('\n');
  }

  /**
   * Run Aider with --message flag for non-interactive mode.
   */
  private runAider(
    message: string,
    targetFiles: string[],
    cwd: string,
    timeoutMs: number,
    model?: string
  ): Promise<string> {
    return new Promise((resolve, reject) => {
      const args = [
        '--yes-always', // Auto-accept all changes
        '--no-auto-commits', // Don't auto-commit (CIL manages git)
        '--no-git', // Don't use git integration (we handle it)
        '--message',
        message,
      ];

      if (model) {
        args.push('--model', model);
      }

      // Add target files so Aider knows which files to edit
      for (const f of targetFiles.slice(0, 20)) {
        // Limit to 20 files
        args.push(f);
      }

      const proc = spawn('aider', args, {
        cwd,
        shell: true,
        timeout: timeoutMs,
        env: { ...process.env },
      });

      let stdout = '';
      let stderr = '';

      proc.stdout?.on('data', (data) => {
        stdout += data.toString();
      });
      proc.stderr?.on('data', (data) => {
        stderr += data.toString();
      });

      proc.on('close', (code) => {
        if (code === 0) {
          resolve(stdout);
        } else {
          reject(
            new Error(`Aider exited with code ${code}: ${stderr || stdout}`)
          );
        }
      });

      proc.on('error', (err) => {
        reject(new Error(`Failed to launch Aider: ${err.message}`));
      });
    });
  }

  /**
   * Extract file paths mentioned in remediation plans.
   */
  private extractTargetFiles(
    plans: Record<string, string>,
    codebasePath: string
  ): string[] {
    const files = new Set<string>();

    for (const plan of Object.values(plans)) {
      // Match file paths in the plan text
      const patterns = [
        /(?:file|path):\s*[`"']?([^\s`"'\n]+\.\w+)[`"']?/gi,
        /[`"']([a-zA-Z0-9_\-./\\]+\.\w{1,10})[`"']/g,
        /(?:src|lib|app|components|pages)\/[^\s`"'\n]+\.\w+/g,
      ];

      for (const pattern of patterns) {
        let match: RegExpExecArray | null;
        while ((match = pattern.exec(plan)) !== null) {
          const filePath = (match[1] || match[0]).trim();
          const absPath = path.resolve(codebasePath, filePath);
          if (fs.existsSync(absPath)) {
            files.add(filePath);
          }
        }
      }
    }

    return Array.from(files);
  }

  /**
   * Parse Aider's output to identify which files were modified.
   */
  private parseAiderOutput(output: string): string[] {
    const files = new Set<string>();

    // Aider outputs lines like "Applied edit to src/foo.ts"
    const patterns = [
      /Applied edit to\s+(.+)/gi,
      /Wrote\s+(.+)/gi,
      /Updated\s+(.+)/gi,
      /Modified\s+(.+)/gi,
    ];

    for (const pattern of patterns) {
      let match: RegExpExecArray | null;
      while ((match = pattern.exec(output)) !== null) {
        const filePath = match[1]!.trim();
        if (filePath.includes('.')) {
          files.add(filePath);
        }
      }
    }

    return Array.from(files);
  }
}
