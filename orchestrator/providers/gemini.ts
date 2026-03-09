/**
 * Google Gemini Provider for Vibecoded Orchestrator
 *
 * Native Google Gemini API provider with dynamic model discovery.
 * Auto-discovers available models via /v1beta/models and resolves "latest" aliases.
 *
 * Model resolution strategy:
 *   1. If config specifies exact model IDs → use those
 *   2. If config uses "latest" or "auto" → query /v1beta/models and pick best available
 *   3. Falls back to known-good defaults if discovery fails
 *
 * Key features:
 *   - Dynamic model discovery via /v1beta/models endpoint
 *   - Maps system prompt to Gemini's systemInstruction field
 *   - Safety settings set to BLOCK_NONE for unrestricted agent use
 *   - Reads API key from GOOGLE_API_KEY or GEMINI_API_KEY env var
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

// ─── Gemini API Types ────────────────────────────────────────────────────────

interface GeminiContent {
  role: "user" | "model";
  parts: Array<{ text: string }>;
}

interface GeminiSafetyRating {
  category: string;
  probability: string;
}

interface GeminiCandidate {
  content: {
    parts: Array<{ text: string }>;
    role: string;
  };
  finishReason: string;
  safetyRatings?: GeminiSafetyRating[];
}

interface GeminiUsageMetadata {
  promptTokenCount: number;
  candidatesTokenCount: number;
  totalTokenCount: number;
}

interface GeminiResponse {
  candidates: GeminiCandidate[];
  usageMetadata?: GeminiUsageMetadata;
  promptFeedback?: {
    blockReason?: string;
    safetyRatings?: GeminiSafetyRating[];
  };
}

interface GeminiErrorResponse {
  error: {
    code: number;
    message: string;
    status: string;
  };
}

// Gemini safety setting categories
const SAFETY_CATEGORIES = [
  "HARM_CATEGORY_HARASSMENT",
  "HARM_CATEGORY_HATE_SPEECH",
  "HARM_CATEGORY_SEXUALLY_EXPLICIT",
  "HARM_CATEGORY_DANGEROUS_CONTENT",
];

// ─── Model Discovery & Resolution ───────────────────────────────────────────

/** Preferred Gemini model families in priority order (newest first) */
const GEMINI_MODEL_PREFERENCE = [
  "gemini-2.5-pro", "gemini-2.5-flash",
  "gemini-2.0-pro", "gemini-2.0-flash",
  "gemini-1.5-pro", "gemini-1.5-flash",
];

// ─── Rate Limit / Retry Config ───────────────────────────────────────────────

const MAX_RETRIES = 3;
const RETRY_DELAYS_MS = [1000, 2000, 4000];

// ─── Provider Implementation ────────────────────────────────────────────────

export class GeminiProvider implements LLMProvider {
  readonly config: ProviderConfig;
  private apiKey: string;
  private baseUrl: string;
  private resolvedModels: string[] | null = null;
  private modelDiscoveryPromise: Promise<string[]> | null = null;

  constructor(config: ProviderConfig) {
    this.config = config;
    this.baseUrl = (
      config.base_url ||
      "https://generativelanguage.googleapis.com/v1beta"
    ).replace(/\/$/, "");

    // Resolve API key: config > GOOGLE_API_KEY > GEMINI_API_KEY
    this.apiKey = config.api_key || "";
    if (!this.apiKey && config.api_key_env) {
      this.apiKey = process.env[config.api_key_env] || "";
    }
    if (!this.apiKey) {
      this.apiKey =
        process.env["GOOGLE_API_KEY"] ||
        process.env["GEMINI_API_KEY"] ||
        "";
    }
  }

  /**
   * Check if the API key is configured.
   */
  private isConfigured(): boolean {
    return !!this.apiKey && this.apiKey.length > 10;
  }

