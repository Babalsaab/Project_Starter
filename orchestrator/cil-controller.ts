/**
 * Continuous Improvement Loop (CIL) Controller
 *
 * Orchestrates N iterations of:  evaluate → triage → remediate → implement → compare
 *
 * Each iteration:
 *   1. EVALUATE  — Run CTO evaluation suite (shell scripts, 21 categories)
 *   2. TRIAGE    — CEO/CTO prioritize findings, map to agents
 *   3. REMEDIATE — Agents produce detailed fix plans for their assigned findings
 *   4. IMPLEMENT — Code writer applies fixes to actual files (via Claude API)
 *   5. COMPARE   — Diff findings, compute score deltas, update agent feedback
 *
 * State is persisted to YAML after each phase so the loop is pause/resume safe.
 */

import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import {
  mapFindingsToAgents,
  groupByAgent,
  getAssignedAgents,
  diffFindings,
  buildIterationReport,
  buildAgentFeedbackContext,
  trackAgentPerformance,
  type EvaluationResult,
  type Finding,
  type FindingAssignment,
  type IterationReport,
} from './agent-feedback';
import { writeFact } from './memory-bridge';
import { ProviderRegistry, getProviderRegistry } from './providers/index';
import type { LLMProvider } from './providers/base';

// Re-export for external use (e.g., API routes)
export type { EvaluationResult };

// ─── Types ───────────────────────────────────────────────────────────────────

export interface CILConfig {
  codebase_path: string;
  max_iterations: number;
  target_score?: number;
  target_grade?: string;
  evaluation_mode: 'quick' | 'standard' | 'enhanced';
  focus_categories?: string[];
  auto_implement: boolean;
  provider?: string;
  /** Coding backend for applying fixes: claude-api, claude-code, cursor, aider, manual */
  coder?: import('./coders/base').CoderBackend;
}

export type CILPhase =
  | 'evaluate'
  | 'triage'
  | 'remediate'
  | 'implement'
  | 'compare';

export interface PhaseState {
  status: 'pending' | 'running' | 'completed' | 'failed' | 'skipped';
  started_at?: string;
  completed_at?: string;
  error?: string;
}

export interface IterationState {
  iteration: number;
  status: 'pending' | 'running' | 'completed' | 'failed';
  phases: Record<CILPhase, PhaseState>;
  evaluation_run_id?: string;
  overall_score?: number;
  grade?: string;
  findings_total?: number;
  findings_resolved?: number;
  findings_new?: number;
  score_delta?: number;
  started_at?: string;
  completed_at?: string;
  artifacts_dir?: string;
  assigned_agents?: string[];
}

export interface CILSummary {
  total_iterations: number;
  initial_score: number;
  final_score: number;
  total_improvement: number;
  initial_grade: string;
  final_grade: string;
  total_findings_resolved: number;
  total_findings_remaining: number;
  best_iteration: number;
  stop_reason:
    | 'target_reached'
    | 'max_iterations'
    | 'no_improvement'
    | 'failed'
    | 'paused'
    | 'no_api_key';
  agent_contributions: Array<{
    agent_id: string;
    findings_resolved: number;
    categories_improved: string[];
  }>;
}

export interface CILState {
  id: string;
  config: CILConfig;
  status: 'running' | 'paused' | 'completed' | 'failed';
  current_iteration: number;
  current_phase: CILPhase;
  iterations: IterationState[];
  iteration_reports: IterationReport[];
  started_at: string;
  updated_at: string;
  summary?: CILSummary;
  /** Whether LLM provider returned placeholder output (no API key configured) */
  placeholder_mode?: boolean;
}

export type ProgressCallback = (state: CILState, message: string) => void;

// ─── Constants ───────────────────────────────────────────────────────────────

const ROOT = path.resolve(__dirname, '..');
const CIL_DIR = path.join(ROOT, 'config', 'project-sessions');
const ARTIFACTS_DIR = path.join(ROOT, 'runs', 'artifacts');

const GRADE_SCORES: Record<string, number> = {
  'A+': 9.5,
  A: 9.0,
  'A-': 8.5,
  'B+': 8.0,
  B: 7.5,
  'B-': 7.0,
  'C+': 6.5,
  C: 6.0,
  'C-': 5.5,
  D: 5.0,
  F: 0,
};

const ALL_PHASES: CILPhase[] = [
  'evaluate',
  'triage',
  'remediate',
  'implement',
  'compare',
];

// ─── State Persistence ───────────────────────────────────────────────────────

function cilDir(cilId: string): string {
  return path.join(CIL_DIR, cilId);
}

function cilStatePath(cilId: string): string {
  return path.join(cilDir(cilId), 'cil-state.yaml');
}

export function saveCILState(state: CILState): void {
  const dir = cilDir(state.id);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  state.updated_at = new Date().toISOString();
  // Don't serialize full evaluation results into the state YAML (too large)
  // Keep them in separate artifact files instead
  const stateForDisk = { ...state, iteration_reports: [] };
  fs.writeFileSync(
    cilStatePath(state.id),
    yaml.dump(stateForDisk, { lineWidth: -1 }),
    'utf-8'
  );
}

export function loadCILState(cilId: string): CILState | null {
  const p = cilStatePath(cilId);
  if (!fs.existsSync(p)) {
    return null;
  }
  try {
    return yaml.load(fs.readFileSync(p, 'utf-8')) as CILState;
  } catch {
    return null;
  }
}

export function listCILRuns(): Array<{
  id: string;
  status: string;
  current_iteration: number;
  config: CILConfig;
  started_at: string;
  updated_at: string;
  summary?: CILSummary;
}> {
  if (!fs.existsSync(CIL_DIR)) {
    return [];
  }
  return fs
    .readdirSync(CIL_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory() && d.name.startsWith('cil_'))
    .map((d) => {
      const state = loadCILState(d.name);
      if (!state) {
        return null;
      }
      return {
        id: state.id,
        status: state.status,
        current_iteration: state.current_iteration,
        config: state.config,
        started_at: state.started_at,
        updated_at: state.updated_at,
        summary: state.summary,
      };
    })
    .filter(Boolean) as any[];
}

