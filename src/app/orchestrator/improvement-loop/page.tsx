'use client';

import { Suspense, useEffect, useState, useRef, useCallback } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { motion, AnimatePresence } from 'framer-motion';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';

// ─── Types ──────────────────────────────────────────────────────────────────

interface CILConfig {
  codebase_path: string;
  max_iterations: number;
  target_score?: number;
  target_grade?: string;
  evaluation_mode: string;
  focus_categories?: string[];
  auto_implement: boolean;
  coder?: string;
}

interface PhaseState {
  status: 'pending' | 'running' | 'completed' | 'failed' | 'skipped';
  started_at?: string;
  completed_at?: string;
  error?: string;
}

interface IterationState {
  iteration: number;
  status: 'pending' | 'running' | 'completed' | 'failed';
  phases: Record<string, PhaseState>;
  overall_score?: number;
  grade?: string;
  findings_total?: number;
  findings_resolved?: number;
  findings_new?: number;
  score_delta?: number;
  started_at?: string;
  completed_at?: string;
  assigned_agents?: string[];
}

interface CILSummary {
  total_iterations: number;
  initial_score: number;
  final_score: number;
  total_improvement: number;
  initial_grade: string;
  final_grade: string;
  total_findings_resolved: number;
  total_findings_remaining: number;
  best_iteration: number;
  stop_reason: string;
  agent_contributions: Array<{
    agent_id: string;
    findings_resolved: number;
    categories_improved: string[];
  }>;
}

interface CILState {
  id: string;
  config: CILConfig;
  status: 'running' | 'paused' | 'completed' | 'failed';
  current_iteration: number;
  current_phase: string;
  iterations: IterationState[];
  started_at: string;
  updated_at: string;
  summary?: CILSummary;
  placeholder_mode?: boolean;
}

interface Finding {
  id: number;
  category: string;
  severity: string;
  description: string;
  file?: string;
  line?: number;
  remediation: string;
}

interface IterationFinding {
  findings: Finding[];
  categories: Array<{
    id: string;
    name: string;
    score: number;
    grade: string;
    findings_count: number;
  }>;
  overall_score: number;
  grade: string;
}

interface CILRun {
  id: string;
  status: string;
  current_iteration: number;
  current_phase: string;
  config: CILConfig;
  iterations: IterationState[];
  started_at: string;
  updated_at: string;
  summary?: CILSummary;
}

interface ProjectOption {
  id: string;
  name: string;
  path: string;
}

// ─── Constants ──────────────────────────────────────────────────────────────

const ALL_CATEGORIES = [
  'code_quality',
  'architecture',
  'security',
  'performance',
  'testing',
  'devops',
  'scalability',
  'reliability',
  'data_architecture',
  'api_design',
  'observability',
  'frontend',
  'backend',
  'mobile',
  'documentation',
  'developer_experience',
  'maintainability',
  'compliance',
  'cost_efficiency',
  'innovation',
  'uiux_consistency',
];

const PHASE_LABELS: Record<string, string> = {
  evaluate: 'Evaluating',
  triage: 'Triaging',
  remediate: 'Remediating',
  implement: 'Implementing',
  compare: 'Comparing',
};

const PHASE_ORDER = ['evaluate', 'triage', 'remediate', 'implement', 'compare'];

// ─── Helpers ────────────────────────────────────────────────────────────────

function gradeColor(grade: string): string {
  if (grade.startsWith('A')) {
    return 'text-green-600';
  }
  if (grade.startsWith('B')) {
    return 'text-blue-600';
  }
  if (grade.startsWith('C')) {
    return 'text-yellow-600';
  }
  return 'text-red-600';
}

function _gradeBg(grade: string): string {
  if (grade.startsWith('A')) {
    return 'bg-green-100 text-green-800';
  }
  if (grade.startsWith('B')) {
    return 'bg-blue-100 text-blue-800';
  }
  if (grade.startsWith('C')) {
    return 'bg-yellow-100 text-yellow-800';
  }
  return 'bg-red-100 text-red-800';
}

function phaseIcon(status: string): string {
  if (status === 'completed') {
    return '\u2705';
  }
  if (status === 'running') {
    return '\u23f3';
  }
  if (status === 'failed') {
    return '\u274c';
  }
  if (status === 'skipped') {
    return '\u23ed\ufe0f';
  }
  return '\u2b55';
}

