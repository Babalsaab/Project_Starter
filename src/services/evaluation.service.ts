/**
 * Evaluation Service
 *
 * Business logic for CTO evaluation run lifecycle and result parsing.
 * Wraps the evaluation-runner lib with a service-layer interface.
 */

import * as fs from 'fs';
import * as path from 'path';

const EVAL_DIR = path.join(process.cwd(), '.cto-evaluation');

export interface EvaluationSummary {
  id: string;
  started_at: string;
  overall_score: number;
  grade: string;
  categories_evaluated: number;
}

export function listEvaluations(): EvaluationSummary[] {
  if (!fs.existsSync(EVAL_DIR)) {
    return [];
  }

  const entries = fs.readdirSync(EVAL_DIR, { withFileTypes: true });
  const evals: EvaluationSummary[] = [];

  for (const entry of entries) {
    if (!entry.isDirectory() || !entry.name.startsWith('evaluation_')) {
      continue;
    }
    const summaryFile = path.join(EVAL_DIR, entry.name, '00-summary.json');
    if (!fs.existsSync(summaryFile)) {
      continue;
    }

    try {
      const raw = JSON.parse(fs.readFileSync(summaryFile, 'utf-8'));
      evals.push({
        id: entry.name,
        started_at: raw.started_at ?? entry.name.replace('evaluation_', ''),
        overall_score: raw.overall_score ?? 0,
        grade: raw.grade ?? 'N/A',
        categories_evaluated: raw.categories_evaluated ?? 0,
      });
    } catch {
      // Skip malformed evaluation directories
    }
  }

  return evals.sort((a, b) => b.started_at.localeCompare(a.started_at));
}

export function getLatestEvaluation(): EvaluationSummary | null {
  const evals = listEvaluations();
  return evals[0] ?? null;
}

export function getEvaluationById(id: string): Record<string, unknown> | null {
  const summaryFile = path.join(EVAL_DIR, id, '00-summary.json');
  if (!fs.existsSync(summaryFile)) {
    return null;
  }

  try {
    return JSON.parse(fs.readFileSync(summaryFile, 'utf-8'));
  } catch {
    return null;
  }
}
