/**
 * API: Get session details + execute a session
 * GET  /api/orchestrator/sessions/[id]  — full session details
 * POST /api/orchestrator/sessions/[id]  — trigger execution via CLI
 */
import { NextRequest, NextResponse } from "next/server";
import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";
import { exec } from "child_process";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: projectId } = await params;
    const sessionsDir = path.join(process.cwd(), "config/project-sessions", projectId);
    const sessionPath = path.join(sessionsDir, "session.yaml");

    if (!fs.existsSync(sessionPath)) {
      return NextResponse.json({ error: "Session not found" }, { status: 404 });
    }

    const session = yaml.load(fs.readFileSync(sessionPath, "utf-8")) as any;

    // Load execution plan
    const planPath = path.join(sessionsDir, "execution-plan.yaml");
    let plan = null;
    if (fs.existsSync(planPath)) {
      plan = yaml.load(fs.readFileSync(planPath, "utf-8"));
    }

    // Load agent selection
    const selectionPath = path.join(sessionsDir, "agent-selection.yaml");
    let agentSelection = null;
    if (fs.existsSync(selectionPath)) {
      agentSelection = yaml.load(fs.readFileSync(selectionPath, "utf-8"));
    }

    // Load PRD content
    let prdContent = null;
    if (session.prd_path && fs.existsSync(session.prd_path)) {
      prdContent = fs.readFileSync(session.prd_path, "utf-8");
    }

    // Load artifacts
    const manifestPath = path.join(
      process.cwd(),
      "runs/artifacts",
      projectId,
      "manifest.json"
    );
    let artifacts: any[] = [];
    if (fs.existsSync(manifestPath)) {
      artifacts = JSON.parse(fs.readFileSync(manifestPath, "utf-8"));
    }

    return NextResponse.json({
      session,
      plan,
      agentSelection,
      prdContent,
      artifacts,
    });
  } catch (error) {
    return NextResponse.json(
      { error: (error as Error).message },
      { status: 500 }
    );
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: projectId } = await params;
    const sessionPath = path.join(
      process.cwd(),
      "config/project-sessions",
      projectId,
      "session.yaml"
    );

    if (!fs.existsSync(sessionPath)) {
      return NextResponse.json({ error: "Session not found" }, { status: 404 });
    }

    // Spawn the orchestrator CLI as a background child process
    // This avoids importing the executor (which lives outside src/ and is excluded from Next.js)
    const cwd = process.cwd();
    exec(
      `npx ts-node --project tsconfig.orchestrator.json -e "import { executeProject } from './orchestrator/executor'; executeProject('${projectId}').then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); })"`,
      { cwd, env: { ...process.env } },
      (error, stdout, stderr) => {
        if (error) {
          console.error(`Execution error for ${projectId}:`, stderr);
        } else {
          console.log(`Execution completed for ${projectId}:`, stdout);
        }
      }
    );

    return NextResponse.json({
      message: "Execution started",
      project_id: projectId,
    });
  } catch (error) {
    return NextResponse.json(
      { error: (error as Error).message },
      { status: 500 }
    );
  }
}
