/**
 * Agent Skills System
 *
 * Inspired by OpenClaw's skills/ directory and SKILL.md pattern.
 * Skills are reusable capability modules that agents can dynamically
 * load to extend their capabilities beyond their base system_prompt.
 *
 * Skills can be:
 * - Bundled: shipped with the repo (skills/)
 * - Workspace: project-specific (config/project-sessions/<id>/skills/)
 *
 * Each skill has:
 * - SKILL.md: prompt injection that teaches the agent the skill
 * - config.yaml: metadata, requirements, compatible agents
 */

import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface SkillConfig {
  id: string;
  name: string;
  description: string;
  version: string;
  compatible_agents: string[]; // agent IDs or "all"
  compatible_domains: string[]; // domain prefixes like "tech/frontend"
  required_inputs: string[];
  provides_outputs: string[];
  priority: number; // higher = loaded first
  enabled: boolean;
}

export interface LoadedSkill {
  config: SkillConfig;
  prompt: string; // the SKILL.md content
  source: "bundled" | "workspace";
}

// ─── Skills Loader ────────────────────────────────────────────────────────────

const BUNDLED_SKILLS_DIR = path.join(__dirname, "../skills");

/**
 * Discovers and loads all skills applicable to a specific agent.
 */
export function loadSkillsForAgent(
  agentId: string,
  agentDomain: string,
  projectId?: string
): LoadedSkill[] {
  const skills: LoadedSkill[] = [];

  // 1. Bundled skills
  if (fs.existsSync(BUNDLED_SKILLS_DIR)) {
    const bundled = discoverSkills(BUNDLED_SKILLS_DIR, "bundled");
    skills.push(...bundled);
  }

  // 2. Workspace/project-specific skills
  if (projectId) {
    const workspaceSkillsDir = path.join(
      "./config/project-sessions",
      projectId,
      "skills"
    );
    if (fs.existsSync(workspaceSkillsDir)) {
      const workspace = discoverSkills(workspaceSkillsDir, "workspace");
      skills.push(...workspace);
    }
  }

  // 3. Filter to compatible skills
  return skills
    .filter((skill) => isSkillCompatible(skill, agentId, agentDomain))
    .sort((a, b) => b.config.priority - a.config.priority);
}

/**
 * Builds a skills context string for prompt injection.
 * This gets appended to the agent's system prompt to give it new capabilities.
 */
export function buildSkillsContext(skills: LoadedSkill[]): string {
  if (skills.length === 0) return "";

  const parts = [
    "## Active Skills\n",
    "The following skills extend your capabilities:\n",
  ];

  for (const skill of skills) {
    parts.push(`### Skill: ${skill.config.name}`);
    parts.push(`*${skill.config.description}*\n`);
    parts.push(skill.prompt);
    parts.push("");
  }

  return parts.join("\n");
}

// ─── Internal Helpers ─────────────────────────────────────────────────────────

function discoverSkills(
  baseDir: string,
  source: "bundled" | "workspace"
): LoadedSkill[] {
  const skills: LoadedSkill[] = [];

  if (!fs.existsSync(baseDir)) return skills;

  const entries = fs.readdirSync(baseDir, { withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;

    const skillDir = path.join(baseDir, entry.name);
    const skillMdPath = path.join(skillDir, "SKILL.md");
    const configPath = path.join(skillDir, "config.yaml");

    // A valid skill needs at least a SKILL.md
    if (!fs.existsSync(skillMdPath)) continue;

    const prompt = fs.readFileSync(skillMdPath, "utf-8");

    // Load config if available, otherwise use defaults
    let config: SkillConfig;
    if (fs.existsSync(configPath)) {
      config = yaml.load(
        fs.readFileSync(configPath, "utf-8")
      ) as SkillConfig;
    } else {
      config = {
        id: entry.name,
        name: entry.name.replace(/-/g, " ").replace(/\b\w/g, (c) => c.toUpperCase()),
        description: `Skill from ${source} skills`,
        version: "1.0.0",
        compatible_agents: ["all"],
        compatible_domains: ["all"],
        required_inputs: [],
        provides_outputs: [],
        priority: 0,
        enabled: true,
      };
    }

    if (!config.enabled) continue;

    skills.push({ config, prompt, source });
  }

  return skills;
}

function isSkillCompatible(
  skill: LoadedSkill,
  agentId: string,
  agentDomain: string
): boolean {
  const { compatible_agents, compatible_domains } = skill.config;

  // "all" means universal compatibility
  if (compatible_agents.includes("all") || compatible_domains.includes("all")) {
    return true;
  }

  // Check agent ID match
  if (compatible_agents.includes(agentId)) return true;

  // Check domain match
  return compatible_domains.some((domain) => agentDomain.startsWith(domain));
}

/**
 * Lists all available skill IDs (for dashboard/registry display).
 */
export function listAvailableSkills(): Array<{
  id: string;
  name: string;
  source: "bundled" | "workspace";
  compatible_agents: string[];
}> {
  const results: Array<{
    id: string;
    name: string;
    source: "bundled" | "workspace";
    compatible_agents: string[];
  }> = [];

  if (fs.existsSync(BUNDLED_SKILLS_DIR)) {
    const skills = discoverSkills(BUNDLED_SKILLS_DIR, "bundled");
    for (const skill of skills) {
      results.push({
        id: skill.config.id,
        name: skill.config.name,
        source: skill.source,
        compatible_agents: skill.config.compatible_agents,
      });
    }
  }

  return results;
}
