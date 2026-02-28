import { readFileSync, readdirSync, existsSync } from "fs";
import { join } from "path";
import yaml from "js-yaml";

export interface SkillConfig {
  id: string;
  name: string;
  description: string;
  version?: string;
  compatible_agents: string[];
  compatible_domains?: string[];
  required_inputs?: string[];
  provides_outputs: string[];
  priority: number;
  enabled?: boolean;
}

export interface SkillFull extends SkillConfig {
  skill_md: string | null;
}

const ROOT = join(import.meta.dirname, "..", "..", "..");
const SKILLS_DIR = join(ROOT, "skills");

let skillCache: Map<string, SkillConfig> | null = null;

function loadSkillConfig(skillDir: string): SkillConfig | null {
  const configPath = join(skillDir, "config.yaml");
  if (!existsSync(configPath)) return null;

  const content = readFileSync(configPath, "utf-8");
  return yaml.load(content) as SkillConfig;
}

function loadSkillMd(skillDir: string): string | null {
  const skillMdPath = join(skillDir, "SKILL.md");
  if (!existsSync(skillMdPath)) return null;
  return readFileSync(skillMdPath, "utf-8");
}

export function loadAllSkills(): Map<string, SkillConfig> {
  if (skillCache) return skillCache;
  if (!existsSync(SKILLS_DIR)) {
    skillCache = new Map();
    return skillCache;
  }

  skillCache = new Map();
  for (const dir of readdirSync(SKILLS_DIR, { withFileTypes: true })) {
    if (!dir.isDirectory()) continue;
    const config = loadSkillConfig(join(SKILLS_DIR, dir.name));
    if (config) {
      skillCache.set(config.id, config);
    }
  }
  return skillCache;
}

export function getSkill(id: string): SkillFull | null {
  const config = loadAllSkills().get(id);
  if (!config) return null;

  const skillDir = join(SKILLS_DIR, id);
  const skill_md = loadSkillMd(skillDir);

  return { ...config, skill_md };
}

export function listSkills(): SkillConfig[] {
  return Array.from(loadAllSkills().values()).sort(
    (a, b) => b.priority - a.priority
  );
}

export function getSkillsForAgent(agentId: string): SkillConfig[] {
  return Array.from(loadAllSkills().values()).filter((s) =>
    s.compatible_agents.includes(agentId)
  );
}

export function getSkillsForDomain(domain: string): SkillConfig[] {
  return Array.from(loadAllSkills().values()).filter(
    (s) =>
      s.compatible_domains?.some((d) => domain.startsWith(d)) ?? false
  );
}
