/**
 * API: List all agents in the registry
 * GET /api/orchestrator/agents
 */
import { NextResponse } from "next/server";
import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";
import { requireAuth } from "@/lib/api-auth";

function loadAgents(dir: string, category: string) {
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((f) => f.endsWith(".yaml"))
    .map((f) => {
      const content = yaml.load(
        fs.readFileSync(path.join(dir, f), "utf-8"),
        { schema: yaml.JSON_SCHEMA }
      ) as any;
      return { ...content, category, file: f };
    });
}

export async function GET() {
  const authResult = await requireAuth();
  if (authResult instanceof NextResponse) return authResult;

  try {
    const agentsDir = path.join(process.cwd(), "agents");

    const chiefs = loadAgents(path.join(agentsDir, "chiefs"), "chief");
    const tech = loadAgents(path.join(agentsDir, "pool/tech"), "tech");
    const marketing = loadAgents(
      path.join(agentsDir, "pool/marketing"),
      "marketing"
    );

    // Load persona list
    const personaDir = path.join(agentsDir, "personas");
    let personas: string[] = [];
    if (fs.existsSync(personaDir)) {
      personas = fs
        .readdirSync(personaDir)
        .filter((f) => f.endsWith(".md"))
        .map((f) => f.replace(".md", ""));
    }

    return NextResponse.json({
      chiefs,
      tech,
      marketing,
      personas,
      total: chiefs.length + tech.length + marketing.length,
    });
  } catch (error) {
    console.error("API error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
