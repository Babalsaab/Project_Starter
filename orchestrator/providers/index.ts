/**
 * Provider Registry & Factory
 *
 * - Loads provider configs from globals.yaml
 * - Instantiates the correct provider class per config type
 * - Routes agents to providers based on capability requirements
 * - Supports hybrid mode (different agents → different providers)
 * - Handles retry wrapping at the registry level
 */

import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";
import type {
  LLMProvider,
  ProviderConfig,
  CompletionRequest,
  CompletionResponse,
  CapabilityRequirement,
  HealthCheckResult,
} from "./base";
import { meetsRequirements } from "./base";
import { AnthropicProvider } from "./anthropic";
import { OpenAIProvider } from "./openai";
import { GeminiProvider } from "./gemini";
import { BedrockProvider } from "./bedrock";
import { OpenAICompatibleProvider } from "./openai-compatible";
import { ManualProvider } from "./manual";

// ─── Default Provider Configs ─────────────────────────────────────────────────

/**
 * Built-in provider configs used when globals.yaml doesn't define any.
 * This preserves backward compatibility — existing users just set
 * ANTHROPIC_API_KEY and everything works as before.
 */
const DEFAULT_PROVIDERS: ProviderConfig[] = [
  {
    id: "anthropic",
    name: "Anthropic Claude",
    type: "anthropic",
    base_url: "https://api.anthropic.com",
    api_key_env: "ANTHROPIC_API_KEY",
    models: ["claude-sonnet-4-20250514", "claude-haiku-35-20241022"],
    max_context_window: 200000,
    max_output_tokens: 8192,
    capabilities: {
      code_generation: "advanced",
      analysis: "advanced",
      creative_writing: "advanced",
      structured_output: "advanced",
      max_context_window: 200000,
      max_output_tokens: 8192,
      supports_system_prompt: true,
      supports_streaming: true,
      supports_json_mode: true,
    },
    enabled: true,
    priority: 1,
    quality_threshold: 1.0,
  },
];

// ─── Registry ─────────────────────────────────────────────────────────────────

export class ProviderRegistry {
  private providers: Map<string, LLMProvider> = new Map();
  private configs: ProviderConfig[] = [];
  private agentOverrides: Map<string, string> = new Map();

  /**
   * Initialize the registry from globals.yaml or defaults.
   */
  async initialize(globalsPath?: string): Promise<void> {
    this.configs = this.loadConfigs(globalsPath);

    for (const config of this.configs) {
      if (!config.enabled) continue;
      const provider = this.createProvider(config);
      this.providers.set(config.id, provider);
    }
  }

  /**
   * Load provider configs from globals.yaml.
   * Falls back to defaults if no providers section exists.
   */
  private loadConfigs(globalsPath?: string): ProviderConfig[] {
    const configPath =
      globalsPath || path.resolve("config/globals.yaml");

    if (!fs.existsSync(configPath)) {
      return [...DEFAULT_PROVIDERS];
    }

    try {
      const raw = fs.readFileSync(configPath, "utf-8");
      const parsed = yaml.load(raw) as Record<string, unknown>;
      const globals = (parsed?.['globals'] || parsed) as Record<string, unknown>;
      const providersRaw = globals?.['providers'] as ProviderConfig[] | undefined;

      if (!providersRaw || !Array.isArray(providersRaw) || providersRaw.length === 0) {
        return [...DEFAULT_PROVIDERS];
      }

      // Validate and normalize each config
      return providersRaw.map((p) => this.normalizeConfig(p));
    } catch {
      console.warn("  ⚠ Failed to load providers from globals.yaml, using defaults");
      return [...DEFAULT_PROVIDERS];
    }
  }

