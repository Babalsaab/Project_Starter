"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Link from "next/link";

// ─── Types ──────────────────────────────────────────────────────────────────

interface AgentEvent {
  id: string;
  type: string;
  timestamp: string;
  agent_id?: string;
  agent_title?: string;
  project_id?: string;
  phase?: string;
  message: string;
  details?: Record<string, unknown>;
  status?: "running" | "success" | "error" | "warning" | "info";
}

interface ActiveAgent {
  id: string;
  title: string;
  phase: string;
  status: "idle" | "thinking" | "working" | "complete" | "error";
  lastAction: string;
  startedAt: number;
  eventCount: number;
}

// ─── Config ─────────────────────────────────────────────────────────────────

const STATUS_COLORS: Record<string, { ring: string; bg: string; text: string; glow: string }> = {
  running: { ring: "ring-blue-400", bg: "bg-blue-500", text: "text-blue-400", glow: "shadow-blue-500/50" },
  success: { ring: "ring-emerald-400", bg: "bg-emerald-500", text: "text-emerald-400", glow: "shadow-emerald-500/50" },
  error: { ring: "ring-red-400", bg: "bg-red-500", text: "text-red-400", glow: "shadow-red-500/50" },
  warning: { ring: "ring-amber-400", bg: "bg-amber-500", text: "text-amber-400", glow: "shadow-amber-500/50" },
  info: { ring: "ring-purple-400", bg: "bg-purple-500", text: "text-purple-400", glow: "shadow-purple-500/50" },
};

const PHASE_COLORS: Record<string, string> = {
  Planning: "from-violet-600 to-purple-600",
  Design: "from-pink-600 to-rose-600",
  Build: "from-blue-600 to-cyan-600",
  Review: "from-amber-600 to-yellow-600",
  Testing: "from-emerald-600 to-green-600",
  Deploy: "from-orange-600 to-red-600",
};

const TYPE_ICONS: Record<string, string> = {
  agent_start: "▶",
  agent_complete: "✓",
  agent_error: "✗",
  agent_thinking: "◉",
  agent_output: "◈",
  quality_gate: "⬡",
  mentor_review: "★",
  skill_applied: "◆",
  pipeline_start: "⏵",
  pipeline_complete: "⏹",
  workflow_advance: "→",
  system_info: "ℹ",
  pipeline_step: "◎",
};

// ─── Component ──────────────────────────────────────────────────────────────

