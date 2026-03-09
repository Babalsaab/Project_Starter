/**
 * AWS Bedrock Provider for Vibecoded Orchestrator
 *
 * Supports Claude, Llama, and Mistral model families on AWS Bedrock.
 * Uses AWS Signature V4 signing with fetch API — no heavy SDK dependency.
 *
 * Model resolution strategy:
 *   1. If config specifies exact model IDs → use those
 *   2. If config uses "latest" or "auto" → query Bedrock foundation models endpoint
 *   3. Falls back to known-good defaults if discovery fails
 *
 * Key features:
 *   - Dynamic model discovery via Bedrock ListFoundationModels
 *   - AWS Signature V4 signing (HMAC-SHA256 via Node.js crypto)
 *   - Supports Claude, Llama, and Mistral model families
 *   - Reads credentials from AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
 */

import * as crypto from "crypto";
import type {
  LLMProvider,
  ProviderConfig,
  CompletionRequest,
  CompletionResponse,
  HealthCheckResult,
  ModelCapabilities,
} from "./base";
import { approximateTokenCount } from "./base";

// ─── Bedrock API Types ──────────────────────────────────────────────────────

/** Bedrock Converse API message format (unified across model families) */
interface BedrockMessage {
  role: "user" | "assistant";
  content: Array<{ text: string }>;
}

/** Bedrock Converse API response */
interface BedrockConverseResponse {
  output: {
    message: {
      role: string;
      content: Array<{ text: string }>;
    };
  };
  stopReason: string;
  usage: {
    inputTokens: number;
    outputTokens: number;
    totalTokens: number;
  };
  metrics?: {
    latencyMs: number;
  };
}

interface BedrockErrorResponse {
  message: string;
  __type?: string;
}

// ─── AWS Signature V4 Types ─────────────────────────────────────────────────

interface AWSCredentials {
  accessKeyId: string;
  secretAccessKey: string;
  sessionToken?: string;
  region: string;
}

// ─── Model Discovery & Resolution ───────────────────────────────────────────

/** Preferred Bedrock model families in priority order (newest first) */
const BEDROCK_MODEL_PREFERENCE = [
  // Claude (newest first)
  "anthropic.claude-opus-4", "anthropic.claude-sonnet-4",
  "anthropic.claude-3-7-sonnet", "anthropic.claude-3-5-sonnet",
  "anthropic.claude-3-5-haiku", "anthropic.claude-3-haiku",
  // Meta Llama (newest first)
  "meta.llama4", "meta.llama3-3", "meta.llama3-1",
  // Mistral (newest first)
  "mistral.mistral-large", "mistral.mistral-small",
];

// ─── Rate Limit / Retry Config ──────────────────────────────────────────────

const MAX_RETRIES = 3;
const RETRY_DELAYS_MS = [1000, 2000, 4000];

// ─── Provider Implementation ────────────────────────────────────────────────

export class BedrockProvider implements LLMProvider {
  readonly config: ProviderConfig;
  private credentials: AWSCredentials;
  private baseUrl: string;
  private resolvedModels: string[] | null = null;
  private modelDiscoveryPromise: Promise<string[]> | null = null;

  constructor(config: ProviderConfig) {
    this.config = config;

    // Resolve AWS credentials from config or environment
    this.credentials = {
      accessKeyId:
        process.env["AWS_ACCESS_KEY_ID"] || "",
      secretAccessKey:
        process.env["AWS_SECRET_ACCESS_KEY"] || "",
      sessionToken:
        process.env["AWS_SESSION_TOKEN"] || undefined,
      region:
        process.env["AWS_REGION"] ||
        process.env["AWS_DEFAULT_REGION"] ||
        "us-east-1",
    };

    this.baseUrl =
      config.base_url ||
      `https://bedrock-runtime.${this.credentials.region}.amazonaws.com`;
  }

