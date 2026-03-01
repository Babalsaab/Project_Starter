/**
 * Memory Bridge — Thin wrapper for the structured memory store.
 *
 * The MCP server's memory-store.ts lives under a separate tsconfig and cannot
 * be imported directly by the orchestrator.  This module reads/writes the same
 * JSON file (`memory/memory-store.json`) so both systems share one source of truth.
 */

import * as fs from 'fs';
import * as path from 'path';

const ROOT = path.resolve(__dirname, '..');
const STORE_PATH = path.join(ROOT, 'memory', 'memory-store.json');

// ─── Types (mirrors mcp-server/src/lib/memory-store.ts) ─────────────────────

export interface MemoryFact {
  id: string;
  content: string;
  section: string;
  tags: string[];
  type:
    | 'decision'
    | 'convention'
    | 'pattern'
    | 'error'
    | 'preference'
    | 'discovery'
    | 'note';
  confidence: number;
  related_facts: string[];
  session_id?: string;
  created_at: string;
  updated_at: string;
  access_count: number;
  last_accessed?: string;
}

interface MemoryStore {
  version: string;
  facts: MemoryFact[];
  sessions: Array<{
    id: string;
    summary: string;
    started_at: string;
    ended_at?: string;
    facts_created: string[];
  }>;
  search_index?: object;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function loadStore(): MemoryStore {
  if (!fs.existsSync(STORE_PATH)) {
    return { version: '1.0', facts: [], sessions: [] };
  }
  try {
    return JSON.parse(fs.readFileSync(STORE_PATH, 'utf-8')) as MemoryStore;
  } catch {
    return { version: '1.0', facts: [], sessions: [] };
  }
}

function saveStore(store: MemoryStore): void {
  const dir = path.dirname(STORE_PATH);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(STORE_PATH, JSON.stringify(store, null, 2), 'utf-8');
}

function generateId(): string {
  return `mem_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

// ─── Public API ──────────────────────────────────────────────────────────────

/** Write a new fact to the memory store. */
export function writeFact(opts: {
  content: string;
  section?: string;
  tags?: string[];
  type?: MemoryFact['type'];
  confidence?: number;
  session_id?: string;
}): MemoryFact {
  const store = loadStore();
  const now = new Date().toISOString();

  const fact: MemoryFact = {
    id: generateId(),
    content: opts.content,
    section: opts.section ?? 'Agent System',
    tags: opts.tags ?? [],
    type: opts.type ?? 'note',
    confidence: opts.confidence ?? 0.8,
    related_facts: [],
    session_id: opts.session_id,
    created_at: now,
    updated_at: now,
    access_count: 0,
  };

  store.facts.push(fact);
  saveStore(store);
  return fact;
}

/** Search facts by keyword matching on content, section, and tags. */
export function searchFacts(
  query: string,
  opts?: { section?: string; tags?: string[]; limit?: number }
): MemoryFact[] {
  const store = loadStore();
  const lower = query.toLowerCase();
  const limit = opts?.limit ?? 20;

  const results = store.facts.filter((f) => {
    const matchContent = f.content.toLowerCase().includes(lower);
    const matchTags = f.tags.some((t) => t.toLowerCase().includes(lower));
    if (!matchContent && !matchTags) {
      return false;
    }
    if (opts?.section && f.section !== opts.section) {
      return false;
    }
    if (opts?.tags && !opts.tags.some((t) => f.tags.includes(t))) {
      return false;
    }
    return true;
  });

  // Sort by relevance: exact content match > tag match > recency
  results.sort((a, b) => {
    const aExact = a.content.toLowerCase().includes(lower) ? 1 : 0;
    const bExact = b.content.toLowerCase().includes(lower) ? 1 : 0;
    if (aExact !== bExact) {
      return bExact - aExact;
    }
    return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime();
  });

  return results.slice(0, limit);
}

/** Read all facts in a given section. */
export function readFacts(section?: string): MemoryFact[] {
  const store = loadStore();
  if (!section) {
    return store.facts;
  }
  return store.facts.filter((f) => f.section === section);
}

/** Update an existing fact by ID. */
export function updateFact(
  id: string,
  updates: Partial<
    Pick<MemoryFact, 'content' | 'section' | 'tags' | 'type' | 'confidence'>
  >
): boolean {
  const store = loadStore();
  const fact = store.facts.find((f) => f.id === id);
  if (!fact) {
    return false;
  }
  Object.assign(fact, updates, { updated_at: new Date().toISOString() });
  saveStore(store);
  return true;
}

/** Delete a fact by ID. */
export function deleteFact(id: string): boolean {
  const store = loadStore();
  const idx = store.facts.findIndex((f) => f.id === id);
  if (idx === -1) {
    return false;
  }
  store.facts.splice(idx, 1);
  // Remove references from other facts
  for (const f of store.facts) {
    f.related_facts = f.related_facts.filter((r) => r !== id);
  }
  saveStore(store);
  return true;
}
