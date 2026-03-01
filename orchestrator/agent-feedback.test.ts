/**
 * Unit Tests — Agent Feedback Module
 *
 * Tests for finding-to-agent mapping, finding diffs (Jaro similarity),
 * iteration reports, feedback context building, and grouping utilities.
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  mapFindingsToAgents,
  getAssignedAgents,
  groupByAgent,
  diffFindings,
  buildIterationReport,
  buildAgentFeedbackContext,
  CATEGORY_AGENT_MAP,
  type Finding,
  type EvaluationResult,
  type FindingAssignment,
  type IterationReport,
} from './agent-feedback';

// ─── Mock the memory-bridge to avoid filesystem I/O ──────────────────────────

vi.mock('./memory-bridge', () => ({
  writeFact: vi.fn(() => ({ id: 'mock_fact_id', content: '' })),
  searchFacts: vi.fn(() => []),
  readFacts: vi.fn(() => []),
}));

// ─── Fixtures ────────────────────────────────────────────────────────────────

function makeFinding(overrides: Partial<Finding> = {}): Finding {
  return {
    id: 1,
    category: 'Code Quality',
    severity: 'medium',
    description: 'Unused variable detected',
    remediation: 'Remove the unused variable',
    ...overrides,
  };
}

function makeEvaluationResult(
  overrides: Partial<EvaluationResult> = {}
): EvaluationResult {
  return {
    overall_score: 65,
    grade: 'C',
    risk_level: 'medium',
    categories: [
      {
        id: 'code_quality',
        name: 'Code Quality',
        weight: 15,
        score: 70,
        grade: 'B-',
        findings_count: 3,
      },
      {
        id: 'security',
        name: 'Security',
        weight: 20,
        score: 55,
        grade: 'D+',
        findings_count: 5,
      },
      {
        id: 'testing',
        name: 'Testing',
        weight: 10,
        score: 30,
        grade: 'F',
        findings_count: 8,
      },
    ],
    findings: [
      makeFinding({
        id: 1,
        category: 'Code Quality',
        severity: 'medium',
        description: 'Unused variable detected',
      }),
      makeFinding({
        id: 2,
        category: 'Security',
        severity: 'critical',
        description: 'SQL injection vulnerability',
        file: 'src/app/api/route.ts',
      }),
      makeFinding({
        id: 3,
        category: 'Testing',
        severity: 'high',
        description: 'No unit tests for core module',
      }),
    ],
    timestamp: '2026-03-01T00:00:00Z',
    codebase_path: '/project',
    mode: 'standard',
    languages_detected: ['typescript'],
    frameworks_detected: ['next.js'],
    ...overrides,
  };
}

// ─── Tests: mapFindingsToAgents ──────────────────────────────────────────────

describe('mapFindingsToAgents', () => {
  it('should map each finding to an agent', () => {
    const result = makeEvaluationResult();
    const assignments = mapFindingsToAgents(result);
    expect(assignments).toHaveLength(3);
    for (const a of assignments) {
      expect(a.agent_id).toBeTruthy();
      expect(a.status).toBe('assigned');
    }
  });

  it('should map Code Quality findings to qa_engineer', () => {
    const result = makeEvaluationResult({
      findings: [makeFinding({ id: 1, category: 'Code Quality' })],
    });
    const assignments = mapFindingsToAgents(result);
    expect(assignments[0]!.agent_id).toBe('qa_engineer');
  });

  it('should map Security findings to security_engineer', () => {
    const result = makeEvaluationResult({
      findings: [makeFinding({ id: 1, category: 'Security' })],
    });
    const assignments = mapFindingsToAgents(result);
    expect(assignments[0]!.agent_id).toBe('security_engineer');
  });

  it('should map Testing findings to qa_engineer', () => {
    const result = makeEvaluationResult({
      findings: [makeFinding({ id: 1, category: 'Testing' })],
    });
    const assignments = mapFindingsToAgents(result);
    expect(assignments[0]!.agent_id).toBe('qa_engineer');
  });

  it('should use file-path matching over category mapping for test files', () => {
    const result = makeEvaluationResult({
      findings: [
        makeFinding({
          id: 1,
          category: 'Code Quality',
          file: 'src/components/Button.test.tsx',
        }),
      ],
    });
    const assignments = mapFindingsToAgents(result);
    expect(assignments[0]!.agent_id).toBe('qa_engineer');
  });

  it('should use file-path matching for Prisma files', () => {
    const result = makeEvaluationResult({
      findings: [
        makeFinding({
          id: 1,
          category: 'Code Quality',
          file: 'prisma/schema.prisma',
        }),
      ],
    });
    const assignments = mapFindingsToAgents(result);
    expect(assignments[0]!.agent_id).toBe('database_engineer');
  });

  it('should use file-path matching for API route files', () => {
    const result = makeEvaluationResult({
      findings: [
        makeFinding({
          id: 1,
          category: 'Code Quality',
          file: 'src/app/api/users/route.ts',
        }),
      ],
    });
    const assignments = mapFindingsToAgents(result);
    expect(assignments[0]!.agent_id).toBe('api_designer');
  });

  it('should use file-path matching for CI/CD files', () => {
    const result = makeEvaluationResult({
      findings: [
        makeFinding({
          id: 1,
          category: 'Code Quality',
          file: '.github/workflows/ci.yml',
        }),
      ],
    });
    const assignments = mapFindingsToAgents(result);
    expect(assignments[0]!.agent_id).toBe('devops_engineer');
  });

  it('should use file-path matching for Docker files', () => {
    const result = makeEvaluationResult({
      findings: [
        makeFinding({ id: 1, category: 'Code Quality', file: 'Dockerfile' }),
      ],
    });
    const assignments = mapFindingsToAgents(result);
    expect(assignments[0]!.agent_id).toBe('devops_engineer');
  });

  it('should fall back to qa_engineer for unknown categories', () => {
    const result = makeEvaluationResult({
      findings: [makeFinding({ id: 1, category: 'Unknown Category' })],
    });
    const assignments = mapFindingsToAgents(result);
    expect(assignments[0]!.agent_id).toBe('qa_engineer');
  });

  it('should preserve finding metadata in assignments', () => {
    const result = makeEvaluationResult({
      findings: [
        makeFinding({
          id: 42,
          severity: 'critical',
          file: 'src/index.ts',
          line: 100,
        }),
      ],
    });
    const assignments = mapFindingsToAgents(result);
    expect(assignments[0]!.finding_id).toBe(42);
    expect(assignments[0]!.severity).toBe('critical');
    expect(assignments[0]!.file).toBe('src/index.ts');
    expect(assignments[0]!.line).toBe(100);
  });

  it('should handle empty findings array', () => {
    const result = makeEvaluationResult({ findings: [] });
    const assignments = mapFindingsToAgents(result);
    expect(assignments).toHaveLength(0);
  });
});

// ─── Tests: CATEGORY_AGENT_MAP ───────────────────────────────────────────────

describe('CATEGORY_AGENT_MAP', () => {
  it('should have at least one agent per category', () => {
    for (const [category, agents] of Object.entries(CATEGORY_AGENT_MAP)) {
      expect(
        agents.length,
        `Category "${category}" should have at least one agent`
      ).toBeGreaterThan(0);
    }
  });

  it('should map all major evaluation categories', () => {
    const expectedCategories = [
      'code_quality',
      'architecture',
      'security',
      'performance',
      'testing',
      'devops',
      'api_design',
      'documentation',
    ];
    for (const cat of expectedCategories) {
      expect(
        CATEGORY_AGENT_MAP,
        `Expected "${cat}" to be in CATEGORY_AGENT_MAP`
      ).toHaveProperty(cat);
    }
  });
});

// ─── Tests: getAssignedAgents ────────────────────────────────────────────────

describe('getAssignedAgents', () => {
  it('should return unique agent IDs from assignments', () => {
    const assignments: FindingAssignment[] = [
      {
        finding_id: 1,
        category: 'Testing',
        severity: 'high',
        agent_id: 'qa_engineer',
        description: '',
        remediation: '',
        status: 'assigned',
      },
      {
        finding_id: 2,
        category: 'Testing',
        severity: 'medium',
        agent_id: 'qa_engineer',
        description: '',
        remediation: '',
        status: 'assigned',
      },
      {
        finding_id: 3,
        category: 'Security',
        severity: 'critical',
        agent_id: 'security_engineer',
        description: '',
        remediation: '',
        status: 'assigned',
      },
    ];
    const agents = getAssignedAgents(assignments);
    expect(agents).toHaveLength(2);
    expect(agents).toContain('qa_engineer');
    expect(agents).toContain('security_engineer');
  });

  it('should return empty array for empty assignments', () => {
    expect(getAssignedAgents([])).toHaveLength(0);
  });
});

// ─── Tests: groupByAgent ─────────────────────────────────────────────────────

describe('groupByAgent', () => {
  it('should group assignments by agent_id', () => {
    const assignments: FindingAssignment[] = [
      {
        finding_id: 1,
        category: 'A',
        severity: 'high',
        agent_id: 'qa_engineer',
        description: '',
        remediation: '',
        status: 'assigned',
      },
      {
        finding_id: 2,
        category: 'B',
        severity: 'medium',
        agent_id: 'security_engineer',
        description: '',
        remediation: '',
        status: 'assigned',
      },
      {
        finding_id: 3,
        category: 'A',
        severity: 'low',
        agent_id: 'qa_engineer',
        description: '',
        remediation: '',
        status: 'assigned',
      },
    ];
    const groups = groupByAgent(assignments);
    expect(Object.keys(groups)).toHaveLength(2);
    expect(groups['qa_engineer']).toHaveLength(2);
    expect(groups['security_engineer']).toHaveLength(1);
  });

  it('should return empty object for empty assignments', () => {
    expect(Object.keys(groupByAgent([]))).toHaveLength(0);
  });
});

// ─── Tests: diffFindings ─────────────────────────────────────────────────────

describe('diffFindings', () => {
  it('should identify resolved findings', () => {
    const prev = [
      makeFinding({ id: 1, description: 'Old bug in login', file: 'auth.ts' }),
    ];
    const curr: Finding[] = [];
    const diff = diffFindings(prev, curr);
    expect(diff.resolved).toHaveLength(1);
    expect(diff.new_findings).toHaveLength(0);
    expect(diff.persistent).toHaveLength(0);
  });

  it('should identify new findings', () => {
    const prev: Finding[] = [];
    const curr = [makeFinding({ id: 1, description: 'New security issue' })];
    const diff = diffFindings(prev, curr);
    expect(diff.resolved).toHaveLength(0);
    expect(diff.new_findings).toHaveLength(1);
  });

  it('should identify persistent findings with similar descriptions', () => {
    const prev = [
      makeFinding({
        id: 1,
        category: 'Security',
        description: 'SQL injection vulnerability in user endpoint',
      }),
    ];
    const curr = [
      makeFinding({
        id: 2,
        category: 'Security',
        description: 'SQL injection vulnerability in user endpoint',
      }),
    ];
    const diff = diffFindings(prev, curr);
    expect(diff.persistent).toHaveLength(1);
    expect(diff.resolved).toHaveLength(0);
    expect(diff.new_findings).toHaveLength(0);
  });

  it('should match findings by file + similar description', () => {
    const prev = [
      makeFinding({
        id: 1,
        description: 'Unused import in component',
        file: 'src/Button.tsx',
      }),
    ];
    const curr = [
      makeFinding({
        id: 2,
        description: 'Unused import in component file',
        file: 'src/Button.tsx',
      }),
    ];
    const diff = diffFindings(prev, curr);
    expect(diff.persistent).toHaveLength(1);
    expect(diff.resolved).toHaveLength(0);
  });

  it('should handle completely different finding sets', () => {
    const prev = [
      makeFinding({ id: 1, category: 'Testing', description: 'No tests' }),
    ];
    const curr = [
      makeFinding({
        id: 2,
        category: 'Security',
        description: 'XSS vulnerability',
      }),
    ];
    const diff = diffFindings(prev, curr);
    expect(diff.resolved).toHaveLength(1);
    expect(diff.new_findings).toHaveLength(1);
    expect(diff.persistent).toHaveLength(0);
  });

  it('should handle empty previous and current findings', () => {
    const diff = diffFindings([], []);
    expect(diff.resolved).toHaveLength(0);
    expect(diff.new_findings).toHaveLength(0);
    expect(diff.persistent).toHaveLength(0);
  });
});

// ─── Tests: buildIterationReport ─────────────────────────────────────────────

describe('buildIterationReport', () => {
  it('should build a report for the first iteration (no previous)', () => {
    const result = makeEvaluationResult();
    const assignments = mapFindingsToAgents(result);
    const report = buildIterationReport(1, result, null, assignments);

    expect(report.iteration).toBe(1);
    expect(report.evaluation_result).toBe(result);
    expect(report.finding_assignments).toBe(assignments);
    expect(report.score_delta).toBe(0);
    expect(report.new_findings).toBe(result.findings.length);
    expect(report.resolved_findings).toBe(0);
  });

  it('should compute score_delta between iterations', () => {
    const prev = makeEvaluationResult({ overall_score: 60 });
    const curr = makeEvaluationResult({ overall_score: 75 });
    const assignments = mapFindingsToAgents(curr);
    const report = buildIterationReport(2, curr, prev, assignments);

    expect(report.score_delta).toBe(15);
  });

  it('should track per-agent performance', () => {
    const result = makeEvaluationResult();
    const assignments = mapFindingsToAgents(result);
    const report = buildIterationReport(1, result, null, assignments);

    expect(report.agent_performance.length).toBeGreaterThan(0);
    for (const perf of report.agent_performance) {
      expect(perf.agent_id).toBeTruthy();
      expect(perf.iterations).toHaveLength(1);
      expect(perf.iterations[0]!.findings_assigned).toBeGreaterThan(0);
    }
  });

  it('should mark resolved findings as fixed when comparing iterations', () => {
    const prevResult = makeEvaluationResult({
      overall_score: 50,
      findings: [
        makeFinding({
          id: 1,
          category: 'Testing',
          description: 'No unit tests for core module',
        }),
      ],
    });
    const currResult = makeEvaluationResult({
      overall_score: 70,
      findings: [], // Finding was resolved
    });
    const assignments: FindingAssignment[] = [
      {
        finding_id: 1,
        category: 'Testing',
        severity: 'high',
        agent_id: 'qa_engineer',
        description: 'No unit tests for core module',
        remediation: 'Add tests',
        status: 'assigned',
      },
    ];
    const report = buildIterationReport(2, currResult, prevResult, assignments);

    expect(report.resolved_findings).toBe(1);
    expect(assignments[0]!.status).toBe('fixed');
  });
});

// ─── Tests: buildAgentFeedbackContext ────────────────────────────────────────

describe('buildAgentFeedbackContext', () => {
  it('should return empty string when history is empty', () => {
    expect(buildAgentFeedbackContext('qa_engineer', [])).toBe('');
  });

  it('should include performance history for the agent', () => {
    const result = makeEvaluationResult();
    const assignments = mapFindingsToAgents(result);
    const report = buildIterationReport(1, result, null, assignments);

    const context = buildAgentFeedbackContext('qa_engineer', [report]);
    expect(context).toContain('Performance Feedback');
    expect(context).toContain('Iteration 1');
  });

  it('should include unresolved findings', () => {
    const result = makeEvaluationResult({
      findings: [
        makeFinding({
          id: 1,
          category: 'Testing',
          severity: 'high',
          description: 'Missing test coverage',
        }),
      ],
    });
    const assignments = mapFindingsToAgents(result);
    const report = buildIterationReport(1, result, null, assignments);

    const context = buildAgentFeedbackContext('qa_engineer', [report]);
    expect(context).toContain('Unresolved Findings');
    expect(context).toContain('Missing test coverage');
  });

  it('should not include findings for other agents', () => {
    const result = makeEvaluationResult({
      findings: [
        makeFinding({
          id: 1,
          category: 'Security',
          severity: 'critical',
          description: 'Auth bypass',
        }),
      ],
    });
    const assignments = mapFindingsToAgents(result);
    const report = buildIterationReport(1, result, null, assignments);

    const context = buildAgentFeedbackContext('qa_engineer', [report]);
    // Security findings belong to security_engineer, not qa_engineer
    expect(context).not.toContain('Auth bypass');
  });
});