  /**
   * Normalize a raw provider config — fill in defaults for missing fields.
   */
  private normalizeConfig(raw: Partial<ProviderConfig>): ProviderConfig {
    return {
      id: raw.id || "unknown",
      name: raw.name || raw.id || "Unknown Provider",
      type: raw.type || "anthropic",
      base_url: raw.base_url,
      api_key: raw.api_key,
      api_key_env: raw.api_key_env,
      models: raw.models || [],
      max_context_window: raw.max_context_window || 4096,
      max_output_tokens: raw.max_output_tokens || 2048,
      capabilities: raw.capabilities || {
        code_generation: "basic",
        analysis: "basic",
        creative_writing: "basic",
        structured_output: "basic",
        max_context_window: raw.max_context_window || 4096,
        max_output_tokens: raw.max_output_tokens || 2048,
        supports_system_prompt: true,
        supports_streaming: false,
        supports_json_mode: false,
      },
      enabled: raw.enabled !== false,
      priority: raw.priority || 10,
      quality_threshold: raw.quality_threshold || 1.0,
      queue_dir: raw.queue_dir,
      manual_timeout_ms: raw.manual_timeout_ms,
      poll_interval_ms: raw.poll_interval_ms,
    };
  }

  /**
   * Create a provider instance from config.
   */
  private createProvider(config: ProviderConfig): LLMProvider {
    switch (config.type) {
      case "anthropic":
        return new AnthropicProvider(config);
      case "openai":
        return new OpenAIProvider(config);
      case "gemini":
        return new GeminiProvider(config);
      case "bedrock":
        return new BedrockProvider(config);
      case "openai-compatible":
        return new OpenAICompatibleProvider(config);
      case "manual":
        return new ManualProvider(config);
      default:
        throw new Error(`Unknown provider type: ${config.type}`);
    }
  }

  /**
   * Set per-agent provider overrides.
   * Used for hybrid mode: { "qa_engineer": "anthropic", "web_frontend_engineer": "manual" }
   */
  setAgentOverrides(overrides: Record<string, string>): void {
    for (const [agent, provider] of Object.entries(overrides)) {
      this.agentOverrides.set(agent, provider);
    }
  }

  /**
   * Get the best provider for a given agent.
   *
   * Priority:
   *  1. Explicit agent override (from hybrid mode config)
   *  2. Best-matching provider based on agent capabilities
   *  3. Highest-priority enabled provider (fallback)
   */
  getProviderForAgent(
    agentId: string,
    requirements?: CapabilityRequirement
  ): LLMProvider {
    // 1. Check for explicit override
    const overrideId = this.agentOverrides.get(agentId);
    if (overrideId) {
      const provider = this.providers.get(overrideId);
      if (provider) return provider;
      console.warn(
        `  ⚠ Override provider "${overrideId}" for agent "${agentId}" not found, using auto-routing`
      );
    }

    // 2. If requirements specified, find best matching provider
    if (requirements) {
      const matching = Array.from(this.providers.values())
        .filter((p) => meetsRequirements(p.getCapabilities(), requirements))
        .sort((a, b) => a.config.priority - b.config.priority);

      if (matching.length > 0) return matching[0]!;
    }

    // 3. Fallback to highest-priority enabled provider
    const sorted = Array.from(this.providers.values()).sort(
      (a, b) => a.config.priority - b.config.priority
    );

    if (sorted.length === 0) {
      throw new Error("No providers available. Configure at least one provider in globals.yaml");
    }

    return sorted[0]!;
  }

  /**
   * Get a specific provider by ID.
   */
  getProvider(id: string): LLMProvider | undefined {
    return this.providers.get(id);
  }

  /**
   * Get the default (highest priority) provider.
   */
  getDefaultProvider(): LLMProvider {
    const sorted = Array.from(this.providers.values()).sort(
      (a, b) => a.config.priority - b.config.priority
    );
    if (sorted.length === 0) {
      throw new Error("No providers available");
    }
    return sorted[0]!;
  }

