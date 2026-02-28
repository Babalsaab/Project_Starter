#!/usr/bin/env ts-node
/**
 * usage-report.ts — Generate token usage & cost reports
 *
 * Inspired by OpenClaw's scripts/cron_usage_report.ts.
 * Aggregates token usage from execution logs and artifacts across
 * all project sessions, outputting a summary by provider, model, agent, and phase.
 *
 * Usage:
 *   npm run usage:report                     # report for all sessions
 *   npm run usage:report -- --session <id>   # report for specific session
 *   npm run usage:report -- --format json    # JSON output
 *   npm run usage:report -- --days 7         # last 7 days only
 */

import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";

// ─── Cost Estimates (per 1M tokens) ──────────────────────────────────────────

const MODEL_COSTS: Record<string, { input: number; output: number }> = {
  "claude-sonnet-4-20250514": { input: 3.0, output: 15.0 },
  "claude-haiku-35-20241022": { input: 0.25, output: 1.25 },
  "claude-3-5-sonnet-20241022": { input: 3.0, output: 15.0 },
  "claude-3-haiku-20240307": { input: 0.25, output: 1.25 },
  placeholder: { input: 0, output: 0 },
  manual: { input: 0, output: 0 },
  // Local models are free
  default_local: { input: 0, output: 0 },
};

function getCostPerMToken(
  model: string
): { input: number; output: number } {
  if (MODEL_COSTS[model]) return MODEL_COSTS[model];
  // Local models
  if (
    model.includes("llama") ||
    model.includes("mistral") ||
    model.includes("qwen") ||
    model.includes("deepseek") ||
    model.includes("codestral")
  ) {
    return { input: 0, output: 0 };
  }
  return { input: 1.0, output: 5.0 }; // conservative default
}

// ─── Types ────────────────────────────────────────────────────────────────────

interface ManifestEntry {
  step_id: string;
  agent_id: string;
  status: string;
  model_used?: string;
  tokens_used?: number;
  started_at?: string;
  completed_at?: string;
  retry_count?: number;
}

interface SessionMeta {
  project_id: string;
  project_name: string;
  created_at?: string;
}

interface UsageRecord {
  project_id: string;
  project_name: string;
  agent_id: string;
  model_used: string;
  tokens_used: number;
  estimated_cost_usd: number;
  retries: number;
  duration_ms: number;
  timestamp: string;
}

// ─── Data Loading ─────────────────────────────────────────────────────────────

const ROOT = path.resolve(__dirname, "..");
const SESSIONS_DIR = path.join(ROOT, "config/project-sessions");
const ARTIFACTS_DIR = path.join(ROOT, "runs/artifacts");
const LOGS_DIR = path.join(ROOT, "runs/logs");

function loadSessions(): SessionMeta[] {
  if (!fs.existsSync(SESSIONS_DIR)) return [];
  return fs
    .readdirSync(SESSIONS_DIR)
    .filter((d) => {
      const sessionPath = path.join(SESSIONS_DIR, d, "session.yaml");
      return fs.existsSync(sessionPath);
    })
    .map((d) => {
      const raw = yaml.load(
        fs.readFileSync(path.join(SESSIONS_DIR, d, "session.yaml"), "utf-8")
      ) as any;
      return {
        project_id: d,
        project_name: raw?.project_name || d,
        created_at: raw?.created_at,
      };
    });
}

function loadManifest(
  projectId: string
): ManifestEntry[] {
  const manifestPath = path.join(ARTIFACTS_DIR, projectId, "manifest.json");
  if (!fs.existsSync(manifestPath)) return [];
  try {
    return JSON.parse(fs.readFileSync(manifestPath, "utf-8"));
  } catch {
    return [];
  }
}

function loadExecutionPlan(
  projectId: string
): any | null {
  const planPath = path.join(ARTIFACTS_DIR, projectId, "execution-plan.json");
  if (!fs.existsSync(planPath)) return null;
  try {
    return JSON.parse(fs.readFileSync(planPath, "utf-8"));
  } catch {
    return null;
  }
}

function gatherUsageRecords(
  sessions: SessionMeta[],
  daysFilter?: number
): UsageRecord[] {
  const records: UsageRecord[] = [];
  const cutoff = daysFilter
    ? new Date(Date.now() - daysFilter * 24 * 60 * 60 * 1000)
    : null;

  for (const session of sessions) {
    const plan = loadExecutionPlan(session.project_id);
    const manifest = loadManifest(session.project_id);

    if (plan?.steps) {
      for (const step of plan.steps) {
        if (step.status !== "done") continue;

        const timestamp = step.completed_at || step.started_at || "";
        if (cutoff && timestamp && new Date(timestamp) < cutoff) continue;

        const model = step.model_used || "unknown";
        const tokens = step.tokens_used || 0;
        const costs = getCostPerMToken(model);
        // Rough split: 70% input, 30% output
        const estimatedCost =
          (tokens * 0.7 * costs.input + tokens * 0.3 * costs.output) / 1_000_000;

        const durationMs =
          step.started_at && step.completed_at
            ? new Date(step.completed_at).getTime() -
              new Date(step.started_at).getTime()
            : 0;

        records.push({
          project_id: session.project_id,
          project_name: session.project_name,
          agent_id: step.owner_agent || step.agent_id || "unknown",
          model_used: model,
          tokens_used: tokens,
          estimated_cost_usd: estimatedCost,
          retries: step.retry_count || 0,
          duration_ms: durationMs,
          timestamp,
        });
      }
    }
  }

  return records;
}

