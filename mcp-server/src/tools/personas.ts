import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import {
  listPersonas,
  getPersonaByFilename,
  getPersonaForAgent,
  searchPersonas,
} from "../lib/persona-loader.js";

export function registerPersonaTools(server: McpServer): void {
  server.tool(
    "list_personas",
    "List all 70 expert personas with name, role, and mapped agent IDs. These are deep professional profiles that enrich agent behavior.",
    {
      search: z.string().optional().describe("Search by name, role, or agent ID"),
    },
    async ({ search }) => {
      const personas = search ? searchPersonas(search) : listPersonas();

      if (personas.length === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: "No personas found. Try a broader search or omit the search parameter.",
            },
          ],
        };
      }

      let output = `# Expert Personas (${personas.length})\n\n`;
      output += personas
        .map(
          (p) =>
            `- **${p.name}** — ${p.role}\n  Agents: ${p.mapped_agents.length > 0 ? p.mapped_agents.map((a) => `\`${a}\``).join(", ") : "_unmapped_"}`
        )
        .join("\n");

      output += `\n\n_Use \`get_persona\` to load a full persona profile._`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "get_persona",
    "Load the full expert persona profile. Can look up by persona filename or by agent ID.",
    {
      filename: z
        .string()
        .optional()
        .describe('Persona filename, e.g. "aisha-patel-api-designer.md"'),
      agent_id: z
        .string()
        .optional()
        .describe('Agent ID to find mapped persona, e.g. "backend_engineer"'),
    },
    async ({ filename, agent_id }) => {
      let content: string | null = null;

      if (filename) {
        content = getPersonaByFilename(filename);
      } else if (agent_id) {
        content = getPersonaForAgent(agent_id);
      }

      if (!content) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Persona not found. Provide a filename or agent_id. Use list_personas to see all available personas.`,
            },
          ],
        };
      }

      return { content: [{ type: "text" as const, text: content }] };
    }
  );
}