  /**
   * Check if AWS credentials are configured.
   */
  private isConfigured(): boolean {
    return (
      !!this.credentials.accessKeyId &&
      !!this.credentials.secretAccessKey &&
      this.credentials.accessKeyId !== "AKIA..."
    );
  }

  /**
   * Discover available models from AWS Bedrock.
   * Queries the Bedrock control plane (not runtime) to list foundation models.
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

    // Check if any config model uses "latest" or "auto"
    const needsDiscovery = this.config.models.some(
      (m) => m === "latest" || m === "auto" || m.endsWith(":latest")
    );
    if (!needsDiscovery) return this.config.models;

    try {
      // Query the Bedrock control plane for available models
      const controlUrl = `https://bedrock.${this.credentials.region}.amazonaws.com`;
      const apiPath = "/foundation-models";
      const url = `${controlUrl}${apiPath}`;

      const headers = await this.signRequest("GET", url, apiPath, "", {
        Accept: "application/json",
      });

      const response = await fetch(url, {
        method: "GET",
        headers,
        signal: AbortSignal.timeout(10000),
      });

      if (!response.ok) return this.config.models;

      const data = (await response.json()) as {
        modelSummaries: Array<{ modelId: string; modelName: string }>;
      };

      const available = data.modelSummaries.map((m) => m.modelId);

      const resolved: string[] = [];
      for (const configModel of this.config.models) {
        if (configModel === "latest" || configModel === "auto") {
          const best = this.pickBestModel(available);
          if (best && !resolved.includes(best)) resolved.push(best);
        } else if (configModel.endsWith(":latest")) {
          const family = configModel.replace(":latest", "");
          const match = available.find((m) => m.startsWith(family));
          resolved.push(match || family);
        } else {
          resolved.push(configModel);
        }
      }

      console.log(`  ✓ Bedrock models resolved: ${resolved.join(", ")}`);
      return resolved.length > 0 ? resolved : this.config.models;
    } catch {
      return this.config.models;
    }
  }

  private pickBestModel(available: string[]): string | undefined {
    for (const pref of BEDROCK_MODEL_PREFERENCE) {
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
        "⚠ AWS Bedrock credentials not configured — returning placeholder output. " +
        "Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in .env.local for real results."
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
          errorMsg.includes("ThrottlingException") ||
          errorMsg.includes("429") ||
          errorMsg.includes("500") ||
          errorMsg.includes("503") ||
          errorMsg.includes("ServiceUnavailableException") ||
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
   * Call a specific model with exponential backoff on throttle errors.
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
          errorMsg.includes("ThrottlingException") ||
          errorMsg.includes("429") ||
          errorMsg.includes("500") ||
          errorMsg.includes("503") ||
          errorMsg.includes("ServiceUnavailableException");

        if (!isRetryable || attempt >= MAX_RETRIES) {
          throw e;
        }

        const delay = RETRY_DELAYS_MS[attempt] || 4000;
        console.log(
          `  ↻ Bedrock throttled, retry ${attempt + 1}/${MAX_RETRIES} in ${delay / 1000}s...`
        );
        await new Promise((r) => setTimeout(r, delay));
      }
    }

    throw lastError || new Error("Retry loop exhausted");
  }

  /**
   * Call a specific model on Bedrock using the Converse API.
   * The Converse API provides a unified interface across all model families
   * (Claude, Llama, Mistral) on Bedrock.
   */
  private async callModel(
    model: string,
    request: CompletionRequest
  ): Promise<CompletionResponse> {
    // Map messages to Bedrock Converse format
    const messages: BedrockMessage[] = [];

    for (const msg of request.messages) {
      if (msg.role === "system") continue; // Handled via system param

      messages.push({
        role: msg.role as "user" | "assistant",
        content: [{ text: msg.content }],
      });
    }

    // Ensure at least one message
    if (messages.length === 0) {
      messages.push({
        role: "user",
        content: [{ text: "Please proceed with the task described in the system instructions." }],
      });
    }

    const maxTokens = Math.min(
      request.maxTokens || 4096,
      this.config.max_output_tokens
    );

    // Build request body using the Converse API format
    const body: Record<string, unknown> = {
      modelId: model,
      messages,
      inferenceConfig: {
        maxTokens,
      },
    };

    // System prompt — Converse API supports it as a top-level system array
    if (request.systemPrompt) {
      body["system"] = [{ text: request.systemPrompt }];
    }

    if (request.temperature !== undefined) {
      (body["inferenceConfig"] as Record<string, unknown>)["temperature"] =
        request.temperature;
    }

    // Use the Converse API endpoint
    const apiPath = `/model/${encodeURIComponent(model)}/converse`;
    const url = `${this.baseUrl}${apiPath}`;
    const bodyStr = JSON.stringify(body);

    // Sign the request with AWS Signature V4
    const headers = await this.signRequest(
      "POST",
      url,
      apiPath,
      bodyStr,
      {
        "Content-Type": "application/json",
        Accept: "application/json",
      }
    );

    const response = await fetch(url, {
      method: "POST",
      headers,
      body: bodyStr,
      signal: request.abortSignal,
    });

    if (response.status === 429) {
      throw new Error(
        `ThrottlingException on ${model} (429) — request rate exceeded`
      );
    }

    if (!response.ok) {
      const errorText = await response.text();
      let errorMessage: string;
      try {
        const errorBody = JSON.parse(errorText) as BedrockErrorResponse;
        errorMessage = errorBody.message || errorText;
      } catch {
        errorMessage = errorText;
      }
      throw new Error(
        `Bedrock API error on ${model} (${response.status}): ${errorMessage.slice(0, 200)}`
      );
    }

    const data = (await response.json()) as BedrockConverseResponse;
    const text =
      data.output?.message?.content?.map((c) => c.text).join("") || "";

    const hasUsage = data.usage && data.usage.totalTokens > 0;
    const tokensUsed = hasUsage
      ? data.usage.totalTokens
      : approximateTokenCount(request.systemPrompt + text);

    return {
      text,
      tokens_used: tokensUsed,
      model_used: model,
      usage: hasUsage
        ? {
            input_tokens: data.usage.inputTokens,
            output_tokens: data.usage.outputTokens,
          }
        : undefined,
    };
  }

