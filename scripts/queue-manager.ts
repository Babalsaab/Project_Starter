#!/usr/bin/env ts-node
/**
 * queue-manager.ts — Manage the manual file-queue for API-less AI coders
 *
 * When using Manual mode (GitHub Copilot, Claude Code, Antigravity), the
 * orchestrator writes instruction files and waits for response files.
 * This tool helps manage that queue.
 *
 * Usage:
 *   npm run queue list                           # list pending instructions
 *   npm run queue status                         # show queue status
 *   npm run queue show <step-number>             # show instruction content
 *   npm run queue respond <step-number> <file>   # submit response from file
 *   npm run queue clear                          # clear completed entries
 *   npm run queue export                         # export all pending as one doc
 */

import * as fs from "fs";
import * as path from "path";

// ─── Config ───────────────────────────────────────────────────────────────────

const RUNS_DIR = path.resolve(__dirname, "../runs");
const QUEUE_DIR = path.join(RUNS_DIR, "queue");

// ─── Types ────────────────────────────────────────────────────────────────────

interface QueueEntry {
  stepNumber: number;
  agentId: string;
  instructionFile: string;
  responseFile: string;
  hasResponse: boolean;
  instructionSize: number;
  responseSize?: number;
}

interface QueueStatus {
  projectId: string;
  entries: QueueEntry[];
  pending: number;
  completed: number;
  total: number;
}

// ─── Queue Operations ────────────────────────────────────────────────────────

function findProjectQueues(): string[] {
  if (!fs.existsSync(QUEUE_DIR)) return [];
  return fs
    .readdirSync(QUEUE_DIR)
    .filter((d) => fs.statSync(path.join(QUEUE_DIR, d)).isDirectory());
}

function loadQueueStatus(projectId: string): QueueStatus {
  const projectDir = path.join(QUEUE_DIR, projectId);
  if (!fs.existsSync(projectDir)) {
    return { projectId, entries: [], pending: 0, completed: 0, total: 0 };
  }

  const files = fs.readdirSync(projectDir);
  const instructionFiles = files.filter((f) => f.includes("-instruction.md"));

  const entries: QueueEntry[] = [];
  for (const instrFile of instructionFiles) {
    const match = instrFile.match(/^step-(\d+)-(.+?)-instruction\.md$/);
    if (!match) continue;

    const stepNumber = parseInt(match[1]!, 10);
    const agentId = match[2]!;
    const responseFile = instrFile.replace("-instruction.md", "-response.md");
    const instrPath = path.join(projectDir, instrFile);
    const respPath = path.join(projectDir, responseFile);

    entries.push({
      stepNumber,
      agentId,
      instructionFile: instrFile,
      responseFile,
      hasResponse: fs.existsSync(respPath),
      instructionSize: fs.statSync(instrPath).size,
      responseSize: fs.existsSync(respPath)
        ? fs.statSync(respPath).size
        : undefined,
    });
  }

  entries.sort((a, b) => a.stepNumber - b.stepNumber);

  return {
    projectId,
    entries,
    pending: entries.filter((e) => !e.hasResponse).length,
    completed: entries.filter((e) => e.hasResponse).length,
    total: entries.length,
  };
}

// ─── Commands ─────────────────────────────────────────────────────────────────

function cmdList(): void {
  const projects = findProjectQueues();
  if (projects.length === 0) {
    console.log("No queue entries found.");
    console.log("Queue entries are created when running the orchestrator in manual mode.");
    console.log("Set provider type to 'manual' in config/globals.yaml.\n");
    return;
  }

  for (const projectId of projects) {
    const status = loadQueueStatus(projectId);
    console.log(`\n📁 Project: ${projectId}`);
    console.log(`   Total: ${status.total} | Pending: ${status.pending} | Completed: ${status.completed}\n`);

    if (status.entries.length === 0) {
      console.log("   (empty)\n");
      continue;
    }

    for (const entry of status.entries) {
      const icon = entry.hasResponse ? "✅" : "⏳";
      const sizeKB = (entry.instructionSize / 1024).toFixed(1);
      console.log(
        `   ${icon} Step ${String(entry.stepNumber).padStart(3)} | ${entry.agentId.padEnd(30)} | ${sizeKB}KB`
      );
    }
    console.log();
  }
}

