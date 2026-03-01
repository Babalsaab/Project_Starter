/**
 * CTO Evaluation Suite - Web App Bridge
 *
 * Server-side module for the Next.js API routes.
 * Spawns shell scripts, reads results from filesystem, tracks progress.
 */

import {
  existsSync,
  readFileSync,
  readdirSync,
  writeFileSync,
  mkdirSync,
  statSync,
} from 'fs';
import { join, resolve } from 'path';
import { execSync, spawn, type ChildProcess } from 'child_process';

const ROOT = process.cwd();
const EVAL_DIR = join(ROOT, 'tools', 'cto-evaluation');
const SCRIPTS_DIR = join(EVAL_DIR, 'scripts');

// --- Interfaces ---

export interface EvaluationOptions {
  mode?: 'quick' | 'standard' | 'enhanced';
  skipCategories?: string[];
  verbose?: boolean;
  timeout?: number; // minutes
}

export interface CategoryScore {
  id: string;
  name: string;
  weight: number;
  score: number;
  grade: string;
  findings_count: number;
  details: Record<string, unknown>;
}

export interface Finding {
  id: number;
  category: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  description: string;
  file?: string;
  line?: number;
  remediation: string;
}

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

export interface EvaluationSummary {
  run_id: string;
  timestamp: string;
  overall_score: number;
  grade: string;
  mode: string;
  categories_evaluated: number;
  findings_total: number;
  findings_critical: number;
  findings_high: number;
}

export interface EvaluationProgress {
  status: 'running' | 'complete' | 'not_found' | 'error';
  run_id: string;
  completed_count: number;
  total_categories: number;
  percent_complete: number;
  completed_categories: Array<{
    id: string;
    name: string;
    score: number;
    grade: string;
    findings_count: number;
  }>;
  /** Categories currently being evaluated (not yet completed) */
  in_progress_categories?: string[];
  /** Elapsed time in seconds since evaluation started */
  elapsed_seconds?: number;
  result?: EvaluationResult;
  error_message?: string;
}

// --- Grade Mapping ---

const GRADE_MAP: Array<{
  min: number;
  max: number;
  grade: string;
  risk: string;
}> = [
  { min: 9.5, max: 10.0, grade: 'A+', risk: 'Low' },
  { min: 9.0, max: 9.49, grade: 'A', risk: 'Low' },
  { min: 8.5, max: 8.99, grade: 'A-', risk: 'Low' },
  { min: 8.0, max: 8.49, grade: 'B+', risk: 'Low' },
  { min: 7.5, max: 7.99, grade: 'B', risk: 'Medium' },
  { min: 7.0, max: 7.49, grade: 'B-', risk: 'Medium' },
  { min: 6.5, max: 6.99, grade: 'C+', risk: 'Medium' },
  { min: 6.0, max: 6.49, grade: 'C', risk: 'Medium' },
  { min: 5.5, max: 5.99, grade: 'C-', risk: 'High' },
  { min: 5.0, max: 5.49, grade: 'D', risk: 'High' },
  { min: 0, max: 4.99, grade: 'F', risk: 'Critical' },
];

export function scoreToGrade(score: number): { grade: string; risk: string } {
  for (const entry of GRADE_MAP) {
    if (score >= entry.min && score <= entry.max) {
      return { grade: entry.grade, risk: entry.risk };
    }
  }
  return { grade: 'F', risk: 'Critical' };
}

// --- Category Weights ---

export const CATEGORY_WEIGHTS: Record<
  string,
  { name: string; weight: number; script: string }