  // ─── AWS Signature V4 Signing ─────────────────────────────────────────────

  /**
   * Sign an HTTP request with AWS Signature V4.
   * Implements the signing algorithm using Node.js crypto module.
   */
  private async signRequest(
    method: string,
    url: string,
    path: string,
    body: string,
    additionalHeaders: Record<string, string>
  ): Promise<Record<string, string>> {
    const now = new Date();
    const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, "");
    const dateStamp = amzDate.slice(0, 8);
    const service = "bedrock";
    const region = this.credentials.region;

    // Parse host from URL
    const parsedUrl = new URL(url);
    const host = parsedUrl.host;

    // Create canonical headers
    const headers: Record<string, string> = {
      ...additionalHeaders,
      host,
      "x-amz-date": amzDate,
    };

    // Add session token if present (for temporary credentials)
    if (this.credentials.sessionToken) {
      headers["x-amz-security-token"] = this.credentials.sessionToken;
    }

    // Sorted header keys for canonical request
    const signedHeaderKeys = Object.keys(headers)
      .map((k) => k.toLowerCase())
      .sort();
    const signedHeaders = signedHeaderKeys.join(";");

    // Canonical headers string
    const canonicalHeaders = signedHeaderKeys
      .map((k) => `${k}:${headers[Object.keys(headers).find((h) => h.toLowerCase() === k)!]!.trim()}`)
      .join("\n") + "\n";

    // Hash the payload
    const payloadHash = crypto
      .createHash("sha256")
      .update(body)
      .digest("hex");

