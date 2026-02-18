/**
 * LLM Provider Abstraction Layer
 *
 * Defines the universal interface that all providers must implement.
 * This enables the executor to work with:
 *   - Anthropic Claude API (cloud)
 *   - OpenAI-compatible APIs (Ollama, LM Studio, llama.cpp, Jan.ai, vLLM)
 *   - Manual file-queue mode (Copilot, Claude Code, Antigravity — no API)
 *
 * Each provider handles its own auth, request format, and response parsing.
 * The executor only ever calls the `LLMProvider` interface.
 */

// ─── Capability Profiles ──────────────────────────────────────────────────────

/**
 * What a model can do — used for intelligent agent→model routing.
 * A small local model might only have { analysis: "basic" },
 * while Claude Opus has everything at "advanced".
 */
export interface ModelCapabilities {
  code_generation: "none" | "basic" | "advanced";
  analysis: "none" | "basic" | "advanced";
  creative_writing: "none" | "basic" | "advanced";
  structured_output: "none" | "basic" | "advanced";
  max_context_window: number;
  max_output_tokens: number;
  supports_system_prompt: boolean;
  supports_streaming: boolean;
  supports_json_mode: boolean;
}

/**
 * Capability requirements for an agent — used to match agents to providers.
 */
export interface CapabilityRequirement {
  min_code_generation?: "none" | "basic" | "advanced";
  min_analysis?: "none" | "basic" | "advanced";
  min_creative_writing?: "none" | "basic" | "advanced";
  min_structured_output?: "none" | "basic" | "advanced";
  min_context_window?: number;
}

// ─── Messages ─────────────────────────────────────────────────────────────────

export interface LLMMessage {
  role: "user" | "assistant" | "system";
  content: string;
}

// ─── Completion Request / Response ────────────────────────────────────────────

export interface CompletionRequest {
  systemPrompt: string;
  messages: LLMMessage[];
  maxTokens?: number;
  temperature?: number;
  /** If the provider supports JSON mode, enforce structured output */
  jsonMode?: boolean;
  /** Abort signal for cancellation */
  abortSignal?: AbortSignal;
}

export interface CompletionResponse {
  text: string;
  tokens_used: number;
  model_used: string;
  /** Provider-specific usage breakdown when available */
  usage?: {
    input_tokens: number;
    output_tokens: number;
    cache_read_tokens?: number;
    cache_write_tokens?: number;
  };
  /** Duration in ms for the request */
  latency_ms?: number;
  /** Whether this response came from a fallback model */
  is_fallback?: boolean;
}

// ─── Provider Configuration ───────────────────────────────────────────────────

export interface ProviderConfig {
  /** Unique provider name: "anthropic", "ollama", "lm-studio", "manual", etc. */
  id: string;
  /** Display name for logs */
  name: string;
  /** Provider type — determines which class to instantiate */
  type: "anthropic" | "openai-compatible" | "manual";
  /** Base URL for API calls (not used for manual) */
  base_url?: string;
  /** API key (optional for local models and manual) */
  api_key?: string;
  /** Environment variable name to read API key from (alternative to api_key) */
  api_key_env?: string;
  /** Model identifier(s) to use — first is primary, rest are fallbacks */
  models: string[];
  /** Max context window for this provider's models */
  max_context_window: number;
  /** Max output tokens per request */
  max_output_tokens: number;
  /** Capability profile for routing */
  capabilities: ModelCapabilities;
  /** Whether this provider is enabled */
  enabled: boolean;
  /** Priority for auto-selection (lower = preferred). 1 = highest priority */
  priority: number;
  /** Quality threshold multiplier (1.0 = normal, 0.7 = lenient for small models) */
  quality_threshold: number;

  // ─── Manual-mode specific ───
  /** Directory for instruction/response files (manual provider only) */
  queue_dir?: string;
  /** How long to wait for manual response before timing out (ms, 0 = infinite) */
  manual_timeout_ms?: number;
  /** Poll interval for checking response files (ms) */
  poll_interval_ms?: number;
}

// ─── Health Check ─────────────────────────────────────────────────────────────

export interface HealthCheckResult {
  healthy: boolean;
  latency_ms?: number;
  error?: string;
  model_name?: string;
  provider_version?: string;
}

// ─── The Interface ────────────────────────────────────────────────────────────