// ─── Artifact Management ─────────────────────────────────────────────────────

function iterationArtifactDir(cilId: string, iteration: number): string {
  const dir = path.join(ARTIFACTS_DIR, cilId, `iteration-${iteration}`);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  return dir;
}

function saveIterationArtifact(
  cilId: string,
  iteration: number,
  filename: string,
  content: string
): void {
  const dir = iterationArtifactDir(cilId, iteration);
  fs.writeFileSync(path.join(dir, filename), content, 'utf-8');
}

function loadIterationArtifact(
  cilId: string,
  iteration: number,
  filename: string
): string | null {
  const filepath = path.join(iterationArtifactDir(cilId, iteration), filename);
  if (!fs.existsSync(filepath)) {
    return null;
  }
  return fs.readFileSync(filepath, 'utf-8');
}

// ─── Provider Setup ──────────────────────────────────────────────────────────

let _provider: LLMProvider | null = null;
let _providerIsPlaceholder = false;
let _llmCallSucceeded = false; // Track if ANY LLM call has succeeded (to avoid false positive placeholder_mode)
let _claudeCodeAvailable: boolean | null = null; // cached detection
let _coderBackend: import('./coders/base').CoderBackend | undefined;

/** Set the coder backend so callLLM knows to use Claude Code CLI when appropriate */
function setCoderBackend(
  backend: import('./coders/base').CoderBackend | undefined
) {
  _coderBackend = backend;
}

async function getProvider(): Promise<LLMProvider> {
  if (_provider) {
    return _provider;
  }
  const registry = await getProviderRegistry();
  _provider = registry.getDefaultProvider();
  return _provider;
}

/** Build a clean env for Claude Code CLI — strip nesting protection + bad API keys */
function buildClaudeChildEnv(): Record<string, string | undefined> {
  const childEnv = { ...process.env };
  // Remove nesting protection flags so `claude` CLI doesn't refuse to run
  delete childEnv['CLAUDECODE'];
  delete childEnv['CLAUDE_CODE_ENTRYPOINT'];
  delete childEnv['CLAUDE_CODE_ENTRY_POINT'];
  // Remove ANTHROPIC_API_KEY so Claude Code uses its own OAuth credentials from disk
  // (~/.claude/.credentials.json) instead of a potentially invalid/placeholder key
  // from .env.local or the parent process
  delete childEnv['ANTHROPIC_API_KEY'];
  return childEnv;
}

/** Check if Claude Code CLI is installed and authenticated */
async function isClaudeCodeAvailable(): Promise<boolean> {
  if (_claudeCodeAvailable !== null) {
    return _claudeCodeAvailable;
  }
  const { spawn } = await import('child_process');
  const childEnv = buildClaudeChildEnv();
  return new Promise((resolve) => {
    const proc = spawn('claude', ['--version'], {
      shell: true,
      timeout: 10000,
      env: childEnv,
    });
    let output = '';
    let stderr = '';
    proc.stdout?.on('data', (d: Buffer) => {
      output += d.toString();
    });
    proc.stderr?.on('data', (d: Buffer) => {
      stderr += d.toString();
    });
    proc.on('close', (code: number | null) => {
      _claudeCodeAvailable = code === 0 && output.trim().length > 0;
      if (_claudeCodeAvailable) {
        console.log(`[CIL] Claude Code CLI detected: ${output.trim()}`);
      } else {
        console.warn(
          `[CIL] Claude Code CLI check failed: code=${code}, stdout="${output.trim()}", stderr="${stderr.trim()}"`
        );
      }
      resolve(_claudeCodeAvailable);
    });
    proc.on('error', (err: Error) => {
      console.warn(`[CIL] Claude Code CLI not found: ${err.message}`);
      _claudeCodeAvailable = false;
      resolve(false);
    });
  });
}