// ─── Reporting ────────────────────────────────────────────────────────────────

function printReport(records: UsageRecord[]): void {
  if (records.length === 0) {
    console.log("No usage data found.\n");
    console.log("Usage data is generated when you run the orchestrator:");
    console.log("  npm run orchestrator\n");
    return;
  }

  const totalTokens = records.reduce((a, r) => a + r.tokens_used, 0);
  const totalCost = records.reduce((a, r) => a + r.estimated_cost_usd, 0);
  const totalRetries = records.reduce((a, r) => a + r.retries, 0);
  const totalDuration = records.reduce((a, r) => a + r.duration_ms, 0);

  console.log("═".repeat(70));
  console.log("📊 USAGE REPORT");
  console.log("═".repeat(70));
  console.log(`Total tokens: ${totalTokens.toLocaleString()}`);
  console.log(`Estimated cost: $${totalCost.toFixed(4)}`);
  console.log(`Total retries: ${totalRetries}`);
  console.log(`Total duration: ${(totalDuration / 1000).toFixed(1)}s`);
  console.log(`Total agent calls: ${records.length}`);
  console.log();

  // By model
  const byModel = new Map<string, { tokens: number; cost: number; count: number }>();
  for (const r of records) {
    const m = byModel.get(r.model_used) || { tokens: 0, cost: 0, count: 0 };
    m.tokens += r.tokens_used;
    m.cost += r.estimated_cost_usd;
    m.count++;
    byModel.set(r.model_used, m);
  }

  console.log("📋 By Model:");
  console.log(
    "Model".padEnd(35) +
      "Tokens".padStart(12) +
      "Cost".padStart(10) +
      "Calls".padStart(8)
  );
  console.log("─".repeat(65));
  for (const [model, data] of [...byModel.entries()].sort(
    (a, b) => b[1].tokens - a[1].tokens
  )) {
    console.log(
      model.padEnd(35) +
        data.tokens.toLocaleString().padStart(12) +
        `$${data.cost.toFixed(4)}`.padStart(10) +
        String(data.count).padStart(8)
    );
  }
  console.log();

  // By agent (top 15)
  const byAgent = new Map<string, { tokens: number; cost: number; count: number }>();
  for (const r of records) {
    const a = byAgent.get(r.agent_id) || { tokens: 0, cost: 0, count: 0 };
    a.tokens += r.tokens_used;
    a.cost += r.estimated_cost_usd;
    a.count++;
    byAgent.set(r.agent_id, a);
  }

  console.log("🤖 By Agent (top 15):");
  console.log(
    "Agent".padEnd(35) +
      "Tokens".padStart(12) +
      "Cost".padStart(10) +
      "Calls".padStart(8)
  );
  console.log("─".repeat(65));
  const topAgents = [...byAgent.entries()]
    .sort((a, b) => b[1].tokens - a[1].tokens)
    .slice(0, 15);
  for (const [agent, data] of topAgents) {
    console.log(
      agent.padEnd(35) +
        data.tokens.toLocaleString().padStart(12) +
        `$${data.cost.toFixed(4)}`.padStart(10) +
        String(data.count).padStart(8)
    );
  }
  console.log();

  // By project
  const byProject = new Map<
    string,
    { name: string; tokens: number; cost: number; count: number }
  >();
  for (const r of records) {
    const p = byProject.get(r.project_id) || {
      name: r.project_name,
      tokens: 0,
      cost: 0,
      count: 0,
    };
    p.tokens += r.tokens_used;
    p.cost += r.estimated_cost_usd;
    p.count++;
    byProject.set(r.project_id, p);
  }

  if (byProject.size > 1) {
    console.log("📁 By Project:");
    console.log(
      "Project".padEnd(35) +
        "Tokens".padStart(12) +
        "Cost".padStart(10) +
        "Agents".padStart(8)
    );
    console.log("─".repeat(65));
    for (const [, data] of [...byProject.entries()].sort(
      (a, b) => b[1].tokens - a[1].tokens
    )) {
      console.log(
        data.name.padEnd(35) +
          data.tokens.toLocaleString().padStart(12) +
          `$${data.cost.toFixed(4)}`.padStart(10) +
          String(data.count).padStart(8)
      );
    }
    console.log();
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

function main(): void {
  const args = process.argv.slice(2);
  let sessionFilter: string | null = null;
  let format = "table";
  let daysFilter: number | undefined;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--session" && args[i + 1]) {
      sessionFilter = args[i + 1]!;
      i++;
    } else if (args[i] === "--format" && args[i + 1]) {
      format = args[i + 1]!;
      i++;
    } else if (args[i] === "--days" && args[i + 1]) {
      daysFilter = parseInt(args[i + 1]!, 10);
      i++;
    }
  }

  let sessions = loadSessions();
  if (sessionFilter) {
    sessions = sessions.filter((s) => s.project_id === sessionFilter);
    if (sessions.length === 0) {
      console.error(`Session not found: ${sessionFilter}`);
      process.exit(1);
    }
  }

  const records = gatherUsageRecords(sessions, daysFilter);

  if (format === "json") {
    console.log(JSON.stringify({ records, summary: { total: records.length } }, null, 2));
  } else {
    printReport(records);
  }
}

main();
