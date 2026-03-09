/**
 * Embedding Provider Abstraction Layer
 *
 * Supports multiple vector embedding backends with automatic fallback:
 *   1. Ollama (local, no API key needed) — nomic-embed-text (768d) or mxbai-embed-large (1024d)
 *   2. OpenAI — text-embedding-3-small (1536d)
 *   3. TF-IDF vectorizer (built-in fallback, always works)
 *
 * The factory function `createEmbeddingProvider()` auto-detects the best available
 * provider at startup. All providers share a common interface so callers never
 * need to care which backend is active.
 */

import { tokenize } from "./tfidf-engine.js";

// ─── Interface ───────────────────────────────────────────────────────────────

/** Common interface every embedding provider must implement. */
export interface EmbeddingProvider {
  /** Human-readable provider name (e.g. "ollama", "openai", "tfidf-fallback"). */
  readonly name: string;

  /** Dimensionality of the vectors this provider produces. */
  readonly dimensions: number;

  /** Embed a single text string and return its vector. */
  embed(text: string): Promise<number[]>;

  /** Embed multiple texts in one call (providers that support batching win here). */
  embedBatch(texts: string[]): Promise<number[][]>;
}

// ─── Ollama Provider ─────────────────────────────────────────────────────────

/** Configuration for the Ollama embedding provider. */
interface OllamaConfig {
  baseUrl: string;
  model: string;
  dimensions: number;
  timeoutMs: number;
}

const OLLAMA_DEFAULTS: OllamaConfig = {
  baseUrl: "http://localhost:11434",
  model: "nomic-embed-text",
  dimensions: 768,
  timeoutMs: 30_000,
};

/**
 * Ollama Embedding Provider
 *
 * Connects to a locally-running Ollama instance. Zero cost, full privacy.
 * Falls back gracefully if Ollama is not running.
 */
export class OllamaEmbeddingProvider implements EmbeddingProvider {
  readonly name = "ollama";
  readonly dimensions: number;
  private config: OllamaConfig;

  constructor(config?: Partial<OllamaConfig>) {
    this.config = { ...OLLAMA_DEFAULTS, ...config };
    this.dimensions = this.config.dimensions;
  }

  async embed(text: string): Promise<number[]> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.config.timeoutMs);

    try {
      const response = await fetch(`${this.config.baseUrl}/api/embeddings`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ model: this.config.model, prompt: text }),
        signal: controller.signal,
      });

      if (!response.ok) {
        const body = await response.text().catch(() => "");
        throw new Error(`Ollama returned ${response.status}: ${body}`);
      }

      const data = (await response.json()) as { embedding: number[] };
      if (!Array.isArray(data.embedding) || data.embedding.length === 0) {
        throw new Error("Ollama returned an empty or invalid embedding");
      }

      return data.embedding;
    } finally {
      clearTimeout(timer);
    }
  }

  async embedBatch(texts: string[]): Promise<number[][]> {
    // Ollama does not natively support batch embeddings, so we serialize.
    // We use a small concurrency limit to avoid overwhelming a local GPU.
    const results: number[][] = [];
    const CONCURRENCY = 4;

    for (let i = 0; i < texts.length; i += CONCURRENCY) {
      const batch = texts.slice(i, i + CONCURRENCY);
      const batchResults = await Promise.all(batch.map((t) => this.embed(t)));
      results.push(...batchResults);
    }

    return results;
  }

  /** Probe whether Ollama is reachable and has the required model pulled. */
  static async isAvailable(config?: Partial<OllamaConfig>): Promise<boolean> {
    const cfg = { ...OLLAMA_DEFAULTS, ...config };
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 3_000);

    try {
      const response = await fetch(`${cfg.baseUrl}/api/tags`, {
        signal: controller.signal,
      });

      if (!response.ok) return false;

      const data = (await response.json()) as { models?: Array<{ name: string }> };
      const models = data.models ?? [];
      return models.some((m) => m.name.startsWith(cfg.model));
    } catch {
      return false;
    } finally {
      clearTimeout(timer);
    }
  }
}