/** Call Claude Code CLI with a prompt and return the response text */
async function callClaudeCode(
  systemPrompt: string,
  userContent: string
): Promise<string> {
  const { spawn, execSync } = await import('child_process');
  const prompt = `${systemPrompt}\n\n---\n\n${userContent}`;
  const childEnv = buildClaudeChildEnv();
  const TIMEOUT_MS = 600000; // 10 minutes per LLM call (generating complete files takes time)

  console.log(
    `[CIL] Calling claude --print (prompt length: ${prompt.length} chars, timeout: ${TIMEOUT_MS / 1000}s)`
  );

  return new Promise((resolve, reject) => {
    let settled = false;

    const proc = spawn('claude', ['--print'], {
      shell: true,
      env: childEnv,
    });

    let stdout = '';
    let stderr = '';
    proc.stdout?.on('data', (d: Buffer) => {
      stdout += d.toString();
    });
    proc.stderr?.on('data', (d: Buffer) => {
      stderr += d.toString();
    });

    proc.stdin?.write(prompt);
    proc.stdin?.end();

    // Manual timeout — Node.js spawn timeout doesn't reliably kill process trees on Windows
    const timer = setTimeout(() => {
      if (settled) {
        return;
      }
      settled = true;
      console.warn(
        `[CIL] claude --print timed out after ${TIMEOUT_MS / 1000}s`
      );

      // Collect any partial output before killing
      const partial = stdout.trim() || stderr.trim();
      if (partial.length > 50) {
        console.log(
          `[CIL] Accepting partial output (${partial.length} chars) before timeout kill`
        );
        resolve(partial);
      } else {
        reject(new Error(`Claude Code timed out after ${TIMEOUT_MS / 1000}s`));
      }

      // Kill the process tree on Windows
      try {
        if (proc.pid) {
          if (process.platform === 'win32') {
            execSync(`taskkill /F /T /PID ${proc.pid}`, { stdio: 'ignore' });
          } else {
            process.kill(-proc.pid, 'SIGTERM');
          }
        }
      } catch {
        /* process may have already exited */
      }
    }, TIMEOUT_MS);

    proc.on('close', (code: number | null) => {
      clearTimeout(timer);
      if (settled) {
        return;
      }
      settled = true;

      // Accept output from stdout OR stderr — `claude --print` sometimes puts
      // valid responses in stderr when it encounters permission issues (code=null)
      const output = stdout.trim() || stderr.trim();

      if (output.length > 50) {
        // Valid response — even if exit code is non-zero or null, Claude still
        // produced meaningful output (e.g. remediation plan text)
        console.log(
          `[CIL] claude --print produced output (${output.length} chars, code=${code})`
        );
        resolve(output);
      } else if (code === 0 && stdout.trim().length > 0) {
        console.log(`[CIL] claude --print succeeded (${stdout.length} chars)`);
        resolve(stdout);
      } else {
        const errDetail = stderr || stdout || 'no output';
        console.error(
          `[CIL] claude --print failed: code=${code}, output=${errDetail.slice(0, 300)}`
        );
        reject(
          new Error(
            `Claude Code exited with code ${code}: ${errDetail.slice(0, 300)}`
          )
        );
      }
    });
    proc.on('error', (err: Error) => {
      clearTimeout(timer);
      if (settled) {
        return;
      }
      settled = true;
      console.error(`[CIL] Failed to spawn claude: ${err.message}`);
      reject(new Error(`Failed to launch Claude Code: ${err.message}`));
    });
  });
}

/**
 * Call an LLM to generate text.
 *
 * Priority when user selected claude-code backend:
 *   1. Claude Code CLI (`claude --print`) — uses disk-based auth
 *   2. Anthropic API (if API key configured)
 *   3. Placeholder fallback
 *
 * Priority otherwise:
 *   1. Anthropic API (if configured)
 *   2. Claude Code CLI (if available — e.g., user is running inside Claude Code)
 *   3. Placeholder fallback
 */
async function callLLM(
  systemPrompt: string,
  userContent: string,
  maxTokens = 4096
): Promise<string> {
  // Try Claude Code CLI first if user selected it or if it's available
  // This avoids the unnecessary Anthropic API round-trip when no API key is set
  const shouldTryClaudeCodeFirst =
    _coderBackend === 'claude-code' || !process.env['ANTHROPIC_API_KEY'];
  let triedClaudeCode = false;

  if (shouldTryClaudeCodeFirst) {
    const ccAvailable = await isClaudeCodeAvailable();
    if (ccAvailable) {
      triedClaudeCode = true;
      try {
        console.log('[CIL] Using Claude Code CLI for LLM call');
        const result = await callClaudeCode(systemPrompt, userContent);
        _llmCallSucceeded = true;
        _providerIsPlaceholder = false; // Reset — this call succeeded
        return result;
      } catch (err) {
        console.warn(`[CIL] Claude Code CLI failed: ${(err as Error).message}`);
        // Fall through to try Anthropic API
      }
    }
  }

  // Try Anthropic API
  const provider = await getProvider();
  const result = await provider.complete({
    systemPrompt,
    messages: [{ role: 'user', content: userContent }],
    maxTokens,
  });

  // If API key is configured and returned real output, use it
  if (!result.is_fallback || result.model_used !== 'placeholder') {
    _llmCallSucceeded = true;
    return result.text;
  }

  // API returned placeholder — try Claude Code CLI as last resort (if not already tried)
  if (!triedClaudeCode) {
    const ccAvailable = await isClaudeCodeAvailable();
    if (ccAvailable) {
      try {
        console.log('[CIL] Using Claude Code CLI as fallback (no API key)');
        const ccResult = await callClaudeCode(systemPrompt, userContent);
        _llmCallSucceeded = true;
        _providerIsPlaceholder = false; // Reset — this call succeeded
        return ccResult;
      } catch (err) {
        console.warn(
          `[CIL] Claude Code CLI fallback failed: ${(err as Error).message}`
        );
      }
    }
  }

  // No LLM available for this call
  if (!_llmCallSucceeded) {
    // Only mark as permanently placeholder if NO call has EVER succeeded
    _providerIsPlaceholder = true;
    console.error(
      '[CIL] No LLM backend available. Neither Anthropic API key nor Claude Code CLI work.'
    );
  } else {
    console.warn(
      '[CIL] This LLM call failed, but previous calls succeeded — not marking as placeholder mode.'
    );
  }
  return result.text;
}

function isPlaceholderMode(): boolean {
  return _providerIsPlaceholder;
}

// ─── Phase Implementations ───────────────────────────────────────────────────

/**
 * PHASE 1: EVALUATE — Run CTO evaluation suite on the codebase.
 * Uses filesystem polling (same pattern as the web evaluation runner).
 */
