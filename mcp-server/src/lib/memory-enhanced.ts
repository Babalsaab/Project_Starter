/**
 * Enhanced Memory Manager
 *
 * Upgrades the existing BM25/TF-IDF memory system with:
 *   - Vector embeddings (multi-provider: Ollama, OpenAI, TF-IDF fallback)
 *   - Temporal decay (exponential half-life model)
 *   - MMR ranking (Maximal Marginal Relevance for diversity)
 *   - Hybrid scoring (weighted merge of BM25 + vector + decay)
 *
 * Backward compatible: reads/writes the same `memory/memory-store.json` format
 * and adds a parallel `memory/vector-store.json` for embeddings. Existing
 * MemoryFact fields are preserved; new fields are added non-destructively.
 *
 * Integration point: this module wraps the existing memory-store.ts and
 * tfidf-engine.ts, adding the vector layer on top. The MCP tools in
 * `tools/memory.ts` can call into this manager for enhanced search while
 * the existing functions remain available as a fallback.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, appendFileSync } from "fs";
import { join } from "path";
import { TfIdfEngine } from "./tfidf-engine.js";
import { VectorStore } from "./vector-store.js";
import { createEmbeddingProvider, type EmbeddingProvider } from "./embedding-provider.js";

// ─── Types ───────────────────────────────────────────────────────────────────

/** Extended fact type — superset of the original MemoryFact. */
export interface EnhancedFact {
  /** Unique identifier (e.g. mem_1709..._abc123). */
  id: string;
  /** The fact content text. */
  content: string;
  /** Organizational section (e.g. "Architecture Decisions"). */
  section: string;
  /** Fact type for classification. */
  type: "decision" | "convention" | "pattern" | "error" | "preference" | "discovery" | "note";
  /** Tags for filtering and categorization. */
  tags: string[];
  /** ISO date when the fact was created. */
  created_at: string;
  /** ISO date when the fact was last updated. */
  updated_at?: string;
  /** Confidence score from 0 to 1. */
  confidence: number;
  /** IDs of related facts (knowledge graph edges). */
  related_to: string[];
  /** How many times this fact has been accessed via search. */
  access_count: number;
  /** ISO date of last access. */
  last_accessed?: string;
  /** Optional session ID for cross-session tracking. */
  session_id?: string;
}

/** Options for the hybrid search algorithm. */
export interface HybridSearchOptions {
  /** The search query text. */
  query: string;
  /** Maximum number of results (default 10). */
  k?: number;
  /** Filter by section name. */
  section?: string;
  /** Filter by fact type. */
  type?: string;
  /** Filter by tags (match any). */
  tags?: string[];
  /** Minimum confidence threshold (default 0). */
  minConfidence?: number;
  /** Enable vector-based search (default true). */
  useVectors?: boolean;
  /** Enable BM25 keyword search (default true). */
  useBM25?: boolean;
  /** Weight for vector similarity scores in the merge (default 0.6). */
  vectorWeight?: number;
  /** Weight for BM25 scores in the merge (default 0.4). */
  bm25Weight?: number;
  /** Temporal decay half-life in days (default 30). */
  decayHalfLife?: number;
  /** MMR lambda: 1.0 = pure relevance, 0.0 = pure diversity (default 0.7). */
  mmrLambda?: number;
}

/** A search result with its computed score. */
export interface ScoredFact extends EnhancedFact {
  /** The final hybrid score. */
  score: number;
}

/** Memory analytics. */
export interface MemoryStats {
  totalFacts: number;
  bySection: Record<string, number>;
  byType: Record<string, number>;
  topTags: Array<{ tag: string; count: number }>;
  averageConfidence: number;
  vectorizedCount: number;
  staleCount: number;
}

// ─── Internal Types ──────────────────────────────────────────────────────────

/** The on-disk format we read/write (compatible with existing memory-store.json). */
interface MemoryStoreFile {
  version: string;
  facts: Array<Record<string, unknown>>;
  sessions: Array<Record<string, unknown>>;
  search_index?: object;
}

// ─── Auto-categorization (ported from memory-store.ts) ───────────────────────

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

