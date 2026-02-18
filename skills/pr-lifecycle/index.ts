/**
 * PR Lifecycle Skill — Prepare, describe, and verify PRs for merge
 *
 * Provides structured prompts for:
 * 1. Generating commit messages from diffs
 * 2. Creating changelog entries
 * 3. Merge readiness checks
 * 4. Release note generation
 */

export interface PRPrepareInput {
  commits: string[];
  changed_files: string[];
  diff_stats: { additions: number; deletions: number };
  test_results?: { passed: number; failed: number; skipped: number };
  tsc_clean?: boolean;
  agent_validation?: "pass" | "pass_with_warnings" | "fail";
}

export interface MergeReadinessOutput {
  ready: boolean;
  blockers: string[];
  warnings: string[];
  commit_message: string;
  changelog_entry: string;
}

// ─── Commit Message Generator ────────────────────────────────────────────────

/**
 * Builds context for an agent to generate a conventional commit message.
 */
export function buildCommitMessageContext(input: PRPrepareInput): string {
  const parts: string[] = [
    "## PR Lifecycle Skill — Commit Message Generation\n",
    "Generate a conventional commit message for this PR.\n",
    "### Format",
    "```",
    "<type>(<scope>): <short description>",
    "",
    "<body>",
    "",
    "<footer>",
    "```\n",
    "### Types",
    "- feat: New feature",
    "- fix: Bug fix",
    "- refactor: Code restructuring",
    "- docs: Documentation only",
    "- chore: Build/tooling/deps",
    "- test: Adding/fixing tests",
    "- perf: Performance improvement\n",
    "### Scopes",
    "orchestrator, providers, agents, skills, web-app, scripts, config, ci\n",
    `### Commits in this PR (${input.commits.length}):`,
  ];

  for (const commit of input.commits.slice(0, 20)) {
    parts.push(`- ${commit}`);
  }

  parts.push(`\n### Changed Files (${input.changed_files.length}):`);
  const grouped = groupFilesByScope(input.changed_files);
  for (const [scope, files] of Object.entries(grouped)) {
    parts.push(`**${scope}:** ${files.join(", ")}`);
  }

  parts.push(
    `\n### Stats: +${input.diff_stats.additions} -${input.diff_stats.deletions} lines`
  );

  parts.push(
    "\n### Instructions",
    "1. Determine the primary type and scope from the changes",
    "2. Write a clear, imperative short description (max 72 chars)",
    "3. Add body explaining WHY the change was made",
    "4. Add BREAKING CHANGE footer if applicable",
    "5. Return ONLY the commit message, no other text"
  );

  return parts.join("\n");
}

// ─── Changelog Generator ────────────────────────────────────────────────────

/**
 * Builds context for generating a changelog entry.
 */
export function buildChangelogContext(input: PRPrepareInput): string {
  const parts: string[] = [
    "## PR Lifecycle Skill — Changelog Entry\n",
    "Generate a changelog entry for this PR in Keep a Changelog format.\n",
    "### Categories",
    "- **Added**: New features",
    "- **Changed**: Changes to existing functionality",
    "- **Deprecated**: Soon-to-be removed features",
    "- **Removed**: Removed features",
    "- **Fixed**: Bug fixes",
    "- **Security**: Vulnerability fixes\n",
    `### Changes:`,
  ];

  for (const commit of input.commits.slice(0, 15)) {
    parts.push(`- ${commit}`);
  }

  parts.push(
    `\n### Files: ${input.changed_files.length} changed`,
    `### Stats: +${input.diff_stats.additions} -${input.diff_stats.deletions} lines`,
    "\n### Instructions",
    "1. Categorize changes into Added/Changed/Fixed/etc.",
    "2. Write user-facing descriptions (not commit messages)",
    "3. Return ONLY the changelog entry, no other text"
  );

  return parts.join("\n");
}

// ─── Merge Readiness Check ──────────────────────────────────────────────────

/**
 * Evaluates whether a PR is ready to merge.
 */
