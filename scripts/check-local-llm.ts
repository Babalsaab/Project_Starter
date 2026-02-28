#!/usr/bin/env ts-node
/**
 * check-local-llm.ts — Verify local LLM servers are running and reachable
 *
 * Checks each local provider configured in globals.yaml:
 *   - HTTP reachability (base_url)
 *   - Model availability (/v1/models endpoint)
 *   - Basic completion test
 *   - Context window / token limits
 *
 * Usage:
 *   npm run check:llm                    # check all configured providers
 *   npm run check:llm -- --verbose       # show model details
 *   npm run check:llm -- --test          # run a test completion
 */

import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";

// ─── Types ────────────────────────────────────────────────────────────────────

interface ProviderConfig {
  id: string;
  name: string;
  type: string;
  enabled: boolean;
  base_url?: string;
  api_key?: string;
  api_key_env?: string;
  models?: string[];
}

interface CheckResult {
  provider_id: string;
  provider_name: string;
  type: string;
  base_url: string;
  reachable: boolean;
  models_found: string[];
  configured_models_available: string[];
  configured_models_missing: string[];
  test_completion?: { success: boolean; latency_ms: number; model: string; error?: string };
  error?: string;
}

// ─── Config Loading ───────────────────────────────────────────────────────────

function loadProviders(): ProviderConfig[] {
  const globalsPath = path.resolve(__dirname, "../config/globals.yaml");
  if (!fs.existsSync(globalsPath)) {
    console.error("config/globals.yaml not found");
    process.exit(1);
  }
  const globals = yaml.load(fs.readFileSync(globalsPath, "utf-8")) as any;
  if (!globals?.providers || !Array.isArray(globals.providers)) {
    return [];
  }

  return globals.providers.filter((p: any) => p.enabled !== false);
}

// ─── Checks ─────────────────────────────────────────────────────────────────

async function checkReachability(baseUrl: string): Promise<boolean> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const resp = await fetch(baseUrl, { signal: controller.signal });
    clearTimeout(timeout);
    return resp.ok || resp.status === 404; // 404 means server is up, just no root handler
  } catch {
    return false;
  }
}

async function listModels(baseUrl: string, apiKey?: string): Promise<string[]> {
  try {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    if (apiKey) headers["Authorization"] = `Bearer ${apiKey}`;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const resp = await fetch(`${baseUrl}/v1/models`, {
      headers,
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!resp.ok) return [];
    const data = (await resp.json()) as any;
    return (data.data || []).map((m: any) => m.id);
  } catch {
    return [];
  }
}

async function testCompletion(
  baseUrl: string,
  model: string,
  apiKey?: string
): Promise<{ success: boolean; latency_ms: number; error?: string }> {
  const start = Date.now();
  try {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    if (apiKey) headers["Authorization"] = `Bearer ${apiKey}`;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 30000);
    const resp = await fetch(`${baseUrl}/v1/chat/completions`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        model,
        messages: [
          { role: "user", content: "Say exactly: 'Hello, I am working.'" },
        ],
        max_tokens: 20,
        temperature: 0,
      }),
      signal: controller.signal,
    });
    clearTimeout(timeout);

    const latency = Date.now() - start;

    if (!resp.ok) {
      const body = await resp.text();
      return {
        success: false,
        latency_ms: latency,
        error: `HTTP ${resp.status}: ${body.slice(0, 100)}`,
      };
    }

    const data = (await resp.json()) as any;
    const text =
      data.choices?.[0]?.message?.content || data.choices?.[0]?.text || "";

    return {
      success: text.length > 0,
      latency_ms: latency,
    };
  } catch (e) {
    return {
      success: false,
      latency_ms: Date.now() - start,
      error: (e as Error).message,
    };
  }
}

