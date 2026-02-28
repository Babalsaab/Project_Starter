/**
 * Unit Tests — Runtime Configuration
 *
 * Tests for loadGlobalConfig, reloadGlobalConfig, and convenience accessors.
 */

import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";

// We need to manipulate the module cache for isolation
let mod: typeof import("./runtime-config");

describe("Runtime Configuration", () => {
  beforeEach(async () => {
    // Force-reload the module each time to reset the singleton cache
    vi.resetModules();
    mod = await import("./runtime-config");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  // ── loadGlobalConfig ──────────────────────────────────────────────────

  describe("loadGlobalConfig", () => {
    it("should return a config object with schema_version", () => {
      const config = mod.loadGlobalConfig();
      expect(config).toHaveProperty("schema_version");
    });

    it("should return globals with required sections", () => {
      const config = mod.loadGlobalConfig();
      expect(config.globals).toHaveProperty("brand_profile");
      expect(config.globals).toHaveProperty("brand_voice");
      expect(config.globals).toHaveProperty("token_policy_defaults");
      expect(config.globals).toHaveProperty("stop_conditions");
      expect(config.globals).toHaveProperty("summary_presets");
      expect(config.globals).toHaveProperty("routing_policy");
      expect(config.globals).toHaveProperty("artifact_store");
    });

    it("should cache results (singleton pattern)", () => {
      const first = mod.loadGlobalConfig();
      const second = mod.loadGlobalConfig();
      expect(first).toBe(second); // exact same reference
    });

    it("should return a complete default config structure", () => {
      // Verify the default fallback structure is well-formed
      // (We test the defaults by inspecting actual loaded config shape)
      const config = mod.loadGlobalConfig();
      expect(config).toBeDefined();
      expect(config.globals.token_policy_defaults.max_total_tokens).toBeGreaterThan(0);
      expect(config.globals.stop_conditions.max_failed_tasks).toBeGreaterThan(0);
    });

    it("should return consistent results across calls", () => {
      const first = mod.loadGlobalConfig();
      mod.reloadGlobalConfig();
      const second = mod.loadGlobalConfig();
      expect(first.schema_version).toBe(second.schema_version);
      expect(first.globals.token_policy_defaults.max_total_tokens)
        .toBe(second.globals.token_policy_defaults.max_total_tokens);
    });
  });

  // ── reloadGlobalConfig ────────────────────────────────────────────────

  describe("reloadGlobalConfig", () => {
    it("should clear cache and reload", () => {
      const first = mod.loadGlobalConfig();
      const reloaded = mod.reloadGlobalConfig();
      // They should have equal shape but the cache should have been cleared
      expect(reloaded).toHaveProperty("schema_version");
    });
  });

  // ── Convenience Accessors ─────────────────────────────────────────────

  describe("getTokenPolicy", () => {
    it("should return token policy with required fields", () => {
      const policy = mod.getTokenPolicy();
      expect(policy).toHaveProperty("max_total_tokens");
      expect(policy).toHaveProperty("max_steps");
      expect(policy).toHaveProperty("max_parallel_agents");
      expect(policy).toHaveProperty("per_agent_soft_limit");
      expect(policy).toHaveProperty("summarization_aggressiveness");
      expect(typeof policy.max_total_tokens).toBe("number");
    });
  });

  describe("getStopConditions", () => {
    it("should return stop conditions with required fields", () => {
      const conds = mod.getStopConditions();
      expect(conds).toHaveProperty("max_failed_tasks");
      expect(conds).toHaveProperty("max_retries_per_task");
      expect(conds).toHaveProperty("abort_on_token_exhaustion");
    });
  });

  describe("getSummaryPresets", () => {
    it("should return numeric presets for short/medium/long", () => {
      const presets = mod.getSummaryPresets();
      expect(typeof presets.short).toBe("number");
      expect(typeof presets.medium).toBe("number");
      expect(typeof presets.long).toBe("number");
      expect(presets.short).toBeLessThan(presets.medium);
      expect(presets.medium).toBeLessThan(presets.long);
    });
  });

  describe("getBrandVoice", () => {
    it("should return voice with tone_keywords, do, dont arrays", () => {
      const voice = mod.getBrandVoice();
      expect(Array.isArray(voice.tone_keywords)).toBe(true);
      expect(Array.isArray(voice.do)).toBe(true);
      expect(Array.isArray(voice.dont)).toBe(true);
    });
  });

  describe("getBrandProfile", () => {
    it("should return a profile with expected shape", () => {
      const profile = mod.getBrandProfile();
      expect(profile).toHaveProperty("name");
      expect(profile).toHaveProperty("description");
      expect(profile).toHaveProperty("category");
      expect(profile).toHaveProperty("primary_markets");
      expect(profile).toHaveProperty("mission");
    });
  });

  describe("getRoutingPolicy", () => {
    it("should return routing policy with domains and hints", () => {
      const routing = mod.getRoutingPolicy();
      expect(routing).toHaveProperty("primary_domains");
      expect(routing).toHaveProperty("classification_hints");
    });
  });
});
