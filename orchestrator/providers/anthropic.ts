/**
 * Anthropic Claude Provider
 *
 * Implements LLMProvider for Anthropic's Claude API.
 * Supports model failover chain (e.g., Sonnet → Haiku),
 * rate limit handling, and exact token counting from API response.
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

// ─── Anthropic API Types ──────────────────────────────────────────────────────

interface AnthropicMessage {
  role: "user" | "assistant";
  content: string;
}

interface AnthropicResponse {
  content: Array<{ type: string; text: string }>;
  usage: {
    input_tokens: number;
    output_tokens: number;
    cache_creation_input_tokens?: number;
    cache_read_input_tokens?: number;
  };
  model: string;
}

// ─── Provider Implementation ──────────────────────────────────────────────────

export class AnthropicProvider implements LLMProvider {
  readonly config: ProviderConfig;
  private apiKey: string;
  private baseUrl: string;

  constructor(config: ProviderConfig) {
    this.config = config;
    this.baseUrl = config.base_url || "https://api.anthropic.com";

    // Resolve API key from config or environment
    this.apiKey = config.api_key || "";
    if (!this.apiKey && config.api_key_env) {
      this.apiKey = process.env[config.api_key_env] || "";
    }
    if (!this.apiKey) {
      this.apiKey = process.env['ANTHROPIC_API_KEY'] || "";
    }
  }

  /**
   * Check if the API key is configured and valid-looking.
   */
  private isConfigured(): boolean {
    return !!this.apiKey && this.apiKey !== "sk-ant-...";
  }

  /**
   * Complete a request with automatic model failover.
   * Tries each model in config.models; on 429/529/error, falls back to next.
   */
  async complete(request: CompletionRequest): Promise<CompletionResponse> {
    if (!this.isConfigured()) {
      console.warn(
        "⚠ Anthropic API key not configured — returning placeholder output. " +
        "Set ANTHROPIC_API_KEY in .env.local for real results."
      );
      return {
        text: this.generatePlaceholder(request),
        tokens_used: 0,
        model_used: "placeholder",
        is_fallback: true,
      };
    }

    const models = this.config.models;
    let lastError: Error | null = null;
    const startTime = Date.now();

    for (let i = 0; i < models.length; i++) {
      const model = models[i];
      const isFallback = i > 0;

      try {
        const result = await this.callModel(model!, request);
        return {
          ...result,
          is_fallback: isFallback,
          latency_ms: Date.now() - startTime,
        };
      } catch (e) {
        lastError = e as Error;
        const errorMsg = (e as Error).message;

        // Only fallback on rate limits, overload, or network errors
        if (
          errorMsg.includes("429") ||
          errorMsg.includes("529") ||
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
   * Call a specific model on the Anthropic API.
   */
  private async callModel(
    model: string,
    request: CompletionRequest
  ): Promise<CompletionResponse> {
    // Convert messages: filter out system role (handled by `system` param)
    const messages: AnthropicMessage[] = request.messages
      .filter((m) => m.role !== "system")
      .map((m) => ({
        role: m.role as "user" | "assistant",
        content: m.content,
      }));

    const maxTokens = Math.min(
      request.maxTokens || 4096,
      this.config.max_output_tokens
    );

    const response = await fetch(`${this.baseUrl}/v1/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": this.apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model,
        max_tokens: maxTokens,
        system: request.systemPrompt,
        messages,
        ...(request.temperature !== undefined && {
          temperature: request.temperature,
        }),
      }),
      signal: request.abortSignal,
    });

    if (response.status === 429 || response.status === 529) {
      const retryAfter = response.headers.get("retry-after");
      throw new Error(
        `Rate limited on ${model} (${response.status})` +
          (retryAfter ? ` retry-after=${retryAfter}s` : "")
      );
    }

    if (!response.ok) {
      const error = await response.text();
      throw new Error(
        `Anthropic API error on ${model} (${response.status}): ${error.slice(0, 200)}`
      );
    }

    const data = (await response.json()) as AnthropicResponse;

    return {
      text: data.content[0]?.text || "",
      tokens_used: data.usage.input_tokens + data.usage.output_tokens,
      model_used: data.model || model,
      usage: {
        input_tokens: data.usage.input_tokens,
        output_tokens: data.usage.output_tokens,
        cache_read_tokens: data.usage.cache_read_input_tokens,
        cache_write_tokens: data.usage.cache_creation_input_tokens,
      },
    };
  }

  /**
   * Health check — ping the API with a minimal request.
   */
  async healthCheck(): Promise<HealthCheckResult> {
    if (!this.isConfigured()) {
      return {
        healthy: false,
        error: "API key not configured. Set ANTHROPIC_API_KEY in .env.local",
      };
    }

    const startTime = Date.now();

    try {
      const response = await fetch(`${this.baseUrl}/v1/messages`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": this.apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: this.config.models[0],
          max_tokens: 10,
          messages: [{ role: "user", content: "ping" }],
        }),
      });

      const latency = Date.now() - startTime;

      if (response.ok) {
        return {
          healthy: true,
          latency_ms: latency,
          model_name: this.config.models[0],
          provider_version: "2023-06-01",
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

  /**
   * Get model capabilities.
   */
  getCapabilities(): ModelCapabilities {
    return this.config.capabilities;
  }

  /**
   * Estimate tokens — use the standard approximation.
   * Anthropic provides exact counts in responses, so this is only
   * used for pre-flight budget checks.
   */
  estimateTokens(text: string): number {
    return approximateTokenCount(text);
  }

  /**
   * Effective context window after accounting for system prompt overhead (~500 tokens).
   */
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

> **Note**: This is a placeholder output. Set ANTHROPIC_API_KEY in .env.local to get real AI-generated results.
> Provider: Anthropic Claude (${this.config.models[0] || "not configured"})

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
