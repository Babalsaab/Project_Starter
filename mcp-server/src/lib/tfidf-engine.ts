/**
 * Pure TypeScript TF-IDF + BM25 Semantic Search Engine
 *
 * No external dependencies. Works offline without API keys.
 * Provides hybrid scoring combining BM25 text relevance with
 * TF-IDF cosine similarity for semantic matching.
 */

// ─── Tokenization & Stemming ────────────────────────────────────────────────

const STOP_WORDS = new Set([
  "a", "an", "the", "is", "are", "was", "were", "be", "been", "being",
  "have", "has", "had", "do", "does", "did", "will", "would", "could",
  "should", "may", "might", "shall", "can", "to", "of", "in", "for",
  "on", "with", "at", "by", "from", "as", "into", "through", "during",
  "before", "after", "above", "below", "between", "out", "off", "over",
  "under", "again", "further", "then", "once", "here", "there", "when",
  "where", "why", "how", "all", "both", "each", "few", "more", "most",
  "other", "some", "such", "no", "nor", "not", "only", "own", "same",
  "so", "than", "too", "very", "just", "because", "but", "and", "or",
  "if", "while", "about", "up", "it", "its", "this", "that", "these",
  "those", "i", "me", "my", "we", "our", "you", "your", "he", "him",
  "his", "she", "her", "they", "them", "their", "what", "which", "who",
]);

/** Simple Porter-like suffix stripping for English */
function simpleStem(word: string): string {
  if (word.length < 4) return word;
  // Remove common suffixes
  const suffixes = [
    "ational", "tional", "enci", "anci", "izer", "ator",
    "ness", "ment", "able", "ible", "tion", "sion",
    "ally", "ful", "ous", "ive", "ize", "ise",
    "ing", "ble", "ant", "ent", "ism", "ist",
    "ity", "ety", "ed", "ly", "er", "es", "al", "s",
  ];
  for (const suffix of suffixes) {
    if (word.endsWith(suffix) && word.length - suffix.length >= 3) {
      return word.slice(0, -suffix.length);
    }
  }
  return word;
}

/** Tokenize text into normalized, stemmed terms */
export function tokenize(text: string): string[] {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s_-]/g, " ")
    .split(/\s+/)
    .filter((w) => w.length >= 2 && !STOP_WORDS.has(w))
    .map(simpleStem);
}

// ─── TF-IDF Engine ──────────────────────────────────────────────────────────

export interface TfIdfDocument {
  id: string;
  tokens: string[];
  termFreqs: Map<string, number>;
  magnitude: number;
}

export interface SearchResult {
  id: string;
  score: number;
  bm25Score: number;
  cosineSimilarity: number;
}

export class TfIdfEngine {
  private documents: Map<string, TfIdfDocument> = new Map();
  private documentFreqs: Map<string, number> = new Map(); // term -> num docs containing it
  private totalDocs = 0;
  private avgDocLen = 0;

  /** Add or update a document */
  addDocument(id: string, text: string): void {
    // Remove old version if exists
    if (this.documents.has(id)) {
      this.removeDocument(id);
    }

    const tokens = tokenize(text);
    const termFreqs = new Map<string, number>();
    for (const token of tokens) {
      termFreqs.set(token, (termFreqs.get(token) ?? 0) + 1);
    }

    // Update document frequencies
    for (const term of termFreqs.keys()) {
      this.documentFreqs.set(term, (this.documentFreqs.get(term) ?? 0) + 1);
    }

    this.totalDocs++;
    this.updateAvgDocLen();

    const doc: TfIdfDocument = { id, tokens, termFreqs, magnitude: 0 };
    doc.magnitude = this.computeMagnitude(doc);
    this.documents.set(id, doc);
  }

  /** Remove a document */
  removeDocument(id: string): void {
    const doc = this.documents.get(id);
    if (!doc) return;

    for (const term of doc.termFreqs.keys()) {
      const count = this.documentFreqs.get(term) ?? 1;
      if (count <= 1) {
        this.documentFreqs.delete(term);
      } else {
        this.documentFreqs.set(term, count - 1);
      }
    }

    this.documents.delete(id);
    this.totalDocs--;
    this.updateAvgDocLen();
  }