  /**
   * Discover available models from the Gemini API.
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
      const response = await fetch(
        `${this.baseUrl}/models?key=${this.apiKey}`,
        { signal: AbortSignal.timeout(10000) }
      );

      if (!response.ok) return this.config.models;

      const data = (await response.json()) as {
        models: Array<{ name: string; supportedGenerationMethods?: string[] }>;
      };

      // Filter to models that support generateContent (chat-capable)
      const chatModels = data.models
        .filter((m) =>
          m.supportedGenerationMethods?.includes("generateContent") &&
          m.name.includes("gemini")
        )
        .map((m) => m.name.replace("models/", ""));

      if (chatModels.length === 0) return this.config.models;

      // Resolve "latest" or "auto" entries
      const resolved: string[] = [];
      for (const configModel of this.config.models) {
        if (configModel === "latest" || configModel === "auto") {
          const best = this.pickBestModel(chatModels);
          if (best && !resolved.includes(best)) resolved.push(best);
        } else if (configModel.endsWith(":latest")) {
          const family = configModel.replace(":latest", "");
          const match = chatModels.find((m) => m.startsWith(family));
          resolved.push(match || family);
        } else {
          resolved.push(configModel);
        }
      }

      if (resolved.length === 0) {
        const best = this.pickBestModel(chatModels);
        if (best) resolved.push(best);
        const fallback = chatModels.find((m) => m.includes("flash"));
        if (fallback && !resolved.includes(fallback)) resolved.push(fallback);
      }

      console.log(`  ✓ Gemini models resolved: ${resolved.join(", ")}`);
      return resolved.length > 0 ? resolved : this.config.models;
    } catch {
      return this.config.models;
    }
  }

  private pickBestModel(available: string[]): string | undefined {
    for (const pref of GEMINI_MODEL_PREFERENCE) {
      const match = available.find((m) => m.startsWith(pref));
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
        "⚠ Gemini API key not configured — returning placeholder output. " +
        "Set GOOGLE_API_KEY or GEMINI_API_KEY in .env.local for real results."
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

        if (
          errorMsg.includes("429") ||
          errorMsg.includes("500") ||
          errorMsg.includes("503") ||
          errorMsg.includes("RESOURCE_EXHAUSTED") ||
          errorMsg.includes("network") ||
          errorMsg.includes("ECONNREFUSED")
        ) {
          console.warn(
            `  ⚠ Model ${model} failed: ${errorMsg.slice(0, 100)}. Trying fallback...`
          );
          continue;
        }

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

        const isRetryable =
          errorMsg.includes("429") ||
          errorMsg.includes("500") ||
          errorMsg.includes("503") ||
          errorMsg.includes("RESOURCE_EXHAUSTED");

        if (!isRetryable || attempt >= MAX_RETRIES) {
          throw e;
        }

        const delay = RETRY_DELAYS_MS[attempt] || 4000;
        console.log(
          `  ↻ Gemini rate limited, retry ${attempt + 1}/${MAX_RETRIES} in ${delay / 1000}s...`
        );
        await new Promise((r) => setTimeout(r, delay));
      }
    }

    throw lastError || new Error("Retry loop exhausted");
  }

  /**
   * Call a specific model on the Gemini generateContent API.
   */
  private async callModel(
    model: string,
    request: CompletionRequest
  ): Promise<CompletionResponse> {
    // Map messages to Gemini format
    const contents: GeminiContent[] = [];

    for (const msg of request.messages) {
      if (msg.role === "system") continue; // Handled via systemInstruction

      contents.push({
        role: msg.role === "assistant" ? "model" : "user",
        parts: [{ text: msg.content }],
      });
    }

    // Ensure contents is not empty — Gemini requires at least one content entry
    if (contents.length === 0) {
      contents.push({
        role: "user",
        parts: [{ text: "Please proceed with the task described in the system instructions." }],
      });
    }

    // Build the request body
    const body: Record<string, unknown> = {
      contents,
      // Safety settings — set all to BLOCK_NONE for agent use
      safetySettings: SAFETY_CATEGORIES.map((category) => ({
        category,
        threshold: "BLOCK_NONE",
      })),
      generationConfig: {
        maxOutputTokens: Math.min(
          request.maxTokens || 4096,
          this.config.max_output_tokens
        ),
      },
    };

    // Add system instruction if provided
    if (request.systemPrompt) {
      body["systemInstruction"] = {
        parts: [{ text: request.systemPrompt }],
      };
    }

    // Add temperature if specified
    if (request.temperature !== undefined) {
      (body["generationConfig"] as Record<string, unknown>)["temperature"] =
        request.temperature;
    }

    // JSON mode — use responseMimeType
    if (request.jsonMode && this.config.capabilities.supports_json_mode) {
      (body["generationConfig"] as Record<string, unknown>)["responseMimeType"] =
        "application/json";
    }

    const url = `${this.baseUrl}/models/${model}:generateContent?key=${this.apiKey}`;

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
      signal: request.abortSignal,
    });

    if (response.status === 429) {
      throw new Error(`Rate limited on ${model} (429 RESOURCE_EXHAUSTED)`);
    }

    if (!response.ok) {
      const errorText = await response.text();
      let errorMessage: string;
      try {
        const errorBody = JSON.parse(errorText) as GeminiErrorResponse;
        errorMessage = errorBody.error?.message || errorText;
      } catch {
        errorMessage = errorText;
      }
      throw new Error(
        `Gemini API error on ${model} (${response.status}): ${errorMessage.slice(0, 200)}`
      );
    }

    const data = (await response.json()) as GeminiResponse;

    // Check for blocked responses
    if (data.promptFeedback?.blockReason) {
      throw new Error(
        `Gemini blocked prompt: ${data.promptFeedback.blockReason}`
      );
    }

    if (!data.candidates || data.candidates.length === 0) {
      throw new Error(
        "Gemini returned no candidates — the prompt may have been blocked by safety filters"
      );
    }

    const candidate = data.candidates[0]!;
    const text =
      candidate.content?.parts?.map((p) => p.text).join("") || "";

    // Token usage from usageMetadata
    const hasUsage =
      data.usageMetadata && data.usageMetadata.totalTokenCount > 0;
    const tokensUsed = hasUsage
      ? data.usageMetadata!.totalTokenCount
      : approximateTokenCount(request.systemPrompt + text);

    return {
      text,
      tokens_used: tokensUsed,
      model_used: model,
      usage: hasUsage
        ? {
            input_tokens: data.usageMetadata!.promptTokenCount,
            output_tokens: data.usageMetadata!.candidatesTokenCount,
          }
        : undefined,
    };
  }

  /**
   * Health check — try listing models to verify the API key works.
   */
  async healthCheck(): Promise<HealthCheckResult> {
    if (!this.isConfigured()) {
      return {
        healthy: false,
        error:
          "API key not configured. Set GOOGLE_API_KEY or GEMINI_API_KEY in .env.local",
      };
    }

    const startTime = Date.now();

    try {
      const response = await fetch(
        `${this.baseUrl}/models?key=${this.apiKey}`,
        {
          method: "GET",
          signal: AbortSignal.timeout(10000),
        }
      );

      const latency = Date.now() - startTime;

      if (response.ok) {
        return {
          healthy: true,
          latency_ms: latency,
          model_name: this.config.models[0],
          provider_version: "Gemini API v1beta",
        };
      }

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
    // Gemini models have large context windows; reserve 500 tokens for overhead
    return this.config.max_context_window - 500;
  }

  /**
   * Generate a structured placeholder when no API key is set.
   */
  private generatePlaceholder(request: CompletionRequest): string {
    const roleMatch = request.systemPrompt.match(
      /You are (?:a |an |the )?(.+?)\./
    );
    const role = roleMatch
      ? roleMatch[1] ?? "Specialist Agent"
      : "Specialist Agent";

    return `# Output from ${role}

> **Note**: This is a placeholder output. Set GOOGLE_API_KEY or GEMINI_API_KEY in .env.local to get real AI-generated results.
> Provider: Google Gemini (${this.config.models[0] || "not configured"})

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