const TYPE_KEYWORDS: Record<string, string[]> = {
  decision: ["decided", "chose", "selected", "going with", "will use", "architecture decision"],
  convention: ["convention", "always", "never", "naming", "format", "standard", "rule"],
  pattern: ["pattern", "approach", "technique", "method", "strategy", "best practice"],
  error: ["error", "bug", "fix", "issue", "workaround", "broken", "crash"],
  preference: ["prefer", "like", "want", "use", "avoid", "style"],
  discovery: ["found", "discovered", "learned", "realized", "turns out", "noted"],
  note: [],
};

const TAG_PATTERNS: Record<string, string[]> = {
  frontend: ["react", "component", "css", "tailwind", "ui", "ux", "dom"],
  backend: ["api", "server", "route", "endpoint", "middleware", "database"],
  agent: ["agent", "persona", "mentor", "skill", "orchestrator"],
  security: ["security", "auth", "token", "secret", "vulnerability"],
  performance: ["performance", "optimize", "cache", "bundle", "lazy"],
  testing: ["test", "spec", "mock", "coverage", "vitest"],
  devops: ["deploy", "docker", "ci", "cd", "pipeline", "release"],
  config: ["config", "settings", "env", "yaml", "json"],
};

function autoDetectSection(content: string): string {
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

function autoDetectType(content: string): EnhancedFact["type"] {
  const lower = content.toLowerCase();
  let bestType: EnhancedFact["type"] = "note";
  let bestScore = 0;
  for (const [type, keywords] of Object.entries(TYPE_KEYWORDS)) {
    const score = keywords.filter((kw) => lower.includes(kw)).length;
    if (score > bestScore) {
      bestScore = score;
      bestType = type as EnhancedFact["type"];
    }
  }
  return bestType;
}

function autoDetectTags(content: string): string[] {
  const lower = content.toLowerCase();
  const tags: string[] = [];
  for (const [tag, keywords] of Object.entries(TAG_PATTERNS)) {
    if (keywords.some((kw) => lower.includes(kw))) {
      tags.push(tag);
    }
  }
  return tags;
}

function generateId(): string {
  return `mem_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

function todayISO(): string {
  return new Date().toISOString().split("T")[0]!;
}

// ─── Enhanced Memory Manager ─────────────────────────────────────────────────

export class EnhancedMemoryManager {
  private memoryPath: string;
  private vectorStorePath: string;
  private dailyDir: string;

  private facts: Map<string, EnhancedFact> = new Map();
  private sessions: Array<Record<string, unknown>> = [];
  private tfidfEngine: TfIdfEngine = new TfIdfEngine();
  private vectorStore: VectorStore = new VectorStore();
  private embeddingProvider: EmbeddingProvider | null = null;

  private loaded = false;
  private providerInitialized = false;

  /**
   * Create a new EnhancedMemoryManager.
   *
   * @param memoryPath - Path to the memory-store.json file.
   * @param vectorStorePath - Path to the vector-store.json file.
   */
  constructor(memoryPath: string, vectorStorePath: string) {
    this.memoryPath = memoryPath;
    this.vectorStorePath = vectorStorePath;
    this.dailyDir = join(memoryPath, "..", "daily");
  }

  // ─── Initialization ────────────────────────────────────────────────────

  /**
   * Ensure the store is loaded from disk. Idempotent.
   * Call this before any read/write operation.
   */
  private async ensureLoaded(): Promise<void> {
    if (this.loaded) return;

    // Ensure directories exist
    const memDir = join(this.memoryPath, "..");
    if (!existsSync(memDir)) mkdirSync(memDir, { recursive: true });
    if (!existsSync(this.dailyDir)) mkdirSync(this.dailyDir, { recursive: true });

    // Load the existing memory store (backward-compatible)
    if (existsSync(this.memoryPath)) {
      try {
        const raw = readFileSync(this.memoryPath, "utf-8");
        const data = JSON.parse(raw) as MemoryStoreFile;

        this.sessions = data.sessions ?? [];

        // Parse facts into EnhancedFact format
        for (const rawFact of data.facts ?? []) {
          const fact = this.parseRawFact(rawFact);
          this.facts.set(fact.id, fact);
          // Index in TF-IDF engine
          this.tfidfEngine.addDocument(
            fact.id,
            `${fact.content} ${fact.tags.join(" ")} ${fact.section}`
          );
        }

        // Try restoring the TF-IDF index from the stored search_index
        if (data.search_index) {
          try {
            const tempEngine = new TfIdfEngine();
            tempEngine.deserialize(data.search_index as Parameters<TfIdfEngine["deserialize"]>[0]);
            this.tfidfEngine = tempEngine;
          } catch {
            // Rebuilt above from facts, so this is fine
          }
        }
      } catch {
        // Corrupted file — start fresh
        this.facts.clear();
      }
    }

    // Load vector store
    await this.vectorStore.load(this.vectorStorePath);

    this.loaded = true;
  }

  /**
   * Lazily initialize the embedding provider (async probe to detect Ollama, etc).
   * Separated from ensureLoaded because it involves network calls.
   */
  private async ensureProvider(): Promise<EmbeddingProvider> {
    if (!this.providerInitialized) {
      try {
        this.embeddingProvider = await createEmbeddingProvider();
      } catch {
        // All providers failed — this should not happen since TF-IDF is the fallback,
        // but guard against it anyway.
        this.embeddingProvider = null;
      }
      this.providerInitialized = true;
    }
    return this.embeddingProvider!;
  }

  /**
   * Parse a raw JSON object into an EnhancedFact, filling in defaults for
   * any fields not present in the legacy format.
   */
  private parseRawFact(raw: Record<string, unknown>): EnhancedFact {
    return {
      id: (raw["id"] as string) ?? generateId(),
      content: (raw["content"] as string) ?? "",
      section: (raw["section"] as string) ?? "Notes",
      type: (raw["type"] as EnhancedFact["type"]) ?? "note",
      tags: (raw["tags"] as string[]) ?? [],
      created_at: (raw["created_at"] as string) ?? todayISO(),
      updated_at: (raw["updated_at"] as string) ?? undefined,
      confidence: typeof raw["confidence"] === "number" ? (raw["confidence"] as number) : 0.8,
      related_to: (raw["related_facts"] as string[]) ?? (raw["related_to"] as string[]) ?? [],
      access_count: typeof raw["access_count"] === "number" ? (raw["access_count"] as number) : 0,
      last_accessed: (raw["last_accessed"] as string) ?? undefined,
      session_id: (raw["session_id"] as string) ?? undefined,
    };
  }

  // ─── Persistence ───────────────────────────────────────────────────────

  /** Save the memory store and vector store to disk. */
  private async persist(): Promise<void> {
    const memDir = join(this.memoryPath, "..");
    if (!existsSync(memDir)) mkdirSync(memDir, { recursive: true });

    // Convert facts back to the legacy format for backward compatibility
    const factsArray = Array.from(this.facts.values()).map((f) => ({
      id: f.id,
      content: f.content,
      section: f.section,
      tags: f.tags,
      type: f.type,
      confidence: f.confidence,
      related_facts: f.related_to,
      session_id: f.session_id,
      created_at: f.created_at,
      updated_at: f.updated_at ?? f.created_at,
      access_count: f.access_count,
      last_accessed: f.last_accessed,
    }));

    const storeData: MemoryStoreFile = {
      version: "2.1.0",
      facts: factsArray,
      sessions: this.sessions,
      search_index: this.tfidfEngine.serialize(),
    };

    writeFileSync(this.memoryPath, JSON.stringify(storeData, null, 2), "utf-8");

    // Save vector store
    await this.vectorStore.save(this.vectorStorePath);

    // Sync to MEMORY.md for backward compatibility
    this.syncToMarkdown(factsArray);
  }

  /** Sync facts to MEMORY.md for human readability and backward compat. */
  private syncToMarkdown(facts: Array<Record<string, unknown>>): void {
    const sections = new Map<string, Array<Record<string, unknown>>>();
    for (const fact of facts) {
      const section = (fact["section"] as string) ?? "Notes";
      const existing = sections.get(section) ?? [];
      existing.push(fact);
      sections.set(section, existing);
    }

    let md = `# Project Memory\n\nPersistent context for the Vibecoded Orchestrator project.\n`;
    md += `Last updated: ${todayISO()}\n`;
    md += `Total facts: ${facts.length} | Sessions: ${this.sessions.length}\n\n`;

    for (const [section, sectionFacts] of sections) {
      md += `## ${section}\n\n`;
      for (const fact of sectionFacts) {
        const tags = Array.isArray(fact["tags"]) && (fact["tags"] as string[]).length > 0
          ? ` [${(fact["tags"] as string[]).join(", ")}]`
          : "";
        md += `- ${fact["content"] as string}${tags} _(${fact["created_at"] as string})_\n`;
      }
      md += "\n";
    }

    const mdPath = join(this.memoryPath, "..", "MEMORY.md");
    writeFileSync(mdPath, md, "utf-8");
  }

  /** Append a log entry to the daily log. */
  private logToDaily(content: string): void {
    if (!existsSync(this.dailyDir)) mkdirSync(this.dailyDir, { recursive: true });
    const today = todayISO();
    const time = new Date().toISOString().split("T")[1]?.slice(0, 5) ?? "00:00";
    const dailyFile = join(this.dailyDir, `${today}.md`);
    appendFileSync(dailyFile, `- [${time}] ${content}\n`, "utf-8");
  }

  // ─── Embedding Helpers ─────────────────────────────────────────────────

  /**
   * Generate and store an embedding for a fact.
   * Returns true if the embedding was successfully generated.
   */
  private async embedFact(fact: EnhancedFact): Promise<boolean> {
    try {
      const provider = await this.ensureProvider();
      if (!provider) return false;

      // Combine content with metadata for richer embeddings
      const textToEmbed = `${fact.section}: ${fact.content} [${fact.tags.join(", ")}]`;
      const embedding = await provider.embed(textToEmbed);

      await this.vectorStore.upsert(fact.id, embedding, {
        section: fact.section,
        type: fact.type,
        tags: fact.tags,
      });

      return true;
    } catch {
      // Embedding failed — the fact is still stored, just not vectorized
      return false;
    }
  }

  // ─── Public API: Write ─────────────────────────────────────────────────

  /**
   * Write a new fact to memory.
   *
   * Auto-categorizes section/type/tags if not provided.
   * Auto-generates a vector embedding.
   * Auto-detects related facts via TF-IDF similarity.
   *
   * @returns The ID of the created fact.
   */
  async write(fact: {
    content: string;
    section?: string;
    type?: EnhancedFact["type"];
    tags?: string[];
    confidence?: number;
    related_to?: string[];
    session_id?: string;
  }): Promise<string> {
    await this.ensureLoaded();

    const id = generateId();
    const now = todayISO();

    const enhanced: EnhancedFact = {
      id,
      content: fact.content,
      section: fact.section ?? autoDetectSection(fact.content),
      type: fact.type ?? autoDetectType(fact.content),
      tags: fact.tags ?? autoDetectTags(fact.content),
      created_at: now,
      updated_at: now,
      confidence: fact.confidence ?? 0.8,
      related_to: fact.related_to ?? [],
      access_count: 0,
      session_id: fact.session_id,
    };

    // Auto-detect related facts via TF-IDF if none provided
    if (enhanced.related_to.length === 0 && this.tfidfEngine.size > 0) {
      const similar = this.tfidfEngine.search(enhanced.content, 3);
      enhanced.related_to = similar.filter((r) => r.score > 0.3).map((r) => r.id);
    }

    // Store the fact
    this.facts.set(id, enhanced);

    // Index in TF-IDF
    this.tfidfEngine.addDocument(
      id,
      `${enhanced.content} ${enhanced.tags.join(" ")} ${enhanced.section}`
    );

    // Generate embedding (async, non-blocking for the write)
    await this.embedFact(enhanced);

    // Persist everything
    await this.persist();

    // Log to daily
    this.logToDaily(enhanced.content);

    return id;
  }

  // ─── Public API: Search ────────────────────────────────────────────────

  /**
   * Hybrid search combining BM25/TF-IDF + vector embeddings + temporal decay + MMR.
   *
   * Algorithm:
   *   1. Run BM25/TF-IDF search via the existing engine -> scored results
   *   2. Run vector similarity search -> scored results
   *   3. Apply temporal decay to both score sets
   *   4. Merge scores: finalScore = vectorWeight * vectorScore + bm25Weight * bm25Score
   *   5. Apply MMR to reduce redundancy in final results
   *   6. Return top-k results
   */
  async search(options: HybridSearchOptions): Promise<ScoredFact[]> {
    await this.ensureLoaded();

    const {
      query,
      k = 10,
      section,
      type,
      tags,
      minConfidence = 0,
      useVectors = true,
      useBM25 = true,
      vectorWeight = 0.6,
      bm25Weight = 0.4,
      decayHalfLife = 30,
      mmrLambda = 0.7,
    } = options;

    if (this.facts.size === 0) return [];

    // Collect scored candidates: id -> { bm25Score, vectorScore }
    const candidates = new Map<string, { bm25Score: number; vectorScore: number }>();

    // ── Step 1: BM25/TF-IDF search ──
    if (useBM25) {
      const bm25Results = this.tfidfEngine.search(query, k * 3);
      for (const result of bm25Results) {
        if (!this.facts.has(result.id)) continue;
        const existing = candidates.get(result.id) ?? { bm25Score: 0, vectorScore: 0 };
        existing.bm25Score = result.score;
        candidates.set(result.id, existing);
      }

      // Also add keyword/tag matches not caught by TF-IDF
      const queryLower = query.toLowerCase();
      for (const fact of this.facts.values()) {
        if (candidates.has(fact.id)) continue;

        // Tag matching
        if (fact.tags.some((t) => queryLower.includes(t))) {
          candidates.set(fact.id, { bm25Score: 0.3, vectorScore: 0 });
          continue;
        }

        // Substring match
        if (fact.content.toLowerCase().includes(queryLower)) {
          candidates.set(fact.id, { bm25Score: 0.4, vectorScore: 0 });
        }
      }
    }

    // ── Step 2: Vector search ──
    if (useVectors && (await this.vectorStore.count()) > 0) {
      try {
        const provider = await this.ensureProvider();
        if (provider) {
          const textToEmbed = query;
          const queryEmbedding = await provider.embed(textToEmbed);

          // Use MMR search for diversity
          const vectorResults = await this.vectorStore.searchMMR(
            queryEmbedding,
            k * 3,
            mmrLambda
          );

          for (const result of vectorResults) {
            if (!this.facts.has(result.id)) continue;
            const existing = candidates.get(result.id) ?? { bm25Score: 0, vectorScore: 0 };
            // Normalize cosine similarity from [-1,1] to [0,1] for merging
            existing.vectorScore = (result.score + 1) / 2;
            candidates.set(result.id, existing);
          }
        }
      } catch {
        // Vector search failed — rely on BM25 alone
      }
    }

    // ── Step 3 & 4: Apply temporal decay and merge scores ──
    const now = Date.now();
    const halfLifeMs = decayHalfLife * 24 * 60 * 60 * 1000;
    const scored: ScoredFact[] = [];

    for (const [id, scores] of candidates) {
      const fact = this.facts.get(id);
      if (!fact) continue;

      // Apply filters
      if (section && fact.section !== section) continue;
      if (type && fact.type !== type) continue;
      if (tags && tags.length > 0 && !tags.some((t) => fact.tags.includes(t))) continue;
      if (fact.confidence < minConfidence) continue;

      // Temporal decay based on last access (or creation if never accessed)
      const lastAccessDate = fact.last_accessed ?? fact.created_at;
      const lastAccessMs = new Date(lastAccessDate).getTime();
      const daysSinceAccess = Math.max(0, (now - lastAccessMs) / (24 * 60 * 60 * 1000));
      const decayFactor = Math.pow(0.5, daysSinceAccess / decayHalfLife);

      // Apply decay to both score components
      const decayedBM25 = scores.bm25Score * decayFactor;
      const decayedVector = scores.vectorScore * decayFactor;

      // Merge with configured weights
      const finalScore = vectorWeight * decayedVector + bm25Weight * decayedBM25;

      if (finalScore > 0) {
        scored.push({ ...fact, score: finalScore });
      }
    }

    // ── Step 5: MMR re-ranking on merged results ──
    // We already applied MMR at the vector search level, but we apply a lighter
    // diversity pass on the merged results to handle redundancy between BM25-only
    // and vector-only hits.
    const mmrResults = this.applyMMRReranking(scored, k, mmrLambda);

    // ── Step 6: Update access tracking ──
    for (const result of mmrResults) {
      const fact = this.facts.get(result.id);
      if (fact) {
        fact.access_count++;
        fact.last_accessed = todayISO();
      }
    }

    if (mmrResults.length > 0) {
      await this.persist();
    }

    return mmrResults;
  }

  /**
   * Apply MMR re-ranking to a list of scored facts.
   *
   * Uses a text-similarity proxy (Jaccard on token sets) for the
   * inter-document similarity since we already have the scores computed.
   */
  private applyMMRReranking(
    candidates: ScoredFact[],
    k: number,
    lambda: number
  ): ScoredFact[] {
    if (candidates.length <= k) {
      return candidates.sort((a, b) => b.score - a.score);
    }

    // Sort by score descending as starting point
    candidates.sort((a, b) => b.score - a.score);

    // Normalize scores to [0,1] for MMR computation
    const maxScore = candidates[0]?.score ?? 1;
    if (maxScore === 0) return candidates.slice(0, k);

    const selected: ScoredFact[] = [];
    const remaining = new Set(candidates.map((_, i) => i));

    // Pre-tokenize for Jaccard similarity
    const tokenSets: Set<string>[] = candidates.map((c) => {
      const tokens = c.content.toLowerCase().split(/\s+/);
      return new Set(tokens);
    });

    while (selected.length < k && remaining.size > 0) {
      let bestIdx = -1;
      let bestMMR = -Infinity;

      for (const idx of remaining) {
        const candidate = candidates[idx]!;
        const normalizedScore = candidate.score / maxScore;

        // Max similarity to any already-selected result
        let maxSimToSelected = 0;
        for (const sel of selected) {
          const selIdx = candidates.indexOf(sel);
          const sim = jaccardSimilarity(tokenSets[idx]!, tokenSets[selIdx]!);
          if (sim > maxSimToSelected) maxSimToSelected = sim;
        }

        const mmr = lambda * normalizedScore - (1 - lambda) * maxSimToSelected;
        if (mmr > bestMMR) {
          bestMMR = mmr;
          bestIdx = idx;
        }
      }

      if (bestIdx === -1) break;

      selected.push(candidates[bestIdx]!);
      remaining.delete(bestIdx);
    }

    return selected;
  }

  // ─── Public API: Update ────────────────────────────────────────────────

  /**
   * Update an existing fact. Re-generates the embedding if content changed.
   */
  async update(id: string, updates: Partial<Omit<EnhancedFact, "id">>): Promise<void> {
    await this.ensureLoaded();

    const fact = this.facts.get(id);
    if (!fact) {
      throw new Error(`Fact "${id}" not found`);
    }

    const contentChanged = updates.content !== undefined && updates.content !== fact.content;

    // Apply updates
    if (updates.content !== undefined) fact.content = updates.content;
    if (updates.section !== undefined) fact.section = updates.section;
    if (updates.type !== undefined) fact.type = updates.type;
    if (updates.tags !== undefined) fact.tags = updates.tags;
    if (updates.confidence !== undefined) fact.confidence = updates.confidence;
    if (updates.related_to !== undefined) fact.related_to = updates.related_to;
    fact.updated_at = todayISO();

    // Re-index in TF-IDF if content changed
    if (contentChanged) {
      this.tfidfEngine.addDocument(
        fact.id,
        `${fact.content} ${fact.tags.join(" ")} ${fact.section}`
      );
    }

    // Re-generate embedding if content or tags changed
    if (contentChanged || updates.tags !== undefined) {
      await this.embedFact(fact);
    }

    await this.persist();
  }

  // ─── Public API: Delete ────────────────────────────────────────────────

  /**
   * Delete a fact and its embedding. Also removes references from other facts.
   */
  async delete(id: string): Promise<void> {
    await this.ensureLoaded();

    if (!this.facts.has(id)) {
      throw new Error(`Fact "${id}" not found`);
    }

    this.facts.delete(id);
    this.tfidfEngine.removeDocument(id);
    await this.vectorStore.delete(id);

    // Remove references from other facts
    for (const fact of this.facts.values()) {
      fact.related_to = fact.related_to.filter((r) => r !== id);
    }

    await this.persist();
  }

  // ─── Public API: Related Facts ─────────────────────────────────────────

  /**
   * Find facts related to a given fact using both the knowledge graph
   * and vector similarity.
   *
   * Returns results with a `relatedness` score that combines:
   * - Direct graph connections (weight 0.5)
   * - Vector similarity (weight 0.5)
   */
  async findRelated(
    factId: string,
    k = 5
  ): Promise<Array<EnhancedFact & { relatedness: number }>> {
    await this.ensureLoaded();

    const sourceFact = this.facts.get(factId);
    if (!sourceFact) return [];

    const scored = new Map<string, number>();

    // Graph-based relatedness: direct connections get a base score
    for (const relatedId of sourceFact.related_to) {
      if (this.facts.has(relatedId)) {
        scored.set(relatedId, 0.5);
      }
    }

    // Also find facts that reference this fact
    for (const fact of this.facts.values()) {
      if (fact.id === factId) continue;
      if (fact.related_to.includes(factId)) {
        const current = scored.get(fact.id) ?? 0;
        scored.set(fact.id, Math.max(current, 0.4));
      }
    }

    // Vector-based relatedness
    const sourceEmbedding = this.vectorStore.getEmbedding(factId);
    if (sourceEmbedding) {
      try {
        const vectorResults = await this.vectorStore.search(sourceEmbedding, k * 2);
        for (const result of vectorResults) {
          if (result.id === factId) continue;
          if (!this.facts.has(result.id)) continue;
          const current = scored.get(result.id) ?? 0;
          // Normalize similarity to [0, 0.5] range and add to existing graph score
          const vectorComponent = ((result.score + 1) / 2) * 0.5;
          scored.set(result.id, current + vectorComponent);
        }
      } catch {
        // Vector search failed, use graph-only results
      }
    }

    // Convert to sorted array
    const results: Array<EnhancedFact & { relatedness: number }> = [];
    for (const [id, relatedness] of scored) {
      const fact = this.facts.get(id);
      if (fact) {
        results.push({ ...fact, relatedness });
      }
    }

    results.sort((a, b) => b.relatedness - a.relatedness);
    return results.slice(0, k);
  }

  // ─── Public API: Stats ─────────────────────────────────────────────────

  /** Get comprehensive memory analytics. */
  async stats(): Promise<MemoryStats> {
    await this.ensureLoaded();

    const bySection: Record<string, number> = {};
    const byType: Record<string, number> = {};
    const tagCounts = new Map<string, number>();
    let totalConfidence = 0;
    let staleCount = 0;
    const now = Date.now();
    const staleThresholdMs = 60 * 24 * 60 * 60 * 1000; // 60 days

    for (const fact of this.facts.values()) {
      bySection[fact.section] = (bySection[fact.section] ?? 0) + 1;
      byType[fact.type] = (byType[fact.type] ?? 0) + 1;
      totalConfidence += fact.confidence;

      for (const tag of fact.tags) {
        tagCounts.set(tag, (tagCounts.get(tag) ?? 0) + 1);
      }

      // Check staleness
      const lastDate = fact.last_accessed ?? fact.created_at;
      const lastMs = new Date(lastDate).getTime();
      if (now - lastMs > staleThresholdMs) {
        staleCount++;
      }
    }

    const topTags = Array.from(tagCounts.entries())
      .map(([tag, count]) => ({ tag, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 15);

    const vectorizedCount = await this.vectorStore.count();

    return {
      totalFacts: this.facts.size,
      bySection,
      byType,
      topTags,
      averageConfidence: this.facts.size > 0 ? totalConfidence / this.facts.size : 0,
      vectorizedCount,
      staleCount,
    };
  }

  // ─── Public API: Temporal Decay ────────────────────────────────────────

  /**
   * Apply temporal decay to reduce confidence of stale facts.
   *
   * Uses an exponential decay model: confidence *= 0.5^(daysSinceAccess / halfLife)
   *
   * Only decays facts that have not been accessed within the half-life period.
   * Facts with a confidence already at or below 0.1 are not decayed further.
   *
   * @param halfLifeDays - Decay half-life in days (default 30).
   * @returns The number of facts whose confidence was reduced.
   */
  async applyDecay(halfLifeDays = 30): Promise<number> {
    await this.ensureLoaded();

    const now = Date.now();
    const halfLifeMs = halfLifeDays * 24 * 60 * 60 * 1000;
    let decayedCount = 0;

    for (const fact of this.facts.values()) {
      // Skip facts that are already very low confidence
      if (fact.confidence <= 0.1) continue;

      const lastDate = fact.last_accessed ?? fact.created_at;
      const lastMs = new Date(lastDate).getTime();
      const elapsed = now - lastMs;

      // Only decay if past the half-life period
      if (elapsed > halfLifeMs) {
        const decayFactor = Math.pow(0.5, elapsed / halfLifeMs);
        const newConfidence = Math.max(0.1, fact.confidence * decayFactor);

        if (newConfidence < fact.confidence) {
          fact.confidence = Math.round(newConfidence * 1000) / 1000; // 3 decimal places
          fact.updated_at = todayISO();
          decayedCount++;
        }
      }
    }

    if (decayedCount > 0) {
      await this.persist();
    }

    return decayedCount;
  }

  // ─── Public API: Backfill Embeddings ───────────────────────────────────

  /**
   * Generate embeddings for all facts that do not yet have a vector in the
   * vector store. Useful after migrating existing data or changing providers.
   *
   * @returns The number of facts that were newly embedded.
   */
  async backfillEmbeddings(): Promise<number> {
    await this.ensureLoaded();

    const provider = await this.ensureProvider();
    if (!provider) return 0;

    // Find facts without embeddings
    const unembedded: EnhancedFact[] = [];
    for (const fact of this.facts.values()) {
      if (!this.vectorStore.has(fact.id)) {
        unembedded.push(fact);
      }
    }

    if (unembedded.length === 0) return 0;

    // Batch embed for efficiency
    const textsToEmbed = unembedded.map(
      (f) => `${f.section}: ${f.content} [${f.tags.join(", ")}]`
    );

    let embeddings: number[][];
    try {
      embeddings = await provider.embedBatch(textsToEmbed);
    } catch {
      // Batch failed — try one at a time
      embeddings = [];
      for (const text of textsToEmbed) {
        try {
          const emb = await provider.embed(text);
          embeddings.push(emb);
        } catch {
          // Skip this fact
          embeddings.push([]);
        }
      }
    }

    let embedded = 0;
    for (let i = 0; i < unembedded.length; i++) {
      const embedding = embeddings[i];
      if (embedding && embedding.length > 0) {
        const fact = unembedded[i]!;
        await this.vectorStore.upsert(fact.id, embedding, {
          section: fact.section,
          type: fact.type,
          tags: fact.tags,
        });
        embedded++;
      }
    }

    if (embedded > 0) {
      await this.vectorStore.save(this.vectorStorePath);
    }

    return embedded;
  }

  // ─── Public API: Direct Accessors ──────────────────────────────────────

  /** Get a single fact by ID. */
  async getFact(id: string): Promise<EnhancedFact | undefined> {
    await this.ensureLoaded();
    return this.facts.get(id);
  }

  /** Get all facts, optionally filtered by section. */
  async getAllFacts(section?: string): Promise<EnhancedFact[]> {
    await this.ensureLoaded();
    const all = Array.from(this.facts.values());
    if (section) return all.filter((f) => f.section === section);
    return all;
  }

  /** Get the name of the active embedding provider. */
  async getProviderName(): Promise<string> {
    const provider = await this.ensureProvider();
    return provider?.name ?? "none";
  }

  /** Invalidate the in-memory cache, forcing a reload from disk on next access. */
  invalidateCache(): void {
    this.loaded = false;
    this.facts.clear();
    this.sessions = [];
    this.tfidfEngine = new TfIdfEngine();
    this.vectorStore = new VectorStore();
    this.providerInitialized = false;
    this.embeddingProvider = null;
  }
}

// ─── Singleton Instance ──────────────────────────────────────────────────────

const ROOT = join(import.meta.dirname, "..", "..", "..");
const MEMORY_DIR = join(ROOT, "memory");
const STORE_FILE = join(MEMORY_DIR, "memory-store.json");
const VECTOR_STORE_FILE = join(MEMORY_DIR, "vector-store.json");

/** Shared singleton for use by MCP tools. */
let _instance: EnhancedMemoryManager | null = null;

/**
 * Get the singleton EnhancedMemoryManager instance.
 *
 * Lazy-initialized on first call. Uses the standard project paths.
 */
export function getEnhancedMemoryManager(): EnhancedMemoryManager {
  if (!_instance) {
    _instance = new EnhancedMemoryManager(STORE_FILE, VECTOR_STORE_FILE);
  }
  return _instance;
}

// ─── Utilities ───────────────────────────────────────────────────────────────

/** Jaccard similarity between two token sets (used for MMR re-ranking). */
function jaccardSimilarity(a: Set<string>, b: Set<string>): number {
  if (a.size === 0 && b.size === 0) return 1;
  let intersection = 0;
  for (const token of a) {
    if (b.has(token)) intersection++;
  }
  const union = a.size + b.size - intersection;
  return union === 0 ? 0 : intersection / union;
}
