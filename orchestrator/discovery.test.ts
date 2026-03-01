/**
 * Unit Tests — Discovery Agent
 *
 * Tests for DiscoveryAgent: question flow, answer storage, summary generation.
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { DiscoveryAgent } from './discovery';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function makeAnswers(): Record<string, string> {
  return {
    project_name: 'TestApp',
    project_type: 'web app',
    primary_goal: 'Get 1000 signups',
    audience: 'Developers aged 25-40',
    geography: 'Global',
    channels: 'web, email, social',
    features: 'login, dashboard, settings',
    design_style: 'minimal like Linear',
    tech_preference: 'Next.js + Supabase',
    timeline: '1 month',
    budget_range: 'bootstrapped',
    existing_brand: 'Starting from scratch',
  };
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('DiscoveryAgent', () => {
  let agent: DiscoveryAgent;

  beforeEach(() => {
    agent = new DiscoveryAgent('test-project-123');
  });

  describe('greet', () => {
    it('should return a welcome message with first question', () => {
      const greeting = agent.greet();
      expect(greeting).toContain('Welcome');
      expect(greeting).toContain('Q1/');
      expect(greeting).toContain('name of your project');
    });

    it('should mention the total number of questions', () => {
      const greeting = agent.greet();
      expect(greeting).toMatch(/Q1\/\d+/);
    });
  });

  describe('respond', () => {
    it('should advance to the next question after receiving input', () => {
      const response = agent.respond('TestApp');
      expect(response.type).toBe('question');
      expect(response.message).toContain('Q2/');
    });

    it('should store answers and complete after all questions', () => {
      const answers = makeAnswers();
      const keys = Object.keys(answers);
      let lastResponse;

      for (let i = 0; i < keys.length; i++) {
        lastResponse = agent.respond(answers[keys[i]!]!);
      }

      expect(lastResponse!.type).toBe('complete');
      expect(lastResponse!.message).toContain('complete');
      expect(lastResponse!.nextAction).toBe('generate_prd');
    });

    it('should parse comma-separated channels into an array', () => {
      const answers = makeAnswers();
      const keys = Object.keys(answers);

      for (const key of keys) {
        agent.respond(answers[key]!);
      }

      const result = agent.getAnswers();
      expect(Array.isArray(result.channels)).toBe(true);
      expect(result.channels.length).toBeGreaterThan(0);
    });

    it('should trim whitespace from answers', () => {
      agent.respond('  TestApp  ');
      const result = agent.getAnswers();
      expect(result.project_name).toBe('TestApp');
    });
  });

  describe('getAnswers', () => {
    it('should return partial answers before completion', () => {
      agent.respond('MyProject');
      const answers = agent.getAnswers();
      expect(answers.project_name).toBe('MyProject');
    });

    it('should return all answers after completion', () => {
      const input = makeAnswers();
      const keys = Object.keys(input);
      for (const key of keys) {
        agent.respond(input[key]!);
      }
      const answers = agent.getAnswers();
      expect(answers.project_name).toBe('TestApp');
      expect(answers.project_type).toBe('web app');
      expect(answers.timeline).toBe('1 month');
    });
  });

  describe('getSummary', () => {
    it('should return a formatted summary of answers', () => {
      agent.respond('TestApp');
      agent.respond('web app');
      const summary = agent.getSummary();
      expect(summary).toContain('project_name');
      expect(summary).toContain('TestApp');
      expect(summary).toContain('project_type');
      expect(summary).toContain('web app');
    });

    it('should format array values as comma-separated', () => {
      const input = makeAnswers();
      const keys = Object.keys(input);
      for (const key of keys) {
        agent.respond(input[key]!);
      }
      const summary = agent.getSummary();
      expect(summary).toContain('channels');
    });

    it('should return empty string when no answers given', () => {
      const summary = agent.getSummary();
      expect(summary).toBe('');
    });
  });
});
