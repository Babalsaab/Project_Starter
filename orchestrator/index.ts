/**
 * Vibecoded Orchestrator — Main Entry Point
 *
 * Flow:
 * 1. Discovery Agent interviews the user
 * 2. PRD Generator creates the Master PRD
 * 3. Agent Configurator selects and activates specialists
 * 4. Executor runs the task plan
 */

import * as readline from "readline";
import * as fs from "fs";
import * as path from "path";
import { DiscoveryAgent } from "./discovery";
import { buildPRDTemplate, selectAgents, savePRD } from "./prd-generator";
import {
  createProjectSession,
  printAgentSummary,
  updateSessionStatus
} from "./agent-configurator";
import { executeProject, listSessions } from "./executor";
import { getProviderRegistry, resetProviderRegistry } from "./providers";
import { detectEnvironment } from "./env-detect";
import { getNotificationManager } from "./notifications";

// ─── Helpers ──────────────────────────────────────────────────────────────────

function generateProjectId(name: string): string {
  const slug = name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 30);
  const date = new Date().toISOString().split("T")[0];
  return `${slug}-${date}`;
}

function print(msg: string): void {
  process.stdout.write(msg + "\n");
}

function divider(): void {
  print("\n─────────────────────────────────────────────────────\n");
}

// ─── CLI Interface ─────────────────────────────────────────────────────────────

async function getUserInput(prompt: string): Promise<string> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  return new Promise(resolve => {
    rl.question(prompt + "\n> ", answer => {
      rl.close();
      resolve(answer);
    });
  });
}

// ─── Phase 1: Discovery ────────────────────────────────────────────────────────

async function runDiscovery(): Promise<{
  answers: ReturnType<DiscoveryAgent["getAnswers"]>;
  projectId: string;
}> {
  const tempId = `project-${Date.now()}`;
  const agent = new DiscoveryAgent(tempId);

  // Print greeting
  print(agent.greet());

  while (true) {
    const input = await getUserInput("");
    const response = agent.respond(input);

    print(response.message);

    if (response.type === "complete") {
      break;
    }
  }

  const answers = agent.getAnswers();
  const projectId = generateProjectId(answers.project_name || "project");
  return { answers, projectId };
}

// ─── Phase 2: Generate Master PRD ─────────────────────────────────────────────

async function generatePRD(
  answers: ReturnType<DiscoveryAgent["getAnswers"]>,
  projectId: string
): Promise<string> {
  divider();
  print(`📋 Generating Master PRD for: ${answers.project_name}`);

  const prdContent = buildPRDTemplate(answers, projectId);
  const prdPath = savePRD(projectId, prdContent);

  print(`✅ Master PRD saved to: ${prdPath}`);
  divider();

  // Print a preview
  print("PRD PREVIEW:");
  print(prdContent.split("\n").slice(0, 30).join("\n"));
  print("...\n[Full PRD available at path above]");
  divider();

  return prdPath;
}

// ─── Phase 3: Configure Agents ────────────────────────────────────────────────

async function configureAgents(
  answers: ReturnType<DiscoveryAgent["getAnswers"]>,
  projectId: string,
  prdPath: string
): Promise<void> {
  print(`🤖 Selecting and configuring agents...`);

  const selectedAgents = selectAgents(answers);
  const session = createProjectSession(
    projectId,
    answers.project_name,
    selectedAgents,
    prdPath
  );

  print(printAgentSummary(session, selectedAgents));

  // Ask for human confirmation before proceeding
  print("⚠️  Review the agent selection above.");
  const confirm = await getUserInput(
    "Type 'yes' to begin execution, or 'edit' to modify the PRD first:"
  );

  if (confirm.toLowerCase().trim() !== "yes") {
    print(`\n📝 PRD saved at: ${prdPath}`);
    print(`   Edit it, then run: npm run execute ${projectId}`);
    print(`   Or restart to re-run discovery.\n`);
    process.exit(0);
  }

  updateSessionStatus(projectId, "running");
  print(`\n🚀 Execution beginning for project: ${projectId}\n`);
}

