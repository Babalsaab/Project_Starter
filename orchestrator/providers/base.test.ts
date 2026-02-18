/**
 * Unit Tests — Provider Base Utilities
 *
 * Tests for meetsRequirements(), approximateTokenCount(), trimContextToFit()
 */

import { describe, it, expect } from "vitest";
import {
  meetsRequirements,
  approximateTokenCount,
  trimContextToFit,
  ModelCapabilities,
  CapabilityRequirement,
} from "./base";

// ─── meetsRequirements ────────────────────────────────────────────────────────

describe("meetsRequirements", () => {
  const advancedCapabilities: ModelCapabilities = {
    code_generation: "advanced",
    analysis: "advanced",
    creative_writing: "advanced",
    structured_output: "advanced",
    max_context_window: 200000,
    max_output_tokens: 8192,
    supports_system_prompt: true,
    supports_streaming: true,
    supports_json_mode: true,
  };

  const basicCapabilities: ModelCapabilities = {
    code_generation: "basic",
    analysis: "basic",
    creative_writing: "basic",
    structured_output: "basic",
    max_context_window: 4096,
    max_output_tokens: 1024,
    supports_system_prompt: true,
    supports_streaming: false,
    supports_json_mode: false,
  };

  it("should return true when capabilities exceed requirements", () => {
    const req: CapabilityRequirement = {
      min_code_generation: "advanced",
      min_analysis: "basic",
    };
    expect(meetsRequirements(advancedCapabilities, req)).toBe(true);
  });

  it("should return false when code generation is insufficient", () => {
    const req: CapabilityRequirement = {
      min_code_generation: "advanced",
    };
    expect(meetsRequirements(basicCapabilities, req)).toBe(false);
  });

  it("should return false when analysis is insufficient", () => {
    const req: CapabilityRequirement = {
      min_analysis: "advanced",
    };
    expect(meetsRequirements(basicCapabilities, req)).toBe(false);
  });

  it("should return false when creative_writing is insufficient", () => {
    const req: CapabilityRequirement = {
      min_creative_writing: "advanced",
    };
    expect(meetsRequirements(basicCapabilities, req)).toBe(false);
  });

  it("should return false when structured_output is insufficient", () => {
    const req: CapabilityRequirement = {
      min_structured_output: "advanced",
    };
    expect(meetsRequirements(basicCapabilities, req)).toBe(false);
  });

  it("should return false when context window is too small", () => {
    const req: CapabilityRequirement = {
      min_context_window: 100000,
    };
    expect(meetsRequirements(basicCapabilities, req)).toBe(false);
  });

  it("should pass context window check when large enough", () => {
    const req: CapabilityRequirement = {
      min_context_window: 100000,
    };
    expect(meetsRequirements(advancedCapabilities, req)).toBe(true);
  });

  it("should return true when requirements are empty", () => {
    expect(meetsRequirements(basicCapabilities, {})).toBe(true);
  });

  it("should handle exact match (basic meets basic)", () => {
    const req: CapabilityRequirement = {
      min_code_generation: "basic",
      min_analysis: "basic",
    };
    expect(meetsRequirements(basicCapabilities, req)).toBe(true);
  });
});

// ─── approximateTokenCount ────────────────────────────────────────────────────

describe("approximateTokenCount", () => {
  it("should return a positive number for non-empty text", () => {
    expect(approximateTokenCount("Hello world")).toBeGreaterThan(0);
  });

  it("should return 0 or very small for empty string", () => {
    const count = approximateTokenCount("");
    expect(count).toBeLessThanOrEqual(1);
  });

  it("should estimate roughly 1 token per word for short text", () => {
    const text = "The quick brown fox jumps over the lazy dog";
    const count = approximateTokenCount(text);
    // 9 words, ~44 chars → should be roughly 9-15 tokens
    expect(count).toBeGreaterThan(5);
    expect(count).toBeLessThan(25);
  });

  it("should scale with text length", () => {
    const short = approximateTokenCount("hello");
    const long = approximateTokenCount("hello ".repeat(100));
    expect(long).toBeGreaterThan(short);
  });

  it("should handle code content", () => {
    const code = `function foo(bar: string): number {\n  return bar.length;\n}`;
    const count = approximateTokenCount(code);
    expect(count).toBeGreaterThan(5);
    expect(count).toBeLessThan(50);
  });
});

// ─── trimContextToFit ─────────────────────────────────────────────────────────

describe("trimContextToFit", () => {
  const sections = [
    { content: "System prompt — core instructions", priority: 10, label: "system" },
    { content: "PRD excerpt — product requirements", priority: 7, label: "prd" },
    { content: "Skills — code quality checklist", priority: 5, label: "skills" },
    { content: "Mentor quotes — Steve Jobs, Dieter Rams", priority: 3, label: "mentors" },
    { content: "Persona details — Sarah Chen background", priority: 2, label: "persona" },
  ];

  // Use a simple 1-char-per-token estimator for deterministic tests
  const charCounter = (text: string) => text.length;

  it("should include all sections when budget is large enough", () => {
    const result = trimContextToFit(sections, 10000, charCounter);
    expect(result).toContain("System prompt");
    expect(result).toContain("PRD excerpt");
    expect(result).toContain("Mentor quotes");
    expect(result).toContain("Persona details");
  });

  it("should drop lowest-priority sections first when budget is tight", () => {
    // Only enough room for ~2 sections
    const result = trimContextToFit(sections, 80, charCounter);
    expect(result).toContain("System prompt");
    // Lowest priority (persona, mentors) should be dropped
    expect(result).not.toContain("Persona details");
  });

  it("should always keep at least one section (highest priority)", () => {
    const result = trimContextToFit(sections, 1, charCounter);
    // Even with tiny budget, should keep the highest-priority section
    expect(result.length).toBeGreaterThan(0);
    expect(result).toContain("System prompt");
  });

  it("should handle single section", () => {
    const single = [{ content: "Only section", priority: 1, label: "only" }];
    const result = trimContextToFit(single, 100, charCounter);
    expect(result).toBe("Only section");
  });

  it("should handle empty sections array", () => {
    const result = trimContextToFit([], 100, charCounter);
    expect(result).toBe("");
  });

  it("should respect section ordering in output (low priority first)", () => {
    const result = trimContextToFit(sections, 10000, charCounter);
    const systemIdx = result.indexOf("System prompt");
    const personaIdx = result.indexOf("Persona details");
    // persona (priority 2) should come before system (priority 10) since lower = earlier
    expect(personaIdx).toBeLessThan(systemIdx);
  });
});
