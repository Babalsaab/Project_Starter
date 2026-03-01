'use client';

import { useEffect, useState, useRef, useCallback } from 'react';
import Link from 'next/link';
import { motion, AnimatePresence } from 'framer-motion';
import {
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  Radar,
  ResponsiveContainer,
} from 'recharts';

// --- Types ---

interface ProjectOption {
  id: string;
  name: string;
  path: string;
}

interface CategoryScore {
  id: string;
  name: string;
  weight: number;
  score: number;
  grade: string;
  findings_count: number;
}

interface Finding {
  id: number;
  category: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  description: string;
  file?: string;
  line?: number;
  remediation: string;
}

interface EvaluationResult {
  overall_score: number;
  grade: string;
  risk_level: string;
  categories: CategoryScore[];
  findings: Finding[];
  timestamp: string;
  codebase_path: string;
  mode: string;
  languages_detected: string[];
  frameworks_detected: string[];
  duration_seconds?: number;
}

interface EvaluationSummary {
  run_id: string;
  timestamp: string;
  overall_score: number;
  grade: string;
  mode: string;
  categories_evaluated: number;
  findings_total: number;
  findings_critical: number;
  findings_high: number;
}

interface ProgressData {
  status: 'running' | 'complete' | 'not_found' | 'error';
  run_id: string;
  completed_count: number;
  total_categories: number;
  percent_complete: number;
  completed_categories: Array<{
    id: string;
    name: string;
    score: number;
    grade: string;
    findings_count: number;
  }>;
  /** Categories currently being evaluated (names, not IDs) */
  in_progress_categories?: string[];
  /** Elapsed seconds since evaluation started */
  elapsed_seconds?: number;
  result?: EvaluationResult;
  error_message?: string;
}

// --- Constants ---

const ALL_CATEGORIES = [
  { id: 'code_quality', name: 'Code Quality', weight: 8 },
  { id: 'architecture', name: 'Architecture', weight: 10 },
  { id: 'security', name: 'Security', weight: 12 },
  { id: 'performance', name: 'Performance', weight: 8 },
  { id: 'testing', name: 'Testing', weight: 8 },
  { id: 'devops', name: 'DevOps', weight: 6 },
  { id: 'scalability', name: 'Scalability', weight: 8 },
  { id: 'reliability', name: 'Reliability', weight: 8 },
  { id: 'data_architecture', name: 'Data Architecture', weight: 5 },
  { id: 'api_design', name: 'API Design', weight: 5 },
  { id: 'observability', name: 'Observability', weight: 4 },
  { id: 'frontend', name: 'Frontend', weight: 4 },
  { id: 'backend', name: 'Backend', weight: 5 },
  { id: 'mobile', name: 'Mobile', weight: 2 },
  { id: 'documentation', name: 'Documentation', weight: 2 },
  { id: 'developer_experience', name: 'Developer Experience', weight: 2 },
  { id: 'maintainability', name: 'Maintainability', weight: 5 },
  { id: 'compliance', name: 'Compliance', weight: 4 },
  { id: 'cost_efficiency', name: 'Cost Efficiency', weight: 2 },
  { id: 'innovation', name: 'Innovation', weight: 2 },
  { id: 'uiux_consistency', name: 'UI/UX Consistency', weight: 4 },
];

const MODE_CONFIG = {
  quick: { label: 'Quick', desc: 'Surface patterns only', time: '~2-5 min' },
  standard: {
    label: 'Standard',
    desc: 'Full automated analysis',
    time: '~10-20 min',
  },
  enhanced: {
    label: 'Enhanced',
    desc: 'Deep analysis + compliance',
    time: '~30-60 min',
  },
} as const;

type EvalMode = keyof typeof MODE_CONFIG;

// --- Main Page ---

