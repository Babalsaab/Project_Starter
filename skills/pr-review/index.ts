/**
 * PR Review Skill — Automated PR quality analysis
 *
 * Provides structured review prompts and checklists that agents can use
 * when reviewing pull requests. Designed to be injected into agent context
 * during PR review tasks.
 */

export interface PRReviewInput {
  diff: string;
  description: string;
  changed_files: string[];
  pr_number?: number;
  author?: string;
}

export interface PRReviewOutput {
  verdict: "approve" | "request_changes" | "comment";
  summary: string;
  issues: PRIssue[];
  checklist: ChecklistItem[];
  suggestions: string[];
}

export interface PRIssue {
  severity: "critical" | "warning" | "info";
  file: string;
  line?: number;
  message: string;
  category: string;
}

export interface ChecklistItem {
  label: string;
  passed: boolean;
  notes?: string;
}

// ─── Review Categories ───────────────────────────────────────────────────────

const REVIEW_CATEGORIES = {
  security: {
    name: "Security",
    checks: [
      "No hardcoded secrets, API keys, or tokens",
      "No SQL injection vectors",
      "Input validation on user-facing endpoints",
      "No eval() or dynamic code execution",
      "Proper authentication/authorization checks",
    ],
  },
  quality: {
    name: "Code Quality",
    checks: [
      "TypeScript strict mode compliance",
      "No 'any' types without justification",
      "Functions under 50 lines",
      "Files under 600 lines",
      "Meaningful variable and function names",
      "No dead code or commented-out blocks",
    ],
  },
  architecture: {
    name: "Architecture",
    checks: [
      "Changes follow existing patterns",
      "No circular dependencies introduced",
      "Provider abstraction used (not direct API calls)",
      "Agent token caps respected",
      "Configuration via globals.yaml, not hardcoded",
    ],
  },
  testing: {
    name: "Testing",
    checks: [
      "New functionality has corresponding tests",
      "Edge cases covered",
      "No test-only code in production files",
    ],
  },
  docs: {
    name: "Documentation",
    checks: [
      "README updated for new features",
      "CLAUDE.md updated if agent/config changes",
      "JSDoc on public functions",
      "Inline comments for complex logic",
    ],
  },
};

// ─── Skill Context Builder ───────────────────────────────────────────────────

/**
 * Builds the review context to inject into an agent's prompt.
 */
export function buildPRReviewContext(input: PRReviewInput): string {
  const filesByType = categorizeFiles(input.changed_files);

  const parts: string[] = [
    "## PR Review Skill — Review Context\n",
    `### PR Description\n${input.description}\n`,
    `### Changed Files (${input.changed_files.length})\n`,
  ];

  for (const [category, files] of Object.entries(filesByType)) {
    if (files.length > 0) {
      parts.push(`**${category}:** ${files.join(", ")}`);
    }
  }

  parts.push("\n### Review Checklist\n");
  for (const [, category] of Object.entries(REVIEW_CATEGORIES)) {
    parts.push(`#### ${category.name}`);
    for (const check of category.checks) {
      parts.push(`- [ ] ${check}`);
    }
    parts.push("");
  }

  parts.push("### Diff\n```diff\n" + truncateDiff(input.diff) + "\n```\n");

  parts.push(
    "### Output Format\nProvide your review as:\n" +
      "1. **Verdict**: APPROVE / REQUEST_CHANGES / COMMENT\n" +
      "2. **Summary**: 2-3 sentence overview\n" +
      "3. **Issues**: List any problems found with severity (critical/warning/info)\n" +
      "4. **Suggestions**: Actionable improvements\n"
  );

  return parts.join("\n");
}

/**
 * Parses an agent's review output into structured format.
 */
export function parseReviewOutput(rawOutput: string): PRReviewOutput {
  const issues: PRIssue[] = [];
  const suggestions: string[] = [];
  const checklist: ChecklistItem[] = [];

  // Extract verdict
  let verdict: PRReviewOutput["verdict"] = "comment";
  const verdictMatch = rawOutput.match(
    /verdict[:\s]*(approve|request_changes|comment)/i
  );
  if (verdictMatch) {
    verdict = verdictMatch[1].toLowerCase() as PRReviewOutput["verdict"];
  } else if (rawOutput.toLowerCase().includes("approve")) {
    verdict = "approve";
  } else if (
    rawOutput.toLowerCase().includes("request changes") ||
    rawOutput.toLowerCase().includes("request_changes")
  ) {
    verdict = "request_changes";
  }

  // Extract summary (first paragraph or after "Summary:")
  const summaryMatch = rawOutput.match(
    /summary[:\s]*\n?([\s\S]*?)(?=\n(?:##|issues|suggestions|\*\*)|$)/i
  );
  const summary = summaryMatch
    ? summaryMatch[1].trim().substring(0, 500)
    : rawOutput.substring(0, 200);

  // Extract issues (lines starting with ❌, ⚠️, ℹ️, or severity markers)
  const issuePattern =
    /(?:❌|⚠️|ℹ️|critical|warning|info)[:\s]*(?:\*\*)?([^*\n]+)(?:\*\*)?/gi;
  let match;
  while ((match = issuePattern.exec(rawOutput)) !== null) {
    const severityIndicator = match[0].toLowerCase();
    let severity: PRIssue["severity"] = "info";
    if (severityIndicator.includes("critical") || severityIndicator.includes("❌")) {
      severity = "critical";
    } else if (severityIndicator.includes("warning") || severityIndicator.includes("⚠")) {
      severity = "warning";
    }

    issues.push({
      severity,
      file: "general",
      message: match[1].trim(),
      category: "review",
    });
  }

  // Extract suggestions (lines starting with - or •)
  const suggestionPattern = /^[\s]*[-•]\s*(?:suggestion[:\s]*)?(.+)$/gim;
  while ((match = suggestionPattern.exec(rawOutput)) !== null) {
    const text = match[1].trim();
    if (text.length > 10 && !text.startsWith("[")) {
      suggestions.push(text);
    }
  }

  // Extract checklist items
  const checkPattern = /^\s*-\s*\[([ xX])\]\s*(.+)$/gm;
  while ((match = checkPattern.exec(rawOutput)) !== null) {
    checklist.push({
      label: match[2].trim(),
      passed: match[1].toLowerCase() === "x",
    });
  }

  return { verdict, summary, issues, suggestions, checklist };
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function categorizeFiles(
  files: string[]
): Record<string, string[]> {
  const categories: Record<string, string[]> = {
    orchestrator: [],
    agents: [],
    providers: [],
    "web-app": [],
    config: [],
    scripts: [],
    docs: [],
    other: [],
  };

  for (const file of files) {
    if (file.startsWith("orchestrator/providers/")) categories.providers.push(file);
    else if (file.startsWith("orchestrator/")) categories.orchestrator.push(file);
    else if (file.startsWith("agents/")) categories.agents.push(file);
    else if (file.startsWith("src/")) categories["web-app"].push(file);
    else if (file.startsWith("config/")) categories.config.push(file);
    else if (file.startsWith("scripts/")) categories.scripts.push(file);
    else if (file.endsWith(".md")) categories.docs.push(file);
    else categories.other.push(file);
  }

  return categories;
}

function truncateDiff(diff: string, maxLines: number = 200): string {
  const lines = diff.split("\n");
  if (lines.length <= maxLines) return diff;
  return (
    lines.slice(0, maxLines).join("\n") +
    `\n\n... truncated (${lines.length - maxLines} more lines) ...`
  );
}