function formatElapsed(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${String(s).padStart(2, '0')}`;
}

// ─── Main Page ──────────────────────────────────────────────────────────────

export default function ImprovementLoopPageWrapper() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-screen items-center justify-center bg-gray-50 text-gray-400">
          Loading...
        </div>
      }
    >
      <ImprovementLoopPage />
    </Suspense>
  );
}

function ImprovementLoopPage() {
  const searchParams = useSearchParams();
  const [view, setView] = useState<'setup' | 'running' | 'results'>('setup');

  // Setup state
  const [projects, setProjects] = useState<ProjectOption[]>([]);
  const [codebasePath, setCodebasePath] = useState('');
  const [manualPath, setManualPath] = useState('');
  const [maxIterations, setMaxIterations] = useState(5);
  const [targetScore, setTargetScore] = useState('');
  const [evalMode, setEvalMode] = useState<'quick' | 'standard' | 'enhanced'>(
    'standard'
  );
  const [focusCategories, setFocusCategories] = useState<string[]>([]);
  const [autoImplement, setAutoImplement] = useState(true);
  const [coderBackend, setCoderBackend] = useState<string>('claude-code');
  const [previousRuns, setPreviousRuns] = useState<CILRun[]>([]);
  const [prefilled, setPrefilled] = useState(false);

  // Running state
  const [cilId, setCilId] = useState<string | null>(null);
  const [cilState, setCilState] = useState<CILState | null>(null);
  const [elapsed, setElapsed] = useState(0);
  const [iterationFindings, setIterationFindings] = useState<
    Record<string, IterationFinding>
  >({});

  // UI state
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const pollingRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // ─── Pre-fill from URL params (linked from evaluation page) ──────────

  useEffect(() => {
    const pathParam = searchParams.get('path');
    const modeParam = searchParams.get('mode');
    const focusParam = searchParams.get('focus');

    if (pathParam) {
      setManualPath(pathParam);
      setCodebasePath(pathParam);
      setPrefilled(true);
    }
    if (modeParam && ['quick', 'standard', 'enhanced'].includes(modeParam)) {
      setEvalMode(modeParam as 'quick' | 'standard' | 'enhanced');
    }
    if (focusParam) {
      const cats = focusParam.split(',').filter((c) => c.length > 0);
      if (cats.length > 0) {
        setFocusCategories(cats);
      }
    }
  }, [searchParams]);

  // ─── Data Fetching ──────────────────────────────────────────────────────

  // Fetch projects and previous runs on mount
  useEffect(() => {
    Promise.all([
      fetch('/api/orchestrator/evaluation').then((r) => {
        if (r.status === 401) {
          window.location.href = '/auth/signin';
          return null;
        }
        return r.json();
      }),
      fetch('/api/orchestrator/improvement-loop')
        .then((r) => r.json())
        .catch(() => ({ runs: [] })),
    ])
      .then(([evalData, cilData]) => {
        if (evalData?.projects) {
          setProjects(evalData.projects);
        }
        if (cilData?.runs) {
          setPreviousRuns(cilData.runs);
        }
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  // Cleanup polling on unmount
  useEffect(() => {
    return () => {
      if (pollingRef.current) {
        clearInterval(pollingRef.current);
      }
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, []);

  // Poll for CIL progress
  const startPolling = useCallback((id: string) => {
    if (pollingRef.current) {
      clearInterval(pollingRef.current);
    }
    if (timerRef.current) {
      clearInterval(timerRef.current);
    }

    setElapsed(0);
    timerRef.current = setInterval(() => setElapsed((e) => e + 1), 1000);

    pollingRef.current = setInterval(async () => {
      try {
        const res = await fetch(`/api/orchestrator/improvement-loop/${id}`);
        if (!res.ok) {
          return;
        }
        const data = await res.json();
        if (data.state) {
          setCilState(data.state as CILState);
          if (data.iterationFindings) {
            setIterationFindings(data.iterationFindings);
          }

          // Check if loop is done
          const status = data.state.status;
          if (status === 'completed' || status === 'failed') {
            if (pollingRef.current) {
              clearInterval(pollingRef.current);
            }
            if (timerRef.current) {
              clearInterval(timerRef.current);
            }
            setView('results');
          }
        }
      } catch {
        // continue polling
      }
    }, 3000);
  }, []);

  // ─── Actions ────────────────────────────────────────────────────────────

  const startLoop = useCallback(async () => {
    const path = codebasePath || manualPath;
    if (!path) {
      return;
    }
    setStarting(true);
    setError(null);

    try {
      const res = await fetch('/api/orchestrator/improvement-loop', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          codebase_path: path,
          max_iterations: maxIterations,
          target_score: targetScore ? parseFloat(targetScore) : undefined,
          evaluation_mode: evalMode,
          focus_categories:
            focusCategories.length > 0 ? focusCategories : undefined,
          auto_implement: autoImplement,
          coder: coderBackend,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        setError(data.error || 'Failed to start improvement loop');
        setStarting(false);
        return;
      }

      setCilId(data.id);
      setView('running');
      setStarting(false);
      startPolling(data.id);
    } catch (err) {
      setError((err as Error).message);
      setStarting(false);
    }
  }, [
    codebasePath,
    manualPath,
    maxIterations,
    targetScore,
    evalMode,
    focusCategories,
    autoImplement,
    startPolling,
  ]);

  const pauseLoop = useCallback(async () => {
    if (!cilId) {
      return;
    }
    await fetch(`/api/orchestrator/improvement-loop/${cilId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'pause' }),
    });
  }, [cilId]);

  const resumeLoop = useCallback(async () => {
    if (!cilId) {
      return;
    }
    await fetch(`/api/orchestrator/improvement-loop/${cilId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'resume' }),
    });
  }, [cilId]);

  const viewExistingRun = useCallback(
    (run: CILRun) => {
      setCilId(run.id);
      setCilState(run as unknown as CILState);
      if (run.status === 'running' || run.status === 'paused') {
        setView('running');
        startPolling(run.id);
      } else {
        setView('results');
      }
    },
    [startPolling]
  );

  // ─── Setup View ─────────────────────────────────────────────────────────

  if (view === 'setup') {
    return (
      <div className="min-h-screen bg-gray-50">
        {/* Header */}
        <div className="border-b bg-white">
          <div className="mx-auto max-w-6xl px-6 py-4">
            <div className="mb-2 flex items-center gap-2 text-sm text-gray-500">
              <Link href="/orchestrator" className="hover:text-blue-600">
                Orchestrator
              </Link>
              <span>/</span>
              <span className="text-gray-900">Improvement Loop</span>
            </div>
            <h1 className="text-2xl font-bold text-gray-900">
              Continuous Improvement Loop
            </h1>
            <p className="mt-1 text-gray-500">
              Iterative evaluate → triage → fix → re-evaluate cycle with
              automated code changes
            </p>
          </div>
        </div>

        <div className="mx-auto max-w-6xl space-y-8 px-6 py-8">
          {/* Pre-filled from evaluation banner */}
          {prefilled && (
            <div className="flex items-center gap-3 rounded-xl border border-blue-200 bg-blue-50 p-4">
              <span className="text-lg text-blue-500">&#x2139;&#xFE0F;</span>
              <div>
                <p className="text-sm font-medium text-blue-900">
                  Pre-filled from evaluation results
                </p>
                <p className="text-xs text-blue-700">
                  Codebase path and focus categories have been set based on your
                  evaluation. Adjust settings below if needed, then start the
                  loop.
                </p>
              </div>
            </div>
          )}

          {/* Codebase Selection */}
          <div className="rounded-xl border bg-white p-6 shadow-sm">
            <h2 className="mb-4 text-lg font-semibold text-gray-900">
              Codebase
            </h2>
            {loading ? (
              <div className="h-10 animate-pulse rounded bg-gray-100" />
            ) : (
              <div className="space-y-3">
                <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                  {projects.map((p) => (
                    <button
                      key={p.id}
                      onClick={() => {
                        setCodebasePath(p.path);
                        setManualPath('');
                      }}
                      className={`rounded-lg border-2 p-3 text-left transition-all ${
                        codebasePath === p.path
                          ? 'border-blue-500 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                    >
                      <div className="font-medium text-gray-900">{p.name}</div>
                      <div className="truncate text-xs text-gray-500">
                        {p.path}
                      </div>
                    </button>
                  ))}
                </div>
                <div>
                  <label className="text-sm text-gray-600">
                    Or enter a path:
                  </label>
                  <input
                    type="text"
                    value={manualPath}
                    onChange={(e) => {
                      setManualPath(e.target.value);
                      setCodebasePath('');
                    }}
                    placeholder="/path/to/codebase"
                    className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
            )}
          </div>

          {/* Configuration */}
          <div className="rounded-xl border bg-white p-6 shadow-sm">
            <h2 className="mb-4 text-lg font-semibold text-gray-900">
              Configuration
            </h2>
            <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
              {/* Max iterations */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Max Iterations
                </label>
                <input
                  type="range"
                  min={1}
                  max={10}
                  value={maxIterations}
                  onChange={(e) => setMaxIterations(Number(e.target.value))}
                  className="w-full"
                />
                <div className="mt-1 flex justify-between text-xs text-gray-500">
                  <span>1</span>
                  <span className="font-medium text-blue-600">
                    {maxIterations}
                  </span>
                  <span>10</span>
                </div>
              </div>

              {/* Target score */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Target Score (optional)
                </label>
                <input
                  type="number"
                  step="0.5"
                  min="0"
                  max="10"
                  value={targetScore}
                  onChange={(e) => setTargetScore(e.target.value)}
                  placeholder="e.g., 8.5 — stop early when reached"
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              {/* Evaluation mode */}
              <div>
                <label className="mb-2 block text-sm font-medium text-gray-700">
                  Evaluation Mode
                </label>
                <div className="flex gap-2">
                  {(['quick', 'standard', 'enhanced'] as const).map((m) => (
                    <button
                      key={m}
                      onClick={() => setEvalMode(m)}
                      className={`flex-1 rounded-lg border px-3 py-2 text-sm font-medium transition-all ${
                        evalMode === m
                          ? 'border-blue-500 bg-blue-50 text-blue-700'
                          : 'border-gray-200 text-gray-600 hover:border-gray-300'
                      }`}
                    >
                      {m.charAt(0).toUpperCase() + m.slice(1)}
                    </button>
                  ))}
                </div>
              </div>

              {/* Auto implement */}
              <div>
                <label className="mb-2 block text-sm font-medium text-gray-700">
                  Auto-Implement Fixes
                </label>
                <button
                  onClick={() => setAutoImplement(!autoImplement)}
                  className={`relative h-7 w-14 rounded-full transition-colors ${
                    autoImplement ? 'bg-blue-500' : 'bg-gray-300'
                  }`}
                >
                  <div
                    className={`absolute top-0.5 h-6 w-6 rounded-full bg-white shadow transition-transform ${
                      autoImplement ? 'translate-x-7' : 'translate-x-0.5'
                    }`}
                  />
                </button>
                <p className="mt-1 text-xs text-gray-500">
                  {autoImplement
                    ? 'Agents will automatically apply code changes'
                    : 'Produce remediation plans only (no file changes)'}
                </p>
              </div>
            </div>

            {/* Coder Backend Selection */}
            {autoImplement && (
              <div className="mt-6">
                <label className="mb-2 block text-sm font-medium text-gray-700">
                  Coding Backend
                </label>
                <p className="mb-3 text-xs text-gray-500">
                  Choose which AI coding tool applies the fixes
                </p>
                <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
                  {[
                    {
                      id: 'claude-api',
                      name: 'Claude API',
                      desc: 'Direct Anthropic API calls for code generation',
                      icon: '\u2728',
                      requirement: 'ANTHROPIC_API_KEY',
                    },
                    {
                      id: 'claude-code',
                      name: 'Claude Code',
                      desc: 'Claude Code CLI with full tool use and multi-turn reasoning',
                      icon: '\uD83D\uDCBB',
                      requirement: 'claude CLI installed',
                    },
                    {
                      id: 'cursor',
                      name: 'Cursor',
                      desc: "Cursor editor's agent mode for AI-powered edits",
                      icon: '\uD83D\uDD2E',
                      requirement: 'Cursor installed',
                    },
                    {
                      id: 'aider',
                      name: 'Aider',
                      desc: 'Open-source AI pair programmer (works with any model)',
                      icon: '\uD83E\uDD1D',
                      requirement: 'pip install aider-chat',
                    },
                    {
                      id: 'manual',
                      name: 'Manual',
                      desc: 'Write instruction files for human review with any tool',
                      icon: '\uD83D\uDCDD',
                      requirement: 'None — always available',
                    },
                  ].map((coder) => (
                    <button
                      key={coder.id}
                      onClick={() => setCoderBackend(coder.id)}
                      className={`rounded-lg border-2 p-3 text-left transition-all ${
                        coderBackend === coder.id
                          ? 'border-blue-500 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                    >
                      <div className="mb-1 flex items-center gap-2">
                        <span className="text-lg">{coder.icon}</span>
                        <span className="text-sm font-medium">
                          {coder.name}
                        </span>
                      </div>
                      <p className="text-xs text-gray-500">{coder.desc}</p>
                      <p className="mt-1 text-[10px] text-gray-400">
                        Requires: {coder.requirement}
                      </p>
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Focus categories */}
            <div className="mt-6">
              <label className="mb-2 block text-sm font-medium text-gray-700">
                Focus Categories (optional — leave empty for all)
              </label>
              <div className="flex flex-wrap gap-2">
                {ALL_CATEGORIES.map((cat) => (
                  <button
                    key={cat}
                    onClick={() =>
                      setFocusCategories((prev) =>
                        prev.includes(cat)
                          ? prev.filter((c) => c !== cat)
                          : [...prev, cat]
                      )
                    }
                    className={`rounded px-2 py-1 text-xs font-medium transition-all ${
                      focusCategories.includes(cat)
                        ? 'border border-blue-300 bg-blue-100 text-blue-700'
                        : 'border border-transparent bg-gray-100 text-gray-600 hover:bg-gray-200'
                    }`}
                  >
                    {cat.replace(/_/g, ' ')}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Start button */}
          <div className="flex justify-end">
            <button
              onClick={startLoop}
              disabled={starting || (!codebasePath && !manualPath)}
              className="rounded-lg bg-blue-600 px-8 py-3 font-medium text-white transition-all hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {starting ? 'Starting...' : 'Start Improvement Loop'}
            </button>
          </div>
          {error && (
            <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
              {error}
            </div>
          )}

          {/* Previous runs */}
          {previousRuns.length > 0 && (
            <div className="rounded-xl border bg-white p-6 shadow-sm">
              <h2 className="mb-4 text-lg font-semibold text-gray-900">
                Previous Runs
              </h2>
              <div className="space-y-3">
                {previousRuns.map((run) => (
                  <button
                    key={run.id}
                    onClick={() => viewExistingRun(run)}
                    className="w-full rounded-lg border border-gray-200 p-4 text-left transition-all hover:border-blue-300 hover:bg-blue-50"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <span className="font-medium text-gray-900">
                          {run.id}
                        </span>
                        <span
                          className={`ml-2 rounded-full px-2 py-0.5 text-xs ${
                            run.status === 'completed'
                              ? 'bg-green-100 text-green-700'
                              : run.status === 'running'
                                ? 'bg-blue-100 text-blue-700'
                                : run.status === 'paused'
                                  ? 'bg-yellow-100 text-yellow-700'
                                  : 'bg-red-100 text-red-700'
                          }`}
                        >
                          {run.status}
                        </span>
                      </div>
                      <span className="text-xs text-gray-500">
                        {new Date(run.started_at).toLocaleDateString()}
                      </span>
                    </div>
                    <div className="mt-1 text-sm text-gray-500">
                      Iteration {run.current_iteration}/
                      {run.config.max_iterations}
                      {run.summary && (
                        <span className="ml-2">
                          Score: {run.summary.initial_score} →{' '}
                          {run.summary.final_score}({run.summary.initial_grade}{' '}
                          → {run.summary.final_grade})
                        </span>
                      )}
                    </div>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    );
  }

  // ─── Running View ─────────────────────────────────────────────────────

  if (view === 'running') {
    const completedIterations =
      cilState?.iterations.filter((i) => i.status === 'completed') ?? [];
    const currentIter = cilState?.iterations.find(
      (i) => i.status === 'running'
    );
    const overallProgress = cilState
      ? (cilState.current_iteration / cilState.config.max_iterations) * 100
      : 0;

    // Build score chart data
    const scoreData = completedIterations.map((it) => ({
      iteration: `#${it.iteration}`,
      score: it.overall_score ?? 0,
    }));

    return (
      <div className="min-h-screen bg-gray-50">
        {/* Header */}
        <div className="border-b bg-white">
          <div className="mx-auto max-w-6xl px-6 py-4">
            <div className="mb-2 flex items-center gap-2 text-sm text-gray-500">
              <Link href="/orchestrator" className="hover:text-blue-600">
                Orchestrator
              </Link>
              <span>/</span>
              <Link
                href="/orchestrator/improvement-loop"
                className="hover:text-blue-600"
              >
                Improvement Loop
              </Link>
              <span>/</span>
              <span className="text-gray-900">{cilId ?? 'Running'}</span>
            </div>
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  Iteration {cilState?.current_iteration ?? 0} of{' '}
                  {cilState?.config.max_iterations ?? maxIterations}
                </h1>
                <p className="mt-1 text-gray-500">
                  {cilState?.current_phase
                    ? PHASE_LABELS[cilState.current_phase] ||
                      cilState.current_phase
                    : 'Starting...'}{' '}
                  &middot; {formatElapsed(elapsed)} elapsed
                  {cilState?.config.coder &&
                    cilState.config.coder !== 'claude-api' && (
                      <span className="ml-2 rounded bg-purple-100 px-2 py-0.5 text-xs text-purple-700">
                        {cilState.config.coder}
                      </span>
                    )}
                </p>
              </div>
              <div className="flex gap-2">
                {cilState?.status === 'running' && (
                  <button
                    onClick={pauseLoop}
                    className="rounded-lg bg-yellow-100 px-4 py-2 text-sm font-medium text-yellow-700 hover:bg-yellow-200"
                  >
                    Pause
                  </button>
                )}
                {cilState?.status === 'paused' && (
                  <button
                    onClick={resumeLoop}
                    className="rounded-lg bg-green-100 px-4 py-2 text-sm font-medium text-green-700 hover:bg-green-200"
                  >
                    Resume
                  </button>
                )}
              </div>
            </div>

            {/* Overall progress bar */}
            <div className="mt-4 h-2 overflow-hidden rounded-full bg-gray-200">
              <motion.div
                className="h-full rounded-full bg-blue-500"
                initial={{ width: 0 }}
                animate={{ width: `${overallProgress}%` }}
                transition={{ duration: 0.5 }}
              />
            </div>
          </div>
        </div>

        <div className="mx-auto max-w-6xl space-y-6 px-6 py-8">
          {/* Current Phase Pipeline */}
          {currentIter && (
            <div className="rounded-xl border bg-white p-6 shadow-sm">
              <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-500">
                Current Iteration — Phase Progress
              </h3>
              <div className="flex items-center justify-between">
                {PHASE_ORDER.map((phase, idx) => {
                  const ps = currentIter.phases[phase];
                  const status = ps?.status ?? 'pending';
                  return (
                    <div key={phase} className="flex items-center">
                      <div
                        className={`flex items-center gap-2 rounded-lg px-3 py-2 ${
                          status === 'running'
                            ? 'border border-blue-200 bg-blue-50'
                            : status === 'completed'
                              ? 'border border-green-200 bg-green-50'
                              : status === 'failed'
                                ? 'border border-red-200 bg-red-50'
                                : 'border border-gray-200 bg-gray-50'
                        }`}
                      >
                        <span>{phaseIcon(status)}</span>
                        <span
                          className={`text-sm font-medium capitalize ${
                            status === 'running'
                              ? 'text-blue-700'
                              : status === 'completed'
                                ? 'text-green-700'
                                : status === 'failed'
                                  ? 'text-red-700'
                                  : 'text-gray-500'
                          }`}
                        >
                          {phase}
                        </span>
                      </div>
                      {idx < PHASE_ORDER.length - 1 && (
                        <div className="mx-1 h-px w-8 bg-gray-300" />
                      )}
                    </div>
                  );
                })}
              </div>

              {/* Active agents */}
              {currentIter.assigned_agents &&
                currentIter.assigned_agents.length > 0 && (
                  <div className="mt-4 border-t pt-4">
                    <div className="mb-2 text-xs text-gray-500">
                      Active Agents
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {currentIter.assigned_agents.map((a) => (
                        <span
                          key={a}
                          className="rounded bg-purple-50 px-2 py-1 text-xs font-medium text-purple-700"
                        >
                          {a.replace(/_/g, ' ')}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
            </div>
          )}

          {/* Score Progression Chart */}
          {scoreData.length > 0 && (
            <div className="rounded-xl border bg-white p-6 shadow-sm">
              <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-500">
                Score Progression
              </h3>
              <ResponsiveContainer width="100%" height={200}>
                <LineChart data={scoreData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                  <XAxis dataKey="iteration" tick={{ fontSize: 12 }} />
                  <YAxis domain={[0, 10]} tick={{ fontSize: 12 }} />
                  <Tooltip />
                  <Line
                    type="monotone"
                    dataKey="score"
                    stroke="#3b82f6"
                    strokeWidth={2}
                    dot={{ fill: '#3b82f6', r: 4 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          )}

          {/* Iteration History */}
          {completedIterations.length > 0 && (
            <div className="rounded-xl border bg-white p-6 shadow-sm">
              <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-500">
                Completed Iterations
              </h3>
              <div className="space-y-3">
                <AnimatePresence>
                  {completedIterations.map((it) => (
                    <IterationCard key={it.iteration} iteration={it} />
                  ))}
                </AnimatePresence>
              </div>
            </div>
          )}

          {/* Preparing state when no iterations completed yet */}
          {completedIterations.length === 0 && (
            <div className="rounded-xl border bg-white p-6 text-center shadow-sm">
              <motion.div
                className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-blue-100"
                animate={{ scale: [1, 1.1, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
              >
                <span className="text-2xl">&#x1f50d;</span>
              </motion.div>
              <h3 className="text-lg font-medium text-gray-900">
                {cilState?.current_phase === 'evaluate'
                  ? 'Running CTO Evaluation...'
                  : 'Starting Improvement Loop...'}
              </h3>
              <p className="mt-1 text-sm text-gray-500">
                First iteration in progress. Results will appear here.
              </p>
            </div>
          )}
        </div>
      </div>
    );
  }

  // ─── Results View ─────────────────────────────────────────────────────

  const summary = cilState?.summary;
  const completedIts =
    cilState?.iterations.filter((i) => i.status === 'completed') ?? [];

  // Score chart data
  const scoreChartData = completedIts.map((it) => ({
    iteration: `#${it.iteration}`,
    score: it.overall_score ?? 0,
    findings: it.findings_total ?? 0,
  }));

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="border-b bg-white">
        <div className="mx-auto max-w-6xl px-6 py-4">
          <div className="mb-2 flex items-center gap-2 text-sm text-gray-500">
            <Link href="/orchestrator" className="hover:text-blue-600">
              Orchestrator
            </Link>
            <span>/</span>
            <Link
              href="/orchestrator/improvement-loop"
              className="hover:text-blue-600"
            >
              Improvement Loop
            </Link>
            <span>/</span>
            <span className="text-gray-900">Results</span>
          </div>
          <h1 className="text-2xl font-bold text-gray-900">
            Improvement Loop Complete
          </h1>
          <p className="mt-1 text-gray-500">
            {cilState?.id} &middot;{' '}
            {summary?.stop_reason?.replace(/_/g, ' ') ?? ''}
          </p>
        </div>
      </div>

      <div className="mx-auto max-w-6xl space-y-6 px-6 py-8">
        {/* Placeholder mode warning */}
        {cilState?.placeholder_mode && (
          <div className="rounded-xl border border-red-200 bg-red-50 p-4">
            <div className="flex items-start gap-3">
              <span className="text-2xl">&#x26a0;&#xfe0f;</span>
              <div>
                <h3 className="font-semibold text-red-800">
                  No Fixes Applied — No LLM Backend Available
                </h3>
                <p className="mt-1 text-sm text-red-700">
                  The <strong>evaluation scores are real</strong>, but the AI
                  agents could not produce or apply code fixes because no LLM
                  backend was accessible.
                  {cilState?.config?.coder === 'claude-code' && (
                    <>
                      {' '}
                      The <strong>Claude Code CLI</strong> was selected but
                      failed to execute. Check that{' '}
                      <code className="rounded bg-red-100 px-1">
                        claude --version
                      </code>{' '}
                      works in your terminal.
                    </>
                  )}
                </p>
                <div className="mt-3 rounded-lg border border-red-100 bg-white p-3">
                  <p className="mb-1 text-sm font-medium text-gray-800">
                    To enable automated fixes (choose one):
                  </p>
                  <ol className="list-inside list-decimal space-y-1 text-sm text-gray-700">
                    <li>
                      <strong>Option A (Claude Code CLI):</strong> Select{' '}
                      <em>claude-code</em> backend + ensure{' '}
                      <code className="rounded bg-gray-100 px-1">
                        claude --version
                      </code>{' '}
                      works. Auth uses your disk credentials.
                    </li>
                    <li>
                      <strong>Option B (API Key):</strong> Create{' '}
                      <code className="rounded bg-gray-100 px-1">
                        .env.local
                      </code>{' '}
                      and add{' '}
                      <code className="rounded bg-gray-100 px-1">
                        ANTHROPIC_API_KEY=&lt;your-key&gt;
                      </code>
                    </li>
                  </ol>
                  <p className="mt-2 text-xs text-gray-500">
                    Check{' '}
                    <code className="rounded bg-gray-100 px-1">
                      runs/logs/cil_*.log
                    </code>{' '}
                    for detailed diagnostic output.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Summary Cards */}
        {summary && (
          <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
            <SummaryCard
              label="Score Improvement"
              value={`${summary.initial_score.toFixed(1)} → ${summary.final_score.toFixed(1)}`}
              detail={`${summary.total_improvement >= 0 ? '+' : ''}${summary.total_improvement.toFixed(1)}`}
              accent={summary.total_improvement >= 0 ? 'green' : 'red'}
            />
            <SummaryCard
              label="Grade Progression"
              value={`${summary.initial_grade} → ${summary.final_grade}`}
              detail={`${summary.total_iterations} iterations`}
              accent="blue"
            />
            <SummaryCard
              label="Findings Resolved"
              value={String(summary.total_findings_resolved)}
              detail={`${summary.total_findings_remaining} remaining`}
              accent="purple"
            />
            <SummaryCard
              label="Best Iteration"
              value={`#${summary.best_iteration}`}
              detail={summary.stop_reason.replace(/_/g, ' ')}
              accent="yellow"
            />
          </div>
        )}

        {/* Score Progression Chart */}
        {scoreChartData.length > 0 && (
          <div className="rounded-xl border bg-white p-6 shadow-sm">
            <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-500">
              Score Progression
            </h3>
            <ResponsiveContainer width="100%" height={250}>
              <LineChart data={scoreChartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="iteration" tick={{ fontSize: 12 }} />
                <YAxis
                  yAxisId="score"
                  domain={[0, 10]}
                  tick={{ fontSize: 12 }}
                />
                <YAxis
                  yAxisId="findings"
                  orientation="right"
                  tick={{ fontSize: 12 }}
                />
                <Tooltip />
                <Legend />
                <Line
                  yAxisId="score"
                  type="monotone"
                  dataKey="score"
                  stroke="#3b82f6"
                  strokeWidth={2}
                  dot={{ fill: '#3b82f6', r: 4 }}
                  name="Score"
                />
                <Line
                  yAxisId="findings"
                  type="monotone"
                  dataKey="findings"
                  stroke="#ef4444"
                  strokeWidth={1}
                  dot={{ fill: '#ef4444', r: 3 }}
                  name="Findings"
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}

        {/* Agent Leaderboard */}
        {summary && summary.agent_contributions.length > 0 && (
          <div className="rounded-xl border bg-white p-6 shadow-sm">
            <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-500">
              Agent Leaderboard
            </h3>
            <div className="space-y-2">
              {summary.agent_contributions.map((agent, idx) => (
                <div
                  key={agent.agent_id}
                  className="flex items-center justify-between rounded-lg bg-gray-50 p-3"
                >
                  <div className="flex items-center gap-3">
                    <span
                      className={`text-lg font-bold ${
                        idx === 0
                          ? 'text-yellow-500'
                          : idx === 1
                            ? 'text-gray-400'
                            : idx === 2
                              ? 'text-amber-600'
                              : 'text-gray-300'
                      }`}
                    >
                      #{idx + 1}
                    </span>
                    <div>
                      <div className="font-medium text-gray-900">
                        {agent.agent_id.replace(/_/g, ' ')}
                      </div>
                      <div className="text-xs text-gray-500">
                        {agent.categories_improved.join(', ')}
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="font-semibold text-green-600">
                      {agent.findings_resolved} resolved
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Findings Table */}
        <FindingsSection iterationFindings={iterationFindings} />

        {/* Iteration Detail */}
        {completedIts.length > 0 && (
          <div className="rounded-xl border bg-white p-6 shadow-sm">
            <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-500">
              Iteration Details
            </h3>
            <div className="space-y-3">
              {completedIts.map((it) => (
                <IterationCard key={it.iteration} iteration={it} />
              ))}
            </div>
          </div>
        )}

        {/* Remaining Issues CTA */}
        {summary && summary.total_findings_remaining > 0 && (
          <div className="rounded-xl border border-blue-200 bg-gradient-to-r from-blue-50 to-purple-50 p-6">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">
                  {summary.total_findings_remaining} issues remaining
                </h3>
                <p className="mt-1 text-sm text-gray-600">
                  {summary.final_grade.startsWith('A')
                    ? 'Great progress! Run another loop to polish the remaining issues.'
                    : `Continue improving from ${summary.final_grade} (${summary.final_score.toFixed(1)}/10) — target the weakest categories for maximum impact.`}
                </p>
                {(() => {
                  const lastIt = completedIts[completedIts.length - 1];
                  const lastKey = lastIt ? String(lastIt.iteration) : undefined;
                  const lastFindings = lastKey
                    ? iterationFindings[lastKey]
                    : undefined;
                  const weakCats =
                    lastFindings?.categories
                      ?.filter((c) => c.score < 7)
                      ?.sort((a, b) => a.score - b.score)
                      ?.slice(0, 5) ?? [];
                  return weakCats.length > 0 ? (
                    <div className="mt-2 flex flex-wrap gap-1.5">
                      {weakCats.map((c) => (
                        <span
                          key={c.id}
                          className="rounded-full border border-red-200 bg-red-100 px-2 py-0.5 text-xs text-red-700"
                        >
                          {c.name} ({c.score.toFixed(1)})
                        </span>
                      ))}
                    </div>
                  ) : null;
                })()}
              </div>
              <button
                onClick={() => {
                  // Pre-fill setup with results from this run
                  const path = cilState?.config.codebase_path ?? '';
                  const lastIt = completedIts[completedIts.length - 1];
                  const lastKey = lastIt ? String(lastIt.iteration) : undefined;
                  const lastFindings = lastKey
                    ? iterationFindings[lastKey]
                    : undefined;
                  const weakCats =
                    lastFindings?.categories
                      ?.filter((c) => c.score < 7)
                      ?.map((c) => c.id) ?? [];

                  setCodebasePath(path);
                  setManualPath(path);
                  if (weakCats.length > 0) {
                    setFocusCategories(weakCats);
                  }
                  setEvalMode(
                    (cilState?.config.evaluation_mode as
                      | 'quick'
                      | 'standard'
                      | 'enhanced') ?? 'standard'
                  );
                  setPrefilled(true);
                  setCilState(null);
                  setCilId(null);
                  setView('setup');
                }}
                className="flex items-center gap-2 whitespace-nowrap rounded-lg bg-blue-600 px-6 py-3 font-medium text-white shadow-sm hover:bg-blue-700"
              >
                Fix Remaining Issues
                <svg
                  className="h-4 w-4"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M13 7l5 5m0 0l-5 5m5-5H6"
                  />
                </svg>
              </button>
            </div>
          </div>
        )}

        {/* Action buttons */}
        <div className="flex justify-end gap-4">
          <button
            onClick={() => {
              setView('setup');
              setCilState(null);
              setCilId(null);
            }}
            className="rounded-lg bg-blue-600 px-6 py-2 font-medium text-white hover:bg-blue-700"
          >
            Run Again
          </button>
          <Link
            href="/orchestrator/evaluation"
            className="rounded-lg bg-gray-100 px-6 py-2 font-medium text-gray-700 hover:bg-gray-200"
          >
            Run Evaluation
          </Link>
          <Link
            href="/orchestrator"
            className="rounded-lg bg-gray-100 px-6 py-2 font-medium text-gray-700 hover:bg-gray-200"
          >
            Back to Dashboard
          </Link>
        </div>
      </div>
    </div>
  );
}

// ─── Sub-Components ───────────────────────────────────────────────────────

function IterationCard({ iteration: it }: { iteration: IterationState }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="overflow-hidden rounded-lg border"
    >
      <button
        onClick={() => setExpanded(!expanded)}
        className="flex w-full items-center justify-between p-4 transition-colors hover:bg-gray-50"
      >
        <div className="flex items-center gap-4">
          <div
            className={`text-2xl font-bold ${gradeColor(it.grade ?? 'N/A')}`}
          >
            {it.grade ?? '—'}
          </div>
          <div className="text-left">
            <div className="font-medium text-gray-900">
              Iteration #{it.iteration}
            </div>
            <div className="text-sm text-gray-500">
              Score: {(it.overall_score ?? 0).toFixed(1)} &middot;{' '}
              {it.findings_total ?? 0} findings
            </div>
          </div>
        </div>
        <div className="flex items-center gap-4">
          {it.score_delta !== undefined && (
            <span
              className={`text-sm font-medium ${
                it.score_delta >= 0 ? 'text-green-600' : 'text-red-600'
              }`}
            >
              {it.score_delta >= 0 ? '+' : ''}
              {it.score_delta.toFixed(2)}
            </span>
          )}
          <div className="flex gap-1">
            {it.findings_resolved !== undefined && it.findings_resolved > 0 && (
              <span className="rounded bg-green-100 px-2 py-0.5 text-xs text-green-700">
                {it.findings_resolved} resolved
              </span>
            )}
            {it.findings_new !== undefined && it.findings_new > 0 && (
              <span className="rounded bg-orange-100 px-2 py-0.5 text-xs text-orange-700">
                {it.findings_new} new
              </span>
            )}
          </div>
          <svg
            className={`h-4 w-4 text-gray-400 transition-transform ${expanded ? 'rotate-180' : ''}`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M19 9l-7 7-7-7"
            />
          </svg>
        </div>
      </button>

      <AnimatePresence>
        {expanded && (
          <motion.div
            initial={{ height: 0 }}
            animate={{ height: 'auto' }}
            exit={{ height: 0 }}
            className="overflow-hidden border-t"
          >
            <div className="space-y-3 bg-gray-50 p-4">
              {/* Phase statuses */}
              <div className="flex gap-3">
                {PHASE_ORDER.map((phase) => {
                  const ps = it.phases[phase];
                  return (
                    <div
                      key={phase}
                      className="flex items-center gap-1 text-xs"
                    >
                      <span>{phaseIcon(ps?.status ?? 'pending')}</span>
                      <span className="capitalize">{phase}</span>
                    </div>
                  );
                })}
              </div>

              {/* Agents */}
              {it.assigned_agents && it.assigned_agents.length > 0 && (
                <div>
                  <div className="mb-1 text-xs text-gray-500">
                    Assigned Agents
                  </div>
                  <div className="flex flex-wrap gap-1">
                    {it.assigned_agents.map((a) => (
                      <span
                        key={a}
                        className="rounded border bg-white px-2 py-0.5 text-xs text-gray-700"
                      >
                        {a.replace(/_/g, ' ')}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Timing */}
              {it.started_at && it.completed_at && (
                <div className="text-xs text-gray-500">
                  Duration:{' '}
                  {Math.round(
                    (new Date(it.completed_at).getTime() -
                      new Date(it.started_at).getTime()) /
                      1000
                  )}
                  s
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}

function SummaryCard({
  label,
  value,
  detail,
  accent,
}: {
  label: string;
  value: string;
  detail: string;
  accent: 'green' | 'red' | 'blue' | 'purple' | 'yellow';
}) {
  const bgColors = {
    green: 'bg-green-50 border-green-200',
    red: 'bg-red-50 border-red-200',
    blue: 'bg-blue-50 border-blue-200',
    purple: 'bg-purple-50 border-purple-200',
    yellow: 'bg-yellow-50 border-yellow-200',
  };
  const textColors = {
    green: 'text-green-700',
    red: 'text-red-700',
    blue: 'text-blue-700',
    purple: 'text-purple-700',
    yellow: 'text-yellow-700',
  };

  return (
    <div className={`rounded-xl border p-4 ${bgColors[accent]}`}>
      <div className="text-xs font-medium uppercase tracking-wider text-gray-500">
        {label}
      </div>
      <div className={`mt-1 text-xl font-bold ${textColors[accent]}`}>
        {value}
      </div>
      <div className="mt-1 text-xs text-gray-500">{detail}</div>
    </div>
  );
}

function FindingsSection({
  iterationFindings,
}: {
  iterationFindings: Record<string, IterationFinding>;
}) {
  const [selectedIteration, setSelectedIteration] = useState<string | null>(
    null
  );
  const [severityFilter, setSeverityFilter] = useState<string>('all');

  const iterKeys = Object.keys(iterationFindings).sort();
  if (iterKeys.length === 0) {
    return null;
  }

  // Default to latest iteration
  const activeKey = selectedIteration ?? iterKeys[iterKeys.length - 1]!;
  const data = iterationFindings[activeKey];
  if (!data) {
    return null;
  }

  const severityCounts = { critical: 0, high: 0, medium: 0, low: 0 };
  for (const f of data.findings) {
    const sev = f.severity as keyof typeof severityCounts;
    if (sev in severityCounts) {
      severityCounts[sev]++;
    }
  }

  const filtered =
    severityFilter === 'all'
      ? data.findings
      : data.findings.filter((f) => f.severity === severityFilter);

  const sevColors: Record<string, string> = {
    critical: 'bg-red-100 text-red-800',
    high: 'bg-orange-100 text-orange-800',
    medium: 'bg-yellow-100 text-yellow-800',
    low: 'bg-blue-100 text-blue-800',
  };

  return (
    <div className="rounded-xl border bg-white p-6 shadow-sm">
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-sm font-semibold uppercase tracking-wider text-gray-500">
          Findings ({data.findings.length})
        </h3>
        <div className="flex items-center gap-2">
          {iterKeys.length > 1 && (
            <select
              value={activeKey}
              onChange={(e) => setSelectedIteration(e.target.value)}
              className="rounded border px-2 py-1 text-xs"
            >
              {iterKeys.map((k) => (
                <option key={k} value={k}>
                  {k.replace('-', ' #')}
                </option>
              ))}
            </select>
          )}
        </div>
      </div>

      {/* Severity filter pills */}
      <div className="mb-4 flex gap-2">
        <button
          onClick={() => setSeverityFilter('all')}
          className={`rounded-full px-3 py-1 text-xs font-medium transition-all ${
            severityFilter === 'all'
              ? 'bg-gray-900 text-white'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          All ({data.findings.length})
        </button>
        {(['critical', 'high', 'medium', 'low'] as const).map(
          (sev) =>
            severityCounts[sev] > 0 && (
              <button
                key={sev}
                onClick={() => setSeverityFilter(sev)}
                className={`rounded-full px-3 py-1 text-xs font-medium transition-all ${
                  severityFilter === sev
                    ? sevColors[sev]
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {sev} ({severityCounts[sev]})
              </button>
            )
        )}
      </div>

      {/* Findings list */}
      <div className="max-h-[500px] space-y-2 overflow-y-auto">
        {filtered.map((f) => (
          <div
            key={f.id}
            className="rounded-lg border border-gray-100 p-3 hover:bg-gray-50"
          >
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0 flex-1">
                <div className="mb-1 flex items-center gap-2">
                  <span
                    className={`rounded px-1.5 py-0.5 text-[10px] font-bold uppercase ${sevColors[f.severity] ?? 'bg-gray-100 text-gray-600'}`}
                  >
                    {f.severity}
                  </span>
                  <span className="text-xs text-gray-500">{f.category}</span>
                </div>
                <p className="text-sm text-gray-900">{f.description}</p>
                {f.file && (
                  <p className="mt-1 truncate font-mono text-xs text-gray-400">
                    {f.file}
                    {f.line ? `:${f.line}` : ''}
                  </p>
                )}
              </div>
            </div>
            {f.remediation && (
              <div className="mt-2 rounded bg-gray-50 p-2 text-xs text-gray-600">
                <span className="font-medium">Fix: </span>
                {f.remediation}
              </div>
            )}
          </div>
        ))}
        {filtered.length === 0 && (
          <div className="py-8 text-center text-sm text-gray-400">
            No findings match this filter.
          </div>
        )}
      </div>
    </div>
  );
}