export default function EvaluationPage() {
  const [view, setView] = useState<'setup' | 'running' | 'results'>('setup');
  const [projects, setProjects] = useState<ProjectOption[]>([]);
  const [codebasePath, setCodebasePath] = useState('');
  const [manualPath, setManualPath] = useState('');
  const [mode, setMode] = useState<EvalMode>('standard');
  const [previousEvals, setPreviousEvals] = useState<EvaluationSummary[]>([]);
  const [runId, setRunId] = useState<string | null>(null);
  const [progress, setProgress] = useState<ProgressData | null>(null);
  const [result, setResult] = useState<EvaluationResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [elapsed, setElapsed] = useState(0);
  const pollingRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Fetch projects on mount + check for any active evaluation to resume
  useEffect(() => {
    fetch('/api/orchestrator/evaluation')
      .then((r) => {
        if (r.status === 401) {
          window.location.href = '/auth/signin';
          return null;
        }
        return r.json();
      })
      .then((data) => {
        if (data?.projects) {
          setProjects(data.projects);
        }

        // Resume running view if there's an active evaluation
        if (
          data?.active &&
          data.active.length > 0 &&
          view === 'setup' &&
          !runId
        ) {
          const active = data.active[0];
          setRunId(active.run_id);
          setCodebasePath(active.codebase_path);
          setManualPath(active.codebase_path);
          setElapsed(active.elapsed_seconds);
          setView('running');

          // Start client-side timer
          timerRef.current = setInterval(() => {
            setElapsed((prev) => prev + 1);
          }, 1000);

          // Start polling
          const pollFn = async () => {
            try {
              const r2 = await fetch(
                `/api/orchestrator/evaluation/${active.run_id}?codebase_path=${encodeURIComponent(active.codebase_path)}`
              );
              const prog: ProgressData = await r2.json();
              setProgress(prog);

              if (
                prog.elapsed_seconds !== undefined &&
                prog.elapsed_seconds > 0
              ) {
                setElapsed(prog.elapsed_seconds);
              }

              if (prog.status === 'complete' && prog.result) {
                if (pollingRef.current) {
                  clearInterval(pollingRef.current);
                }
                if (timerRef.current) {
                  clearInterval(timerRef.current);
                }
                setResult(prog.result);
                setTimeout(() => setView('results'), 1000);
              } else if (prog.status === 'error') {
                if (pollingRef.current) {
                  clearInterval(pollingRef.current);
                }
                if (timerRef.current) {
                  clearInterval(timerRef.current);
                }
                setError(prog.error_message || 'Evaluation failed');
              }
            } catch {
              /* continue */
            }
          };

          pollingRef.current = setInterval(pollFn, 2000);
          pollFn();
        }

        setLoading(false);
      })
      .catch(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Fetch previous evaluations when path changes
  useEffect(() => {
    if (!codebasePath) {
      setPreviousEvals([]);
      return;
    }
    fetch(
      `/api/orchestrator/evaluation?codebase_path=${encodeURIComponent(codebasePath)}`
    )
      .then((r) => r.json())
      .then((data) => {
        if (data?.evaluations) {
          setPreviousEvals(data.evaluations);
        }
        if (data?.latest) {
          setResult(data.latest);
        }
      })
      .catch(() => setPreviousEvals([]));
  }, [codebasePath]);

  // Cleanup on unmount
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

  const startEvaluation = useCallback(async () => {
    if (!codebasePath) {
      return;
    }
    setStarting(true);
    setError(null);

    try {
      const res = await fetch('/api/orchestrator/evaluation', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ codebase_path: codebasePath, mode }),
      });

      const data = await res.json();
      if (!res.ok) {
        setError(data.error || 'Failed to start evaluation');
        setStarting(false);
        return;
      }

      setRunId(data.run_id);
      setElapsed(0);
      setProgress(null);
      setView('running');
      setStarting(false);

      // Start client-side timer (ticks every second for smooth display)
      timerRef.current = setInterval(() => {
        setElapsed((prev) => prev + 1);
      }, 1000);

      // Start polling for progress
      const pollFn = async () => {
        try {
          const r = await fetch(
            `/api/orchestrator/evaluation/${data.run_id}?codebase_path=${encodeURIComponent(codebasePath)}`
          );
          const prog: ProgressData = await r.json();
          setProgress(prog);

          // Sync elapsed timer with server-reported elapsed_seconds
          if (prog.elapsed_seconds !== undefined && prog.elapsed_seconds > 0) {
            setElapsed(prog.elapsed_seconds);
          }

          if (prog.status === 'complete' && prog.result) {
            if (pollingRef.current) {
              clearInterval(pollingRef.current);
            }
            if (timerRef.current) {
              clearInterval(timerRef.current);
            }
            setResult(prog.result);
            setTimeout(() => setView('results'), 1000);
          } else if (prog.status === 'error') {
            if (pollingRef.current) {
              clearInterval(pollingRef.current);
            }
            if (timerRef.current) {
              clearInterval(timerRef.current);
            }
            setError(prog.error_message || 'Evaluation failed');
          }
        } catch {
          // Continue polling on network errors
        }
      };

      pollingRef.current = setInterval(pollFn, 2000);
      // First poll immediately
      pollFn();
    } catch {
      setError('Network error starting evaluation');
      setStarting(false);
    }
  }, [codebasePath, mode]);

  const handleSelectProject = (projectPath: string) => {
    setCodebasePath(projectPath);
    setManualPath(projectPath);
    setResult(null);
  };

  const handleManualPathSubmit = () => {
    if (manualPath.trim()) {
      setCodebasePath(manualPath.trim());
    }
  };

  const loadPreviousResult = (evalSummary: EvaluationSummary) => {
    // Fetch the full result for this evaluation
    fetch(
      `/api/orchestrator/evaluation/${evalSummary.run_id}?codebase_path=${encodeURIComponent(codebasePath)}`
    )
      .then((r) => r.json())
      .then((data) => {
        if (data?.result) {
          setResult(data.result);
          setView('results');
        }
      })
      .catch(console.error);
  };

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <div className="text-lg text-gray-500">Loading evaluation suite...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="border-b border-gray-200 bg-white px-6 py-4">
        <div className="mx-auto flex max-w-7xl items-center justify-between">
          <div>
            <div className="mb-1 flex items-center gap-2 text-sm text-gray-500">
              <Link href="/orchestrator" className="hover:text-gray-900">
                Orchestrator
              </Link>
              <span>/</span>
              <span className="text-gray-900">Codebase Evaluation</span>
            </div>
            <h1 className="text-2xl font-bold text-gray-900">
              CTO Codebase Evaluation
            </h1>
            <p className="mt-1 text-sm text-gray-500">
              495 parameters across 21 weighted categories
            </p>
          </div>
          <div className="flex gap-3">
            <Link
              href="/orchestrator"
              className="rounded-lg border px-4 py-2 text-sm text-gray-600 hover:bg-gray-50 hover:text-gray-900"
            >
              ← Dashboard
            </Link>
            {view === 'results' && (
              <>
                <button
                  onClick={() => {
                    setView('setup');
                    setResult(null);
                  }}
                  className="rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-800"
                >
                  New Evaluation
                </button>
                {result && result.findings.length > 0 && (
                  <Link
                    href={`/orchestrator/improvement-loop?path=${encodeURIComponent(
                      codebasePath || manualPath || result.codebase_path
                    )}&mode=${result.mode || 'standard'}&focus=${result.categories
                      .filter((c) => c.score < 7)
                      .map((c) => c.id)
                      .join(',')}`}
                    className="flex items-center gap-1 rounded-lg bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700"
                  >
                    Fix Issues →
                  </Link>
                )}
              </>
            )}
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-7xl px-6 py-8">
        {view === 'setup' && (
          <SetupView
            projects={projects}
            codebasePath={codebasePath}
            manualPath={manualPath}
            mode={mode}
            previousEvals={previousEvals}
            starting={starting}
            error={error}
            onSelectProject={handleSelectProject}
            onManualPathChange={setManualPath}
            onManualPathSubmit={handleManualPathSubmit}
            onModeChange={setMode}
            onStart={startEvaluation}
            onLoadPrevious={loadPreviousResult}
          />
        )}
        {view === 'running' && (
          <RunningView progress={progress} elapsed={elapsed} error={error} />
        )}
        {view === 'results' && result && (
          <ResultsView
            result={result}
            codebasePath={codebasePath || manualPath}
          />
        )}
      </main>
    </div>
  );
}