  /** Hybrid search combining BM25 + cosine similarity */
  search(query: string, topK = 10, bm25Weight = 0.6): SearchResult[] {
    const queryTokens = tokenize(query);
    if (queryTokens.length === 0) return [];

    const queryTermFreqs = new Map<string, number>();
    for (const token of queryTokens) {
      queryTermFreqs.set(token, (queryTermFreqs.get(token) ?? 0) + 1);
    }

    const results: SearchResult[] = [];

    for (const [docId, doc] of this.documents) {
      const bm25Score = this.bm25Score(queryTokens, doc);
      const cosineSim = this.cosineSimilarity(queryTermFreqs, doc);

      const combinedScore = bm25Weight * bm25Score + (1 - bm25Weight) * cosineSim;
      if (combinedScore > 0) {
        results.push({
          id: docId,
          score: combinedScore,
          bm25Score,
          cosineSimilarity: cosineSim,
        });
      }
    }

    return results.sort((a, b) => b.score - a.score).slice(0, topK);
  }

  /** BM25 scoring for a query against a document */
  private bm25Score(queryTokens: string[], doc: TfIdfDocument): number {
    const k1 = 1.5;
    const b = 0.75;
    let score = 0;

    for (const term of queryTokens) {
      const df = this.documentFreqs.get(term) ?? 0;
      if (df === 0) continue;

      const idf = Math.log(1 + (this.totalDocs - df + 0.5) / (df + 0.5));
      const tf = doc.termFreqs.get(term) ?? 0;
      const docLen = doc.tokens.length;
      const tfNorm = (tf * (k1 + 1)) / (tf + k1 * (1 - b + b * (docLen / this.avgDocLen)));

      score += idf * tfNorm;
    }

    return score;
  }

  /** TF-IDF cosine similarity between query and document */
  private cosineSimilarity(queryTermFreqs: Map<string, number>, doc: TfIdfDocument): number {
    let dotProduct = 0;
    let queryMagnitude = 0;

    for (const [term, queryTf] of queryTermFreqs) {
      const idf = this.idf(term);
      const queryTfIdf = (queryTf / queryTermFreqs.size) * idf;
      queryMagnitude += queryTfIdf * queryTfIdf;

      const docTf = doc.termFreqs.get(term) ?? 0;
      if (docTf > 0) {
        const docTfIdf = (docTf / doc.tokens.length) * idf;
        dotProduct += queryTfIdf * docTfIdf;
      }
    }

    queryMagnitude = Math.sqrt(queryMagnitude);
    if (queryMagnitude === 0 || doc.magnitude === 0) return 0;

    return dotProduct / (queryMagnitude * doc.magnitude);
  }

  private idf(term: string): number {
    const df = this.documentFreqs.get(term) ?? 0;
    if (df === 0) return 0;
    return Math.log(1 + this.totalDocs / df);
  }

  private computeMagnitude(doc: TfIdfDocument): number {
    let sum = 0;
    for (const [term, tf] of doc.termFreqs) {
      const tfidf = (tf / doc.tokens.length) * this.idf(term);
      sum += tfidf * tfidf;
    }
    return Math.sqrt(sum);
  }

  private updateAvgDocLen(): void {
    if (this.totalDocs === 0) {
      this.avgDocLen = 0;
      return;
    }
    let totalLen = 0;
    for (const doc of this.documents.values()) {
      totalLen += doc.tokens.length;
    }
    this.avgDocLen = totalLen / this.totalDocs;
  }

  /** Export state for persistence */
  serialize(): object {
    const docs: Array<{ id: string; tokens: string[]; termFreqs: Record<string, number> }> = [];
    for (const [, doc] of this.documents) {
      const freqs: Record<string, number> = {};
      for (const [k, v] of doc.termFreqs) freqs[k] = v;
      docs.push({ id: doc.id, tokens: doc.tokens, termFreqs: freqs });
    }
    const dfMap: Record<string, number> = {};
    for (const [k, v] of this.documentFreqs) dfMap[k] = v;
    return { docs, documentFreqs: dfMap, totalDocs: this.totalDocs };
  }

  /** Restore from serialized state */
  deserialize(data: { docs: Array<{ id: string; tokens: string[]; termFreqs: Record<string, number> }>; documentFreqs: Record<string, number>; totalDocs: number }): void {
    this.documents.clear();
    this.documentFreqs.clear();

    for (const [k, v] of Object.entries(data.documentFreqs)) {
      this.documentFreqs.set(k, v);
    }
    this.totalDocs = data.totalDocs;

    for (const docData of data.docs) {
      const termFreqs = new Map<string, number>();
      for (const [k, v] of Object.entries(docData.termFreqs)) {
        termFreqs.set(k, v);
      }
      const doc: TfIdfDocument = {
        id: docData.id,
        tokens: docData.tokens,
        termFreqs,
        magnitude: 0,
      };
      doc.magnitude = this.computeMagnitude(doc);
      this.documents.set(docData.id, doc);
    }

    this.updateAvgDocLen();
  }

  get size(): number {
    return this.totalDocs;
  }
}
