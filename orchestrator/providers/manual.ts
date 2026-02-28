/**
 * Manual File-Queue Provider
 *
 * Enables orchestration WITHOUT any LLM API by using a file-based queue.
 * Designed for users of Copilot, Claude Code, Antigravity, or any AI coder
 * that runs in an editor with no programmable API.
 *
 * Flow:
 *  1. Executor calls complete() → provider writes an instruction .md file
 *  2. User sees the instruction file → copies content into their AI coder
 *  3. User pastes the AI coder's response into a response .md file
 *  4. Provider detects the response file → returns it as CompletionResponse
 *
 * Queue directory structure:
 *   runs/queue/<project-id>/
 *     step-001-<agent-name>-instruction.md    ← written by provider
 *     step-001-<agent-name>-response.md       ← written by user
 *     step-002-<agent-name>-instruction.md
 *     step-002-<agent-name>-response.md
 *     ...
 *     _status.json                             ← progress tracking
 */

import * as fs from "fs";
import * as path from "path";
import type {
  LLMProvider,
  ProviderConfig,
  CompletionRequest,
  CompletionResponse,
  HealthCheckResult,
  ModelCapabilities,
} from "./base";
import { approximateTokenCount } from "./base";

// ─── Queue State ──────────────────────────────────────────────────────────────

interface QueueStatus {
  project_id: string;
  total_steps: number;
  completed_steps: number;
  current_step: number;
  steps: Array<{
    step_number: number;
    agent: string;
    status: "waiting" | "in-progress" | "completed" | "skipped";
    instruction_file: string;
    response_file: string;
    created_at: string;
    completed_at?: string;
  }>;
}

// ─── Provider Implementation ──────────────────────────────────────────────────

export class ManualProvider implements LLMProvider {
  readonly config: ProviderConfig;
  private queueDir: string;
  private pollInterval: number;
  private timeout: number;
  private stepCounter: number = 0;

  constructor(config: ProviderConfig) {
    this.config = config;
    this.queueDir = config.queue_dir || "./runs/queue";
    this.pollInterval = config.poll_interval_ms || 3000;
    this.timeout = config.manual_timeout_ms || 0; // 0 = infinite
  }

  /**
   * Write an instruction file and wait for the user to provide a response.
   */
  async complete(request: CompletionRequest): Promise<CompletionResponse> {
    this.stepCounter++;
    const startTime = Date.now();

    // Extract agent name from the system prompt or use generic
    const agentName = this.extractAgentName(request.systemPrompt);
    const stepNum = String(this.stepCounter).padStart(3, "0");

    // Ensure queue directory exists
    fs.mkdirSync(this.queueDir, { recursive: true });

    // Write the instruction file
    const instructionFile = path.join(
      this.queueDir,
      `step-${stepNum}-${agentName}-instruction.md`
    );
    const responseFile = path.join(
      this.queueDir,
      `step-${stepNum}-${agentName}-response.md`
    );

    const instructionContent = this.buildInstructionFile(
      request,
      agentName,
      stepNum,
      responseFile
    );

    fs.writeFileSync(instructionFile, instructionContent, "utf-8");

    // Update status file
    this.updateStatus(stepNum, agentName, instructionFile, responseFile);

    // Log to console so the user knows what to do
    console.log(
      `\n  📋 MANUAL MODE — Step ${stepNum}: ${agentName}`
    );
    console.log(`  ─────────────────────────────────────────`);
    console.log(`  📄 Instruction: ${path.relative(process.cwd(), instructionFile)}`);
    console.log(`  ✏️  Response:    ${path.relative(process.cwd(), responseFile)}`);
    console.log(`  ─────────────────────────────────────────`);
    console.log(
      `  Open the instruction file, paste its content into your AI coder,`
    );
    console.log(
      `  then save the AI's response to the response file listed above.`
    );
    console.log(`  Waiting for response...`);

    // Poll for the response file
    const responseText = await this.waitForResponse(responseFile);

    // Mark step complete
    this.markStepCompleted(stepNum);

    const latency = Date.now() - startTime;
    console.log(
      `  ✓ Response received (${(latency / 1000).toFixed(1)}s)`
    );

    return {
      text: responseText,
      tokens_used: approximateTokenCount(responseText),
      model_used: "manual",
      latency_ms: latency,
      is_fallback: false,
    };
  }

  /**
   * Build a self-contained instruction file the user can paste into any AI coder.
   */
  private buildInstructionFile(
    request: CompletionRequest,
    agentName: string,
    stepNum: string,
    responseFile: string
  ): string {
    const contextBudget = this.config.max_context_window;
    const userMessages = request.messages
      .filter((m) => m.role === "user")
      .map((m) => m.content)
      .join("\n\n---\n\n");

    let content = `# Step ${stepNum}: ${agentName}

> **HOW TO USE THIS FILE**
> 1. Copy everything below the "---" line
> 2. Paste it into your AI coder (Copilot, Claude Code, Antigravity, etc.)
> 3. Save the AI's response to: \`${path.basename(responseFile)}\`
> 4. The orchestrator will automatically detect your response and continue

**Context Budget**: ~${contextBudget} tokens
**Expected Output**: Structured markdown with clear headers
**Response File**: \`${path.basename(responseFile)}\`

---

## System Instructions

${request.systemPrompt}

## Task

${userMessages}
`;

    // Trim if beyond context budget
    const estimatedTokens = approximateTokenCount(content);
    if (estimatedTokens > contextBudget) {
      const ratio = contextBudget / estimatedTokens;
      const maxChars = Math.floor(content.length * ratio * 0.9); // 90% to leave room
      content = content.slice(0, maxChars) + "\n\n[Context trimmed to fit AI coder's context window]";
    }

    return content;
  }

