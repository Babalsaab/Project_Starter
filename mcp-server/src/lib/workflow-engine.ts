/**
 * Workflow Engine — Lobster-style YAML Workflows
 *
 * Deterministic YAML-defined workflows with:
 * - Sequential and parallel step execution
 * - Conditional branching (if/else)
 * - Loop support (foreach)
 * - Approval gates (pause/resume with tokens)
 * - Quality gates tied to skill system
 * - Resume tokens for interrupted workflows
 * - Agent assignment per step
 * - Variable interpolation
 *
 * Surpasses OpenClaw's Lobster with mentor reviews,
 * quality gates, and parallel agent execution.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from "fs";
import { join } from "path";
import yaml from "js-yaml";

// ─── Types ──────────────────────────────────────────────────────────────────

export interface WorkflowStep {
  id: string;
  name: string;
  agent?: string;
  action: string;
  inputs?: Record<string, string>;
  outputs?: Record<string, string>;
  depends_on?: string[];
  condition?: string;
  quality_gate?: string; // skill ID to run as gate
  mentor_review?: string; // mentor ID for review
  approval_required?: boolean;
  timeout_minutes?: number;
  retry?: { max_attempts: number; backoff_seconds: number };
  on_failure?: "skip" | "abort" | "continue";
}

export interface WorkflowParallelGroup {
  id: string;
  name: string;
  parallel: WorkflowStep[];
  depends_on?: string[];
}

export interface WorkflowLoop {
  id: string;
  name: string;
  foreach: string; // Variable reference like "${{ inputs.files }}"
  as: string; // Loop variable name
  steps: Array<WorkflowStep | WorkflowParallelGroup>;
  depends_on?: string[];
}

export type WorkflowNode = WorkflowStep | WorkflowParallelGroup | WorkflowLoop;

export interface WorkflowDefinition {
  name: string;
  version: string;
  description: string;
  trigger: "manual" | "on_commit" | "on_pr" | "on_schedule" | "on_mcp_call";
  inputs?: Record<string, { type: string; description: string; default?: string; required?: boolean }>;
  outputs?: Record<string, { description: string; from_step: string; value: string }>;
  steps: WorkflowNode[];
  on_complete?: { notify?: string; artifact?: string };
  on_failure?: { notify?: string; rollback_steps?: string[] };
}

export type StepStatus = "pending" | "running" | "completed" | "failed" | "skipped" | "waiting_approval" | "paused";

export interface StepExecution {
  step_id: string;
  status: StepStatus;
  started_at?: string;
  completed_at?: string;
  output?: Record<string, string>;
  error?: string;
  attempt: number;
  approval_token?: string;
  agent_output?: string;
}

export interface WorkflowExecution {
  id: string;
  workflow_name: string;
  status: "pending" | "running" | "completed" | "failed" | "paused" | "waiting_approval";
  inputs: Record<string, string>;
  variables: Record<string, string>;
  steps: StepExecution[];
  started_at: string;
  completed_at?: string;
  current_step?: string;
  resume_token?: string;
  error?: string;
}

// ─── Paths ──────────────────────────────────────────────────────────────────

const ROOT = join(import.meta.dirname, "..", "..", "..");
const WORKFLOWS_DIR = join(ROOT, "config", "workflows");
const EXECUTIONS_DIR = join(ROOT, "runs", "workflows");

function ensureDirs(): void {
  if (!existsSync(WORKFLOWS_DIR)) mkdirSync(WORKFLOWS_DIR, { recursive: true });
  if (!existsSync(EXECUTIONS_DIR)) mkdirSync(EXECUTIONS_DIR, { recursive: true });
}

// ─── Workflow Cache ──────────────────────────────────────────────────────────

interface CachedWorkflow {
  definition: WorkflowDefinition;
  filename: string;
  loadedAt: number;
}

let workflowCache: Map<string, CachedWorkflow> | null = null;
const WORKFLOW_CACHE_TTL_MS = 30_000; // 30 seconds TTL
let workflowCacheTimestamp = 0;

function loadWorkflowCache(): Map<string, CachedWorkflow> {
  const now = Date.now();
  if (workflowCache && now - workflowCacheTimestamp < WORKFLOW_CACHE_TTL_MS) {
    return workflowCache;
  }

  ensureDirs();
  workflowCache = new Map();
  workflowCacheTimestamp = now;

  const files = readdirSync(WORKFLOWS_DIR).filter((f) => f.endsWith(".yaml") || f.endsWith(".yml"));
  for (const file of files) {
    try {
      const content = readFileSync(join(WORKFLOWS_DIR, file), "utf-8");
      const def = yaml.load(content) as WorkflowDefinition;
      workflowCache.set(file, { definition: def, filename: file, loadedAt: now });
    } catch {
      // Skip invalid workflow files
    }
  }

  return workflowCache;
}

export function invalidateWorkflowCache(): void {
  workflowCache = null;
  workflowCacheTimestamp = 0;
}

// ─── Workflow Loading ───────────────────────────────────────────────────────

export function listWorkflows(): Array<{ name: string; description: string; trigger: string; stepCount: number; filename: string }> {
  const cache = loadWorkflowCache();
  const workflows: Array<{ name: string; description: string; trigger: string; stepCount: number; filename: string }> = [];

  for (const [, entry] of cache) {
    const def = entry.definition;
    workflows.push({
      name: def.name,
      description: def.description,
      trigger: def.trigger,
      stepCount: countSteps(def.steps),
      filename: entry.filename,
    });
  }

  return workflows;
}

export function getWorkflow(nameOrFile: string): WorkflowDefinition | null {
  const cache = loadWorkflowCache();

  // Match by filename
  for (const [file, entry] of cache) {
    if (file === nameOrFile || file.replace(/\.(yaml|yml)$/, "") === nameOrFile) {
      return entry.definition;
    }
  }

  // Match by workflow name
  for (const [, entry] of cache) {
    if (entry.definition.name === nameOrFile) return entry.definition;
  }

  return null;
}

function countSteps(nodes: WorkflowNode[]): number {
  let count = 0;
  for (const node of nodes) {
    if ("parallel" in node) {
      count += node.parallel.length;
    } else if ("foreach" in node) {
      count += countSteps(node.steps) + 1;
    } else {
      count++;
    }
  }
  return count;
}

// ─── Workflow Execution ─────────────────────────────────────────────────────

function generateToken(): string {
  return `wf_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
}

export function startWorkflow(workflowName: string, inputs: Record<string, string>): WorkflowExecution {
  const workflow = getWorkflow(workflowName);
  if (!workflow) throw new Error(`Workflow "${workflowName}" not found`);

  // Validate required inputs
  if (workflow.inputs) {
    for (const [key, spec] of Object.entries(workflow.inputs)) {
      if (spec.required !== false && !inputs[key] && !spec.default) {
        throw new Error(`Missing required input: ${key}`);
      }
      if (!inputs[key] && spec.default) {
        inputs[key] = spec.default;
      }
    }
  }

  const execution: WorkflowExecution = {
    id: generateToken(),
    workflow_name: workflowName,
    status: "pending",
    inputs,
    variables: { ...inputs },
    steps: flattenSteps(workflow.steps).map((stepId) => ({
      step_id: stepId,
      status: "pending" as StepStatus,
      attempt: 0,
    })),
    started_at: new Date().toISOString(),
    resume_token: generateToken(),
  };

  saveExecution(execution);
  return execution;
}

/** Delimiter for composite step IDs — using :: to avoid conflicts with / in step names */
const STEP_ID_DELIM = "::";

