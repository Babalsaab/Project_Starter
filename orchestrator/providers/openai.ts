/**
 * OpenAI Provider for Vibecoded Orchestrator
 *
 * Native OpenAI API provider with dynamic model discovery.
 * Auto-discovers available models via /v1/models and resolves "latest" aliases.
 *
 * Model resolution strategy:
 *   1. If config specifies exact model IDs → use those
 *   2. If config uses "latest" or "auto" → query /v1/models and pick best available
 *   3. Falls back to known-good defaults if discovery fails
 *
 * Key features:
 *   - Dynamic model discovery via /v1/models endpoint
 *   - Supports JSON mode via response_format
 *   - Exponential backoff for rate limits (3 retries)
 *   - Reads API key from OPENAI_API_KEY env var
 */

import type {
  LLMProvider,
  ProviderConfig,
  CompletionRequest,
  CompletionResponse,
  HealthCheckResult,
  ModelCapabilities,
} from "./base";
import { approximateTokenCount } from "./base";

// ─── OpenAI API Types ────────────────────────────────────────────────────────

interface OpenAIChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface OpenAIChatChoice {
  message: {
    role: string;
    content: string;
  };
  finish_reason: string;
}

interface OpenAIChatResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: OpenAIChatChoice[];
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

interface OpenAIErrorResponse {
  error: {
    message: string;
    type: string;
    code: string | null;
  };
}

// ─── Model Discovery & Resolution ───────────────────────────────────────────

/** Preferred model families in priority order (newest first) */
const OPENAI_MODEL_PREFERENCE = [
  // Reasoning models (newest first)
  "o4-mini", "o3", "o3-mini", "o1", "o1-mini",
  // GPT chat models (newest first)
  "gpt-4.1", "gpt-4.1-mini", "gpt-4.1-nano",
  "gpt-4o", "gpt-4o-mini",
  "gpt-4-turbo", "gpt-4",
];

/** Check if a model ID matches a preference (prefix match) */
function matchesPreference(modelId: string, pref: string): boolean {
  return modelId === pref || modelId.startsWith(`${pref}-`);
}

// ─── Rate Limit / Retry Config ───────────────────────────────────────────────

const MAX_RETRIES = 3;
const RETRY_DELAYS_MS = [1000, 2000, 4000]; // exponential backoff

// ─── Provider Implementation ────────────────────────────────────────────────

export class OpenAIProvider implements LLMProvider {
  readonly config: ProviderConfig;
  private apiKey: string;
  private baseUrl: string;
  private resolvedModels: string[] | null = null;
  private modelDiscoveryPromise: Promise<string[]> | null = null;

  constructor(config: ProviderConfig) {
    this.config = config;
    this.baseUrl = (config.base_url || "https://api.openai.com/v1").replace(
      /\/$/,
      ""
    );

    // Resolve API key from config or environment
    this.apiKey = config.api_key || "";
    if (!this.apiKey && config.api_key_env) {
      this.apiKey = process.env[config.api_key_env] || "";
    }
    if (!this.apiKey) {
      this.apiKey = process.env["OPENAI_API_KEY"] || "";
    }
  }

  /**
   * Check if the API key is configured.
   */
  private isConfigured(): boolean {
    return !!this.apiKey && this.apiKey !== "sk-...";
  }

  /**
   * Discover available models from the OpenAI API.
   * Results are cached for the lifetime of the provider instance.
   */
  async discoverModels(): Promise<string[]> {
    if (this.resolvedModels) return this.resolvedModels;
    if (this.modelDiscoveryPromise) return this.modelDiscoveryPromise;

    this.modelDiscoveryPromise = this._discoverModels();
    this.resolvedModels = await this.modelDiscoveryPromise;
    this.modelDiscoveryPromise = null;
    return this.resolvedModels;
  }

