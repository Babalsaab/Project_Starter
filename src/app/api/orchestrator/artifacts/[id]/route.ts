/**
 * API: Get artifact content
 * GET /api/orchestrator/artifacts/[id]?agent=<agent_id>
 */
import { NextRequest, NextResponse } from "next/server";
import * as fs from "fs";
import * as path from "path";
import { requireAuth } from "@/lib/api-auth";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const authResult = await requireAuth();
  if (authResult instanceof NextResponse) return authResult;

  try {
    const { id: projectId } = await params;
    const agentId = request.nextUrl.searchParams.get("agent");

    // Validate IDs — only allow alphanumeric, hyphens, underscores
    if (!/^[a-zA-Z0-9_-]+$/.test(projectId)) {
      return NextResponse.json(
        { error: "Invalid project ID format" },
        { status: 400 }
      );
    }
    if (agentId && !/^[a-zA-Z0-9_-]+$/.test(agentId)) {
      return NextResponse.json(
        { error: "Invalid agent ID format" },
        { status: 400 }
      );
    }

    const allowedBase = path.resolve(process.cwd(), "runs/artifacts");
    const artifactDir = path.resolve(allowedBase, projectId);

    // Prevent path traversal — resolved path must be within allowed base
    if (!artifactDir.startsWith(allowedBase + path.sep)) {
      return NextResponse.json(
        { error: "Invalid project ID" },
        { status: 400 }
      );
    }

    if (!fs.existsSync(artifactDir)) {
      return NextResponse.json({ error: "No artifacts found" }, { status: 404 });
    }

    // If agent specified, return that specific artifact
    if (agentId) {
      const filePath = path.resolve(artifactDir, `${agentId}-output.md`);
      // Ensure resolved path is still within the artifact directory
      if (!filePath.startsWith(artifactDir + path.sep)) {
        return NextResponse.json(
          { error: "Invalid agent ID" },
          { status: 400 }
        );
      }
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

    // Include content for each artifact (with path traversal protection)
    const MAX_ARTIFACT_SIZE = 5 * 1024 * 1024; // 5MB limit per artifact
    const artifacts = manifest.map((meta: any) => {
      const filePath = path.resolve(artifactDir, meta.filename);
      // Ensure each filename resolves within artifact directory
      if (!filePath.startsWith(artifactDir + path.sep) && filePath !== artifactDir) {
        return { ...meta, content: null, error: "Invalid filename" };
      }
      if (!fs.existsSync(filePath)) {
        return { ...meta, content: null };
      }
      const stats = fs.statSync(filePath);
      if (stats.size > MAX_ARTIFACT_SIZE) {
        return { ...meta, content: null, error: "Artifact too large" };
      }
      const content = fs.readFileSync(filePath, "utf-8");
      return { ...meta, content };
    });

    return NextResponse.json({ artifacts });
  } catch (error) {
    console.error("API error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