// ─── OpenAI Provider ─────────────────────────────────────────────────────────

/** Configuration for the OpenAI embedding provider. */
interface OpenAIConfig {
  apiKey: string;
  model: string;
  dimensions: number;
  baseUrl: string;
  timeoutMs: number;
}

const OPENAI_DEFAULTS: Omit<OpenAIConfig, "apiKey"> = {
  model: "text-embedding-3-small",
  dimensions: 1536,
  baseUrl: "https://api.openai.com/v1",
  timeoutMs: 30_000,
};

/**
 * OpenAI Embedding Provider
 *
 * Uses the OpenAI embeddings API. Requires OPENAI_API_KEY in environment.
 * Supports native batch embedding for efficiency.
 */
export class OpenAIEmbeddingProvider implements EmbeddingProvider {
  readonly name = "openai";
  readonly dimensions: number;
  private config: OpenAIConfig;

  constructor(config?: Partial<OpenAIConfig>) {
    const apiKey = config?.apiKey ?? process.env["OPENAI_API_KEY"] ?? "";
    if (!apiKey) {
      throw new Error("OpenAI embedding provider requires OPENAI_API_KEY environment variable");
    }
    this.config = { ...OPENAI_DEFAULTS, apiKey, ...config };
    this.dimensions = this.config.dimensions;
  }

  async embed(text: string): Promise<number[]> {
    const results = await this.embedBatch([text]);
    return results[0]!;
  }

  async embedBatch(texts: string[]): Promise<number[][]> {
    if (texts.length === 0) return [];

    // OpenAI supports up to 2048 inputs per request; chunk conservatively.
    const MAX_BATCH = 512;
    const allResults: number[][] = [];

    for (let i = 0; i < texts.length; i += MAX_BATCH) {
      const batch = texts.slice(i, i + MAX_BATCH);
      const batchResults = await this.callApi(batch);
      allResults.push(...batchResults);
    }

    return allResults;
  }