function flattenSteps(nodes: WorkflowNode[]): string[] {
  const ids: string[] = [];
  for (const node of nodes) {
    if ("parallel" in node) {
      ids.push(node.id);
      for (const step of node.parallel) {
        ids.push(`${node.id}${STEP_ID_DELIM}${step.id}`);
      }
    } else if ("foreach" in node) {
      ids.push(node.id);
      for (const subId of flattenSteps(node.steps)) {
        ids.push(`${node.id}${STEP_ID_DELIM}${subId}`);
      }
    } else {
      ids.push(node.id);
    }
  }
  return ids;
}

/** Advance workflow to next step, returns what needs to run */
export function advanceWorkflow(executionId: string): {
  action: "run_step" | "run_parallel" | "wait_approval" | "completed" | "failed";
  steps?: WorkflowStep[];
  parallelGroup?: WorkflowParallelGroup;
  approvalStep?: { step: WorkflowStep; token: string };
} {
  const execution = loadExecution(executionId);
  if (!execution) throw new Error(`Execution "${executionId}" not found`);

  const workflow = getWorkflow(execution.workflow_name);
  if (!workflow) throw new Error(`Workflow "${execution.workflow_name}" not found`);

  execution.status = "running";

  for (const node of workflow.steps) {
    const stepExec = execution.steps.find((s) => s.step_id === node.id);
    if (!stepExec || stepExec.status !== "pending") continue;

    // Check dependencies
    if ("depends_on" in node && node.depends_on) {
      const depsReady = node.depends_on.every((dep) => {
        const depExec = execution.steps.find((s) => s.step_id === dep);
        return depExec?.status === "completed";
      });
      if (!depsReady) continue;
    }

    // Check condition
    if ("condition" in node && (node as WorkflowStep).condition) {
      const condResult = evaluateCondition((node as WorkflowStep).condition!, execution.variables);
      if (!condResult) {
        stepExec.status = "skipped";
        saveExecution(execution);
        continue;
      }
    }

    if ("parallel" in node) {
      // Parallel group
      stepExec.status = "running";
      stepExec.started_at = new Date().toISOString();
      for (const pStep of node.parallel) {
        const pExec = execution.steps.find((s) => s.step_id === `${node.id}${STEP_ID_DELIM}${pStep.id}`);
        if (pExec) {
          pExec.status = "running";
          pExec.started_at = new Date().toISOString();
        }
      }
      execution.current_step = node.id;
      saveExecution(execution);
      return { action: "run_parallel", parallelGroup: node };
    }

    if ("foreach" in node) {
      // Loop — expand into sequential steps
      stepExec.status = "running";
      stepExec.started_at = new Date().toISOString();
      execution.current_step = node.id;
      saveExecution(execution);
      // Return first inner step
      const innerSteps = node.steps.filter((s): s is WorkflowStep => !("parallel" in s) && !("foreach" in s));
      if (innerSteps.length > 0) {
        return { action: "run_step", steps: [innerSteps[0]!] };
      }
      continue;
    }

    // Single step
    const step = node as WorkflowStep;

    if (step.approval_required) {
      stepExec.status = "waiting_approval";
      stepExec.approval_token = generateToken();
      execution.status = "waiting_approval";
      execution.current_step = step.id;
      saveExecution(execution);
      return {
        action: "wait_approval",
        approvalStep: { step, token: stepExec.approval_token },
      };
    }

    stepExec.status = "running";
    stepExec.started_at = new Date().toISOString();
    stepExec.attempt++;
    execution.current_step = step.id;
    saveExecution(execution);
    return { action: "run_step", steps: [step] };
  }

  // Check if all done
  const allDone = execution.steps.every(
    (s) => s.status === "completed" || s.status === "skipped" || s.status === "failed"
  );
  if (allDone) {
    execution.status = "completed";
    execution.completed_at = new Date().toISOString();
    saveExecution(execution);
    return { action: "completed" };
  }

  // Check for failures
  const hasFailed = execution.steps.some((s) => s.status === "failed");
  if (hasFailed) {
    execution.status = "failed";
    saveExecution(execution);
    return { action: "failed" };
  }

  return { action: "completed" };
}

