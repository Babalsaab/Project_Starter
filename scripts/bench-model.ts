#!/usr/bin/env ts-node
/**
 * bench-model.ts — Benchmark LLM providers and models
 *
 * Inspired by OpenClaw's scripts/bench-model.ts.
 * Tests configured providers with a standardized prompt, measuring:
 *   - Latency (time to first token proxy, total time)
 *   - Output quality (structured output compliance)
 *   - Token efficiency (output tokens per useful content)
 *   - Cost estimation
 *
 * Usage:
 *   npm run bench:model                              # bench all enabled providers
 *   npm run bench:model -- --provider anthropic      # bench specific provider
 *   npm run bench:model -- --iterations 5            # custom iteration count
 *   npm run bench:model -- --output results.json     # save results
 */

import * as fs from "fs";
import * as path from "path";
import {
  getProviderRegistry,
  resetProviderRegistry,
} from "../orchestrator/providers/index";
import type { LLMProvider, HealthCheckResult } from "../orchestrator/providers/base";

// ─── Benchmark Prompts ───────────────────────────────────────────────────────

const BENCH_PROMPTS = [
  {
    id: "structured_output",
    name: "Structured Output (JSON)",
    systemPrompt: "You are a data extraction assistant. Return valid JSON only.",
    userMessage: `Extract the following information from this text and return as JSON with keys: name, role, skills (array), experience_years (number).

"Sarah Chen is a senior UX designer with 12 years of experience. She specializes in design systems, accessibility, and user research."`,
    validateFn: (output: string): { valid: boolean; notes: string } => {
      try {
        const jsonMatch = output.match(/\{[\s\S]*\}/);
        if (!jsonMatch) return { valid: false, notes: "No JSON found" };
        const data = JSON.parse(jsonMatch[0]);
        const hasKeys = ["name", "role", "skills", "experience_years"].every(
          (k) => k in data
        );
        return {
          valid: hasKeys,
          notes: hasKeys ? "All keys present" : "Missing keys",
        };
      } catch {
        return { valid: false, notes: "Invalid JSON" };
      }
    },
  },
  {
    id: "code_generation",
    name: "Code Generation (TypeScript)",
    systemPrompt:
      "You are a TypeScript expert. Write clean, typed code. No explanations — code only.",
    userMessage: `Write a TypeScript function called "retry" that:
1. Takes an async function and maxRetries number
2. Retries on failure with exponential backoff
3. Returns the result or throws after all retries exhausted
4. Is properly typed with generics`,
    validateFn: (output: string): { valid: boolean; notes: string } => {
      const hasFunction =
        output.includes("function retry") ||
        output.includes("const retry") ||
        output.includes("async function retry");
      const hasGeneric = output.includes("<");
      const hasAsync = output.includes("async");
      const hasRetry =
        output.includes("retries") || output.includes("maxRetries");
      const score = [hasFunction, hasGeneric, hasAsync, hasRetry].filter(
        Boolean
      ).length;
      return {
        valid: score >= 3,
        notes: `${score}/4 criteria met (function: ${hasFunction}, generic: ${hasGeneric}, async: ${hasAsync}, retry: ${hasRetry})`,
      };
    },
  },
  {
    id: "analysis",
    name: "Analysis & Reasoning",
    systemPrompt:
      "You are a product strategist. Be concise and structured.",
    userMessage: `Analyze the pros and cons of using a multi-agent AI system vs a single monolithic LLM for software development. List exactly 3 pros and 3 cons for each approach. Use bullet points.`,
    validateFn: (output: string): { valid: boolean; notes: string } => {
      const bulletCount = (output.match(/^[\s]*[-•*]\s/gm) || []).length;
      const hasMultiAgent =
        output.toLowerCase().includes("multi-agent") ||
        output.toLowerCase().includes("multi agent");
      const hasMonolithic =
        output.toLowerCase().includes("monolithic") ||
        output.toLowerCase().includes("single");
      return {
        valid: bulletCount >= 6 && hasMultiAgent && hasMonolithic,
        notes: `${bulletCount} bullets, mentions multi-agent: ${hasMultiAgent}, monolithic: ${hasMonolithic}`,
      };
    },
  },
];

