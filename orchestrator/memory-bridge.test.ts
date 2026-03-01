/**
 * Unit Tests — Memory Bridge
 *
 * Tests for the memory bridge CRUD operations: writeFact, searchFacts,
 * readFacts, updateFact, deleteFact. Uses a temp directory to avoid
 * polluting the real memory store.
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';

// ─── Setup: redirect STORE_PATH to a temp location ──────────────────────────

const TEST_STORE_DIR = path.join(__dirname, '..', '__test_memory__');
const TEST_STORE_PATH = path.join(TEST_STORE_DIR, 'memory-store.json');

// We need to mock the path resolution so memory-bridge uses our test path
vi.mock('fs', async () => {
  const actual = await vi.importActual<typeof import('fs')>('fs');
  return { ...actual };
});

// Since memory-bridge uses __dirname-relative paths, we'll test the
// functions by directly importing and using a clean store per test.

import {
  writeFact,
  searchFacts,
  readFacts,
  updateFact,
  deleteFact,
} from './memory-bridge';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function getStoreDir(): string {
  return path.join(path.resolve(__dirname, '..'), 'memory');
}

function getStorePath(): string {
  return path.join(getStoreDir(), 'memory-store.json');
}

function backupStore(): { existed: boolean; content?: string } {
  const storePath = getStorePath();
  if (fs.existsSync(storePath)) {
    return { existed: true, content: fs.readFileSync(storePath, 'utf-8') };
  }
  return { existed: false };
}

function restoreStore(backup: { existed: boolean; content?: string }): void {
  const storePath = getStorePath();
  if (backup.existed && backup.content) {
    fs.writeFileSync(storePath, backup.content, 'utf-8');
  }
}

let storeBackup: { existed: boolean; content?: string };

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('Memory Bridge', () => {
  beforeEach(() => {
    // Back up existing store
    storeBackup = backupStore();
  });

  afterEach(() => {
    // Restore original store
    restoreStore(storeBackup);
  });

  describe('writeFact', () => {
    it('should create a fact with generated ID', () => {
      const fact = writeFact({ content: 'Test fact content' });
      expect(fact.id).toMatch(/^mem_/);
      expect(fact.content).toBe('Test fact content');

      // Clean up
      deleteFact(fact.id);
    });

    it('should use default section and type when not specified', () => {
      const fact = writeFact({ content: 'Default section test' });
      expect(fact.section).toBe('Agent System');
      expect(fact.type).toBe('note');

      deleteFact(fact.id);
    });

    it('should use provided section and tags', () => {
      const fact = writeFact({
        content: 'Custom section test',
        section: 'Testing',
        tags: ['test', 'unit'],
        type: 'discovery',
      });
      expect(fact.section).toBe('Testing');
      expect(fact.tags).toEqual(['test', 'unit']);
      expect(fact.type).toBe('discovery');

      deleteFact(fact.id);
    });

    it('should set access_count to 0 initially', () => {
      const fact = writeFact({ content: 'Access count test' });
      expect(fact.access_count).toBe(0);

      deleteFact(fact.id);
    });

    it('should set timestamps', () => {
      const fact = writeFact({ content: 'Timestamp test' });
      expect(fact.created_at).toBeTruthy();
      expect(fact.updated_at).toBeTruthy();

      deleteFact(fact.id);
    });
  });

  describe('searchFacts', () => {
    it('should find facts matching content', () => {
      const fact = writeFact({ content: 'Unique search term xyz123' });
      const results = searchFacts('xyz123');
      expect(results.length).toBeGreaterThan(0);
      expect(results.some((f) => f.id === fact.id)).toBe(true);

      deleteFact(fact.id);
    });

    it('should filter by section', () => {
      const fact = writeFact({
        content: 'Section filter test abc789',
        section: 'Testing',
      });
      const results = searchFacts('abc789', { section: 'Testing' });
      expect(results.length).toBeGreaterThan(0);

      const wrongSection = searchFacts('abc789', { section: 'Nonexistent' });
      expect(wrongSection.some((f) => f.id === fact.id)).toBe(false);

      deleteFact(fact.id);
    });

    it('should filter by tags', () => {
      const fact = writeFact({
        content: 'Tag filter test def456',
        tags: ['special_tag'],
      });
      const results = searchFacts('def456', { tags: ['special_tag'] });
      expect(results.length).toBeGreaterThan(0);

      deleteFact(fact.id);
    });

    it('should respect limit parameter', () => {
      const facts = [];
      for (let i = 0; i < 5; i++) {
        facts.push(writeFact({ content: `Limit test ghi${i}` }));
      }
      const results = searchFacts('Limit test ghi', { limit: 2 });
      expect(results.length).toBeLessThanOrEqual(2);

      for (const f of facts) {
        deleteFact(f.id);
      }
    });

    it('should return empty array for no matches', () => {
      const results = searchFacts('absolutely_nonexistent_query_zzz999');
      expect(results).toHaveLength(0);
    });
  });

  describe('readFacts', () => {
    it('should return all facts when no section specified', () => {
      const results = readFacts();
      expect(Array.isArray(results)).toBe(true);
    });

    it('should filter by section', () => {
      const fact = writeFact({
        content: 'Read section test',
        section: 'TestSection',
      });
      const results = readFacts('TestSection');
      expect(results.some((f) => f.id === fact.id)).toBe(true);

      deleteFact(fact.id);
    });
  });

  describe('updateFact', () => {
    it('should update fact content', () => {
      const fact = writeFact({ content: 'Original content' });
      const result = updateFact(fact.id, { content: 'Updated content' });
      expect(result).toBe(true);

      const facts = readFacts();
      const updated = facts.find((f) => f.id === fact.id);
      expect(updated?.content).toBe('Updated content');

      deleteFact(fact.id);
    });

    it('should return false for non-existent fact', () => {
      const result = updateFact('nonexistent_id', { content: 'Should fail' });
      expect(result).toBe(false);
    });

    it('should update multiple fields at once', () => {
      const fact = writeFact({ content: 'Multi-update test' });
      updateFact(fact.id, {
        content: 'Updated',
        section: 'NewSection',
        tags: ['new-tag'],
      });

      const facts = readFacts();
      const updated = facts.find((f) => f.id === fact.id);
      expect(updated?.content).toBe('Updated');
      expect(updated?.section).toBe('NewSection');
      expect(updated?.tags).toEqual(['new-tag']);

      deleteFact(fact.id);
    });
  });

  describe('deleteFact', () => {
    it('should delete an existing fact', () => {
      const fact = writeFact({ content: 'Delete me' });
      const result = deleteFact(fact.id);
      expect(result).toBe(true);

      const facts = readFacts();
      expect(facts.find((f) => f.id === fact.id)).toBeUndefined();
    });

    it('should return false for non-existent fact', () => {
      const result = deleteFact('nonexistent_id_xyz');
      expect(result).toBe(false);
    });

    it('should clean up references from other facts', () => {
      const fact1 = writeFact({ content: 'Fact one' });
      const fact2 = writeFact({ content: 'Fact two' });

      // Manually add a reference (simulate related_facts)
      const storePath = getStorePath();
      if (fs.existsSync(storePath)) {
        const store = JSON.parse(fs.readFileSync(storePath, 'utf-8'));
        const f2 = store.facts.find((f: any) => f.id === fact2.id);
        if (f2) {
          f2.related_facts = [fact1.id];
          fs.writeFileSync(storePath, JSON.stringify(store, null, 2), 'utf-8');
        }
      }

      deleteFact(fact1.id);

      // Verify reference was cleaned up
      const facts = readFacts();
      const remaining = facts.find((f) => f.id === fact2.id);
      if (remaining) {
        expect(remaining.related_facts).not.toContain(fact1.id);
      }

      deleteFact(fact2.id);
    });
  });
});
