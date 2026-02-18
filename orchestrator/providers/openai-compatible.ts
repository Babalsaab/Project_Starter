/**
 * OpenAI-Compatible Provider
 *
 * Implements LLMProvider for any LLM server exposing the OpenAI chat completions API.
 * This covers:
 *   - Ollama (http://localhost:11434/v1)
 *   - LM Studio (http://localhost:1234/v1)
 *   - llama.cpp server (http://localhost:8080/v1)
 *   - Jan.ai (http://localhost:1337/v1)
 *   - vLLM (http://localhost:8000/v1)
 *   - text-generation-webui (http://localhost:5000/v1)
 *   - Any OpenAI-compatible endpoint (OpenRouter, Together, Groq, etc.)
 *
 * Handles the common differences between local model servers:
 *   - Some don't report token usage → falls back to approximation
 *   - Some don't support system messages → prepends to first user message
 *   - Context windows vary wildly (4k–128k)
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

// ─── OpenAI API Types ─────────────────────────────────────────────────────────

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
  choices: OpenAIChatChoice[];
  model: string;
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

interface OpenAIModel {
  id: string;
  owned_by?: string;
}

interface OpenAIModelList {
  data: OpenAIModel[];
}

// ─── Provider Implementation ──────────────────────────────────────────────────

export class OpenAICompatibleProvider implements LLMProvider {
  readonly config: ProviderConfig;
  private apiKey: string;
  private baseUrl: string;

  constructor(config: ProviderConfig) {
    this.config = config;
    this.baseUrl = (config.base_url || "http://localhost:11434/v1").replace(
      /\/$/,
      ""
    );

    // Resolve API key — many local models don't need one
    this.apiKey = config.api_key || "";
    if (!this.apiKey && config.api_key_env) {
      this.apiKey = process.env[config.api_key_env] || "";
    }
    // Default to "no-key" for local models that require a non-empty string
    if (!this.apiKey) {
      this.apiKey = "no-key";
    }
  }

  /**
   * Complete a request with model failover.
   */
  async complete(request: CompletionRequest): Promise<CompletionResponse> {
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
        console.warn(
          `  ⚠ Model ${model} failed: ${(e as Error).message.slice(0, 100)}. Trying fallback...`
        );
        continue;
      }
    }

    throw lastError || new Error("All models in failover chain exhausted");
  }

  /**
   * Call a specific model via the OpenAI chat completions endpoint.
   */
  private async callModel(
    model: string,
    request: CompletionRequest
  ): Promise<CompletionResponse> {
    const messages: OpenAIChatMessage[] = [];

    // Handle system prompt — some local servers need it as a system message,
    // others need it prepended to the first user message
    if (request.systemPrompt && this.config.capabilities.supports_system_prompt) {
      messages.push({ role: "system", content: request.systemPrompt });
    }

    for (const msg of request.messages) {
      if (msg.role === "system") continue; // Already handled above

      let content = msg.content;
      // If server doesn't support system prompts, prepend to first user message
      if (
        msg.role === "user" &&
        messages.length === 0 &&
        request.systemPrompt &&
        !this.config.capabilities.supports_system_prompt
      ) {
        content = `[System Instructions]\n${request.systemPrompt}\n\n[Your Task]\n${content}`;
      }

      messages.push({
        role: msg.role as "user" | "assistant",
        content,
      });
    }

    const maxTokens = Math.min(
      request.maxTokens || 4096,
      this.config.max_output_tokens
    );

    const body: Record<string, unknown> = {
      model,
      messages,
      max_tokens: maxTokens,
      stream: false,
    };

    if (request.temperature !== undefined) {
      body['temperature'] = request.temperature;
    }

    // JSON mode support — varies by server
    if (request.jsonMode && this.config.capabilities.supports_json_mode) {
      body['response_format'] = { type: "json_object" };
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
      throw new Error(`Rate limited on ${model} (429)`);
    }

    if (!response.ok) {
      const error = await response.text();
      throw new Error(
        `OpenAI-compatible API error on ${model} (${response.status}): ${error.slice(0, 200)}`
      );
    }

    const data = (await response.json()) as OpenAIChatResponse;
    const text = data.choices[0]?.message?.content || "";

    // Some local servers don't report usage — fall back to approximation
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
   * Health check — try /v1/models to see if the server is running.
   * Falls back to a minimal chat completion if /models isn't supported.
   */
  async healthCheck(): Promise<HealthCheckResult> {
    const startTime = Date.now();

    try {
      // First try /v1/models — fast, doesn't generate tokens
      const modelsResponse = await fetch(`${this.baseUrl}/models`, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
        },
        signal: AbortSignal.timeout(10000),
      });

      const latency = Date.now() - startTime;

      if (modelsResponse.ok) {
        const modelList = (await modelsResponse.json()) as OpenAIModelList;
        const availableModels = modelList.data?.map((m) => m.id) || [];
        const requestedModel = this.config.models[0] ?? "unknown";
        const modelFound = availableModels.some(
          (m) =>
            m === requestedModel || m.includes(requestedModel.split(":")[0]!)
        );

        return {
          healthy: true,
          latency_ms: latency,
          model_name: modelFound
            ? requestedModel
            : `${requestedModel} (not found; available: ${availableModels.slice(0, 3).join(", ")})`,
          provider_version: `OpenAI-compatible (${this.config.name})`,
        };
      }

      // If /models fails, try a minimal completion
      return await this.healthCheckViaCompletion();
    } catch (e) {
      // Server not reachable
      return {
        healthy: false,
        latency_ms: Date.now() - startTime,
        error: `Cannot reach ${this.baseUrl}: ${(e as Error).message}`,
      };
    }
  }

  /**
   * Fallback health check via a minimal chat completion.
   */
  private async healthCheckViaCompletion(): Promise<HealthCheckResult> {
    const startTime = Date.now();

    try {
      const response = await fetch(`${this.baseUrl}/chat/completions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify({
          model: this.config.models[0],
          messages: [{ role: "user", content: "Say ok" }],
          max_tokens: 5,
        }),
        signal: AbortSignal.timeout(30000),
      });

      const latency = Date.now() - startTime;

      if (response.ok) {
        return {
          healthy: true,
          latency_ms: latency,
          model_name: this.config.models[0],
          provider_version: `OpenAI-compatible (${this.config.name})`,
        };
      }

      return {
        healthy: false,
        latency_ms: latency,
        error: `HTTP ${response.status}`,
      };
    } catch (e) {
      return {
        healthy: false,
        latency_ms: Date.now() - startTime,
        error: `Completion check failed: ${(e as Error).message}`,
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
    // Local models need more headroom for system prompt handling
    return this.config.max_context_window - 800;
  }
}
