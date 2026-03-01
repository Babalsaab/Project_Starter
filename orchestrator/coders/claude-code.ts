/**
 * Claude Code CLI Coder
 *
 * Applies code changes from remediation plans. Uses two strategies:
 *
 *   1. DIRECT EXTRACTION (primary): Parse ===FILE: path=== blocks from the
 *      remediation plans and write files directly to disk. This is fast,
 *      reliable, and doesn't require an extra LLM call.
 *
 *   2. CLAUDE CODE CLI (fallback): If no ===FILE:=== blocks found, spawn
 *      `claude --print` to interpret the plans and apply changes. This is
 *      slower but handles unstructured remediation text.
 *
 * Requirements:
 *   - Claude Code CLI installed: npm install -g @anthropic-ai/claude-code
 *   - Authenticated: `claude auth login` or running inside VS Code Claude extension
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
import {
  buildRemediationPrompt,
  FORBIDDEN_FILES,
  isSafeToModify,
  parseFileBlocks,
} from './base';
import { generateTemplateRemediations } from './template-remediator';

export class ClaudeCodeCoder implements Coder {
  readonly backend = 'claude-code' as const;
  readonly displayName = 'Claude Code CLI';

  /**
   * Build a clean env for Claude Code CLI child processes.
   * - Strips nesting protection flags (CLAUDECODE, CLAUDE_CODE_ENTRYPOINT)
   * - Strips ANTHROPIC_API_KEY so Claude uses its own OAuth credentials from disk
   *   instead of a potentially invalid/placeholder key from .env.local
   */
  static buildCleanEnv(): Record<string, string | undefined> {
    const childEnv = { ...process.env };
    delete childEnv['CLAUDECODE'];
    delete childEnv['CLAUDE_CODE_ENTRYPOINT'];
    delete childEnv['CLAUDE_CODE_ENTRY_POINT'];
    delete childEnv['ANTHROPIC_API_KEY'];
    return childEnv;
  }

  async applyFixes(
    request: CoderRequest,
    config: CoderConfig
  ): Promise<CoderResult> {
    const startTime = Date.now();
    const timeoutMs = config.timeout_ms ?? 300000;
    const maxFiles = config.max_files ?? 10;
    const allowCreate = config.allow_create ?? true;
    const warnings: string[] = [];

    // ────────────────────────────────────────────────────────────────────────
    // Strategy 1: DIRECT EXTRACTION — parse ===FILE:=== blocks from
    // remediation plans and write them directly to disk (no extra LLM call)
    // ────────────────────────────────────────────────────────────────────────
    const allPlansText = Object.values(request.remediation_plans).join(
      '\n\n---\n\n'
    );
    const fileBlocks = parseFileBlocks(allPlansText);

    if (fileBlocks.length > 0) {
      console.log(
        `[ClaudeCodeCoder] Found ${fileBlocks.length} ===FILE:=== blocks in remediation plans`
      );
      const { filesModified, fileChanges } = this.applyFileBlocks(
        fileBlocks,
        request.codebase_path,
        maxFiles,
        allowCreate,
        warnings
      );

      if (filesModified.length > 0) {
        return {
          files_modified: filesModified,
          changes_summary: `Applied ${filesModified.length} files from remediation plans:\n${filesModified.map((f) => `  - ${f}`).join('\n')}`,
          file_changes: fileChanges,
          executed: true,
          backend: 'claude-code',
          duration_ms: Date.now() - startTime,
          warnings,
        };
      }
    }

    console.log(
      '[ClaudeCodeCoder] No ===FILE:=== blocks found in remediation plans.'
    );

    // ────────────────────────────────────────────────────────────────────────
    // Strategy 2: TEMPLATE REMEDIATOR — deterministic fix generation from
    // evaluation findings. No LLM call needed. Maps finding descriptions
    // to known file templates (test files, configs, .gitignore, etc.)
    // ────────────────────────────────────────────────────────────────────────
    if (request.findings && request.findings.length > 0) {
      console.log(
        `[ClaudeCodeCoder] Running template remediator on ${request.findings.length} findings...`
      );
      const templateBlocks = generateTemplateRemediations(
        request.findings,
        request.codebase_path
      );

      if (templateBlocks.length > 0) {
        console.log(
          `[ClaudeCodeCoder] Template remediator produced ${templateBlocks.length} file blocks`
        );
        const { filesModified, fileChanges } = this.applyFileBlocks(
          templateBlocks,
          request.codebase_path,
          maxFiles,
          allowCreate,
          warnings
        );

        if (filesModified.length > 0) {
          return {
            files_modified: filesModified,
            changes_summary: `Template remediator applied ${filesModified.length} files:\n${filesModified.map((f) => `  - ${f}`).join('\n')}`,
            file_changes: fileChanges,
            executed: true,
            backend: 'claude-code',
            duration_ms: Date.now() - startTime,
            warnings,
          };
        }
      } else {
        console.log(
          '[ClaudeCodeCoder] Template remediator produced 0 blocks (no matching templates).'
        );
      }
    } else {
      console.log(
        '[ClaudeCodeCoder] No findings available for template remediator.'
      );
    }

    console.log('[ClaudeCodeCoder] Falling back to Claude Code CLI.');

    // ────────────────────────────────────────────────────────────────────────
    // Strategy 3: CLAUDE CODE CLI — spawn `claude --print` to interpret the
    // remediation plans and apply changes via tool use
    // ────────────────────────────────────────────────────────────────────────

    // Take git diff snapshot BEFORE running Claude to detect only NEW changes
    const baselineFiles = await this.getGitDiffFiles(request.codebase_path);

    const allPlans = buildRemediationPrompt(request.remediation_plans);
    const prompt = `You are part of a Continuous Improvement Loop (CIL). Specialist agents have analyzed this codebase and produced remediation plans.

Your task: Apply the code fixes described below to the actual files. Focus on the highest-severity findings first. Maximum ${maxFiles} files.

RULES:
- Create new files when the plan requires it (test files, config files, etc.)
- Do NOT modify: ${FORBIDDEN_FILES.join(', ')}
- Preserve existing functionality — only fix the specific issues identified.
- If a remediation is vague or risky, skip it.
- After applying fixes, list every file you modified or created.

## Codebase: ${request.codebase_path}

## Remediation Plans:

${allPlans}

Apply these fixes now. For each file you modify or create, briefly explain what you changed and why.`;

    try {
      const output = await this.runClaudeCode(
        prompt,
        request.codebase_path,
        timeoutMs,
        config.model
      );

      // First try: parse ===FILE:=== blocks from Claude's output
      const outputBlocks = parseFileBlocks(output);
      if (outputBlocks.length > 0) {
        console.log(
          `[ClaudeCodeCoder] Found ${outputBlocks.length} ===FILE:=== blocks in CLI output`
        );
        const { filesModified, fileChanges } = this.applyFileBlocks(
          outputBlocks,
          request.codebase_path,
          maxFiles,
          allowCreate,
          warnings
        );
        if (filesModified.length > 0) {
          return {
            files_modified: filesModified,
            changes_summary: `Claude Code applied ${filesModified.length} files:\n${filesModified.map((f) => `  - ${f}`).join('\n')}`,
            file_changes: fileChanges,
            executed: true,
            backend: 'claude-code',
            duration_ms: Date.now() - startTime,
            warnings,
          };
        }
      }

      // Second try: detect new git changes since baseline
      const currentFiles = await this.getGitDiffFiles(request.codebase_path);
      const baselineSet = new Set(baselineFiles);
      const newChanges = currentFiles.filter((f) => !baselineSet.has(f));

      if (newChanges.length > 0) {
        console.log(
          `[ClaudeCodeCoder] Detected ${newChanges.length} new files via git diff (baseline had ${baselineFiles.length})`
        );
        return {
          files_modified: newChanges,
          changes_summary: `Claude Code modified ${newChanges.length} files:\n${newChanges.map((f) => `  - ${f}`).join('\n')}`,
          file_changes: newChanges.map((f) => ({
            file_path: f,
            new_content: '',
            change_description: 'Modified by Claude Code CLI',
          })),
          executed: true,
          backend: 'claude-code',
          duration_ms: Date.now() - startTime,
          warnings,
        };
      }

      // Third try: parse natural language output for file mentions
      const { filesModified, fileChanges } = this.parseNaturalOutput(
        output,
        request.codebase_path
      );
      const changesSummary =
        filesModified.length > 0
          ? `Claude Code modified ${filesModified.length} files:\n${filesModified.map((f) => `  - ${f}`).join('\n')}`
          : 'Claude Code ran but no files were modified.';

      return {
        files_modified: filesModified,
        changes_summary: changesSummary,
        file_changes: fileChanges,
        executed: true,
        backend: 'claude-code',
        duration_ms: Date.now() - startTime,
        warnings,
      };
    } catch (err) {
      warnings.push(`Claude Code CLI: ${(err as Error).message}`);
      return {
        files_modified: [],
        changes_summary: `Claude Code failed: ${(err as Error).message}`,
        file_changes: [],
        executed: false,
        backend: 'claude-code',
        duration_ms: Date.now() - startTime,
        warnings,
      };
    }
  }

  async isAvailable(): Promise<boolean> {
    const childEnv = ClaudeCodeCoder.buildCleanEnv();
    return new Promise((resolve) => {
      const proc = spawn('claude', ['--version'], {
        shell: true,
        timeout: 5000,
        env: childEnv,
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
      'Install Claude Code CLI: npm install -g @anthropic-ai/claude-code',
      'Authenticate: claude auth login (or run from within VS Code Claude extension)',
      'Verify: claude --version',
    ].join('\n');
  }

  // ─── Private Methods ────────────────────────────────────────────────────────

  /**
   * Apply parsed file blocks to disk.
   */
  private applyFileBlocks(
    blocks: Array<{ filePath: string; content: string }>,
    codebasePath: string,
    maxFiles: number,
    allowCreate: boolean,
    warnings: string[]
  ): { filesModified: string[]; fileChanges: FileChange[] } {
    const filesModified: string[] = [];
    const fileChanges: FileChange[] = [];

    for (const block of blocks) {
      if (filesModified.length >= maxFiles) {
        warnings.push(
          `Reached max file limit (${maxFiles}). Skipping remaining changes.`
        );
        break;
      }

      const relPath = block.filePath;
      const absPath = path.resolve(codebasePath, relPath);

      if (!isSafeToModify(relPath, codebasePath, absPath)) {
        warnings.push(`Skipped unsafe path: ${relPath}`);
        continue;
      }

      const fileExists = fs.existsSync(absPath);
      if (!fileExists && !allowCreate) {
        warnings.push(`Skipped new file (allow_create=false): ${relPath}`);
        continue;
      }

      try {
        // Ensure parent directory exists
        const dir = path.dirname(absPath);
        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir, { recursive: true });
        }

        fs.writeFileSync(absPath, block.content, 'utf-8');
        filesModified.push(relPath);
        fileChanges.push({
          file_path: relPath,
          new_content: block.content,
          change_description: fileExists
            ? 'Modified from remediation plan'
            : 'Created from remediation plan',
        });
        console.log(
          `[ClaudeCodeCoder] ${fileExists ? 'Modified' : 'Created'}: ${relPath}`
        );
      } catch (err) {
        warnings.push(`Failed to write ${relPath}: ${(err as Error).message}`);
      }
    }

    return { filesModified, fileChanges };
  }

  /**
   * Run Claude Code CLI with --print flag for non-interactive execution.
   */
  private runClaudeCode(
    prompt: string,
    cwd: string,
    timeoutMs: number,
    model?: string
  ): Promise<string> {
    const { execSync } =
      require('child_process') as typeof import('child_process');

    return new Promise((resolve, reject) => {
      let settled = false;
      const args = ['--print'];
      if (model) {
        args.push('--model', model);
      }
      const childEnv = ClaudeCodeCoder.buildCleanEnv();

      console.log(
        `[ClaudeCodeCoder] Spawning claude ${args.join(' ')} (prompt: ${prompt.length} chars, timeout: ${timeoutMs / 1000}s)`
      );

      const proc = spawn('claude', args, {
        cwd,
        shell: true,
        env: childEnv,
      });

      let stdout = '';
      let stderr = '';

      proc.stdout?.on('data', (data) => {
        stdout += data.toString();
      });
      proc.stderr?.on('data', (data) => {
        stderr += data.toString();
      });

      proc.stdin?.write(prompt);
      proc.stdin?.end();

      // Manual timeout — Node.js spawn timeout doesn't reliably kill process trees on Windows
      const timer = setTimeout(() => {
        if (settled) {
          return;
        }
        settled = true;
        console.warn(`[ClaudeCodeCoder] Timed out after ${timeoutMs / 1000}s`);
        const partial = stdout.trim() || stderr.trim();
        if (partial.length > 50) {
          resolve(partial);
        } else {
          reject(new Error(`Claude Code timed out after ${timeoutMs / 1000}s`));
        }
        try {
          if (proc.pid) {
            if (process.platform === 'win32') {
              execSync(`taskkill /F /T /PID ${proc.pid}`, { stdio: 'ignore' });
            } else {
              process.kill(-proc.pid, 'SIGTERM');
            }
          }
        } catch {
          /* already exited */
        }
      }, timeoutMs);

      proc.on('close', (code) => {
        clearTimeout(timer);
        if (settled) {
          return;
        }
        settled = true;
        const output = stdout.trim() || stderr.trim();
        if (code === 0 || output.length > 50) {
          console.log(
            `[ClaudeCodeCoder] CLI completed (${output.length} chars, code=${code})`
          );
          resolve(stdout || stderr);
        } else {
          reject(
            new Error(
              `Claude Code exited with code ${code}: ${stderr || stdout || 'no output'}`
            )
          );
        }
      });

      proc.on('error', (err) => {
        clearTimeout(timer);
        if (settled) {
          return;
        }
        settled = true;
        reject(new Error(`Failed to launch Claude Code: ${err.message}`));
      });
    });
  }

  /**
   * Parse Claude Code's natural language output to identify file mentions.
   * Less reliable than ===FILE:=== parsing but covers cases where Claude
   * describes changes in prose.
   */
  private parseNaturalOutput(
    output: string,
    codebasePath: string
  ): { filesModified: string[]; fileChanges: FileChange[] } {
    const filesModified: string[] = [];
    const fileChanges: FileChange[] = [];

    const patterns = [
      /(?:modified|updated|changed|edited|wrote|created|fixed)\s+[`"']?([^\s`"']+\.\w+)[`"']?/gi,
      /(?:file|path):\s*[`"']?([^\s`"']+\.\w+)[`"']?/gi,
      /wrote\s+(?:to\s+)?[`"']?([^\s`"']+\.\w+)[`"']?/gi,
    ];

    const seen = new Set<string>();
    for (const pattern of patterns) {
      let match: RegExpExecArray | null;
      while ((match = pattern.exec(output)) !== null) {
        const filePath = match[1]!.trim();
        const absPath = path.resolve(codebasePath, filePath);
        // File must exist on disk (either pre-existing or just created by Claude)
        if (fs.existsSync(absPath) && !seen.has(filePath)) {
          seen.add(filePath);
          filesModified.push(filePath);
          fileChanges.push({
            file_path: filePath,
            new_content: '',
            change_description: 'Modified by Claude Code CLI',
          });
        }
      }
    }

    return { filesModified, fileChanges };
  }

  /**
   * Get list of modified files from git diff (tracked files only).
   * Used to detect what files changed between two points in time.
   */
  private getGitDiffFiles(cwd: string): Promise<string[]> {
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
        const files = output
          .trim()
          .split('\n')
          .filter((f) => f.length > 0);
        resolve(files);
      });
      proc.on('error', () => resolve([]));
    });
  }
}
