---
name: pr-review
description: "Use when reviewing pull requests, checking code quality in diffs, running security analysis on changed files, or generating structured PR review reports."
version: "1.0.0"
argument-hint: "[pr-number-or-diff]"
compatible_agents:
  - qa_engineer
  - security_engineer
  - feedback_agent
  - ceo
domain: "tech/"
priority: 10
user_invocable: true
---

# PR Review Skill

Automated pull request quality analysis and structured review for the Vibecoded Orchestrator.
This skill provides agents with review checklists, diff categorization, and a standardized
output format so that every PR is evaluated consistently across security, quality,
architecture, testing, and documentation concerns.

## Review Categories

The skill evaluates PRs across five categories, each with its own checklist:

### Security
- No hardcoded secrets, API keys, or tokens
- No SQL injection vectors
- Input validation on user-facing endpoints
- No `eval()` or dynamic code execution
- Proper authentication/authorization checks

### Code Quality
- TypeScript strict mode compliance
- No `any` types without justification
- Functions under 50 lines
- Files under 600 lines
- Meaningful variable and function names
- No dead code or commented-out blocks

### Architecture
- Changes follow existing patterns
- No circular dependencies introduced
- Provider abstraction used (not direct API calls)
- Agent token caps respected
- Configuration via `globals.yaml`, not hardcoded

### Testing
- New functionality has corresponding tests
- Edge cases covered
- No test-only code in production files

### Documentation
- README updated for new features
- CLAUDE.md updated if agent/config changes
- JSDoc on public functions
- Inline comments for complex logic

## Inputs

| Input | Type | Description |
|-------|------|-------------|
| `diff` | `string` | The full PR diff |
| `description` | `string` | The PR description / body text |
| `changed_files` | `string[]` | List of file paths changed in the PR |
| `pr_number` | `number` (optional) | PR number for reference |
| `author` | `string` (optional) | PR author for context |

## File Categorization

Changed files are automatically categorized into groups for focused review:

- **orchestrator** -- files under `orchestrator/` (excluding providers)
- **providers** -- files under `orchestrator/providers/`
- **agents** -- files under `agents/`
- **web-app** -- files under `src/`
- **config** -- files under `config/`
- **scripts** -- files under `scripts/`
- **docs** -- markdown files
- **other** -- everything else

## Output Format

The skill produces a structured `PRReviewOutput` with the following fields:

### Verdict

One of three values:
- **APPROVE** -- PR meets all quality standards and is safe to merge
- **REQUEST_CHANGES** -- PR has issues that must be addressed before merging
- **COMMENT** -- PR needs discussion but is not necessarily blocked

### Summary

A 2-3 sentence overview of the PR's purpose and overall quality assessment
(capped at 500 characters).

### Issues

A list of problems found, each with:
| Field | Type | Description |
|-------|------|-------------|
| `severity` | `"critical" \| "warning" \| "info"` | Issue severity level |
| `file` | `string` | File where the issue was found |
| `line` | `number` (optional) | Line number if applicable |
| `message` | `string` | Description of the issue |
| `category` | `string` | Review category (security, quality, etc.) |

### Checklist

A list of checklist items with pass/fail status:
| Field | Type | Description |
|-------|------|-------------|
| `label` | `string` | The checklist item text |
| `passed` | `boolean` | Whether the check passed |
| `notes` | `string` (optional) | Additional context |

### Suggestions

A list of actionable improvement recommendations as plain strings.

## Usage

This skill is injected into agent context during PR review tasks. The `buildPRReviewContext`
function generates the review prompt with the diff, file categorization, and full checklist.
The `parseReviewOutput` function then parses the agent's free-text response back into the
structured `PRReviewOutput` format.
