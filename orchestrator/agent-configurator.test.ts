/**
 * Unit Tests — Agent Configurator
 *
 * Tests for loadAgentFromPool(), createProjectSession(), printAgentSummary(),
 * and updateSessionStatus().
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import {
  loadAgentFromPool,
  createProjectSession,
  printAgentSummary,
  updateSessionStatus,
} from './agent-configurator';
import type { AgentSelection } from './prd-generator';

// ─── Helpers ─────────────────────────────────────────────────────────────────

const TEST_PROJECT_ID = '__test_config__';
const SESSION_DIR = path.join('./config/project-sessions', TEST_PROJECT_ID);

function cleanup(): void {
  if (fs.existsSync(SESSION_DIR)) {
    fs.rmSync(SESSION_DIR, { recursive: true, force: true });
  }
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('loadAgentFromPool', () => {
  it('should load a known tech agent', () => {
    const agent = loadAgentFromPool('qa_engineer');
    expect(agent).not.toBeNull();
    expect(agent!.id).toBe('qa_engineer');
    expect(agent!.title).toBeTruthy();
    expect(agent!.system_prompt).toBeTruthy();
  });

  it('should load a known marketing agent', () => {
    const agent = loadAgentFromPool('seo_specialist');
    expect(agent).not.toBeNull();
    expect(agent!.id).toBe('seo_specialist');
  });

  it('should return null for non-existent agent', () => {
    const agent = loadAgentFromPool('nonexistent_agent_xyz');
    expect(agent).toBeNull();
  });

  it('should include expected_inputs and expected_outputs', () => {
    const agent = loadAgentFromPool('backend_engineer');
    expect(agent).not.toBeNull();
    expect(Array.isArray(agent!.expected_inputs)).toBe(true);
    expect(Array.isArray(agent!.expected_outputs)).toBe(true);
  });

  it('should include token_cap', () => {
    const agent = loadAgentFromPool('product_manager');
    expect(agent).not.toBeNull();
    expect(typeof agent!.token_cap).toBe('number');
    expect(agent!.token_cap).toBeGreaterThan(0);
  });
});

describe('createProjectSession', () => {
  beforeEach(() => cleanup());
  afterEach(() => cleanup());

  const agents: AgentSelection[] = [
    { id: 'product_manager', domain: 'tech/product', reason: 'Spec needed' },
    { id: 'backend_engineer', domain: 'tech/backend', reason: 'API work' },
  ];

  it('should create session directory', () => {
    createProjectSession(
      TEST_PROJECT_ID,
      'Test Project',
      agents,
      './runs/prds/test-prd.md'
    );
    expect(fs.existsSync(SESSION_DIR)).toBe(true);
  });

  it('should write session.yaml', () => {
    createProjectSession(
      TEST_PROJECT_ID,
      'Test Project',
      agents,
      './runs/prds/test-prd.md'
    );
    expect(fs.existsSync(path.join(SESSION_DIR, 'session.yaml'))).toBe(true);
  });

  it('should write agent-selection.yaml', () => {
    createProjectSession(
      TEST_PROJECT_ID,
      'Test Project',
      agents,
      './runs/prds/test-prd.md'
    );
    expect(fs.existsSync(path.join(SESSION_DIR, 'agent-selection.yaml'))).toBe(
      true
    );
  });

  it('should include chiefs in active_agents', () => {
    const session = createProjectSession(
      TEST_PROJECT_ID,
      'Test Project',
      agents,
      './runs/prds/test-prd.md'
    );
    expect(session.active_agents).toContain('CEO');
    expect(session.active_agents).toContain('CTO');
  });

  it('should include specialist agents in active_agents', () => {
    const session = createProjectSession(
      TEST_PROJECT_ID,
      'Test Project',
      agents,
      './runs/prds/test-prd.md'
    );
    expect(session.active_agents).toContain('product_manager');
    expect(session.active_agents).toContain('backend_engineer');
  });

  it('should set initial status to initialising', () => {
    const session = createProjectSession(
      TEST_PROJECT_ID,
      'Test Project',
      agents,
      './runs/prds/test-prd.md'
    );
    expect(session.status).toBe('initialising');
  });

  it('should handle agents not found in pool gracefully', () => {
    const agentsWithMissing: AgentSelection[] = [
      { id: 'nonexistent_agent', domain: 'tech/misc', reason: 'Testing' },
    ];
    const session = createProjectSession(
      TEST_PROJECT_ID,
      'Test Project',
      agentsWithMissing,
      './runs/prds/test-prd.md'
    );
    expect(session.active_agents).toContain('nonexistent_agent');
    expect(session.agent_configs['nonexistent_agent']?.title).toContain(
      'PLACEHOLDER'
    );
  });
});

describe('printAgentSummary', () => {
  it('should format a readable agent summary', () => {
    const agents: AgentSelection[] = [
      { id: 'backend_engineer', domain: 'tech/backend', reason: 'API work' },
      {
        id: 'seo_specialist',
        domain: 'marketing/seo',
        reason: 'SEO optimization',
      },
    ];

    cleanup();
    const session = createProjectSession(
      TEST_PROJECT_ID,
      'Test Project',
      agents,
      './runs/prds/test-prd.md'
    );
    const summary = printAgentSummary(session, agents);

    expect(summary).toContain('AGENT CONFIGURATION');
    expect(summary).toContain('Test Project');
    expect(summary).toContain('TECH SPECIALISTS');
    expect(summary).toContain('MARKETING SPECIALISTS');
    expect(summary).toContain('backend_engineer');
    expect(summary).toContain('seo_specialist');

    cleanup();
  });

  it("should show '(none)' when no tech agents selected", () => {
    const agents: AgentSelection[] = [
      {
        id: 'seo_specialist',
        domain: 'marketing/seo',
        reason: 'SEO optimization',
      },
    ];

    cleanup();
    const session = createProjectSession(
      TEST_PROJECT_ID,
      'Test Project',
      agents,
      './runs/prds/test-prd.md'
    );
    const summary = printAgentSummary(session, []);

    expect(summary).toContain('(none');

    cleanup();
  });
});

describe('updateSessionStatus', () => {
  beforeEach(() => cleanup());
  afterEach(() => cleanup());

  it('should update session status on disk', () => {
    const agents: AgentSelection[] = [
      { id: 'product_manager', domain: 'tech/product', reason: 'test' },
    ];
    createProjectSession(
      TEST_PROJECT_ID,
      'Test Project',
      agents,
      './runs/prds/test-prd.md'
    );

    updateSessionStatus(TEST_PROJECT_ID, 'complete');

    // Read back
    const yaml = require('js-yaml');
    const sessionPath = path.join(SESSION_DIR, 'session.yaml');
    const loaded = yaml.load(fs.readFileSync(sessionPath, 'utf-8'));
    expect(loaded.status).toBe('complete');
  });

  it('should do nothing for non-existent session', () => {
    // Should not throw
    updateSessionStatus('nonexistent_session_xyz_' + Date.now(), 'running');
  });
});
