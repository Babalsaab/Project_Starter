/**
 * Workflow Engine MCP Tools
 *
 * Lobster-style YAML workflows with:
 * - Deterministic pipeline definitions
 * - Sequential, parallel, and conditional steps
 * - Approval gates with resume tokens
 * - Quality gates tied to skills
 * - Full execution tracking
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import {
  listWorkflows,
  getWorkflow,
  startWorkflow,
  advanceWorkflow,
  completeStep,
  approveStep,
  resumeWorkflow,
  listExecutions,
  getExecution,
  getExecutionStatus,
} from "../lib/workflow-engine.js";

export function registerWorkflowTools(server: McpServer): void {
  server.tool(
    "list_workflows",
    "List all available workflow definitions. Workflows are deterministic YAML pipelines with sequential, parallel, and conditional steps.",
    {},
    async () => {
      const workflows = listWorkflows();

      if (workflows.length === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: "No workflow definitions found.\n\nCreate YAML workflow files in `config/workflows/` to define reusable pipelines.\nUse `create_workflow` to generate a workflow from a template.",
            },
          ],
        };
      }

      let output = `# Available Workflows (${workflows.length})\n\n`;
      output += workflows
        .map(
          (w) =>
            `- **${w.name}** (\`${w.filename}\`)\n  ${w.description}\n  Trigger: ${w.trigger} | Steps: ${w.stepCount}`
        )
        .join("\n\n");

      output += `\n\n_Use \`get_workflow\` for full definition or \`run_workflow\` to start execution._`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "get_workflow",
    "Get the full YAML definition of a workflow including all steps, conditions, and gates.",
    {
      name: z.string().describe("Workflow name or filename"),
    },
    async ({ name }) => {
      const workflow = getWorkflow(name);
      if (!workflow) {
        const available = listWorkflows()
          .map((w) => `\`${w.name}\``)
          .join(", ");
        return {
          content: [
            {
              type: "text" as const,
              text: `Workflow "${name}" not found. Available: ${available || "(none)"}`,
            },
          ],
        };
      }

      let output = `# Workflow: ${workflow.name}\n\n`;
      output += `**Version:** ${workflow.version}\n`;
      output += `**Description:** ${workflow.description}\n`;
      output += `**Trigger:** ${workflow.trigger}\n\n`;

      if (workflow.inputs && Object.keys(workflow.inputs).length > 0) {
        output += `## Inputs\n`;
        for (const [key, spec] of Object.entries(workflow.inputs)) {
          const req = spec.required !== false ? " (required)" : "";
          const def = spec.default ? ` [default: ${spec.default}]` : "";
          output += `- **${key}**${req}: ${spec.description}${def}\n`;
        }
        output += "\n";
      }

      output += `## Steps\n\n`;
      for (let i = 0; i < workflow.steps.length; i++) {
        const step = workflow.steps[i]!;
        if ("parallel" in step) {
          output += `### ${i + 1}. ${step.name} (Parallel Group)\n`;
          if (step.depends_on?.length) {
            output += `  Depends on: ${step.depends_on.join(", ")}\n`;
          }
          for (const pStep of step.parallel) {
            output += `  - **${pStep.id}** → Agent: \`${pStep.agent}\` | Action: ${pStep.action}\n`;
          }
        } else if ("foreach" in step) {
          output += `### ${i + 1}. ${step.name} (Loop)\n`;
          output += `  Foreach: ${step.foreach} as \`${step.as}\`\n`;
        } else {
          output += `### ${i + 1}. ${step.name}\n`;
          output += `  **ID:** \`${step.id}\`\n`;
          if (step.agent) output += `  **Agent:** \`${step.agent}\`\n`;
          output += `  **Action:** ${step.action}\n`;
          if (step.depends_on?.length) {
            output += `  **Depends on:** ${step.depends_on.join(", ")}\n`;
          }
          if (step.condition) {
            output += `  **Condition:** \`${step.condition}\`\n`;
          }
          if (step.quality_gate) {
            output += `  **Quality Gate:** \`${step.quality_gate}\` skill\n`;
          }
          if (step.mentor_review) {
            output += `  **Mentor Review:** \`${step.mentor_review}\`\n`;
          }
          if (step.approval_required) {
            output += `  **Approval Required:** Yes (workflow pauses here)\n`;
          }
        }
        output += "\n";
      }

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "run_workflow",
    "Start executing a workflow. Returns an execution ID and resume token for tracking progress and resuming paused workflows.",
    {
      workflow: z.string().describe("Workflow name or filename to execute"),
      inputs: z
        .record(z.string(), z.string())
        .optional()
        .describe("Input parameters for the workflow as key-value pairs"),
    },
    async ({ workflow: workflowName, inputs }) => {
      try {
        const execution = startWorkflow(workflowName, inputs ?? {});

        // Advance to the first step
        const next = advanceWorkflow(execution.id);

        let output = `# Workflow Started\n\n`;
        output += `**Execution ID:** \`${execution.id}\`\n`;
        output += `**Workflow:** ${execution.workflow_name}\n`;
        output += `**Resume Token:** \`${execution.resume_token}\`\n`;
        output += `**Status:** ${execution.status}\n\n`;

        if (next.action === "run_step" && next.steps) {
          output += `## Next Step\n`;
          for (const step of next.steps) {
            output += `- **${step.id}**: ${step.action}`;
            if (step.agent) output += ` (Agent: \`${step.agent}\`)`;
            output += "\n";
          }
          output += `\nThe AI coder should now execute this step and call \`workflow_complete_step\` when done.`;
        } else if (next.action === "run_parallel") {
          output += `## Parallel Steps Ready\n`;
          for (const step of next.parallelGroup!.parallel) {
            output += `- **${step.id}**: ${step.action} (Agent: \`${step.agent}\`)\n`;
          }
          output += `\nExecute all steps in parallel. Call \`workflow_complete_step\` for each.`;
        } else if (next.action === "wait_approval") {
          output += `## Waiting for Approval\n`;
          output += `Step \`${next.approvalStep!.step.id}\` requires approval.\n`;
          output += `Approval token: \`${next.approvalStep!.token}\`\n`;
          output += `Call \`workflow_approve\` with this token to continue.`;
        }

        return { content: [{ type: "text" as const, text: output }] };
      } catch (err) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Failed to start workflow: ${(err as Error).message}`,
            },
          ],
        };
      }
    }
  );

  server.tool(
    "workflow_complete_step",
    "Mark a workflow step as completed (or failed). Advances the workflow to the next step.",
    {
      execution_id: z.string().describe("The workflow execution ID"),
      step_id: z.string().describe("The step ID to mark as completed"),
      output: z
        .record(z.string(), z.string())
        .optional()
        .describe("Step output values as key-value pairs"),
      error: z
        .string()
        .optional()
        .describe("Error message if the step failed"),
    },
    async ({ execution_id, step_id, output, error }) => {
      completeStep(execution_id, step_id, output, error);

      // Advance to next
      const next = advanceWorkflow(execution_id);

      let text = `Step \`${step_id}\` ${error ? "failed" : "completed"}.\n\n`;

      if (next.action === "run_step" && next.steps) {
        text += `**Next step:** ${next.steps.map((s) => `\`${s.id}\` (${s.action})`).join(", ")}`;
      } else if (next.action === "run_parallel") {
        text += `**Next:** Parallel group with ${next.parallelGroup!.parallel.length} steps`;
      } else if (next.action === "wait_approval") {
        text += `**Waiting for approval** on step \`${next.approvalStep!.step.id}\`\nToken: \`${next.approvalStep!.token}\``;
      } else if (next.action === "completed") {
        text += `**Workflow completed!**`;
      } else if (next.action === "failed") {
        text += `**Workflow failed.**`;
      }

      return { content: [{ type: "text" as const, text }] };
    }
  );

  server.tool(
    "workflow_approve",
    "Approve a workflow step that requires human approval. Resumes the workflow.",
    {
      execution_id: z.string().describe("The workflow execution ID"),
      token: z.string().describe("The approval token for the waiting step"),
    },
    async ({ execution_id, token }) => {
      const approved = approveStep(execution_id, token);
      if (!approved) {
        return {
          content: [
            { type: "text" as const, text: "Approval failed. Invalid execution ID or token." },
          ],
        };
      }

      const next = advanceWorkflow(execution_id);
      let text = `Step approved and workflow resumed.\n\n`;

      if (next.action === "run_step" && next.steps) {
        text += `**Next step:** ${next.steps.map((s) => `\`${s.id}\``).join(", ")}`;
      } else if (next.action === "completed") {
        text += `**Workflow completed!**`;
      }

      return { content: [{ type: "text" as const, text }] };
    }
  );

  server.tool(
    "workflow_resume",
    "Resume a paused or interrupted workflow using its resume token.",
    {
      execution_id: z.string().describe("The workflow execution ID"),
      resume_token: z.string().describe("The resume token from the original execution"),
    },
    async ({ execution_id, resume_token }) => {
      const resumed = resumeWorkflow(execution_id, resume_token);
      if (!resumed) {
        return {
          content: [
            { type: "text" as const, text: "Resume failed. Invalid execution ID or token." },
          ],
        };
      }

      const next = advanceWorkflow(execution_id);
      let text = `Workflow resumed from where it left off.\n\n`;

      if (next.action === "run_step" && next.steps) {
        text += `**Next step:** ${next.steps.map((s) => `\`${s.id}\``).join(", ")}`;
      } else if (next.action === "completed") {
        text += `**Workflow already completed.**`;
      }

      return { content: [{ type: "text" as const, text }] };
    }
  );

  server.tool(
    "workflow_status",
    "Check the execution status of a running workflow.",
    {
      execution_id: z.string().describe("The workflow execution ID"),
    },
    async ({ execution_id }) => {
      const status = getExecutionStatus(execution_id);
      if (!status) {
        return {
          content: [
            { type: "text" as const, text: `Execution "${execution_id}" not found.` },
          ],
        };
      }

      let output = `# Workflow Status: \`${execution_id}\`\n\n`;
      output += `**Status:** ${status.status}\n`;
      output += `**Progress:** ${status.progress.completed}/${status.progress.total} steps\n`;
      output += `**Running:** ${status.progress.running} | **Failed:** ${status.progress.failed} | **Waiting:** ${status.progress.waiting}\n`;

      if (status.currentStep) {
        output += `**Current Step:** \`${status.currentStep}\`\n`;
      }
      if (status.resumeToken) {
        output += `**Resume Token:** \`${status.resumeToken}\`\n`;
      }

      output += `\n## Steps\n`;
      for (const step of status.steps) {
        const icon =
          step.status === "completed" ? "[DONE]" :
          step.status === "running" ? "[....]" :
          step.status === "failed" ? "[FAIL]" :
          step.status === "waiting_approval" ? "[WAIT]" :
          step.status === "skipped" ? "[SKIP]" :
          "[    ]";
        output += `${icon} \`${step.id}\``;
        if (step.agent) output += ` — Agent: \`${step.agent}\``;
        if (step.error) output += ` — Error: ${step.error}`;
        output += "\n";
      }

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "list_workflow_executions",
    "List all workflow executions with their status and progress.",
    {},
    async () => {
      const executions = listExecutions();

      if (executions.length === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: "No workflow executions found. Use `run_workflow` to start one.",
            },
          ],
        };
      }

      let output = `# Workflow Executions (${executions.length})\n\n`;
      output += executions
        .map(
          (e) =>
            `- **${e.workflow}** (\`${e.id}\`)\n  Status: ${e.status} | Progress: ${e.progress} | Started: ${e.started_at}`
        )
        .join("\n\n");

      return { content: [{ type: "text" as const, text: output }] };
    }
  );
}
