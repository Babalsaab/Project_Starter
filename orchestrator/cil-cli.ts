/**
 * CIL CLI — `npm run improve`
 *
 * Interactive command-line entry point for the Continuous Improvement Loop.
 *
 * Usage:
 *   npm run improve -- --path <codebase> --iterations <N> --target-score <X>
 *                      --mode <quick|standard|enhanced> --focus <cat1,cat2>
 *                      --no-auto-implement
 */

import * as readline from 'readline';
import * as path from 'path';
import {
  startCIL,
  listCILRuns,
  type CILConfig,
  type CILState,
} from './cil-controller';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function print(msg: string): void {
  process.stdout.write(msg + '\n');
}

function divider(): void {
  print('─────────────────────────────────────────────────────');
}

async function ask(prompt: string): Promise<string> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(prompt, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

// ─── Arg Parsing ──────────────────────────────────────────────────────────────

function parseArgs(): CILConfig & { _yes: boolean; _id?: string } {
  const args = process.argv.slice(2);
  const get = (flag: string): string | undefined => {
    const idx = args.indexOf(flag);
    return idx !== -1 && args[idx + 1] ? args[idx + 1] : undefined;
  };
  const has = (flag: string): boolean => args.includes(flag);

  const coderArg = get('--coder');
  const validCoders = [
    'claude-api',
    'claude-code',
    'cursor',
    'aider',
    'manual',
  ];
  const coder =
    coderArg && validCoders.includes(coderArg)
      ? (coderArg as CILConfig['coder'])
      : undefined;

  return {
    codebase_path: get('--path') ?? process.cwd(),
    max_iterations: parseInt(get('--iterations') ?? '5', 10),
    target_score: get('--target-score')
      ? parseFloat(get('--target-score')!)
      : undefined,
    target_grade: get('--target-grade'),
    evaluation_mode:
      (get('--mode') as CILConfig['evaluation_mode']) ?? 'standard',
    focus_categories: get('--focus')
      ?.split(',')
      .map((s) => s.trim()),
    auto_implement: !has('--no-auto-implement'),
    provider: get('--provider'),
    coder,
    _yes: has('--yes') || has('-y'),
    _id: get('--id'),
  };
}

// ─── List Command ─────────────────────────────────────────────────────────────

function listRuns(): void {
  const runs = listCILRuns();
  if (runs.length === 0) {
    print('\n  No improvement loop runs found.\n');
    return;
  }

  print('\n  IMPROVEMENT LOOP RUNS');
  divider();
  for (const run of runs) {
    const icon =
      { running: '▶', paused: '⏸', completed: '✅', failed: '❌' }[
        run.status
      ] ?? '❓';
    print(`  ${icon} ${run.id}`);
    print(`     Path: ${run.config.codebase_path}`);
    print(
      `     Iteration: ${run.current_iteration}/${run.config.max_iterations}`
    );
    print(`     Status: ${run.status}`);
    if (run.summary) {
      print(
        `     Score: ${run.summary.initial_score} → ${run.summary.final_score} (${run.summary.initial_grade} → ${run.summary.final_grade})`
      );
      print(`     Resolved: ${run.summary.total_findings_resolved} findings`);
    }
    print(`     Started: ${run.started_at}`);
    print('');
  }
}

// ─── Summary Printer ──────────────────────────────────────────────────────────

function printSummary(state: CILState): void {
  const s = state.summary;
  if (!s) {
    return;
  }

  print('');
  divider();
  print('  IMPROVEMENT LOOP SUMMARY');
  divider();
  print(`  Iterations:   ${s.total_iterations}`);
  print(
    `  Score:         ${s.initial_score} → ${s.final_score} (${s.total_improvement >= 0 ? '+' : ''}${s.total_improvement})`
  );
  print(`  Grade:         ${s.initial_grade} → ${s.final_grade}`);
  print(`  Resolved:      ${s.total_findings_resolved} findings`);
  print(`  Remaining:     ${s.total_findings_remaining} findings`);
  print(`  Best iteration: #${s.best_iteration}`);
  print(`  Stop reason:   ${s.stop_reason}`);

  if (s.agent_contributions.length > 0) {
    print('');
    print('  AGENT CONTRIBUTIONS');
    divider();
    for (const a of s.agent_contributions.slice(0, 10)) {
      print(
        `    ${a.agent_id}: ${a.findings_resolved} findings resolved (${a.categories_improved.join(', ')})`
      );
    }
  }

  // Iteration-by-iteration table
  print('');
  print('  ITERATION HISTORY');
  divider();
  print('  #  | Score  | Grade | Findings | Resolved | New  | Delta');
  print('  ---|--------|-------|----------|----------|------|------');
  for (const it of state.iterations.filter((i) => i.status === 'completed')) {
    const score = (it.overall_score ?? 0).toFixed(1).padStart(5);
    const grade = (it.grade ?? 'N/A').padEnd(5);
    const findings = String(it.findings_total ?? 0).padStart(8);
    const resolved = String(it.findings_resolved ?? 0).padStart(8);
    const newF = String(it.findings_new ?? 0).padStart(4);
    const delta =
      (it.score_delta ?? 0) >= 0
        ? `+${(it.score_delta ?? 0).toFixed(1)}`.padStart(5)
        : (it.score_delta ?? 0).toFixed(1).padStart(5);
    print(
      `  ${String(it.iteration).padStart(2)} | ${score} | ${grade} | ${findings} | ${resolved} | ${newF} | ${delta}`
    );
  }

  print('');
  print(`  Artifacts: ./runs/artifacts/${state.id}/`);
  print(`  State:     ./config/project-sessions/${state.id}/cil-state.yaml`);
  print(`  Dashboard: http://localhost:1000/orchestrator/improvement-loop`);
  divider();
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  print('');
  print('  ╔══════════════════════════════════════════════════════╗');
  print('  ║       CONTINUOUS IMPROVEMENT LOOP (CIL)             ║');
  print('  ║       evaluate → triage → fix → re-evaluate         ║');
  print('  ╚══════════════════════════════════════════════════════╝');
  print('');

  const command = process.argv[2];

  if (command === 'list') {
    listRuns();
    return;
  }

  if (command === 'help' || command === '--help' || command === '-h') {
    print('Usage: npm run improve -- [options]');
    print('');
    print('Options:');
    print(
      '  --path <path>          Codebase path (default: current directory)'
    );
    print('  --iterations <N>       Max iterations (default: 5)');
    print(
      '  --target-score <X>     Stop when this score is reached (e.g., 8.5)'
    );
    print(
      '  --target-grade <G>     Stop when this grade is reached (e.g., A-)'
    );
    print(
      '  --mode <mode>          Evaluation mode: quick|standard|enhanced (default: standard)'
    );
    print('  --focus <cats>         Comma-separated categories to focus on');
    print(
      "  --no-auto-implement    Don't auto-apply fixes (produce plans only)"
    );
    print(
      '  --coder <backend>      Coding backend: claude-api|claude-code|cursor|aider|manual'
    );
    print(
      '  --provider <id>        Provider to use (default: from globals.yaml)'
    );
    print(
      '  --yes, -y              Skip confirmation prompt (for headless/API use)'
    );
    print(
      '  --id <cil_id>          Use a pre-assigned CIL ID (for API coordination)'
    );
    print('');
    print('Coder Backends:');
    print(
      '  claude-api             Use Anthropic API directly for code generation (default)'
    );
    print(
      '  claude-code            Use Claude Code CLI (npm i -g @anthropic-ai/claude-code)'
    );
    print("  cursor                 Use Cursor editor's agent mode");
    print('  aider                  Use Aider CLI (pip install aider-chat)');
    print(
      '  manual                 Write instruction files for any tool/human review'
    );
    print('');
    print('Commands:');
    print('  list                   List previous improvement loop runs');
    print('  help                   Show this help message');
    print('');
    print('Examples:');
    print(
      '  npm run improve                                      # default settings'
    );
    print('  npm run improve -- --path . --iterations 3 --mode quick');
    print('  npm run improve -- --focus "security,testing" --target-score 8.5');
    print('  npm run improve -- --coder claude-code --iterations 3');
    print(
      '  npm run improve -- --coder manual                    # review fixes yourself'
    );
    print('  npm run improve -- list');
    return;
  }

  const parsed = parseArgs();
  const { _yes, _id, ...config } = parsed;
  const absPath = path.resolve(config.codebase_path);

  print('  Configuration:');
  print(`    Path:           ${absPath}`);
  print(`    Iterations:     ${config.max_iterations}`);
  print(`    Target score:   ${config.target_score ?? 'none'}`);
  print(`    Target grade:   ${config.target_grade ?? 'none'}`);
  print(`    Eval mode:      ${config.evaluation_mode}`);
  print(
    `    Focus:          ${config.focus_categories?.join(', ') ?? 'all categories'}`
  );
  print(`    Auto-implement: ${config.auto_implement}`);
  print(`    Coder:          ${config.coder ?? 'claude-api (default)'}`);
  print(`    Provider:       ${config.provider ?? 'default'}`);
  if (_id) {
    print(`    Assigned ID:    ${_id}`);
  }
  print('');

  if (!_yes) {
    const confirm = await ask('  Start improvement loop? (y/n) > ');
    if (confirm.toLowerCase() !== 'y' && confirm.toLowerCase() !== 'yes') {
      print('\n  Cancelled.\n');
      process.exit(0);
    }
  }

  print('');
  divider();

  const state = await startCIL(
    { ...config, codebase_path: absPath },
    (_state, msg) => {
      // Progress callback — onProgress messages are already logged by startCIL
    },
    _id
  );

  printSummary(state);
}

main().catch((err) => {
  print(`\n  ERROR: ${(err as Error).message}\n`);
  process.exit(1);
});