async function runEvaluationPhase(
  codebasePath: string,
  mode: string
): Promise<EvaluationResult> {
  const absPath = path.resolve(codebasePath);
  const evalDir = path.join(absPath, '.cto-evaluation');

  // Import startEvaluation dynamically (it lives under src/ which uses Next.js tsconfig)
  // Instead, call the shell scripts directly — same approach as the web runner.
  const { execSync, spawn } = await import('child_process');
  const scriptPath = path.join(
    ROOT,
    'tools',
    'cto-evaluation',
    'scripts',
    'run-full-evaluation.sh'
  );

  // Find bash
  let bashPath = '/bin/bash';
  if (process.platform === 'win32') {
    const gitBash = 'C:\\Program Files\\Git\\bin\\bash.exe';
    if (fs.existsSync(gitBash)) {
      bashPath = gitBash;
    }
  }

  // Ensure jq is available
  const toolsBin = path.join(ROOT, 'tools');
  const toolsUnix = toolsBin
    .replace(/\\/g, '/')
    .replace(/^([A-Z]):/, (_, d: string) => `/${d.toLowerCase()}`);
  const childPath = `${toolsUnix}:${process.env['PATH'] ?? ''}`;

  const toUnixPath = (p: string) => p.replace(/\\/g, '/');

  return new Promise((resolve, reject) => {
    const args = [
      scriptPath,
      toUnixPath(absPath),
      '--output-dir',
      toUnixPath(evalDir),
    ];
    if (mode === 'quick') {
      args.push('--quick');
    }

    const proc = spawn(bashPath, args, {
      cwd: path.join(ROOT, 'tools', 'cto-evaluation'),
      env: {
        ...process.env,
        PATH: childPath,
        CTO_MAX_PARALLEL: '6',
        CTO_SCRIPT_TIMEOUT: '480',
      },
      stdio: 'ignore',
    });

    proc.on('close', (code) => {
      // Find the latest evaluation result directory
      if (!fs.existsSync(evalDir)) {
        return reject(new Error('Evaluation directory not created'));
      }

      const runs = fs
        .readdirSync(evalDir, { withFileTypes: true })
        .filter((d) => d.isDirectory() && d.name.startsWith('evaluation_'))
        .map((d) => d.name)
        .sort()
        .reverse();

      if (runs.length === 0) {
        return reject(new Error('No evaluation run found'));
      }

      const latestDir = path.join(evalDir, runs[0]!);
      const reportPath = path.join(latestDir, 'report.json');

      if (fs.existsSync(reportPath)) {
        try {
          const result = JSON.parse(
            fs.readFileSync(reportPath, 'utf-8')
          ) as EvaluationResult;
          return resolve(result);
        } catch (e) {
          // Fall through to build from category files
        }
      }

      // Build result from individual category JSONs
      const result = buildResultFromCategoryFiles(latestDir, absPath);
      resolve(result);
    });

    proc.on('error', (err) => {
      reject(new Error(`Evaluation script failed: ${err.message}`));
    });
  });
}

/** Build an EvaluationResult from individual category JSON files. */
function buildResultFromCategoryFiles(
  runDir: string,
  codebasePath: string
): EvaluationResult {
  const categories: any[] = [];
  const findings: Finding[] = [];
  let totalWeightedScore = 0;
  let totalWeight = 0;

  const WEIGHTS: Record<
    string,
    { name: string; weight: number; script: string }
  > = {
    code_quality: {
      name: 'Code Quality',
      weight: 8,
      script: '01-code-quality',
    },
    architecture: {
      name: 'Architecture',
      weight: 10,
      script: '02-architecture',
    },
    security: { name: 'Security', weight: 12, script: '03-security' },
    performance: { name: 'Performance', weight: 8, script: '04-performance' },
    testing: { name: 'Testing', weight: 8, script: '05-testing' },
    devops: { name: 'DevOps', weight: 6, script: '06-devops' },
    scalability: { name: 'Scalability', weight: 8, script: '07-scalability' },
    reliability: { name: 'Reliability', weight: 8, script: '08-reliability' },
    data_architecture: {
      name: 'Data Architecture',
      weight: 5,
      script: '09-data',
    },
    api_design: { name: 'API Design', weight: 5, script: '10-api' },
    observability: {
      name: 'Observability',
      weight: 4,
      script: '11-observability',
    },
    frontend: { name: 'Frontend', weight: 4, script: '12-frontend' },
    backend: { name: 'Backend', weight: 5, script: '13-backend' },
    mobile: { name: 'Mobile', weight: 2, script: '14-mobile' },
    documentation: {
      name: 'Documentation',
      weight: 2,
      script: '15-documentation',
    },
    developer_experience: {
      name: 'Developer Experience',
      weight: 2,
      script: '16-developer-experience',
    },
    maintainability: {
      name: 'Maintainability',
      weight: 5,
      script: '17-maintainability',
    },
    compliance: { name: 'Compliance', weight: 4, script: '18-compliance' },
    cost_efficiency: {
      name: 'Cost Efficiency',
      weight: 2,
      script: '19-cost-efficiency',
    },
    innovation: { name: 'Innovation', weight: 2, script: '20-innovation' },
    uiux_consistency: {
      name: 'UI/UX Consistency',
      weight: 4,
      script: '21-uiux-audit',
    },
  };

  for (const [catId, meta] of Object.entries(WEIGHTS)) {
    const possibleFiles = [
      path.join(runDir, `${meta.script}.json`),
      path.join(runDir, `${catId}.json`),
    ];

    let catData: any = null;
    for (const f of possibleFiles) {
      if (fs.existsSync(f)) {
        try {
          catData = JSON.parse(fs.readFileSync(f, 'utf-8'));
          break;
        } catch {
          /* skip */
        }
      }
    }

    if (catData) {
      const score = catData.score ?? 5.0;
      const catFindings = Array.isArray(catData.findings)
        ? catData.findings
        : [];
      categories.push({
        id: catId,
        name: meta.name,
        weight: meta.weight,
        score,
        grade: scoreToGrade(score),
        findings_count: catFindings.length,
      });
      totalWeightedScore += score * meta.weight;
      totalWeight += meta.weight;
      for (const f of catFindings) {
        findings.push({
          id: findings.length + 1,
          category: meta.name,
          severity: f.severity ?? 'medium',
          description: f.description ?? f.message ?? 'Unknown finding',
          file: f.file,
          line: f.line,
          remediation: f.remediation ?? 'Review and address this finding',
        });
      }
    }
  }

  const overallScore =
    totalWeight > 0
      ? Math.round((totalWeightedScore / totalWeight) * 100) / 100
      : 0;

  return {
    overall_score: overallScore,
    grade: scoreToGrade(overallScore),
    risk_level:
      overallScore >= 8
        ? 'Low'
        : overallScore >= 6
          ? 'Medium'
          : overallScore >= 5
            ? 'High'
            : 'Critical',
    categories,
    findings: findings.sort(
      (a, b) => severityOrder(a.severity) - severityOrder(b.severity)
    ),
    timestamp: new Date().toISOString(),
    codebase_path: codebasePath,
    mode: 'standard',
    languages_detected: [],
    frameworks_detected: [],
  };
}