export default function LiveDashboardPage() {
  const [events, setEvents] = useState<AgentEvent[]>([]);
  const [activeAgents, setActiveAgents] = useState<Map<string, ActiveAgent>>(new Map());
  const [connected, setConnected] = useState(false);
  const [totalEvents, setTotalEvents] = useState(0);
  const feedRef = useRef<HTMLDivElement>(null);
  const eventSourceRef = useRef<EventSource | null>(null);

  const processEvent = useCallback((event: AgentEvent) => {
    setEvents((prev) => [event, ...prev].slice(0, 50)); // Keep last 50
    setTotalEvents((prev) => prev + 1);

    if (event.agent_id && event.agent_title) {
      setActiveAgents((prev) => {
        const next = new Map(prev);
        const existing = next.get(event.agent_id!) ?? {
          id: event.agent_id!,
          title: event.agent_title!,
          phase: event.phase ?? "Unknown",
          status: "idle" as const,
          lastAction: "",
          startedAt: Date.now(),
          eventCount: 0,
        };

        existing.lastAction = event.message;
        existing.eventCount++;
        existing.phase = event.phase ?? existing.phase;

        if (event.type === "agent_thinking") existing.status = "thinking";
        else if (event.type === "agent_start") existing.status = "working";
        else if (event.type === "agent_complete") existing.status = "complete";
        else if (event.type === "agent_error") existing.status = "error";
        else if (event.type === "agent_output") existing.status = "working";

        next.set(event.agent_id!, existing);
        return next;
      });
    }
  }, []);

  useEffect(() => {
    // Auth guard: verify session before connecting to SSE stream
    fetch("/api/orchestrator/sessions")
      .then((r) => {
        if (r.status === 401) {
          window.location.href = '/auth/signin';
        }
      })
      .catch(console.error);

    const eventSource = new EventSource("/api/orchestrator/events");
    eventSourceRef.current = eventSource;

    eventSource.onopen = () => setConnected(true);
    eventSource.onerror = () => setConnected(false);

    eventSource.onmessage = (e) => {
      try {
        const event = JSON.parse(e.data) as AgentEvent;
        processEvent(event);
      } catch {
        // Skip malformed events
      }
    };

    return () => {
      eventSource.close();
      eventSourceRef.current = null;
    };
  }, [processEvent]);

  const agentList = Array.from(activeAgents.values()).sort(
    (a, b) => b.eventCount - a.eventCount
  );

  // Group by phase
  const phases = new Map<string, ActiveAgent[]>();
  for (const agent of agentList) {
    const existing = phases.get(agent.phase) ?? [];
    existing.push(agent);
    phases.set(agent.phase, existing);
  }

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      {/* Header */}
      <header className="border-b border-gray-800 px-6 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link
              href="/orchestrator"
              className="text-gray-400 hover:text-white text-sm"
            >
              ← Dashboard
            </Link>
            <div>
              <h1 className="text-xl font-bold text-white flex items-center gap-3">
                <span className="relative flex h-3 w-3">
                  {connected && (
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
                  )}
                  <span
                    className={`relative inline-flex rounded-full h-3 w-3 ${connected ? "bg-emerald-500" : "bg-red-500"}`}
                  />
                </span>
                Live Agent Activity
              </h1>
              <p className="text-xs text-gray-500 mt-0.5">
                {connected ? "Connected" : "Disconnected"} · {totalEvents} events
                · {activeAgents.size} agents active
              </p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Agent Grid (2/3 width) */}
          <div className="lg:col-span-2">
            <h2 className="text-sm font-medium text-gray-400 uppercase tracking-wider mb-4">
              Active Agents by Phase
            </h2>

            {phases.size === 0 ? (
              <div className="border border-dashed border-gray-700 rounded-xl p-12 text-center">
                <motion.div
                  animate={{ opacity: [0.3, 1, 0.3] }}
                  transition={{ duration: 2, repeat: Infinity }}
                  className="text-gray-500 text-lg"
                >
                  Waiting for agent activity...
                </motion.div>
                <p className="text-gray-600 text-sm mt-2">
                  Events will appear here when agents start working
                </p>
              </div>
            ) : (
              <div className="space-y-6">
                <AnimatePresence>
                  {Array.from(phases.entries()).map(([phase, agents]) => (
                    <motion.div
                      key={phase}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0 }}
                      className="space-y-3"
                    >
                      {/* Phase Header */}
                      <div className="flex items-center gap-2">
                        <div
                          className={`h-1 w-8 rounded-full bg-gradient-to-r ${PHASE_COLORS[phase] ?? "from-gray-600 to-gray-500"}`}
                        />
                        <span className="text-xs font-medium text-gray-400 uppercase tracking-wider">
                          {phase}
                        </span>
                        <span className="text-xs text-gray-600">
                          ({agents.length} agent{agents.length !== 1 ? "s" : ""})
                        </span>
                      </div>

                      {/* Agent Cards */}
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <AnimatePresence>
                          {agents.map((agent) => (
                            <AgentCard key={agent.id} agent={agent} />
                          ))}
                        </AnimatePresence>
                      </div>
                    </motion.div>
                  ))}
                </AnimatePresence>
              </div>
            )}
          </div>

          {/* Event Feed (1/3 width) */}
          <div>
            <h2 className="text-sm font-medium text-gray-400 uppercase tracking-wider mb-4">
              Event Stream
            </h2>
            <div
              ref={feedRef}
              className="space-y-1 max-h-[calc(100vh-200px)] overflow-y-auto pr-2 scrollbar-thin"
            >
              <AnimatePresence>
                {events.map((event) => (
                  <EventRow key={event.id} event={event} />
                ))}
              </AnimatePresence>
              {events.length === 0 && (
                <div className="text-gray-600 text-sm text-center py-8">
                  No events yet
                </div>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

// ─── Agent Card ─────────────────────────────────────────────────────────────

function AgentCard({ agent }: { agent: ActiveAgent }) {
  const isActive = agent.status === "thinking" || agent.status === "working";

  return (
    <motion.div
      layout
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.9 }}
      className={`relative rounded-xl border p-4 transition-all ${
        isActive
          ? "border-blue-500/30 bg-gray-900/80 shadow-lg shadow-blue-500/10"
          : agent.status === "complete"
            ? "border-emerald-500/20 bg-gray-900/50"
            : agent.status === "error"
              ? "border-red-500/20 bg-gray-900/50"
              : "border-gray-800 bg-gray-900/30"
      }`}
    >
      {/* Pulse ring for active agents */}
      {isActive && (
        <motion.div
          className="absolute inset-0 rounded-xl border-2 border-blue-400/20"
          animate={{ scale: [1, 1.02, 1], opacity: [0.5, 0, 0.5] }}
          transition={{ duration: 2, repeat: Infinity }}
        />
      )}

      <div className="flex items-start gap-3">
        {/* Status Indicator */}
        <div className="relative mt-0.5">
          <div
            className={`w-8 h-8 rounded-lg flex items-center justify-center text-sm font-bold ${
              isActive
                ? "bg-blue-500/20 text-blue-400"
                : agent.status === "complete"
                  ? "bg-emerald-500/20 text-emerald-400"
                  : agent.status === "error"
                    ? "bg-red-500/20 text-red-400"
                    : "bg-gray-800 text-gray-500"
            }`}
          >
            {agent.title.charAt(0)}
          </div>
          {isActive && (
            <motion.div
              className="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full bg-blue-500"
              animate={{ scale: [1, 1.3, 1] }}
              transition={{ duration: 1, repeat: Infinity }}
            />
          )}
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="text-sm font-medium text-white truncate">
              {agent.title}
            </span>
            {isActive && (
              <motion.span
                className="text-xs text-blue-400"
                animate={{ opacity: [1, 0.3, 1] }}
                transition={{ duration: 1.5, repeat: Infinity }}
              >
                {agent.status === "thinking" ? "thinking..." : "working..."}
              </motion.span>
            )}
          </div>
          <p className="text-xs text-gray-500 truncate mt-0.5">
            {agent.lastAction}
          </p>
          <div className="flex items-center gap-2 mt-1.5">
            <span className="text-[10px] text-gray-600">
              {agent.eventCount} events
            </span>
            <StatusBadge status={agent.status} />
          </div>
        </div>
      </div>

      {/* Progress shimmer for active agents */}
      {isActive && (
        <motion.div
          className="absolute bottom-0 left-0 right-0 h-0.5 rounded-b-xl overflow-hidden"
        >
          <motion.div
            className="h-full bg-gradient-to-r from-transparent via-blue-500 to-transparent"
            animate={{ x: ["-100%", "100%"] }}
            transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
            style={{ width: "50%" }}
          />
        </motion.div>
      )}
    </motion.div>
  );
}

