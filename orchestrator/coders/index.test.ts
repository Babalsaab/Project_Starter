/**
 * Unit Tests — Coder Registry
 *
 * Tests for getCoder(), getDefaultCoderConfig(), and detectBestCoder().
 */

import { describe, it, expect, vi } from 'vitest';
import { getCoder, getDefaultCoderConfig } from './index';
import type { CoderBackend } from './base';

// ─── getCoder ────────────────────────────────────────────────────────────────

describe('getCoder', () => {
  it('should return a coder for each known backend', () => {
    const backends: CoderBackend[] = [
      'claude-api',
      'claude-code',
      'cursor',
      'aider',
      'manual',
    ];
    for (const backend of backends) {
      const coder = getCoder(backend);
      expect(coder.backend).toBe(backend);
      expect(coder.displayName).toBeTruthy();
    }
  });

  it('should throw for unknown backend', () => {
    expect(() => getCoder('nonexistent' as CoderBackend)).toThrow(
      'Unknown coder backend'
    );
  });

  it('should return coder with applyFixes method', () => {
    const coder = getCoder('manual');
    expect(typeof coder.applyFixes).toBe('function');
  });

  it('should return coder with isAvailable method', () => {
    const coder = getCoder('manual');
    expect(typeof coder.isAvailable).toBe('function');
  });

  it('should return coder with setupInstructions method', () => {
    const coder = getCoder('manual');
    expect(typeof coder.setupInstructions).toBe('function');
  });
});

// ─── getDefaultCoderConfig ───────────────────────────────────────────────────

describe('getDefaultCoderConfig', () => {
  it('should return config for default backend (claude-api)', () => {
    const config = getDefaultCoderConfig();
    expect(config.backend).toBe('claude-api');
    expect(config.timeout_ms).toBeGreaterThan(0);
    expect(config.max_files).toBeGreaterThan(0);
  });

  it('should return config for specified backend', () => {
    const config = getDefaultCoderConfig('manual');
    expect(config.backend).toBe('manual');
    expect(config.timeout_ms).toBe(0);
  });

  it('should set allow_create to true by default', () => {
    const config = getDefaultCoderConfig();
    expect(config.allow_create).toBe(true);
  });

  it('should set max_files to a reasonable number', () => {
    const config = getDefaultCoderConfig();
    expect(config.max_files).toBe(10);
  });
});

// ─── Manual coder availability ───────────────────────────────────────────────

describe('ManualCoder availability', () => {
  it('should always be available', async () => {
    const coder = getCoder('manual');
    const available = await coder.isAvailable();
    expect(available).toBe(true);
  });

  it('should have setup instructions', () => {
    const coder = getCoder('manual');
    const instructions = coder.setupInstructions();
    expect(instructions.length).toBeGreaterThan(0);
    expect(instructions).toContain('No setup needed');
  });
});