// ─── Phase 4: Execute Agents ──────────────────────────────────────────────────

async function executeAgents(projectId: string, prdPath: string): Promise<void> {
  divider();
  print(`🚀 EXECUTING AGENTS FOR: ${projectId}`);
  divider();

  // Set up notification hooks
  const notifier = getNotificationManager();
  if (notifier.isConfigured()) {
    await notifier.notifyPipelineStart(projectId, 0); // count unknown at this point
  }

  try {
    const result = await executeProject(projectId, (step, total, index) => {
      const icon = step.owner_agent.includes("feedback") ? "🔍" :
                   step.owner_agent.includes("deployment") ? "🚀" :
                   step.owner_agent.includes("housekeeping") ? "🧹" :
                   step.owner_agent.includes("mentor") ? "🧠" : "▶";
      print(`  [${index + 1}/${total}] ${icon} ${step.owner_agent} — ${step.label}`);
    });

    // Count mentor reviews in artifacts
    const mentorReviews = result.artifacts.filter(a => a.agent_id.startsWith("mentor-review")).length;
    const qualityGateCount = Object.keys(result.quality_gate_results).length;
    const qualityGatePasses = Object.values(result.quality_gate_results).filter(v => v === "pass" || v === "pass_with_notes").length;
    const blockedSteps = result.plan.steps.filter(s => s.status === 'blocked').length;
    const doneSteps = result.plan.steps.filter(s => s.status === 'done').length;
    const failedSteps = result.plan.steps.filter(s => s.status === 'failed').length;

    divider();
    print(`✅ EXECUTION COMPLETE`);
    print(``);
    print(`  ── Pipeline ──────────────────────────────`);
    print(`  Steps completed: ${doneSteps}/${result.plan.steps.length}`);
    print(`  Steps skipped:   ${result.plan.steps.filter(s => s.status === 'skipped').length}`);
    print(`  Steps failed:    ${failedSteps}`);
    print(`  Steps blocked:   ${blockedSteps}`);
    print(`  Artifacts:       ${result.artifacts.length}`);
    print(`  Mentor reviews:  ${mentorReviews}`);
    print(``);
    print(`  ── Resilience ────────────────────────────`);
    print(`  Retries used:    ${result.retries_used}`);
    print(`  Model failovers: ${result.model_failovers}`);
    print(`  Quality gates:   ${qualityGatePasses}/${qualityGateCount} passed`);
    print(``);
    print(`  ── Resources ─────────────────────────────`);
    print(`  Tokens used:     ${result.total_tokens_used}`);
    print(`  Duration:        ${(result.duration_ms / 1000).toFixed(1)}s`);
    print(``);
    print(`  📁 Artifacts:   ./runs/artifacts/${projectId}/`);
    print(`  📋 Plan:        ./config/project-sessions/${projectId}/execution-plan.yaml`);
    print(`  📊 Metrics:     ./config/project-sessions/${projectId}/execution-metrics.json`);
    print(`  🌐 Dashboard:   http://localhost:1000/orchestrator/${projectId}`);
    divider();

    // Send completion notification
    if (notifier.isConfigured()) {
      await notifier.notifyPipelineComplete(projectId, {
        totalSteps: result.plan.steps.length,
        successSteps: doneSteps,
        failedSteps,
        tokensUsed: result.total_tokens_used,
        durationMs: result.duration_ms,
      });
    }
  } catch (error) {
    print(`\n❌ Execution failed: ${(error as Error).message}`);

    // Send failure notification
    if (notifier.isConfigured()) {
      await notifier.send({
        title: "Pipeline Failed",
        message: `Execution failed for project "${projectId}": ${(error as Error).message}`,
        status: "error",
        projectId,
      });
    }
  }
}

// ─── List Projects Command ─────────────────────────────────────────────────────

