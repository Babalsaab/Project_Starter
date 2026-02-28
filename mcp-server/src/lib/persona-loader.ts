import { readFileSync, readdirSync, existsSync } from "fs";
import { join, basename } from "path";

export interface PersonaSummary {
  filename: string;
  name: string;
  role: string;
  mapped_agents: string[];
}

const ROOT = join(import.meta.dirname, "..", "..", "..");
const PERSONAS_DIR = join(ROOT, "agents", "personas");

// Persona filename → agent ID mapping (from CLAUDE.md)
const PERSONA_AGENT_MAP: Record<string, string[]> = {
  "sarah-chen": ["ux_designer", "ui_designer"],
  "marcus-rodriguez": ["backend_engineer", "api_designer"],
  "jordan-park": ["web_frontend_engineer", "design_engineer"],
  "rachel-thompson": ["security_engineer"],
  "alex-kim-devops": ["devops_engineer", "release_engineer"],
  "anna-kim": ["accessibility_engineer"],
  "carlos-martinez": ["frontend_performance_engineer"],
  "david-chen": ["product_analyst", "experimentation_engineer"],
  "diana-patel": ["api_designer", "data_engineer"],
  "emily-watson": ["product_manager"],
  "jennifer-wu": ["qa_engineer", "test_automation_engineer"],
  "lisa-morgan": ["content_strategist", "editorial_writer"],
  "maria-santos": ["database_engineer"],
  "thomas-clark": ["ios_engineer", "android_engineer", "cross_platform_engineer"],
  "ryan-zhao": ["3d_designer"],
  "priya-kapoor": ["accessibility_engineer"],
  "kenji-tanaka": ["android_engineer"],
  "aisha-patel": ["api_designer"],
  "natasha-volkov": ["art_director"],
  "sofia-navarro": ["cross_platform_engineer"],
  "daniel-okafor": ["data_engineer"],
  "liam-chen": ["design_engineer"],
  "elena-petrova": ["design_systems_engineer"],
  "maya-washington": ["experimentation_engineer"],
  "nina-rossi": ["information_architect"],
  "yuki-matsuda": ["interaction_designer"],
  "kai-nakamura": ["ios_engineer"],
  "amara-osei": ["ml_engineer"],
  "sven-eriksson": ["motion_designer"],
  "victor-andrade": ["product_manager"],
  "hannah-johansson": ["prototype_engineer"],
  "grace-kim": ["qa_engineer"],
  "omar-hassan": ["release_engineer"],
  "james-mitchell": ["technical_writer"],
  "derek-okonkwo": ["test_automation_engineer"],
  "mia-chen-ramirez": ["ux_designer"],
  "alex-petrov": ["ux_researcher"],
  "raj-krishnamurthy": ["webgl_engineer"],
  "tanya-brooks": ["affiliate_manager"],
  "kevin-park": ["aso_specialist"],
  "zara-okafor-williams": ["brand_strategist"],
  "jade-moreno": ["community_manager"],
  "marcus-chen": ["crm_automation_specialist"],
  "samantha-liu": ["cro_specialist"],
  "danielle-foster": ["email_copywriter"],
  "arjun-mehta": ["email_designer"],
  "rachel-goldstein": ["email_platform_builder"],
  "natalie-rivera": ["email_strategist"],
  "tyler-nguyen": ["growth_marketer"],
  "camille-dubois": ["influencer_manager"],
  "wei-zhang": ["marketing_analytics"],
  "jordan-blake": ["marketing_copywriter"],
  "isabella-santos": ["marketing_designer"],
  "david-okonjo": ["marketing_strategist"],
  "lauren-torres": ["media_buyer"],
  "priya-sharma": ["partnership_manager"],
  "eric-chang": ["performance_marketer"],
  "nina-kowalski": ["push_messaging_specialist"],
  "ryan-patel": ["sem_specialist"],
  "anika-johansson": ["seo_specialist"],
  "amara-johnson": ["social_media_marketer"],
  "marco-valentino": ["social_video_creator"],
  "sophie-laurent": ["ux_writer"],
  "andre-williams": ["video_producer"],
  "elena-vasquez": ["feedback_agent"],
  "nathan-okafor": ["error_logging_agent"],
  "clara-fitzgerald": ["environment_checker_agent"],
  "tomas-herrera": ["dependency_tracker_agent"],
  "ingrid-holm": ["directory_housekeeping_agent"],
  "mateo-rivera": ["deployment_readiness_agent"],
};