function cmdStatus(): void {
  const projects = findProjectQueues();
  if (projects.length === 0) {
    console.log("No active queues.\n");
    return;
  }

  console.log("═".repeat(60));
  console.log("📊 Manual Queue Status");
  console.log("═".repeat(60));

  let totalPending = 0;
  let totalCompleted = 0;

  for (const projectId of projects) {
    const status = loadQueueStatus(projectId);
    totalPending += status.pending;
    totalCompleted += status.completed;

    const pct =
      status.total > 0
        ? Math.round((status.completed / status.total) * 100)
        : 0;
    const bar = "█".repeat(Math.floor(pct / 5)) + "░".repeat(20 - Math.floor(pct / 5));

    console.log(`\n  ${projectId}`);
    console.log(`  [${bar}] ${pct}%  (${status.completed}/${status.total})`);

    if (status.pending > 0) {
      const nextPending = status.entries.find((e) => !e.hasResponse);
      if (nextPending) {
        console.log(
          `  Next: Step ${nextPending.stepNumber} → ${nextPending.agentId}`
        );
      }
    }
  }

  console.log(`\n${"─".repeat(60)}`);
  console.log(`Total pending: ${totalPending} | Total completed: ${totalCompleted}\n`);
}

function cmdShow(stepArg: string): void {
  const stepNum = parseInt(stepArg, 10);
  if (isNaN(stepNum)) {
    console.error("Invalid step number. Usage: queue show <step-number>");
    process.exit(1);
  }

  const projects = findProjectQueues();
  for (const projectId of projects) {
    const status = loadQueueStatus(projectId);
    const entry = status.entries.find((e) => e.stepNumber === stepNum);
    if (entry) {
      const instrPath = path.join(QUEUE_DIR, projectId, entry.instructionFile);
      const content = fs.readFileSync(instrPath, "utf-8");
      console.log(`📄 Step ${stepNum} — ${entry.agentId} (${projectId})\n`);
      console.log(content);

      if (entry.hasResponse) {
        console.log("\n" + "─".repeat(60));
        console.log("✅ Response already submitted.\n");
        const respPath = path.join(QUEUE_DIR, projectId, entry.responseFile);
        console.log(fs.readFileSync(respPath, "utf-8"));
      } else {
        console.log("\n" + "─".repeat(60));
        console.log(
          `⏳ Awaiting response. Save your response to:\n   ${path.join(QUEUE_DIR, projectId, entry.responseFile)}\n`
        );
      }
      return;
    }
  }

  console.error(`Step ${stepNum} not found in any project queue.`);
  process.exit(1);
}

function cmdRespond(stepArg: string, responseFileArg: string): void {
  const stepNum = parseInt(stepArg, 10);
  if (isNaN(stepNum)) {
    console.error(
      "Invalid step number. Usage: queue respond <step-number> <response-file>"
    );
    process.exit(1);
  }

  if (!fs.existsSync(responseFileArg)) {
    console.error(`Response file not found: ${responseFileArg}`);
    process.exit(1);
  }

  const content = fs.readFileSync(responseFileArg, "utf-8");
  if (content.trim().length === 0) {
    console.error("Response file is empty.");
    process.exit(1);
  }

  const projects = findProjectQueues();
  for (const projectId of projects) {
    const status = loadQueueStatus(projectId);
    const entry = status.entries.find((e) => e.stepNumber === stepNum);
    if (entry) {
      const respPath = path.join(QUEUE_DIR, projectId, entry.responseFile);
      fs.writeFileSync(respPath, content, "utf-8");
      console.log(
        `✅ Response submitted for Step ${stepNum} (${entry.agentId})`
      );
      console.log(`   Saved to: ${respPath}`);
      console.log(`   Size: ${(content.length / 1024).toFixed(1)}KB\n`);
      return;
    }
  }

  console.error(`Step ${stepNum} not found in any project queue.`);
  process.exit(1);
}

