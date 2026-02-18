/**
 * Agent Configurator
 * Reads the Master PRD and selected agents, then writes per-project
 * config that the orchestrator uses at runtime.
 */

import { AgentSelection } from "./prd-generator";
import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";

export interface AgentConfig {
  id: string;
  title: string;
  domain: string;
  reports_to: string;
  system_prompt: string;
  token_cap: number;
  responsibilities: string[];
  expected_inputs: string[];
  expected_outputs: string[];
  mentors?: {
    primary: string[];
    secondary: string[];
  };
  mentor_lens?: string;
}

export interface ProjectSession {
  project_id: string;
  project_name: string;
  created_at: string;
  active_agents: string[];
  agent_configs: Record<string, Partial<AgentConfig>>;
  prd_path: string;
  status: "initialising" | "running" | "paused" | "complete" | "failed";
}

const AGENT_POOL_DIR = path.join(__dirname, "../agents/pool");

/**
 * Loads a YAML agent definition from the pool.
 */
export function loadAgentFromPool(agentId: string): AgentConfig | null {
  // Search in all subdirectories
  const subdirs = ["tech", "marketing", "chiefs"];
  for (const dir of subdirs) {
    const filepath = path.join(AGENT_POOL_DIR, dir, `${agentId}.yaml`);
    if (fs.existsSync(filepath)) {
      const content = fs.readFileSync(filepath, "utf-8");
      return yaml.load(content) as AgentConfig;
    }
  }
  // Also check chiefs
  const chiefPath = path.join(__dirname, "../agents/chiefs", `${agentId}.yaml`);
  if (fs.existsSync(chiefPath)) {
    const content = fs.readFileSync(chiefPath, "utf-8");
    return yaml.load(content) as AgentConfig;
  }
  return null;
}

/**
 * Creates a project session directory and config file.
 */
export function createProjectSession(
  projectId: string,
  projectName: string,
  selectedAgents: AgentSelection[],
  prdPath: string
): ProjectSession {
  const sessionDir = path.join("./config/project-sessions", projectId);
  if (!fs.existsSync(sessionDir)) {
    fs.mkdirSync(sessionDir, { recursive: true });
  }

  // Load each agent config and store a lightweight ref
  const agentConfigs: Record<string, Partial<AgentConfig>> = {};
  const loadedAgentIds: string[] = [];

  // Always include chiefs
  const chiefsToLoad = ["CEO", "CMO", "CTO"];
  const hasTech = selectedAgents.some(a => a.domain.startsWith("tech"));
  const hasMarketing = selectedAgents.some(a => a.domain.startsWith("marketing"));
  if (hasTech && hasMarketing) chiefsToLoad.push("COO");

  for (const chiefId of chiefsToLoad) {
    const config = loadAgentFromPool(chiefId.toLowerCase());
    if (config) {
      agentConfigs[chiefId] = {
        id: config.id,
        title: config.title,
        domain: config.domain,
        token_cap: config.token_cap
      };
      loadedAgentIds.push(chiefId);
    }
  }

  // Load specialist agents
  for (const agent of selectedAgents) {
    const config = loadAgentFromPool(agent.id);
    if (config) {
      agentConfigs[agent.id] = {
        id: config.id,
        title: config.title,
        domain: config.domain,
        token_cap: config.token_cap,
        expected_inputs: config.expected_inputs,
        expected_outputs: config.expected_outputs
      };
      loadedAgentIds.push(agent.id);
    } else {
      // Placeholder for missing agents
      agentConfigs[agent.id] = {
        id: agent.id,
        title: `[PLACEHOLDER] ${agent.id}`,
        domain: agent.domain,
        token_cap: 2000
      };
      loadedAgentIds.push(agent.id);
    }
  }

  const session: ProjectSession = {
    project_id: projectId,
    project_name: projectName,
    created_at: new Date().toISOString(),
    active_agents: loadedAgentIds,
    agent_configs: agentConfigs,
    prd_path: prdPath,
    status: "initialising"
  };

  // Save session config
  const sessionConfigPath = path.join(sessionDir, "session.yaml");
  fs.writeFileSync(sessionConfigPath, yaml.dump(session), "utf-8");

  // Save agent selection with reasons for transparency
  const selectionPath = path.join(sessionDir, "agent-selection.yaml");
  fs.writeFileSync(
    selectionPath,
    yaml.dump({ project_id: projectId, selected_agents: selectedAgents }),
    "utf-8"
  );

  return session;
}

/**
 * Prints a human-readable summary of the configured agents.
 */
export function printAgentSummary(
  session: ProjectSession,
  selectedAgents: AgentSelection[]
): string {
  const lines: string[] = [
    "",
    "═══════════════════════════════════════════════════════════",
    `  AGENT CONFIGURATION FOR: ${session.project_name}`,
    "═══════════════════════════════════════════════════════════",
    "",
    "  CHIEFS:",
    "  ──────────────────────────────────────────────────────",
  ];

  const chiefsInSession = Object.values(session.agent_configs).filter(
    a => ["CEO", "CMO", "CTO", "COO"].includes(a.id?.toUpperCase() ?? "")
  );

  for (const chief of chiefsInSession) {
    lines.push(`  ✦ ${(chief.id ?? "").toUpperCase()} — ${chief.title}`);
  }

  lines.push("");
  lines.push("  TECH SPECIALISTS:");
  lines.push("  ──────────────────────────────────────────────────────");

  const techAgents = selectedAgents.filter(a => a.domain.startsWith("tech"));
  if (techAgents.length === 0) {
    lines.push("  (none — no tech work in scope)");
  } else {
    for (const a of techAgents) {
      const config = session.agent_configs[a.id];
      lines.push(`  → ${a.id.padEnd(35)} ${a.reason}`);
    }
  }

  lines.push("");
  lines.push("  MARKETING SPECIALISTS:");
  lines.push("  ──────────────────────────────────────────────────────");

  const mktAgents = selectedAgents.filter(a => a.domain.startsWith("marketing"));
  if (mktAgents.length === 0) {
    lines.push("  (none — no marketing work in scope)");
  } else {
    for (const a of mktAgents) {
      lines.push(`  → ${a.id.padEnd(35)} ${a.reason}`);
    }
  }

  lines.push("");
  lines.push(`  TOTAL AGENTS ACTIVE: ${session.active_agents.length}`);
  lines.push("═══════════════════════════════════════════════════════════");
  lines.push("");

  return lines.join("\n");
}

/**
 * Updates session status.
 */
export function updateSessionStatus(
  projectId: string,
  status: ProjectSession["status"]
): void {
  const sessionPath = path.join(
    "./config/project-sessions",
    projectId,
    "session.yaml"
  );
  if (fs.existsSync(sessionPath)) {
    const session = yaml.load(fs.readFileSync(sessionPath, "utf-8")) as ProjectSession;
    session.status = status;
    fs.writeFileSync(sessionPath, yaml.dump(session), "utf-8");
  }
}