  private async _discoverModels(): Promise<string[]> {
    if (!this.isConfigured()) return this.config.models;

    try {
      const response = await fetch(`${this.baseUrl}/models`, {
        headers: { Authorization: `Bearer ${this.apiKey}` },
        signal: AbortSignal.timeout(10000),
      });

      if (!response.ok) return this.config.models;

      const data = (await response.json()) as { data: Array<{ id: string; created: number }> };
      const chatModels = data.data
        .filter((m) => m.id.startsWith("gpt-") || m.id.startsWith("o1") || m.id.startsWith("o3") || m.id.startsWith("o4"))
        .sort((a, b) => b.created - a.created);

      if (chatModels.length === 0) return this.config.models;

      // Resolve "latest" or "auto" entries in config
      const resolved: string[] = [];
      for (const configModel of this.config.models) {
        if (configModel === "latest" || configModel === "auto") {
          // Pick the best available model by preference order
          const best = this.pickBestModel(chatModels.map((m) => m.id));
          if (best && !resolved.includes(best)) resolved.push(best);
        } else if (configModel.endsWith(":latest")) {
          // e.g. "gpt-4o:latest" → find newest gpt-4o-* variant
          const family = configModel.replace(":latest", "");
          const match = chatModels.find((m) => matchesPreference(m.id, family));
          resolved.push(match ? match.id : family);
        } else {
          resolved.push(configModel);
        }
      }

      // If config had no models, auto-select the top 2
      if (resolved.length === 0) {
        const best = this.pickBestModel(chatModels.map((m) => m.id));
        if (best) resolved.push(best);
        // Add a fallback
        const fallback = chatModels.find((m) => m.id.includes("mini") || m.id.includes("nano"));
        if (fallback && !resolved.includes(fallback.id)) resolved.push(fallback.id);
      }

      console.log(`  ✓ OpenAI models resolved: ${resolved.join(", ")}`);
      return resolved.length > 0 ? resolved : this.config.models;
    } catch {
      // Discovery failed — use config defaults
      return this.config.models;
    }
  }

  /** Pick the best model from a list based on preference order */
  private pickBestModel(available: string[]): string | undefined {
    for (const pref of OPENAI_MODEL_PREFERENCE) {
      const match = available.find((m) => matchesPreference(m, pref));
      if (match) return match;
    }
    return available[0];
  }

  /**
   * Complete a request with model failover and exponential backoff.
   * Auto-discovers latest models if configured with "latest" or "auto".
   */
  async complete(request: CompletionRequest): Promise<CompletionResponse> {
    if (!this.isConfigured()) {
      console.warn(
        "⚠ OpenAI API key not configured — returning placeholder output. " +
        "Set OPENAI_API_KEY in .env.local for real results."
      );
      return {
        text: this.generatePlaceholder(request),
        tokens_used: 0,
        model_used: "placeholder",
        is_fallback: true,
      };
    }

    const models = await this.discoverModels();
    let lastError: Error | null = null;
    const startTime = Date.now();

    for (let i = 0; i < models.length; i++) {
      const model = models[i];
      const isFallback = i > 0;

      try {
        const result = await this.callModelWithRetry(model!, request);
        return {
          ...result,
          is_fallback: isFallback,
          latency_ms: Date.now() - startTime,
        };
      } catch (e) {
        lastError = e as Error;
        const errorMsg = (e as Error).message;

        // Only fallback to next model on rate limits, overload, or network errors
        if (
          errorMsg.includes("429") ||
          errorMsg.includes("500") ||
          errorMsg.includes("503") ||
          errorMsg.includes("network") ||
          errorMsg.includes("ECONNREFUSED")
        ) {
          console.warn(
            `  ⚠ Model ${model} failed: ${errorMsg.slice(0, 100)}. Trying fallback...`
          );
          continue;
        }

        // Non-retryable errors — don't bother with fallback
        throw e;
      }
    }

    throw lastError || new Error("All models in failover chain exhausted");
  }

  /**
   * Call a specific model with exponential backoff on rate limits.
   */
  private async callModelWithRetry(
    model: string,
    request: CompletionRequest
  ): Promise<CompletionResponse> {
    let lastError: Error | null = null;

    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
      try {
        return await this.callModel(model, request);
      } catch (e) {
        lastError = e as Error;
        const errorMsg = (e as Error).message;

        // Only retry on rate limits (429) and server errors (500, 503)
        const isRetryable =
          errorMsg.includes("429") ||
          errorMsg.includes("500") ||
          errorMsg.includes("503");

        if (!isRetryable || attempt >= MAX_RETRIES) {
          throw e;
        }

        const delay = RETRY_DELAYS_MS[attempt] || 4000;
        console.log(
          `  ↻ OpenAI rate limited, retry ${attempt + 1}/${MAX_RETRIES} in ${delay / 1000}s...`
        );
        await new Promise((r) => setTimeout(r, delay));
      }
    }