function cmdClear(): void {
  const projects = findProjectQueues();
  let cleared = 0;

  for (const projectId of projects) {
    const status = loadQueueStatus(projectId);
    for (const entry of status.entries) {
      if (entry.hasResponse) {
        const instrPath = path.join(QUEUE_DIR, projectId, entry.instructionFile);
        const respPath = path.join(QUEUE_DIR, projectId, entry.responseFile);
        fs.unlinkSync(instrPath);
        fs.unlinkSync(respPath);
        cleared++;
      }
    }

    // Clean up _status.json if empty
    const remaining = loadQueueStatus(projectId);
    if (remaining.total === 0) {
      const statusFile = path.join(QUEUE_DIR, projectId, "_status.json");
      if (fs.existsSync(statusFile)) fs.unlinkSync(statusFile);
      try {
        fs.rmdirSync(path.join(QUEUE_DIR, projectId));
      } catch {}
    }
  }

  console.log(`🧹 Cleared ${cleared} completed queue entries.\n`);
}

function cmdExport(): void {
  const projects = findProjectQueues();
  const parts: string[] = [
    "# Manual Queue — All Pending Instructions\n",
    `Generated: ${new Date().toISOString()}\n`,
  ];

  let count = 0;
  for (const projectId of projects) {
    const status = loadQueueStatus(projectId);
    const pending = status.entries.filter((e) => !e.hasResponse);
    if (pending.length === 0) continue;

    parts.push(`## Project: ${projectId}\n`);

    for (const entry of pending) {
      const instrPath = path.join(QUEUE_DIR, projectId, entry.instructionFile);
      const content = fs.readFileSync(instrPath, "utf-8");

      parts.push(`### Step ${entry.stepNumber}: ${entry.agentId}\n`);
      parts.push(content);
      parts.push(`\n**Save response to:** \`${path.join(QUEUE_DIR, projectId, entry.responseFile)}\`\n`);
      parts.push("---\n");
      count++;
    }
  }

  if (count === 0) {
    console.log("No pending instructions to export.\n");
    return;
  }

  const exportPath = path.join(RUNS_DIR, "queue-export.md");
  fs.writeFileSync(exportPath, parts.join("\n"), "utf-8");
  console.log(`📤 Exported ${count} pending instructions to ${exportPath}\n`);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

function main(): void {
  const args = process.argv.slice(2);
  const cmd = args[0] || "help";

  switch (cmd) {
    case "list":
      cmdList();
      break;
    case "status":
      cmdStatus();
      break;
    case "show":
      cmdShow(args[1]!);
      break;
    case "respond":
      cmdRespond(args[1]!, args[2]!);
      break;
    case "clear":
      cmdClear();
      break;
    case "export":
      cmdExport();
      break;
    case "help":
    case "--help":
    case "-h":
      console.log("Usage: npm run queue <command> [args]\n");
      console.log("Commands:");
      console.log("  list                           List all queue entries");
      console.log("  status                         Show queue status dashboard");
      console.log("  show <step-number>             Show instruction content");
      console.log(
        "  respond <step-number> <file>   Submit response from file"
      );
      console.log("  clear                          Clear completed entries");
      console.log(
        "  export                         Export all pending as one markdown doc"
      );
      console.log("\nThe manual queue is used when running the orchestrator");
      console.log("with provider type 'manual' in config/globals.yaml.\n");
      break;
    default:
      console.error(`Unknown command: ${cmd}`);
      console.log("Run 'npm run queue help' for usage.");
      process.exit(1);
  }
}

main();