export function completeStep(executionId: string, stepId: string, output?: Record<string, string>, error?: string): void {
  const execution = loadExecution(executionId);
  if (!execution) return;

  const stepExec = execution.steps.find((s) => s.step_id === stepId);
  if (!stepExec) return;

  if (error) {
    stepExec.status = "failed";
    stepExec.error = error;
  } else {
    stepExec.status = "completed";
    stepExec.output = output;
  }
  stepExec.completed_at = new Date().toISOString();

  // Merge outputs into variables
  if (output) {
    for (const [key, value] of Object.entries(output)) {
      execution.variables[`steps.${stepId}.outputs.${key}`] = value;
    }
  }

  saveExecution(execution);
}

export function approveStep(executionId: string, token: string): boolean {
  const execution = loadExecution(executionId);
  if (!execution) return false;

  const stepExec = execution.steps.find(
    (s) => s.approval_token === token && s.status === "waiting_approval"
  );
  if (!stepExec) return false;

  stepExec.status = "pending"; // Reset to pending so advanceWorkflow picks it up
  stepExec.approval_token = undefined;
  execution.status = "running";
  saveExecution(execution);
  return true;
}

export function resumeWorkflow(executionId: string, resumeToken: string): boolean {
  const execution = loadExecution(executionId);
  if (!execution) return false;
  if (execution.resume_token !== resumeToken) return false;

  if (execution.status === "paused" || execution.status === "waiting_approval") {
    execution.status = "running";
    // Reset any waiting_approval steps to pending
    for (const step of execution.steps) {
      if (step.status === "waiting_approval") {
        step.status = "pending";
        step.approval_token = undefined;
      }
    }
    saveExecution(execution);
    return true;
  }
  return false;
}

