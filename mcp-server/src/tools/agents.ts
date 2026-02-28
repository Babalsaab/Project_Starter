import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import {
  loadAllAgents,
  getAgent,
  searchAgents,
  suggestAgentsForFile,
  type AgentConfig,
} from "../lib/agent-loader.js";
import { getPersonaForAgent } from "../lib/persona-loader.js";
import { getMentorsForAgent } from "../lib/mentor-loader.js";
import { getSkillsForAgent } from "../lib/skill-loader.js";

function formatAgentSummary(a: AgentConfig): string {
  return `- **${a.title}** (\`${a.id}\`) — ${a.domain} | Reports to: ${a.reports_to}\n  Responsibilities: ${a.responsibilities.slice(0, 2).join("; ")}`;
}

export function registerAgentTools(server: McpServer): void {
  server.tool(
    "list_agents",
    "List all 66+ specialist agents. Filter by domain (tech/frontend, marketing/email), chief (CTO/CMO), or keyword.",
    {
      domain: z
        .string()
        .optional()
        .describe(
          'Filter by domain prefix, e.g. "tech/frontend", "marketing/email", "tech"'
        ),
      chief: z
        .string()
        .optional()
        .describe('Filter by reporting chief: "CTO", "CMO", "CEO"'),
      keyword: z
        .string()
        .optional()
        .describe("Search keyword across agent titles, responsibilities, prompts"),
    },
    async ({ domain, chief, keyword }) => {
      const agents = searchAgents({ domain, chief, keyword });

      if (agents.length === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: "No agents found matching your criteria. Try broader filters or use list_agents without filters to see all agents.",
            },
          ],
        };
      }

      const grouped = new Map<string, AgentConfig[]>();
      for (const a of agents) {
        const group = a.reports_to || "Other";
        if (!grouped.has(group)) grouped.set(group, []);
        grouped.get(group)!.push(a);
      }

      let output = `# Agents Found: ${agents.length}\n\n`;
      for (const [chief, group] of grouped) {
        output += `## ${chief}\n${group.map(formatAgentSummary).join("\n")}\n\n`;
      }
      output += `\n_Use \`get_agent\` with an agent ID for full details, or \`invoke_agent\` to adopt an agent's identity._`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "get_agent",
    "Get full configuration for a specific agent including system prompt, expected inputs/outputs, mentors, and token cap.",
    {
      agent_id: z.string().describe('The agent ID, e.g. "backend_engineer", "ux_designer"'),
    },
    async ({ agent_id }) => {
      const agent = getAgent(agent_id);
      if (!agent) {
        const all = Array.from(loadAllAgents().keys());
        return {
          content: [
            {
              type: "text" as const,
              text: `Agent "${agent_id}" not found. Available agents:\n${all.join(", ")}`,
            },
          ],
        };
      }

      const output = `# ${agent.title} (\`${agent.id}\`)

**Domain:** ${agent.domain}
**Reports to:** ${agent.reports_to}
**Token Cap:** ${agent.token_cap ?? agent.token_cap_per_turn ?? "N/A"}

## Responsibilities
${agent.responsibilities.map((r) => `- ${r}`).join("\n")}

## Expected Inputs
${agent.expected_inputs.map((i) => `- \`${i}\``).join("\n")}

## Expected Outputs
${agent.expected_outputs.map((o) => `- \`${o}\``).join("\n")}

## Mentors
**Primary:** ${agent.mentors.primary.join(", ")}
${agent.mentors.secondary ? `**Secondary:** ${agent.mentors.secondary.join(", ")}` : ""}

## Mentor Lens
${agent.mentor_lens}

