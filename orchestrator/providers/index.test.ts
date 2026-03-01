/**
 * Unit Tests — Provider Registry
 *
 * Tests for ProviderRegistry initialization, provider creation,
 * and agent routing.
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { ProviderRegistry } from './index';
import * as path from 'path';

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('ProviderRegistry', () => {
  let registry: ProviderRegistry;

  beforeEach(() => {
    registry = new ProviderRegistry();
  });

  describe('initialize', () => {
    it('should initialize with default providers when no config exists', async () => {
      await registry.initialize('/nonexistent/path/globals.yaml');
      // Should fall back to defaults (anthropic)
      const provider = registry.getDefaultProvider();
      expect(provider).toBeDefined();
      expect(provider.config.type).toBe('anthropic');
    });

    it('should load providers from globals.yaml if available', async () => {
      const globalsPath = path.resolve('config/globals.yaml');
      await registry.initialize(globalsPath);
      const provider = registry.getDefaultProvider();
      expect(provider).toBeDefined();
    });
  });

  describe('getDefaultProvider', () => {
    it('should return a provider after initialization', async () => {
      await registry.initialize('/nonexistent/path.yaml');
      const provider = registry.getDefaultProvider();
      expect(provider).toBeDefined();
      expect(typeof provider.complete).toBe('function');
      expect(typeof provider.healthCheck).toBe('function');
      expect(typeof provider.getCapabilities).toBe('function');
    });
  });

  describe('getProviderForAgent', () => {
    it('should return default provider for unknown agents', async () => {
      await registry.initialize('/nonexistent/path.yaml');
      const provider = registry.getProviderForAgent('unknown_agent');
      expect(provider).toBeDefined();
      expect(provider.config.type).toBe('anthropic');
    });
  });

  describe('completeWithRetry', () => {
    it('should be a function on the registry', async () => {
      await registry.initialize('/nonexistent/path.yaml');
      expect(typeof registry.completeWithRetry).toBe('function');
    });
  });
});
