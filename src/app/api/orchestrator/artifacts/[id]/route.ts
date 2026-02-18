/**
 * API: Get artifact content
 * GET /api/orchestrator/artifacts/[id]?agent=<agent_id>
 */
import { NextRequest, NextResponse } from "next/server";
import * as fs from "fs";
import * as path from "path";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: projectId } = await params;
    const agentId = request.nextUrl.searchParams.get("agent");

    const artifactDir = path.join(process.cwd(), "runs/artifacts", projectId);

    if (!fs.existsSync(artifactDir)) {
      return NextResponse.json({ error: "No artifacts found" }, { status: 404 });
    }

    // If agent specified, return that specific artifact
    if (agentId) {
      const filePath = path.join(artifactDir, `${agentId}-output.md`);
      if (!fs.existsSync(filePath)) {
        return NextResponse.json(
          { error: `Artifact not found for agent: ${agentId}` },
          { status: 404 }
        );
      }
      const content = fs.readFileSync(filePath, "utf-8");
      return NextResponse.json({ agent_id: agentId, content });
    }

    // Otherwise return all artifacts
    const manifestPath = path.join(artifactDir, "manifest.json");
    if (!fs.existsSync(manifestPath)) {
      return NextResponse.json({ artifacts: [] });
    }

    const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf-8"));

    // Include content for each artifact
    const artifacts = manifest.map((meta: any) => {
      const filePath = path.join(artifactDir, meta.filename);
      const content = fs.existsSync(filePath)
        ? fs.readFileSync(filePath, "utf-8")
        : null;
      return { ...meta, content };
    });

    return NextResponse.json({ artifacts });
  } catch (error) {
    return NextResponse.json(
      { error: (error as Error).message },
      { status: 500 }
    );
  }
}