function scoreToGrade(score: number): string {
  if (score >= 9.5) {
    return 'A+';
  }
  if (score >= 9.0) {
    return 'A';
  }
  if (score >= 8.5) {
    return 'A-';
  }
  if (score >= 8.0) {
    return 'B+';
  }
  if (score >= 7.5) {
    return 'B';
  }
  if (score >= 7.0) {
    return 'B-';
  }
  if (score >= 6.5) {
    return 'C+';
  }
  if (score >= 6.0) {
    return 'C';
  }
  if (score >= 5.5) {
    return 'C-';
  }
  if (score >= 5.0) {
    return 'D';
  }
  return 'F';
}

function severityOrder(s: string): number {
  return { critical: 0, high: 1, medium: 2, low: 3 }[s] ?? 3;
}

/**
 * PHASE 2: TRIAGE — CEO/CTO analyze findings, prioritize, and assign to agents.
 */
async function runTriagePhase(
  result: EvaluationResult,
  previousReport: IterationReport | null,
  config: CILConfig
): Promise<FindingAssignment[]> {
  // Map findings to agents using the category→agent mapping
  let assignments = mapFindingsToAgents(result);

  // If focus_categories specified, filter to those
  if (config.focus_categories && config.focus_categories.length > 0) {
    const focusSet = new Set(config.focus_categories);
    const catIdFromName = (name: string) =>
      name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '_')
        .replace(/(^_|_$)/g, '');
    assignments = assignments.filter((a) =>
      focusSet.has(catIdFromName(a.category))
    );
  }

  // Sort by severity (critical first)
  assignments.sort(
    (a, b) => severityOrder(a.severity) - severityOrder(b.severity)
  );

  // Mark previously unresolved findings
  if (previousReport) {
    const prevDescs = new Set(
      previousReport.finding_assignments
        .filter((a) => a.status !== 'fixed')
        .map((a) => a.description.toLowerCase().trim())
    );
    for (const a of assignments) {
      if (prevDescs.has(a.description.toLowerCase().trim())) {
        a.status = 'unresolved'; // was assigned before and not fixed
      }
    }
  }

  return assignments;
}

/**
 * PHASE 3: REMEDIATE — Invoke specialist agents to produce fix plans.
 * Each agent receives their assigned findings and produces a remediation artifact.
 */
async function runRemediatePhase(
  assignments: FindingAssignment[],
  codebasePath: string,
  cilId: string,
  iteration: number,
  history: IterationReport[]
): Promise<Record<string, string>> {
  const grouped = groupByAgent(assignments);
  const results: Record<string, string> = {};

  for (const [agentId, agentFindings] of Object.entries(grouped)) {
    // Build agent context with feedback from previous iterations
    const feedbackCtx = buildAgentFeedbackContext(agentId, history);

    const findingsList = agentFindings
      .map(
        (f, i) =>
          `${i + 1}. [${f.severity.toUpperCase()}] ${f.description}\n   File: ${f.file ?? 'N/A'}${f.line ? `:${f.line}` : ''}\n   Remediation: ${f.remediation}`
      )
      .join('\n\n');

    const systemPrompt = `You are a specialist ${agentId.replace(/_/g, ' ')} performing code remediation.
Your task is to analyze the findings below and produce EXACT code changes that fix each issue.

CRITICAL: For EVERY file you want to create or modify, output it in this EXACT format:

===FILE: path/to/file.ts===
\`\`\`typescript
// The COMPLETE content of the file
\`\`\`
===END FILE===

RULES:
- Output the COMPLETE file content (not just diffs or snippets)
- Use relative paths from the codebase root
- You MAY create new files (e.g., test files, config files) when needed
- Focus on the highest-severity findings first
- Before each ===FILE:=== block, briefly explain what you're changing and why
- If a finding requires creating a test file, create it with real test implementations
${feedbackCtx}`;

    const userPrompt = `## Codebase: ${codebasePath}
## Iteration: ${iteration}
## Your Assigned Findings (${agentFindings.length}):

${findingsList}

Produce the EXACT file changes using the ===FILE: path=== format. Output complete file content for each file.`;

    try {
      const response = await callLLM(systemPrompt, userPrompt, 16384);
      results[agentId] = response;
      saveIterationArtifact(
        cilId,
        iteration,
        `${agentId}-remediation.md`,
        response
      );
    } catch (err) {
      results[agentId] =
        `ERROR: Failed to get remediation from ${agentId}: ${(err as Error).message}`;
      saveIterationArtifact(
        cilId,
        iteration,
        `${agentId}-remediation.md`,
        results[agentId]!
      );
    }
  }

  return results;
}

/**
 * PHASE 4: IMPLEMENT — Apply code changes using the configured Coder backend.
 * Supports: claude-api (default), claude-code, cursor, aider, manual.
 */