## System Prompt
\`\`\`
${agent.system_prompt}
\`\`\``;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "invoke_agent",
    "Adopt a specialist agent's identity. Returns the complete context block: system prompt + persona + mentor principles + applicable skills. Use this to 'become' a specialist for your current task.",
    {
      agent_id: z.string().describe('The agent ID to invoke, e.g. "security_engineer"'),
      include_persona: z
        .boolean()
        .default(true)
        .describe("Include the mapped expert persona profile"),
      include_mentors: z
        .boolean()
        .default(true)
        .describe("Include mentor principles and review lenses"),
      include_skills: z
        .boolean()
        .default(false)
        .describe("Include applicable skill checklists"),
    },
    async ({ agent_id, include_persona, include_mentors, include_skills }) => {
      const agent = getAgent(agent_id);
      if (!agent) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Agent "${agent_id}" not found. Use list_agents to see available agents.`,
            },
          ],
        };
      }

      let context = `# Agent Identity: ${agent.title}\n\n`;
      context += `## System Prompt\n\n${agent.system_prompt}\n\n`;
      context += `## Expected Inputs\n${agent.expected_inputs.map((i) => `- ${i}`).join("\n")}\n\n`;
      context += `## Expected Outputs\n${agent.expected_outputs.map((o) => `- ${o}`).join("\n")}\n\n`;

      if (include_persona) {
        const persona = getPersonaForAgent(agent_id);
        if (persona) {
          // Trim to first 3000 chars to stay token-efficient
          const trimmed =
            persona.length > 3000
              ? persona.slice(0, 3000) + "\n\n...[truncated for token efficiency]"
              : persona;
          context += `## Expert Persona\n\n${trimmed}\n\n`;
        }
      }

      if (include_mentors) {
        const mentors = getMentorsForAgent(agent_id);
        if (mentors.length > 0) {
          context += `## Mentor Influences\n\n`;
          for (const m of mentors.slice(0, 3)) {
            context += `### ${m.name} (${m.domain_focus})\n`;
            context += `> "${m.quote}"\n\n`;
            context += `**Principles:**\n${m.principles.slice(0, 3).map((p) => `- ${p}`).join("\n")}\n\n`;
            context += `**Review Lens:** ${m.review_lens}\n\n`;
          }
        }
      }

      if (include_skills) {
        const skills = getSkillsForAgent(agent_id);
        if (skills.length > 0) {
          context += `## Applicable Skills\n\n`;
          context += skills
            .map(
              (s) =>
                `- **${s.name}** (\`${s.id}\`): ${s.description}`
            )
            .join("\n");
          context += `\n\n_Use \`get_skill\` to load full skill checklists._\n`;
        }
      }

      context += `\n## Mentor Quality Check\n\n${agent.mentor_lens}\n`;
      context += `\n---\n_You are now operating as **${agent.title}**. Apply the system prompt, persona expertise, and mentor principles to your work. Stay within token cap: ${agent.token_cap ?? agent.token_cap_per_turn ?? "N/A"} tokens._`;

      return { content: [{ type: "text" as const, text: context }] };
    }
  );

  server.tool(
    "suggest_agents",
    "Given a file path or task description, suggest the most relevant specialist agents.",
    {
      file_path: z.string().optional().describe("Current file path to analyze"),
      task_description: z
        .string()
        .optional()
        .describe("Description of the task you're working on"),
    },
    async ({ file_path, task_description }) => {
      let suggestions: AgentConfig[] = [];

      if (file_path) {
        suggestions = suggestAgentsForFile(file_path);
      }

      if (task_description) {
        // Keyword-based search on task description
        const kw = task_description.toLowerCase();
        const kwResults = searchAgents({ keyword: kw });
        for (const agent of kwResults) {
          if (!suggestions.find((s) => s.id === agent.id)) {
            suggestions.push(agent);
          }
        }
      }

      if (suggestions.length === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: "No specific agents suggested. Use `list_agents` to browse all available agents.",
            },
          ],
        };
      }

      const output =
        `# Suggested Agents\n\n` +
        suggestions
          .slice(0, 5)
          .map(
            (a) =>
              `- **${a.title}** (\`${a.id}\`) — ${a.domain}\n  ${a.responsibilities[0]}`
          )
          .join("\n") +
        `\n\n_Use \`invoke_agent\` with an agent ID to adopt their identity._`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );
}
