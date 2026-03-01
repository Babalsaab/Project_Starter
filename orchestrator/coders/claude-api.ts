/**
 * Claude API Coder
 *
 * Uses the Anthropic Claude API (or any configured LLM provider) to generate
 * code modifications. This is the original implementation — extracts the
 * existing behavior from cil-controller.ts into the Coder interface.
 *
 * Flow:
 *   1. Combine remediation plans into a single prompt
 *   2. Call LLM with code-implementation system prompt
 *   3. Parse ===FILE: path=== blocks from response
 *   4. Write modified files to disk
 */

import * as fs from 'fs';
import * as path from 'path';
import type {
  Coder,
  CoderConfig,
  CoderRequest,
  CoderResult,
  FileChange,
} from './base';
import {
  buildRemediationPrompt,
  isSafeToModify,
  parseFileBlocks,
} from './base';
import { getProviderRegistry } from '../providers/index';
import type { LLMProvider } from '../providers/base';
import { generateTemplateRemediations } from './template-remediator';

export class ClaudeAPICoder implements Coder {
  readonly backend = 'claude-api' as const;
  readonly displayName = 'Claude API (Direct)';

  private provider: LLMProvider | null = null;

  async applyFixes(
    request: CoderRequest,
    config: CoderConfig
  ): Promise<CoderResult> {
    const startTime = Date.now();
    const maxFiles = config.max_files ?? 10;
    const warnings: string[] = [];

    const allPlans = buildRemediationPrompt(request.remediation_plans);

    const systemPrompt = `You are a code implementation agent. You receive remediation plans from specialist agents.
Your job is to produce the EXACT file modifications needed.

For each file that needs changes, output a block in this exact format:

===FILE: path/to/file.ts===
\`\`\`typescript
// The complete new content of the file (or the modified section)
\`\`\`
===END FILE===

IMPORTANT:
- Only modify files that need changes based on the remediation plans.
- If a remediation plan is vague, skip it rather than making bad changes.
- Preserve existing functionality — only fix the specific issues identified.
- Focus on the highest-severity findings first.
- Maximum ${maxFiles} file modifications per iteration to avoid breaking changes.`;

    const userPrompt = `## Codebase: ${request.codebase_path}

## Remediation Plans from Specialist Agents:

${allPlans}

Produce the exact file modifications. Use the ===FILE: path=== format.`;

    let implementationOutput = '';
    try {
      const provider = await this.getProvider();
      const result = await provider.complete({
        systemPrompt,
        messages: [{ role: 'user', content: userPrompt }],
        maxTokens: 16384,
      });
      implementationOutput = result.text;

      if (result.is_fallback && result.model_used === 'placeholder') {
        // Fallback to template remediator when API key is not configured
        if (request.findings && request.findings.length > 0) {
          const templateBlocks = generateTemplateRemediations(
            request.findings,
            request.codebase_path
          );
          if (templateBlocks.length > 0) {
            const tFilesModified: string[] = [];
            const tFileChanges: FileChange[] = [];
            for (const block of templateBlocks.slice(0, maxFiles)) {
              const absPath = path.resolve(
                request.codebase_path,
                block.filePath
              );
              if (
                !isSafeToModify(block.filePath, request.codebase_path, absPath)
              ) {
                continue;
              }
              try {
                const dir = path.dirname(absPath);
                if (!fs.existsSync(dir)) {
                  fs.mkdirSync(dir, { recursive: true });
                }
                fs.writeFileSync(absPath, block.content, 'utf-8');
                tFilesModified.push(block.filePath);
                tFileChanges.push({
                  file_path: block.filePath,
                  new_content: block.content,
                  change_description:
                    'Created by template remediator (API fallback)',
                });
              } catch {
                /* skip */
              }
            }
            if (tFilesModified.length > 0) {
              return {
                files_modified: tFilesModified,
                changes_summary: `Template remediator applied ${tFilesModified.length} files (API key not configured):\n${tFilesModified.map((f) => `  - ${f}`).join('\n')}`,
                file_changes: tFileChanges,
                executed: true,
                backend: 'claude-api',
                duration_ms: Date.now() - startTime,
                warnings: [
                  'Used template remediator — API key not configured.',
                ],
              };
            }
          }
        }
        return {
          files_modified: [],
          changes_summary:
            'Placeholder mode — no API key configured. Set ANTHROPIC_API_KEY in .env.local.',
          file_changes: [],
          executed: false,
          backend: 'claude-api',
          duration_ms: Date.now() - startTime,
          warnings: [
            'LLM provider returned placeholder output. Configure ANTHROPIC_API_KEY for real code changes.',
          ],
        };
      }
    } catch (err) {
      return {
        files_modified: [],
        changes_summary: `Implementation failed: ${(err as Error).message}`,
        file_changes: [],
        executed: false,
        backend: 'claude-api',
        duration_ms: Date.now() - startTime,
        warnings: [(err as Error).message],
      };
    }

    // Parse and apply file changes using shared ===FILE:=== parser
    const fileChanges: FileChange[] = [];
    const filesModified: string[] = [];
    const blocks = parseFileBlocks(implementationOutput);

    for (const block of blocks) {
      if (filesModified.length >= maxFiles) {
        warnings.push(
          `Reached max file limit (${maxFiles}). Skipping remaining changes.`
        );
        break;
      }

      const relPath = block.filePath;
      const absFilePath = path.resolve(request.codebase_path, relPath);

      if (!isSafeToModify(relPath, request.codebase_path, absFilePath)) {
        warnings.push(`Skipped unsafe path: ${relPath}`);
        continue;
      }

      try {
        const fileExists = fs.existsSync(absFilePath);
        if (fileExists || config.allow_create) {
          // Ensure parent directory exists for new files
          const dir = path.dirname(absFilePath);
          if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
          }
          fs.writeFileSync(absFilePath, block.content, 'utf-8');
          filesModified.push(relPath);
          fileChanges.push({
            file_path: relPath,
            new_content: block.content,
            change_description: fileExists
              ? 'Modified by Claude API'
              : 'Created by Claude API',
          });
        }
      } catch {
        warnings.push(`Failed to write: ${relPath}`);
      }
    }

    const changesSummary =
      filesModified.length > 0
        ? `Modified ${filesModified.length} files:\n${filesModified.map((f) => `  - ${f}`).join('\n')}`
        : 'No files were modified in this iteration.';

    return {
      files_modified: filesModified,
      changes_summary: changesSummary,
      file_changes: fileChanges,
      executed: true,
      backend: 'claude-api',
      duration_ms: Date.now() - startTime,
      warnings,
    };
  }

  async isAvailable(): Promise<boolean> {
    try {
      const provider = await this.getProvider();
      const health = await provider.healthCheck();
      return health.healthy;
    } catch {
      return false;
    }
  }

  setupInstructions(): string {
    return 'Set ANTHROPIC_API_KEY in .env.local to use Claude API for code generation.';
  }

  private async getProvider(): Promise<LLMProvider> {
    if (this.provider) {
      return this.provider;
    }
    const registry = await getProviderRegistry();
    this.provider = registry.getDefaultProvider();
    return this.provider;
  }
}
