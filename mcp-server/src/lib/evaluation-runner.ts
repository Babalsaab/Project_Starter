/**
 * CTO Evaluation Suite - TypeScript Bridge
 *
 * Wraps the shell-based evaluation engine (tools/cto-evaluation/)
 * to provide typed interfaces for the MCP server.
 */

import { existsSync, readFileSync, readdirSync, statSync } from 'fs';
import { join, resolve } from 'path';
import { execSync, spawn } from 'child_process';

const ROOT = join(import.meta.dirname, '..', '..', '..');
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

function scoreToGrade(score: number): { grade: string; risk: string } {
  for (const entry of GRADE_MAP) {
    if (score >= entry.min && score <= entry.max) {
      return { grade: entry.grade, risk: entry.risk };
    }
  }
  return { grade: 'F', risk: 'Critical' };
}

// --- Category Weights ---

const CATEGORY_WEIGHTS: Record<string, { name: string; weight: number }> = {
  code_quality: { name: 'Code Quality', weight: 8 },
  architecture: { name: 'Architecture', weight: 10 },
  security: { name: 'Security', weight: 12 },
  performance: { name: 'Performance', weight: 8 },
  testing: { name: 'Testing', weight: 8 },
  devops: { name: 'DevOps', weight: 6 },
  scalability: { name: 'Scalability', weight: 8 },
  reliability: { name: 'Reliability', weight: 8 },
  data_architecture: { name: 'Data Architecture', weight: 5 },
  api_design: { name: 'API Design', weight: 5 },
  frontend: { name: 'Frontend', weight: 4 },
  backend: { name: 'Backend', weight: 5 },
  mobile: { name: 'Mobile', weight: 2 },
  documentation: { name: 'Documentation', weight: 2 },
  developer_experience: { name: 'Developer Experience', weight: 2 },
  maintainability: { name: 'Maintainability', weight: 5 },
  compliance: { name: 'Compliance', weight: 4 },
  observability: { name: 'Observability', weight: 4 },
  cost_efficiency: { name: 'Cost Efficiency', weight: 2 },
  innovation: { name: 'Innovation', weight: 2 },
  uiux_consistency: { name: 'UI/UX Consistency', weight: 4 },
};

// --- Shell Detection ---

function getBashPath(): string {
  // On Windows, look for Git Bash
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
    // Fallback to PATH
    try {
      execSync('bash --version', { stdio: 'ignore' });
      return 'bash';
    } catch {
      throw new Error(
        'Git Bash not found. Install Git for Windows to use the evaluation suite.'
      );
    }
  }
  return '/bin/bash';
}

// --- Evaluation Results Directory ---

function findEvaluationDir(codebasePath: string): string | null {
  const evalOutputDir = join(codebasePath, '.cto-evaluation');
  if (!existsSync(evalOutputDir)) {
    return null;
  }
  return evalOutputDir;
}

function listEvaluationRuns(codebasePath: string): string[] {
  const evalDir = findEvaluationDir(codebasePath);
  if (!evalDir) {
    return [];
  }

  return readdirSync(evalDir, { withFileTypes: true })
    .filter((d) => d.isDirectory() && d.name.startsWith('evaluation_'))
    .map((d) => d.name)
    .sort()
    .reverse(); // newest first
}

// --- Parse Results ---

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

function buildResultFromCategoryFiles(runDir: string): EvaluationResult {
  const categories: CategoryScore[] = [];
  const findings: Finding[] = [];
  let totalWeightedScore = 0;
  let totalWeight = 0;

  for (const [catId, catMeta] of Object.entries(CATEGORY_WEIGHTS)) {
    // Try to find category result JSON
    const catFile = join(runDir, `${catId}.json`);
    if (existsSync(catFile)) {
      try {
        const catData = JSON.parse(readFileSync(catFile, 'utf-8'));
        const score = catData.score ?? 5.0;
        const { grade } = scoreToGrade(score);
        categories.push({
          id: catId,
          name: catMeta.name,
          weight: catMeta.weight,
          score,
          grade,
          findings_count: catData.findings?.length ?? 0,
          details: catData,
        });
        totalWeightedScore += score * catMeta.weight;
        totalWeight += catMeta.weight;

        // Collect findings
        if (catData.findings && Array.isArray(catData.findings)) {
          for (const f of catData.findings) {
            findings.push({
              id: findings.length + 1,
              category: catMeta.name,
              severity: f.severity ?? 'medium',
              description: f.description ?? f.message ?? 'Unknown finding',
              file: f.file,
              line: f.line,
              remediation: f.remediation ?? 'Review and address this finding',
            });
          }
        }
      } catch {
        // Skip malformed files
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
      const severityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
      return (
        (severityOrder[a.severity] ?? 3) - (severityOrder[b.severity] ?? 3)
      );
    }),
    timestamp: new Date().toISOString(),
    codebase_path: '',
    mode: 'standard',
    languages_detected: [],
    frameworks_detected: [],
  };
}