  private async callApi(inputs: string[]): Promise<number[][]> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.config.timeoutMs);

    try {
      const response = await fetch(`${this.config.baseUrl}/embeddings`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.config.apiKey}`,
        },
        body: JSON.stringify({
          model: this.config.model,
          input: inputs,
        }),
        signal: controller.signal,
      });

      if (!response.ok) {
        const body = await response.text().catch(() => "");
        throw new Error(`OpenAI returned ${response.status}: ${body}`);
      }

      const data = (await response.json()) as {
        data: Array<{ embedding: number[]; index: number }>;
      };

      // OpenAI returns embeddings sorted by index.
      return data.data
        .sort((a, b) => a.index - b.index)
        .map((d) => d.embedding);
    } finally {
      clearTimeout(timer);
    }
  }

  /** Check whether an OpenAI API key is configured. */
  static isAvailable(): boolean {
    const key = process.env["OPENAI_API_KEY"];
    return typeof key === "string" && key.length > 0;
  }
}

// ─── TF-IDF Fallback Provider ────────────────────────────────────────────────

/**
 * TF-IDF Embedding Provider (built-in fallback)
 *
 * Converts text into a fixed-dimension vector using feature hashing of
 * TF-IDF-weighted tokens. No external services or API keys required.
 *
 * Quality is lower than neural embeddings but guarantees the system
 * always has vector search capability, even fully offline.
 */
export class TFIDFEmbeddingProvider implements EmbeddingProvider {
  readonly name = "tfidf-fallback";
  readonly dimensions: number;

  constructor(dimensions = 256) {
    this.dimensions = dimensions;
  }

  async embed(text: string): Promise<number[]> {
    return this.vectorize(text);
  }

  async embedBatch(texts: string[]): Promise<number[][]> {
    return texts.map((t) => this.vectorize(t));
  }

  /**
   * Convert text to a fixed-dimension vector via feature hashing.
   *
   * 1. Tokenize and stem the text (reusing the existing tokenizer).
   * 2. Compute term frequencies within the document.
   * 3. Hash each token to a bucket in the output vector (signed hashing
   *    to reduce collision bias).
   * 4. L2-normalize the result so cosine similarity works correctly.
   */
  private vectorize(text: string): number[] {
    const tokens = tokenize(text);
    if (tokens.length === 0) {
      return new Array(this.dimensions).fill(0) as number[];
    }

    // Term frequency map
    const tf = new Map<string, number>();
    for (const t of tokens) {
      tf.set(t, (tf.get(t) ?? 0) + 1);
    }

    // Feature hashing into fixed-dimension vector
    const vec = new Array(this.dimensions).fill(0) as number[];
    for (const [term, freq] of tf) {
      const hash1 = this.fnv1a(term);
      const hash2 = this.fnv1a(term + "_sign");
      const bucket = Math.abs(hash1) % this.dimensions;
      const sign = hash2 % 2 === 0 ? 1 : -1;

      // Weight by log(1 + tf) to dampen high-frequency terms
      vec[bucket] = (vec[bucket] ?? 0) + sign * Math.log1p(freq);
    }

    // L2 normalization
    return this.l2Normalize(vec);
  }

  /** FNV-1a 32-bit hash (fast, good distribution for feature hashing). */
  private fnv1a(str: string): number {
    let hash = 0x811c9dc5;
    for (let i = 0; i < str.length; i++) {
      hash ^= str.charCodeAt(i);
      hash = (hash * 0x01000193) | 0;
    }
    return hash >>> 0; // ensure unsigned
  }

  /** Normalize a vector to unit length. Returns a zero vector if magnitude is 0. */
  private l2Normalize(vec: number[]): number[] {
    let mag = 0;
    for (const v of vec) mag += v * v;
    mag = Math.sqrt(mag);
    if (mag === 0) return vec;
    return vec.map((v) => v / mag);
  }
}

// ─── Factory ─────────────────────────────────────────────────────────────────

/**
 * Create the best available embedding provider.
 *
 * Detection order:
 *   1. Ollama (local, free) — if running and has the embedding model
 *   2. OpenAI — if OPENAI_API_KEY is set
 *   3. TF-IDF fallback — always works, no dependencies
 *
 * This function is async because probing Ollama requires a network call.
 */
export async function createEmbeddingProvider(): Promise<EmbeddingProvider> {
  // 1. Try Ollama (best option: local, private, free)
  try {
    const ollamaAvailable = await OllamaEmbeddingProvider.isAvailable();
    if (ollamaAvailable) {
      return new OllamaEmbeddingProvider();
    }
  } catch {
    // Ollama not available, try next
  }

  // 2. Try OpenAI (good quality, requires API key)
  if (OpenAIEmbeddingProvider.isAvailable()) {
    try {
      return new OpenAIEmbeddingProvider();
    } catch {
      // API key invalid or other issue, try next
    }
  }

  // 3. Fallback to TF-IDF (always works)
  return new TFIDFEmbeddingProvider();
}

/**
 * Create a specific embedding provider by name.
 *
 * @param name - Provider name: "ollama", "openai", or "tfidf"
 * @throws if the requested provider is not available
 */
export async function createNamedProvider(name: "ollama" | "openai" | "tfidf"): Promise<EmbeddingProvider> {
  switch (name) {
    case "ollama": {
      const available = await OllamaEmbeddingProvider.isAvailable();
      if (!available) {
        throw new Error("Ollama is not running or does not have the nomic-embed-text model");
      }
      return new OllamaEmbeddingProvider();
    }
    case "openai": {
      if (!OpenAIEmbeddingProvider.isAvailable()) {
        throw new Error("OPENAI_API_KEY environment variable is not set");
      }
      return new OpenAIEmbeddingProvider();
    }
    case "tfidf":
      return new TFIDFEmbeddingProvider();
    default:
      throw new Error(`Unknown embedding provider: ${name as string}`);
  }
}
