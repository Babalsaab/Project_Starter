/**
 * API: CTO Evaluation Progress/Results
 * GET /api/orchestrator/evaluation/[id] — Get evaluation progress or results
 */
import { type NextRequest, NextResponse } from 'next/server';
import * as path from 'path';
import * as fs from 'fs';
import { requireAuth } from '@/lib/api-auth';
import { getEvaluationProgress } from '@/lib/evaluation-runner';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const authResult = await requireAuth();
  if (authResult instanceof NextResponse) {
    return authResult;
  }

  try {
    const { id: runId } = await params;
    const { searchParams } = new URL(request.url);
    const codebasePath = searchParams.get('codebase_path');

    // Validate run ID format
    if (!/^evaluation_\d{8}_\d{6}$/.test(runId)) {
      return NextResponse.json(
        {
          error: 'Invalid run ID format. Expected: evaluation_YYYYMMDD_HHMMSS',
        },
        { status: 400 }
      );
    }

    if (!codebasePath) {
      return NextResponse.json(
        { error: 'codebase_path query parameter is required' },
        { status: 400 }
      );
    }

    // Validate path
    const absPath = path.resolve(codebasePath);
    if (absPath.includes('..')) {
      return NextResponse.json({ error: 'Invalid path' }, { status: 400 });
    }
    if (!fs.existsSync(absPath) || !fs.statSync(absPath).isDirectory()) {
      return NextResponse.json({ error: 'Path not found' }, { status: 404 });
    }

    const progress = getEvaluationProgress(absPath, runId);
    return NextResponse.json(progress);
  } catch (error) {
    console.error('Evaluation progress API error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
