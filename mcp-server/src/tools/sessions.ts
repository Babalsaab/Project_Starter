import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { readFileSync, readdirSync, existsSync } from "fs";
import { join, resolve, sep } from "path";
import yaml from "js-yaml";

const ROOT = join(import.meta.dirname, "..", "..", "..");
const SESSIONS_DIR = join(ROOT, "config", "project-sessions");
const ARTIFACTS_DIR = join(ROOT, "runs", "artifacts");
const PRDS_DIR = join(ROOT, "runs", "prds");

interface SessionSummary {
  project_id: string;
  name: string;
  status: string;
  created_at: string;
  agent_count: number;
}

function loadSessionYaml(
  projectId: string
): Record<string, unknown> | null {
  const sessionPath = join(SESSIONS_DIR, projectId, "session.yaml");
  if (!existsSync(sessionPath)) return null;
  try {
    return yaml.load(readFileSync(sessionPath, "utf-8")) as Record<
      string,
      unknown
    >;
  } catch (err) {
    console.error(`Failed to parse session YAML for "${projectId}":`, err);
    return null;
  }
}

export function registerSessionTools(server: McpServer): void {
  server.tool(
    "list_sessions",
    "List all orchestrator project sessions with their status and agent count.",
    {},
    async () => {
      if (!existsSync(SESSIONS_DIR)) {
        return {
          content: [
            {
              type: "text" as const,
              text: "No project sessions found. Run `npm run orchestrator` to create a new session.",
            },
          ],
        };
      }

      const dirs = readdirSync(SESSIONS_DIR, { withFileTypes: true }).filter(
        (d) => d.isDirectory()
      );

      if (dirs.length === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: "No project sessions found. Run `npm run orchestrator` to start a new project.",
            },
          ],
        };
      }

      const sessions: SessionSummary[] = [];
      for (const dir of dirs) {
        const session = loadSessionYaml(dir.name);
        if (session) {
          sessions.push({
            project_id: dir.name,
            name: (session["project_name"] as string) ?? dir.name,
            status: (session["status"] as string) ?? "unknown",
            created_at: (session["created_at"] as string) ?? "unknown",
            agent_count: Array.isArray(session["selected_agents"])
              ? session["selected_agents"].length
              : 0,
          });
        }
      }

      let output = `# Project Sessions (${sessions.length})\n\n`;
      output += sessions
        .map(
          (s) =>
            `- **${s.name}** (\`${s.project_id}\`)\n  Status: ${s.status} | Agents: ${s.agent_count} | Created: ${s.created_at}`
        )
        .join("\n\n");

      output += `\n\n_Use \`get_session\` for full details or \`run_pipeline\` to trigger execution._`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "get_session",
    "Get full details for a project session including configuration, execution plan, and artifacts.",
    {
      project_id: z.string().describe("The project session ID"),
    },
    async ({ project_id }) => {
      const session = loadSessionYaml(project_id);
      if (!session) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Session "${project_id}" not found. Use list_sessions to see available sessions.`,
            },
          ],
        };
      }

      let output = `# Session: ${session["project_name"] ?? project_id}\n\n`;
      output += `**Status:** ${session["status"] ?? "unknown"}\n`;
      output += `**Created:** ${session["created_at"] ?? "unknown"}\n\n`;

      // Selected agents
      const agents = session["selected_agents"];
      if (Array.isArray(agents)) {
        output += `## Selected Agents (${agents.length})\n`;
        output += agents.map((a: string) => `- \`${a}\``).join("\n");
        output += "\n\n";
      }

      // Check for PRD
      const prdPath = join(PRDS_DIR, `${project_id}-prd.md`);
      if (existsSync(prdPath)) {
        output += `## PRD\nAvailable at: \`runs/prds/${project_id}-prd.md\`\n\n`;
      }

      // Check for artifacts
      const artifactDir = join(ARTIFACTS_DIR, project_id);
      if (existsSync(artifactDir)) {
        const files = readdirSync(artifactDir).filter((f) =>
          f.endsWith(".md")
        );
        output += `## Artifacts (${files.length})\n`;
        output += files
          .map((f) => `- \`runs/artifacts/${project_id}/${f}\``)
          .join("\n");
        output += "\n\n";
      }

      // Execution plan
      const planPath = join(
        SESSIONS_DIR,
        project_id,
        "execution-plan.yaml"
      );
      if (existsSync(planPath)) {
        const planContent = readFileSync(planPath, "utf-8");
        // Truncate if too long
        const trimmed =
          planContent.length > 2000
            ? planContent.slice(0, 2000) + "\n...[truncated]"
            : planContent;
        output += `## Execution Plan\n\`\`\`yaml\n${trimmed}\n\`\`\`\n`;
      }

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "get_artifact",
    "Load a specific agent's output artifact from a project session.",
    {
      project_id: z.string().describe("The project session ID"),
      agent_id: z
        .string()
        .optional()
        .describe("Agent ID to load artifact for. Omit to list all artifacts."),
    },
    async ({ project_id, agent_id }) => {
      const artifactDir = join(ARTIFACTS_DIR, project_id);
      if (!existsSync(artifactDir)) {
        return {
          content: [
            {
              type: "text" as const,
              text: `No artifacts found for project "${project_id}".`,
            },
          ],
        };
      }

      if (!agent_id) {
        const files = readdirSync(artifactDir);
        return {
          content: [
            {
              type: "text" as const,
              text: `# Artifacts for ${project_id}\n\n${files.map((f) => `- \`${f}\``).join("\n")}\n\n_Specify an agent_id to load a specific artifact._`,
            },
          ],
        };
      }

      const artifactPath = resolve(artifactDir, `${agent_id}-output.md`);
      // Path boundary check: resolved path must remain within artifactDir
      if (!artifactPath.startsWith(resolve(artifactDir) + sep)) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Invalid agent ID "${agent_id}".`,
            },
          ],
        };
      }
      if (!existsSync(artifactPath)) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Artifact not found for agent "${agent_id}" in project "${project_id}".`,
            },
          ],
        };
      }

      const content = readFileSync(artifactPath, "utf-8");
      return { content: [{ type: "text" as const, text: content }] };
    }
  );

  server.tool(
    "pipeline_status",
    "Check the execution status of a project pipeline.",
    {
      project_id: z.string().describe("The project session ID"),
    },
    async ({ project_id }) => {
      const planPath = join(
        SESSIONS_DIR,
        project_id,
        "execution-plan.yaml"
      );
      if (!existsSync(planPath)) {
        return {
          content: [
            {
              type: "text" as const,
              text: `No execution plan found for "${project_id}". The pipeline may not have started yet.`,
            },
          ],
        };
      }

      const plan = yaml.load(readFileSync(planPath, "utf-8")) as Record<
        string,
        unknown
      >;
      const steps = (plan["steps"] ?? plan["tasks"] ?? []) as Array<
        Record<string, unknown>
      >;

      const total = steps.length;
      const done = steps.filter((s) => s["status"] === "done").length;
      const failed = steps.filter((s) => s["status"] === "failed").length;
      const running = steps.filter(
        (s) => s["status"] === "in_progress" || s["status"] === "running"
      ).length;
      const pending = total - done - failed - running;
      const progress = total > 0 ? Math.round((done / total) * 100) : 0;

      let output = `# Pipeline Status: ${project_id}\n\n`;
      output += `**Progress:** ${progress}% (${done}/${total} steps)\n`;
      output += `**Done:** ${done} | **Running:** ${running} | **Failed:** ${failed} | **Pending:** ${pending}\n\n`;

      if (steps.length > 0) {
        output += `## Steps\n`;
        output += steps
          .map((s) => {
            const status = s["status"] as string;
            const icon =
              status === "done"
                ? "[DONE]"
                : status === "failed"
                  ? "[FAIL]"
                  : status === "in_progress" || status === "running"
                    ? "[....]"
                    : "[    ]";
            return `${icon} ${s["label"] ?? s["id"] ?? "unknown"} — ${s["owner_agent"] ?? ""}`;
          })
          .join("\n");
      }

      return { content: [{ type: "text" as const, text: output }] };
    }
  );
}
