/**
 * Notification System for Vibecoded Orchestrator
 *
 * Sends pipeline events to external messaging channels:
 *   - Slack (incoming webhook)
 *   - Discord (webhook)
 *   - Telegram (Bot API)
 *
 * Hooks into the executor's ExecutionHooks interface to send
 * notifications at key pipeline milestones.
 *
 * Configuration: via environment variables or config/globals.yaml
 */

import * as fs from "fs";
import * as path from "path";

// ─── Types ───────────────────────────────────────────────────────────────────

export type NotificationChannel = "slack" | "discord" | "telegram";
export type NotificationLevel = "all" | "phases" | "errors" | "summary";

export interface NotificationConfig {
  enabled: boolean;
  level: NotificationLevel;
  channels: ChannelConfig[];
}

export interface ChannelConfig {
  type: NotificationChannel;
  enabled: boolean;
  webhookUrl?: string;   // Slack & Discord
  botToken?: string;     // Telegram
  chatId?: string;       // Telegram
}

export interface NotificationPayload {
  title: string;
  message: string;
  status: "info" | "success" | "warning" | "error";
  projectId?: string;
  agentId?: string;
  agentTitle?: string;
  phase?: string;
  details?: Record<string, unknown>;
}

// ─── Channel Adapters ────────────────────────────────────────────────────────

const STATUS_EMOJI: Record<NotificationPayload["status"], string> = {
  info: "ℹ️",
  success: "✅",
  warning: "⚠️",
  error: "❌",
};

/**
 * Send a Slack notification via incoming webhook.
 */
async function sendSlack(
  webhookUrl: string,
  payload: NotificationPayload
): Promise<boolean> {
  const emoji = STATUS_EMOJI[payload.status];
  const blocks: unknown[] = [
    {
      type: "header",
      text: {
        type: "plain_text",
        text: `${emoji} ${payload.title}`,
        emoji: true,
      },
    },
    {
      type: "section",
      text: {
        type: "mrkdwn",
        text: payload.message,
      },
    },
  ];

  // Add context fields
  const contextElements: unknown[] = [];
  if (payload.projectId) {
    contextElements.push({
      type: "mrkdwn",
      text: `*Project:* ${payload.projectId}`,
    });
  }
  if (payload.agentTitle) {
    contextElements.push({
      type: "mrkdwn",
      text: `*Agent:* ${payload.agentTitle}`,
    });
  }
  if (payload.phase) {
    contextElements.push({
      type: "mrkdwn",
      text: `*Phase:* ${payload.phase}`,
    });
  }

  if (contextElements.length > 0) {
    blocks.push({ type: "context", elements: contextElements });
  }

  try {
    const response = await fetch(webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ blocks }),
      signal: AbortSignal.timeout(10000),
    });
    return response.ok;
  } catch (e) {
    console.warn(`  ⚠ Slack notification failed: ${(e as Error).message}`);
    return false;
  }
}

/**
 * Send a Discord notification via webhook.
 */
async function sendDiscord(
  webhookUrl: string,
  payload: NotificationPayload
): Promise<boolean> {
  const emoji = STATUS_EMOJI[payload.status];
  const colorMap: Record<NotificationPayload["status"], number> = {
    info: 0x3498db,    // blue
    success: 0x2ecc71, // green
    warning: 0xf39c12, // orange
    error: 0xe74c3c,   // red
  };

  const fields: Array<{ name: string; value: string; inline: boolean }> = [];
  if (payload.projectId) {
    fields.push({ name: "Project", value: payload.projectId, inline: true });
  }
  if (payload.agentTitle) {
    fields.push({ name: "Agent", value: payload.agentTitle, inline: true });
  }
  if (payload.phase) {
    fields.push({ name: "Phase", value: payload.phase, inline: true });
  }

  const embed = {
    title: `${emoji} ${payload.title}`,
    description: payload.message,
    color: colorMap[payload.status],
    fields: fields.length > 0 ? fields : undefined,
    timestamp: new Date().toISOString(),
    footer: { text: "Vibecoded Orchestrator" },
  };

  try {
    const response = await fetch(webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ embeds: [embed] }),
      signal: AbortSignal.timeout(10000),
    });
    return response.ok;
  } catch (e) {
    console.warn(`  ⚠ Discord notification failed: ${(e as Error).message}`);
    return false;
  }
}

/**
 * Send a Telegram notification via Bot API.
 */
async function sendTelegram(
  botToken: string,
  chatId: string,
  payload: NotificationPayload
): Promise<boolean> {
  const emoji = STATUS_EMOJI[payload.status];
  let text = `${emoji} *${escapeMarkdown(payload.title)}*\n\n${escapeMarkdown(payload.message)}`;

  if (payload.projectId) {
    text += `\n\n📁 *Project:* ${escapeMarkdown(payload.projectId)}`;
  }
  if (payload.agentTitle) {
    text += `\n🤖 *Agent:* ${escapeMarkdown(payload.agentTitle)}`;
  }
  if (payload.phase) {
    text += `\n📋 *Phase:* ${escapeMarkdown(payload.phase)}`;
  }

  try {
    const url = `https://api.telegram.org/bot${botToken}/sendMessage`;
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chat_id: chatId,
        text,
        parse_mode: "MarkdownV2",
        disable_notification: payload.status === "info",
      }),
      signal: AbortSignal.timeout(10000),
    });
    return response.ok;
  } catch (e) {
    console.warn(`  ⚠ Telegram notification failed: ${(e as Error).message}`);
    return false;
  }
}

