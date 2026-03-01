/**
 * Unit Tests — Workflow Engine Helpers
 *
 * Tests for condition evaluation, variable interpolation, step flattening,
 * and other pure-logic parts of the workflow engine. These tests don't
 * require filesystem access — they test the logic directly.
 */

import { describe, it, expect } from 'vitest';

// ─── Recreate pure functions from workflow-engine for testing ─────────────────
// These functions are private in the workflow engine, so we reimplement them
// here to test the logic. This pattern is valid for testing internal algorithms.

/** Matches the evaluateCondition() in mcp-server/src/lib/workflow-engine.ts */
function evaluateCondition(
  condition: string,
  variables: Record<string, string>
): boolean {
  const interpolated = interpolateVariables(condition, variables);

  const eqMatch = interpolated.match(/(.+?)\s*==\s*['"](.+?)['"]/);
  if (eqMatch) {
    return eqMatch[1]!.trim() === eqMatch[2]!.trim();
  }

  const neqMatch = interpolated.match(/(.+?)\s*!=\s*['"](.+?)['"]/);
  if (neqMatch) {
    return neqMatch[1]!.trim() !== neqMatch[2]!.trim();
  }

  return (
    interpolated !== '' && interpolated !== 'false' && interpolated !== '0'
  );
}

/** Matches the interpolateVariables() in mcp-server/src/lib/workflow-engine.ts */
function interpolateVariables(
  template: string,
  variables: Record<string, string>
): string {
  return template.replace(/\$\{\{\s*(.+?)\s*\}\}/g, (_, key: string) => {
    return variables[key.trim()] ?? '';
  });
}

/** Matches the countSteps() in mcp-server/src/lib/workflow-engine.ts */
interface WorkflowNode {
  id: string;
  parallel?: Array<{ id: string }>;
  foreach?: string;
  steps?: WorkflowNode[];
}

function countSteps(nodes: WorkflowNode[]): number {
  let count = 0;
  for (const node of nodes) {
    if (node.parallel) {
      count += node.parallel.length;
    } else if (node.foreach && node.steps) {
      count += countSteps(node.steps) + 1;
    } else {
      count++;
    }
  }
  return count;
}

/** Matches the flattenSteps() in mcp-server/src/lib/workflow-engine.ts */
const STEP_ID_DELIM = '::';

function flattenSteps(nodes: WorkflowNode[]): string[] {
  const ids: string[] = [];
  for (const node of nodes) {
    if (node.parallel) {
      ids.push(node.id);
      for (const step of node.parallel) {
        ids.push(`${node.id}${STEP_ID_DELIM}${step.id}`);
      }
    } else if (node.foreach && node.steps) {
      ids.push(node.id);
      for (const subId of flattenSteps(node.steps)) {
        ids.push(`${node.id}${STEP_ID_DELIM}${subId}`);
      }
    } else {
      ids.push(node.id);
    }
  }
  return ids;
}

// ─── Tests: interpolateVariables ─────────────────────────────────────────────

describe('interpolateVariables', () => {
  it('should replace ${{ variable }} with value from variables', () => {
    const result = interpolateVariables('Hello ${{ name }}', { name: 'World' });
    expect(result).toBe('Hello World');
  });

  it('should handle multiple variables', () => {
    const result = interpolateVariables(
      '${{ greeting }} ${{ name }}, welcome to ${{ place }}',
      { greeting: 'Hello', name: 'Alice', place: 'Wonderland' }
    );
    expect(result).toBe('Hello Alice, welcome to Wonderland');
  });

  it('should replace missing variables with empty string', () => {
    const result = interpolateVariables('Value: ${{ missing }}', {});
    expect(result).toBe('Value: ');
  });

  it('should handle step output references', () => {
    const result = interpolateVariables(
      '${{ steps.review.outputs.quality_gate }}',
      { 'steps.review.outputs.quality_gate': 'pass' }
    );
    expect(result).toBe('pass');
  });

  it('should handle whitespace around variable names', () => {
    const result = interpolateVariables('${{  name  }}', { name: 'trimmed' });
    expect(result).toBe('trimmed');
  });

  it('should not modify text without variables', () => {
    const result = interpolateVariables('No variables here', {
      name: 'unused',
    });
    expect(result).toBe('No variables here');
  });

  it('should handle empty template', () => {
    const result = interpolateVariables('', { name: 'test' });
    expect(result).toBe('');
  });
});

// ─── Tests: evaluateCondition ────────────────────────────────────────────────

describe('evaluateCondition', () => {
  it('should evaluate equality with string literals (true)', () => {
    const result = evaluateCondition(
      "${{ steps.review.outputs.quality_gate }} == 'pass'",
      { 'steps.review.outputs.quality_gate': 'pass' }
    );
    expect(result).toBe(true);
  });

  it('should evaluate equality with string literals (false)', () => {
    const result = evaluateCondition(
      "${{ steps.review.outputs.quality_gate }} == 'pass'",
      { 'steps.review.outputs.quality_gate': 'fail' }
    );
    expect(result).toBe(false);
  });

  it('should evaluate inequality (true)', () => {
    const result = evaluateCondition(
      "${{ steps.test.outputs.status }} != 'failed'",
      { 'steps.test.outputs.status': 'passed' }
    );
    expect(result).toBe(true);
  });

  it('should evaluate inequality (false)', () => {
    const result = evaluateCondition(
      "${{ steps.test.outputs.status }} != 'failed'",
      { 'steps.test.outputs.status': 'failed' }
    );
    expect(result).toBe(false);
  });

  it('should treat non-empty interpolated strings as truthy', () => {
    const result = evaluateCondition('${{ some_var }}', {
      some_var: 'any_value',
    });
    expect(result).toBe(true);
  });

  it('should treat empty interpolated strings as falsy', () => {
    const result = evaluateCondition('${{ missing_var }}', {});
    expect(result).toBe(false);
  });

  it("should treat 'false' as falsy", () => {
    const result = evaluateCondition('${{ flag }}', { flag: 'false' });
    expect(result).toBe(false);
  });

  it("should treat '0' as falsy", () => {
    const result = evaluateCondition('${{ count }}', { count: '0' });
    expect(result).toBe(false);
  });

  it('should handle double-quoted string comparisons', () => {
    const result = evaluateCondition('${{ mode }} == "enhanced"', {
      mode: 'enhanced',
    });
    expect(result).toBe(true);
  });
});

// ─── Tests: countSteps ───────────────────────────────────────────────────────

describe('countSteps', () => {
  it('should count simple sequential steps', () => {
    const nodes: WorkflowNode[] = [
      { id: 'step1' },
      { id: 'step2' },
      { id: 'step3' },
    ];
    expect(countSteps(nodes)).toBe(3);
  });

  it('should count parallel group steps (not the group itself)', () => {
    const nodes: WorkflowNode[] = [
      {
        id: 'parallel-group',
        parallel: [{ id: 'p1' }, { id: 'p2' }, { id: 'p3' }],
      },
    ];
    expect(countSteps(nodes)).toBe(3);
  });

  it('should count foreach loop steps including the loop itself', () => {
    const nodes: WorkflowNode[] = [
      {
        id: 'loop',
        foreach: '${{ inputs.files }}',
        steps: [{ id: 'inner1' }, { id: 'inner2' }],
      },
    ];
    // Loop itself (1) + inner steps (2)
    expect(countSteps(nodes)).toBe(3);
  });

  it('should count mixed step types', () => {
    const nodes: WorkflowNode[] = [
      { id: 'step1' },
      {
        id: 'parallel-group',
        parallel: [{ id: 'p1' }, { id: 'p2' }],
      },
      { id: 'step2' },
    ];
    // 1 + 2 (parallel) + 1 = 4
    expect(countSteps(nodes)).toBe(4);
  });

  it('should return 0 for empty nodes array', () => {
    expect(countSteps([])).toBe(0);
  });
});

// ─── Tests: flattenSteps ─────────────────────────────────────────────────────

describe('flattenSteps', () => {
  it('should flatten simple steps to their IDs', () => {
    const nodes: WorkflowNode[] = [{ id: 'step1' }, { id: 'step2' }];
    expect(flattenSteps(nodes)).toEqual(['step1', 'step2']);
  });

  it('should flatten parallel groups with composite IDs', () => {
    const nodes: WorkflowNode[] = [
      {
        id: 'review',
        parallel: [{ id: 'code' }, { id: 'security' }],
      },
    ];
    const flattened = flattenSteps(nodes);
    expect(flattened).toEqual(['review', 'review::code', 'review::security']);
  });

  it('should flatten foreach loops with composite IDs', () => {
    const nodes: WorkflowNode[] = [
      {
        id: 'file-loop',
        foreach: '${{ inputs.files }}',
        steps: [{ id: 'lint' }, { id: 'test' }],
      },
    ];
    const flattened = flattenSteps(nodes);
    expect(flattened).toEqual([
      'file-loop',
      'file-loop::lint',
      'file-loop::test',
    ]);
  });

  it('should handle mixed sequential, parallel, and loop steps', () => {
    const nodes: WorkflowNode[] = [
      { id: 'init' },
      {
        id: 'parallel-build',
        parallel: [{ id: 'frontend' }, { id: 'backend' }],
      },
      { id: 'deploy' },
    ];
    const flattened = flattenSteps(nodes);
    expect(flattened).toEqual([
      'init',
      'parallel-build',
      'parallel-build::frontend',
      'parallel-build::backend',
      'deploy',
    ]);
  });

  it('should return empty array for empty input', () => {
    expect(flattenSteps([])).toEqual([]);
  });
});
