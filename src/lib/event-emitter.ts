/**
 * Server-side event emitter for live agent activity streaming.
 *
 * Provides a singleton event bus that the orchestrator executor
 * and API routes can use to broadcast agent activity events
 * to connected SSE clients.
 */

export type AgentEventType =
  | "agent_start"
  | "agent_complete"
  | "agent_error"
  | "agent_thinking"
  | "agent_output"
  | "pipeline_start"
  | "pipeline_complete"
  | "pipeline_step"
  | "quality_gate"
  | "mentor_review"
  | "skill_applied"
  | "workflow_advance"
  | "system_info";

export interface AgentEvent {
  id: string;
  type: AgentEventType;
  timestamp: string;
  agent_id?: string;
  agent_title?: string;
  project_id?: string;
  phase?: string;
  message: string;
  details?: Record<string, unknown>;
  status?: "running" | "success" | "error" | "warning" | "info";
}

type EventHandler = (event: AgentEvent) => void;

class EventBus {
  private handlers: Set<EventHandler> = new Set();

  subscribe(handler: EventHandler): () => void {
    this.handlers.add(handler);
    return () => this.handlers.delete(handler);
  }

  emit(event: Omit<AgentEvent, "id" | "timestamp">): void {
    const fullEvent: AgentEvent = {
      ...event,
      id: `evt_${crypto.randomUUID()}`,
      timestamp: new Date().toISOString(),
    };

    for (const handler of this.handlers) {
      try {
        handler(fullEvent);
      } catch {
        // Don't let one handler break others
      }
    }
  }

  get subscriberCount(): number {
    return this.handlers.size;
  }
}

// Singleton
export const agentEventBus = new EventBus();
