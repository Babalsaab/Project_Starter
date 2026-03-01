/**
 * API: Improvement Loop Detail
 * GET  /api/orchestrator/improvement-loop/[id]  — Get CIL progress
 * POST /api/orchestrator/improvement-loop/[id]  — Control actions (pause/resume)
 */
import { type NextRequest, NextResponse } from 'next/server';
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import { requireAuth, requireRole } from '@/lib/api-auth';

const CIL_DIR = path.join(process.cwd(), 'config/project-sessions');
const ARTIFACTS_DIR = path.join(process.cwd(), 'runs/artifacts');

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const authResult = await requireAuth();
  if (authResult instanceof NextResponse) {
    return authResult;
  }

  try {
    const { id: cilId } = await params;

    // Validate ID format
    if (!/^cil_[a-zA-Z0-9_]+$/.test(cilId)) {
      return NextResponse.json(
        { error: 'Invalid CIL ID format' },
        { status: 400 }
      );
    }

    const statePath = path.join(CIL_DIR, cilId, 'cil-state.yaml');
    if (!fs.existsSync(statePath)) {
      // Try to find a CIL run that starts with the given prefix
      if (fs.existsSync(CIL_DIR)) {
        const dirs = fs
          .readdirSync(CIL_DIR, { withFileTypes: true })
          .filter(
            (d) => d.isDirectory() && d.name.startsWith(cilId.slice(0, 10))
          )
          .map((d) => d.name)
          .sort()
          .reverse();

        if (dirs.length > 0) {
          const altPath = path.join(CIL_DIR, dirs[0]!, 'cil-state.yaml');
          if (fs.existsSync(altPath)) {
            const state = yaml.load(fs.readFileSync(altPath, 'utf-8'), {
              schema: yaml.JSON_SCHEMA,
            }) as Record<string, unknown>;

            // Load iteration artifacts if available
            const artifacts = loadIterationArtifacts(
              dirs[0]!,
              state['current_iteration'] as number
            );

            return NextResponse.json({ state, artifacts });
          }
        }
      }

      return NextResponse.json({ error: 'CIL run not found' }, { status: 404 });
    }

    const state = yaml.load(fs.readFileSync(statePath, 'utf-8'), {
      schema: yaml.JSON_SCHEMA,
    }) as Record<string, unknown>;

    // Load iteration artifacts
    const artifacts = loadIterationArtifacts(
      cilId,
      state['current_iteration'] as number
    );

    // Load evaluation results and findings for each completed iteration
    const iterationFindings = loadIterationFindings(
      cilId,
      state['current_iteration'] as number
    );

    return NextResponse.json({ state, artifacts, iterationFindings });
  } catch (error) {
    console.error('CIL detail API error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const authResult = await requireRole('ADMIN', 'MANAGER');
  if (authResult instanceof NextResponse) {
    return authResult;
  }

  try {
    const { id: cilId } = await params;
    const body = await request.json();
    const { action } = body;

    // Validate ID format
    if (!/^cil_[a-zA-Z0-9_]+$/.test(cilId)) {
      return NextResponse.json(
        { error: 'Invalid CIL ID format' },
        { status: 400 }
      );
    }

    const statePath = path.join(CIL_DIR, cilId, 'cil-state.yaml');
    if (!fs.existsSync(statePath)) {
      return NextResponse.json({ error: 'CIL run not found' }, { status: 404 });
    }

    const state = yaml.load(fs.readFileSync(statePath, 'utf-8'), {
      schema: yaml.JSON_SCHEMA,
    }) as Record<string, unknown>;

    if (action === 'pause') {
      if (state['status'] !== 'running') {
        return NextResponse.json(
          { error: 'Can only pause running loops' },
          { status: 400 }
        );
      }
      state['status'] = 'paused';
      state['updated_at'] = new Date().toISOString();
      fs.writeFileSync(statePath, yaml.dump(state, { lineWidth: -1 }), 'utf-8');
      return NextResponse.json({ message: 'Loop paused', status: 'paused' });
    }

    if (action === 'resume') {
      if (state['status'] !== 'paused') {
        return NextResponse.json(
          { error: 'Can only resume paused loops' },
          { status: 400 }
        );
      }
      state['status'] = 'running';
      state['updated_at'] = new Date().toISOString();
      fs.writeFileSync(statePath, yaml.dump(state, { lineWidth: -1 }), 'utf-8');
      return NextResponse.json({ message: 'Loop resumed', status: 'running' });
    }

    return NextResponse.json(
      { error: "Invalid action — use 'pause' or 'resume'" },
      { status: 400 }
    );
  } catch (error) {
    console.error('CIL control API error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function loadIterationArtifacts(
  cilId: string,
  currentIteration: number
): Record<string, string[]> {
  const result: Record<string, string[]> = {};
  const baseDir = path.join(ARTIFACTS_DIR, cilId);
  if (!fs.existsSync(baseDir)) {
    return result;
  }

  for (let i = 1; i <= (currentIteration || 1); i++) {
    const iterDir = path.join(baseDir, `iteration-${i}`);
    if (!fs.existsSync(iterDir)) {
      continue;
    }

    try {
      const files = fs
        .readdirSync(iterDir)
        .filter((f) => !fs.statSync(path.join(iterDir, f)).isDirectory());
      result[`iteration-${i}`] = files;
    } catch {
      // skip
    }
  }

  return result;
}

interface IterationFinding {
  findings: Array<{
    id: number;
    category: string;
    severity: string;
    description: string;
    file?: string;
    line?: number;
    remediation: string;
  }>;
  categories: Array<{
    id: string;
    name: string;
    score: number;
    grade: string;
    findings_count: number;
  }>;
  overall_score: number;
  grade: string;
}

function loadIterationFindings(
  cilId: string,
  currentIteration: number
): Record<string, IterationFinding> {
  const result: Record<string, IterationFinding> = {};
  const baseDir = path.join(ARTIFACTS_DIR, cilId);
  if (!fs.existsSync(baseDir)) {
    return result;
  }

  for (let i = 1; i <= (currentIteration || 1); i++) {
    const evalPath = path.join(
      baseDir,
      `iteration-${i}`,
      'evaluation-result.json'
    );
    if (!fs.existsSync(evalPath)) {
      continue;
    }

    try {
      const evalData = JSON.parse(fs.readFileSync(evalPath, 'utf-8'));
      result[`iteration-${i}`] = {
        findings: evalData.findings ?? [],
        categories: (evalData.categories ?? []).map(
          (c: Record<string, unknown>) => ({
            id: c['id'],
            name: c['name'],
            score: c['score'],
            grade: c['grade'],
            findings_count: c['findings_count'],
          })
        ),
        overall_score: evalData.overall_score ?? 0,
        grade: evalData.grade ?? 'N/A',
      };
    } catch {
      // skip malformed files
    }
  }

  return result;
}