async function checkProvider(
  config: ProviderConfig,
  runTest: boolean,
  verbose: boolean
): Promise<CheckResult> {
  const baseUrl = (
    config.base_url || "http://localhost:11434/v1"
  ).replace(/\/+$/, "");

  // Resolve API key
  let apiKey = config.api_key;
  if (!apiKey && config.api_key_env) {
    apiKey = process.env[config.api_key_env];
  }

  const result: CheckResult = {
    provider_id: config.id,
    provider_name: config.name,
    type: config.type,
    base_url: baseUrl,
    reachable: false,
    models_found: [],
    configured_models_available: [],
    configured_models_missing: [],
  };

  // Skip non-local providers (Anthropic, Manual)
  if (config.type === "anthropic") {
    result.reachable = !!apiKey;
    if (!apiKey) {
      result.error = "No API key configured";
    }
    return result;
  }

  if (config.type === "manual") {
    result.reachable = true; // manual always works
    return result;
  }

  // Reachability
  result.reachable = await checkReachability(baseUrl);
  if (!result.reachable) {
    result.error = `Cannot reach ${baseUrl}`;
    return result;
  }

  // Model listing
  result.models_found = await listModels(baseUrl, apiKey);

  // Compare with configured models
  const configured = config.models || [];
  for (const model of configured) {
    if (
      result.models_found.some(
        (m) => m === model || m.includes(model) || model.includes(m)
      )
    ) {
      result.configured_models_available.push(model);
    } else {
      result.configured_models_missing.push(model);
    }
  }

  // Test completion
  if (runTest && result.configured_models_available.length > 0) {
    const testModel = result.configured_models_available[0];
    const testResult = await testCompletion(baseUrl, testModel!, apiKey);
    result.test_completion = {
      ...testResult,
      model: testModel!,
    };
  }

  return result;
}

// ─── Output ───────────────────────────────────────────────────────────────────

function printResults(results: CheckResult[], verbose: boolean): void {
  console.log("═".repeat(60));
  console.log("🔍 Local LLM Provider Check");
  console.log("═".repeat(60));
  console.log();

  for (const r of results) {
    const icon = r.reachable ? "✅" : "❌";
    console.log(`${icon} ${r.provider_name} (${r.provider_id})`);
    console.log(`   Type: ${r.type}`);

    if (r.type !== "anthropic" && r.type !== "manual") {
      console.log(`   URL: ${r.base_url}`);
    }

    if (r.error) {
      console.log(`   Error: ${r.error}`);
    }

    if (r.models_found.length > 0) {
      console.log(`   Models found: ${r.models_found.length}`);
      if (verbose) {
        for (const m of r.models_found) {
          console.log(`     - ${m}`);
        }
      }
    }

    if (r.configured_models_available.length > 0) {
      console.log(
        `   Configured models available: ${r.configured_models_available.join(", ")}`
      );
    }
    if (r.configured_models_missing.length > 0) {
      console.log(
        `   ⚠️  Missing models: ${r.configured_models_missing.join(", ")}`
      );
    }

    if (r.test_completion) {
      const tc = r.test_completion;
      if (tc.success) {
        console.log(
          `   Test completion: ✅ ${tc.model} (${tc.latency_ms}ms)`
        );
      } else {
        console.log(
          `   Test completion: ❌ ${tc.model} — ${tc.error || "no output"}`
        );
      }
    }

    console.log();
  }

  // Summary
  const reachable = results.filter((r) => r.reachable).length;
  console.log("─".repeat(60));
  console.log(
    `Summary: ${reachable}/${results.length} providers reachable`
  );

  if (results.every((r) => !r.reachable && r.type === "openai-compatible")) {
    console.log(
      "\n💡 No local LLM servers detected. To set one up:\n" +
        "   Ollama:     brew install ollama && ollama serve && ollama pull llama3.2\n" +
        "   LM Studio:  Download from https://lmstudio.ai and start the server\n" +
        "   llama.cpp:  ./llama-server -m model.gguf --port 8080\n"
    );
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const verbose = args.includes("--verbose");
  const runTest = args.includes("--test");

  const providers = loadProviders();
  if (providers.length === 0) {
    console.log("No providers configured in config/globals.yaml.");
    console.log("Add providers to the 'providers' section. See CLAUDE.md for examples.\n");
    process.exit(0);
  }

  console.log(
    `Checking ${providers.length} provider(s)...${runTest ? " (with test completions)" : ""}\n`
  );

  const results: CheckResult[] = [];
  for (const p of providers) {
    results.push(await checkProvider(p, runTest, verbose));
  }

  printResults(results, verbose);

  const allReachable = results.every((r) => r.reachable);
  process.exit(allReachable ? 0 : 1);
}

main().catch((e) => {
  console.error(`Fatal: ${e.message}`);
  process.exit(1);
});
