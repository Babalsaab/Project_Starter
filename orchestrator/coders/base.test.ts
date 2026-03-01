/**
 * Unit Tests — Coder Base Utilities
 *
 * Tests for buildRemediationPrompt(), isSafeToModify(), parseFileBlocks(),
 * and FORBIDDEN_FILES constant.
 */

import { describe, it, expect } from 'vitest';
import * as path from 'path';
import {
  buildRemediationPrompt,
  isSafeToModify,
  parseFileBlocks,
  FORBIDDEN_FILES,
} from './base';

// ─── buildRemediationPrompt ─────────────────────────────────────────────────

describe('buildRemediationPrompt', () => {
  it('should combine multiple agent plans into a single string', () => {
    const plans = {
      qa_engineer: 'Fix test coverage',
      security_engineer: 'Add input validation',
    };
    const result = buildRemediationPrompt(plans);
    expect(result).toContain('## qa_engineer');
    expect(result).toContain('Fix test coverage');
    expect(result).toContain('## security_engineer');
    expect(result).toContain('Add input validation');
  });

  it('should separate plans with horizontal rules', () => {
    const plans = {
      agent_a: 'Plan A',
      agent_b: 'Plan B',
    };
    const result = buildRemediationPrompt(plans);
    expect(result).toContain('---');
  });

  it('should handle empty plans object', () => {
    const result = buildRemediationPrompt({});
    expect(result).toBe('');
  });

  it('should handle single plan', () => {
    const plans = { only_agent: 'Only plan' };
    const result = buildRemediationPrompt(plans);
    expect(result).toContain('## only_agent');
    expect(result).toContain('Only plan');
    expect(result).not.toContain('---');
  });
});

// ─── isSafeToModify ──────────────────────────────────────────────────────────

describe('isSafeToModify', () => {
  const codebasePath = '/home/user/project';

  it('should allow files within the codebase', () => {
    const absPath = path.resolve(codebasePath, 'src/index.ts');
    expect(isSafeToModify('src/index.ts', codebasePath, absPath)).toBe(true);
  });

  it('should reject files outside the codebase', () => {
    expect(
      isSafeToModify('../../etc/passwd', codebasePath, '/etc/passwd')
    ).toBe(false);
  });

  it('should reject forbidden files', () => {
    for (const forbidden of FORBIDDEN_FILES) {
      const absPath = path.resolve(codebasePath, forbidden);
      expect(
        isSafeToModify(forbidden, codebasePath, absPath),
        `Should reject ${forbidden}`
      ).toBe(false);
    }
  });

  it('should reject .env.local', () => {
    const absPath = path.resolve(codebasePath, '.env.local');
    expect(isSafeToModify('.env.local', codebasePath, absPath)).toBe(false);
  });

  it('should allow regular source files', () => {
    const absPath = path.resolve(codebasePath, 'orchestrator/executor.ts');
    expect(
      isSafeToModify('orchestrator/executor.ts', codebasePath, absPath)
    ).toBe(true);
  });
});

// ─── FORBIDDEN_FILES ──────────────────────────────────────────────────────────

describe('FORBIDDEN_FILES', () => {
  it('should include sensitive files', () => {
    expect(FORBIDDEN_FILES).toContain('.env');
    expect(FORBIDDEN_FILES).toContain('.env.local');
    expect(FORBIDDEN_FILES).toContain('package-lock.json');
  });

  it('should include lock files', () => {
    expect(FORBIDDEN_FILES).toContain('yarn.lock');
    expect(FORBIDDEN_FILES).toContain('pnpm-lock.yaml');
  });

  it('should include .git', () => {
    expect(FORBIDDEN_FILES).toContain('.git');
  });
});

// ─── parseFileBlocks ──────────────────────────────────────────────────────────

describe('parseFileBlocks', () => {
  it('should parse strict ===FILE: ... ===END FILE=== format', () => {
    const text = `Some intro text

===FILE: src/index.ts===
\`\`\`typescript
export function hello() {
  return "world";
}
\`\`\`
===END FILE===

More text here.`;

    const blocks = parseFileBlocks(text);
    expect(blocks).toHaveLength(1);
    expect(blocks[0]!.filePath).toBe('src/index.ts');
    expect(blocks[0]!.content).toContain('return "world"');
  });

  it('should parse multiple file blocks', () => {
    const text = `
===FILE: a.ts===
\`\`\`typescript
const a = 1;
\`\`\`
===END FILE===

===FILE: b.ts===
\`\`\`typescript
const b = 2;
\`\`\`
===END FILE===
`;

    const blocks = parseFileBlocks(text);
    expect(blocks).toHaveLength(2);
    expect(blocks[0]!.filePath).toBe('a.ts');
    expect(blocks[1]!.filePath).toBe('b.ts');
  });

  it('should fall back to loose format when ===END FILE=== is missing', () => {
    const text = `
===FILE: loose.ts===
\`\`\`typescript
const loose = true;
\`\`\`
`;

    const blocks = parseFileBlocks(text);
    expect(blocks).toHaveLength(1);
    expect(blocks[0]!.filePath).toBe('loose.ts');
    expect(blocks[0]!.content).toContain('loose = true');
  });

  it('should return empty array for text with no file blocks', () => {
    const blocks = parseFileBlocks(
      'Just some regular text with no code blocks.'
    );
    expect(blocks).toHaveLength(0);
  });

  it('should skip blocks with empty content', () => {
    const text = `
===FILE: empty.ts===
\`\`\`typescript

\`\`\`
===END FILE===
`;

    const blocks = parseFileBlocks(text);
    expect(blocks).toHaveLength(0);
  });

  it('should trim file paths', () => {
    const text = `
===FILE:   spaced/path.ts  ===
\`\`\`typescript
const x = 1;
\`\`\`
===END FILE===
`;

    const blocks = parseFileBlocks(text);
    expect(blocks).toHaveLength(1);
    expect(blocks[0]!.filePath).toBe('spaced/path.ts');
  });

  it('should handle different code fence languages', () => {
    const text = `
===FILE: config.yaml===
\`\`\`yaml
key: value
\`\`\`
===END FILE===
`;

    const blocks = parseFileBlocks(text);
    expect(blocks).toHaveLength(1);
    expect(blocks[0]!.content).toContain('key: value');
  });
});
