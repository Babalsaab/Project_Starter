/**
 * Session Service
 *
 * Business logic for orchestrator session management.
 * Decoupled from Next.js route handlers — usable in CLI, API, and tests.
 */

import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';

const SESSIONS_DIR = path.join(process.cwd(), 'config/project-sessions');

export interface SessionSummary {
  id: string;
  project_name: string;
  status: string;
  created_at: string;
  phases_completed: number;
  phases_total: number;
}

export function listSessions(): SessionSummary[] {
  if (!fs.existsSync(SESSIONS_DIR)) {
    return [];
  }

  const entries = fs.readdirSync(SESSIONS_DIR, { withFileTypes: true });
  const sessions: SessionSummary[] = [];

  for (const entry of entries) {
    if (!entry.isDirectory()) {
      continue;
    }
    const sessionFile = path.join(SESSIONS_DIR, entry.name, 'session.yaml');
    if (!fs.existsSync(sessionFile)) {
      continue;
    }

    try {
      const raw = fs.readFileSync(sessionFile, 'utf-8');
      const session = yaml.load(raw) as Record<string, unknown>;
      sessions.push({
        id: (session['id'] as string) ?? entry.name,
        project_name: (session['project_name'] as string) ?? entry.name,
        status: (session['status'] as string) ?? 'unknown',
        created_at: (session['created_at'] as string) ?? '',
        phases_completed: (session['phases_completed'] as number) ?? 0,
        phases_total: (session['phases_total'] as number) ?? 9,
      });
    } catch {
      // Skip malformed session files
    }
  }

  return sessions.sort((a, b) => b.created_at.localeCompare(a.created_at));
}

export function getSessionById(id: string): Record<string, unknown> | null {
  const sessionFile = path.join(SESSIONS_DIR, id, 'session.yaml');
  if (!fs.existsSync(sessionFile)) {
    return null;
  }

  try {
    const raw = fs.readFileSync(sessionFile, 'utf-8');
    return yaml.load(raw) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export function sessionExists(id: string): boolean {
  return fs.existsSync(path.join(SESSIONS_DIR, id, 'session.yaml'));
}
