'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';

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

const statusConfig: Record<
  string,
  { icon: string; color: string; bg: string }
> = {
  initialising: { icon: '⏳', color: 'text-yellow-600', bg: 'bg-yellow-100' },
  running: { icon: '▶', color: 'text-blue-600', bg: 'bg-blue-100' },
  paused: { icon: '⏸', color: 'text-gray-600', bg: 'bg-gray-100' },
  complete: { icon: '✅', color: 'text-green-600', bg: 'bg-green-100' },
  failed: { icon: '❌', color: 'text-red-600', bg: 'bg-red-100' },
};

export default function OrchestratorPage() {
  const [sessions, setSessions] = useState<Session[]>([]);
  const [agents, setAgents] = useState<AgentRegistry | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/orchestrator/sessions')
      .then((r) => {
        if (r.status === 401) {
          window.location.href = '/auth/signin';
          return null;
        }
        return r.json();
      })
      .then((sessionData) => {
        if (!sessionData) {
          return;
        }
        setSessions(sessionData.sessions || []);
        fetch('/api/orchestrator/agents')
          .then((r) => r.json())
          .then((agentData) => {
            setAgents(agentData);
            setLoading(false);
          })
          .catch(console.error);
      })
      .catch(console.error);
  }, []);

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <div className="text-lg text-gray-500">Loading orchestrator...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="border-b border-gray-200 bg-white px-6 py-4">
        <div className="mx-auto flex max-w-7xl items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">
              Vibecoded Orchestrator
            </h1>
            <p className="mt-1 text-sm text-gray-500">
              Multi-agent system — {agents?.total || 0} agents,{' '}
              {agents?.personas.length || 0} personas
            </p>
          </div>
          <div className="flex gap-3">
            <Link
              href="/"
              className="rounded-lg border px-4 py-2 text-sm text-gray-600 hover:bg-gray-50 hover:text-gray-900"
            >
              ← TaskFlow
            </Link>
            <Link
              href="/orchestrator/live"
              className="flex items-center gap-1.5 rounded-lg border border-emerald-300 px-4 py-2 text-sm text-emerald-700 hover:bg-emerald-50"
            >
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />
                <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-500" />
              </span>
              Live View
            </Link>
            <Link
              href="/orchestrator/evaluation"
              className="rounded-lg border border-blue-300 px-4 py-2 text-sm text-blue-700 hover:bg-blue-50"
            >
              Evaluation
            </Link>
            <Link
              href="/orchestrator/improvement-loop"
              className="rounded-lg border border-purple-300 px-4 py-2 text-sm text-purple-700 hover:bg-purple-50"
            >
              Improvement
            </Link>
            <Link
              href="/orchestrator/agents"
              className="rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-800"
            >
              View All Agents
            </Link>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-7xl px-6 py-8">
        {/* Stats */}
        <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-4">
          <StatCard
            label="Total Agents"
            value={agents?.total || 0}
            sub="Chiefs + Specialists"
          />
          <StatCard
            label="Tech Agents"
            value={agents?.tech.length || 0}
            sub="CTO managed"
          />
          <StatCard
            label="Marketing Agents"
            value={agents?.marketing.length || 0}
            sub="CMO managed"
          />
          <StatCard
            label="Project Sessions"
            value={sessions.length}
            sub={`${sessions.filter((s) => s.status === 'complete').length} completed`}
          />
        </div>

        {/* CTO Evaluation */}
        <Link
          href="/orchestrator/evaluation"
          className="mb-8 block rounded-xl border bg-white p-6 transition-all hover:border-gray-400 hover:shadow-sm"
        >
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-gray-900">
                CTO Codebase Evaluation
              </h2>
              <p className="mt-1 text-sm text-gray-500">
                Evaluate any codebase across 21 categories with 495 parameters
              </p>
            </div>
            <span className="whitespace-nowrap rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white">
              Run Evaluation →
            </span>
          </div>
        </Link>

        {/* Continuous Improvement Loop */}
        <Link
          href="/orchestrator/improvement-loop"
          className="mb-8 block rounded-xl border bg-white p-6 transition-all hover:border-purple-400 hover:shadow-sm"
        >
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-gray-900">
                Continuous Improvement Loop
              </h2>
              <p className="mt-1 text-sm text-gray-500">
                Iterative evaluate → fix → re-evaluate cycle with automated code
                changes
              </p>
            </div>
            <span className="whitespace-nowrap rounded-lg bg-purple-600 px-4 py-2 text-sm font-medium text-white">
              Start Loop →
            </span>
          </div>
        </Link>

        {/* Sessions */}
        <div className="mb-8">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900">
              Project Sessions
            </h2>
            <p className="text-sm text-gray-500">
              Run{' '}
              <code className="rounded bg-gray-100 px-2 py-0.5 text-xs">
                npm run orchestrator
              </code>{' '}
              to start a new project
            </p>
          </div>

          {sessions.length === 0 ? (
            <div className="rounded-xl border border-dashed border-gray-300 bg-white p-12 text-center">
              <p className="mb-2 text-lg text-gray-500">No sessions yet</p>
              <p className="text-sm text-gray-400">
                Run{' '}
                <code className="rounded bg-gray-100 px-2 py-0.5">
                  npm run orchestrator
                </code>{' '}
                in your terminal to start the Discovery Agent flow.
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
        <div className="rounded-xl border bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            CLI Commands
          </h2>
          <div className="grid grid-cols-1 gap-3 text-sm md:grid-cols-2">
            <CmdRow
              cmd="npm run orchestrator"
              desc="Start discovery → PRD → agents → execute"
            />
            <CmdRow
              cmd="npm run orchestrator:list"
              desc="List all project sessions"
            />
            <CmdRow
              cmd="npm run orchestrator:execute <id>"
              desc="Re-run execution for a project"
            />
            <CmdRow
              cmd="npm run list-agents"
              desc="Show all 66 agents + 70 personas"
            />
            <CmdRow
              cmd="npm run generate:all-prds"
              desc="Generate 35+ PRD templates"
            />
            <CmdRow cmd="npm run evaluate" desc="Run CTO codebase evaluation" />
            <CmdRow
              cmd="npm run improve"
              desc="Run continuous improvement loop"
            />
            <CmdRow cmd="npm run dev" desc="Start this web dashboard" />
          </div>
        </div>
      </main>
    </div>
  );
}