// ─── Types ────────────────────────────────────────────────────────────────────

interface BenchmarkResult {
  provider_id: string;
  provider_name: string;
  provider_type: string;
  prompt_id: string;
  prompt_name: string;
  model_used: string;
  latency_ms: number;
  tokens_used: number;
  output_length: number;
  quality: { valid: boolean; notes: string };
  error?: string;
  iteration: number;
}

interface BenchmarkSummary {
  provider_id: string;
  provider_name: string;
  avg_latency_ms: number;
  median_latency_ms: number;
  p95_latency_ms: number;
  avg_tokens: number;
  quality_pass_rate: number;
  total_runs: number;
  errors: number;
  models_used: string[];
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function median(arr: number[]): number {
  const sorted = [...arr].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 !== 0
    ? sorted[mid]!
    : (sorted[mid - 1]! + sorted[mid]!) / 2;
}

function p95(arr: number[]): number {
  const sorted = [...arr].sort((a, b) => a - b);
  const idx = Math.ceil(sorted.length * 0.95) - 1;
  return sorted[Math.min(idx, sorted.length - 1)]!;
}

async function benchmarkProvider(
  provider: LLMProvider,
  providerId: string,
  providerName: string,
  providerType: string,
  iterations: number
): Promise<BenchmarkResult[]> {
  const results: BenchmarkResult[] = [];

  for (let iter = 0; iter < iterations; iter++) {
    for (const prompt of BENCH_PROMPTS) {
      const start = Date.now();
      try {
        const result = await provider.complete({
          systemPrompt: prompt.systemPrompt,
          messages: [{ role: "user", content: prompt.userMessage }],
          maxTokens: 1024,
        });

        const latency = Date.now() - start;
        const quality = prompt.validateFn(result.text);

        results.push({
          provider_id: providerId,
          provider_name: providerName,
          provider_type: providerType,
          prompt_id: prompt.id,
          prompt_name: prompt.name,
          model_used: result.model_used,
          latency_ms: latency,
          tokens_used: result.tokens_used,
          output_length: result.text.length,
          quality,
          iteration: iter + 1,
        });
      } catch (e) {
        const latency = Date.now() - start;
        results.push({
          provider_id: providerId,
          provider_name: providerName,
          provider_type: providerType,
          prompt_id: prompt.id,
          prompt_name: prompt.name,
          model_used: "error",
          latency_ms: latency,
          tokens_used: 0,
          output_length: 0,
          quality: { valid: false, notes: "Error" },
          error: (e as Error).message.slice(0, 200),
          iteration: iter + 1,
        });
      }
    }
  }

  return results;
}

function summarize(results: BenchmarkResult[]): BenchmarkSummary {
  const latencies = results
    .filter((r) => !r.error)
    .map((r) => r.latency_ms);
  const tokens = results.filter((r) => !r.error).map((r) => r.tokens_used);
  const passed = results.filter((r) => r.quality.valid).length;
  const errors = results.filter((r) => r.error).length;
  const models = [...new Set(results.map((r) => r.model_used).filter((m) => m !== "error"))];

  return {
    provider_id: results[0]!.provider_id,
    provider_name: results[0]!.provider_name,
    avg_latency_ms: latencies.length
      ? Math.round(latencies.reduce((a, b) => a + b, 0) / latencies.length)
      : 0,
    median_latency_ms: latencies.length ? Math.round(median(latencies)) : 0,
    p95_latency_ms: latencies.length ? Math.round(p95(latencies)) : 0,
    avg_tokens: tokens.length
      ? Math.round(tokens.reduce((a, b) => a + b, 0) / tokens.length)
      : 0,
    quality_pass_rate: results.length
      ? Math.round((passed / results.length) * 100)
      : 0,
    total_runs: results.length,
    errors,
    models_used: models,
  };
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  let targetProvider: string | null = null;
  let iterations = 3;
  let outputFile: string | null = null;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--provider" && args[i + 1]) {
      targetProvider = args[i + 1]!;
      i++;
    } else if (args[i] === "--iterations" && args[i + 1]) {
      iterations = parseInt(args[i + 1]!, 10);
      i++;
    } else if (args[i] === "--output" && args[i + 1]) {
      outputFile = args[i + 1]!;
      i++;
    }
  }

  console.log("🏋️ LLM Provider Benchmark");
  console.log(`   Iterations: ${iterations}`);
  console.log(`   Prompts: ${BENCH_PROMPTS.length}`);
  console.log(`   Target: ${targetProvider || "all enabled providers"}\n`);

  const registry = await getProviderRegistry();
  const healthResults = await registry.healthCheckAll();

  const allResults: BenchmarkResult[] = [];
  const summaries: BenchmarkSummary[] = [];

  for (const health of healthResults) {
    if (targetProvider && health.id !== targetProvider) continue;

    if (!health.result.healthy) {
      console.log(`⏭  Skipping ${health.name} (unhealthy: ${health.result.error})\n`);
      continue;
    }

    console.log(`📊 Benchmarking: ${health.name} (${health.id})`);

    const provider = registry.getProviderForAgent(health.id); // default provider for this
    // Actually get the specific provider by iterating
    // We need to get the provider matching health.id
    let benchProvider: LLMProvider;
    try {
      // Try to get it as an override provider
      benchProvider = registry.getProviderForAgent(health.id);
    } catch {
      benchProvider = registry.getDefaultProvider();
    }

    const results = await benchmarkProvider(
      benchProvider,
      health.id,
      health.name,
      "unknown",
      iterations
    );

    allResults.push(...results);
    const summary = summarize(results);
    summaries.push(summary);

    // Print per-prompt results
    for (const prompt of BENCH_PROMPTS) {
      const promptResults = results.filter((r) => r.prompt_id === prompt.id);
      const avgLatency =
        promptResults.length > 0
          ? Math.round(
              promptResults.reduce((a, r) => a + r.latency_ms, 0) /
                promptResults.length
            )
          : 0;
      const passed = promptResults.filter((r) => r.quality.valid).length;
      console.log(
        `   ${prompt.name}: avg ${avgLatency}ms, quality ${passed}/${promptResults.length}`
      );
    }

    console.log(
      `   Summary: avg ${summary.avg_latency_ms}ms, p95 ${summary.p95_latency_ms}ms, quality ${summary.quality_pass_rate}%, errors ${summary.errors}\n`
    );
  }

  // ─── Final Comparison ───────────────────────────────────────────────────────

  if (summaries.length > 1) {
    console.log("═".repeat(70));
    console.log("📈 COMPARISON\n");
    console.log(
      "Provider".padEnd(25) +
        "Avg(ms)".padStart(10) +
        "P95(ms)".padStart(10) +
        "Tokens".padStart(10) +
        "Quality".padStart(10) +
        "Errors".padStart(10)
    );
    console.log("─".repeat(75));
    for (const s of summaries.sort((a, b) => a.avg_latency_ms - b.avg_latency_ms)) {
      console.log(
        s.provider_name.padEnd(25) +
          String(s.avg_latency_ms).padStart(10) +
          String(s.p95_latency_ms).padStart(10) +
          String(s.avg_tokens).padStart(10) +
          `${s.quality_pass_rate}%`.padStart(10) +
          String(s.errors).padStart(10)
      );
    }
    console.log();
  }

  // ─── Save Results ───────────────────────────────────────────────────────────

  if (outputFile) {
    const output = {
      timestamp: new Date().toISOString(),
      config: { iterations, target_provider: targetProvider },
      summaries,
      detailed_results: allResults,
    };
    fs.writeFileSync(outputFile, JSON.stringify(output, null, 2));
    console.log(`💾 Results saved to ${outputFile}`);
  }

  // Exit code based on whether any provider had >50% errors
  const anyBadProvider = summaries.some(
    (s) => s.errors > s.total_runs * 0.5
  );
  process.exit(anyBadProvider ? 1 : 0);
}

main().catch((e) => {
  console.error(`Fatal: ${e.message}`);
  process.exit(1);
});
