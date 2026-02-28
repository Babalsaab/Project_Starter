import { readFileSync, readdirSync, existsSync } from "fs";
import { join, basename } from "path";
import yaml from "js-yaml";

export interface AgentConfig {
  id: string;
  title: string;
  domain: string;
  reports_to: string;
  responsibilities: string[];
  expected_inputs: string[];
  expected_outputs: string[];
  token_cap: number;
  mentors: {
    primary: string[];
    secondary?: string[];
  };
  mentor_lens: string;
  system_prompt: string;
  // Chiefs have extra fields
  tier?: string;
  description?: string;
  token_cap_per_turn?: number;
}

const ROOT = join(import.meta.dirname, "..", "..", "..");
const CHIEFS_DIR = join(ROOT, "agents", "chiefs");
const TECH_DIR = join(ROOT, "agents", "pool", "tech");
const MARKETING_DIR = join(ROOT, "agents", "pool", "marketing");

let agentCache: Map<string, AgentConfig> | null = null;
let agentCacheTimestamp = 0;
const AGENT_CACHE_TTL_MS = 60_000; // 60 seconds TTL

function loadYamlDir(dir: string): AgentConfig[] {
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((f) => f.endsWith(".yaml") || f.endsWith(".yml"))
    .map((f) => {
      try {
        const content = readFileSync(join(dir, f), "utf-8");
        return yaml.load(content) as AgentConfig;
      } catch {
        return null;
      }
    })
    .filter(Boolean) as AgentConfig[];
}

export function loadAllAgents(): Map<string, AgentConfig> {
  const now = Date.now();
  if (agentCache && now - agentCacheTimestamp < AGENT_CACHE_TTL_MS) {
    return agentCache;
  }

  agentCache = new Map();
  agentCacheTimestamp = now;
  const dirs = [CHIEFS_DIR, TECH_DIR, MARKETING_DIR];
  for (const dir of dirs) {
    for (const agent of loadYamlDir(dir)) {
      agentCache.set(agent.id, agent);
    }
  }
  return agentCache;
}

export function getAgent(id: string): AgentConfig | undefined {
  return loadAllAgents().get(id);
}

export function searchAgents(query: {
  domain?: string;
  chief?: string;
  keyword?: string;
}): AgentConfig[] {
  const agents = Array.from(loadAllAgents().values());

  return agents.filter((a) => {
    if (query.domain && !a.domain.startsWith(query.domain)) return false;
    if (query.chief && a.reports_to.toLowerCase() !== query.chief.toLowerCase())
      return false;
    if (query.keyword) {
      const kw = query.keyword.toLowerCase();
      const searchable = [
        a.id,
        a.title,
        a.domain,
        ...a.responsibilities,
        a.system_prompt,
      ]
        .join(" ")
        .toLowerCase();
      if (!searchable.includes(kw)) return false;
    }
    return true;
  });
}

export function suggestAgentsForFile(filePath: string): AgentConfig[] {
  const agents = loadAllAgents();
  const suggestions: string[] = [];
  const ext = filePath.split(".").pop()?.toLowerCase() ?? "";
  const pathLower = filePath.toLowerCase().replace(/\\/g, "/");

  // File extension mapping
  const extMap: Record<string, string[]> = {
    tsx: ["web_frontend_engineer", "ux_designer", "design_engineer"],
    jsx: ["web_frontend_engineer", "design_engineer"],
    ts: ["backend_engineer", "web_frontend_engineer"],
    js: ["backend_engineer", "web_frontend_engineer"],
    prisma: ["database_engineer"],
    sql: ["database_engineer"],
    css: ["web_frontend_engineer", "design_systems_engineer"],
    scss: ["web_frontend_engineer", "design_systems_engineer"],
    swift: ["ios_engineer"],
    kt: ["android_engineer"],
    py: ["backend_engineer", "ml_engineer", "data_engineer"],
    yaml: ["devops_engineer"],
    yml: ["devops_engineer"],
    dockerfile: ["devops_engineer"],
    md: ["technical_writer", "content_strategist"],
    html: ["web_frontend_engineer", "accessibility_engineer"],
  };

  // Path pattern mapping
  const pathMap: Array<{ pattern: string; agents: string[] }> = [
    { pattern: "src/app/api/", agents: ["api_designer", "backend_engineer"] },
    {
      pattern: "src/components/",
      agents: ["web_frontend_engineer", "ux_designer"],
    },
    { pattern: "src/app/auth/", agents: ["security_engineer"] },
    { pattern: "orchestrator/", agents: ["backend_engineer", "devops_engineer"] },
    { pattern: "agents/", agents: ["product_manager"] },
    { pattern: "config/", agents: ["devops_engineer"] },
    { pattern: "prisma/", agents: ["database_engineer"] },
    { pattern: ".github/", agents: ["devops_engineer", "release_engineer"] },
    { pattern: "skills/", agents: ["qa_engineer"] },
    { pattern: "e2e/", agents: ["test_automation_engineer", "qa_engineer"] },
    {
      pattern: ".test.",
      agents: ["qa_engineer", "test_automation_engineer"],
    },
    {
      pattern: "marketing/",
      agents: ["marketing_strategist", "content_strategist"],
    },
  ];

  if (extMap[ext]) suggestions.push(...extMap[ext]);

  for (const { pattern, agents: agentIds } of pathMap) {
    if (pathLower.includes(pattern)) suggestions.push(...agentIds);
  }

  // Deduplicate and resolve
  const unique = [...new Set(suggestions)];
  return unique
    .map((id) => agents.get(id))
    .filter((a): a is AgentConfig => a !== undefined);
}

export function invalidateCache(): void {
  agentCache = null;
}
