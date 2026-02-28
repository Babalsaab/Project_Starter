---
name: pr-lifecycle
description: "Use when preparing pull requests, generating conventional commit messages, creating changelog entries, or evaluating merge readiness with blocker detection."
version: "1.0.0"
argument-hint: "[branch-name]"
compatible_agents:
  - release_engineer
  - devops_engineer
  - feedback_agent
  - deployment_readiness_agent
domain: "tech/"
priority: 10
user_invocable: true
---

# PR Lifecycle Skill

Manages the full pull request lifecycle from preparation through merge. This skill provides
structured prompts for generating conventional commit messages, creating changelog entries,
and evaluating merge readiness with automated blocker and warning detection.

## Capabilities

### 1. Conventional Commit Message Generation

Generates commit messages following the Conventional Commits specification.

**Format:**
```
<type>(<scope>): <short description>

<body>

<footer>
```

**Supported Types:**
| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring |
| `docs` | Documentation only |
| `chore` | Build/tooling/deps |
| `test` | Adding/fixing tests |
| `perf` | Performance improvement |

**Supported Scopes:**
`orchestrator`, `providers`, `agents`, `skills`, `web-app`, `scripts`, `config`, `ci`

The scope is automatically inferred from the changed file paths. The type is inferred
from commit message keywords (e.g., "fix", "add", "refactor").

**Rules:**
- Short description is imperative mood, max 72 characters
- Body explains WHY the change was made
- Footer includes `BREAKING CHANGE` if applicable

### 2. Changelog Entry Creation

Generates changelog entries in [Keep a Changelog](https://keepachangelog.com/) format.

**Categories:**
| Category | Description |
|----------|-------------|
| **Added** | New features |
| **Changed** | Changes to existing functionality |
| **Deprecated** | Soon-to-be removed features |
| **Removed** | Removed features |
| **Fixed** | Bug fixes |
| **Security** | Vulnerability fixes |

Commits are automatically categorized based on their prefix:
- `feat`/`add`/`new` commits go to **Added**
- `fix` commits go to **Fixed**
- All other commits go to **Changed**

Descriptions are written in user-facing language (not raw commit messages).

### 3. Merge Readiness Evaluation

Evaluates whether a PR is safe to merge by checking multiple quality gates.

**Merge Blockers** (PR cannot merge if any are present):
| Blocker | Condition |
|---------|-----------|
| TypeScript errors | `tsc_clean` is `false` |
| Agent validation failure | `agent_validation` is `"fail"` |
| Failing tests | `test_results.failed > 0` |
| No commits | `commits` array is empty |

**Merge Warnings** (PR can merge but should be reviewed):
| Warning | Condition |
|---------|-----------|
| Agent validation warnings | `agent_validation` is `"pass_with_warnings"` |
| High test skip ratio | Skipped tests exceed 50% of passed tests |
| Large PR | More than 1000 additions |

**Output:**
The merge readiness check returns:
- `ready` -- boolean indicating whether the PR can merge
- `blockers` -- list of issues that prevent merging
- `warnings` -- list of concerns that do not block but deserve attention
- `commit_message` -- auto-generated conventional commit message
- `changelog_entry` -- auto-generated changelog entry

## Inputs

| Input | Type | Description |
|-------|------|-------------|
| `commits` | `string[]` | List of commit messages in the PR |
| `changed_files` | `string[]` | List of file paths changed |
| `diff_stats` | `{ additions, deletions }` | Line count statistics |
| `test_results` | `{ passed, failed, skipped }` (optional) | Test run results |
| `tsc_clean` | `boolean` (optional) | Whether TypeScript compilation succeeded |
| `agent_validation` | `"pass" \| "pass_with_warnings" \| "fail"` (optional) | Agent validation result |

## Outputs

| Output | Description |
|--------|-------------|
| `commit_message` | Conventional commit message for the PR |
| `changelog_entry` | Keep a Changelog formatted entry |
| `merge_readiness_report` | Blockers, warnings, and overall readiness verdict |

## File Scope Mapping

Changed files are grouped by scope for commit message inference:
- `orchestrator/providers/` -- `providers`
- `orchestrator/` -- `orchestrator`
- `agents/` -- `agents`
- `skills/` -- `skills`
- `src/` -- `web-app`
- `config/` -- `config`
- `scripts/` -- `scripts`
- `.github/` -- `ci`

## Usage

This skill exposes three main functions:
- `buildCommitMessageContext(input)` -- generates prompt context for commit message creation
- `buildChangelogContext(input)` -- generates prompt context for changelog entry creation
- `checkMergeReadiness(input)` -- evaluates merge readiness and returns structured results
