"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";

interface StepData {
  id: string;
  label: string;
  owner_agent: string;
  status: "pending" | "in_progress" | "done" | "failed" | "skipped";
  priority: string;
  depends_on: string[];
  started_at?: string;
  completed_at?: string;
  error?: string;
  outputs?: { artifact_id: string; summary: string };
}

interface ArtifactData {
  id: string;
  agent_id: string;
  type: string;
  filename: string;
  summary: string;
  created_at: string;
  content?: string;
}

interface SessionDetail {
  session: {
    project_id: string;
    project_name: string;
    status: string;
    created_at: string;
    active_agents: string[];
    agent_configs: Record<string, any>;
    prd_path: string;
  };
  plan: { steps: StepData[]; status: string } | null;
  agentSelection: { selected_agents: Array<{ id: string; domain: string; reason: string }> } | null;
  prdContent: string | null;
  artifacts: ArtifactData[];
}

const statusIcons: Record<string, string> = {
  pending: "○",
  in_progress: "◉",
  done: "✓",
  failed: "✗",
  skipped: "⊘",
};

const statusColors: Record<string, string> = {
  pending: "text-gray-400",
  in_progress: "text-blue-500 animate-pulse",
  done: "text-green-500",
  failed: "text-red-500",
  skipped: "text-gray-300",
};

