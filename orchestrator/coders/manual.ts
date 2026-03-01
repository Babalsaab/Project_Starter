/**
 * Manual File-Queue Coder
 *
 * Writes detailed remediation instructions to files for human review.
 * The user can apply fixes using ANY tool — Copilot, Claude Code interactive
 * session, Cursor Composer, VS Code, or even manually.
 *
 * Flow:
 *   1. Write instruction files to the CIL artifacts directory
 *   2. Log instructions to console/UI
 *   3. Poll for a "done" signal file
 *   4. Detect changes via git diff
 *
 * This is the universal fallback — works with any editor or AI tool.
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

export class ManualCoder implements Coder {
  readonly backend = 'manual' as const;
  readonly displayName = 'Manual (Any Tool)';

  async applyFixes(
    request: CoderRequest,
    config: CoderConfig
  ): Promise<CoderResult> {
    const startTime = Date.now();
    const timeoutMs = config.timeout_ms ?? 0; // 0 = infinite wait
    const warnings: string[] = [];

    const allPlans = buildRemediationPrompt(request.remediation_plans);

    // Write instruction files
    const artifactDir = path.join(
      process.cwd(),
      'runs',
      'artifacts',
      request.cil_id,
      `iteration-${request.iteration}`
    );
    fs.mkdirSync(artifactDir, { recursive: true });

    // Main instruction file
    const instrPath = path.join(artifactDir, 'APPLY-FIXES.md');
    const donePath = path.join(artifactDir, '.fixes-applied');

    const instructionContent = `# CIL Iteration ${request.iteration} — Apply Fixes

> **Remediation instructions from the Continuous Improvement Loop**
>
> This file contains code fix plans produced by specialist agents.
> Apply these fixes using your preferred tool, then signal completion.

## How to Apply

### Option A: Copy into your AI coder
1. Copy the content below into Claude Code, Cursor Composer, Copilot Chat, or any AI tool
2. Let the AI apply the fixes
3. Create the signal file: \`touch ${path.relative(process.cwd(), donePath)}\`

### Option B: Apply manually
1. Read through each remediation plan below
2. Make the code changes in your editor
3. Create the signal file: \`touch ${path.relative(process.cwd(), donePath)}\`

### Option C: Use the CLI copy-paste prompt
\`\`\`
Paste this into any AI coding assistant:

Apply these code fixes to the codebase at ${request.codebase_path}:
${allPlans.slice(0, 2000)}${allPlans.length > 2000 ? '\n\n[See full file for complete plans]' : ''}
\`\`\`

## Completion Signal

When you're done applying fixes, create this file:
\`\`\`bash
touch ${path.relative(process.cwd(), donePath)}
# OR on Windows:
echo done > ${path.relative(process.cwd(), donePath).replace(/\//g, '\\')}
\`\`\`

The CIL system will detect this file and continue with re-evaluation.

---

## Codebase: ${request.codebase_path}
## Do NOT modify: ${FORBIDDEN_FILES.join(', ')}

---

## Remediation Plans

${allPlans}
`;

    fs.writeFileSync(instrPath, instructionContent, 'utf-8');

    // Also write individual per-agent instruction files
    for (const [agentId, plan] of Object.entries(request.remediation_plans)) {
      const agentInstrPath = path.join(artifactDir, `fix-${agentId}.md`);
      fs.writeFileSync(
        agentInstrPath,
        `# ${agentId} — Remediation Plan\n\n${plan}`,
        'utf-8'
      );
    }

    // Console output
    console.log(`\n  📋 MANUAL MODE — CIL Iteration ${request.iteration}`);
    console.log(`  ─────────────────────────────────────────`);
    console.log(
      `  📄 Instructions: ${path.relative(process.cwd(), instrPath)}`
    );
    console.log(`  ✅ Signal file:  ${path.relative(process.cwd(), donePath)}`);
    console.log(`  ─────────────────────────────────────────`);
    console.log(`  Apply the fixes using your preferred AI tool or editor,`);
    console.log(`  then create the signal file to continue.`);

    // If timeout is 0, don't wait (return immediately for headless/GUI use)
    if (timeoutMs === 0) {
      console.log(`  ⏳ Waiting for fixes (no timeout)...`);
      await this.waitForSignal(donePath, 0);
    } else if (timeoutMs > 0) {
      console.log(`  ⏳ Waiting for fixes (timeout: ${timeoutMs / 1000}s)...`);
      const signaled = await this.waitForSignal(donePath, timeoutMs);
      if (!signaled) {
        warnings.push(
          `Timed out waiting for manual fixes after ${timeoutMs / 1000}s`
        );
        return {
          files_modified: [],
          changes_summary: `Manual mode: instruction file written but timed out waiting for fixes.\nFile: ${instrPath}`,
          file_changes: [],
          executed: false,
          backend: 'manual',
          duration_ms: Date.now() - startTime,
          warnings,
        };
      }
    }

    // Detect changes via git diff
    const filesModified = await this.getGitChanges(request.codebase_path);
    const fileChanges: FileChange[] = filesModified.map((f) => ({
      file_path: f,
      new_content: '',
      change_description: 'Manually applied fix',
    }));

    const changesSummary =
      filesModified.length > 0
        ? `Manual fixes applied — ${filesModified.length} files modified:\n${filesModified.map((f) => `  - ${f}`).join('\n')}`
        : 'Manual mode completed but no file changes detected via git diff.';

    // Clean up signal file
    try {
      fs.unlinkSync(donePath);
    } catch {
      /* ignore */
    }

    return {
      files_modified: filesModified,
      changes_summary: changesSummary,
      file_changes: fileChanges,
      executed: true,
      backend: 'manual',
      duration_ms: Date.now() - startTime,
      warnings,
    };
  }

  async isAvailable(): Promise<boolean> {
    // Manual mode is always available
    return true;
  }

  setupInstructions(): string {
    return 'No setup needed. Manual mode writes instruction files that you apply with any tool.';
  }

  /**
   * Wait for the signal file to appear.
   */
  private waitForSignal(donePath: string, timeoutMs: number): Promise<boolean> {
    return new Promise((resolve) => {
      const startTime = Date.now();
      const interval = setInterval(() => {
        if (fs.existsSync(donePath)) {
          clearInterval(interval);
          resolve(true);
          return;
        }
        if (timeoutMs > 0 && Date.now() - startTime > timeoutMs) {
          clearInterval(interval);
          resolve(false);
          return;
        }
      }, 3000);
    });
  }

  /**
   * Get list of modified files via git.
   */
  private getGitChanges(cwd: string): Promise<string[]> {
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
