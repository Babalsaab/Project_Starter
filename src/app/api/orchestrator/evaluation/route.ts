/**
 * API: CTO Codebase Evaluation
 * GET  /api/orchestrator/evaluation  — List projects or evaluation history
 * POST /api/orchestrator/evaluation  — Start a new evaluation
 */
import { type NextRequest, NextResponse } from 'next/server';
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import { requireAuth, requireRole } from '@/lib/api-auth';
import {
  startEvaluation,
  listEvaluations,
  getLatestEvaluation,
  getActiveEvaluations,
} from '@/lib/evaluation-runner';

export async function GET(request: NextRequest) {
  const authResult = await requireAuth();
  if (authResult instanceof NextResponse) {
    return authResult;
  }

  try {
    const { searchParams } = new URL(request.url);
    const codebasePath = searchParams.get('codebase_path');

    // Return any active evaluations so the client can resume the running view
    const activeEvals: Array<{
      run_id: string;
      codebase_path: string;
      elapsed_seconds: number;
    }> = [];
    for (const [runId, active] of getActiveEvaluations()) {
      activeEvals.push({
        run_id: runId,
        codebase_path: active.codebasePath,
        elapsed_seconds: Math.round((Date.now() - active.startedAt) / 1000),
      });
    }

    if (!codebasePath) {
      // Return available projects for the picker
      const projects: Array<{ id: string; name: string; path: string }> = [];

      // Add current project root
      projects.push({
        id: 'current',
        name: 'Current Project',
        path: process.cwd(),
      });

      // Scan config/project-sessions/ for known projects
      const sessionsDir = path.join(process.cwd(), 'config/project-sessions');
      if (fs.existsSync(sessionsDir)) {
        const entries = fs.readdirSync(sessionsDir, { withFileTypes: true });
        for (const entry of entries) {
          if (!entry.isDirectory()) {
            continue;
          }
          const sessionPath = path.join(
            sessionsDir,
            entry.name,
            'session.yaml'
          );
          if (fs.existsSync(sessionPath)) {
            try {
              const session = yaml.load(fs.readFileSync(sessionPath, 'utf-8'), {
                schema: yaml.JSON_SCHEMA,
              }) as Record<string, unknown>;
              projects.push({
                id: entry.name,
                name: (session['project_name'] as string) ?? entry.name,
                path:
                  (session['codebase_path'] as string) ??
                  path.join(process.cwd()),
              });
            } catch {
              // skip malformed sessions
            }
          }
        }
      }

      return NextResponse.json({ projects, active: activeEvals });
    }

    // Validate path
    const absPath = path.resolve(codebasePath);
    if (absPath.includes('..')) {
      return NextResponse.json({ error: 'Invalid path' }, { status: 400 });
    }
    if (!fs.existsSync(absPath) || !fs.statSync(absPath).isDirectory()) {
      return NextResponse.json(
        { error: 'Path not found or not a directory' },
        { status: 404 }
      );
    }

    const evaluations = listEvaluations(absPath);
    const latest = getLatestEvaluation(absPath);

    return NextResponse.json({ evaluations, latest });
  } catch (error) {
    console.error('Evaluation API error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  const authResult = await requireRole('ADMIN', 'MANAGER');
  if (authResult instanceof NextResponse) {
    return authResult;
  }

  try {
    const body = await request.json();
    const { codebase_path, mode, skipCategories } = body;

    if (!codebase_path || typeof codebase_path !== 'string') {
      return NextResponse.json(
        { error: 'codebase_path is required' },
        { status: 400 }
      );
    }

    // Validate path format
    if (!/^[a-zA-Z0-9_\-\\/:. ]+$/.test(codebase_path)) {
      return NextResponse.json(
        { error: 'Invalid path characters' },
        { status: 400 }
      );
    }

    const absPath = path.resolve(codebase_path);
    if (absPath.includes('..')) {
      return NextResponse.json(
        { error: 'Path traversal not allowed' },
        { status: 400 }
      );
    }
    if (!fs.existsSync(absPath) || !fs.statSync(absPath).isDirectory()) {
      return NextResponse.json(
        { error: 'Path not found or not a directory' },
        { status: 404 }
      );
    }

    // Check for already running evaluation
    for (const [, active] of getActiveEvaluations()) {
      if (active.codebasePath === absPath) {
        return NextResponse.json(
          { error: 'An evaluation is already running for this codebase' },
          { status: 409 }
        );
      }
    }

    // Validate mode
    const validModes = ['quick', 'standard', 'enhanced'];
    const evalMode = validModes.includes(mode) ? mode : 'standard';

    const result = startEvaluation(absPath, {
      mode: evalMode,
      skipCategories: Array.isArray(skipCategories)
        ? skipCategories
        : undefined,
    });

    if (!result.success) {
      return NextResponse.json({ error: result.error }, { status: 500 });
    }

    return NextResponse.json({
      message: 'Evaluation started',
      run_id: result.run_id,
      output_dir: result.output_dir,
      status: 'started',
    });
  } catch (error) {
    console.error('Evaluation API error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
