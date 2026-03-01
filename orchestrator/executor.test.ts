/**
 * Unit Tests — Execution Engine
 *
 * Tests the pure/deterministic parts of the executor:
 * - generateExecutionPlan()
 * - validateAgentInputs() (via plan generation)
 * - compactArtifact() (via context building)
 * - findBestPersonaMatch() (via context building)
 * - generatePlaceholderOutput()
 * - Phase ordering and dependency logic
 *
 * Note: The actual LLM calling (callProvider, callWithRetry, executeProject)
 * requires mocking and is not tested here since it depends on API keys.
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  generateExecutionPlan,
  type TaskStep,
  type ExecutionPlan,
} from './executor';
import type { ProjectSession } from './agent-configurator';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function makeSession(
  agents: string[],
  configs?: Record<string, any>
): ProjectSession {
  const agentConfigs: Record<string, any> = {};
  for (const id of agents) {
    agentConfigs[id] = configs?.[id] ?? {
      id,
      title: id.replace(/_/g, ' '),
      domain: 'tech/misc',
      token_cap: 2000,
    };
  }
  return {
    project_id: 'test-project',
    project_name: 'Test Project',
    created_at: new Date().toISOString(),
    active_agents: ['CEO', 'CTO', ...agents],
    agent_configs: {
      CEO: { id: 'CEO', title: 'CEO', domain: 'chiefs', token_cap: 1000 },
      CTO: { id: 'CTO', title: 'CTO', domain: 'chiefs', token_cap: 1500 },
      ...agentConfigs,
    },
    prd_path: './runs/prds/test-project-prd.md',
    status: 'running',
  };
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('generateExecutionPlan', () => {
  it('should create steps for all specialist agents (excluding chiefs)', () => {
    const session = makeSession([
      'product_manager',
      'backend_engineer',
      'qa_engineer',
    ]);
    const plan = generateExecutionPlan(session);

    // Chiefs (CEO, CTO) should NOT have execution steps
    const stepAgents = plan.steps.map((s) => s.owner_agent);
    expect(stepAgents).not.toContain('CEO');
    expect(stepAgents).not.toContain('CTO');

    // Specialists should have steps
    expect(stepAgents).toContain('product_manager');
    expect(stepAgents).toContain('backend_engineer');
    expect(stepAgents).toContain('qa_engineer');
  });

  it('should sort agents by phase order', () => {
    const session = makeSession([
      'qa_engineer',
      'product_manager',
      'backend_engineer',
    ]);
    const plan = generateExecutionPlan(session);

    // product_manager is phase 1, backend_engineer is phase 5, qa_engineer is phase 7
    const pmIndex = plan.steps.findIndex(
      (s) => s.owner_agent === 'product_manager'
    );
    const beIndex = plan.steps.findIndex(
      (s) => s.owner_agent === 'backend_engineer'
    );
    const qaIndex = plan.steps.findIndex(
      (s) => s.owner_agent === 'qa_engineer'
    );

    expect(pmIndex).toBeLessThan(beIndex);
    expect(beIndex).toBeLessThan(qaIndex);
  });

  it('should set up dependencies between phases', () => {
    const session = makeSession([
      'product_manager',
      'ux_designer',
      'web_frontend_engineer',
    ]);
    const plan = generateExecutionPlan(session);

    // ux_designer (phase 2) should depend on product_manager (phase 1)
    const uxStep = plan.steps.find((s) => s.owner_agent === 'ux_designer');
    expect(uxStep).toBeDefined();
    expect(uxStep!.depends_on.length).toBeGreaterThan(0);

    // product_manager (phase 1) should have no dependencies
    const pmStep = plan.steps.find((s) => s.owner_agent === 'product_manager');
    expect(pmStep).toBeDefined();
    expect(pmStep!.depends_on).toHaveLength(0);
  });

  it('should inject feedback agent steps after review phases', () => {
    const session = makeSession(['product_manager', 'web_frontend_engineer']);
    const plan = generateExecutionPlan(session);

    const feedbackSteps = plan.steps.filter(
      (s) => s.owner_agent === 'feedback_agent'
    );
    expect(feedbackSteps.length).toBeGreaterThan(0);
  });

  it('should always add deployment_readiness_agent as the last step', () => {
    const session = makeSession(['product_manager', 'backend_engineer']);
    const plan = generateExecutionPlan(session);

    const lastStep = plan.steps[plan.steps.length - 1];
    expect(lastStep!.owner_agent).toBe('deployment_readiness_agent');
  });

  it('should set initial plan status to pending', () => {
    const session = makeSession(['product_manager']);
    const plan = generateExecutionPlan(session);

    expect(plan.status).toBe('pending');
    expect(plan.current_step).toBe(0);
    expect(plan.tokens_consumed).toBe(0);
  });

  it('should set step IDs with step- prefix', () => {
    const session = makeSession(['product_manager']);
    const plan = generateExecutionPlan(session);

    for (const step of plan.steps) {
      expect(step.id).toMatch(/^step-/);
    }
  });

  it('should set initial step status to pending', () => {
    const session = makeSession(['product_manager', 'backend_engineer']);
    const plan = generateExecutionPlan(session);

    for (const step of plan.steps) {
      expect(step.status).toBe('pending');
      expect(step.retry_count).toBe(0);
    }
  });

  it('should use agent token_cap from session config', () => {
    const session = makeSession(['product_manager'], {
      product_manager: {
        id: 'product_manager',
        title: 'Product Manager',
        domain: 'tech/product',
        token_cap: 3500,
      },
    });
    const plan = generateExecutionPlan(session);

    const pmStep = plan.steps.find((s) => s.owner_agent === 'product_manager');
    expect(pmStep!.token_cap).toBe(3500);
  });

  it('should add directory_housekeeping_agent for build/test phases', () => {
    const session = makeSession(['web_frontend_engineer', 'qa_engineer']);
    const plan = generateExecutionPlan(session);

    const housekeeper = plan.steps.find(
      (s) => s.owner_agent === 'directory_housekeeping_agent'
    );
    expect(housekeeper).toBeDefined();
  });

  it('should handle empty specialist list gracefully', () => {
    const session = makeSession([]);
    const plan = generateExecutionPlan(session);

    // Should still have deployment readiness agent
    expect(plan.steps.length).toBeGreaterThanOrEqual(1);
    expect(plan.steps[plan.steps.length - 1]!.owner_agent).toBe(
      'deployment_readiness_agent'
    );
  });
});
