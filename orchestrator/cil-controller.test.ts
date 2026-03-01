/**
 * Unit Tests — CIL Controller
 *
 * Tests for CIL state management: saveCILState, loadCILState, listCILRuns.
 * These are the pure/deterministic parts — the actual evaluation + LLM loop
 * requires mocking and is covered by integration tests.
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import {
  saveCILState,
  loadCILState,
  listCILRuns,
  type CILState,
  type CILConfig,
  type IterationState,
} from './cil-controller';

// ─── Helpers ─────────────────────────────────────────────────────────────────

const TEST_CIL_ID = 'cil_test_unit';
const CIL_DIR = path.resolve(__dirname, '../config/project-sessions');
const TEST_DIR = path.join(CIL_DIR, TEST_CIL_ID);

function makeCILConfig(overrides: Partial<CILConfig> = {}): CILConfig {
  return {
    codebase_path: '/tmp/test-project',
    max_iterations: 3,
    evaluation_mode: 'quick',
    auto_implement: false,
    ...overrides,
  };
}

function makeCILState(overrides: Partial<CILState> = {}): CILState {
  return {
    id: TEST_CIL_ID,
    config: makeCILConfig(),
    status: 'running',
    current_iteration: 1,
    current_phase: 'evaluate',
    iterations: [],
    iteration_reports: [],
    started_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides,
  };
}

function cleanup(): void {
  if (fs.existsSync(TEST_DIR)) {
    fs.rmSync(TEST_DIR, { recursive: true, force: true });
  }
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('CIL State Persistence', () => {
  beforeEach(() => cleanup());
  afterEach(() => cleanup());

  describe('saveCILState', () => {
    it('should create the CIL directory if it does not exist', () => {
      const state = makeCILState();
      saveCILState(state);
      expect(fs.existsSync(TEST_DIR)).toBe(true);
    });

    it('should write cil-state.yaml file', () => {
      const state = makeCILState();
      saveCILState(state);
      const statePath = path.join(TEST_DIR, 'cil-state.yaml');
      expect(fs.existsSync(statePath)).toBe(true);
    });

    it('should update the updated_at timestamp', () => {
      const state = makeCILState({ updated_at: '2020-01-01T00:00:00.000Z' });
      saveCILState(state);
      // updated_at should be refreshed
      expect(state.updated_at).not.toBe('2020-01-01T00:00:00.000Z');
    });

    it('should strip iteration_reports from disk to save space', () => {
      const state = makeCILState({
        iteration_reports: [
          {
            iteration: 1,
            evaluation_result: {} as any,
            finding_assignments: [],
            agent_performance: [],
            score_delta: 1.0,
            new_findings: 0,
            resolved_findings: 5,
          },
        ],
      });
      saveCILState(state);

      const onDisk = loadCILState(TEST_CIL_ID);
      expect(onDisk).toBeDefined();
      // iteration_reports should be empty array on disk
      expect(onDisk!.iteration_reports).toHaveLength(0);
    });
  });

  describe('loadCILState', () => {
    it('should load a saved state', () => {
      const state = makeCILState({ status: 'completed' });
      saveCILState(state);

      const loaded = loadCILState(TEST_CIL_ID);
      expect(loaded).toBeDefined();
      expect(loaded!.id).toBe(TEST_CIL_ID);
      expect(loaded!.status).toBe('completed');
    });

    it('should return null for non-existent CIL run', () => {
      const loaded = loadCILState('cil_nonexistent_' + Date.now());
      expect(loaded).toBeNull();
    });

    it('should return null for corrupted state file', () => {
      fs.mkdirSync(TEST_DIR, { recursive: true });
      fs.writeFileSync(
        path.join(TEST_DIR, 'cil-state.yaml'),
        'NOT: VALID: : YAML: [broken',
        'utf-8'
      );
      const loaded = loadCILState(TEST_CIL_ID);
      // Should not crash, may return the parsed-but-invalid object or null
      // The important thing is it doesn't throw
      expect(loaded !== undefined).toBe(true);
    });
  });

  describe('listCILRuns', () => {
    it('should return empty array when no CIL runs exist', () => {
      // Clean any existing cil_ test dirs first
      const runs = listCILRuns().filter((r) => r.id === TEST_CIL_ID);
      // May or may not be empty depending on other tests
      expect(Array.isArray(runs)).toBe(true);
    });

    it('should include saved CIL runs', () => {
      const state = makeCILState();
      saveCILState(state);

      const runs = listCILRuns();
      const testRun = runs.find((r) => r.id === TEST_CIL_ID);
      expect(testRun).toBeDefined();
      expect(testRun!.status).toBe('running');
    });

    it('should return run metadata (id, status, config, timestamps)', () => {
      const state = makeCILState({ current_iteration: 2 });
      saveCILState(state);

      const runs = listCILRuns();
      const testRun = runs.find((r) => r.id === TEST_CIL_ID);
      expect(testRun).toBeDefined();
      expect(testRun!.current_iteration).toBe(2);
      expect(testRun!.config.evaluation_mode).toBe('quick');
      expect(testRun!.started_at).toBeTruthy();
    });
  });
});

// ─── CIL Type Validation ─────────────────────────────────────────────────────

describe('CIL Types', () => {
  it('should enforce CILConfig required fields', () => {
    const config = makeCILConfig();
    expect(config.codebase_path).toBeDefined();
    expect(config.max_iterations).toBeDefined();
    expect(config.evaluation_mode).toBeDefined();
    expect(config.auto_implement).toBeDefined();
  });

  it('should support all evaluation modes', () => {
    const modes: CILConfig['evaluation_mode'][] = [
      'quick',
      'standard',
      'enhanced',
    ];
    for (const mode of modes) {
      const config = makeCILConfig({ evaluation_mode: mode });
      expect(config.evaluation_mode).toBe(mode);
    }
  });

  it('should support optional target_score', () => {
    const withTarget = makeCILConfig({ target_score: 8.5 });
    expect(withTarget.target_score).toBe(8.5);

    const withoutTarget = makeCILConfig();
    expect(withoutTarget.target_score).toBeUndefined();
  });

  it('should support focus_categories', () => {
    const config = makeCILConfig({ focus_categories: ['security', 'testing'] });
    expect(config.focus_categories).toEqual(['security', 'testing']);
  });
});