async function runImplementPhase(
  remediationPlans: Record<string, string>,
  codebasePath: string,
  cilId: string,
  iteration: number,
  coderBackend?: import('./coders/base').CoderBackend,
  findings?: Finding[]
): Promise<{ files_modified: string[]; changes_summary: string }> {
  const { getCoder, getDefaultCoderConfig } =
    require('./coders/index') as typeof import('./coders/index');
  // Use the configured backend, or the global _coderBackend (which may have been auto-upgraded)
  const backend = coderBackend || _coderBackend || 'claude-api';
  const coder = getCoder(backend);
  const coderConfig = getDefaultCoderConfig(backend);

  // Map evaluation findings to the format expected by CoderRequest
  const coderFindings = findings?.map((f) => ({
    id: typeof f.id === 'number' ? f.id : 0,
    category: f.category || '',
    severity: f.severity || '',
    description: f.description || '',
    file: f.file,
    remediation: f.remediation || '',
  }));

  const result = await coder.applyFixes(
    {
      codebase_path: codebasePath,
      remediation_plans: remediationPlans,
      cil_id: cilId,
      iteration,
      findings: coderFindings,
    },
    coderConfig
  );

  // Save artifacts
  saveIterationArtifact(
    cilId,
    iteration,
    'implementation-output.md',
    `# Implementation (${coder.displayName})\n\nBackend: ${backend}\nExecuted: ${result.executed}\nDuration: ${result.duration_ms}ms\n\n${result.changes_summary}`
  );
  saveIterationArtifact(
    cilId,
    iteration,
    'changes-summary.md',
    result.changes_summary
  );

  if (result.warnings.length > 0) {
    saveIterationArtifact(
      cilId,
      iteration,
      'implementation-warnings.md',
      result.warnings.map((w) => `- ${w}`).join('\n')
    );
  }

  // Detect failure mode — only mark as placeholder if no LLM call has ever succeeded
  if (!result.executed && !_llmCallSucceeded) {
    _providerIsPlaceholder = true;
  }

  return {
    files_modified: result.files_modified,
    changes_summary: result.changes_summary,
  };
}

// ─── Main Loop ───────────────────────────────────────────────────────────────

function createInitialState(config: CILConfig, assignedId?: string): CILState {
  const id =
    assignedId ||
    `cil_${new Date()
      .toISOString()
      .replace(/[-:.TZ]/g, '')
      .slice(0, 14)}`;
  const iterations: IterationState[] = [];

  for (let i = 1; i <= config.max_iterations; i++) {
    iterations.push({
      iteration: i,
      status: 'pending',
      phases: {
        evaluate: { status: 'pending' },
        triage: { status: 'pending' },
        remediate: { status: 'pending' },
        implement: { status: 'pending' },
        compare: { status: 'pending' },
      },
    });
  }

  return {
    id,
    config,
    status: 'running',
    current_iteration: 0,
    current_phase: 'evaluate',
    iterations,
    iteration_reports: [],
    started_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };
}

function updatePhase(
  state: CILState,
  phase: CILPhase,
  update: Partial<PhaseState>
): void {
  const it = state.iterations[state.current_iteration - 1];
  if (it) {
    Object.assign(it.phases[phase], update);
  }
  state.current_phase = phase;
}

/**
 * Start the Continuous Improvement Loop.
 * @param assignedId Optional pre-assigned CIL ID (used when spawned from API route)
 */