function listProjectSessions(): void {
  const sessions = listSessions();
  if (sessions.length === 0) {
    print("\n  No project sessions found. Run 'npm run orchestrator' to start one.\n");
    return;
  }

  print("\n╔══════════════════════════════════════════════════════════════════╗");
  print("║              PROJECT SESSIONS                                  ║");
  print("╚══════════════════════════════════════════════════════════════════╝\n");

  for (const s of sessions) {
    const statusIcon = { initialising: "⏳", running: "▶", paused: "⏸", complete: "✅", failed: "❌" }[s.status] || "❓";
    print(`  ${statusIcon} ${s.project_id}`);
    print(`     Name: ${s.project_name} | Agents: ${s.agent_count} | Status: ${s.status}`);
    print(`     Created: ${s.created_at}`);
    print("");
  }
}

// ─── Main ──────────────────────────────────────────────────────────────────────

/**
 * Force-initialize the registry with only the manual (file-queue) provider.
 */
async function initManualProvider(): Promise<void> {
  resetProviderRegistry();
  const registry = await getProviderRegistry();

  // The registry reads globals.yaml's providers.
  // We override so every agent routes through manual.
  // Inject a runtime manual provider if not already present.
  const health = await registry.healthCheckAll();
  const hasManual = health.some((h) => h.name.toLowerCase().includes("manual"));

  if (!hasManual) {
    // Directly initialize with a manual-only config
    print("  ℹ  No manual provider in globals.yaml — injecting runtime manual provider");
    // Re-init with override: we write a temporary config
    const { ManualProvider } = await import("./providers/manual");
    const manualProvider = new ManualProvider({
      id: "manual-runtime",
      name: "Manual File-Queue (runtime)",
      type: "manual",
      models: ["human"],
      max_context_window: 100000,
      max_output_tokens: 100000,
      capabilities: {
        code_generation: "advanced",
        analysis: "advanced",
        creative_writing: "advanced",
        structured_output: "advanced",
        max_context_window: 100000,
        max_output_tokens: 100000,
        supports_system_prompt: true,
        supports_streaming: false,
        supports_json_mode: true,
      },
      enabled: true,
      priority: 1,
      quality_threshold: 1.0,
      queue_dir: "./runs/queue",
      poll_interval_ms: 3000,
      manual_timeout_ms: 0,
    });
    // Register it via the registry's internal map
    (registry as any).providers.set("manual-runtime", manualProvider);
    // Override every agent to use this provider
    (registry as any).agentOverrides = new Proxy(new Map(), {
      get(_target, prop) {
        if (prop === "get") return () => "manual-runtime";
        if (prop === "has") return () => true;
        return Reflect.get(_target, prop);
      },
    });
  } else {
    // Route all agents to the existing manual provider
    const manualId = health.find((h) => h.name.toLowerCase().includes("manual"))?.id || "manual";
    const allOverrides: Record<string, string> = {};
    // We'll set a catch-all by making getProviderForAgent always return manual
    (registry as any).agentOverrides = new Proxy(new Map(), {
      get(_target, prop) {
        if (prop === "get") return () => manualId;
        if (prop === "has") return () => true;
        return Reflect.get(_target, prop);
      },
    });
  }

  print("  ✅ Manual provider active — all agents routed to file-queue\n");
}

/**
 * Initialize hybrid mode — mixed providers from globals.yaml + runtime overrides.
 */
