/**
 * Vector Store — In-Memory with JSON Persistence
 *
 * Stores embedding vectors alongside fact IDs for fast similarity search.
 * Provides both standard cosine-similarity search and MMR (Maximal Marginal
 * Relevance) search to balance relevance with diversity.
 *
 * Persistence format: JSON file at `memory/vector-store.json`.
 * All search operations run in-memory for speed; the file is loaded once
 * at startup and saved after mutations.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "fs";
import { dirname } from "path";

// ─── Types ───────────────────────────────────────────────────────────────────

/** A single entry in the vector store. */
export interface VectorEntry {
  /** Unique identifier (matches the memory fact ID). */
  id: string;
  /** The embedding vector. */
  embedding: number[];
  /** Optional metadata stored alongside the vector. */
  metadata?: Record<string, unknown>;
}

/** A search result with its similarity score. */
export interface VectorSearchResult {
  /** The matched entry's ID. */
  id: string;
  /** Cosine similarity score (0 to 1 for normalized vectors, -1 to 1 otherwise). */
  score: number;
  /** Optional metadata from the matched entry. */
  metadata?: Record<string, unknown>;
}

/** Serialized format for JSON persistence. */
interface VectorStoreData {
  version: string;
  dimensions: number;
  entries: Array<{
    id: string;
    embedding: number[];
    metadata?: Record<string, unknown>;
  }>;
}

// ─── Math Utilities ──────────────────────────────────────────────────────────

/**
 * Compute cosine similarity between two vectors.
 *
 * For L2-normalized vectors this is simply the dot product.
 * For unnormalized vectors it divides by the product of magnitudes.
 *
 * Returns 0 if either vector has zero magnitude.
 */
export function cosineSimilarity(a: number[], b: number[]): number {
  const len = Math.min(a.length, b.length);
  let dot = 0;
  let magA = 0;
  let magB = 0;

  for (let i = 0; i < len; i++) {
    const ai = a[i]!;
    const bi = b[i]!;
    dot += ai * bi;
    magA += ai * ai;
    magB += bi * bi;
  }

  const denom = Math.sqrt(magA) * Math.sqrt(magB);
  if (denom === 0) return 0;
  return dot / denom;
}

/**
 * L2-normalize a vector in-place and return it.
 * If the vector has zero magnitude, it is returned unchanged.
 */
function l2Normalize(vec: number[]): number[] {
  let mag = 0;
  for (const v of vec) mag += v * v;
  mag = Math.sqrt(mag);
  if (mag === 0) return vec;
  for (let i = 0; i < vec.length; i++) {
    vec[i] = vec[i]! / mag;
  }
  return vec;
}

// ─── Vector Store ────────────────────────────────────────────────────────────

export class VectorStore {
  /** In-memory index: id -> VectorEntry */
  private entries: Map<string, VectorEntry> = new Map();
  /** Expected dimensionality (set by first insert or load). */
  private dimensions = 0;

  /**
   * Create a new VectorStore.
   *
   * @param expectedDimensions - If known ahead of time, validates inserts
   *   against this dimensionality. If 0, dimensions are inferred from the
   *   first inserted vector.
   */
  constructor(expectedDimensions = 0) {
    this.dimensions = expectedDimensions;
  }

  // ─── Mutations ───────────────────────────────────────────────────────────

  /**
   * Insert or update a vector entry.
   *
   * The embedding is L2-normalized on insert so that cosine similarity
   * reduces to a simple dot product during search.
   *
   * @throws if the embedding dimensionality does not match existing entries.
   */
  async upsert(
    id: string,
    embedding: number[],
    metadata?: Record<string, unknown>
  ): Promise<void> {
    if (embedding.length === 0) {
      throw new Error("Cannot insert a zero-length embedding");
    }

    // Set or validate dimensions
    if (this.dimensions === 0) {
      this.dimensions = embedding.length;
    } else if (embedding.length !== this.dimensions) {
      throw new Error(
        `Dimension mismatch: expected ${this.dimensions}, got ${embedding.length}. ` +
          `If the embedding provider changed, clear the vector store first.`
      );
    }

    // Normalize and store
    const normalized = l2Normalize([...embedding]);
    this.entries.set(id, { id, embedding: normalized, metadata });
  }

  /**
   * Insert or update multiple vector entries in one call.
   *
   * @param items - Array of { id, embedding, metadata? } objects.
   */
  async upsertBatch(
    items: Array<{ id: string; embedding: number[]; metadata?: Record<string, unknown> }>
  ): Promise<void> {
    for (const item of items) {
      await this.upsert(item.id, item.embedding, item.metadata);
    }
  }

  /** Remove a vector entry by ID. No-op if the ID does not exist. */
  async delete(id: string): Promise<void> {
    this.entries.delete(id);
  }

  // ─── Search ──────────────────────────────────────────────────────────────

  /**
   * Find the k most similar vectors to a query vector using cosine similarity.
   *
   * @param query - The query embedding (will be L2-normalized internally).
   * @param k - Maximum number of results to return.
   * @returns Results sorted by descending similarity score.
   */
  async search(query: number[], k: number): Promise<VectorSearchResult[]> {
    if (this.entries.size === 0 || query.length === 0) return [];

    const normalizedQuery = l2Normalize([...query]);
    const scored: VectorSearchResult[] = [];

    for (const entry of this.entries.values()) {
      // Since both vectors are normalized, cosine sim = dot product
      const score = dotProduct(normalizedQuery, entry.embedding);
      scored.push({ id: entry.id, score, metadata: entry.metadata });
    }

    scored.sort((a, b) => b.score - a.score);
    return scored.slice(0, k);
  }

