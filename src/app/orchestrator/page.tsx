"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

interface Session {
  project_id: string;
  project_name: string;
  status: string;
  created_at: string;
  agent_count: number;
  progress: { total: number; done: number; failed: number; running: number };
  artifact_count: number;
}

interface AgentRegistry {
  chiefs: any[];
  tech: any[];
  marketing: any[];
  personas: string[];
  total: number;
}

const statusConfig: Record<string, { icon: string; color: string; bg: string }> = {
  initialising: { icon: "⏳", color: "text-yellow-600", bg: "bg-yellow-100" },
  running: { icon: "▶", color: "text-blue-600", bg: "bg-blue-100" },
  paused: { icon: "⏸", color: "text-gray-600", bg: "bg-gray-100" },
  complete: { icon: "✅", color: "text-green-600", bg: "bg-green-100" },
  failed: { icon: "❌", color: "text-red-600", bg: "bg-red-100" },
};

export default function OrchestratorPage() {
  const [sessions, setSessions] = useState<Session[]>([]);
  const [agents, setAgents] = useState<AgentRegistry | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      fetch("/api/orchestrator/sessions").then((r) => r.json()),
      fetch("/api/orchestrator/agents").then((r) => r.json()),
    ]).then(([sessionData, agentData]) => {
      setSessions(sessionData.sessions || []);
      setAgents(agentData);
      setLoading(false);
    });
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-gray-500 text-lg">Loading orchestrator...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">
              Vibecoded Orchestrator
            </h1>
            <p className="text-sm text-gray-500 mt-1">
              Multi-agent system — {agents?.total || 0} agents, {agents?.personas.length || 0} personas
            </p>
          </div>
          <div className="flex gap-3">
            <Link
              href="/"
              className="px-4 py-2 text-sm text-gray-600 hover:text-gray-900 border rounded-lg hover:bg-gray-50"
            >
              ← TaskFlow
            </Link>
            <Link
              href="/orchestrator/agents"
              className="px-4 py-2 text-sm bg-gray-900 text-white rounded-lg hover:bg-gray-800"
            >
              View All Agents
            </Link>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-8">
        {/* Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-4 gap-4 mb-8">
          <StatCard label="Total Agents" value={agents?.total || 0} sub="Chiefs + Specialists" />
          <StatCard label="Tech Agents" value={agents?.tech.length || 0} sub="CTO managed" />
          <StatCard label="Marketing Agents" value={agents?.marketing.length || 0} sub="CMO managed" />
          <StatCard label="Project Sessions" value={sessions.length} sub={`${sessions.filter(s => s.status === 'complete').length} completed`} />
        </div>

        {/* Sessions */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">
              Project Sessions
            </h2>
            <p className="text-sm text-gray-500">
              Run <code className="bg-gray-100 px-2 py-0.5 rounded text-xs">npm run orchestrator</code> to start a new project
            </p>
          </div>

          {sessions.length === 0 ? (
            <div className="bg-white border border-dashed border-gray-300 rounded-xl p-12 text-center">
              <p className="text-gray-500 text-lg mb-2">No sessions yet</p>
              <p className="text-gray-400 text-sm">
                Run <code className="bg-gray-100 px-2 py-0.5 rounded">npm run orchestrator</code> in
                your terminal to start the Discovery Agent flow.
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {sessions.map((session) => (
                <SessionCard key={session.project_id} session={session} />
              ))}
            </div>
          )}
        </div>

        {/* Quick Reference */}
        <div className="bg-white border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            CLI Commands
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
            <CmdRow cmd="npm run orchestrator" desc="Start discovery → PRD → agents → execute" />
            <CmdRow cmd="npm run orchestrator:list" desc="List all project sessions" />
            <CmdRow cmd="npm run orchestrator:execute <id>" desc="Re-run execution for a project" />
            <CmdRow cmd="npm run list-agents" desc="Show all 64 agents + 14 personas" />
            <CmdRow cmd="npm run generate:all-prds" desc="Generate 35+ PRD templates" />
            <CmdRow cmd="npm run dev" desc="Start this web dashboard" />
          </div>
        </div>
      </main>
    </div>
  );
}

function StatCard({ label, value, sub }: { label: string; value: number; sub: string }) {
  return (
    <div className="bg-white border rounded-xl p-5">
      <div className="text-sm text-gray-500">{label}</div>
      <div className="text-3xl font-bold text-gray-900 mt-1">{value}</div>
      <div className="text-xs text-gray-400 mt-1">{sub}</div>
    </div>
  );
}

function SessionCard({ session }: { session: Session }) {
  const config = statusConfig[session.status] ?? statusConfig['initialising'] ?? { icon: "⏳", color: "text-yellow-600", bg: "bg-yellow-100" };
  const progressPct =
    session.progress.total > 0
      ? Math.round((session.progress.done / session.progress.total) * 100)
      : 0;

  return (
    <Link
      href={`/orchestrator/${session.project_id}`}
      className="block bg-white border rounded-xl p-5 hover:border-gray-400 hover:shadow-sm transition-all"
    >
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <span className="text-lg">{config.icon}</span>
            <h3 className="font-semibold text-gray-900">
              {session.project_name}
            </h3>
            <span
              className={`px-2 py-0.5 rounded-full text-xs font-medium ${config.color} ${config.bg}`}
            >
              {session.status}
            </span>
          </div>
          <p className="text-sm text-gray-500 mt-1">
            {session.project_id} · {session.agent_count} agents ·{" "}
            {session.artifact_count} artifacts
          </p>
        </div>
        <div className="text-right text-sm text-gray-400">
          {new Date(session.created_at).toLocaleDateString()}
        </div>
      </div>

      {/* Progress bar */}
      {session.progress.total > 0 && (
        <div className="mt-3">
          <div className="flex justify-between text-xs text-gray-500 mb-1">
            <span>
              {session.progress.done}/{session.progress.total} steps complete
            </span>
            <span>{progressPct}%</span>
          </div>
          <div className="w-full bg-gray-100 rounded-full h-2">
            <div
              className="bg-green-500 h-2 rounded-full transition-all"
              style={{ width: `${progressPct}%` }}
            />
          </div>
        </div>
      )}
    </Link>
  );
}

function CmdRow({ cmd, desc }: { cmd: string; desc: string }) {
  return (
    <div className="flex items-start gap-3 p-2 rounded hover:bg-gray-50">
      <code className="bg-gray-900 text-green-400 px-2 py-1 rounded text-xs whitespace-nowrap">
        {cmd}
      </code>
      <span className="text-gray-600">{desc}</span>
    </div>
  );
}
