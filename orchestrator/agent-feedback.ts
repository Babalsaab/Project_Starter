/**
 * Agent Feedback Module
 *
 * Maps CTO evaluation findings to responsible agents, tracks performance
 * across iterations, and builds feedback context for agent prompt injection.
 *
 * This is the "learning" layer — agents get smarter by receiving their past
 * performance data and specific unresolved findings each time they're invoked.
 */

import { writeFact, searchFacts, readFacts } from './memory-bridge';

// ─── Types ───────────────────────────────────────────────────────────────────

/** Mirrors Finding from src/lib/evaluation-runner.ts */
export interface Finding {
  id: number;
  category: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  description: string;
  file?: string;
  line?: number;
  remediation: string;
}

/** Mirrors CategoryScore from src/lib/evaluation-runner.ts */
export interface CategoryScore {
  id: string;
  name: string;
  weight: number;
  score: number;
  grade: string;
  findings_count: number;
}

/** Mirrors EvaluationResult from src/lib/evaluation-runner.ts */
export interface EvaluationResult {
  overall_score: number;
  grade: string;
  risk_level: string;
  categories: CategoryScore[];
  findings: Finding[];
  timestamp: string;
  codebase_path: string;
  mode: string;
  languages_detected: string[];
  frameworks_detected: string[];
  duration_seconds?: number;
}

export interface FindingAssignment {
  finding_id: number;
  category: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  agent_id: string;
  file?: string;
  line?: number;
  description: string;
  remediation: string;
  status: 'assigned' | 'fixed' | 'unresolved' | 'new';
}

export interface AgentPerformance {
  agent_id: string;
  iterations: AgentIterationData[];
}

export interface AgentIterationData {
  iteration: number;
  findings_assigned: number;
  findings_resolved: number;
  category_scores: Record<string, number>;
  score_delta: number;
}

export interface IterationReport {
  iteration: number;
  evaluation_result: EvaluationResult;
  finding_assignments: FindingAssignment[];
  agent_performance: AgentPerformance[];
  score_delta: number;
  new_findings: number;
  resolved_findings: number;
}

export interface FindingDiff {
  resolved: Finding[];
  new_findings: Finding[];
  persistent: Finding[];
}

// ─── Category → Agent Mapping ────────────────────────────────────────────────

/**
 * Maps CTO evaluation category IDs to the agents responsible for that area.
 * First agent in each array is the primary responsible agent.
 */
export const CATEGORY_AGENT_MAP: Record<string, string[]> = {
  code_quality: ['qa_engineer', 'backend_engineer', 'web_frontend_engineer'],
  architecture: ['backend_engineer', 'api_designer', 'database_engineer'],
  security: ['security_engineer', 'penetration_tester', 'devsecops_engineer'],
  performance: ['frontend_performance_engineer', 'backend_engineer'],
  testing: ['qa_engineer', 'test_automation_engineer'],
  devops: ['devops_engineer', 'release_engineer'],
  scalability: ['backend_engineer', 'database_engineer', 'devops_engineer'],
  reliability: ['backend_engineer', 'devops_engineer', 'qa_engineer'],
  data_architecture: ['database_engineer', 'data_engineer', 'backend_engineer'],
  api_design: ['api_designer', 'backend_engineer'],
  observability: ['devops_engineer', 'backend_engineer'],
  frontend: ['web_frontend_engineer', 'design_engineer'],
  backend: ['backend_engineer', 'api_designer'],
  mobile: ['ios_engineer', 'android_engineer', 'cross_platform_engineer'],
  documentation: ['technical_writer'],
  developer_experience: ['devops_engineer', 'technical_writer'],
  maintainability: ['backend_engineer', 'qa_engineer', 'web_frontend_engineer'],
  compliance: ['compliance_engineer', 'security_engineer'],
  cost_efficiency: ['devops_engineer', 'backend_engineer'],
  innovation: ['product_manager', 'ml_engineer'],
  uiux_consistency: ['ux_designer', 'ui_designer', 'design_systems_engineer'],
};

