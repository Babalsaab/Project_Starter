/**
 * Runtime Configuration Loader
 *
 * Loads globals.yaml and makes ALL config values available to the executor
 * at runtime. Inspired by OpenClaw's centralized config consumption.
 *
 * Previously globals.yaml was defined but never consumed — token policies,
 * stop conditions, routing hints, brand voice were all dead config.
 * This module wires everything to the runtime.
 */

import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface TokenPolicy {
  max_total_tokens: number;
  max_steps: number;
  max_parallel_agents: number;
  per_agent_soft_limit: number;
  summarization_aggressiveness: "low" | "medium" | "high";
}

export interface StopConditions {
  max_failed_tasks: number;
  max_retries_per_task: number;
  abort_on_token_exhaustion: boolean;
}

export interface SummaryPresets {
  short: number;
  medium: number;
  long: number;
}

export interface BrandVoice {
  tone_keywords: string[];
  do: string[];
  dont: string[];
}

export interface BrandProfile {
  name: string;
  description: string;
  category: string;
  primary_markets: string[];
  mission: string;
}

export interface RoutingPolicy {
  primary_domains: Record<string, string[]>;
  classification_hints: Record<string, string>;
}

export interface ArtifactStoreConfig {
  provider: "local" | "s3" | "gdrive" | "postgres";
  base_path: string;
}

export interface GlobalConfig {
  schema_version: string;
  globals: {
    brand_profile: BrandProfile;
    brand_voice: BrandVoice;
    constraints: {
      legal_regulatory_notes: string;
      content_restrictions: string[];
      safety_policies_ref: string;
    };
    token_policy_defaults: TokenPolicy;
    artifact_store: ArtifactStoreConfig;
    routing_policy: RoutingPolicy;
    summary_presets: SummaryPresets;
    stop_conditions: StopConditions;
  };
}

// ─── Singleton Loader ─────────────────────────────────────────────────────────

let _configCache: GlobalConfig | null = null;

export function loadGlobalConfig(): GlobalConfig {
  if (_configCache) return _configCache;

  const configPath = path.join(__dirname, "../config/globals.yaml");
  if (!fs.existsSync(configPath)) {
    console.warn("⚠ config/globals.yaml not found — using defaults");
    return getDefaultConfig();
  }

  try {
    _configCache = yaml.load(
      fs.readFileSync(configPath, "utf-8")
    ) as GlobalConfig;
    return _configCache;
  } catch (e) {
    console.warn(`⚠ Failed to parse globals.yaml: ${(e as Error).message}`);
    return getDefaultConfig();
  }
}

/** Force reload (useful in tests or after config update) */
export function reloadGlobalConfig(): GlobalConfig {
  _configCache = null;
  return loadGlobalConfig();
}

// ─── Convenience Accessors ────────────────────────────────────────────────────

export function getTokenPolicy(): TokenPolicy {
  return loadGlobalConfig().globals.token_policy_defaults;
}

export function getStopConditions(): StopConditions {
  return loadGlobalConfig().globals.stop_conditions;
}

export function getSummaryPresets(): SummaryPresets {
  return loadGlobalConfig().globals.summary_presets;
}

export function getBrandVoice(): BrandVoice {
  return loadGlobalConfig().globals.brand_voice;
}

export function getBrandProfile(): BrandProfile {
  return loadGlobalConfig().globals.brand_profile;
}

export function getRoutingPolicy(): RoutingPolicy {
  return loadGlobalConfig().globals.routing_policy;
}

// ─── Default Config ───────────────────────────────────────────────────────────

function getDefaultConfig(): GlobalConfig {
  return {
    schema_version: "2.0.0",
    globals: {
      brand_profile: {
        name: "",
        description: "",
        category: "",
        primary_markets: [],
        mission: "",
      },
      brand_voice: {
        tone_keywords: [],
        do: ["Use active voice", "Lead with the benefit", "Be specific"],
        dont: ["Never use jargon", "Avoid passive voice", "No hyperbole"],
      },
      constraints: {
        legal_regulatory_notes: "",
        content_restrictions: [],
        safety_policies_ref: "",
      },
      token_policy_defaults: {
        max_total_tokens: 32000,
        max_steps: 16,
        max_parallel_agents: 4,
        per_agent_soft_limit: 2000,
        summarization_aggressiveness: "medium",
      },
      artifact_store: {
        provider: "local",
        base_path: "./runs/artifacts",
      },
      routing_policy: {
        primary_domains: {
          marketing: ["CMO"],
          tech: ["CTO"],
          full_product: ["CTO", "CMO"],
        },
        classification_hints: {},
      },
      summary_presets: { short: 150, medium: 400, long: 800 },
      stop_conditions: {
        max_failed_tasks: 3,
        max_retries_per_task: 2,
        abort_on_token_exhaustion: true,
      },
    },
  };
}
