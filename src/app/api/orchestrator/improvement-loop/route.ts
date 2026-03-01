/**
 * API: Continuous Improvement Loop
 * GET  /api/orchestrator/improvement-loop  — List all CIL runs
 * POST /api/orchestrator/improvement-loop  — Start a new improvement loop
 */
import { type NextRequest, NextResponse } from 'next/server';
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import { spawn } from 'child_process';
import { requireAuth, requireRole } from '@/lib/api-auth';

const CIL_DIR = path.join(process.cwd(), 'config/project-sessions');

export async function GET() {
  const authResult = await requireAuth();
  if (authResult instanceof NextResponse) {
    return authResult;
  }

  try {
    if (!fs.existsSync(CIL_DIR)) {
      return NextResponse.json({ runs: [] });
    }

    const runs = fs
      .readdirSync(CIL_DIR, { withFileTypes: true })
      .filter((d) => d.isDirectory() && d.name.startsWith('cil_'))
      .map((d) => {
        const statePath = path.join(CIL_DIR, d.name, 'cil-state.yaml');
        if (!fs.existsSync(statePath)) {
          return null;
        }
        try {
          const state = yaml.load(fs.readFileSync(statePath, 'utf-8'), {
            schema: yaml.JSON_SCHEMA,
          }) as Record<string, unknown>;
          return {
            id: state['id'],
            status: state['status'],
            current_iteration: state['current_iteration'],
            current_phase: state['current_phase'],
            config: state['config'],
            iterations: state['iterations'],
            started_at: state['started_at'],
            updated_at: state['updated_at'],
            summary: state['summary'],
          };
        } catch {
          return null;
        }
      })
      .filter(Boolean);

    return NextResponse.json({ runs });
  } catch (error) {
    console.error('CIL API error:', error);
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
    const {
      codebase_path,
      max_iterations = 5,
      target_score,
      target_grade,
      evaluation_mode = 'standard',
      focus_categories,
      auto_implement = true,
      coder,
    } = body;

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
    if (!fs.existsSync(absPath) || !fs.statSync(absPath).isDirectory()) {
      return NextResponse.json(
        { error: 'Path not found or not a directory' },
        { status: 404 }
      );
    }

    // Validate max_iterations
    const iterations = Math.max(1, Math.min(10, Number(max_iterations) || 5));

    // Validate evaluation mode
    const validModes = ['quick', 'standard', 'enhanced'];
    const mode = validModes.includes(evaluation_mode)
      ? evaluation_mode
      : 'standard';

    // Validate coder backend
    const validCoders = [
      'claude-api',
      'claude-code',
      'cursor',
      'aider',
      'manual',
    ];
    const coderBackend =
      coder && validCoders.includes(coder) ? coder : undefined;

    // Generate a CIL ID upfront so the API can return it immediately
    // and the CLI uses the same ID (via --id flag)
    const cilId = `cil_${new Date()
      .toISOString()
      .replace(/[-:.TZ]/g, '')
      .slice(0, 14)}`;

    // Build args for the CIL CLI
    const args = [
      'ts-node',
      '--project',
      'tsconfig.orchestrator.json',
      'orchestrator/cil-cli.ts',
      '--yes',
      '--id',
      cilId,
      '--path',
      absPath,
      '--iterations',
      String(iterations),
      '--mode',
      mode,
    ];

    if (target_score) {
      args.push('--target-score', String(target_score));
    }
    if (target_grade) {
      args.push('--target-grade', String(target_grade));
    }
    if (!auto_implement) {
      args.push('--no-auto-implement');
    }
    if (Array.isArray(focus_categories) && focus_categories.length > 0) {
      args.push('--focus', focus_categories.join(','));
    }
    if (coderBackend) {
      args.push('--coder', coderBackend);
    }

    // Spawn as background process using shell:true so npx.cmd resolves on Windows
    // Clean env for child process:
    // - Remove CLAUDECODE nesting flags so `claude --print` can run
    // - Remove ANTHROPIC_API_KEY if it's a placeholder (sk-ant-...) so claude falls back
    //   to its own OAuth credentials from ~/.claude/.credentials.json
    const cwd = process.cwd();
    const childEnv = { ...process.env };
    delete childEnv['CLAUDECODE'];
    delete childEnv['CLAUDE_CODE_ENTRYPOINT'];
    delete childEnv['CLAUDE_CODE_ENTRY_POINT'];
    const apiKey = childEnv['ANTHROPIC_API_KEY'] || '';
    if (!apiKey || apiKey === 'sk-ant-...' || apiKey.length < 20) {
      delete childEnv['ANTHROPIC_API_KEY'];
    }

    // Create log file for the CIL process so we can see diagnostic output
    const logsDir = path.join(cwd, 'runs', 'logs');
    if (!fs.existsSync(logsDir)) {
      fs.mkdirSync(logsDir, { recursive: true });
    }
    const logPath = path.join(logsDir, `${cilId}.log`);
    const logFd = fs.openSync(logPath, 'a');

    const proc = spawn('npx', args, {
      cwd,
      env: childEnv,
      shell: true,
      detached: false,
      stdio: ['ignore', logFd, logFd],
    });
    proc.unref();

    // Log when the process exits
    proc.on('close', (code) => {
      try {
        fs.closeSync(logFd);
      } catch {
        /* ignore */
      }
      if (code !== 0) {
        console.error(`CIL process exited with code ${code}, log: ${logPath}`);
      } else {
        console.log(`CIL execution completed successfully, log: ${logPath}`);
      }
    });

    return NextResponse.json({
      message: 'Improvement loop started',
      id: cilId,
      status: 'started',
      config: {
        codebase_path: absPath,
        max_iterations: iterations,
        target_score,
        target_grade,
        evaluation_mode: mode,
        focus_categories,
        auto_implement,
        coder: coderBackend || 'claude-api',
      },
    });
  } catch (error) {
    console.error('CIL API error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
