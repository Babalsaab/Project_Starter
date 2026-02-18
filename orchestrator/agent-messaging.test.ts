/**
 * Unit Tests — Agent Message Bus
 *
 * Tests for AgentMessageBus: registration, messaging, memory, context building
 */

import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { AgentMessageBus, AgentCapability } from "./agent-messaging";
import * as fs from "fs";
import * as path from "path";

// ─── Test Setup ───────────────────────────────────────────────────────────────

const TEST_PROJECT_ID = "__test_messaging__";
const TEST_PERSIST_PATH = path.join(
  "./config/project-sessions",
  TEST_PROJECT_ID,
  "message-bus.json"
);

function cleanup(): void {
  const dir = path.dirname(TEST_PERSIST_PATH);
  if (fs.existsSync(dir)) {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function makeAgent(id: string, domain = "tech/frontend"): AgentCapability {
  return {
    agent_id: id,
    title: id.replace(/_/g, " "),
    domain,
    status: "pending",
    expected_outputs: [`${id}_output`],
    phase: 1,
  };
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe("AgentMessageBus", () => {
  let bus: AgentMessageBus;

  beforeEach(() => {
    cleanup();
    bus = new AgentMessageBus(TEST_PROJECT_ID);
  });

  afterEach(() => {
    cleanup();
  });

  // ── Registration ──────────────────────────────────────────────────────

  describe("registerAgent", () => {
    it("should register an agent", () => {
      bus.registerAgent(makeAgent("qa_engineer"));
      const agents = bus.listAgents();
      expect(agents).toHaveLength(1);
      expect(agents[0]!.agent_id).toBe("qa_engineer");
    });

    it("should register multiple agents", () => {
      bus.registerAgent(makeAgent("qa_engineer"));
      bus.registerAgent(makeAgent("backend_engineer"));
      bus.registerAgent(makeAgent("ux_designer", "tech/design"));
      expect(bus.listAgents()).toHaveLength(3);
    });
  });

  describe("updateAgentStatus", () => {
    it("should update agent status", () => {
      bus.registerAgent(makeAgent("qa_engineer"));
      bus.updateAgentStatus("qa_engineer", "in_progress");
      const agents = bus.listAgents({ status: "in_progress" });
      expect(agents).toHaveLength(1);
      expect(agents[0]!.agent_id).toBe("qa_engineer");
    });

    it("should do nothing for unknown agents", () => {
      bus.updateAgentStatus("nonexistent", "done");
      expect(bus.listAgents()).toHaveLength(0);
    });
  });

  describe("listAgents", () => {
    it("should filter by status", () => {
      bus.registerAgent(makeAgent("qa_engineer"));
      bus.registerAgent(makeAgent("backend_engineer"));
      bus.updateAgentStatus("qa_engineer", "done");
      expect(bus.listAgents({ status: "done" })).toHaveLength(1);
      expect(bus.listAgents({ status: "pending" })).toHaveLength(1);
    });

    it("should filter by domain", () => {
      bus.registerAgent(makeAgent("qa_engineer", "tech/qa"));
      bus.registerAgent(makeAgent("seo_specialist", "marketing/seo"));
      expect(bus.listAgents({ domain: "tech" })).toHaveLength(1);
      expect(bus.listAgents({ domain: "marketing" })).toHaveLength(1);
    });
  });

  // ── Messaging ─────────────────────────────────────────────────────────

  describe("send", () => {
    it("should create a message with correct fields", () => {
      const msg = bus.send("qa_engineer", "backend_engineer", "Review done", "feedback");
      expect(msg.from_agent).toBe("qa_engineer");
      expect(msg.to_agent).toBe("backend_engineer");
      expect(msg.content).toBe("Review done");
      expect(msg.message_type).toBe("feedback");
      expect(msg.id).toMatch(/^msg-/);
      expect(msg.timestamp).toBeTruthy();
    });

    it("should support reply_to", () => {
      const original = bus.send("a", "b", "Question?", "query");
      const reply = bus.send("b", "a", "Answer.", "result", original.id);
      expect(reply.reply_to).toBe(original.id);
    });
  });

  describe("broadcast", () => {
    it("should send to all registered agents except sender", () => {
      bus.registerAgent(makeAgent("ceo"));
      bus.registerAgent(makeAgent("qa_engineer"));
      bus.registerAgent(makeAgent("backend_engineer"));
      const msgs = bus.broadcast("ceo", "Project kickoff", "broadcast");
      expect(msgs).toHaveLength(2);
      expect(msgs.map((m) => m.to_agent)).toContain("qa_engineer");
      expect(msgs.map((m) => m.to_agent)).toContain("backend_engineer");
      expect(msgs.map((m) => m.to_agent)).not.toContain("ceo");
    });
  });

  describe("getInbox", () => {
    it("should return only messages addressed to the agent", () => {
      bus.send("a", "b", "msg1");
      bus.send("c", "b", "msg2");
      bus.send("a", "c", "msg3");
      expect(bus.getInbox("b")).toHaveLength(2);
      expect(bus.getInbox("c")).toHaveLength(1);
      expect(bus.getInbox("a")).toHaveLength(0);
    });
  });

  describe("getConversation", () => {
    it("should return messages between two agents in both directions", () => {
      bus.send("a", "b", "hello");
      bus.send("b", "a", "hi back");
      bus.send("a", "c", "unrelated");
      expect(bus.getConversation("a", "b")).toHaveLength(2);
      expect(bus.getConversation("b", "a")).toHaveLength(2);
    });
  });

  describe("getHistory", () => {
    it("should return all messages sorted by timestamp", () => {
      bus.send("a", "b", "first");
      bus.send("c", "d", "second");
      bus.send("e", "f", "third");
      const history = bus.getHistory();
      expect(history).toHaveLength(3);
    });

    it("should respect limit parameter", () => {
      bus.send("a", "b", "1");
      bus.send("a", "b", "2");
      bus.send("a", "b", "3");
      expect(bus.getHistory(2)).toHaveLength(2);
    });
  });

  // ── Shared Memory ─────────────────────────────────────────────────────

  describe("setMemory / getMemory", () => {
    it("should store and retrieve values", () => {
      bus.setMemory("tech_stack", "Next.js + Prisma", "product_manager");
      expect(bus.getMemory("tech_stack")).toBe("Next.js + Prisma");
    });

    it("should return null for unknown keys", () => {
      expect(bus.getMemory("nonexistent")).toBeNull();
    });

    it("should overwrite existing keys", () => {
      bus.setMemory("version", "1.0", "pm");
      bus.setMemory("version", "2.0", "pm");
      expect(bus.getMemory("version")).toBe("2.0");
    });
  });

  describe("listMemoryKeys", () => {
    it("should list all stored keys", () => {
      bus.setMemory("a", "1", "agent");
      bus.setMemory("b", "2", "agent");
      const keys = bus.listMemoryKeys();
      expect(keys).toContain("a");
      expect(keys).toContain("b");
      expect(keys).toHaveLength(2);
    });
  });

  describe("compactMemory", () => {
    it("should expire slots past their TTL", () => {
      bus.setMemory("volatile", "data", "agent", 5); // expires after step 5
      bus.setMemory("permanent", "data", "agent"); // no TTL
      const expired = bus.compactMemory(10);
      expect(expired).toBe(1);
      expect(bus.getMemory("volatile")).toBeNull();
      expect(bus.getMemory("permanent")).toBe("data");
    });

    it("should keep slots within TTL", () => {
      bus.setMemory("fresh", "data", "agent", 10);
      const expired = bus.compactMemory(5);
      expect(expired).toBe(0);
      expect(bus.getMemory("fresh")).toBe("data");
    });
  });

  // ── Context Builder ───────────────────────────────────────────────────

  describe("buildContextForAgent", () => {
    it("should include inbox messages", () => {
      bus.send("qa_engineer", "backend_engineer", "Found 3 bugs");
      const context = bus.buildContextForAgent("backend_engineer");
      expect(context).toContain("Found 3 bugs");
      expect(context).toContain("qa_engineer");
    });

    it("should include shared memory", () => {
      bus.setMemory("api_base_url", "/api/v2", "api_designer");
      const context = bus.buildContextForAgent("backend_engineer");
      expect(context).toContain("api_base_url");
      expect(context).toContain("/api/v2");
    });

    it("should include agent landscape", () => {
      bus.registerAgent(makeAgent("qa_engineer"));
      bus.registerAgent(makeAgent("backend_engineer"));
      bus.updateAgentStatus("qa_engineer", "done");
      const context = bus.buildContextForAgent("backend_engineer");
      expect(context).toContain("Completed");
      expect(context).toContain("qa_engineer");
    });

    it("should return empty string when nothing exists", () => {
      const context = bus.buildContextForAgent("nonexistent");
      expect(context).toBe("");
    });
  });

  // ── Persistence ───────────────────────────────────────────────────────

  describe("persistence", () => {
    it("should persist and reload state", () => {
      bus.registerAgent(makeAgent("qa_engineer"));
      bus.send("a", "b", "persisted message");
      bus.setMemory("key", "value", "agent");

      // Create a new bus instance — should load from disk
      const bus2 = new AgentMessageBus(TEST_PROJECT_ID);
      expect(bus2.listAgents()).toHaveLength(1);
      expect(bus2.getInbox("b")).toHaveLength(1);
      expect(bus2.getMemory("key")).toBe("value");
    });

    it("should handle corrupted state gracefully", () => {
      const dir = path.dirname(TEST_PERSIST_PATH);
      fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(TEST_PERSIST_PATH, "NOT VALID JSON");

      const bus2 = new AgentMessageBus(TEST_PROJECT_ID);
      expect(bus2.listAgents()).toHaveLength(0);
      expect(bus2.getHistory()).toHaveLength(0);
    });
  });

  // ── Stats ─────────────────────────────────────────────────────────────

  describe("getStats", () => {
    it("should return correct statistics", () => {
      bus.registerAgent(makeAgent("qa_engineer"));
      bus.registerAgent(makeAgent("backend_engineer"));
      bus.updateAgentStatus("qa_engineer", "done");
      bus.send("a", "b", "msg");
      bus.setMemory("k", "v", "a");

      const stats = bus.getStats();
      expect(stats.total_messages).toBe(1);
      expect(stats.memory_slots).toBe(1);
      expect(stats.registered_agents).toBe(2);
      expect(stats.agents_by_status['done']).toBe(1);
      expect(stats.agents_by_status['pending']).toBe(1);
    });
  });
});