async function initHybridProvider(runtimeOverrides: Record<string, string>): Promise<void> {
  resetProviderRegistry();
  const registry = await getProviderRegistry();

  // Load agent_provider_overrides from globals.yaml (already loaded by registry)
  // Then layer on runtime --map overrides
  if (Object.keys(runtimeOverrides).length > 0) {
    registry.setAgentOverrides(runtimeOverrides);
    print(`   Runtime overrides applied:`);
    for (const [agent, provider] of Object.entries(runtimeOverrides)) {
      print(`     ${agent} → ${provider}`);
    }
  }

  // Health check all providers
  const health = await registry.healthCheckAll();
  print(`\n   Providers available:`);
  for (const h of health) {
    const icon = h.result.healthy ? "✅" : "❌";
    print(`     ${icon} ${h.name} (${h.id})${h.result.error ? ` — ${h.result.error}` : ""}`);
  }

  const healthyCount = health.filter((h) => h.result.healthy).length;
  if (healthyCount === 0) {
    print("\n❌ No healthy providers available. Check your configuration.");
    process.exit(1);
  }

  print(`\n  ✅ Hybrid mode active — ${healthyCount}/${health.length} providers healthy\n`);
}

/**
 * Print CLI help.
 */
function printHelp(): void {
  print("\nUsage: npm run orchestrator [command] [options]\n");
  print("Commands:");
  print("  (none)                Full flow: Discovery → PRD → Configure → Execute");
  print("  list                  List all project sessions");
  print("  execute <project-id>  Resume execution for an existing project");
  print("  manual  <project-id>  Run in manual mode (file-queue, no API needed)");
  print("  hybrid  <project-id>  Run with mixed providers (API + manual + local)");
  print("    --map agent=provider,...   Override agent→provider mapping at runtime");
  print("  help                  Show this help message");
  print("\nExamples:");
  print("  npm run orchestrator                        # start fresh project");
  print("  npm run orchestrator -- list                # see all sessions");
  print("  npm run orchestrator -- execute my-project  # resume project");
  print("  npm run orchestrator -- manual my-project   # file-queue mode");
  print("  npm run orchestrator -- hybrid my-project \\");
  print('    --map "qa_engineer=manual,ux_designer=ollama-local"');
  print("");
}

