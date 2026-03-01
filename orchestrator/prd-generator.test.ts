/**
 * Unit Tests — PRD Generator
 *
 * Tests for buildPRDTemplate(), selectAgents(), and savePRD().
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import { buildPRDTemplate, selectAgents, savePRD } from './prd-generator';
import type { DiscoveryAnswers } from './discovery';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function makeDiscoveryAnswers(
  overrides: Partial<DiscoveryAnswers> = {}
): DiscoveryAnswers {
  return {
    project_name: 'TestApp',
    project_type: 'web app',
    primary_goal: 'Get 1000 signups in the first month',
    audience: 'Developers aged 25-40',
    geography: 'Global',
    channels: ['web', 'email'],
    features: 'login, dashboard, settings, notifications',
    design_style: 'minimal like Linear',
    tech_preference: 'Next.js + Supabase',
    timeline: '1 month',
    budget_range: 'bootstrapped',
    existing_brand: 'Starting from scratch',
    ...overrides,
  };
}

const TEST_OUTPUT_DIR = path.join('./runs/prds/__test__');

function cleanupTestDir(): void {
  if (fs.existsSync(TEST_OUTPUT_DIR)) {
    fs.rmSync(TEST_OUTPUT_DIR, { recursive: true, force: true });
  }
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('buildPRDTemplate', () => {
  it('should generate a valid markdown PRD', () => {
    const answers = makeDiscoveryAnswers();
    const prd = buildPRDTemplate(answers, 'test-project-001');

    expect(prd).toContain('# Master PRD: TestApp');
    expect(prd).toContain('test-project-001');
    expect(prd).toContain('web app');
    expect(prd).toContain('Get 1000 signups');
  });

  it('should include all discovery answers in the PRD', () => {
    const answers = makeDiscoveryAnswers();
    const prd = buildPRDTemplate(answers, 'proj-1');

    expect(prd).toContain(answers.audience);
    expect(prd).toContain(answers.geography);
    expect(prd).toContain(answers.design_style);
    expect(prd).toContain(answers.tech_preference);
    expect(prd).toContain(answers.timeline);
    expect(prd).toContain(answers.budget_range);
  });

  it('should include channels as bullet list', () => {
    const answers = makeDiscoveryAnswers({ channels: ['web', 'iOS', 'email'] });
    const prd = buildPRDTemplate(answers, 'proj-2');

    expect(prd).toContain('- web');
    expect(prd).toContain('- iOS');
    expect(prd).toContain('- email');
  });

  it('should handle empty channels gracefully', () => {
    const answers = makeDiscoveryAnswers({ channels: [] });
    const prd = buildPRDTemplate(answers, 'proj-3');

    expect(prd).toContain('To be determined');
  });

  it('should include a generated date', () => {
    const answers = makeDiscoveryAnswers();
    const prd = buildPRDTemplate(answers, 'proj-4');
    const today = new Date().toISOString().split('T')[0];
    expect(prd).toContain(today!);
  });
});

describe('selectAgents', () => {
  it('should always include product_manager', () => {
    const answers = makeDiscoveryAnswers();
    const agents = selectAgents(answers);
    expect(agents.some((a) => a.id === 'product_manager')).toBe(true);
  });

  it('should include web frontend agents for web app type', () => {
    const answers = makeDiscoveryAnswers({
      project_type: 'web app',
      channels: ['web'],
    });
    const agents = selectAgents(answers);
    expect(agents.some((a) => a.id === 'web_frontend_engineer')).toBe(true);
    expect(agents.some((a) => a.id === 'ux_designer')).toBe(true);
    expect(agents.some((a) => a.id === 'ui_designer')).toBe(true);
  });

  it('should include backend agents for SaaS projects', () => {
    const answers = makeDiscoveryAnswers({ project_type: 'saas' });
    const agents = selectAgents(answers);
    expect(agents.some((a) => a.id === 'backend_engineer')).toBe(true);
    expect(agents.some((a) => a.id === 'database_engineer')).toBe(true);
    expect(agents.some((a) => a.id === 'security_engineer')).toBe(true);
  });

  it('should include iOS engineer when iOS channel is specified', () => {
    const answers = makeDiscoveryAnswers({ channels: ['ios'] });
    const agents = selectAgents(answers);
    expect(agents.some((a) => a.id === 'ios_engineer')).toBe(true);
  });

  it('should include Android engineer when Android channel is specified', () => {
    const answers = makeDiscoveryAnswers({ channels: ['android'] });
    const agents = selectAgents(answers);
    expect(agents.some((a) => a.id === 'android_engineer')).toBe(true);
  });

  it('should include email marketing agents when email channel is specified', () => {
    const answers = makeDiscoveryAnswers({ channels: ['email'] });
    const agents = selectAgents(answers);
    expect(agents.some((a) => a.id === 'email_strategist')).toBe(true);
    expect(agents.some((a) => a.id === 'email_copywriter')).toBe(true);
  });

  it('should include social media agents when social channel is specified', () => {
    const answers = makeDiscoveryAnswers({ channels: ['social'] });
    const agents = selectAgents(answers);
    expect(agents.some((a) => a.id === 'social_media_marketer')).toBe(true);
  });

  it('should include SEO agents when goal mentions organic', () => {
    const answers = makeDiscoveryAnswers({
      primary_goal: 'grow organic traffic',
    });
    const agents = selectAgents(answers);
    expect(agents.some((a) => a.id === 'seo_specialist')).toBe(true);
  });

  it('should include growth agents when goal mentions launch', () => {
    const answers = makeDiscoveryAnswers({
      primary_goal: 'launch and get signups',
    });
    const agents = selectAgents(answers);
    expect(agents.some((a) => a.id === 'marketing_strategist')).toBe(true);
    expect(agents.some((a) => a.id === 'growth_marketer')).toBe(true);
  });

  it('should include QA agents for product builds', () => {
    const answers = makeDiscoveryAnswers({ project_type: 'web app' });
    const agents = selectAgents(answers);
    expect(agents.some((a) => a.id === 'qa_engineer')).toBe(true);
  });

  it('should not duplicate agents', () => {
    const answers = makeDiscoveryAnswers({
      project_type: 'web app',
      channels: ['web', 'email', 'social', 'paid ads'],
      primary_goal: 'launch and get organic signups',
    });
    const agents = selectAgents(answers);
    const ids = agents.map((a) => a.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('should include 3D agents when design style mentions 3D', () => {
    const answers = makeDiscoveryAnswers({
      design_style: '3D immersive experience',
    });
    const agents = selectAgents(answers);
    expect(agents.some((a) => a.id === '3d_designer')).toBe(true);
  });
});

describe('savePRD', () => {
  beforeEach(() => cleanupTestDir());
  afterEach(() => cleanupTestDir());

  it('should write PRD file to disk', () => {
    const filepath = savePRD(
      'test-prd-001',
      '# Test PRD Content',
      TEST_OUTPUT_DIR
    );
    expect(fs.existsSync(filepath)).toBe(true);
    const content = fs.readFileSync(filepath, 'utf-8');
    expect(content).toBe('# Test PRD Content');
  });

  it('should return correct file path', () => {
    const filepath = savePRD('my-project', 'content', TEST_OUTPUT_DIR);
    expect(filepath).toContain('my-project-prd.md');
  });

  it('should create output directory if it does not exist', () => {
    const nested = path.join(TEST_OUTPUT_DIR, 'deep', 'nested');
    savePRD('deep-proj', 'content', nested);
    expect(fs.existsSync(nested)).toBe(true);
  });
});
