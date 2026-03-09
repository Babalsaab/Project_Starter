import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import {
  listMentors,
  getMentor,
  buildMentorReviewPrompt,
  buildAutoReviewPrompt,
} from "../lib/mentor-loader.js";

export function registerMentorTools(server: McpServer): void {
  server.tool(
    "list_mentors",
    "List all 30 world-class mentors with their domain focus and signature quote. These provide quality review lenses unique to this system.",
    {},
    async () => {
      const mentors = listMentors();

      let output = `# Mentor Layer (${mentors.length} World-Class Influences)\n\n`;
      output += mentors
        .map(
          (m) =>
            `- **${m.name}** (\`${m.id}\`) — ${m.domain_focus}\n  > "${m.quote}"`
        )
        .join("\n\n");

      output += `\n\n_Use \`mentor_review\` to apply a mentor's review lens to your work._`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "mentor_review",
    'Apply a mentor\'s review lens to content. Choose a specific mentor or use "auto" to select based on domain. Returns a structured review prompt with the mentor\'s principles and evaluation criteria.',
    {
      mentor_id: z
        .string()
        .describe(
          'Mentor ID (e.g. "steve_jobs", "linus_torvalds") or "auto" for domain-based selection'
        ),
      domain: z
        .string()
        .optional()
        .describe('Required when mentor_id is "auto". Domain like "tech/frontend", "marketing/email"'),
      content: z
        .string()
        .describe(
          "The content to review — code snippet, design decision, architecture proposal, etc."
        ),
    },
    async ({ mentor_id, domain, content }) => {
      let reviewPrompt: string;

      if (mentor_id === "auto") {
        if (!domain) {
          return {
            content: [
              {
                type: "text" as const,
                text: 'When using mentor_id "auto", you must provide a domain (e.g. "tech/frontend"). Use list_mentors to see all mentors.',
              },
            ],
          };
        }
        reviewPrompt = buildAutoReviewPrompt(domain, content);
      } else {
        const prompt = buildMentorReviewPrompt(mentor_id, content);
        if (!prompt) {
          const available = listMentors()
            .map((m) => `\`${m.id}\``)
            .join(", ");
          return {
            content: [
              {
                type: "text" as const,
                text: `Mentor "${mentor_id}" not found. Available mentors: ${available}`,
              },
            ],
          };
        }
        reviewPrompt = prompt;
      }

      return { content: [{ type: "text" as const, text: reviewPrompt }] };
    }
  );
}