function StatCard({
  label,
  value,
  sub,
}: {
  label: string;
  value: number;
  sub: string;
}) {
  return (
    <div className="rounded-xl border bg-white p-5">
      <div className="text-sm text-gray-500">{label}</div>
      <div className="mt-1 text-3xl font-bold text-gray-900">{value}</div>
      <div className="mt-1 text-xs text-gray-400">{sub}</div>
    </div>
  );
}

function SessionCard({ session }: { session: Session }) {
  const config = statusConfig[session.status] ??
    statusConfig['initialising'] ?? {
      icon: '⏳',
      color: 'text-yellow-600',
      bg: 'bg-yellow-100',
    };
  const progressPct =
    session.progress.total > 0
      ? Math.round((session.progress.done / session.progress.total) * 100)
      : 0;

  return (
    <Link
      href={`/orchestrator/${session.project_id}`}
      className="block rounded-xl border bg-white p-5 transition-all hover:border-gray-400 hover:shadow-sm"
    >
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <span className="text-lg">{config.icon}</span>
            <h3 className="font-semibold text-gray-900">
              {session.project_name}
            </h3>
            <span
              className={`rounded-full px-2 py-0.5 text-xs font-medium ${config.color} ${config.bg}`}
            >
              {session.status}
            </span>
          </div>
          <p className="mt-1 text-sm text-gray-500">
            {session.project_id} · {session.agent_count} agents ·{' '}
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
          <div className="mb-1 flex justify-between text-xs text-gray-500">
            <span>
              {session.progress.done}/{session.progress.total} steps complete
            </span>
            <span>{progressPct}%</span>
          </div>
          <div className="h-2 w-full rounded-full bg-gray-100">
            <div
              className="h-2 rounded-full bg-green-500 transition-all"
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
    <div className="flex items-start gap-3 rounded p-2 hover:bg-gray-50">
      <code className="whitespace-nowrap rounded bg-gray-900 px-2 py-1 text-xs text-green-400">
        {cmd}
      </code>
      <span className="text-gray-600">{desc}</span>
    </div>
  );
}
