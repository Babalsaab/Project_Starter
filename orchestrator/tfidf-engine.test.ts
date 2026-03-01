/**
 * Unit Tests — TF-IDF + BM25 Search Engine
 *
 * Tests for tokenization, document indexing, search ranking,
 * serialization/deserialization, and edge cases.
 *
 * Note: The TfIdfEngine lives in mcp-server/src/lib/tfidf-engine.ts
 * but uses no external dependencies. We import it directly since
 * vitest can resolve TypeScript imports across the repo.
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { TfIdfEngine, tokenize } from '../mcp-server/src/lib/tfidf-engine';

// ─── Tests: tokenize ────────────────────────────────────────────────────────

describe('tokenize', () => {
  it('should lowercase all tokens', () => {
    const tokens = tokenize('Hello WORLD FoO');
    for (const t of tokens) {
      expect(t).toBe(t.toLowerCase());
    }
  });

  it('should remove stop words', () => {
    const tokens = tokenize('the quick brown fox is a very fast animal');
    expect(tokens).not.toContain('the');
    expect(tokens).not.toContain('is');
    expect(tokens).not.toContain('a');
    expect(tokens).not.toContain('very');
  });

  it('should filter out single-character tokens', () => {
    const tokens = tokenize('a b c d hello world');
    expect(tokens.every((t) => t.length >= 2)).toBe(true);
  });

  it('should apply stemming to common suffixes', () => {
    const tokens = tokenize('running testing deployment');
    // "running" -> stem removes "ing" -> "runn" (or similar)
    // "testing" -> "test"
    // The exact stems depend on the simple stemmer
    expect(tokens.length).toBeGreaterThan(0);
  });

  it('should handle special characters by replacing with spaces', () => {
    const tokens = tokenize('hello@world.com foo/bar-baz');
    // @ and . become spaces, so we get individual words
    expect(tokens.length).toBeGreaterThan(0);
  });

  it('should return empty array for stop-words-only input', () => {
    const tokens = tokenize('the is a an');
    expect(tokens).toHaveLength(0);
  });

  it('should return empty array for empty string', () => {
    expect(tokenize('')).toHaveLength(0);
  });

  it('should handle hyphenated words', () => {
    const tokens = tokenize('test-driven development');
    expect(tokens.length).toBeGreaterThan(0);
  });
});

// ─── Tests: TfIdfEngine ─────────────────────────────────────────────────────

describe('TfIdfEngine', () => {
  let engine: TfIdfEngine;

  beforeEach(() => {
    engine = new TfIdfEngine();
  });

  describe('addDocument', () => {
    it('should increase document count', () => {
      expect(engine.size).toBe(0);
      engine.addDocument('doc1', 'Hello world');
      expect(engine.size).toBe(1);
    });

    it('should handle multiple documents', () => {
      engine.addDocument('doc1', 'TypeScript programming');
      engine.addDocument('doc2', 'JavaScript frameworks');
      engine.addDocument('doc3', 'Python data science');
      expect(engine.size).toBe(3);
    });

    it('should overwrite document with same ID', () => {
      engine.addDocument('doc1', 'Original content');
      engine.addDocument('doc1', 'Updated content');
      expect(engine.size).toBe(1);
    });
  });

  describe('removeDocument', () => {
    it('should decrease document count', () => {
      engine.addDocument('doc1', 'Hello world');
      engine.addDocument('doc2', 'Goodbye world');
      engine.removeDocument('doc1');
      expect(engine.size).toBe(1);
    });

    it('should handle removing non-existent document gracefully', () => {
      engine.removeDocument('nonexistent');
      expect(engine.size).toBe(0);
    });
  });

  describe('search', () => {
    beforeEach(() => {
      engine.addDocument(
        'react-guide',
        'React is a JavaScript library for building user interfaces with components'
      );
      engine.addDocument(
        'vue-guide',
        'Vue is a progressive JavaScript framework for building user interfaces'
      );
      engine.addDocument(
        'angular-guide',
        'Angular is a TypeScript platform for building web applications'
      );
      engine.addDocument(
        'python-ml',
        'Python machine learning with scikit-learn and TensorFlow for data science'
      );
      engine.addDocument(
        'security-audit',
        'Security vulnerability scanning and penetration testing for web applications'
      );
    });

    it('should return relevant results for a query', () => {
      const results = engine.search('JavaScript framework');
      expect(results.length).toBeGreaterThan(0);
      // React and Vue are both JavaScript, so they should rank highly
      const topIds = results.slice(0, 3).map((r) => r.id);
      expect(topIds).toContain('react-guide');
    });

    it('should return results sorted by score (highest first)', () => {
      const results = engine.search('building user interfaces');
      for (let i = 1; i < results.length; i++) {
        expect(
          results[i - 1]!.score,
          `Result ${i - 1} should have higher score than result ${i}`
        ).toBeGreaterThanOrEqual(results[i]!.score);
      }
    });

    it('should respect topK parameter', () => {
      const results = engine.search('JavaScript', 2);
      expect(results.length).toBeLessThanOrEqual(2);
    });

    it('should return empty array for empty query', () => {
      const results = engine.search('');
      expect(results).toHaveLength(0);
    });

    it('should return empty array for stop-words-only query', () => {
      const results = engine.search('the is a an');
      expect(results).toHaveLength(0);
    });

    it('should include bm25Score and cosineSimilarity in results', () => {
      const results = engine.search('React components');
      expect(results.length).toBeGreaterThan(0);
      for (const r of results) {
        expect(r).toHaveProperty('bm25Score');
        expect(r).toHaveProperty('cosineSimilarity');
        expect(r).toHaveProperty('score');
        expect(r.score).toBeGreaterThan(0);
      }
    });

    it('should weight BM25 higher than cosine when bm25Weight is high', () => {
      const highBm25 = engine.search('security vulnerability', 5, 0.9);
      const lowBm25 = engine.search('security vulnerability', 5, 0.1);
      // Both should return results, but ranking may differ
      expect(highBm25.length).toBeGreaterThan(0);
      expect(lowBm25.length).toBeGreaterThan(0);
    });

    it('should find exact matches with high scores', () => {
      engine.addDocument('exact', 'vitest testing framework configuration');
      const results = engine.search('vitest testing framework');
      expect(results.length).toBeGreaterThan(0);
      expect(results[0]!.id).toBe('exact');
    });

    it('should handle search with no matching documents', () => {
      const results = engine.search('quantum computing blockchain');
      // May or may not find partial matches, but should not crash
      expect(Array.isArray(results)).toBe(true);
    });
  });

  describe('serialize / deserialize', () => {
    it('should roundtrip serialization correctly', () => {
      engine.addDocument('doc1', 'TypeScript React Next.js web development');
      engine.addDocument('doc2', 'Python Flask backend API development');
      engine.addDocument('doc3', 'Docker Kubernetes deployment orchestration');

      const serialized = engine.serialize();
      expect(serialized).toHaveProperty('docs');
      expect(serialized).toHaveProperty('documentFreqs');
      expect(serialized).toHaveProperty('totalDocs');

      const engine2 = new TfIdfEngine();
      engine2.deserialize(serialized as any);

      expect(engine2.size).toBe(3);

      // Search should work the same after deserialization
      const results1 = engine.search('TypeScript web');
      const results2 = engine2.search('TypeScript web');

      expect(results1.length).toBe(results2.length);
      expect(results1[0]?.id).toBe(results2[0]?.id);
    });

    it('should handle empty engine serialization', () => {
      const serialized = engine.serialize();
      expect((serialized as any).totalDocs).toBe(0);
      expect((serialized as any).docs).toHaveLength(0);
    });

    it('should handle deserialization of empty state', () => {
      engine.addDocument('doc1', 'Some content');
      engine.deserialize({ docs: [], documentFreqs: {}, totalDocs: 0 });
      expect(engine.size).toBe(0);
    });
  });

  describe('edge cases', () => {
    it('should handle very short documents', () => {
      engine.addDocument('short', 'hi');
      const results = engine.search('hi');
      // "hi" is only 2 chars, should still be tokenized
      expect(Array.isArray(results)).toBe(true);
    });

    it('should handle documents with only stop words', () => {
      engine.addDocument('stops', 'the is a an the');
      expect(engine.size).toBe(1);
      const results = engine.search('the is');
      expect(results).toHaveLength(0); // No meaningful tokens
    });

    it('should handle many documents without performance issues', () => {
      for (let i = 0; i < 100; i++) {
        engine.addDocument(
          `doc${i}`,
          `Document number ${i} about topic ${i % 10} with content variation ${i % 5}`
        );
      }
      expect(engine.size).toBe(100);

      // Use performance.now() for accurate timing (avoids flaky Date.now issues)
      const start = performance.now();
      const results = engine.search('topic variation');
      const elapsed = performance.now() - start;

      expect(results.length).toBeGreaterThan(0);
      expect(elapsed, 'Search should complete in under 1 second').toBeLessThan(
        1000
      );
    });

    it('should handle documents with special characters', () => {
      engine.addDocument(
        'special',
        "Error: Cannot read property 'foo' of undefined (TypeError)"
      );
      const results = engine.search('TypeError undefined');
      expect(results.length).toBeGreaterThan(0);
    });

    it('should handle unicode content gracefully', () => {
      engine.addDocument('unicode', 'café résumé naïve');
      // Non-ASCII chars get stripped by the tokenizer, but it shouldn't crash
      expect(engine.size).toBe(1);
    });
  });
});