// Reverse map: agent_id → persona filename prefix
let agentToPersonaMap: Map<string, string> | null = null;

function buildAgentToPersonaMap(): Map<string, string> {
  if (agentToPersonaMap) return agentToPersonaMap;
  agentToPersonaMap = new Map();
  for (const [personaKey, agentIds] of Object.entries(PERSONA_AGENT_MAP)) {
    for (const agentId of agentIds) {
      agentToPersonaMap.set(agentId, personaKey);
    }
  }
  return agentToPersonaMap;
}

function parsePersonaName(filename: string): { name: string; role: string } {
  // filename like: aisha-patel-api-designer.md
  const base = filename.replace(".md", "");
  const parts = base.split("-");

  // Heuristic: first 2-3 parts are name, rest is role
  // Try to match against known persona keys
  for (const key of Object.keys(PERSONA_AGENT_MAP)) {
    if (base.startsWith(key)) {
      const rolePart = base.slice(key.length + 1); // +1 for the hyphen
      const name = key
        .split("-")
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(" ");
      const role = rolePart
        .split("-")
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(" ");
      return { name, role };
    }
  }

  // Fallback: assume first two parts are name
  const name = parts
    .slice(0, 2)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
  const role = parts
    .slice(2)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
  return { name, role };
}

function findMappedAgents(filename: string): string[] {
  const base = filename.replace(".md", "");
  for (const [key, agents] of Object.entries(PERSONA_AGENT_MAP)) {
    if (base.startsWith(key) || base.includes(key)) {
      return agents;
    }
  }
  return [];
}

let personaListCache: PersonaSummary[] | null = null;
let personaCacheTimestamp = 0;
const PERSONA_CACHE_TTL_MS = 60_000; // 60 seconds TTL

export function listPersonas(): PersonaSummary[] {
  const now = Date.now();
  if (personaListCache && now - personaCacheTimestamp < PERSONA_CACHE_TTL_MS) {
    return personaListCache;
  }
  if (!existsSync(PERSONAS_DIR)) return [];

  personaCacheTimestamp = now;
  personaListCache = readdirSync(PERSONAS_DIR)
    .filter((f) => f.endsWith(".md"))
    .map((f) => {
      const { name, role } = parsePersonaName(f);
      return {
        filename: f,
        name,
        role,
        mapped_agents: findMappedAgents(f),
      };
    })
    .sort((a, b) => a.name.localeCompare(b.name));

  return personaListCache;
}

export function getPersonaByFilename(filename: string): string | null {
  const filePath = join(PERSONAS_DIR, filename);
  if (!existsSync(filePath)) return null;
  return readFileSync(filePath, "utf-8");
}

export function getPersonaForAgent(agentId: string): string | null {
  const map = buildAgentToPersonaMap();
  const personaKey = map.get(agentId);
  if (!personaKey) return null;

  // Use cached persona list instead of re-scanning directory
  const personas = listPersonas();
  const match = personas.find((p) =>
    p.filename.replace(".md", "").startsWith(personaKey)
  );
  if (!match) return null;

  return readFileSync(join(PERSONAS_DIR, match.filename), "utf-8");
}

export function searchPersonas(query: string): PersonaSummary[] {
  const kw = query.toLowerCase();
  return listPersonas().filter((p) => {
    const searchable = [p.name, p.role, ...p.mapped_agents]
      .join(" ")
      .toLowerCase();
    return searchable.includes(kw);
  });
}
