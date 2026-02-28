import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { existsSync, mkdirSync, writeFileSync } from "fs";
import { join } from "path";
import {
  listSkills,
  getSkill,
  getSkillsForAgent,
  getSkillsForDomain,
} from "../lib/skill-loader.js";

const ROOT = join(import.meta.dirname, "..", "..", "..");
const CLAUDE_SKILLS_DIR = join(ROOT, ".claude", "skills");

export function registerSkillTools(server: McpServer): void {
  server.tool(
    "list_skills",
    "List all available quality skills (security audit, code quality, accessibility check, etc.) with compatible agents.",
    {},
    async () => {
      const skills = listSkills();

      let output = `# Available Skills (${skills.length})\n\n`;
      output += skills
        .map(
          (s) =>
            `- **${s.name}** (\`${s.id}\`) — Priority: ${s.priority}\n  ${s.description}\n  Compatible agents: ${s.compatible_agents.slice(0, 5).join(", ")}${s.compatible_agents.length > 5 ? "..." : ""}`
        )
        .join("\n\n");

      output += `\n\n_Use \`get_skill\` to load the full checklist/framework for a skill._`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "get_skill",
    "Load the full SKILL.md content for a specific skill. Returns the complete checklist, framework, and output format.",
    {
      skill_id: z
        .string()
        .describe(
          'Skill ID, e.g. "security-audit", "code-quality", "accessibility-check"'
        ),
    },
    async ({ skill_id }) => {
      const skill = getSkill(skill_id);
      if (!skill) {
        const available = listSkills()
          .map((s) => `\`${s.id}\``)
          .join(", ");
        return {
          content: [
            {
              type: "text" as const,
              text: `Skill "${skill_id}" not found. Available skills: ${available}`,
            },
          ],
        };
      }

      let output = `# Skill: ${skill.name} (\`${skill.id}\`)\n\n`;
      output += `**Description:** ${skill.description}\n`;
      output += `**Version:** ${skill.version ?? "1.0.0"}\n`;
      output += `**Priority:** ${skill.priority}\n`;
      output += `**Compatible Agents:** ${skill.compatible_agents.join(", ")}\n`;
      if (skill.required_inputs?.length) {
        output += `**Required Inputs:** ${skill.required_inputs.join(", ")}\n`;
      }
      output += `**Outputs:** ${skill.provides_outputs.join(", ")}\n\n`;

      if (skill.skill_md) {
        output += `---\n\n${skill.skill_md}`;
      } else {
        output += `_No SKILL.md documentation available for this skill. Check if it has a TypeScript implementation in skills/${skill.id}/._`;
      }

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "check_skill_applicability",
    "Check which skills are applicable for a given agent or domain.",
    {
      agent_id: z.string().optional().describe("Agent ID to check skills for"),
      domain: z
        .string()
        .optional()
        .describe('Domain to check skills for, e.g. "tech/frontend"'),
    },
    async ({ agent_id, domain }) => {
      let skills = agent_id
        ? getSkillsForAgent(agent_id)
        : domain
          ? getSkillsForDomain(domain)
          : listSkills();

      if (skills.length === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: `No skills applicable for ${agent_id ? `agent "${agent_id}"` : `domain "${domain}"`}. Use list_skills to see all skills.`,
            },
          ],
        };
      }

      const output =
        `# Applicable Skills\n\n` +
        skills
          .map((s) => `- **${s.name}** (\`${s.id}\`): ${s.description}`)
          .join("\n") +
        `\n\n_Use \`get_skill\` to load the full checklist._`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "create_claude_skill",
    "Create a native Claude Code skill in .claude/skills/. Generates SKILL.md with proper frontmatter for /slash-command invocation, auto-detection, and tool restrictions.",
    {
      name: z.string().describe("Skill name (lowercase, hyphens). Becomes the /slash-command. E.g. 'deploy-check', 'ux-review'"),
      description: z.string().describe("What the skill does and when to use it. Written as: 'Use when someone asks to [action]'. Claude uses this for auto-invocation."),
      steps: z.array(z.string()).describe("Step-by-step workflow instructions (3-10 steps)"),
      allowed_tools: z.string().optional().describe("Comma-separated tools allowed without prompts. E.g. 'Read, Grep, Glob' or 'Bash(git *), Read'"),
      argument_hint: z.string().optional().describe("Autocomplete hint shown in / menu. E.g. '[file-path]', '[issue-number]'"),
      disable_model_invocation: z.boolean().optional().describe("Set true to only allow manual /slash-command invocation (no auto-detection). Good for skills with side effects."),
      context_fork: z.boolean().optional().describe("Set true to run in an isolated subagent context. Good for self-contained, verbose tasks."),
      output_format: z.string().optional().describe("Expected output format template or description"),
      notes: z.array(z.string()).optional().describe("Edge cases, constraints, or things the skill should NOT do"),
    },
    async ({ name, description, steps, allowed_tools, argument_hint, disable_model_invocation, context_fork, output_format, notes }) => {
      const skillDir = join(CLAUDE_SKILLS_DIR, name);
      if (existsSync(skillDir)) {
        return {
          content: [{
            type: "text" as const,
            text: `Skill "${name}" already exists at \`.claude/skills/${name}/\`. Edit the existing SKILL.md instead.`,
          }],
        };
      }

      // Build frontmatter
      let frontmatter = `---\nname: ${name}\ndescription: ${description}\n`;
      if (allowed_tools) frontmatter += `allowed-tools: ${allowed_tools}\n`;
      if (argument_hint) frontmatter += `argument-hint: ${argument_hint}\n`;
      if (disable_model_invocation) frontmatter += `disable-model-invocation: true\n`;
      if (context_fork) frontmatter += `context: fork\nagent: general-purpose\n`;
      frontmatter += `---`;

      // Build content
      const title = name.split("-").map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
      let content = `${frontmatter}\n\n# ${title}\n\n`;
      content += `## When to Use\n${description}\n\n`;
      content += `## Workflow\n\n`;
      steps.forEach((step, i) => {
        content += `${i + 1}. ${step}\n`;
      });

      if (output_format) {
        content += `\n## Output Format\n\n${output_format}\n`;
      }

      if (notes && notes.length > 0) {
        content += `\n## Notes\n\n`;
        notes.forEach((note) => {
          content += `- ${note}\n`;
        });
      }

      // Write files
      try {
        mkdirSync(skillDir, { recursive: true });
        writeFileSync(join(skillDir, "SKILL.md"), content, "utf-8");
      } catch (err) {
        return {
          content: [{
            type: "text" as const,
            text: `Failed to create skill "${name}": ${(err as Error).message}`,
          }],
          isError: true,
        };
      }

      return {
        content: [{
          type: "text" as const,
          text: `Created Claude Code skill "${name}" at \`.claude/skills/${name}/SKILL.md\`.\n\n**Invoke with:** \`/${name}\`${argument_hint ? ` ${argument_hint}` : ""}\n**Auto-detection:** ${disable_model_invocation ? "Disabled (manual only)" : "Enabled"}\n${allowed_tools ? `**Allowed tools:** ${allowed_tools}\n` : ""}${context_fork ? "**Runs in:** Isolated subagent\n" : ""}\n**Steps:**\n${steps.map((s, i) => `${i + 1}. ${s}`).join("\n")}`,
        }],
      };
    }
  );
}
