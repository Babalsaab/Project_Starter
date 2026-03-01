/**
 * Cursor CLI Coder
 *
 * Uses Cursor's CLI mode to apply code changes. Cursor has an agent mode
 * that can be invoked programmatically.
 *
 * Flow:
 *   1. Build instruction prompt from remediation plans
 *   2. Spawn `cursor` CLI with --cli flag or use the Composer API
 *   3. Cursor's AI applies changes to files
 *   4. Detect modified files via git diff
 *
 * Requirements:
 *   - Cursor editor installed with CLI available on PATH
 *   - OR: Use Cursor's background agent mode
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

export class CursorCoder implements Coder {
  readonly backend = 'cursor' as const;
  readonly displayName = 'Cursor Agent';

  async applyFixes(
    request: CoderRequest,
    config: CoderConfig
  ): Promise<CoderResult> {
    const startTime = Date.now();
    const timeoutMs = config.timeout_ms ?? 300000;
    const maxFiles = config.max_files ?? 10;
    const warnings: string[] = [];

    const allPlans = buildRemediationPrompt(request.remediation_plans);

    const prompt = `Apply the following code remediation plans to this codebase. Focus on highest-severity findings first. Maximum ${maxFiles} file modifications.

RULES:
- Only modify existing files.
- Do NOT modify: ${FORBIDDEN_FILES.join(', ')}
- Preserve existing functionality.
- Skip vague or risky remediations.

## Remediation Plans:

${allPlans}`;

    // Get baseline git state for diff comparison
    const baselineFiles = await this.getGitTrackedChanges(
      request.codebase_path
    );

    try {
      // Try Cursor's background agent mode first (cursor --background)
      const output = await this.runCursor(
        prompt,
        request.codebase_path,
        timeoutMs
      );

      // Detect what files changed by comparing git diff
      const afterFiles = await this.getGitTrackedChanges(request.codebase_path);
      const newlyModified = afterFiles.filter(
        (f) => !baselineFiles.includes(f)
      );

      const fileChanges: FileChange[] = newlyModified.map((f) => ({
        file_path: f,
        new_content: '',
        change_description: 'Modified by Cursor Agent',
      }));

      const changesSummary =
        newlyModified.length > 0
          ? `Cursor modified ${newlyModified.length} files:\n${newlyModified.map((f) => `  - ${f}`).join('\n')}`
          : 'Cursor ran but no files were modified.';

      return {
        files_modified: newlyModified,
        changes_summary: changesSummary,
        file_changes: fileChanges,
        executed: true,
        backend: 'cursor',
        duration_ms: Date.now() - startTime,
        warnings,
      };
    } catch (err) {
      // Fallback: write instruction file for manual Cursor use
      warnings.push(
        `Cursor CLI failed: ${(err as Error).message}. Writing instruction file instead.`
      );

      const instrPath = this.writeInstructionFile(request, allPlans);
      warnings.push(`Instruction file written to: ${instrPath}`);
      warnings.push(
        'Open this file in Cursor and use Composer (Ctrl+I) to apply the fixes.'
      );

      return {
        files_modified: [],
        changes_summary: `Cursor CLI not available. Instruction file written to: ${instrPath}`,
        file_changes: [],
        executed: false,
        backend: 'cursor',
        duration_ms: Date.now() - startTime,
        warnings,
      };
    }
  }

  async isAvailable(): Promise<boolean> {
    return new Promise((resolve) => {
      const proc = spawn('cursor', ['--version'], {
        shell: true,
        timeout: 5000,
      });
      let output = '';
      proc.stdout?.on('data', (d) => {
        output += d.toString();
      });
      proc.on('close', (code) => resolve(code === 0));
      proc.on('error', () => resolve(false));
    });
  }

  setupInstructions(): string {
    return [
      'Install Cursor: https://cursor.com',
      "Ensure 'cursor' CLI is available on PATH (Cursor > Settings > Enable CLI)",
      'Alternatively, Cursor will fall back to writing instruction files you can paste into Composer.',
    ].join('\n');
  }

  /**
   * Run Cursor via its CLI agent mode.
   */
  private runCursor(
    prompt: string,
    cwd: string,
    timeoutMs: number
  ): Promise<string> {
    return new Promise((resolve, reject) => {
      // Cursor's agent mode: cursor agent --message "..."
      // Falls back to: cursor --goto <file> for opening files
      const proc = spawn('cursor', ['agent', '--message', prompt], {
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
            new Error(`Cursor exited with code ${code}: ${stderr || stdout}`)
          );
        }
      });

      proc.on('error', (err) => {
        reject(new Error(`Failed to launch Cursor: ${err.message}`));
      });
    });
  }

  /**
   * Write an instruction file that can be opened in Cursor's Composer.
   */
  private writeInstructionFile(request: CoderRequest, plans: string): string {
    const artifactDir = path.join(
      process.cwd(),
      'runs',
      'artifacts',
      request.cil_id,
      `iteration-${request.iteration}`
    );
    fs.mkdirSync(artifactDir, { recursive: true });

    const instrPath = path.join(artifactDir, 'cursor-instructions.md');
    const content = `# CIL Iteration ${request.iteration} — Cursor Instructions

> **How to use this file:**
> 1. Open this file in Cursor
> 2. Select all content below the "---" line
> 3. Open Composer (Ctrl+I / Cmd+I) and paste
> 4. Let Cursor's AI apply the fixes
> 5. Save and the CIL system will detect changes on next evaluation

**Codebase:** ${request.codebase_path}
**CIL Run:** ${request.cil_id}
**Iteration:** ${request.iteration}

---

## Task: Apply Code Fixes

Apply these remediation plans to the codebase. Focus on highest-severity issues first.

${plans}
`;

    fs.writeFileSync(instrPath, content, 'utf-8');
    return instrPath;
  }

  /**
   * Get list of modified files via git diff.
   */
  private getGitTrackedChanges(cwd: string): Promise<string[]> {
    return new Promise((resolve) => {
      const proc = spawn('git', ['diff', '--name-only'], {
        cwd,
        shell: true,
        timeout: 5000,
      });
      let output = '';
      proc.stdout?.on('data', (d) => {
        output += d.toString();
      });
      proc.on('close', () => {
        resolve(
          output
            .trim()
            .split('\n')
            .filter((f) => f.length > 0)
        );
      });
      proc.on('error', () => resolve([]));
    });
  }
}