// --- Setup View ---

function SetupView({
  projects,
  codebasePath,
  manualPath,
  mode,
  previousEvals,
  starting,
  error,
  onSelectProject,
  onManualPathChange,
  onManualPathSubmit,
  onModeChange,
  onStart,
  onLoadPrevious,
}: {
  projects: ProjectOption[];
  codebasePath: string;
  manualPath: string;
  mode: EvalMode;
  previousEvals: EvaluationSummary[];
  starting: boolean;
  error: string | null;
  onSelectProject: (path: string) => void;
  onManualPathChange: (path: string) => void;
  onManualPathSubmit: () => void;
  onModeChange: (mode: EvalMode) => void;
  onStart: () => void;
  onLoadPrevious: (evalSummary: EvaluationSummary) => void;
}) {
  return (
    <div className="space-y-6">
      {/* Project Selection */}
      <div className="rounded-xl border bg-white p-6">
        <h2 className="mb-4 text-lg font-semibold text-gray-900">
          Select Codebase to Evaluate
        </h2>

        {/* Project Dropdown */}
        {projects.length > 0 && (
          <div className="mb-4">
            <label className="mb-2 block text-sm font-medium text-gray-700">
              Known Projects
            </label>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {projects.map((project) => (
                <button
                  key={project.id}
                  onClick={() => onSelectProject(project.path)}
                  className={`rounded-lg border p-4 text-left transition-all ${
                    codebasePath === project.path
                      ? 'border-blue-500 bg-blue-50 ring-1 ring-blue-200'
                      : 'hover:border-gray-400 hover:bg-gray-50'
                  }`}
                >
                  <div className="font-medium text-gray-900">
                    {project.name}
                  </div>
                  <div className="mt-1 truncate text-xs text-gray-500">
                    {project.path}
                  </div>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Manual Path Input */}
        <div>
          <label className="mb-2 block text-sm font-medium text-gray-700">
            Or enter path manually
          </label>
          <div className="flex gap-2">
            <input
              type="text"
              value={manualPath}
              onChange={(e) => onManualPathChange(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && onManualPathSubmit()}
              placeholder="/path/to/your/codebase"
              className="flex-1 rounded-lg border px-4 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-300"
            />
            <button
              onClick={onManualPathSubmit}
              className="rounded-lg border bg-gray-100 px-4 py-2 text-sm text-gray-700 hover:bg-gray-200"
            >
              Set Path
            </button>
          </div>
        </div>
      </div>

      {/* Mode Selector */}
      <div className="rounded-xl border bg-white p-6">
        <h2 className="mb-4 text-lg font-semibold text-gray-900">
          Evaluation Mode
        </h2>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
          {(
            Object.entries(MODE_CONFIG) as Array<
              [EvalMode, (typeof MODE_CONFIG)[EvalMode]]
            >
          ).map(([key, config]) => (
            <button
              key={key}
              onClick={() => onModeChange(key)}
              className={`rounded-lg border p-4 text-left transition-all ${
                mode === key
                  ? 'border-gray-900 bg-gray-900 text-white'
                  : 'bg-white text-gray-700 hover:border-gray-400 hover:bg-gray-50'
              }`}
            >
              <div className="font-medium">{config.label}</div>
              <div
                className={`mt-1 text-sm ${mode === key ? 'text-gray-300' : 'text-gray-500'}`}
              >
                {config.desc}
              </div>
              <div
                className={`mt-2 text-xs ${mode === key ? 'text-gray-400' : 'text-gray-400'}`}
              >
                {config.time}
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Start Button + Error */}
      <div className="flex items-center gap-4">
        <button
          onClick={onStart}
          disabled={!codebasePath || starting}
          className={`rounded-lg px-8 py-3 text-lg font-medium transition-all ${
            !codebasePath || starting
              ? 'cursor-not-allowed bg-gray-200 text-gray-400'
              : 'bg-green-600 text-white shadow-sm hover:bg-green-700 hover:shadow'
          }`}
        >
          {starting ? 'Starting...' : 'Start Evaluation'}
        </button>
        {codebasePath && (
          <span className="text-sm text-gray-500">
            Target:{' '}
            <code className="rounded bg-gray-100 px-2 py-0.5 text-xs">
              {codebasePath}
            </code>
          </span>
        )}
      </div>

      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* Previous Evaluations */}
      {previousEvals.length > 0 && (
        <div className="rounded-xl border bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            Previous Evaluations
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b text-left text-gray-500">
                  <th className="pb-2 font-medium">Date</th>
                  <th className="pb-2 font-medium">Score</th>
                  <th className="pb-2 font-medium">Grade</th>
                  <th className="pb-2 font-medium">Mode</th>
                  <th className="pb-2 font-medium">Findings</th>
                  <th className="pb-2 font-medium">Critical</th>
                  <th className="pb-2 font-medium"></th>
                </tr>
              </thead>
              <tbody>
                {previousEvals.map((evalItem) => (
                  <tr
                    key={evalItem.run_id}
                    className="border-b last:border-0 hover:bg-gray-50"
                  >
                    <td className="py-3 text-gray-700">
                      {new Date(evalItem.timestamp).toLocaleDateString()}
                    </td>
                    <td className="py-3">
                      <span className="font-semibold">
                        {evalItem.overall_score.toFixed(1)}
                      </span>
                      <span className="text-gray-400"> /10</span>
                    </td>
                    <td className="py-3">
                      <GradeBadge grade={evalItem.grade} />
                    </td>
                    <td className="py-3 capitalize text-gray-500">
                      {evalItem.mode}
                    </td>
                    <td className="py-3 text-gray-700">
                      {evalItem.findings_total}
                    </td>
                    <td className="py-3">
                      {evalItem.findings_critical > 0 ? (
                        <span className="rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700">
                          {evalItem.findings_critical}
                        </span>
                      ) : (
                        <span className="text-gray-400">0</span>
                      )}
                    </td>
                    <td className="py-3">
                      <button
                        onClick={() => onLoadPrevious(evalItem)}
                        className="text-xs font-medium text-blue-600 hover:text-blue-800"
                      >
                        View
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

// --- Running View ---

function RunningView({
  progress,
  elapsed,
  error,
}: {
  progress: ProgressData | null;
  elapsed: number;
  error: string | null;
}) {
  const completedCount = progress?.completed_count ?? 0;
  const percentComplete = progress?.percent_complete ?? 0;
  const completedMap = new Map(
    (progress?.completed_categories ?? []).map((c) => [c.id, c])
  );

  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <div className="space-y-6">
      {/* Progress Header */}
      <div className="rounded-xl border bg-white p-6">
        <div className="mb-4 flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">
              {completedCount === 0
                ? 'Preparing Evaluation...'
                : 'Evaluating Codebase...'}
            </h2>
            <p className="mt-1 text-sm text-gray-500">
              {completedCount === 0
                ? 'Checking dependencies, detecting languages, counting files...'
                : `${completedCount} of 21 categories complete`}
            </p>
          </div>
          <div className="text-right">
            <div className="text-2xl font-bold text-gray-900">
              {percentComplete}%
            </div>
            <div className="text-sm text-gray-500">
              Elapsed: {formatTime(elapsed)}
            </div>
          </div>
        </div>

        {/* Progress Bar */}
        <div className="h-3 w-full overflow-hidden rounded-full bg-gray-100">
          {completedCount === 0 ? (
            <motion.div
              className="h-3 rounded-full bg-blue-400"
              initial={{ width: '0%' }}
              animate={{ width: ['0%', '70%', '0%'] }}
              transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
            />
          ) : (
            <motion.div
              className="h-3 rounded-full bg-blue-500"
              initial={{ width: 0 }}
              animate={{ width: `${percentComplete}%` }}
              transition={{ duration: 0.5, ease: 'easeOut' }}
            />
          )}
        </div>
      </div>

      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* In-progress categories callout */}
      {progress?.in_progress_categories &&
        progress.in_progress_categories.length > 0 && (
          <div className="rounded-xl border border-blue-200 bg-blue-50 p-4">
            <div className="mb-2 flex items-center gap-2">
              <span className="h-2 w-2 animate-pulse rounded-full bg-blue-500" />
              <span className="text-sm font-medium text-blue-900">
                Currently evaluating ({progress.in_progress_categories.length}{' '}
                remaining)
              </span>
            </div>
            <div className="flex flex-wrap gap-2">
              {progress.in_progress_categories.map((name) => (
                <span
                  key={name}
                  className="animate-pulse rounded bg-blue-100 px-2 py-1 text-xs font-medium text-blue-700"
                >
                  {name}
                </span>
              ))}
            </div>
          </div>
        )}

      {/* Category Grid */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
        <AnimatePresence mode="popLayout">
          {ALL_CATEGORIES.map((cat) => {
            const completed = completedMap.get(cat.id);
            const isInProgress = progress?.in_progress_categories?.includes(
              cat.name
            );
            return (
              <motion.div
                key={cat.id}
                layout
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.3 }}
              >
                {completed ? (
                  <div className="rounded-lg border bg-white p-4 transition-all">
                    <div className="mb-2 flex items-center justify-between">
                      <span className="text-xs font-medium text-gray-500">
                        {cat.weight}%
                      </span>
                      <GradeBadge grade={completed.grade} small />
                    </div>
                    <div className="text-2xl font-bold text-gray-900">
                      {completed.score.toFixed(1)}
                    </div>
                    <div className="mt-1 text-sm text-gray-700">{cat.name}</div>
                    <div className="mt-2 h-1.5 w-full rounded-full bg-gray-100">
                      <div
                        className={`h-1.5 rounded-full ${scoreColor(completed.score)}`}
                        style={{ width: `${(completed.score / 10) * 100}%` }}
                      />
                    </div>
                  </div>
                ) : isInProgress ? (
                  <div className="rounded-lg border-2 border-blue-300 bg-blue-50 p-4">
                    <div className="mb-2 flex items-center justify-between">
                      <span className="text-xs font-medium text-blue-500">
                        {cat.weight}%
                      </span>
                      <span className="h-2 w-2 animate-pulse rounded-full bg-blue-500" />
                    </div>
                    <div className="text-2xl font-bold text-blue-400">...</div>
                    <div className="mt-1 text-sm font-medium text-blue-600">
                      {cat.name}
                    </div>
                    <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-blue-100">
                      <motion.div
                        className="h-1.5 rounded-full bg-blue-400"
                        animate={{ width: ['20%', '80%', '20%'] }}
                        transition={{
                          duration: 2,
                          repeat: Infinity,
                          ease: 'easeInOut',
                        }}
                      />
                    </div>
                  </div>
                ) : (
                  <div className="rounded-lg border border-dashed border-gray-300 bg-gray-50 p-4">
                    <div className="mb-2 flex items-center justify-between">
                      <span className="text-xs font-medium text-gray-400">
                        {cat.weight}%
                      </span>
                      <span className="text-xs text-gray-400">Queued</span>
                    </div>
                    <div className="text-2xl font-bold text-gray-300">--</div>
                    <div className="mt-1 text-sm text-gray-400">{cat.name}</div>
                    <div className="mt-2 h-1.5 w-full rounded-full bg-gray-200" />
                  </div>
                )}
              </motion.div>
            );
          })}
        </AnimatePresence>
      </div>
    </div>
  );
}

// --- Results View ---

function ResultsView({
  result,
  codebasePath,
}: {
  result: EvaluationResult;
  codebasePath?: string;
}) {
  const [expandedCategory, setExpandedCategory] = useState<string | null>(null);
  const [severityFilter, setSeverityFilter] = useState<string>('all');
  const [sortBy, setSortBy] = useState<'weight' | 'score' | 'name'>('weight');

  const sortedCategories = [...result.categories].sort((a, b) => {
    if (sortBy === 'weight') {
      return b.weight - a.weight;
    }
    if (sortBy === 'score') {
      return a.score - b.score;
    }
    return a.name.localeCompare(b.name);
  });

  const filteredFindings = result.findings.filter(
    (f) => severityFilter === 'all' || f.severity === severityFilter
  );

  const radarData = result.categories.map((cat) => ({
    category: cat.name.length > 12 ? cat.name.slice(0, 12) + '...' : cat.name,
    score: cat.score,
    fullMark: 10,
  }));

  const criticalCount = result.findings.filter(
    (f) => f.severity === 'critical'
  ).length;
  const highCount = result.findings.filter((f) => f.severity === 'high').length;
  const mediumCount = result.findings.filter(
    (f) => f.severity === 'medium'
  ).length;
  const lowCount = result.findings.filter((f) => f.severity === 'low').length;

  return (
    <div className="space-y-6">
      {/* Executive Summary */}
      <div className="rounded-xl border bg-white p-8">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
          {/* Score */}
          <div className="flex items-center gap-6">
            <div className="text-center">
              <div
                className={`text-6xl font-bold ${scoreTextColor(result.overall_score)}`}
              >
                {result.overall_score.toFixed(1)}
              </div>
              <div className="mt-1 text-sm text-gray-500">out of 10.0</div>
            </div>
            <div className="space-y-2">
              <GradeBadge grade={result.grade} large />
              <RiskBadge risk={result.risk_level} />
            </div>
          </div>

          {/* Quick Stats */}
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <QuickStat label="Total Findings" value={result.findings.length} />
            <QuickStat
              label="Critical"
              value={criticalCount}
              color="text-red-600"
            />
            <QuickStat label="High" value={highCount} color="text-orange-600" />
            <QuickStat label="Categories" value={result.categories.length} />
          </div>
        </div>

        {/* Detected Tech */}
        {(result.languages_detected.length > 0 ||
          result.frameworks_detected.length > 0) && (
          <div className="mt-6 flex flex-wrap gap-2 border-t pt-4">
            {result.languages_detected.map((lang) => (
              <span
                key={lang}
                className="rounded bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700"
              >
                {lang}
              </span>
            ))}
            {result.frameworks_detected.map((fw) => (
              <span
                key={fw}
                className="rounded bg-purple-50 px-2 py-1 text-xs font-medium text-purple-700"
              >
                {fw}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Fix These Issues CTA */}
      {result.findings.length > 0 && (
        <div className="rounded-xl border border-blue-200 bg-gradient-to-r from-blue-50 to-purple-50 p-6">
          <div className="flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-center">
            <div>
              <h2 className="text-lg font-semibold text-gray-900">
                Fix These Issues Automatically
              </h2>
              <p className="mt-1 text-sm text-gray-600">
                Start a Continuous Improvement Loop to automatically remediate{' '}
                {result.findings.length} findings using AI coding tools (Claude
                Code, Cursor, Aider, or manual review).
              </p>
            </div>
            <Link
              href={`/orchestrator/improvement-loop?path=${encodeURIComponent(
                codebasePath || result.codebase_path
              )}&mode=${result.mode || 'standard'}&focus=${result.categories
                .filter((c) => c.score < 7)
                .map((c) => c.id)
                .join(',')}`}
              className="flex shrink-0 items-center gap-2 rounded-lg bg-blue-600 px-6 py-3 font-medium text-white transition-all hover:bg-blue-700"
            >
              <span>Fix These Issues</span>
              <span className="text-blue-200">→</span>
            </Link>
          </div>
          <div className="mt-3 flex flex-wrap gap-2">
            {result.categories
              .filter((c) => c.score < 7)
              .sort((a, b) => a.score - b.score)
              .slice(0, 8)
              .map((cat) => (
                <span
                  key={cat.id}
                  className="rounded border border-gray-200 bg-white/80 px-2 py-0.5 text-xs text-gray-700"
                >
                  {cat.name}: {cat.score.toFixed(1)}
                </span>
              ))}
            {result.categories.filter((c) => c.score < 7).length > 8 && (
              <span className="px-2 py-0.5 text-xs text-gray-500">
                +{result.categories.filter((c) => c.score < 7).length - 8} more
              </span>
            )}
          </div>
        </div>
      )}

      {/* Radar Chart */}
      {radarData.length > 0 && (
        <div className="rounded-xl border bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">
            Category Radar
          </h2>
          <ResponsiveContainer width="100%" height={400}>
            <RadarChart cx="50%" cy="50%" outerRadius="75%" data={radarData}>
              <PolarGrid strokeDasharray="3 3" />
              <PolarAngleAxis dataKey="category" tick={{ fontSize: 11 }} />
              <PolarRadiusAxis
                angle={90}
                domain={[0, 10]}
                tick={{ fontSize: 10 }}
              />
              <Radar
                name="Score"
                dataKey="score"
                stroke="#3b82f6"
                fill="#3b82f6"
                fillOpacity={0.2}
                strokeWidth={2}
              />
            </RadarChart>
          </ResponsiveContainer>
        </div>
      )}

      {/* Category Breakdown */}
      <div className="rounded-xl border bg-white p-6">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">
            Category Breakdown
          </h2>
          <div className="flex gap-2">
            {(['weight', 'score', 'name'] as const).map((s) => (
              <button
                key={s}
                onClick={() => setSortBy(s)}
                className={`rounded px-3 py-1 text-xs font-medium transition-all ${
                  sortBy === s
                    ? 'bg-gray-900 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {s === 'weight'
                  ? 'By Weight'
                  : s === 'score'
                    ? 'By Score'
                    : 'By Name'}
              </button>
            ))}
          </div>
        </div>

        <div className="space-y-2">
          {sortedCategories.map((cat) => {
            const isExpanded = expandedCategory === cat.id;
            const catFindings = result.findings.filter(
              (f) => f.category === cat.name
            );

            return (
              <div key={cat.id} className="overflow-hidden rounded-lg border">
                <button
                  onClick={() =>
                    setExpandedCategory(isExpanded ? null : cat.id)
                  }
                  className="flex w-full items-center gap-4 p-4 text-left transition-colors hover:bg-gray-50"
                >
                  <div className="w-12 text-right">
                    <span className="text-xs text-gray-500">{cat.weight}%</span>
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="font-medium text-gray-900">{cat.name}</div>
                    <div className="mt-1 h-1.5 w-full rounded-full bg-gray-100">
                      <div
                        className={`h-1.5 rounded-full ${scoreColor(cat.score)}`}
                        style={{ width: `${(cat.score / 10) * 100}%` }}
                      />
                    </div>
                  </div>
                  <div className="flex items-center gap-3 text-right">
                    <span className="text-xl font-bold text-gray-900">
                      {cat.score.toFixed(1)}
                    </span>
                    <GradeBadge grade={cat.grade} small />
                    {cat.findings_count > 0 && (
                      <span className="text-xs text-gray-500">
                        {cat.findings_count} findings
                      </span>
                    )}
                    <span className="text-gray-400">
                      {isExpanded ? '▴' : '▾'}
                    </span>
                  </div>
                </button>

                {isExpanded && catFindings.length > 0 && (
                  <div className="space-y-2 border-t bg-gray-50 px-4 py-3">
                    {catFindings.map((finding) => (
                      <FindingRow key={finding.id} finding={finding} />
                    ))}
                  </div>
                )}
                {isExpanded && catFindings.length === 0 && (
                  <div className="border-t bg-gray-50 px-4 py-3 text-sm text-gray-500">
                    No findings for this category.
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Findings Panel */}
      <div className="rounded-xl border bg-white p-6">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">
            All Findings ({filteredFindings.length})
          </h2>
          <div className="flex gap-2">
            {[
              { key: 'all', label: 'All', count: result.findings.length },
              { key: 'critical', label: 'Critical', count: criticalCount },
              { key: 'high', label: 'High', count: highCount },
              { key: 'medium', label: 'Medium', count: mediumCount },
              { key: 'low', label: 'Low', count: lowCount },
            ].map(({ key, label, count }) => (
              <button
                key={key}
                onClick={() => setSeverityFilter(key)}
                className={`rounded px-3 py-1 text-xs font-medium transition-all ${
                  severityFilter === key
                    ? 'bg-gray-900 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {label} ({count})
              </button>
            ))}
          </div>
        </div>

        {filteredFindings.length === 0 ? (
          <div className="py-8 text-center text-gray-500">
            No findings match the current filter.
          </div>
        ) : (
          <div className="space-y-2">
            {filteredFindings.slice(0, 50).map((finding) => (
              <FindingRow key={finding.id} finding={finding} showCategory />
            ))}
            {filteredFindings.length > 50 && (
              <div className="py-4 text-center text-sm text-gray-500">
                Showing first 50 of {filteredFindings.length} findings.
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

// --- Shared Sub-Components ---

function FindingRow({
  finding,
  showCategory,
}: {
  finding: Finding;
  showCategory?: boolean;
}) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="overflow-hidden rounded-lg border bg-white">
      <button
        onClick={() => setExpanded(!expanded)}
        className="flex w-full items-start gap-3 p-3 text-left text-sm hover:bg-gray-50"
      >
        <SeverityBadge severity={finding.severity} />
        {showCategory && (
          <span className="whitespace-nowrap rounded bg-gray-100 px-2 py-0.5 text-xs text-gray-600">
            {finding.category}
          </span>
        )}
        <span className="flex-1 text-gray-800">{finding.description}</span>
        {finding.file && (
          <span className="whitespace-nowrap text-xs text-gray-400">
            {finding.file}
            {finding.line ? `:${finding.line}` : ''}
          </span>
        )}
        <span className="text-xs text-gray-400">{expanded ? '▴' : '▾'}</span>
      </button>
      {expanded && (
        <div className="space-y-2 border-t bg-gray-50 px-4 py-3 text-sm">
          <div>
            <span className="font-medium text-gray-700">Remediation: </span>
            <span className="text-gray-600">{finding.remediation}</span>
          </div>
          {finding.file && (
            <div>
              <span className="font-medium text-gray-700">File: </span>
              <code className="rounded bg-gray-100 px-2 py-0.5 text-xs">
                {finding.file}
                {finding.line ? `:${finding.line}` : ''}
              </code>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function GradeBadge({
  grade,
  small,
  large,
}: {
  grade: string;
  small?: boolean;
  large?: boolean;
}) {
  const color = gradeColor(grade);
  const size = large
    ? 'px-4 py-1.5 text-xl font-bold'
    : small
      ? 'px-2 py-0.5 text-xs font-medium'
      : 'px-2.5 py-0.5 text-sm font-semibold';

  return <span className={`${color} rounded-full ${size}`}>{grade}</span>;
}

function RiskBadge({ risk }: { risk: string }) {
  const colors: Record<string, string> = {
    Low: 'bg-green-100 text-green-700',
    Medium: 'bg-yellow-100 text-yellow-700',
    High: 'bg-red-100 text-red-700',
    Critical: 'bg-red-200 text-red-800',
  };

  return (
    <span
      className={`rounded-full px-3 py-1 text-sm font-medium ${colors[risk] ?? 'bg-gray-100 text-gray-700'}`}
    >
      {risk} Risk
    </span>
  );
}

function SeverityBadge({ severity }: { severity: string }) {
  const config: Record<string, string> = {
    critical: 'bg-red-100 text-red-700',
    high: 'bg-orange-100 text-orange-700',
    medium: 'bg-yellow-100 text-yellow-700',
    low: 'bg-blue-100 text-blue-700',
  };

  return (
    <span
      className={`whitespace-nowrap rounded px-2 py-0.5 text-xs font-medium ${config[severity] ?? 'bg-gray-100 text-gray-700'}`}
    >
      {severity.toUpperCase()}
    </span>
  );
}

function QuickStat({
  label,
  value,
  color,
}: {
  label: string;
  value: number;
  color?: string;
}) {
  return (
    <div className="text-center">
      <div className={`text-2xl font-bold ${color ?? 'text-gray-900'}`}>
        {value}
      </div>
      <div className="mt-1 text-xs text-gray-500">{label}</div>
    </div>
  );
}

// --- Utility Functions ---

function scoreColor(score: number): string {
  if (score >= 8) {
    return 'bg-green-500';
  }
  if (score >= 6) {
    return 'bg-yellow-500';
  }
  if (score >= 4) {
    return 'bg-orange-500';
  }
  return 'bg-red-500';
}

function scoreTextColor(score: number): string {
  if (score >= 8) {
    return 'text-green-600';
  }
  if (score >= 6) {
    return 'text-yellow-600';
  }
  if (score >= 4) {
    return 'text-orange-600';
  }
  return 'text-red-600';
}

function gradeColor(grade: string): string {
  if (grade.startsWith('A')) {
    return 'bg-green-100 text-green-700';
  }
  if (grade.startsWith('B')) {
    return 'bg-blue-100 text-blue-700';
  }
  if (grade.startsWith('C')) {
    return 'bg-yellow-100 text-yellow-700';
  }
  if (grade.startsWith('D')) {
    return 'bg-orange-100 text-orange-700';
  }
  return 'bg-red-100 text-red-700';
}