  /**
   * Get the best available provider — checks API key / credential availability
   * and returns the highest-priority provider that is actually usable.
   *
   * This differs from getDefaultProvider() which returns the highest-priority
   * registered provider regardless of whether its credentials are configured.
   *
   * Uses health checks to verify each provider, sorted by priority.
   */
  async getBestAvailable(): Promise<LLMProvider> {
    const sorted = Array.from(this.providers.values()).sort(
      (a, b) => a.config.priority - b.config.priority
    );

    for (const provider of sorted) {
      try {
        const health = await provider.healthCheck();
        if (health.healthy) {
          return provider;
        }
      } catch {
        // Provider not available, try next
        continue;
      }
    }

    // If no provider passed health check, fall back to highest priority
    // (it will return a placeholder if unconfigured)
    if (sorted.length > 0) {
      return sorted[0]!;
    }

    throw new Error(
      "No providers available. Configure at least one provider in globals.yaml " +
      "and set the corresponding API key environment variable."
    );
  }

  /**
   * Complete with retry wrapper.
   * Implements exponential backoff, respects maxRetries.
   */
  async completeWithRetry(
    provider: LLMProvider,
    request: CompletionRequest,
    maxRetries: number
  ): Promise<CompletionResponse & { retries: number }> {
    let retries = 0;

    while (true) {
      try {
        const result = await provider.complete(request);
        return { ...result, retries };
      } catch (e) {
        retries++;
        if (retries > maxRetries) {
          throw e;
        }
        const backoff = Math.min(1000 * Math.pow(2, retries - 1), 30000);
        console.log(
          `  ↻ Retry ${retries}/${maxRetries} in ${backoff / 1000}s...`
        );
        await new Promise((r) => setTimeout(r, backoff));
      }
    }
  }

  /**
   * Run health checks on all enabled providers.
   */
  async healthCheckAll(): Promise<
    Array<{ id: string; name: string; result: HealthCheckResult }>
  > {
    const results: Array<{
      id: string;
      name: string;
      result: HealthCheckResult;
    }> = [];

    for (const [id, provider] of this.providers) {
      try {
        const result = await provider.healthCheck();
        results.push({ id, name: provider.config.name, result });
      } catch (e) {
        results.push({
          id,
          name: provider.config.name,
          result: {
            healthy: false,
            error: (e as Error).message,
          },
        });
      }
    }

    return results;
  }

  /**
   * List all registered providers.
   */
  listProviders(): Array<{
    id: string;
    name: string;
    type: string;
    priority: number;
    enabled: boolean;
    models: string[];
  }> {
    return this.configs.map((c) => ({
      id: c.id,
      name: c.name,
      type: c.type,
      priority: c.priority,
      enabled: c.enabled,
      models: c.models,
    }));
  }

  /**
   * Get quality threshold for a provider.
   * Used to adjust quality gate scoring for weaker models.
   */
  getQualityThreshold(providerId: string): number {
    const config = this.configs.find((c) => c.id === providerId);
    return config?.quality_threshold || 1.0;
  }

  /**
   * Check if we have any configured and enabled providers.
   */
  hasProviders(): boolean {
    return this.providers.size > 0;
  }

  /**
   * Get a summary string for logging.
   */
  getSummary(): string {
    const providers = Array.from(this.providers.values());
    return providers
      .map(
        (p) =>
          `${p.config.name} (${p.config.type}, priority=${p.config.priority}, models=[${p.config.models.join(",")}])`
      )
      .join("\n    ");
  }
}

// ─── Singleton & Convenience ──────────────────────────────────────────────────

let _registry: ProviderRegistry | null = null;

/**
 * Get or create the global provider registry.
 * Initializes from globals.yaml on first call.
 */
export async function getProviderRegistry(
  globalsPath?: string
): Promise<ProviderRegistry> {
  if (!_registry) {
    _registry = new ProviderRegistry();
    await _registry.initialize(globalsPath);
  }
  return _registry;
}

/**
 * Reset the global registry (for testing or re-initialization).
 */
export function resetProviderRegistry(): void {
  _registry = null;
}