export async function startCIL(
  config: CILConfig,
  onProgress?: ProgressCallback,
  assignedId?: string
): Promise<CILState> {
  const state = createInitialState(config, assignedId);
  const log = (msg: string) => {
    console.log(`  [CIL] ${msg}`);
    onProgress?.(state, msg);
  };

  // Pre-flight: check LLM availability and auto-select the best backend
  const hasApiKey = !!process.env['ANTHROPIC_API_KEY'];
  const ccAvail = await isClaudeCodeAvailable();

  // Auto-upgrade to claude-code if no API key but Claude Code CLI is available
  if (!config.coder || config.coder === 'claude-api') {
    if (!hasApiKey && ccAvail) {
      log(
        'Auto-selecting claude-code backend (no API key, but Claude Code CLI is available)'
      );
      config.coder = 'claude-code';
      state.config.coder = 'claude-code';
    }
  }

  // Tell callLLM which coder backend is selected
  setCoderBackend(config.coder);

  log(
    `Starting CIL: ${config.max_iterations} iterations on ${config.codebase_path}`
  );
  log(`Coder backend: ${config.coder || 'claude-api (default)'}`);
  log(`Anthropic API key: ${hasApiKey ? 'configured' : 'not set'}`);
  log(`Claude Code CLI: ${ccAvail ? 'available' : 'NOT available'}`);

  if (!ccAvail && !hasApiKey) {
    log(
      'WARNING: No LLM backend available! Neither ANTHROPIC_API_KEY nor Claude Code CLI found.'
    );
    log(
      '  Evaluation results will be real, but remediation/implementation will be placeholders.'
    );
  }

  // Log environment for diagnostics
  log(`CLAUDECODE env: ${process.env['CLAUDECODE'] ?? '(not set)'}`);
  log(
    `CLAUDE_CODE_ENTRYPOINT env: ${process.env['CLAUDE_CODE_ENTRYPOINT'] ?? '(not set)'}`
  );

  saveCILState(state);

  let previousResult: EvaluationResult | null = null;
  let previousReport: IterationReport | null = null;

  for (let i = 1; i <= config.max_iterations; i++) {
    state.current_iteration = i;
    const iterState = state.iterations[i - 1]!;
    iterState.status = 'running';
    iterState.started_at = new Date().toISOString();
    iterState.artifacts_dir = iterationArtifactDir(state.id, i);
    saveCILState(state);

    log(`\n━━━ Iteration ${i}/${config.max_iterations} ━━━`);

    try {
      // ─── PHASE 1: EVALUATE ───
      updatePhase(state, 'evaluate', {
        status: 'running',
        started_at: new Date().toISOString(),
      });
      saveCILState(state);
      log('Phase 1/5: Running CTO Evaluation...');

      const evalResult = await runEvaluationPhase(
        config.codebase_path,
        config.evaluation_mode
      );
      iterState.overall_score = evalResult.overall_score;
      iterState.grade = evalResult.grade;
      iterState.findings_total = evalResult.findings.length;
      saveIterationArtifact(
        state.id,
        i,
        'evaluation-result.json',
        JSON.stringify(evalResult, null, 2)
      );

      updatePhase(state, 'evaluate', {
        status: 'completed',
        completed_at: new Date().toISOString(),
      });
      saveCILState(state);
      log(
        `  Score: ${evalResult.overall_score}/10 (${evalResult.grade}), ${evalResult.findings.length} findings`
      );

      // Check early stop: target reached
      if (
        config.target_score &&
        evalResult.overall_score >= config.target_score
      ) {
        log(`Target score ${config.target_score} reached! Stopping.`);
        iterState.status = 'completed';
        iterState.completed_at = new Date().toISOString();
        state.status = 'completed';
        state.summary = buildSummary(state, 'target_reached');
        saveCILState(state);
        break;
      }
      if (
        config.target_grade &&
        GRADE_SCORES[config.target_grade] !== undefined &&
        evalResult.overall_score >= GRADE_SCORES[config.target_grade]!
      ) {
        log(`Target grade ${config.target_grade} reached! Stopping.`);
        iterState.status = 'completed';
        iterState.completed_at = new Date().toISOString();
        state.status = 'completed';
        state.summary = buildSummary(state, 'target_reached');
        saveCILState(state);
        break;
      }

      // ─── PHASE 2: TRIAGE ───
      updatePhase(state, 'triage', {
        status: 'running',
        started_at: new Date().toISOString(),
      });
      saveCILState(state);
      log('Phase 2/5: Triaging findings...');

      const assignments = await runTriagePhase(
        evalResult,
        previousReport,
        config
      );
      const assignedAgents = getAssignedAgents(assignments);
      iterState.assigned_agents = assignedAgents;
      saveIterationArtifact(
        state.id,
        i,
        'finding-assignments.json',
        JSON.stringify(assignments, null, 2)
      );

      updatePhase(state, 'triage', {
        status: 'completed',
        completed_at: new Date().toISOString(),
      });
      saveCILState(state);
      log(
        `  ${assignments.length} findings assigned to ${assignedAgents.length} agents: ${assignedAgents.join(', ')}`
      );

      // ─── PHASE 3: REMEDIATE ───
      updatePhase(state, 'remediate', {
        status: 'running',
        started_at: new Date().toISOString(),
      });
      saveCILState(state);
      log('Phase 3/5: Agents producing remediation plans...');

      const remediationPlans = await runRemediatePhase(
        assignments,
        config.codebase_path,
        state.id,
        i,
        state.iteration_reports
      );

      updatePhase(state, 'remediate', {
        status: 'completed',
        completed_at: new Date().toISOString(),
      });

      // Detect placeholder mode (no LLM available — neither API key nor Claude Code CLI)
      if (isPlaceholderMode() && !state.placeholder_mode) {
        state.placeholder_mode = true;
        log('  ⚠ WARNING: No LLM backend available for generating fixes.');
        log('    Option 1: Set ANTHROPIC_API_KEY in .env.local');
        log(
          '    Option 2: Run from within Claude Code (claude --print must be available)'
        );
        log(
          '    Evaluation results are real, but remediation/implementation are placeholders.'
        );
      }

      saveCILState(state);
      log(
        `  ${Object.keys(remediationPlans).length} agents produced fix plans`
      );

      // ─── PHASE 4: IMPLEMENT ───
      if (config.auto_implement) {
        updatePhase(state, 'implement', {
          status: 'running',
          started_at: new Date().toISOString(),
        });
        saveCILState(state);
        log('Phase 4/5: Applying code changes...');

        const implResult = await runImplementPhase(
          remediationPlans,
          config.codebase_path,
          state.id,
          i,
          config.coder,
          evalResult.findings
        );

        updatePhase(state, 'implement', {
          status: 'completed',
          completed_at: new Date().toISOString(),
        });
        saveCILState(state);
        log(`  ${implResult.files_modified.length} files modified`);

        // Early exit: if LLM never succeeded AND zero files modified, stop looping
        // Running additional iterations will produce identical results
        if (
          !_llmCallSucceeded &&
          implResult.files_modified.length === 0 &&
          i > 1
        ) {
          log(
            '  ⚠ No files modified and no API key configured. Stopping loop early.'
          );
          log('    Further iterations would produce identical results.');
          updatePhase(state, 'compare', { status: 'skipped' });
          iterState.status = 'completed';
          iterState.completed_at = new Date().toISOString();
          iterState.score_delta = 0;
          iterState.findings_resolved = 0;
          iterState.findings_new = 0;
          state.status = 'completed';
          state.summary = buildSummary(state, 'no_api_key');
          saveCILState(state);
          break;
        }
      } else {
        updatePhase(state, 'implement', { status: 'skipped' });
        saveCILState(state);
        log('Phase 4/5: Skipped (auto_implement=false)');
      }

      // ─── PHASE 5: COMPARE ───
      updatePhase(state, 'compare', {
        status: 'running',
        started_at: new Date().toISOString(),
      });
      saveCILState(state);
      log('Phase 5/5: Comparing with previous iteration...');

      const report = buildIterationReport(
        i,
        evalResult,
        previousResult,
        assignments,
        previousReport?.finding_assignments
      );
      iterState.findings_resolved = report.resolved_findings;
      iterState.findings_new = report.new_findings;
      iterState.score_delta = report.score_delta;
      state.iteration_reports.push(report);

      // Track agent performance in memory
      for (const agentId of assignedAgents) {
        trackAgentPerformance(agentId, report, state.id);
      }

      saveIterationArtifact(
        state.id,
        i,
        'iteration-report.json',
        JSON.stringify(
          {
            iteration: i,
            score: evalResult.overall_score,
            grade: evalResult.grade,
            findings_total: evalResult.findings.length,
            resolved: report.resolved_findings,
            new_findings: report.new_findings,
            score_delta: report.score_delta,
            agents_involved: assignedAgents,
          },
          null,
          2
        )
      );

      updatePhase(state, 'compare', {
        status: 'completed',
        completed_at: new Date().toISOString(),
      });
      iterState.status = 'completed';
      iterState.completed_at = new Date().toISOString();
      saveCILState(state);

      log(
        `  Resolved: ${report.resolved_findings}, New: ${report.new_findings}, Delta: ${report.score_delta >= 0 ? '+' : ''}${report.score_delta}`
      );

      previousResult = evalResult;
      previousReport = report;
    } catch (err) {
      const errMsg = (err as Error).message;
      log(`  ERROR: ${errMsg}`);
      iterState.status = 'failed';
      const failedPhase = state.current_phase;
      updatePhase(state, failedPhase, {
        status: 'failed',
        error: errMsg,
        completed_at: new Date().toISOString(),
      });
      state.status = 'failed';
      state.summary = buildSummary(state, 'failed');
      saveCILState(state);

      // Log error to memory
      writeFact({
        content: `[CIL ${state.id}] Iteration ${i} failed at ${failedPhase}: ${errMsg}`,
        section: 'Errors & Solutions',
        tags: ['error', 'cil'],
        type: 'error',
        confidence: 1.0,
      });

      break;
    }

    // Check for pause request
    const freshState = loadCILState(state.id);
    if (freshState && freshState.status === 'paused') {
      log('Loop paused by user.');
      state.status = 'paused';
      state.summary = buildSummary(state, 'paused');
      saveCILState(state);
      break;
    }
  }

  // Finalize
  if (state.status === 'running') {
    state.status = 'completed';
    state.summary = buildSummary(
      state,
      state.current_iteration >= config.max_iterations
        ? 'max_iterations'
        : 'no_improvement'
    );
    saveCILState(state);
  }

  // Write final summary to memory
  if (state.summary) {
    writeFact({
      content:
        `[CIL ${state.id}] Completed: ${state.summary.total_iterations} iterations, ` +
        `score ${state.summary.initial_score} → ${state.summary.final_score} ` +
        `(${state.summary.initial_grade} → ${state.summary.final_grade}), ` +
        `${state.summary.total_findings_resolved} findings resolved`,
      section: 'Agent System',
      tags: ['cil', 'performance'],
      type: 'discovery',
      confidence: 1.0,
    });
  }

  log('\n━━━ CIL Complete ━━━');
  log(
    `Final score: ${state.summary?.final_score ?? 'N/A'} (${state.summary?.final_grade ?? 'N/A'})`
  );

  return state;
}