> = {
  code_quality: { name: 'Code Quality', weight: 8, script: '01-code-quality' },
  architecture: { name: 'Architecture', weight: 10, script: '02-architecture' },
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

// Script-number prefix to category ID mapping (for reading output files)
const SCRIPT_TO_CATEGORY: Record<string, string> = {};
for (const [catId, meta] of Object.entries(CATEGORY_WEIGHTS)) {
  SCRIPT_TO_CATEGORY[meta.script] = catId;
}

// --- Shell Detection ---

function getBashPath(): string {
  if (process.platform === 'win32') {
    const gitBashPaths = [
      'C:\\Program Files\\Git\\bin\\bash.exe',
      'C:\\Program Files (x86)\\Git\\bin\\bash.exe',
    ];
    for (const p of gitBashPaths) {
      if (existsSync(p)) {
        return p;
      }
    }
    try {
      execSync('bash --version', { stdio: 'ignore' });
      return 'bash';
    } catch {
      throw new Error('Git Bash not found. Install Git for Windows.');
    }
  }
  return '/bin/bash';
}

// --- Evaluation Results Directory ---

function listEvaluationRuns(codebasePath: string): string[] {
  const evalDir = join(codebasePath, '.cto-evaluation');
  if (!existsSync(evalDir)) {
    return [];
  }

  return readdirSync(evalDir, { withFileTypes: true })
    .filter((d) => d.isDirectory() && d.name.startsWith('evaluation_'))
    .map((d) => d.name)
    .sort()
    .reverse(); // newest first
}

function parseResultJson(jsonPath: string): EvaluationResult | null {
  if (!existsSync(jsonPath)) {
    return null;
  }
  try {
    const raw = readFileSync(jsonPath, 'utf-8');
    return JSON.parse(raw) as EvaluationResult;
  } catch {
    return null;
  }
}

function buildResultFromCategoryFiles(
  runDir: string,
  codebasePath: string
): EvaluationResult {
  const categories: CategoryScore[] = [];
  const findings: Finding[] = [];
  let totalWeightedScore = 0;
  let totalWeight = 0;

  // Try both naming patterns: <script-name>.json and <category_id>.json
  for (const [catId, catMeta] of Object.entries(CATEGORY_WEIGHTS)) {
    const possibleFiles = [
      join(runDir, `${catMeta.script}.json`),
      join(runDir, `${catId}.json`),
    ];

    let catData: Record<string, unknown> | null = null;
    for (const filePath of possibleFiles) {
      if (existsSync(filePath)) {
        try {
          catData = JSON.parse(readFileSync(filePath, 'utf-8'));
          break;
        } catch {
          // skip malformed
        }
      }
    }

    if (catData) {
      const score = (catData['score'] as number) ?? 5.0;
      const { grade } = scoreToGrade(score);
      const catFindings = Array.isArray(catData['findings'])
        ? catData['findings']
        : [];

      categories.push({
        id: catId,
        name: catMeta.name,
        weight: catMeta.weight,
        score,
        grade,
        findings_count: catFindings.length,
        details: catData,
      });
      totalWeightedScore += score * catMeta.weight;
      totalWeight += catMeta.weight;

      for (const f of catFindings) {
        const fi = f as Record<string, unknown>;
        findings.push({
          id: findings.length + 1,
          category: catMeta.name,
          severity: (fi['severity'] as Finding['severity']) ?? 'medium',
          description:
            (fi['description'] as string) ??
            (fi['message'] as string) ??
            'Unknown finding',
          file: fi['file'] as string | undefined,
          line: fi['line'] as number | undefined,
          remediation:
            (fi['remediation'] as string) ?? 'Review and address this finding',
        });
      }
    }
  }

  const overallScore = totalWeight > 0 ? totalWeightedScore / totalWeight : 0;
  const { grade, risk } = scoreToGrade(overallScore);

  return {
    overall_score: Math.round(overallScore * 100) / 100,
    grade,
    risk_level: risk,
    categories,
    findings: findings.sort((a, b) => {
      const order = { critical: 0, high: 1, medium: 2, low: 3 };
      return (order[a.severity] ?? 3) - (order[b.severity] ?? 3);
    }),
    timestamp: new Date().toISOString(),
    codebase_path: codebasePath,
    mode: 'standard',
    languages_detected: [],
    frameworks_detected: [],
  };
}

// --- Active Evaluations Tracking ---

interface ActiveEvaluation {
  process: ChildProcess;
  outputDir: string;
  startedAt: number;
  codebasePath: string;
}

const activeEvaluations = new Map<string, ActiveEvaluation>();

export function getActiveEvaluations(): Map<string, ActiveEvaluation> {
  return activeEvaluations;
}

// --- Public API ---

export function startEvaluation(
  codebasePath: string,
  options: EvaluationOptions = {}
): { success: boolean; run_id?: string; output_dir?: string; error?: string } {
  const absPath = resolve(codebasePath);
  if (!existsSync(absPath)) {
    return { success: false, error: `Codebase path not found: ${absPath}` };
  }

  const scriptPath = join(SCRIPTS_DIR, 'run-full-evaluation.sh');
  if (!existsSync(scriptPath)) {
    return {
      success: false,
      error:
        'Evaluation script not found. Ensure tools/cto-evaluation/ is set up.',
    };
  }

  // Check if evaluation is already running for this path
  for (const [, active] of activeEvaluations) {
    if (active.codebasePath === absPath) {
      return {
        success: false,
        error: 'An evaluation is already running for this codebase.',
      };
    }
  }

  let bashPath: string;
  try {
    bashPath = getBashPath();
  } catch (err) {
    return { success: false, error: (err as Error).message };
  }

  // Build PATH for child process — include project tools/ so bundled jq.exe is found
  const toolsBinDir = join(ROOT, 'tools');
  const toolsBinUnix = toolsBinDir
    .replace(/\\/g, '/')
    .replace(/^([A-Z]):/, (_, d: string) => `/${d.toLowerCase()}`);
  const childPath = `${toolsBinUnix}:${process.env['PATH'] ?? ''}`;

  // Verify jq is available (either system or bundled)
  try {
    execSync(`"${bashPath}" -c "command -v jq"`, {
      stdio: 'ignore',
      env: { ...process.env, PATH: childPath },
    });
  } catch {
    return {
      success: false,
      error:
        'jq is required by the evaluation scripts but is not installed. ' +
        'Install it with: winget install jqlang.jq  (or: scoop install jq / choco install jq). ' +
        'Then restart your terminal.',
    };
  }

  const now = new Date();
  const ts = now
    .toISOString()
    .replace(/[-:.TZ]/g, '')
    .slice(0, 14)
    .replace(/^(\d{8})(\d{6})/, '$1_$2');
  const runId = `evaluation_${ts}`;

  // Direct the script to write into <codebasePath>/.cto-evaluation/
  // The script appends evaluation_<its-timestamp>/ inside this dir.
  // getEvaluationProgress() falls back to the latest dir if our runId doesn't match exactly.
  const outputBaseDir = join(absPath, '.cto-evaluation');
  const outputDir = join(outputBaseDir, runId);

  // Convert Windows backslashes → forward slashes for Git Bash args
  const toUnixPath = (p: string) => p.replace(/\\/g, '/');

  const args = [
    scriptPath,
    toUnixPath(absPath),
    '--output-dir',
    toUnixPath(outputBaseDir),
  ];
  if (options.mode === 'quick') {
    args.push('--quick');
  }
  if (options.mode === 'enhanced') {
    args.push('--enhanced');
  }
  if (options.verbose) {
    args.push('--verbose');
  }
  if (options.skipCategories?.length) {
    for (const cat of options.skipCategories) {
      args.push(`--skip-${cat}`);
    }
  }

  // Set MAX_PARALLEL higher for faster evaluation and add timeout
  const timeoutMinutes = options.timeout ?? 20; // 20min overall (was 15)
  const childEnv = {
    ...process.env,
    PATH: childPath,
    CTO_MAX_PARALLEL: '6', // Run up to 6 categories in parallel
    CTO_SCRIPT_TIMEOUT: '480', // Per-script timeout: 8 minutes
  };

  const proc = spawn(bashPath, args, {
    cwd: EVAL_DIR,
    env: childEnv,
    stdio: 'ignore',
    detached: false,
  });

  const startedAt = Date.now();

  activeEvaluations.set(runId, {
    process: proc,
    outputDir,
    startedAt,
    codebasePath: absPath,
  });

  // Persist startedAt to file so elapsed time survives server restarts / hot reloads
  // Write to base dir (not run dir) to avoid creating the run directory prematurely —
  // the bash script creates its own timestamped run directory, and if ours exists first
  // with no JSON files, progress detection gets confused.
  try {
    mkdirSync(outputBaseDir, { recursive: true });
    writeFileSync(
      join(outputBaseDir, `.started-${runId}`),
      String(startedAt),
      'utf-8'
    );
  } catch {
    /* non-critical */
  }

  // Timeout: kill the process after N minutes to prevent hanging
  const timeoutHandle = setTimeout(
    () => {
      if (activeEvaluations.has(runId)) {
        console.error(
          `[Evaluation] Timeout after ${timeoutMinutes}min — killing process for ${runId}`
        );
        try {
          proc.kill('SIGTERM');
        } catch {
          /* ignore */
        }
        setTimeout(() => {
          try {
            proc.kill('SIGKILL');
          } catch {
            /* ignore */
          }
        }, 5000);
      }
    },
    timeoutMinutes * 60 * 1000
  );

  proc.on('close', () => {
    clearTimeout(timeoutHandle);
    activeEvaluations.delete(runId);
  });

  proc.on('error', () => {
    clearTimeout(timeoutHandle);
    activeEvaluations.delete(runId);
  });

  return { success: true, run_id: runId, output_dir: outputDir };
}

export function getEvaluationProgress(
  codebasePath: string,
  runId: string
): EvaluationProgress {
  const absPath = resolve(codebasePath);
  const evalDir = join(absPath, '.cto-evaluation');

  // Find the best matching run directory.
  // The shell script creates its own timestamped directory (may differ by seconds from runId),
  // so we need to find it by scanning for the latest directory with actual JSON output.
  const findBestRunDir = (): string | null => {
    const runDir = join(evalDir, runId);
    // Check if exact runDir has JSON files
    if (existsSync(runDir)) {
      try {
        const files = readdirSync(runDir).filter((f) => f.endsWith('.json'));
        if (files.length > 0) {
          return runDir;
        }
      } catch {
        /* continue */
      }
    }
    // Fall back to latest run directory with actual results
    const runs = listEvaluationRuns(absPath);
    for (const run of runs) {
      const dir = join(evalDir, run);
      try {
        const files = readdirSync(dir).filter((f) => f.endsWith('.json'));
        if (files.length > 0) {
          return dir;
        }
      } catch {
        /* continue */
      }
    }
    return null;
  };

  const bestDir = findBestRunDir();

  if (!bestDir) {
    // No output yet — check if evaluation is still active
    if (activeEvaluations.has(runId)) {
      return {
        status: 'running',
        run_id: runId,
        completed_count: 0,
        total_categories: 21,
        percent_complete: 0,
        completed_categories: [],
      };
    }
    return {
      status: 'not_found',
      run_id: runId,
      completed_count: 0,
      total_categories: 21,
      percent_complete: 0,
      completed_categories: [],
    };
  }

  return getEvaluationProgressFromDir(absPath, bestDir, runId);
}

function getEvaluationProgressFromDir(
  codebasePath: string,
  runDir: string,
  runId: string
): EvaluationProgress {
  // Check for completed report.json
  const reportPath = join(runDir, 'report.json');
  if (existsSync(reportPath)) {
    let result = parseResultJson(reportPath);
    if (!result) {
      result = buildResultFromCategoryFiles(runDir, codebasePath);
    }
    result.codebase_path = codebasePath;
    return {
      status: 'complete',
      run_id: runId,
      completed_count: result.categories.length,
      total_categories: 21,
      percent_complete: 100,
      completed_categories: result.categories.map((c) => ({
        id: c.id,
        name: c.name,
        score: c.score,
        grade: c.grade,
        findings_count: c.findings_count,
      })),
      result,
    };
  }

  // Scan for individual category JSON files
  const completedCategories: EvaluationProgress['completed_categories'] = [];
  let files: string[];
  try {
    files = readdirSync(runDir).filter(
      (f) => f.endsWith('.json') && !f.startsWith('.')
    );
  } catch {
    files = [];
  }

  for (const file of files) {
    const baseName = file.replace('.json', '');
    // Map from script name (e.g., "01-code-quality") to category ID
    const catId = SCRIPT_TO_CATEGORY[baseName] ?? baseName;
    const catMeta = CATEGORY_WEIGHTS[catId];
    if (!catMeta) {
      continue;
    }

    // Skip empty files (script was killed before writing results)
    const filePath = join(runDir, file);
    try {
      const content = readFileSync(filePath, 'utf-8').trim();
      if (!content) {
        continue;
      }
      const data = JSON.parse(content);
      const score = data.score ?? 5.0;
      const { grade } = scoreToGrade(score);
      completedCategories.push({
        id: catId,
        name: catMeta.name,
        score,
        grade,
        findings_count: Array.isArray(data.findings) ? data.findings.length : 0,
      });
    } catch {
      // skip malformed
    }
  }

  const activeEval = activeEvaluations.get(runId);
  const isActive = !!activeEval;

  // Elapsed time — use in-memory value first, fall back to persisted .started file
  let startedAt = activeEval?.startedAt;
  if (!startedAt) {
    const evalBaseDir = join(resolve(codebasePath), '.cto-evaluation');
    try {
      const startedFile = join(evalBaseDir, `.started-${runId}`);
      if (existsSync(startedFile)) {
        startedAt = parseInt(readFileSync(startedFile, 'utf-8').trim(), 10);
      }
    } catch {
      /* ignore */
    }
  }
  const elapsedSeconds = startedAt
    ? Math.round((Date.now() - startedAt) / 1000)
    : undefined;

  // Stale detection: if most categories are done and no new files for >3 minutes,
  // or elapsed time exceeds 10 minutes, auto-complete with partial results.
  // This prevents the UI from being stuck at 90% forever when 1-2 scripts hang.
  const STALE_THRESHOLD_SECONDS = 180; // 3 minutes with no new files
  const MAX_EVAL_SECONDS = 600; // 10 minutes max total
  let isStale = false;

  if (completedCategories.length >= 17 && completedCategories.length < 21) {
    // Check if the most recent JSON file is older than the stale threshold
    try {
      const jsonFiles = readdirSync(runDir)
        .filter((f) => f.endsWith('.json') && !f.startsWith('.'))
        .map((f) => ({ name: f, mtime: statSync(join(runDir, f)).mtimeMs }))
        .sort((a, b) => b.mtime - a.mtime);

      if (jsonFiles.length > 0) {
        const newestFileAge = (Date.now() - jsonFiles[0]!.mtime) / 1000;
        if (newestFileAge > STALE_THRESHOLD_SECONDS) {
          isStale = true;
        }
      }
    } catch {
      /* ignore */
    }

    // Also check elapsed time
    if (elapsedSeconds && elapsedSeconds > MAX_EVAL_SECONDS) {
      isStale = true;
    }
  }

  // Determine status
  let status: EvaluationProgress['status'];
  let result: EvaluationResult | undefined;

  if (completedCategories.length >= 21) {
    status = 'complete';
    result = buildResultFromCategoryFiles(runDir, codebasePath);
  } else if (isStale) {
    // Auto-complete with partial results — kill the hanging process
    status = 'complete';
    result = buildResultFromCategoryFiles(runDir, codebasePath);
    // Mark timed-out categories in the result
    const completedIds = new Set(completedCategories.map((c) => c.id));
    const timedOutCats = Object.entries(CATEGORY_WEIGHTS)
      .filter(([catId]) => !completedIds.has(catId))
      .map(([, meta]) => meta.name);
    if (result && timedOutCats.length > 0) {
      result.findings.push({
        id: result.findings.length + 1,
        category: 'Evaluation',
        severity: 'low',
        description: `${timedOutCats.length} categories timed out and were scored with defaults: ${timedOutCats.join(', ')}`,
        remediation:
          'Re-run the evaluation or increase the per-script timeout (CTO_SCRIPT_TIMEOUT)',
      });
    }
    // Kill the hanging process if still active
    if (activeEval) {
      try {
        activeEval.process.kill('SIGTERM');
      } catch {
        /* ignore */
      }
      setTimeout(() => {
        try {
          activeEval.process.kill('SIGKILL');
        } catch {
          /* ignore */
        }
      }, 3000);
      activeEvaluations.delete(runId);
    }
  } else {
    status =
      isActive || completedCategories.length < 21 ? 'running' : 'complete';
    if (status === 'complete') {
      result = buildResultFromCategoryFiles(runDir, codebasePath);
    }
  }

  // Determine which categories are still in progress
  const completedIds = new Set(completedCategories.map((c) => c.id));
  const inProgressCategories = Object.entries(CATEGORY_WEIGHTS)
    .filter(([catId]) => !completedIds.has(catId))
    .map(([, meta]) => meta.name);

  return {
    status,
    run_id: runId,
    completed_count: completedCategories.length,
    total_categories: 21,
    percent_complete:
      status === 'complete'
        ? 100
        : Math.round((completedCategories.length / 21) * 100),
    completed_categories: completedCategories,
    in_progress_categories:
      status === 'complete'
        ? undefined
        : inProgressCategories.length > 0
          ? inProgressCategories
          : undefined,
    elapsed_seconds: elapsedSeconds,
    result,
  };
}

export function getLatestEvaluation(
  codebasePath: string
): EvaluationResult | null {
  const absPath = resolve(codebasePath);
  const runs = listEvaluationRuns(absPath);
  if (runs.length === 0) {
    return null;
  }

  const latestRunName = runs[0]!;
  const latestRun = join(absPath, '.cto-evaluation', latestRunName);
  const reportJson = join(latestRun, 'report.json');
  let result = parseResultJson(reportJson);

  if (!result) {
    result = buildResultFromCategoryFiles(latestRun, absPath);
  }
  result.codebase_path = absPath;

  return result;
}

export function listEvaluations(codebasePath: string): EvaluationSummary[] {
  const absPath = resolve(codebasePath);
  const runs = listEvaluationRuns(absPath);

  return runs.map((runName) => {
    const runDir = join(absPath, '.cto-evaluation', runName);
    const reportJson = join(runDir, 'report.json');
    const result = parseResultJson(reportJson);

    const tsMatch = runName.match(/evaluation_(\d{8}_\d{6})/);
    const tsRaw = tsMatch?.[1];
    const timestamp = tsRaw
      ? `${tsRaw.slice(0, 4)}-${tsRaw.slice(4, 6)}-${tsRaw.slice(6, 8)}T${tsRaw.slice(9, 11)}:${tsRaw.slice(11, 13)}:${tsRaw.slice(13, 15)}`
      : new Date().toISOString();

    if (result) {
      return {
        run_id: runName,
        timestamp,
        overall_score: result.overall_score,
        grade: result.grade,
        mode: result.mode,
        categories_evaluated: result.categories.length,
        findings_total: result.findings.length,
        findings_critical: result.findings.filter(
          (f) => f.severity === 'critical'
        ).length,
        findings_high: result.findings.filter((f) => f.severity === 'high')
          .length,
      };
    }

    return {
      run_id: runName,
      timestamp,
      overall_score: 0,
      grade: 'N/A',
      mode: 'unknown',
      categories_evaluated: 0,
      findings_total: 0,
      findings_critical: 0,
      findings_high: 0,
    };
  });
}