/**
 * Universal LLM Provider interface.
 *
 * Every provider (Anthropic, Ollama, manual file-queue) implements this.
 * The executor ONLY interacts through this interface — never calls
 * provider-specific APIs directly.
 */
export interface LLMProvider {
  /** Provider config */
  readonly config: ProviderConfig;

  /**
   * Send a completion request and get a response.
   * Handles auth, formatting, retries, and failover internally.
   */
  complete(request: CompletionRequest): Promise<CompletionResponse>;

  /**
   * Check if the provider is reachable and ready.
   * For cloud APIs: ping the API endpoint.
   * For local models: check if the server is running.
   * For manual: check if the queue directory exists.
   */
  healthCheck(): Promise<HealthCheckResult>;

  /**
   * Get the capability profile for this provider.
   * Used by the executor to route agents to appropriate providers.
   */
  getCapabilities(): ModelCapabilities;

  /**
   * Estimate token count for a string.
   * Cloud APIs use exact counting; local models use approximation.
   */
  estimateTokens(text: string): number;

  /**
   * Get the effective max context window after accounting for system prompt overhead.
   */
  getEffectiveContextWindow(): number;
}

// ─── Utility: Capability Matching ─────────────────────────────────────────────

const CAPABILITY_LEVELS = { none: 0, basic: 1, advanced: 2 };

/**
 * Check if a provider meets the minimum capability requirements for an agent.
 */
export function meetsRequirements(
  capabilities: ModelCapabilities,
  requirements: CapabilityRequirement
): boolean {
  if (
    requirements.min_code_generation &&
    CAPABILITY_LEVELS[capabilities.code_generation] <
      CAPABILITY_LEVELS[requirements.min_code_generation]
  ) {
    return false;
  }
  if (
    requirements.min_analysis &&
    CAPABILITY_LEVELS[capabilities.analysis] <
      CAPABILITY_LEVELS[requirements.min_analysis]
  ) {
    return false;
  }
  if (
    requirements.min_creative_writing &&
    CAPABILITY_LEVELS[capabilities.creative_writing] <
      CAPABILITY_LEVELS[requirements.min_creative_writing]
  ) {
    return false;
  }
  if (
    requirements.min_structured_output &&
    CAPABILITY_LEVELS[capabilities.structured_output] <
      CAPABILITY_LEVELS[requirements.min_structured_output]
  ) {
    return false;
  }
  if (
    requirements.min_context_window &&
    capabilities.max_context_window < requirements.min_context_window
  ) {
    return false;
  }
  return true;
}

// ─── Utility: Approximate Token Counter ───────────────────────────────────────

/**
 * Rough token estimation (~4 chars per token for English text).
 * Used as fallback when the provider doesn't report exact usage.
 */
export function approximateTokenCount(text: string): number {
  // ~4 chars per token is a reasonable approximation for English
  // Code tends to be ~3.5 chars per token due to shorter identifiers
  const charCount = text.length;
  const wordCount = text.split(/\s+/).length;
  // Blend character-based and word-based estimates
  return Math.ceil((charCount / 4 + wordCount * 1.3) / 2);
}

// ─── Utility: Context Trimming ────────────────────────────────────────────────

/**
 * Trim context to fit within a provider's context window.
 * Removes sections in priority order (lowest priority dropped first):
 *   1. Persona details (nice-to-have)
 *   2. Mentor quotes (nice-to-have)
 *   3. Upstream artifact details (compress further)
 *   4. PRD excerpt (shorten)
 *   5. Skills (keep structure, drop examples)
 *   6. System prompt + core instructions (never dropped)
 */
export function trimContextToFit(
  sections: { content: string; priority: number; label: string }[],
  maxTokens: number,
  estimateTokensFn: (text: string) => number = approximateTokenCount
): string {
  // Sort by priority descending (highest priority = keep)
  const sorted = [...sections].sort((a, b) => b.priority - a.priority);

  let totalTokens = sorted.reduce(
    (sum, s) => sum + estimateTokensFn(s.content),
    0
  );

  // Drop lowest-priority sections until we fit
  while (totalTokens > maxTokens && sorted.length > 1) {
    const dropped = sorted.pop()!;
    totalTokens -= estimateTokensFn(dropped.content);
  }

  // Re-sort by original priority for coherent output ordering
  sorted.sort((a, b) => a.priority - b.priority);

  return sorted.map((s) => s.content).join("\n\n");
}
