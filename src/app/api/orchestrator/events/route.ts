/**
 * SSE (Server-Sent Events) endpoint for live agent activity streaming.
 *
 * GET /api/orchestrator/events
 *
 * Streams real-time events:
 * - Agent start/complete/error
 * - Pipeline progress
 * - Quality gate results
 * - Mentor reviews
 * - Skill applications
 *
 * Also emits periodic heartbeats and demo events for the live dashboard.
 */

import { agentEventBus, type AgentEvent } from "@/lib/event-emitter";
import { auth } from "@/../../auth";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET(): Promise<Response> {
  // Auth check for SSE endpoint
  try {
    const session = await auth();
    if (!session?.user?.email) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
  } catch {
    return new Response(JSON.stringify({ error: "Authentication error" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const encoder = new TextEncoder();

  // Hoist cleanup handles so cancel() can access them
  let heartbeat: ReturnType<typeof setInterval>;
  let demoInterval: ReturnType<typeof setInterval>;
  let unsubscribe: () => void;

  const stream = new ReadableStream({
    start(controller) {
      // Send initial connection event
      const connectEvent: AgentEvent = {
        id: `evt_${Date.now()}`,
        type: "system_info",
        timestamp: new Date().toISOString(),
        message: "Connected to live agent event stream",
        status: "info",
        details: { subscribers: agentEventBus.subscriberCount + 1 },
      };
      controller.enqueue(
        encoder.encode(`data: ${JSON.stringify(connectEvent)}\n\n`)
      );

      // Subscribe to the event bus
      unsubscribe = agentEventBus.subscribe((event) => {
        try {
          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify(event)}\n\n`)
          );
        } catch {
          // Stream closed — cancel() will handle cleanup
        }
      });

      // Heartbeat every 15 seconds to keep connection alive
      heartbeat = setInterval(() => {
        try {
          controller.enqueue(
            encoder.encode(`: heartbeat ${new Date().toISOString()}\n\n`)
          );
        } catch {
          // Stream closed — cancel() will handle cleanup
        }
      }, 15000);

      // Demo mode: emit simulated agent events for the live dashboard
      // These show what real events look like during pipeline execution
      const demoAgents = [
        { id: "product_manager", title: "Product Manager", phase: "Planning" },
        { id: "ux_designer", title: "UX Designer", phase: "Design" },
        { id: "web_frontend_engineer", title: "Frontend Engineer", phase: "Build" },
        { id: "backend_engineer", title: "Backend Engineer", phase: "Build" },
        { id: "security_engineer", title: "Security Engineer", phase: "Review" },
        { id: "qa_engineer", title: "QA Engineer", phase: "Testing" },
        { id: "devops_engineer", title: "DevOps Engineer", phase: "Deploy" },
      ];

      let demoIndex = 0;
      demoInterval = setInterval(() => {
        try {
          const agent = demoAgents[demoIndex % demoAgents.length]!;
          const actions = [
            { type: "agent_thinking" as const, msg: `${agent.title} is analyzing requirements...`, status: "running" as const },
            { type: "agent_output" as const, msg: `${agent.title} generated design specifications`, status: "success" as const },
            { type: "quality_gate" as const, msg: `Code quality check passed for ${agent.title}`, status: "success" as const },
            { type: "mentor_review" as const, msg: `Mentor review requested by ${agent.title}`, status: "info" as const },
            { type: "agent_complete" as const, msg: `${agent.title} completed task`, status: "success" as const },
          ];
          const action = actions[demoIndex % actions.length]!;

          const event: AgentEvent = {
            id: `demo_${Date.now()}`,
            type: action.type,
            timestamp: new Date().toISOString(),
            agent_id: agent.id,
            agent_title: agent.title,
            phase: agent.phase,
            message: action.msg,
            status: action.status,
            details: { demo: true },
          };

          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify(event)}\n\n`)
          );
          demoIndex++;
        } catch {
          // Stream closed — cancel() will handle cleanup
        }
      }, 3000);
    },
    cancel() {
      clearInterval(heartbeat);
      clearInterval(demoInterval);
      unsubscribe();
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache, no-transform",
      Connection: "keep-alive",
      "X-Accel-Buffering": "no",
    },
  });
}