    throw lastError || new Error("Retry loop exhausted");
  }

  /**
   * Call a specific model on the OpenAI chat completions API.
   */
  private async callModel(
    model: string,
    request: CompletionRequest
  ): Promise<CompletionResponse> {
    const messages: OpenAIChatMessage[] = [];

    // System prompt as a system message
    if (request.systemPrompt) {
      messages.push({ role: "system", content: request.systemPrompt });
    }

    // Map conversation messages (filter out system — already handled)
    for (const msg of request.messages) {
      if (msg.role === "system") continue;
      messages.push({
        role: msg.role as "user" | "assistant",
        content: msg.content,
      });
    }

    const maxTokens = Math.min(
      request.maxTokens || 4096,
      this.config.max_output_tokens
    );

    // Build request body
    const body: Record<string, unknown> = {
      model,
      messages,
      max_tokens: maxTokens,
      stream: false,
    };

    if (request.temperature !== undefined) {
      body["temperature"] = request.temperature;
    }

    // JSON mode support
    if (request.jsonMode && this.config.capabilities.supports_json_mode) {
      body["response_format"] = { type: "json_object" };
    }

    const response = await fetch(`${this.baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify(body),
      signal: request.abortSignal,
    });

    if (response.status === 429) {
      const retryAfter = response.headers.get("retry-after");
      throw new Error(
        `Rate limited on ${model} (429)` +
          (retryAfter ? ` retry-after=${retryAfter}s` : "")
      );
    }

    if (!response.ok) {
      const errorText = await response.text();
      let errorMessage: string;
      try {
        const errorBody = JSON.parse(errorText) as OpenAIErrorResponse;
        errorMessage = errorBody.error?.message || errorText;
      } catch {
        errorMessage = errorText;
      }
      throw new Error(
        `OpenAI API error on ${model} (${response.status}): ${errorMessage.slice(0, 200)}`
      );
    }

    const data = (await response.json()) as OpenAIChatResponse;
    const text = data.choices[0]?.message?.content || "";

    const hasUsage = data.usage && data.usage.total_tokens > 0;
    const tokensUsed = hasUsage
      ? data.usage!.total_tokens
      : approximateTokenCount(request.systemPrompt + text);

    return {
      text,
      tokens_used: tokensUsed,
      model_used: data.model || model,
      usage: hasUsage
        ? {
            input_tokens: data.usage!.prompt_tokens,
            output_tokens: data.usage!.completion_tokens,
          }
        : undefined,
    };
  }

  /**
   * Health check — ping the OpenAI API with /v1/models.
   */
  async healthCheck(): Promise<HealthCheckResult> {
    if (!this.isConfigured()) {
      return {
        healthy: false,
        error: "API key not configured. Set OPENAI_API_KEY in .env.local",
      };
    }

    const startTime = Date.now();

    try {
      const response = await fetch(`${this.baseUrl}/models`, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
        },
        signal: AbortSignal.timeout(10000),
      });

      const latency = Date.now() - startTime;

      if (response.ok) {
        return {
          healthy: true,
          latency_ms: latency,
          model_name: this.config.models[0],
          provider_version: "OpenAI API",
        };
      }

      // 401 = bad key, 429 = rate limited (but server is reachable)
      if (response.status === 429) {
        return {
          healthy: true,
          latency_ms: latency,
          model_name: this.config.models[0],
          error: "Rate limited but reachable",
        };
      }

      const errorText = await response.text();
      return {
        healthy: false,
        latency_ms: latency,
        error: `HTTP ${response.status}: ${errorText.slice(0, 100)}`,
      };
    } catch (e) {
      return {
        healthy: false,
        latency_ms: Date.now() - startTime,
        error: `Connection failed: ${(e as Error).message}`,
      };
    }
  }

  getCapabilities(): ModelCapabilities {
    return this.config.capabilities;
  }

  estimateTokens(text: string): number {
    return approximateTokenCount(text);
  }

  getEffectiveContextWindow(): number {
    return this.config.max_context_window - 500;
  }

  /**
   * Generate a structured placeholder when no API key is set.
   */
  private generatePlaceholder(request: CompletionRequest): string {
    const roleMatch = request.systemPrompt.match(
      /You are (?:a |an |the )?(.+?)\./
    );
    const role = roleMatch ? roleMatch[1] ?? "Specialist Agent" : "Specialist Agent";

    return `# Output from ${role}

> **Note**: This is a placeholder output. Set OPENAI_API_KEY in .env.local to get real AI-generated results.
> Provider: OpenAI (${this.config.models[0] || "not configured"})

## Analysis

Based on the provided context, here are the key deliverables:

### Recommendations
1. Review the project requirements and align with the PRD
2. Implement best practices for the ${role.toLowerCase()} domain
3. Coordinate with dependent agents for seamless integration

### Deliverables
- Primary deliverable document (to be generated with API key)
- Implementation specifications
- Quality checklist

### Next Steps
- Pass this output to downstream agents
- Review and iterate based on feedback
`;
  }
}
