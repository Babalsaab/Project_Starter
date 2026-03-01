/**
 * Coder Abstraction Layer
 *
 * Defines the universal interface for AI coding tools that apply
 * code changes to files. Separate from the LLM provider abstraction
 * (which generates text) — a Coder takes remediation instructions
 * and modifies actual files on disk.
 *
 * Supported backends:
 *   - claude-api:  Use Anthropic API directly (current default)
 *   - claude-code: Invoke Claude Code CLI as subprocess
 *   - cursor:      Invoke Cursor CLI
 *   - aider:       Invoke Aider CLI (open-source AI pair programmer)
 *   - manual:      Write instructions to files for human/any-tool review
 */

// ─── Types ────────────────────────────────────────────────────────────────────

export type CoderBackend =
  | 'claude-api'
  | 'claude-code'
  | 'cursor'
  | 'aider'
  | 'manual';

export interface CoderConfig {
  /** Which coding backend to use */
  backend: CoderBackend;
  /** Timeout per file modification in ms (default: 120000 = 2 min) */
  timeout_ms?: number;
  /** Maximum files to modify per invocation (safety limit) */
  max_files?: number;
  /** Model to use (backend-specific, e.g. "claude-sonnet-4-20250514" for claude-code) */
  model?: string;
  /** Whether to allow creating new files (default: false — only modify existing) */
  allow_create?: boolean;
}

export interface FileChange {
  /** Relative path from codebase root */
  file_path: string;
  /** The new content of the file (or modified section) */
  new_content: string;
  /** What was changed (human-readable summary) */
  change_description: string;
}

export interface CoderResult {
  /** Files that were successfully modified */
  files_modified: string[];
  /** Human-readable summary of all changes */
  changes_summary: string;
  /** Detailed file changes (for artifacts) */
  file_changes: FileChange[];
  /** Whether the coder actually ran (false = placeholder/skipped) */
  executed: boolean;
  /** Backend that was used */
  backend: CoderBackend;
  /** Duration in ms */
  duration_ms: number;
  /** Any warnings or notes */
  warnings: string[];
}

export interface CoderRequest {
  /** Absolute path to the codebase root */
  codebase_path: string;
  /** Remediation plans from specialist agents (agent_id → plan text) */
  remediation_plans: Record<string, string>;
  /** CIL run ID (for artifact tracking) */
  cil_id: string;
  /** Current iteration number */
  iteration: number;
  /** Optional: specific files to focus on */
  target_files?: string[];
  /** Raw evaluation findings — used by template remediator for deterministic fixes */
  findings?: Array<{
    id: number;
    category: string;
    severity: string;
    description: string;
    file?: string;
    remediation: string;
  }>;
}

// ─── Forbidden Files (shared safety list) ─────────────────────────────────────

export const FORBIDDEN_FILES = [
  '.env',
  '.env.local',
  '.env.production',
  'package-lock.json',
  'yarn.lock',
  'pnpm-lock.yaml',
  '.git',
];

// ─── Interface ────────────────────────────────────────────────────────────────

/**
 * Universal Coder interface.
 *
 * Every coding backend (Claude API, Claude Code CLI, Cursor, Aider, manual)
 * implements this interface. The CIL controller only calls through this —
 * never invokes a specific backend directly.
 */
export interface Coder {
  /** The backend identifier */
  readonly backend: CoderBackend;
  /** Display name for logs and UI */
  readonly displayName: string;

  /**
   * Apply code changes based on remediation plans.
   * This is the main entry point — takes agent fix plans and modifies files.
   */
  applyFixes(request: CoderRequest, config: CoderConfig): Promise<CoderResult>;

  /**
   * Check if this coding backend is available and configured.
   * E.g., Claude Code checks if `claude` CLI is on PATH.
   */
  isAvailable(): Promise<boolean>;

  /**
   * Human-readable description of what's needed to use this backend.
   */
  setupInstructions(): string;
}

// ─── Utilities ────────────────────────────────────────────────────────────────

/**
 * Combine all remediation plans into a single instruction block.
 */
export function buildRemediationPrompt(plans: Record<string, string>): string {
  return Object.entries(plans)
    .map(([agentId, plan]) => `## ${agentId}\n\n${plan}`)
    .join('\n\n---\n\n');
}

/**
 * Check if a file path is safe to modify (not in forbidden list, within codebase).
 */
export function isSafeToModify(
  relPath: string,
  codebasePath: string,
  absFilePath: string
): boolean {
  const path = require('path');
  // Must be within codebase
  if (!absFilePath.startsWith(path.resolve(codebasePath))) {
    return false;
  }
  // Must not be a forbidden file
  if (
    FORBIDDEN_FILES.some(
      (f) => relPath.endsWith(f) || relPath.includes(`${f}/`)
    )
  ) {
    return false;
  }
  return true;
}

/**
 * Parsed file block from structured remediation output.
 */
export interface ParsedFileBlock {
  /** Relative path from codebase root */
  filePath: string;
  /** Complete file content */
  content: string;
}

/**
 * Parse ===FILE: path=== blocks from LLM output.
 *
 * Expected format:
 *   ===FILE: path/to/file.ts===
 *   ```typescript
 *   // file content
 *   ```
 *   ===END FILE===
 *
 * Also handles blocks without ===END FILE=== (terminated by next ===FILE:=== or end of text).
 */
export function parseFileBlocks(text: string): ParsedFileBlock[] {
  const results: ParsedFileBlock[] = [];

  // Primary format: ===FILE: path===...===END FILE===
  const strictRegex =
    /===FILE:\s*(.+?)===\s*```[\w]*\n([\s\S]*?)```\s*===END FILE===/g;
  let match: RegExpExecArray | null;

  while ((match = strictRegex.exec(text)) !== null) {
    const filePath = match[1]!.trim();
    const content = match[2]!;
    if (filePath && content.trim().length > 0) {
      results.push({ filePath, content });
    }
  }

  // If strict format found blocks, return them
  if (results.length > 0) {
    return results;
  }

  // Fallback: look for ===FILE: path=== blocks without ===END FILE===
  const looseRegex = /===FILE:\s*(.+?)===\s*```[\w]*\n([\s\S]*?)```/g;
  while ((match = looseRegex.exec(text)) !== null) {
    const filePath = match[1]!.trim();
    const content = match[2]!;
    if (filePath && content.trim().length > 0) {
      results.push({ filePath, content });
    }
  }

  return results;
}
