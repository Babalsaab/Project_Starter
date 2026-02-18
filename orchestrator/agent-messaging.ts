/**
 * Agent-to-Agent Messaging System
 *
 * Inspired by OpenClaw's sessions_send / sessions_list / sessions_history tools.
 * Enables agents to communicate, share findings, and coordinate work
 * during pipeline execution — instead of only reading upstream artifacts.
 *
 * Key capabilities:
 * - Inter-agent messages with reply-back support
 * - Shared memory slots for compressed state between agents
 * - Agent discovery (list active agents and their capabilities)
 * - Message history for audit trail
 */

import * as fs from "fs";
import * as path from "path";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface AgentMessage {
  id: string;
  from_agent: string;
  to_agent: string;
  content: string;
  message_type: "handoff" | "query" | "result" | "feedback" | "broadcast";
  timestamp: string;
  reply_to?: string;
  metadata?: Record<string, unknown>;
}

export interface MemorySlot {
  key: string;
  value: string;
  set_by: string;
  updated_at: string;
  ttl_steps?: number; // expire after N pipeline steps
}

export interface AgentCapability {
  agent_id: string;
  title: string;
  domain: string;
  status: "pending" | "in_progress" | "done" | "failed";
  expected_outputs: string[];
  phase: number;
}

// ─── Agent Message Bus ────────────────────────────────────────────────────────

export class AgentMessageBus {
  private messages: AgentMessage[] = [];
  private memorySlots: Map<string, MemorySlot> = new Map();
  private agentRegistry: Map<string, AgentCapability> = new Map();
  private projectId: string;
  private persistPath: string;

  constructor(projectId: string) {
    this.projectId = projectId;
    this.persistPath = path.join(
      "./config/project-sessions",
      projectId,
      "message-bus.json"
    );
    this.loadState();
  }

  // ─── Agent Registration ───────────────────────────────────────────────

  registerAgent(capability: AgentCapability): void {
    this.agentRegistry.set(capability.agent_id, capability);
  }

  updateAgentStatus(
    agentId: string,
    status: AgentCapability["status"]
  ): void {
    const cap = this.agentRegistry.get(agentId);
    if (cap) {
      cap.status = status;
      this.agentRegistry.set(agentId, cap);
    }
  }

  /** OpenClaw-style sessions_list — discover active agents */
  listAgents(filter?: {
    status?: string;
    domain?: string;
  }): AgentCapability[] {
    let agents = Array.from(this.agentRegistry.values());
    if (filter?.status) {
      agents = agents.filter((a) => a.status === filter.status);
    }
    if (filter?.domain) {
      agents = agents.filter((a) => a.domain.includes(filter.domain!));
    }
    return agents;
  }

  // ─── Messaging ────────────────────────────────────────────────────────