export default function SessionDetailPage() {
  const params = useParams();
  const projectId = params['id'] as string;
  const [data, setData] = useState<SessionDetail | null>(null);
  const [activeTab, setActiveTab] = useState<"pipeline" | "prd" | "artifacts">("pipeline");
  const [selectedArtifact, setSelectedArtifact] = useState<string | null>(null);
  const [artifactContent, setArtifactContent] = useState<string | null>(null);
  const [executing, setExecuting] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = () => {
      fetch(`/api/orchestrator/sessions/${projectId}`)
        .then((r) => r.json())
        .then((d) => {
          setData(d);
          setLoading(false);
        });
    };
    fetchData();
    // Poll for updates while running
    const interval = setInterval(fetchData, 3000);
    return () => clearInterval(interval);
  }, [projectId]);

  const handleExecute = async () => {
    setExecuting(true);
    await fetch(`/api/orchestrator/sessions/${projectId}`, { method: "POST" });
    // Trigger a refetch after short delay
    setTimeout(() => {
      fetch(`/api/orchestrator/sessions/${projectId}`)
        .then((r) => r.json())
        .then((d) => setData(d));
    }, 1000);
  };

  const viewArtifact = async (agentId: string) => {
    setSelectedArtifact(agentId);
    const res = await fetch(
      `/api/orchestrator/artifacts/${projectId}?agent=${agentId}`
    );
    const d = await res.json();
    setArtifactContent(d.content || "No content available");
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-gray-500">Loading session...</div>
      </div>
    );
  }

  if (!data?.session) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <p className="text-gray-500 text-lg mb-2">Session not found</p>
          <Link href="/orchestrator" className="text-blue-500 hover:underline">
            ← Back to orchestrator
          </Link>
        </div>
      </div>
    );
  }

  const { session, plan, agentSelection, prdContent, artifacts } = data;
  const steps = plan?.steps || [];
  const doneCount = steps.filter((s) => s.status === "done").length;
  const progressPct = steps.length > 0 ? Math.round((doneCount / steps.length) * 100) : 0;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center gap-2 text-sm text-gray-500 mb-2">
            <Link href="/orchestrator" className="hover:text-gray-900">
              Orchestrator
            </Link>
            <span>/</span>
            <span className="text-gray-900">{session.project_name}</span>
          </div>
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                {session.project_name}
              </h1>
              <p className="text-sm text-gray-500 mt-1">
                {session.project_id} · {session.active_agents.length} agents ·
                Status: {session.status}
              </p>
            </div>
            <div className="flex gap-3">
              {(session.status === "initialising" || session.status === "failed") && (
                <button
                  onClick={handleExecute}
                  disabled={executing}
                  className="px-5 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 font-medium"
                >
                  {executing ? "Starting..." : "▶ Execute Agents"}
                </button>
              )}
              {session.status === "running" && (
                <span className="px-4 py-2 bg-blue-100 text-blue-700 rounded-lg font-medium animate-pulse">
                  Running...
                </span>
              )}
            </div>
          </div>

          {/* Progress */}
          {steps.length > 0 && (
            <div className="mt-4">
              <div className="flex justify-between text-xs text-gray-500 mb-1">
                <span>{doneCount}/{steps.length} steps</span>
                <span>{progressPct}%</span>
              </div>
              <div className="w-full bg-gray-100 rounded-full h-2">
                <div
                  className="bg-green-500 h-2 rounded-full transition-all duration-500"
                  style={{ width: `${progressPct}%` }}
                />
              </div>
            </div>
          )}
        </div>
      </header>

      {/* Tabs */}
      <div className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-6 flex gap-6">
          {(["pipeline", "prd", "artifacts"] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`py-3 text-sm font-medium border-b-2 transition-colors ${
                activeTab === tab
                  ? "border-gray-900 text-gray-900"
                  : "border-transparent text-gray-500 hover:text-gray-700"
              }`}
            >
              {tab === "pipeline"
                ? `Pipeline (${steps.length})`
                : tab === "prd"
                ? "PRD"
                : `Artifacts (${artifacts.length})`}
            </button>
          ))}
        </div>
      </div>

      <main className="max-w-7xl mx-auto px-6 py-6">
        {/* Pipeline Tab */}
        {activeTab === "pipeline" && (
          <div className="space-y-2">
            {steps.length === 0 ? (
              <div className="bg-white border border-dashed rounded-xl p-12 text-center text-gray-500">
                No execution plan yet. Click &quot;Execute Agents&quot; to generate and run.
              </div>
            ) : (
              steps.map((step, i) => (
                <div
                  key={step.id}
                  className={`bg-white border rounded-lg p-4 flex items-center gap-4 ${
                    step.status === "in_progress" ? "border-blue-300 shadow-sm" : ""
                  }`}
                >
                  <div className="w-8 text-center">
                    <span className={`text-lg font-mono ${statusColors[step.status]}`}>
                      {statusIcons[step.status]}
                    </span>
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-gray-900">
                        {step.owner_agent}
                      </span>
                      <span className="text-xs text-gray-400">
                        Step {i + 1}
                      </span>
                    </div>
                    <p className="text-sm text-gray-500">{step.label}</p>
                    {step.error && (
                      <p className="text-xs text-red-500 mt-1">{step.error}</p>
                    )}
                  </div>
                  <div className="text-right">
                    {step.status === "done" && step.outputs?.artifact_id && (
                      <button
                        onClick={() => viewArtifact(step.owner_agent)}
                        className="text-xs text-blue-500 hover:underline"
                      >
                        View Output →
                      </button>
                    )}
                    {step.completed_at && (
                      <p className="text-xs text-gray-400">
                        {new Date(step.completed_at).toLocaleTimeString()}
                      </p>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {/* PRD Tab */}
        {activeTab === "prd" && (
          <div className="bg-white border rounded-xl p-6">
            {prdContent ? (
              <pre className="whitespace-pre-wrap text-sm text-gray-800 font-mono leading-relaxed">
                {prdContent}
              </pre>
            ) : (
              <p className="text-gray-500">No PRD generated yet.</p>
            )}
          </div>
        )}

        {/* Artifacts Tab */}
        {activeTab === "artifacts" && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <div className="space-y-2">
              {artifacts.length === 0 ? (
                <div className="bg-white border border-dashed rounded-xl p-8 text-center text-gray-500 text-sm">
                  No artifacts yet. Execute agents to generate outputs.
                </div>
              ) : (
                artifacts.map((a) => (
                  <button
                    key={a.id}
                    onClick={() => viewArtifact(a.agent_id)}
                    className={`w-full text-left bg-white border rounded-lg p-3 hover:border-gray-400 transition-colors ${
                      selectedArtifact === a.agent_id
                        ? "border-blue-500 ring-1 ring-blue-200"
                        : ""
                    }`}
                  >
                    <div className="font-medium text-sm text-gray-900">
                      {a.agent_id}
                    </div>
                    <div className="text-xs text-gray-500 mt-1">
                      {a.filename} · {a.type}
                    </div>
                    <div className="text-xs text-gray-400 mt-1 truncate">
                      {a.summary}
                    </div>
                  </button>
                ))
              )}
            </div>
            <div className="lg:col-span-2">
              {artifactContent ? (
                <div className="bg-white border rounded-xl p-6 sticky top-6">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="font-semibold text-gray-900">
                      {selectedArtifact}
                    </h3>
                    <button
                      onClick={() => {
                        setSelectedArtifact(null);
                        setArtifactContent(null);
                      }}
                      className="text-gray-400 hover:text-gray-600 text-sm"
                    >
                      Close
                    </button>
                  </div>
                  <pre className="whitespace-pre-wrap text-sm text-gray-800 font-mono leading-relaxed max-h-[70vh] overflow-auto">
                    {artifactContent}
                  </pre>
                </div>
              ) : (
                <div className="bg-white border border-dashed rounded-xl p-12 text-center text-gray-400 text-sm">
                  Select an artifact to view its content
                </div>
              )}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
