/**
 * API: List all orchestrator sessions
 * GET /api/orchestrator/sessions
 */
import { NextResponse } from "next/server";
import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";
import { requireAuth } from "@/lib/api-auth";

export async function GET() {
  const session = await requireAuth();
  if (session instanceof NextResponse) return session;

  try {
    const sessionsDir = path.join(process.cwd(), "config/project-sessions");
    if (!fs.existsSync(sessionsDir)) {
      return NextResponse.json({ sessions: [] });
    }

    const dirs = fs
      .readdirSync(sessionsDir)
      .filter((d) =>
        fs.statSync(path.join(sessionsDir, d)).isDirectory()
      );

    const sessions = dirs
      .map((d) => {
        const sessionPath = path.join(sessionsDir, d, "session.yaml");
        if (!fs.existsSync(sessionPath)) return null;
        const session = yaml.load(fs.readFileSync(sessionPath, "utf-8"), { schema: yaml.JSON_SCHEMA }) as any;

        // Check for execution plan
        const planPath = path.join(sessionsDir, d, "execution-plan.yaml");
        const progress = { total: 0, done: 0, failed: 0, running: 0 };
        if (fs.existsSync(planPath)) {
          const plan = yaml.load(fs.readFileSync(planPath, "utf-8"), { schema: yaml.JSON_SCHEMA }) as any;
          if (plan?.steps) {
            progress.total = plan.steps.length;
            progress.done = plan.steps.filter((s: any) => s.status === "done").length;
            progress.failed = plan.steps.filter((s: any) => s.status === "failed").length;
            progress.running = plan.steps.filter((s: any) => s.status === "in_progress").length;
          }
        }

        // Check for artifacts
        const manifestPath = path.join(
          process.cwd(),
          "runs/artifacts",
          d,
          "manifest.json"
        );
        const artifactCount = fs.existsSync(manifestPath)
          ? JSON.parse(fs.readFileSync(manifestPath, "utf-8")).length
          : 0;

        return {
          project_id: session.project_id,
          project_name: session.project_name,
          status: session.status,
          created_at: session.created_at,
          agent_count: session.active_agents?.length || 0,
          progress,
          artifact_count: artifactCount,
        };
      })
      .filter(Boolean);

    return NextResponse.json({ sessions });
  } catch (error) {
    console.error("API error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