  /** Send a message from one agent to another */
  send(
    fromAgent: string,
    toAgent: string,
    content: string,
    type: AgentMessage["message_type"] = "handoff",
    replyTo?: string
  ): AgentMessage {
    const msg: AgentMessage = {
      id: `msg-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
      from_agent: fromAgent,
      to_agent: toAgent,
      content,
      message_type: type,
      timestamp: new Date().toISOString(),
      reply_to: replyTo,
    };
    this.messages.push(msg);
    this.persistState();
    return msg;
  }

  /** Broadcast a message to all agents (e.g., CEO directives) */
  broadcast(
    fromAgent: string,
    content: string,
    type: AgentMessage["message_type"] = "broadcast"
  ): AgentMessage[] {
    const agents = Array.from(this.agentRegistry.keys()).filter(
      (id) => id !== fromAgent
    );
    return agents.map((toAgent) =>
      this.send(fromAgent, toAgent, content, type)
    );
  }

  /** Get messages for a specific agent (inbox) */
  getInbox(agentId: string): AgentMessage[] {
    return this.messages.filter((m) => m.to_agent === agentId);
  }

  /** Get conversation between two agents */
  getConversation(agentA: string, agentB: string): AgentMessage[] {
    return this.messages.filter(
      (m) =>
        (m.from_agent === agentA && m.to_agent === agentB) ||
        (m.from_agent === agentB && m.to_agent === agentA)
    );
  }

  /** OpenClaw-style sessions_history — full message log */
  getHistory(limit?: number): AgentMessage[] {
    const msgs = [...this.messages].sort(
      (a, b) =>
        new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
    );
    return limit ? msgs.slice(-limit) : msgs;
  }

  // ─── Shared Memory (implements orchestrator-schema memory_slots) ──────

  /** Set a shared memory slot (any agent can read/write) */
  setMemory(key: string, value: string, setBy: string, ttlSteps?: number): void {
    this.memorySlots.set(key, {
      key,
      value,
      set_by: setBy,
      updated_at: new Date().toISOString(),
      ttl_steps: ttlSteps,
    });
    this.persistState();
  }

  /** Read a shared memory slot */
  getMemory(key: string): string | null {
    return this.memorySlots.get(key)?.value ?? null;
  }

  /** List all memory slot keys */
  listMemoryKeys(): string[] {
    return Array.from(this.memorySlots.keys());
  }

  /** Compact memory — expire slots past their TTL */
  compactMemory(currentStep: number): number {
    let expired = 0;
    for (const [key, slot] of this.memorySlots) {
      if (slot.ttl_steps !== undefined && currentStep > slot.ttl_steps) {
        this.memorySlots.delete(key);
        expired++;
      }
    }
    if (expired > 0) this.persistState();
    return expired;
  }

  // ─── Context Builder (for injection into agent prompts) ───────────────

  /**
   * Builds a context string for an agent that includes:
   * - Relevant messages from other agents
   * - Shared memory slots it should know about
   * - Agent discovery info
   */
  buildContextForAgent(agentId: string): string {
    const parts: string[] = [];

    // 1. Inbox messages
    const inbox = this.getInbox(agentId);
    if (inbox.length > 0) {
      parts.push("## Messages from Other Agents\n");
      for (const msg of inbox.slice(-5)) {
        // Last 5 messages
        parts.push(
          `**From ${msg.from_agent}** (${msg.message_type}):\n${msg.content}\n`
        );
      }
    }

    // 2. Relevant memory slots
    const memoryKeys = this.listMemoryKeys();
    if (memoryKeys.length > 0) {
      parts.push("## Shared Project Context\n");
      for (const key of memoryKeys) {
        const slot = this.memorySlots.get(key)!;
        parts.push(`- **${key}** (set by ${slot.set_by}): ${slot.value}`);
      }
      parts.push("");
    }

    // 3. Active agent landscape (what's done, what's coming)
    const doneAgents = this.listAgents({ status: "done" });
    const pendingAgents = this.listAgents({ status: "pending" });
    if (doneAgents.length > 0 || pendingAgents.length > 0) {
      parts.push("## Agent Landscape\n");
      if (doneAgents.length > 0) {
        parts.push(
          `**Completed:** ${doneAgents.map((a) => a.agent_id).join(", ")}`
        );
      }
      if (pendingAgents.length > 0) {
        parts.push(
          `**Upcoming:** ${pendingAgents.map((a) => a.agent_id).join(", ")}`
        );
      }
      parts.push("");
    }

    return parts.join("\n");
  }

  // ─── Persistence ──────────────────────────────────────────────────────

  private persistState(): void {
    const state = {
      messages: this.messages,
      memory_slots: Object.fromEntries(this.memorySlots),
      agent_registry: Object.fromEntries(this.agentRegistry),
    };
    const dir = path.dirname(this.persistPath);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(this.persistPath, JSON.stringify(state, null, 2), "utf-8");
  }

  private loadState(): void {
    if (!fs.existsSync(this.persistPath)) return;
    try {
      const raw = JSON.parse(fs.readFileSync(this.persistPath, "utf-8"));
      this.messages = raw.messages || [];
      this.memorySlots = new Map(Object.entries(raw.memory_slots || {}));
      this.agentRegistry = new Map(
        Object.entries(raw.agent_registry || {})
      );
    } catch {
      // Corrupted state — start fresh
      this.messages = [];
      this.memorySlots = new Map();
      this.agentRegistry = new Map();
    }
  }

  /** Get stats for dashboard display */
  getStats(): {
    total_messages: number;
    memory_slots: number;
    registered_agents: number;
    agents_by_status: Record<string, number>;
  } {
    const byStatus: Record<string, number> = {};
    for (const agent of this.agentRegistry.values()) {
      byStatus[agent.status] = (byStatus[agent.status] || 0) + 1;
    }
    return {
      total_messages: this.messages.length,
      memory_slots: this.memorySlots.size,
      registered_agents: this.agentRegistry.size,
      agents_by_status: byStatus,
    };
  }
}