// ─── Event Row ──────────────────────────────────────────────────────────────

function EventRow({ event }: { event: AgentEvent }) {
  const color = STATUS_COLORS[event.status ?? "info"] ?? STATUS_COLORS["info"]!;
  const icon = TYPE_ICONS[event.type] ?? "·";
  const time = new Date(event.timestamp).toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });

  return (
    <motion.div
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      className="flex items-start gap-2 py-1.5 px-2 rounded-lg hover:bg-gray-900/50 group"
    >
      <span className={`text-xs mt-0.5 ${color.text} font-mono`}>{icon}</span>
      <div className="flex-1 min-w-0">
        <p className="text-xs text-gray-300 leading-relaxed truncate">
          {event.message}
        </p>
        <div className="flex items-center gap-2 mt-0.5">
          <span className="text-[10px] text-gray-600 font-mono">{time}</span>
          {event.agent_id && (
            <span className="text-[10px] text-gray-600 truncate">
              {event.agent_id}
            </span>
          )}
        </div>
      </div>
      <div className={`w-1.5 h-1.5 rounded-full ${color.bg} mt-1.5 flex-shrink-0`} />
    </motion.div>
  );
}

// ─── Status Badge ───────────────────────────────────────────────────────────

function StatusBadge({ status }: { status: string }) {
  const configs: Record<string, { label: string; color: string }> = {
    idle: { label: "Idle", color: "text-gray-500 bg-gray-800" },
    thinking: { label: "Thinking", color: "text-blue-400 bg-blue-500/10" },
    working: { label: "Working", color: "text-cyan-400 bg-cyan-500/10" },
    complete: { label: "Done", color: "text-emerald-400 bg-emerald-500/10" },
    error: { label: "Error", color: "text-red-400 bg-red-500/10" },
  };
  const config = configs[status] ?? configs["idle"]!;

  return (
    <span className={`text-[10px] px-1.5 py-0.5 rounded-full ${config.color}`}>
      {config.label}
    </span>
  );
}