export function checkMergeReadiness(
  input: PRPrepareInput
): MergeReadinessOutput {
  const blockers: string[] = [];
  const warnings: string[] = [];

  // TypeScript compilation
  if (input.tsc_clean === false) {
    blockers.push("TypeScript compilation has errors");
  }

  // Agent validation
  if (input.agent_validation === "fail") {
    blockers.push("Agent validation failed");
  } else if (input.agent_validation === "pass_with_warnings") {
    warnings.push("Agent validation passed with warnings");
  }

  // Test results
  if (input.test_results) {
    if (input.test_results.failed > 0) {
      blockers.push(`${input.test_results.failed} test(s) failing`);
    }
    if (input.test_results.skipped > input.test_results.passed * 0.5) {
      warnings.push(
        `High skip ratio: ${input.test_results.skipped} skipped vs ${input.test_results.passed} passed`
      );
    }
  }

  // Large PR warning
  if (input.diff_stats.additions > 1000) {
    warnings.push(
      `Large PR: ${input.diff_stats.additions} additions — consider splitting`
    );
  }

  // No commits
  if (input.commits.length === 0) {
    blockers.push("No commits found");
  }

  // Generate commit message from commits
  const primaryType = inferCommitType(input.commits, input.changed_files);
  const scope = inferScope(input.changed_files);
  const description = input.commits.length > 0
    ? input.commits[0].replace(/^[a-f0-9]+ /, "")
    : "update";
  const commitMessage = `${primaryType}(${scope}): ${description}`;

  // Generate changelog entry
  const changelogEntry = generateSimpleChangelog(input.commits);

  return {
    ready: blockers.length === 0,
    blockers,
    warnings,
    commit_message: commitMessage,
    changelog_entry: changelogEntry,
  };
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function groupFilesByScope(
  files: string[]
): Record<string, string[]> {
  const groups: Record<string, string[]> = {};
  for (const file of files) {
    let scope = "other";
    if (file.startsWith("orchestrator/providers/")) scope = "providers";
    else if (file.startsWith("orchestrator/")) scope = "orchestrator";
    else if (file.startsWith("agents/")) scope = "agents";
    else if (file.startsWith("skills/")) scope = "skills";
    else if (file.startsWith("src/")) scope = "web-app";
    else if (file.startsWith("config/")) scope = "config";
    else if (file.startsWith("scripts/")) scope = "scripts";
    else if (file.startsWith(".github/")) scope = "ci";

    if (!groups[scope]) groups[scope] = [];
    groups[scope].push(file);
  }
  return groups;
}

function inferCommitType(
  commits: string[],
  files: string[]
): string {
  const allText = commits.join(" ").toLowerCase();
  if (allText.includes("fix") || allText.includes("bug")) return "fix";
  if (allText.includes("feat") || allText.includes("add") || allText.includes("new"))
    return "feat";
  if (allText.includes("refactor") || allText.includes("restructure"))
    return "refactor";
  if (allText.includes("doc") || files.every((f) => f.endsWith(".md")))
    return "docs";
  if (allText.includes("test")) return "test";
  if (allText.includes("perf")) return "perf";
  return "chore";
}

function inferScope(files: string[]): string {
  const groups = groupFilesByScope(files);
  const sorted = Object.entries(groups).sort(
    (a, b) => b[1].length - a[1].length
  );
  return sorted[0]?.[0] || "general";
}

function generateSimpleChangelog(commits: string[]): string {
  const added: string[] = [];
  const changed: string[] = [];
  const fixed: string[] = [];

  for (const commit of commits) {
    const msg = commit.replace(/^[a-f0-9]+ /, "");
    if (msg.match(/^(feat|add|new)/i)) added.push(msg);
    else if (msg.match(/^fix/i)) fixed.push(msg);
    else changed.push(msg);
  }

  const parts: string[] = [];
  if (added.length > 0) {
    parts.push("### Added");
    for (const a of added) parts.push(`- ${a}`);
  }
  if (changed.length > 0) {
    parts.push("### Changed");
    for (const c of changed) parts.push(`- ${c}`);
  }
  if (fixed.length > 0) {
    parts.push("### Fixed");
    for (const f of fixed) parts.push(`- ${f}`);
  }

  return parts.join("\n");
}