// --- Public API ---

export async function runEvaluation(
  codebasePath: string,
  options: EvaluationOptions = {}
): Promise<{ success: boolean; message: string; result?: EvaluationResult }> {
  const absPath = resolve(codebasePath);
  if (!existsSync(absPath)) {
    return { success: false, message: `Codebase path not found: ${absPath}` };
  }

  const scriptPath = join(SCRIPTS_DIR, 'run-full-evaluation.sh');
  if (!existsSync(scriptPath)) {
    return {
      success: false,
      message: `Evaluation script not found at ${scriptPath}. Ensure tools/cto-evaluation/ is set up.`,
    };
  }

  const bashPath = getBashPath();
  const args = [scriptPath, absPath];

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

  const timeoutMs = (options.timeout ?? 30) * 60 * 1000;

  return new Promise((resolvePromise) => {
    const proc = spawn(bashPath, args, {
      cwd: EVAL_DIR,
      timeout: timeoutMs,
      env: { ...process.env, CTO_EVAL_OUTPUT_DIR: absPath },
    });

    let stdout = '';
    let stderr = '';

    proc.stdout?.on('data', (data) => {
      stdout += data.toString();
    });
    proc.stderr?.on('data', (data) => {
      stderr += data.toString();
    });

    proc.on('close', (code) => {
      if (code !== 0) {
        resolvePromise({
          success: false,
          message: `Evaluation exited with code ${code}.\n${stderr || stdout}`,
        });
        return;
      }

      // Try to find and parse results
      const runs = listEvaluationRuns(absPath);
      if (runs.length === 0) {
        resolvePromise({
          success: true,
          message: 'Evaluation completed but no results directory found.',
        });
        return;
      }

      const latestRunName = runs[0]!;
      const latestRun = join(absPath, '.cto-evaluation', latestRunName);
      const reportJson = join(latestRun, 'report.json');
      let result = parseResultJson(reportJson);

      if (!result) {
        result = buildResultFromCategoryFiles(latestRun);
      }

      result.codebase_path = absPath;
      result.mode = options.mode ?? 'standard';

      resolvePromise({
        success: true,
        message: 'Evaluation completed successfully.',
        result,
      });
    });

    proc.on('error', (err) => {
      resolvePromise({
        success: false,
        message: `Failed to start evaluation: ${err.message}`,
      });
    });
  });
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
    result = buildResultFromCategoryFiles(latestRun);
    result.codebase_path = absPath;
  }

  return result;
}

export function listEvaluations(codebasePath: string): EvaluationSummary[] {
  const absPath = resolve(codebasePath);
  const runs = listEvaluationRuns(absPath);

  return runs.map((runName) => {
    const runDir = join(absPath, '.cto-evaluation', runName);
    const reportJson = join(runDir, 'report.json');
    const result = parseResultJson(reportJson);

    // Extract timestamp from directory name: evaluation_YYYYMMDD_HHMMSS
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

export function compareEvaluations(
  result1: EvaluationResult,
  result2: EvaluationResult
): string {
  let output = '# Evaluation Comparison\n\n';
  output += `| Metric | Run 1 | Run 2 | Change |\n`;
  output += `|--------|-------|-------|--------|\n`;

  const scoreDiff = result2.overall_score - result1.overall_score;
  const diffSymbol = scoreDiff > 0 ? '+' : '';
  output += `| Overall Score | ${result1.overall_score} (${result1.grade}) | ${result2.overall_score} (${result2.grade}) | ${diffSymbol}${scoreDiff.toFixed(2)} |\n`;
  output += `| Findings | ${result1.findings.length} | ${result2.findings.length} | ${result2.findings.length - result1.findings.length} |\n`;
  output += `| Critical | ${result1.findings.filter((f) => f.severity === 'critical').length} | ${result2.findings.filter((f) => f.severity === 'critical').length} | — |\n`;

  output += `\n## Category Comparison\n\n`;
  output += `| Category | Run 1 | Run 2 | Change |\n`;
  output += `|----------|-------|-------|--------|\n`;

  const cat1Map = new Map(result1.categories.map((c) => [c.id, c]));
  for (const cat2 of result2.categories) {
    const cat1 = cat1Map.get(cat2.id);
    if (cat1) {
      const diff = cat2.score - cat1.score;
      const sym = diff > 0 ? '+' : '';
      output += `| ${cat2.name} | ${cat1.score} | ${cat2.score} | ${sym}${diff.toFixed(1)} |\n`;
    }
  }

  return output;
}
