/**
 * API: Get session details + execute a session
 * GET  /api/orchestrator/sessions/[id]  — full session details
 * POST /api/orchestrator/sessions/[id]  — trigger execution via CLI
 */
import { NextRequest, NextResponse } from "next/server";
import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";
import { execFile } from "child_process";
import { requireAuth, requireRole } from "@/lib/api-auth";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const authResult = await requireAuth();
  if (authResult instanceof NextResponse) return authResult;

  try {
    const { id: projectId } = await params;

    // Validate project ID — only allow alphanumeric, hyphens, underscores
    if (!/^[a-zA-Z0-9_-]+$/.test(projectId)) {
      return NextResponse.json(
        { error: "Invalid project ID format" },
        { status: 400 }
      );
    }

    const sessionsDir = path.join(process.cwd(), "config/project-sessions", projectId);
    const sessionPath = path.join(sessionsDir, "session.yaml");

    if (!fs.existsSync(sessionPath)) {
      return NextResponse.json({ error: "Session not found" }, { status: 404 });
    }

    const session = yaml.load(fs.readFileSync(sessionPath, "utf-8"), { schema: yaml.JSON_SCHEMA }) as any;

    // Load execution plan
    const planPath = path.join(sessionsDir, "execution-plan.yaml");
    let plan = null;
    if (fs.existsSync(planPath)) {
      plan = yaml.load(fs.readFileSync(planPath, "utf-8"), { schema: yaml.JSON_SCHEMA });
    }

    // Load agent selection
    const selectionPath = path.join(sessionsDir, "agent-selection.yaml");
    let agentSelection = null;
    if (fs.existsSync(selectionPath)) {
      agentSelection = yaml.load(fs.readFileSync(selectionPath, "utf-8"), { schema: yaml.JSON_SCHEMA });
    }

    // Load PRD content — validate prd_path resolves within the project directory
    let prdContent = null;
    if (session.prd_path) {
      const allowedPrdBase = path.resolve(process.cwd());
      const resolvedPrdPath = path.resolve(session.prd_path);
      if (!resolvedPrdPath.startsWith(allowedPrdBase + path.sep)) {
        console.error("Rejected prd_path outside project directory:", session.prd_path);
        return NextResponse.json({ error: "Invalid prd_path in session" }, { status: 400 });
      }
      if (fs.existsSync(resolvedPrdPath)) {
        prdContent = fs.readFileSync(resolvedPrdPath, "utf-8");
      }
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
    console.error("API error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  // Require ADMIN or MANAGER role to trigger execution
  const authResult = await requireRole("ADMIN", "MANAGER");
  if (authResult instanceof NextResponse) return authResult;

  try {
    const { id: projectId } = await params;

    // Validate project ID — only allow alphanumeric, hyphens, underscores
    if (!/^[a-zA-Z0-9_-]+$/.test(projectId)) {
      return NextResponse.json(
        { error: "Invalid project ID format" },
        { status: 400 }
      );
    }

    const sessionPath = path.join(
      process.cwd(),
      "config/project-sessions",
      projectId,
      "session.yaml"
    );

    if (!fs.existsSync(sessionPath)) {
      return NextResponse.json({ error: "Session not found" }, { status: 404 });
    }

    // Spawn the orchestrator CLI as a background child process using execFile (no shell).
    // Pass projectId via environment variable to avoid interpolation into the script string.
    const cwd = process.cwd();
    const script = `import { executeProject } from './orchestrator/executor'; executeProject(process.env.__PROJECT_ID__).then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); })`;
    execFile(
      "npx",
      ["ts-node", "--project", "tsconfig.orchestrator.json", "-e", script],
      { cwd, env: { ...process.env, __PROJECT_ID__: projectId } },
      (error, stdout, stderr) => {
        if (error) {
          console.error(`Execution error for project:`, stderr);
        } else {
          console.log(`Execution completed for project:`, stdout);
        }
      }
    );

    return NextResponse.json({
      message: "Execution started",
      project_id: projectId,
    });
  } catch (error) {
    console.error("API error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
