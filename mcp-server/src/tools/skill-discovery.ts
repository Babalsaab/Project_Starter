/**
 * Self-Extending Skills System MCP Tools
 *
 * Discover, install, generate, and manage skills:
 * - Search external skill registries (GitHub, URLs)
 * - Install skills from remote sources
 * - Generate new skills from templates
 * - Skill marketplace with curated collections
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from "fs";
import { join } from "path";
import { listSkills, getSkill } from "../lib/skill-loader.js";

const ROOT = join(import.meta.dirname, "..", "..", "..");
const SKILLS_DIR = join(ROOT, "skills");
const EXTERNAL_SKILLS_DIR = join(ROOT, "skills", "external");
const SKILL_REGISTRY_FILE = join(ROOT, "config", "registries", "skill-registry.yaml");

// ─── Curated Skill Registries ───────────────────────────────────────────────

interface ExternalSkillSource {
  name: string;
  url: string;
  description: string;
  category: string;
  skills: string[];
  format: "skill-md" | "csv-data" | "prompt" | "yaml";
  compatibility: string[];
}

const CURATED_REGISTRIES: ExternalSkillSource[] = [
  {
    name: "Anthropic Official Skills",
    url: "https://github.com/anthropics/skills",
    description: "Official Anthropic skills: PDF, DOCX, PPTX, XLSX, frontend-design, webapp-testing, MCP builder",
    category: "official",
    skills: ["pdf", "docx", "pptx", "xlsx", "frontend-design", "webapp-testing", "mcp-builder", "canvas-design", "brand-guidelines", "skill-creator"],
    format: "skill-md",
    compatibility: ["claude-code", "cursor", "windsurf", "copilot"],
  },
  {
    name: "Corey Haines Marketing Skills",
    url: "https://github.com/coreyhaines31/marketingskills",
    description: "32 marketing skills: CRO, SEO, copywriting, email, analytics, pricing, growth",
    category: "marketing",
    skills: ["page-cro", "signup-flow-cro", "onboarding-cro", "form-cro", "popup-cro", "paywall-upgrade-cro", "copywriting", "copy-editing", "cold-email", "email-sequence", "social-content", "seo-audit", "ai-seo", "programmatic-seo", "site-architecture", "competitor-alternatives", "schema-markup", "paid-ads", "ad-creative", "analytics-tracking", "ab-test-setup", "churn-prevention", "free-tool-strategy", "referral-program", "marketing-ideas", "marketing-psychology", "launch-strategy", "pricing-strategy", "revops", "sales-enablement", "content-strategy", "product-marketing-context"],
    format: "skill-md",
    compatibility: ["claude-code", "cursor", "windsurf", "copilot"],
  },
  {
    name: "UI/UX Pro Max",
    url: "https://github.com/nextlevelbuilder/ui-ux-pro-max-skill",
    description: "Design intelligence: 67 UI styles, 96 color palettes, 57 font pairings, 100 industry reasoning rules, BM25 search",
    category: "design",
    skills: ["ui-ux-pro-max"],
    format: "csv-data",
    compatibility: ["claude-code", "cursor", "windsurf"],
  },
  {
    name: "Obra Superpowers",
    url: "https://github.com/obra/superpowers",
    description: "14 dev workflow skills: TDD, debugging, planning, code review, git worktrees, parallel agents",
    category: "development",
    skills: ["test-driven-development", "systematic-debugging", "brainstorming", "writing-plans", "executing-plans", "dispatching-parallel-agents", "requesting-code-review", "receiving-code-review", "subagent-driven-development", "using-git-worktrees"],
    format: "skill-md",
    compatibility: ["claude-code"],
  },
  {
    name: "Superskills (Vibecode)",
    url: "https://superskills.vibecode.run",
    description: "Media production skills: Remotion video generator, ElevenLabs audio",
    category: "media",
    skills: ["video-generator", "elevenlabs-music"],
    format: "skill-md",
    compatibility: ["claude-code", "cursor"],
  },
  {
    name: "Gravity Claw Features",
    url: "https://gravity-claw.vercel.app",
    description: "58+ selectable AI agent features: memory tiers, MCP bridge, proactive behavior, security",
    category: "agent-architecture",
    skills: ["three-tier-memory", "mcp-tool-bridge", "proactive-scheduler", "container-sandboxing", "agent-swarms"],
    format: "prompt",
    compatibility: ["claude-code", "cursor", "windsurf", "copilot"],
  },
  {
    name: "AntiGravity Methodology",
    url: "https://github.com/tfriedel/antigravity_prompts",
    description: "Google DeepMind's agentic methodology: KI system, 5-phase web dev, design excellence gates",
    category: "methodology",
    skills: ["knowledge-items", "design-excellence-gate", "5-phase-web-dev", "seo-auto-check"],
    format: "prompt",
    compatibility: ["claude-code", "cursor", "windsurf", "copilot"],
  },
  {
    name: "Google Stitch Skills",
    url: "https://github.com/google-labs-code/stitch-skills",
    description: "Google Labs design-to-code pipeline: design system docs, React components from Stitch screens, multi-page site generation, shadcn/ui integration, video walkthroughs",
    category: "design-to-code",
    skills: ["design-md", "enhance-prompt", "react-components", "stitch-loop", "shadcn-ui", "remotion"],
    format: "skill-md",
    compatibility: ["claude-code", "cursor", "windsurf", "copilot"],
  },
];

// ─── Skill Template ─────────────────────────────────────────────────────────

function generateSkillTemplate(opts: {
  id: string;
  name: string;
  description: string;
  domain: string;
  compatible_agents: string[];
  checklist_items: string[];
}): { configYaml: string; skillMd: string } {
  const configYaml = `id: "${opts.id}"
name: "${opts.name}"
description: "${opts.description}"
version: "1.0.0"
domain: "${opts.domain}"
priority: 10
compatible_agents:
${opts.compatible_agents.map((a) => `  - "${a}"`).join("\n")}
required_inputs: []
provides_outputs:
  - "${opts.id}_report"
`;

  const skillMd = `---
name: ${opts.id}
description: ${opts.description}
version: 1.0.0
compatible_agents: [${opts.compatible_agents.join(", ")}]
domain: ${opts.domain}
priority: 10
user_invocable: true
---

# ${opts.name}

## Purpose
${opts.description}

## When to Apply
- When working on files in the \`${opts.domain}\` domain
- When any of these agents are active: ${opts.compatible_agents.join(", ")}

## Checklist

${opts.checklist_items.map((item, i) => `### ${i + 1}. ${item}\n- [ ] Verify this requirement\n- [ ] Document findings\n`).join("\n")}

## Output Format

\`\`\`markdown
# ${opts.name} Report

## Summary
[Overall assessment]

## Findings
${opts.checklist_items.map((item, i) => `### ${i + 1}. ${item}\n- Status: PASS / FAIL / N/A\n- Details: ...\n`).join("\n")}

## Recommendations
[Prioritized list of improvements]
\`\`\`
`;

  return { configYaml, skillMd };
}

// ─── MCP Tools ──────────────────────────────────────────────────────────────

export function registerSkillDiscoveryTools(server: McpServer): void {
  server.tool(
    "discover_skills",
    "Search curated skill registries for skills to install. Browse skills from Anthropic, marketing specialists, UI/UX design, development workflows, media production, and more.",
    {
      category: z
        .string()
        .optional()
        .describe("Filter by category: official, marketing, design, development, media, agent-architecture, methodology"),
      query: z
        .string()
        .optional()
        .describe("Search query to find specific skills"),
    },
    async ({ category, query }) => {
      let registries = CURATED_REGISTRIES;

      if (category) {
        registries = registries.filter((r) => r.category === category);
      }

      if (query) {
        const q = query.toLowerCase();
        registries = registries.filter(
          (r) =>
            r.name.toLowerCase().includes(q) ||
            r.description.toLowerCase().includes(q) ||
            r.skills.some((s) => s.includes(q))
        );
      }

      if (registries.length === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: `No registries match your search. Available categories: ${CURATED_REGISTRIES.map((r) => r.category).filter((c, i, a) => a.indexOf(c) === i).join(", ")}`,
            },
          ],
        };
      }

      let output = `# Skill Registries (${registries.length} sources, ${registries.reduce((sum, r) => sum + r.skills.length, 0)} skills)\n\n`;

      for (const reg of registries) {
        output += `## ${reg.name}\n`;
        output += `**Category:** ${reg.category} | **Format:** ${reg.format}\n`;
        output += `**URL:** ${reg.url}\n`;
        output += `**Description:** ${reg.description}\n`;
        output += `**Compatible with:** ${reg.compatibility.join(", ")}\n`;
        output += `**Skills (${reg.skills.length}):** ${reg.skills.join(", ")}\n\n`;
      }

      output += `_Use \`install_skill\` to install a skill from any of these registries._`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "install_skill",
    "Install a skill from an external registry into the project's skills directory. Creates the skill directory with config.yaml and SKILL.md.",
    {
      registry: z.string().describe("Registry name to install from (e.g. 'Anthropic Official Skills')"),
      skill_name: z.string().describe("Skill name to install (e.g. 'frontend-design')"),
    },
    async ({ registry, skill_name }) => {
      const reg = CURATED_REGISTRIES.find(
        (r) => r.name.toLowerCase().includes(registry.toLowerCase())
      );

      if (!reg) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Registry "${registry}" not found. Use \`discover_skills\` to see available registries.`,
            },
          ],
        };
      }

      if (!reg.skills.includes(skill_name)) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Skill "${skill_name}" not found in "${reg.name}". Available: ${reg.skills.join(", ")}`,
            },
          ],
        };
      }

      // Create external skill directory
      try {
        if (!existsSync(EXTERNAL_SKILLS_DIR)) {
          mkdirSync(EXTERNAL_SKILLS_DIR, { recursive: true });
        }
      } catch (err) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Failed to create external skills directory: ${(err as Error).message}`,
            },
          ],
          isError: true,
        };
      }

      const skillDir = join(EXTERNAL_SKILLS_DIR, skill_name);
      if (existsSync(skillDir)) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Skill "${skill_name}" is already installed at \`skills/external/${skill_name}/\`.`,
            },
          ],
        };
      }

      // Generate placeholder files
      const { configYaml, skillMd } = generateSkillTemplate({
        id: skill_name,
        name: skill_name.split("-").map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(" "),
        description: `Installed from ${reg.name}. See ${reg.url} for full documentation.`,
        domain: reg.category === "marketing" ? "marketing" : "tech",
        compatible_agents: reg.category === "marketing"
          ? ["marketing_strategist", "content_strategist", "marketing_copywriter"]
          : ["web_frontend_engineer", "backend_engineer", "qa_engineer"],
        checklist_items: [
          "Review skill documentation",
          "Verify compatibility with project",
          "Run skill against sample content",
        ],
      });

      try {
        mkdirSync(skillDir, { recursive: true });
        writeFileSync(join(skillDir, "config.yaml"), configYaml, "utf-8");
        writeFileSync(join(skillDir, "SKILL.md"), skillMd, "utf-8");

        // Create a README with installation source
        const readme = `# ${skill_name}\n\nInstalled from: ${reg.name}\nSource: ${reg.url}\nInstalled: ${new Date().toISOString()}\n\n## Setup\n\nTo get the full skill content, clone the source repository:\n\n\`\`\`bash\ngit clone ${reg.url}\n\`\`\`\n\nThen copy the relevant SKILL.md and supporting files into this directory.\n`;
        writeFileSync(join(skillDir, "README.md"), readme, "utf-8");
      } catch (err) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Failed to install skill "${skill_name}": ${(err as Error).message}`,
            },
          ],
          isError: true,
        };
      }

      return {
        content: [
          {
            type: "text" as const,
            text: `Installed skill "${skill_name}" from ${reg.name}.\n\n**Location:** \`skills/external/${skill_name}/\`\n**Files created:**\n- config.yaml\n- SKILL.md (template)\n- README.md\n\nFor the full skill content, visit: ${reg.url}\nThe SKILL.md contains a template — replace it with the actual content from the source.`,
          },
        ],
      };
    }
  );

  server.tool(
    "create_skill",
    "Generate a new custom skill from a template. Creates the skill directory with config.yaml and SKILL.md.",
    {
      id: z.string().describe("Skill ID (lowercase, hyphens). E.g. 'ux-review', 'api-security'"),
      name: z.string().describe("Human-readable name. E.g. 'UX Review', 'API Security Audit'"),
      description: z.string().describe("What this skill does and when to use it"),
      domain: z.string().describe("Domain. E.g. 'tech/frontend', 'marketing/seo', 'tech/security'"),
      compatible_agents: z.array(z.string()).describe("List of agent IDs this skill works with"),
      checklist_items: z.array(z.string()).describe("Checklist items for the skill (3-10 items)"),
    },
    async ({ id, name, description, domain, compatible_agents, checklist_items }) => {
      const skillDir = join(SKILLS_DIR, id);
      if (existsSync(skillDir)) {
        return {
          content: [
            { type: "text" as const, text: `Skill "${id}" already exists at \`skills/${id}/\`.` },
          ],
        };
      }

      const { configYaml, skillMd } = generateSkillTemplate({
        id,
        name,
        description,
        domain,
        compatible_agents,
        checklist_items,
      });

      try {
        mkdirSync(skillDir, { recursive: true });
        writeFileSync(join(skillDir, "config.yaml"), configYaml, "utf-8");
        writeFileSync(join(skillDir, "SKILL.md"), skillMd, "utf-8");
      } catch (err) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Failed to create skill "${id}": ${(err as Error).message}`,
            },
          ],
          isError: true,
        };
      }

      return {
        content: [
          {
            type: "text" as const,
            text: `Created skill "${name}" at \`skills/${id}/\`.\n\n**Files:**\n- \`skills/${id}/config.yaml\` — Skill configuration\n- \`skills/${id}/SKILL.md\` — Skill documentation and checklist\n\nEdit the SKILL.md to customize the checklist and instructions.`,
          },
        ],
      };
    }
  );

  server.tool(
    "skill_status",
    "Show all installed skills (bundled + external) with their compatibility status.",
    {},
    async () => {
      const bundled = listSkills();

      // Check for external skills
      const external: Array<{ id: string; name: string }> = [];
      if (existsSync(EXTERNAL_SKILLS_DIR)) {
        const dirs = readdirSync(EXTERNAL_SKILLS_DIR, { withFileTypes: true })
          .filter((d) => d.isDirectory());
        for (const dir of dirs) {
          external.push({ id: dir.name, name: dir.name });
        }
      }

      let output = `# Skill Status\n\n`;
      output += `**Bundled Skills:** ${bundled.length}\n`;
      output += `**External Skills:** ${external.length}\n`;
      output += `**Total:** ${bundled.length + external.length}\n\n`;

      output += `## Bundled Skills\n`;
      for (const skill of bundled) {
        output += `- **${skill.name}** (\`${skill.id}\`) — ${skill.description}\n`;
      }

      if (external.length > 0) {
        output += `\n## External Skills (installed from registries)\n`;
        for (const skill of external) {
          output += `- **${skill.name}** (\`skills/external/${skill.id}/\`)\n`;
        }
      }

      output += `\n## Available Registries\n`;
      output += `${CURATED_REGISTRIES.length} curated registries with ${CURATED_REGISTRIES.reduce((s, r) => s + r.skills.length, 0)} total skills.\n`;
      output += `Use \`discover_skills\` to browse and \`install_skill\` to install.`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );
}