    // Build canonical request
    const canonicalRequest = [
      method,
      path,
      "", // query string (empty for POST)
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join("\n");

    // Create string to sign
    const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
    const stringToSign = [
      "AWS4-HMAC-SHA256",
      amzDate,
      credentialScope,
      crypto.createHash("sha256").update(canonicalRequest).digest("hex"),
    ].join("\n");

    // Calculate signing key
    const signingKey = this.getSignatureKey(
      this.credentials.secretAccessKey,
      dateStamp,
      region,
      service
    );

    // Calculate signature
    const signature = crypto
      .createHmac("sha256", signingKey)
      .update(stringToSign)
      .digest("hex");

    // Build Authorization header
    const authorization =
      `AWS4-HMAC-SHA256 Credential=${this.credentials.accessKeyId}/${credentialScope}, ` +
      `SignedHeaders=${signedHeaders}, ` +
      `Signature=${signature}`;

    return {
      ...additionalHeaders,
      "x-amz-date": amzDate,
      Authorization: authorization,
      ...(this.credentials.sessionToken
        ? { "x-amz-security-token": this.credentials.sessionToken }
        : {}),
    };
  }

  /**
   * Derive the signing key using HMAC-SHA256 chain.
   */
  private getSignatureKey(
    key: string,
    dateStamp: string,
    region: string,
    service: string
  ): Buffer {
    const kDate = crypto
      .createHmac("sha256", `AWS4${key}`)
      .update(dateStamp)
      .digest();
    const kRegion = crypto
      .createHmac("sha256", kDate)
      .update(region)
      .digest();
    const kService = crypto
      .createHmac("sha256", kRegion)
      .update(service)
      .digest();
    const kSigning = crypto
      .createHmac("sha256", kService)
      .update("aws4_request")
      .digest();
    return kSigning;
  }

  // ─── Health Check ─────────────────────────────────────────────────────────

  /**
   * Health check — verify AWS credentials and Bedrock access.
   * Uses a minimal Converse call to verify connectivity.
   */
  async healthCheck(): Promise<HealthCheckResult> {
    if (!this.isConfigured()) {
      return {
        healthy: false,
        error:
          "AWS credentials not configured. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in .env.local",
      };
    }

    const startTime = Date.now();
    const models = this.resolvedModels || this.config.models;
    const model = models[0] || "anthropic.claude-sonnet-4-20250514-v1:0";

    try {
      // Use Converse with a minimal request to check connectivity
      const apiPath = `/model/${encodeURIComponent(model)}/converse`;
      const url = `${this.baseUrl}${apiPath}`;

      const body = JSON.stringify({
        modelId: model,
        messages: [
          {
            role: "user",
            content: [{ text: "ping" }],
          },
        ],
        inferenceConfig: {
          maxTokens: 5,
        },
      });

      const headers = await this.signRequest("POST", url, apiPath, body, {
        "Content-Type": "application/json",
        Accept: "application/json",
      });

      const response = await fetch(url, {
        method: "POST",
        headers,
        body,
        signal: AbortSignal.timeout(15000),
      });

      const latency = Date.now() - startTime;

      if (response.ok) {
        return {
          healthy: true,
          latency_ms: latency,
          model_name: model,
          provider_version: "AWS Bedrock Converse API",
        };
      }

      // 429 = throttled but reachable
      if (response.status === 429) {
        return {
          healthy: true,
          latency_ms: latency,
          model_name: model,
          error: "Throttled but reachable",
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
   * Generate a structured placeholder when no credentials are set.
   */
  private generatePlaceholder(request: CompletionRequest): string {
    const roleMatch = request.systemPrompt.match(
      /You are (?:a |an |the )?(.+?)\./
    );
    const role = roleMatch
      ? roleMatch[1] ?? "Specialist Agent"
      : "Specialist Agent";

    return `# Output from ${role}

> **Note**: This is a placeholder output. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in .env.local to get real AI-generated results.
> Provider: AWS Bedrock (${this.config.models[0] || "not configured"})

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