/** File-path patterns → agent overrides (more specific than category mapping). */
const FILE_AGENT_MAP: Array<{ pattern: RegExp; agents: string[] }> = [
  {
    pattern: /\.(test|spec)\.(ts|tsx|js|jsx)$/i,
    agents: ['qa_engineer', 'test_automation_engineer'],
  },
  { pattern: /prisma\//i, agents: ['database_engineer'] },
  { pattern: /\.github\//i, agents: ['devops_engineer'] },
  { pattern: /Dockerfile|docker-compose/i, agents: ['devops_engineer'] },
  {
    pattern: /auth\.(ts|js)|middleware/i,
    agents: ['security_engineer', 'backend_engineer'],
  },
  {
    pattern: /components\/ui\//i,
    agents: ['ui_designer', 'design_systems_engineer'],
  },
  {
    pattern: /\.css$|tailwind/i,
    agents: ['web_frontend_engineer', 'ux_designer'],
  },
  { pattern: /api\//i, agents: ['api_designer', 'backend_engineer'] },
  { pattern: /README|CONTRIBUTING|docs\//i, agents: ['technical_writer'] },
];

// ─── Finding → Agent Mapping ─────────────────────────────────────────────────

/**
 * Maps each evaluation finding to the most relevant agent.
 * Priority: file-path match → category mapping → fallback to qa_engineer.
 */
export function mapFindingsToAgents(
  result: EvaluationResult
): FindingAssignment[] {
  const assignments: FindingAssignment[] = [];

  for (const finding of result.findings) {
    let agentId = 'qa_engineer'; // default fallback

    // 1) Try file-path matching (most specific)
    if (finding.file) {
      for (const entry of FILE_AGENT_MAP) {
        if (entry.pattern.test(finding.file)) {
          agentId = entry.agents[0]!;
          break;
        }
      }
    }

    // 2) Fall back to category mapping
    if (agentId === 'qa_engineer' && finding.category) {
      // Normalize category name to ID: "Code Quality" → "code_quality"
      const catId = finding.category
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '_')
        .replace(/(^_|_$)/g, '');
      const mapped = CATEGORY_AGENT_MAP[catId];
      if (mapped && mapped.length > 0) {
        agentId = mapped[0]!;
      }
    }

    assignments.push({
      finding_id: finding.id,
      category: finding.category,
      severity: finding.severity,
      agent_id: agentId,
      file: finding.file,
      line: finding.line,
      description: finding.description,
      remediation: finding.remediation,
      status: 'assigned',
    });
  }

  return assignments;
}

/**
 * Get all agents needed for a set of assignments (deduplicated).
 */
export function getAssignedAgents(assignments: FindingAssignment[]): string[] {
  return [...new Set(assignments.map((a) => a.agent_id))];
}

/**
 * Get assignments grouped by agent.
 */
export function groupByAgent(
  assignments: FindingAssignment[]
): Record<string, FindingAssignment[]> {
  const groups: Record<string, FindingAssignment[]> = {};
  for (const a of assignments) {
    (groups[a.agent_id] ??= []).push(a);
  }
  return groups;
}

// ─── Finding Diff ────────────────────────────────────────────────────────────

/**
 * Compare findings between two evaluation iterations.
 * Matches findings by (file + description similarity) since IDs aren't stable across runs.
 */
export function diffFindings(prev: Finding[], curr: Finding[]): FindingDiff {
  const resolved: Finding[] = [];
  const persistent: Finding[] = [];
  const matchedCurr = new Set<number>();

  for (const pf of prev) {
    let found = false;
    for (const cf of curr) {
      if (matchedCurr.has(cf.id)) {
        continue;
      }
      if (isSimilarFinding(pf, cf)) {
        persistent.push(cf);
        matchedCurr.add(cf.id);
        found = true;
        break;
      }
    }
    if (!found) {
      resolved.push(pf);
    }
  }

  const new_findings = curr.filter((cf) => !matchedCurr.has(cf.id));

  return { resolved, new_findings, persistent };
}

function isSimilarFinding(a: Finding, b: Finding): boolean {
  // Same file + similar description = same finding
  if (a.file && b.file && a.file === b.file) {
    const simDesc = jaroSimilarity(
      a.description.toLowerCase(),
      b.description.toLowerCase()
    );
    if (simDesc > 0.75) {
      return true;
    }
  }
  // Same category + very similar description
  if (a.category === b.category) {
    const simDesc = jaroSimilarity(
      a.description.toLowerCase(),
      b.description.toLowerCase()
    );
    if (simDesc > 0.85) {
      return true;
    }
  }
  return false;
}

/** Jaro string similarity (0-1). Simple and fast enough for finding comparison. */
function jaroSimilarity(s1: string, s2: string): number {
  if (s1 === s2) {
    return 1;
  }
  const len1 = s1.length;
  const len2 = s2.length;
  if (len1 === 0 || len2 === 0) {
    return 0;
  }

  const matchDist = Math.max(Math.floor(Math.max(len1, len2) / 2) - 1, 0);
  const s1Matches = new Array(len1).fill(false);
  const s2Matches = new Array(len2).fill(false);

  let matches = 0;
  let transpositions = 0;

  for (let i = 0; i < len1; i++) {
    const start = Math.max(0, i - matchDist);
    const end = Math.min(i + matchDist + 1, len2);
    for (let j = start; j < end; j++) {
      if (s2Matches[j] || s1[i] !== s2[j]) {
        continue;
      }
      s1Matches[i] = true;
      s2Matches[j] = true;
      matches++;
      break;
    }
  }

  if (matches === 0) {
    return 0;
  }

  let k = 0;
  for (let i = 0; i < len1; i++) {
    if (!s1Matches[i]) {
      continue;
    }
    while (!s2Matches[k]) {
      k++;
    }
    if (s1[i] !== s2[k]) {
      transpositions++;
    }
    k++;
  }

  return (
    (matches / len1 +
      matches / len2 +
      (matches - transpositions / 2) / matches) /
    3
  );
}

// ─── Performance Tracking ────────────────────────────────────────────────────

/**
 * Build an IterationReport comparing the current iteration against the previous one.
 * @param previousAssignments - Assignments from the PREVIOUS iteration (used to correctly
 *   attribute resolved findings to the agents that were assigned to fix them).
 */
export function buildIterationReport(
  iteration: number,
  currentResult: EvaluationResult,
  previousResult: EvaluationResult | null,
  assignments: FindingAssignment[],
  previousAssignments?: FindingAssignment[]
): IterationReport {
  const diff = previousResult
    ? diffFindings(previousResult.findings, currentResult.findings)
    : null;

  // Update current assignments status (for new/persistent findings in this iteration)
  if (diff) {
    const resolvedDescs = new Set(
      diff.resolved.map((f) => f.description.toLowerCase())
    );

    // Mark resolved in current assignments (if any overlap)
    for (const a of assignments) {
      if (resolvedDescs.has(a.description.toLowerCase())) {
        a.status = 'fixed';
      }
    }

    // Also mark resolved in PREVIOUS assignments — this is the correct attribution
    // because resolved findings were assigned to agents in the PREVIOUS iteration
    if (previousAssignments) {
      for (const a of previousAssignments) {
        if (resolvedDescs.has(a.description.toLowerCase())) {
          a.status = 'fixed';
        }
      }
    }
  }

  // Build per-agent performance
  // Merge current + previous assignments so resolved findings from previous iteration
  // are correctly attributed to the agents that worked on them
  const mergedAssignments = [...assignments];
  if (previousAssignments) {
    for (const pa of previousAssignments) {
      if (!mergedAssignments.some((a) => a.finding_id === pa.finding_id)) {
        mergedAssignments.push(pa);
      }
    }
  }
  const agentGroups = groupByAgent(mergedAssignments);
  const agentPerformance: AgentPerformance[] = [];

  for (const [agentId, agentFindings] of Object.entries(agentGroups)) {
    const fixed = agentFindings.filter((f) => f.status === 'fixed').length;

    // Get category scores relevant to this agent
    const catScores: Record<string, number> = {};
    for (const [catId, agents] of Object.entries(CATEGORY_AGENT_MAP)) {
      if (agents.includes(agentId)) {
        const cat = currentResult.categories.find((c) => c.id === catId);
        if (cat) {
          catScores[catId] = cat.score;
        }
      }
    }

    // Compute score delta from previous
    let scoreDelta = 0;
    if (previousResult) {
      const prevCatScores = Object.keys(catScores).map((id) => {
        const pc = previousResult.categories.find((c) => c.id === id);
        return pc ? pc.score : 0;
      });
      const currCatScores = Object.values(catScores);
      const prevAvg =
        prevCatScores.length > 0
          ? prevCatScores.reduce((s, v) => s + v, 0) / prevCatScores.length
          : 0;
      const currAvg =
        currCatScores.length > 0
          ? currCatScores.reduce((s, v) => s + v, 0) / currCatScores.length
          : 0;
      scoreDelta = Math.round((currAvg - prevAvg) * 100) / 100;
    }

    agentPerformance.push({
      agent_id: agentId,
      iterations: [
        {
          iteration,
          findings_assigned: agentFindings.length,
          findings_resolved: fixed,
          category_scores: catScores,
          score_delta: scoreDelta,
        },
      ],
    });
  }

  const overallDelta = previousResult
    ? Math.round(
        (currentResult.overall_score - previousResult.overall_score) * 100
      ) / 100
    : 0;

  return {
    iteration,
    evaluation_result: currentResult,
    finding_assignments: assignments,
    agent_performance: agentPerformance,
    score_delta: overallDelta,
    new_findings: diff?.new_findings.length ?? currentResult.findings.length,
    resolved_findings: diff?.resolved.length ?? 0,
  };
}

/**
 * Persist agent performance as a structured memory fact.
 */
export function trackAgentPerformance(
  agentId: string,
  report: IterationReport,
  cilId: string
): void {
  const perf = report.agent_performance.find((p) => p.agent_id === agentId);
  if (!perf || perf.iterations.length === 0) {
    return;
  }

  const latest = perf.iterations[perf.iterations.length - 1]!;
  const resolutionRate =
    latest.findings_assigned > 0
      ? Math.round((latest.findings_resolved / latest.findings_assigned) * 100)
      : 0;

  writeFact({
    content:
      `[CIL ${cilId}] Agent ${agentId} iteration ${report.iteration}: ` +
      `${latest.findings_assigned} findings assigned, ${latest.findings_resolved} resolved (${resolutionRate}%), ` +
      `score delta ${latest.score_delta >= 0 ? '+' : ''}${latest.score_delta}`,
    section: 'Agent System',
    tags: ['agent', 'performance', agentId],
    type: 'discovery',
    confidence: 0.9,
  });
}

// ─── Feedback Context Builder ────────────────────────────────────────────────

/**
 * Build a context block that gets injected into an agent's prompt.
 * Contains the agent's past performance + unresolved findings in their domain.
 */
export function buildAgentFeedbackContext(
  agentId: string,
  history: IterationReport[]
): string {
  if (history.length === 0) {
    return '';
  }

  const parts: string[] = [];
  parts.push('## Performance Feedback from Previous Iterations\n');

  // Gather per-iteration stats for this agent
  const agentHistory: Array<{
    iteration: number;
    assigned: number;
    resolved: number;
    delta: number;
  }> = [];
  for (const report of history) {
    const perf = report.agent_performance.find((p) => p.agent_id === agentId);
    if (perf && perf.iterations.length > 0) {
      const it = perf.iterations[0]!;
      agentHistory.push({
        iteration: report.iteration,
        assigned: it.findings_assigned,
        resolved: it.findings_resolved,
        delta: it.score_delta,
      });
    }
  }

  if (agentHistory.length > 0) {
    parts.push('### Your Track Record');
    for (const h of agentHistory) {
      const rate =
        h.assigned > 0 ? Math.round((h.resolved / h.assigned) * 100) : 0;
      parts.push(
        `- Iteration ${h.iteration}: ${h.resolved}/${h.assigned} findings resolved (${rate}%), score ${h.delta >= 0 ? '+' : ''}${h.delta}`
      );
    }
    parts.push('');
  }

  // Unresolved findings from the latest iteration
  const latest = history[history.length - 1]!;
  const unresolvedForAgent = latest.finding_assignments.filter(
    (a) =>
      a.agent_id === agentId &&
      (a.status === 'assigned' || a.status === 'unresolved')
  );

  if (unresolvedForAgent.length > 0) {
    parts.push('### Unresolved Findings in Your Domain\n');
    parts.push(
      'These findings were NOT fixed in previous iterations. Prioritize them:\n'
    );
    for (const f of unresolvedForAgent.slice(0, 15)) {
      parts.push(`- [${f.severity.toUpperCase()}] ${f.description}`);
      if (f.file) {
        parts.push(`  File: ${f.file}${f.line ? `:${f.line}` : ''}`);
      }
      parts.push(`  Remediation: ${f.remediation}`);
    }
    parts.push('');
  }

  // Also pull historical facts from memory store
  const memFacts = searchFacts(agentId, {
    section: 'Agent System',
    tags: ['performance'],
    limit: 5,
  });
  if (memFacts.length > 0) {
    parts.push('### Historical Performance Notes\n');
    for (const f of memFacts) {
      parts.push(`- ${f.content}`);
    }
  }

  return parts.join('\n');
}

/**
 * Build feedback context for an agent using only the memory store (for non-CIL runs).
 * Used by the executor to inject feedback even during regular project execution.
 */
export function buildAgentFeedbackFromMemory(agentId: string): string {
  const facts = searchFacts(agentId, {
    section: 'Agent System',
    tags: ['performance'],
    limit: 10,
  });
  if (facts.length === 0) {
    return '';
  }

  const parts: string[] = ['## Historical Performance Feedback\n'];
  for (const f of facts) {
    parts.push(`- ${f.content}`);
  }
  return parts.join('\n');
}
