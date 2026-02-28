/**
 * Persistent Memory Store with Semantic Search
 *
 * JSON-backed structured knowledge store with:
 * - Categorized facts (sections, tags, types)
 * - Cross-session tracking
 * - TF-IDF semantic search index
 * - Relationship graph between facts
 * - Auto-categorization
 *
 * Beats OpenClaw's flat key-value store with STRUCTURED knowledge.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, appendFileSync, readdirSync } from "fs";
import { join } from "path";
import { TfIdfEngine } from "./tfidf-engine.js";

// ─── Types ──────────────────────────────────────────────────────────────────

export interface MemoryFact {
  id: string;
  content: string;
  section: string;
  tags: string[];
  type: "decision" | "convention" | "pattern" | "error" | "preference" | "discovery" | "note";
  confidence: number; // 0-1, how certain this fact is
  related_facts: string[]; // IDs of related facts
  session_id?: string;
  created_at: string;
  updated_at: string;
  access_count: number;
  last_accessed?: string;
}

export interface MemorySession {
  id: string;
  summary: string;
  started_at: string;
  ended_at?: string;
  facts_created: string[];
}

export interface MemoryStore {
  version: string;
  facts: MemoryFact[];
  sessions: MemorySession[];
  search_index?: object; // Serialized TfIdfEngine state
}

export interface MemorySearchResult {
  fact: MemoryFact;
  score: number;
  matchType: "semantic" | "keyword" | "tag" | "hybrid";
}

// ─── Auto-categorization ────────────────────────────────────────────────────

const SECTION_KEYWORDS: Record<string, string[]> = {
  "Architecture Decisions": ["architecture", "design", "pattern", "structure", "module", "layer", "service", "microservice", "monolith", "component"],
  "Key Conventions": ["convention", "naming", "format", "style", "standard", "rule", "guideline", "always", "never", "prefer"],
  "Tech Stack": ["framework", "library", "dependency", "version", "typescript", "react", "next", "prisma", "tailwind", "node"],
  "API & Integrations": ["api", "endpoint", "route", "rest", "graphql", "webhook", "integration", "provider", "sdk"],
  "Database": ["database", "schema", "migration", "query", "table", "index", "relation", "prisma", "sqlite", "postgres"],
  "Security": ["security", "auth", "token", "secret", "permission", "role", "vulnerability", "owasp", "cors", "csrf"],
  "Performance": ["performance", "optimization", "cache", "lazy", "bundle", "render", "latency", "throughput", "memory"],
  "Testing": ["test", "spec", "mock", "fixture", "coverage", "assertion", "vitest", "playwright", "jest"],
  "DevOps & Deployment": ["deploy", "ci", "cd", "docker", "pipeline", "release", "workflow", "github actions", "build"],
  "Agent System": ["agent", "persona", "mentor", "skill", "orchestrator", "pipeline", "execution", "mcp"],
  "Errors & Solutions": ["error", "bug", "fix", "workaround", "issue", "crash", "exception", "debug"],
  "User Preferences": ["prefer", "always use", "never use", "like", "dislike", "want", "style preference"],
};

const TYPE_KEYWORDS: Record<MemoryFact["type"], string[]> = {
  decision: ["decided", "chose", "selected", "going with", "will use", "architecture decision"],
  convention: ["convention", "always", "never", "naming", "format", "standard", "rule"],
  pattern: ["pattern", "approach", "technique", "method", "strategy", "best practice"],
  error: ["error", "bug", "fix", "issue", "workaround", "broken", "crash"],
  preference: ["prefer", "like", "want", "use", "avoid", "style"],
  discovery: ["found", "discovered", "learned", "realized", "turns out", "noted"],
  note: [],
};

function autoSection(content: string): string {
  const lower = content.toLowerCase();
  let bestSection = "Notes";
  let bestScore = 0;

  for (const [section, keywords] of Object.entries(SECTION_KEYWORDS)) {
    const score = keywords.filter((kw) => lower.includes(kw)).length;
    if (score > bestScore) {
      bestScore = score;
      bestSection = section;
    }
  }
  return bestSection;
}

function autoType(content: string): MemoryFact["type"] {
  const lower = content.toLowerCase();
  let bestType: MemoryFact["type"] = "note";
  let bestScore = 0;

  for (const [type, keywords] of Object.entries(TYPE_KEYWORDS)) {
    const score = keywords.filter((kw) => lower.includes(kw)).length;
    if (score > bestScore) {
      bestScore = score;
      bestType = type as MemoryFact["type"];
    }
  }
  return bestType;
}

function autoTags(content: string): string[] {
  const lower = content.toLowerCase();
  const tags: string[] = [];
  const tagPatterns: Record<string, string[]> = {
    frontend: ["react", "component", "css", "tailwind", "ui", "ux", "dom"],
    backend: ["api", "server", "route", "endpoint", "middleware", "database"],
    agent: ["agent", "persona", "mentor", "skill", "orchestrator"],
    security: ["security", "auth", "token", "secret", "vulnerability"],
    performance: ["performance", "optimize", "cache", "bundle", "lazy"],
    testing: ["test", "spec", "mock", "coverage", "vitest"],
    devops: ["deploy", "docker", "ci", "cd", "pipeline", "release"],
    config: ["config", "settings", "env", "yaml", "json"],
  };

  for (const [tag, keywords] of Object.entries(tagPatterns)) {
    if (keywords.some((kw) => lower.includes(kw))) {
      tags.push(tag);
    }
  }
  return tags;
}

// ─── Memory Manager ─────────────────────────────────────────────────────────

const ROOT = join(import.meta.dirname, "..", "..", "..");
const MEMORY_DIR = join(ROOT, "memory");
const STORE_FILE = join(MEMORY_DIR, "memory-store.json");
const MEMORY_MD = join(MEMORY_DIR, "MEMORY.md");
const DAILY_DIR = join(MEMORY_DIR, "daily");

let cachedStore: MemoryStore | null = null;
let searchEngine: TfIdfEngine | null = null;

function ensureDirs(): void {
  if (!existsSync(MEMORY_DIR)) mkdirSync(MEMORY_DIR, { recursive: true });
  if (!existsSync(DAILY_DIR)) mkdirSync(DAILY_DIR, { recursive: true });
}

function generateId(): string {
  return `mem_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

function loadStore(): MemoryStore {
  if (cachedStore) return cachedStore;

  ensureDirs();

  if (existsSync(STORE_FILE)) {
    cachedStore = JSON.parse(readFileSync(STORE_FILE, "utf-8")) as MemoryStore;
  } else {
    cachedStore = { version: "2.0.0", facts: [], sessions: [] };
  }

  // Rebuild search index
  searchEngine = new TfIdfEngine();
  if (cachedStore.search_index) {
    try {
      searchEngine.deserialize(cachedStore.search_index as any);
    } catch {
      // Rebuild from facts if index is corrupted
      for (const fact of cachedStore.facts) {
        searchEngine.addDocument(fact.id, `${fact.content} ${fact.tags.join(" ")} ${fact.section}`);
      }
    }
  } else {
    for (const fact of cachedStore.facts) {
      searchEngine.addDocument(fact.id, `${fact.content} ${fact.tags.join(" ")} ${fact.section}`);
    }
  }

  return cachedStore;
}

function saveStore(store: MemoryStore): void {
  ensureDirs();
  if (searchEngine) {
    store.search_index = searchEngine.serialize();
  }
  writeFileSync(STORE_FILE, JSON.stringify(store, null, 2), "utf-8");
  cachedStore = store;

  // Also sync to MEMORY.md for backward compatibility
  syncToMarkdown(store);
}

function syncToMarkdown(store: MemoryStore): void {
  const sections = new Map<string, MemoryFact[]>();
  for (const fact of store.facts) {
    const existing = sections.get(fact.section) ?? [];
    existing.push(fact);
    sections.set(fact.section, existing);
  }

  let md = `# Project Memory\n\nPersistent context for the Vibecoded Orchestrator project.\n`;
  md += `Last updated: ${new Date().toISOString().split("T")[0]}\n`;
  md += `Total facts: ${store.facts.length} | Sessions: ${store.sessions.length}\n\n`;

  for (const [section, facts] of sections) {
    md += `## ${section}\n\n`;
    for (const fact of facts) {
      const tags = fact.tags.length > 0 ? ` [${fact.tags.join(", ")}]` : "";
      md += `- ${fact.content}${tags} _(${fact.created_at})_\n`;
    }
    md += "\n";
  }

  writeFileSync(MEMORY_MD, md, "utf-8");
}

function logToDaily(content: string): void {
  ensureDirs();
  const today = new Date().toISOString().split("T")[0];
  const time = new Date().toISOString().split("T")[1]?.slice(0, 5) ?? "00:00";
  const dailyFile = join(DAILY_DIR, `${today}.md`);
  appendFileSync(dailyFile, `- [${time}] ${content}\n`, "utf-8");
}

// ─── Public API ─────────────────────────────────────────────────────────────

export function writeFact(opts: {
  content: string;
  section?: string;
  tags?: string[];
  type?: MemoryFact["type"];
  confidence?: number;
  related_facts?: string[];
  session_id?: string;
}): MemoryFact {
  const store = loadStore();

  const fact: MemoryFact = {
    id: generateId(),
    content: opts.content,
    section: opts.section ?? autoSection(opts.content),
    tags: opts.tags ?? autoTags(opts.content),
    type: opts.type ?? autoType(opts.content),
    confidence: opts.confidence ?? 0.8,
    related_facts: opts.related_facts ?? [],
    session_id: opts.session_id,
    created_at: new Date().toISOString().split("T")[0]!,
    updated_at: new Date().toISOString().split("T")[0]!,
    access_count: 0,
  };

  // Auto-detect related facts by content similarity
  if (searchEngine && fact.related_facts.length === 0) {
    const similar = searchEngine.search(fact.content, 3);
    fact.related_facts = similar.filter((r) => r.score > 0.3).map((r) => r.id);
  }

  store.facts.push(fact);
  searchEngine?.addDocument(fact.id, `${fact.content} ${fact.tags.join(" ")} ${fact.section}`);
  saveStore(store);
  logToDaily(fact.content);

  return fact;
}

export function updateFact(id: string, updates: Partial<Pick<MemoryFact, "content" | "section" | "tags" | "type" | "confidence">>): MemoryFact | null {
  const store = loadStore();
  const fact = store.facts.find((f) => f.id === id);
  if (!fact) return null;

  if (updates.content !== undefined) fact.content = updates.content;
  if (updates.section !== undefined) fact.section = updates.section;
  if (updates.tags !== undefined) fact.tags = updates.tags;
  if (updates.type !== undefined) fact.type = updates.type;
  if (updates.confidence !== undefined) fact.confidence = updates.confidence;
  fact.updated_at = new Date().toISOString().split("T")[0]!;

  if (updates.content && searchEngine) {
    searchEngine.addDocument(fact.id, `${fact.content} ${fact.tags.join(" ")} ${fact.section}`);
  }

  saveStore(store);
  return fact;
}

export function deleteFact(id: string): boolean {
  const store = loadStore();
  const idx = store.facts.findIndex((f) => f.id === id);
  if (idx === -1) return false;

  store.facts.splice(idx, 1);
  searchEngine?.removeDocument(id);

  // Remove references from other facts
  for (const fact of store.facts) {
    fact.related_facts = fact.related_facts.filter((r) => r !== id);
  }

  saveStore(store);
  return true;
}

export function searchMemory(query: string, opts?: {
  section?: string;
  tags?: string[];
  type?: MemoryFact["type"];
  topK?: number;
  minScore?: number;
}): MemorySearchResult[] {
  const store = loadStore();
  const topK = opts?.topK ?? 10;
  const minScore = opts?.minScore ?? 0.05;
  const results: MemorySearchResult[] = [];

  // Semantic search via TF-IDF + BM25
  if (searchEngine) {
    const engineResults = searchEngine.search(query, topK * 2);
    for (const result of engineResults) {
      const fact = store.facts.find((f) => f.id === result.id);
      if (!fact) continue;

      // Apply filters
      if (opts?.section && fact.section !== opts.section) continue;
      if (opts?.tags && !opts.tags.some((t) => fact.tags.includes(t))) continue;
      if (opts?.type && fact.type !== opts.type) continue;

      if (result.score >= minScore) {
        results.push({ fact, score: result.score, matchType: "semantic" });
      }
    }
  }

  // Also do keyword matching for facts not caught by TF-IDF
  const queryLower = query.toLowerCase();
  const semanticIds = new Set(results.map((r) => r.fact.id));

  for (const fact of store.facts) {
    if (semanticIds.has(fact.id)) continue;

    // Apply filters
    if (opts?.section && fact.section !== opts.section) continue;
    if (opts?.tags && !opts.tags.some((t) => fact.tags.includes(t))) continue;
    if (opts?.type && fact.type !== opts.type) continue;

    // Tag matching
    if (fact.tags.some((t) => queryLower.includes(t))) {
      results.push({ fact, score: 0.3, matchType: "tag" });
      continue;
    }

    // Direct keyword match
    if (fact.content.toLowerCase().includes(queryLower)) {
      results.push({ fact, score: 0.4, matchType: "keyword" });
    }
  }

  // Update access counts
  for (const result of results) {
    result.fact.access_count++;
    result.fact.last_accessed = new Date().toISOString().split("T")[0];
  }
  if (results.length > 0) saveStore(store);

  return results.sort((a, b) => b.score - a.score).slice(0, topK);
}

export function readAllFacts(section?: string): MemoryFact[] {
  const store = loadStore();
  if (section) {
    return store.facts.filter((f) => f.section === section);
  }
  return store.facts;
}

export function getSections(): Array<{ name: string; count: number }> {
  const store = loadStore();
  const counts = new Map<string, number>();
  for (const fact of store.facts) {
    counts.set(fact.section, (counts.get(fact.section) ?? 0) + 1);
  }
  return Array.from(counts.entries())
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count);
}

export function getRelatedFacts(factId: string): MemoryFact[] {
  const store = loadStore();
  const fact = store.facts.find((f) => f.id === factId);
  if (!fact) return [];

  return fact.related_facts
    .map((id) => store.facts.find((f) => f.id === id))
    .filter((f): f is MemoryFact => f !== undefined);
}

export function getMemoryStats(): {
  totalFacts: number;
  totalSessions: number;
  sections: Array<{ name: string; count: number }>;
  typeBreakdown: Record<string, number>;
  topTags: Array<{ tag: string; count: number }>;
  recentFacts: MemoryFact[];
} {
  const store = loadStore();

  const typeBreakdown: Record<string, number> = {};
  const tagCounts = new Map<string, number>();

  for (const fact of store.facts) {
    typeBreakdown[fact.type] = (typeBreakdown[fact.type] ?? 0) + 1;
    for (const tag of fact.tags) {
      tagCounts.set(tag, (tagCounts.get(tag) ?? 0) + 1);
    }
  }

  const topTags = Array.from(tagCounts.entries())
    .map(([tag, count]) => ({ tag, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 10);

  const recentFacts = [...store.facts]
    .sort((a, b) => b.created_at.localeCompare(a.created_at))
    .slice(0, 5);

  return {
    totalFacts: store.facts.length,
    totalSessions: store.sessions.length,
    sections: getSections(),
    typeBreakdown,
    topTags,
    recentFacts,
  };
}

// ─── Session Management ─────────────────────────────────────────────────────

export function startSession(summary: string): MemorySession {
  const store = loadStore();
  const session: MemorySession = {
    id: `session_${Date.now()}`,
    summary,
    started_at: new Date().toISOString(),
    facts_created: [],
  };
  store.sessions.push(session);
  saveStore(store);
  return session;
}

export function endSession(sessionId: string): void {
  const store = loadStore();
  const session = store.sessions.find((s) => s.id === sessionId);
  if (session) {
    session.ended_at = new Date().toISOString();
    session.facts_created = store.facts
      .filter((f) => f.session_id === sessionId)
      .map((f) => f.id);
    saveStore(store);
  }
}

/** Migrate existing MEMORY.md into the new structured store */
export function migrateFromMarkdown(): number {
  ensureDirs();
  if (!existsSync(MEMORY_MD)) return 0;

  const store = loadStore();
  if (store.facts.length > 0) return 0; // Already has data

  const content = readFileSync(MEMORY_MD, "utf-8");
  const lines = content.split("\n");
  let currentSection = "Notes";
  let migrated = 0;

  for (const line of lines) {
    const sectionMatch = line.match(/^## (.+)/);
    if (sectionMatch) {
      currentSection = sectionMatch[1]!;
      continue;
    }

    const factMatch = line.match(/^- (.+?)(?:\s+_\((.+?)\)_)?$/);
    if (factMatch) {
      const factContent = factMatch[1]!;
      const date = factMatch[2] ?? new Date().toISOString().split("T")[0];

      writeFact({
        content: factContent,
        section: currentSection,
      });
      migrated++;
    }
  }

  return migrated;
}

export function invalidateCache(): void {
  cachedStore = null;
  searchEngine = null;
}