  /**
   * Maximal Marginal Relevance (MMR) search.
   *
   * Balances relevance to the query with diversity among selected results.
   * This reduces redundancy when many stored facts cover similar topics.
   *
   * Algorithm (Carbonell & Goldstein, 1998):
   *   MMR = lambda * sim(query, doc) - (1 - lambda) * max(sim(doc, selected))
   *
   * @param query - The query embedding.
   * @param k - Number of results to return.
   * @param lambda - Trade-off parameter (default 0.7).
   *   - lambda = 1.0 → pure relevance (same as standard search)
   *   - lambda = 0.0 → pure diversity
   *   - lambda = 0.7 → good default balancing both
   * @returns Results ordered by MMR score (not raw similarity).
   */
  async searchMMR(
    query: number[],
    k: number,
    lambda = 0.7
  ): Promise<VectorSearchResult[]> {
    if (this.entries.size === 0 || query.length === 0) return [];

    const normalizedQuery = l2Normalize([...query]);

    // Pre-compute query similarities for all entries
    const candidates = new Map<
      string,
      { entry: VectorEntry; querySim: number }
    >();
    for (const entry of this.entries.values()) {
      const querySim = dotProduct(normalizedQuery, entry.embedding);
      candidates.set(entry.id, { entry, querySim });
    }

    const selected: VectorSearchResult[] = [];
    const selectedEntries: VectorEntry[] = [];

    while (selected.length < k && candidates.size > 0) {
      let bestId = "";
      let bestMMR = -Infinity;

      for (const [id, { entry, querySim }] of candidates) {
        // Compute max similarity to any already-selected result
        let maxSimToSelected = 0;
        for (const sel of selectedEntries) {
          const sim = dotProduct(entry.embedding, sel.embedding);
          if (sim > maxSimToSelected) maxSimToSelected = sim;
        }

        // MMR formula
        const mmrScore = lambda * querySim - (1 - lambda) * maxSimToSelected;
        if (mmrScore > bestMMR) {
          bestMMR = mmrScore;
          bestId = id;
        }
      }

      if (!bestId) break;

      const winner = candidates.get(bestId)!;
      selected.push({
        id: bestId,
        score: winner.querySim, // Report the actual similarity, not MMR
        metadata: winner.entry.metadata,
      });
      selectedEntries.push(winner.entry);
      candidates.delete(bestId);
    }

    return selected;
  }

  // ─── Accessors ───────────────────────────────────────────────────────────

  /** Return the number of entries in the store. */
  async count(): Promise<number> {
    return this.entries.size;
  }

  /** Check whether an entry with the given ID exists. */
  has(id: string): boolean {
    return this.entries.has(id);
  }

  /** Get the raw embedding for an entry, or undefined if not found. */
  getEmbedding(id: string): number[] | undefined {
    return this.entries.get(id)?.embedding;
  }

  /** Get the dimensionality of stored vectors (0 if empty). */
  getDimensions(): number {
    return this.dimensions;
  }

  // ─── Persistence ─────────────────────────────────────────────────────────

  /**
   * Save the vector store to a JSON file.
   *
   * @param path - Absolute file path (e.g. `memory/vector-store.json`).
   */
  async save(path: string): Promise<void> {
    const dir = dirname(path);
    if (!existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
    }

    const data: VectorStoreData = {
      version: "1.0.0",
      dimensions: this.dimensions,
      entries: Array.from(this.entries.values()).map((e) => ({
        id: e.id,
        embedding: e.embedding,
        metadata: e.metadata,
      })),
    };

    writeFileSync(path, JSON.stringify(data), "utf-8");
  }

  /**
   * Load the vector store from a JSON file.
   *
   * Replaces all in-memory data. If the file does not exist, this is a no-op.
   *
   * @param path - Absolute file path.
   */
  async load(path: string): Promise<void> {
    if (!existsSync(path)) return;

    let raw: string;
    try {
      raw = readFileSync(path, "utf-8");
    } catch {
      return; // File unreadable, start fresh
    }

    let data: VectorStoreData;
    try {
      data = JSON.parse(raw) as VectorStoreData;
    } catch {
      return; // Corrupted JSON, start fresh
    }

    // Validate structure
    if (!data.entries || !Array.isArray(data.entries)) return;

    this.entries.clear();
    this.dimensions = data.dimensions || 0;

    for (const entry of data.entries) {
      if (entry.id && Array.isArray(entry.embedding) && entry.embedding.length > 0) {
        this.entries.set(entry.id, {
          id: entry.id,
          embedding: entry.embedding,
          metadata: entry.metadata,
        });
      }
    }

    // Re-infer dimensions from first entry if header was missing
    if (this.dimensions === 0 && this.entries.size > 0) {
      const first = this.entries.values().next().value;
      if (first) {
        this.dimensions = first.embedding.length;
      }
    }
  }

  /** Clear all entries from the in-memory index (does not touch disk). */
  clear(): void {
    this.entries.clear();
    this.dimensions = 0;
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/** Dot product of two vectors (fast path for normalized vectors). */
function dotProduct(a: number[], b: number[]): number {
  const len = Math.min(a.length, b.length);
  let sum = 0;
  for (let i = 0; i < len; i++) {
    sum += a[i]! * b[i]!;
  }
  return sum;
}