/**
 * Pause a running CIL.
 */
export function pauseCIL(cilId: string): boolean {
  const state = loadCILState(cilId);
  if (!state || state.status !== 'running') {
    return false;
  }
  state.status = 'paused';
  saveCILState(state);
  return true;
}

/**
 * Resume a paused CIL.
 */
export async function resumeCIL(
  cilId: string,
  onProgress?: ProgressCallback
): Promise<CILState | null> {
  const state = loadCILState(cilId);
  if (!state || state.status !== 'paused') {
    return null;
  }
  state.status = 'running';
  saveCILState(state);
  // Continue from current iteration
  return startCIL(state.config, onProgress);
}

// ─── Summary Builder ─────────────────────────────────────────────────────────

function buildSummary(
  state: CILState,
  stopReason: CILSummary['stop_reason']
): CILSummary {
  const completedIterations = state.iterations.filter(
    (it) => it.status === 'completed'
  );
  const first = completedIterations[0];
  const last = completedIterations[completedIterations.length - 1];

  // Aggregate agent contributions
  const agentMap = new Map<
    string,
    { resolved: number; categories: Set<string> }
  >();
  for (const report of state.iteration_reports) {
    for (const perf of report.agent_performance) {
      const existing = agentMap.get(perf.agent_id) ?? {
        resolved: 0,
        categories: new Set<string>(),
      };
      for (const iter of perf.iterations) {
        existing.resolved += iter.findings_resolved;
        for (const cat of Object.keys(iter.category_scores)) {
          existing.categories.add(cat);
        }
      }
      agentMap.set(perf.agent_id, existing);
    }
  }

  return {
    total_iterations: completedIterations.length,
    initial_score: first?.overall_score ?? 0,
    final_score: last?.overall_score ?? 0,
    total_improvement:
      Math.round(
        ((last?.overall_score ?? 0) - (first?.overall_score ?? 0)) * 100
      ) / 100,
    initial_grade: first?.grade ?? 'N/A',
    final_grade: last?.grade ?? 'N/A',
    total_findings_resolved: completedIterations.reduce(
      (sum, it) => sum + (it.findings_resolved ?? 0),
      0
    ),
    total_findings_remaining: last?.findings_total ?? 0,
    best_iteration:
      completedIterations.reduce(
        (best, it) =>
          (it.overall_score ?? 0) > (best.overall_score ?? 0) ? it : best,
        completedIterations[0]!
      )?.iteration ?? 0,
    stop_reason: stopReason,
    agent_contributions: [...agentMap.entries()]
      .map(([agentId, data]) => ({
        agent_id: agentId,
        findings_resolved: data.resolved,
        categories_improved: [...data.categories],
      }))
      .sort((a, b) => b.findings_resolved - a.findings_resolved),
  };
}
