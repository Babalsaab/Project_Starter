/**
 * Agent Service
 *
 * Business logic for agent registry loading, searching, and suggestion.
 */

import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';

const AGENTS_DIR = path.join(process.cwd(), 'agents/pool');

export interface AgentSummary {
  id: string;
  title: string;
  domain: string;
  reports_to: string;
  token_cap: number;
}

let _agentCache: AgentSummary[] | null = null;

export function listAgents(): AgentSummary[] {
  if (_agentCache) {
    return _agentCache;
  }

  const agents: AgentSummary[] = [];
  const scanDir = (dir: string) => {
    if (!fs.existsSync(dir)) {
      return;
    }
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        scanDir(fullPath);
      } else if (entry.name.endsWith('.yaml') || entry.name.endsWith('.yml')) {
        try {
          const raw = fs.readFileSync(fullPath, 'utf-8');
          const agent = yaml.load(raw) as Record<string, unknown>;
          if (agent?.['id'] && agent?.['title']) {
            agents.push({
              id: agent['id'] as string,
              title: agent['title'] as string,
              domain: (agent['domain'] as string) ?? '',
              reports_to: (agent['reports_to'] as string) ?? '',
              token_cap: (agent['token_cap'] as number) ?? 2000,
            });
          }
        } catch {
          // Skip malformed agent files
        }
      }
    }
  };

  scanDir(AGENTS_DIR);
  _agentCache = agents;
  return agents;
}

export function getAgentById(id: string): AgentSummary | null {
  return listAgents().find((a) => a.id === id) ?? null;
}

export function suggestAgentsForDomain(domain: string): AgentSummary[] {
  return listAgents().filter((a) =>
    a.domain.toLowerCase().includes(domain.toLowerCase())
  );
}