  /**
   * Poll for the response file to appear.
   */
  private async waitForResponse(responseFile: string): Promise<string> {
    const startTime = Date.now();
    let dotCount = 0;

    while (true) {
      // Check if response file exists and has content
      if (fs.existsSync(responseFile)) {
        const content = fs.readFileSync(responseFile, "utf-8").trim();
        if (content.length > 0) {
          return content;
        }
      }

      // Check timeout
      if (this.timeout > 0 && Date.now() - startTime > this.timeout) {
        throw new Error(
          `Manual response timeout after ${this.timeout / 1000}s. ` +
            `Expected response at: ${responseFile}`
        );
      }

      // Progress dots
      dotCount++;
      if (dotCount % 10 === 0) {
        const elapsed = Math.floor((Date.now() - startTime) / 1000);
        process.stdout.write(
          `\r  ⏳ Waiting for response... (${elapsed}s)`
        );
      }

      // Wait before next poll
      await new Promise((resolve) => setTimeout(resolve, this.pollInterval));
    }
  }

  /**
   * Extract agent name from system prompt.
   */
  private extractAgentName(systemPrompt: string): string {
    // Try to find agent name in the prompt
    const match = systemPrompt.match(
      /You are (?:a |an |the )?(.+?)(?:\.|,| who| with| responsible)/i
    );
    if (match) {
      return match[1]!
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "")
        .slice(0, 30);
    }
    return "agent";
  }

  /**
   * Update the queue status file.
   */
  private updateStatus(
    stepNum: string,
    agentName: string,
    instructionFile: string,
    responseFile: string
  ): void {
    const statusFile = path.join(this.queueDir, "_status.json");

    let status: QueueStatus;
    if (fs.existsSync(statusFile)) {
      status = JSON.parse(fs.readFileSync(statusFile, "utf-8"));
    } else {
      status = {
        project_id: path.basename(this.queueDir),
        total_steps: 0,
        completed_steps: 0,
        current_step: 0,
        steps: [],
      };
    }

    status.total_steps++;
    status.current_step = parseInt(stepNum, 10);
    status.steps.push({
      step_number: parseInt(stepNum, 10),
      agent: agentName,
      status: "waiting",
      instruction_file: path.relative(this.queueDir, instructionFile),
      response_file: path.relative(this.queueDir, responseFile),
      created_at: new Date().toISOString(),
    });

    fs.writeFileSync(statusFile, JSON.stringify(status, null, 2), "utf-8");
  }

  /**
   * Mark a step as completed in the status file.
   */
  private markStepCompleted(stepNum: string): void {
    const statusFile = path.join(this.queueDir, "_status.json");
    if (!fs.existsSync(statusFile)) return;

    const status: QueueStatus = JSON.parse(
      fs.readFileSync(statusFile, "utf-8")
    );
    const step = status.steps.find(
      (s) => s.step_number === parseInt(stepNum, 10)
    );
    if (step) {
      step.status = "completed";
      step.completed_at = new Date().toISOString();
      status.completed_steps++;
    }

    fs.writeFileSync(statusFile, JSON.stringify(status, null, 2), "utf-8");
  }

  /**
   * Health check — verify the queue directory is writable.
   */
  async healthCheck(): Promise<HealthCheckResult> {
    try {
      fs.mkdirSync(this.queueDir, { recursive: true });

      // Test write
      const testFile = path.join(this.queueDir, ".health-check");
      fs.writeFileSync(testFile, "ok", "utf-8");
      fs.unlinkSync(testFile);

      return {
        healthy: true,
        model_name: "manual (file-queue)",
        provider_version: "1.0.0",
      };
    } catch (e) {
      return {
        healthy: false,
        error: `Queue directory not writable: ${(e as Error).message}`,
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
    return this.config.max_context_window;
  }

  /**
   * Reset step counter (called at start of a new execution run).
   */
  resetCounter(): void {
    this.stepCounter = 0;
  }

  /**
   * Set the queue directory for a specific project.
   */
  setQueueDir(projectId: string): void {
    this.queueDir = path.join(
      this.config.queue_dir || "./runs/queue",
      projectId
    );
  }

  /**
   * Export all pending instructions as a batch (for parallel work).
   * Returns paths to all instruction files that don't have responses yet.
   */
  getPendingInstructions(): string[] {
    if (!fs.existsSync(this.queueDir)) return [];

    const files = fs.readdirSync(this.queueDir);
    const instructions = files.filter((f) => f.endsWith("-instruction.md"));

    return instructions
      .filter((instrFile) => {
        const respFile = instrFile.replace("-instruction.md", "-response.md");
        return !files.includes(respFile);
      })
      .map((f) => path.join(this.queueDir, f));
  }
}