async function main(): Promise<void> {
  print(`\n`);
  print(`  ██╗   ██╗██╗██████╗ ███████╗ ██████╗ ██████╗ ██████╗ ███████╗██████╗`);
  print(`  ██║   ██║██║██╔══██╗██╔════╝██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗`);
  print(`  ██║   ██║██║██████╔╝█████╗  ██║     ██║   ██║██║  ██║█████╗  ██║  ██║`);
  print(`  ╚██╗ ██╔╝██║██╔══██╗██╔══╝  ██║     ██║   ██║██║  ██║██╔══╝  ██║  ██║`);
  print(`   ╚████╔╝ ██║██████╔╝███████╗╚██████╗╚██████╔╝██████╔╝███████╗██████╔╝`);
  print(`    ╚═══╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═════╝`);
  print(`\n                    🎯 Multi-Agent Orchestrator v2.0\n`);
  divider();

  // ── Environment Auto-Detection ──────────────────────────────────────────
  // Detects: AI coding tool, project context (standalone vs cloned-into),
  // stack, frameworks, and auto-configures integrations on first run.
  const envReport = await detectEnvironment({ autoConfig: true });

  // ── Notification System ─────────────────────────────────────────────────
  const notifier = getNotificationManager();
  if (notifier.isConfigured()) {
    const channels = notifier.getActiveChannels().join(", ");
    print(`  📡 Notifications active: ${channels}\n`);
  }

  divider();

  try {
    const command = process.argv[2];

    // Handle CLI commands
    if (command === "list") {
      listProjectSessions();
      return;
    }

    if (command === "execute") {
      const pid = process.argv[3];
      if (!pid) {
        print("Usage: npm run orchestrator:execute <project-id>");
        print("Run 'npm run orchestrator -- list' to see available projects.");
        process.exit(1);
      }
      print(`\nResuming execution for: ${pid}`);
      await executeAgents(pid, `./runs/prds/${pid}-prd.md`);
      return;
    }

    // ── Manual Mode ─────────────────────────────────────────────────────────
    // Runs the full orchestrator using the ManualProvider (file-queue).
    // All agent prompts are written as .md files for a human / AI coder to fill in.
    if (command === "manual") {
      const pid = process.argv[3];
      if (!pid) {
        print("Usage: npm run orchestrator -- manual <project-id>");
        print("  Runs the project using the file-queue (manual) provider.");
        print("  Agent prompts are written to runs/queue/<project-id>/");
        print("  Respond by creating the matching -response.md files.");
        print("\nRun 'npm run orchestrator -- list' to see available projects.");
        process.exit(1);
      }

      const prdPath = `./runs/prds/${pid}-prd.md`;
      if (!fs.existsSync(prdPath)) {
        print(`❌ PRD not found: ${prdPath}`);
        print("   Run the full flow first to generate a PRD, then use manual mode.");
        process.exit(1);
      }

      print(`\n🔧 MANUAL MODE — file-queue provider`);
      print(`   Project: ${pid}`);
      print(`   Queue:   ./runs/queue/${pid}/\n`);

      // Force manual provider via runtime override
      await initManualProvider();

      divider();
      print(`📋 Instructions will appear in runs/queue/${pid}/`);
      print(`   Use 'npm run queue -- status' to monitor progress`);
      print(`   Use 'npm run queue -- respond <step> <file>' to submit responses`);
      divider();

      await executeAgents(pid, prdPath);
      return;
    }

    // ── Hybrid Mode ─────────────────────────────────────────────────────────
    // Runs with mixed providers — some agents use API, others use file-queue.
    // Reads agent_provider_overrides from globals.yaml or accepts --map flag.
    if (command === "hybrid") {
      const pid = process.argv[3];
      if (!pid) {
        print("Usage: npm run orchestrator -- hybrid <project-id> [--map agent=provider,...]");
        print("  Runs with mixed providers per agent.");
        print("  Default overrides are read from globals.yaml → agent_provider_overrides");
        print("  Use --map to specify or override at runtime:");
        print('    --map "qa_engineer=manual,web_frontend_engineer=ollama-local"');
        print("\nRun 'npm run orchestrator -- list' to see available projects.");
        process.exit(1);
      }

      const prdPath = `./runs/prds/${pid}-prd.md`;
      if (!fs.existsSync(prdPath)) {
        print(`❌ PRD not found: ${prdPath}`);
        process.exit(1);
      }

      // Parse optional --map flag
      const runtimeOverrides: Record<string, string> = {};
      const mapIdx = process.argv.indexOf("--map");
      if (mapIdx !== -1 && process.argv[mapIdx + 1]) {
        const pairs = process.argv[mapIdx + 1]!.split(",");
        for (const pair of pairs) {
          const [agent, provider] = pair.split("=");
          if (agent && provider) {
            runtimeOverrides[agent.trim()] = provider.trim();
          }
        }
      }

      print(`\n🔀 HYBRID MODE — mixed providers`);
      print(`   Project: ${pid}`);

      // Initialize registry and apply overrides
      await initHybridProvider(runtimeOverrides);

      divider();
      await executeAgents(pid, prdPath);
      return;
    }

    // ── Help ────────────────────────────────────────────────────────────────
    if (command === "help" || command === "--help" || command === "-h") {
      printHelp();
      return;
    }

    if (command && !["list", "execute", "manual", "hybrid", "help"].includes(command)) {
      print(`❌ Unknown command: ${command}`);
      printHelp();
      process.exit(1);
    }

    // Full flow: Discovery → PRD → Configure → Execute
    // Phase 1: Discovery
    const { answers, projectId } = await runDiscovery();

    // Phase 2: Generate PRD
    const prdPath = await generatePRD(answers, projectId);

    // Phase 3: Configure Agents
    await configureAgents(answers, projectId, prdPath);

    // Phase 4: Execute Agents
    await executeAgents(projectId, prdPath);

  } catch (error) {
    print(`\n❌ Error: ${(error as Error).message}`);
    process.exit(1);
  }
}

main();