// ─── Variable Interpolation ─────────────────────────────────────────────────

function evaluateCondition(condition: string, variables: Record<string, string>): boolean {
  // Simple condition evaluation: "${{ steps.review.outputs.quality_gate == 'pass' }}"
  const interpolated = interpolateVariables(condition, variables);

  // Handle equality checks
  const eqMatch = interpolated.match(/(.+?)\s*==\s*['"](.+?)['"]/);
  if (eqMatch) {
    return eqMatch[1]!.trim() === eqMatch[2]!.trim();
  }

  const neqMatch = interpolated.match(/(.+?)\s*!=\s*['"](.+?)['"]/);
  if (neqMatch) {
    return neqMatch[1]!.trim() !== neqMatch[2]!.trim();
  }

  // Boolean-like
  return interpolated !== "" && interpolated !== "false" && interpolated !== "0";
}

function interpolateVariables(template: string, variables: Record<string, string>): string {
  return template.replace(/\$\{\{\s*(.+?)\s*\}\}/g, (_, key: string) => {
    return variables[key.trim()] ?? "";
  });
}

// ─── Persistence ────────────────────────────────────────────────────────────

function saveExecution(execution: WorkflowExecution): void {
  ensureDirs();
  const filePath = join(EXECUTIONS_DIR, `${execution.id}.yaml`);
  writeFileSync(filePath, yaml.dump(execution, { lineWidth: -1 }), "utf-8");
}

function loadExecution(executionId: string): WorkflowExecution | null {
  const filePath = join(EXECUTIONS_DIR, `${executionId}.yaml`);
  if (!existsSync(filePath)) return null;
  return yaml.load(readFileSync(filePath, "utf-8")) as WorkflowExecution;
}

export function listExecutions(): Array<{ id: string; workflow: string; status: string; started_at: string; progress: string }> {
  ensureDirs();
  const files = readdirSync(EXECUTIONS_DIR).filter((f) => f.endsWith(".yaml"));
  const executions: Array<{ id: string; workflow: string; status: string; started_at: string; progress: string }> = [];

  for (const file of files) {
    try {
      const exec = yaml.load(readFileSync(join(EXECUTIONS_DIR, file), "utf-8")) as WorkflowExecution;
      const completed = exec.steps.filter((s) => s.status === "completed" || s.status === "skipped").length;
      executions.push({
        id: exec.id,
        workflow: exec.workflow_name,
        status: exec.status,
        started_at: exec.started_at,
        progress: `${completed}/${exec.steps.length}`,
      });
    } catch {
      // Skip invalid files
    }
  }

  return executions.sort((a, b) => b.started_at.localeCompare(a.started_at));
}

export function getExecution(executionId: string): WorkflowExecution | null {
  return loadExecution(executionId);
}

export function getExecutionStatus(executionId: string): {
  status: string;
  progress: { total: number; completed: number; running: number; failed: number; pending: number; waiting: number };
  currentStep?: string;
  resumeToken?: string;
  steps: Array<{ id: string; status: string; agent?: string; error?: string }>;
} | null {
  const execution = loadExecution(executionId);
  if (!execution) return null;

  const workflow = getWorkflow(execution.workflow_name);

  return {
    status: execution.status,
    progress: {
      total: execution.steps.length,
      completed: execution.steps.filter((s) => s.status === "completed").length,
      running: execution.steps.filter((s) => s.status === "running").length,
      failed: execution.steps.filter((s) => s.status === "failed").length,
      pending: execution.steps.filter((s) => s.status === "pending").length,
      waiting: execution.steps.filter((s) => s.status === "waiting_approval").length,
    },
    currentStep: execution.current_step,
    resumeToken: execution.resume_token,
    steps: execution.steps.map((s) => {
      const workflowStep = workflow?.steps.find((ws) => ws.id === s.step_id) as WorkflowStep | undefined;
      return {
        id: s.step_id,
        status: s.status,
        agent: workflowStep?.agent,
        error: s.error,
      };
    }),
  };
}