/** Escape special characters for Telegram MarkdownV2 */
function escapeMarkdown(text: string): string {
  return text.replace(/([_*\[\]()~`>#+\-=|{}.!\\])/g, "\\$1");
}

// ─── Notification Manager ────────────────────────────────────────────────────

export class NotificationManager {
  private config: NotificationConfig;
  private channels: ChannelConfig[];

  constructor(config?: Partial<NotificationConfig>) {
    this.config = {
      enabled: config?.enabled ?? true,
      level: config?.level ?? "phases",
      channels: config?.channels ?? [],
    };

    // Auto-configure from environment variables
    this.channels = this.resolveChannels();
  }

  /**
   * Resolve notification channels from config + environment variables.
   */
  private resolveChannels(): ChannelConfig[] {
    const channels: ChannelConfig[] = [...this.config.channels];

    // Slack from env
    const slackUrl = process.env["SLACK_WEBHOOK_URL"];
    if (slackUrl && !channels.some((c) => c.type === "slack")) {
      channels.push({
        type: "slack",
        enabled: true,
        webhookUrl: slackUrl,
      });
    }

    // Discord from env
    const discordUrl = process.env["DISCORD_WEBHOOK_URL"];
    if (discordUrl && !channels.some((c) => c.type === "discord")) {
      channels.push({
        type: "discord",
        enabled: true,
        webhookUrl: discordUrl,
      });
    }

    // Telegram from env
    const telegramToken = process.env["TELEGRAM_BOT_TOKEN"];
    const telegramChat = process.env["TELEGRAM_CHAT_ID"];
    if (
      telegramToken &&
      telegramChat &&
      !channels.some((c) => c.type === "telegram")
    ) {
      channels.push({
        type: "telegram",
        enabled: true,
        botToken: telegramToken,
        chatId: telegramChat,
      });
    }

    return channels.filter((c) => c.enabled);
  }

  /**
   * Check if any notification channels are configured.
   */
  isConfigured(): boolean {
    return this.config.enabled && this.channels.length > 0;
  }

  /**
   * Get configured channel names.
   */
  getActiveChannels(): string[] {
    return this.channels.map((c) => c.type);
  }

  /**
   * Send a notification to all configured channels.
   */
  async send(payload: NotificationPayload): Promise<void> {
    if (!this.config.enabled || this.channels.length === 0) return;

    // Filter by notification level
    if (!this.shouldSend(payload)) return;

    const promises = this.channels.map((channel) =>
      this.sendToChannel(channel, payload)
    );

    await Promise.allSettled(promises);
  }

  /**
   * Check if this payload should be sent based on notification level.
   */
  private shouldSend(payload: NotificationPayload): boolean {
    switch (this.config.level) {
      case "all":
        return true;
      case "phases":
        // Send phase transitions, errors, and summaries
        return (
          payload.status === "error" ||
          payload.title.includes("Phase") ||
          payload.title.includes("Pipeline") ||
          payload.title.includes("Quality Gate") ||
          payload.title.includes("Complete") ||
          payload.title.includes("Failed")
        );
      case "errors":
        return payload.status === "error" || payload.status === "warning";
      case "summary":
        return (
          payload.title.includes("Pipeline") ||
          payload.title.includes("Complete") ||
          payload.title.includes("Failed")
        );
      default:
        return true;
    }
  }

  /**
   * Send to a single channel.
   */
  private async sendToChannel(
    channel: ChannelConfig,
    payload: NotificationPayload
  ): Promise<boolean> {
    switch (channel.type) {
      case "slack":
        if (!channel.webhookUrl) return false;
        return sendSlack(channel.webhookUrl, payload);

      case "discord":
        if (!channel.webhookUrl) return false;
        return sendDiscord(channel.webhookUrl, payload);

      case "telegram":
        if (!channel.botToken || !channel.chatId) return false;
        return sendTelegram(channel.botToken, channel.chatId, payload);

      default:
        return false;
    }
  }

  // ─── Executor Hook Integration ───────────────────────────────────────────

  /**
   * Create ExecutionHooks that send notifications at pipeline milestones.
   * Wire these into the executor's `executeProject()` call.
   */
  createExecutionHooks(projectId: string) {
    const manager = this;

    return {
      async before_phase(phase: number) {
        const phaseNames = [
          "", "Planning", "Design", "Build", "Test", "Deploy",
          "Review", "QA", "Release", "Monitor",
        ];
        const phaseName = phaseNames[phase] || `Phase ${phase}`;

        await manager.send({
          title: `Phase ${phase}: ${phaseName} Starting`,
          message: `Entering ${phaseName} phase for project execution.`,
          status: "info",
          projectId,
          phase: phaseName,
        });
      },

      async after_phase(phase: number) {
        const phaseNames = [
          "", "Planning", "Design", "Build", "Test", "Deploy",
          "Review", "QA", "Release", "Monitor",
        ];
        const phaseName = phaseNames[phase] || `Phase ${phase}`;

        await manager.send({
          title: `Phase ${phase}: ${phaseName} Complete`,
          message: `${phaseName} phase completed successfully.`,
          status: "success",
          projectId,
          phase: phaseName,
        });
      },

      async before_agent(context: {
        step: { agent_id?: string; title?: string };
      }) {
        if (manager.config.level !== "all") return;

        await manager.send({
          title: "Agent Started",
          message: `Agent ${context.step.title || context.step.agent_id || "unknown"} is now executing.`,
          status: "info",
          projectId,
          agentId: context.step.agent_id,
          agentTitle: context.step.title,
        });
      },

      async after_agent(context: {
        step: { agent_id?: string; title?: string };
        success: boolean;
        error?: string;
      }) {
        if (!context.success) {
          await manager.send({
            title: "Agent Failed",
            message: `Agent ${context.step.title || context.step.agent_id || "unknown"} failed: ${context.error || "Unknown error"}`,
            status: "error",
            projectId,
            agentId: context.step.agent_id,
            agentTitle: context.step.title,
          });
        } else if (manager.config.level === "all") {
          await manager.send({
            title: "Agent Complete",
            message: `Agent ${context.step.title || context.step.agent_id || "unknown"} completed successfully.`,
            status: "success",
            projectId,
            agentId: context.step.agent_id,
            agentTitle: context.step.title,
          });
        }
      },

      async on_quality_gate(
        step: { agent_id?: string; title?: string },
        verdict: string
      ) {
        const isPassing = verdict.toLowerCase().includes("pass");
        await manager.send({
          title: `Quality Gate: ${isPassing ? "Passed" : "Failed"}`,
          message: `Quality gate for ${step.title || step.agent_id || "unknown"}: ${verdict}`,
          status: isPassing ? "success" : "warning",
          projectId,
          agentId: step.agent_id,
          agentTitle: step.title,
        });
      },

      async on_token_budget_warning(used: number, budget: number) {
        const pct = Math.round((used / budget) * 100);
        await manager.send({
          title: "Token Budget Warning",
          message: `Token usage at ${pct}% (${used.toLocaleString()} / ${budget.toLocaleString()}).`,
          status: "warning",
          projectId,
        });
      },
    };
  }

  /**
   * Send pipeline start notification.
   */
  async notifyPipelineStart(
    projectId: string,
    agentCount: number
  ): Promise<void> {
    await this.send({
      title: "Pipeline Started",
      message: `Executing ${agentCount} agents for project "${projectId}".`,
      status: "info",
      projectId,
    });
  }

  /**
   * Send pipeline completion notification.
   */
  async notifyPipelineComplete(
    projectId: string,
    metrics: {
      totalSteps: number;
      successSteps: number;
      failedSteps: number;
      tokensUsed: number;
      durationMs: number;
    }
  ): Promise<void> {
    const allPassed = metrics.failedSteps === 0;
    const duration = (metrics.durationMs / 1000).toFixed(1);

    await this.send({
      title: allPassed ? "Pipeline Complete" : "Pipeline Complete (with errors)",
      message: [
        `Project "${projectId}" execution finished.`,
        `Steps: ${metrics.successSteps}/${metrics.totalSteps} passed`,
        `Tokens: ${metrics.tokensUsed.toLocaleString()}`,
        `Duration: ${duration}s`,
      ].join("\n"),
      status: allPassed ? "success" : "warning",
      projectId,
    });
  }
}

// ─── Singleton ───────────────────────────────────────────────────────────────

let _instance: NotificationManager | null = null;

/**
 * Get or create the singleton NotificationManager.
 * Reads config from globals.yaml and environment variables.
 */
export function getNotificationManager(
  config?: Partial<NotificationConfig>
): NotificationManager {
  if (!_instance || config) {
    // Try loading config from globals.yaml
    let yamlConfig: Partial<NotificationConfig> = {};
    try {
      const globalsPath = path.join(
        process.cwd(),
        "config",
        "globals.yaml"
      );
      if (fs.existsSync(globalsPath)) {
        const content = fs.readFileSync(globalsPath, "utf-8");
        // Simple extraction of notification config
        const match = content.match(
          /notifications:\s*\n\s+enabled:\s*(true|false)/
        );
        if (match) {
          yamlConfig.enabled = match[1] === "true";
        }
        const levelMatch = content.match(
          /notifications:[\s\S]*?level:\s*"?(\w+)"?/
        );
        if (levelMatch) {
          yamlConfig.level = levelMatch[1] as NotificationLevel;
        }
      }
    } catch { /* use defaults */ }

    _instance = new NotificationManager({ ...yamlConfig, ...config });
  }
  return _instance;
}

/**
 * Reset the singleton (for testing or reconfiguration).
 */
export function resetNotificationManager(): void {
  _instance = null;
}
