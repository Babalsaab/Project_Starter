# GitHub Copilot Instructions for Vibecoded Orchestrator

## Project Overview

This is a **multi-agent AI orchestrator** structured like an IT company.
66 specialist agents (38 tech + 28 marketing) coordinated by a CEO orchestrator,
with CMO and CTO chiefs managing their teams, guided by 15 world-class mentors.

**Stack**: Next.js 15, TypeScript, Tailwind CSS, Prisma (SQLite dev / PostgreSQL prod),
NextAuth.js 5, shadcn/ui components.

**Architecture**: Agent YAML definitions → Provider abstraction → Execution engine → Artifact pipeline.

## Key Conventions

### File Organization
- `src/` — Next.js web app (TaskFlow dashboard)
- `orchestrator/` — CLI agent execution engine (separate tsconfig)
- `agents/` — Agent YAML definitions and persona documents
- `config/` — Global config, PRD templates, project sessions
- `scripts/` — CLI tools (validate, commit, bench, etc.)
- `skills/` — Dynamic skill modules loaded per agent
- `runs/` — Generated PRDs, artifacts, logs (gitignored outputs)

### TypeScript
- Use strict mode, no `any` unless truly necessary
- Orchestrator code compiles with `tsconfig.orchestrator.json`
- Next.js app compiles with `tsconfig.json`
- Max 600 LOC per file — split into modules if exceeded
- Use named exports; avoid default exports in libraries

### Agent System
- Agents are defined in YAML at `agents/pool/{tech,marketing}/`
- Chiefs at `agents/chiefs/`
- Each agent has: `id`, `title`, `domain`, `reports_to`, `responsibilities`,
  `expected_inputs`, `expected_outputs`, `token_cap`, `system_prompt`, `mentors`
- Persona files in `agents/personas/` enrich agent system prompts
- Never put full outputs in agent-to-agent messages — use file paths + summaries (≤150 tokens)

### Provider Abstraction
- **Never call Anthropic API directly** — always route through `orchestrator/providers/`
- Three provider types: `anthropic` (cloud), `openai-compatible` (local LLMs), `manual` (file-queue)
- Provider selection: per-agent overrides in `globals.yaml` → capability matching → priority fallback
- Add new providers by implementing `LLMProvider` interface from `providers/base.ts`

### Configuration
- Global settings in `config/globals.yaml` (brand voice, token policy, stop conditions, providers)
- Per-project state in `config/project-sessions/<id>/session.yaml`
- Mentors in `config/mentors.yaml`
- Agent registry in `config/registries/`

### Commit Guidelines
- Use `scripts/committer "msg"` instead of raw `git commit` — it runs safety checks
- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- Never commit `.env` files, API keys, or files > 500KB
- Run `npm run validate` before PRs to check agent definitions

### Testing
- Jest for unit tests, Playwright for E2E
- Agent validation: `npm run validate`
- TypeScript check: `npx tsc --noEmit -p tsconfig.orchestrator.json`
- LOC check: `npm run check:loc`

### When to Use Manual Mode
- Set provider type to `manual` in `globals.yaml` to use file-queue mode
- Instructions written to `runs/queue/<project-id>/step-NNN-<agent>-instruction.md`
- Paste LLM response into corresponding `step-NNN-<agent>-response.md`
- Use for: GitHub Copilot Chat, Claude Code, Antigravity, or any AI coder without API access

### Common Patterns
```typescript
// Loading an agent
import { loadAgentFromPool } from "./agent-configurator";
const agent = loadAgentFromPool("web_frontend_engineer");

// Getting runtime config
import { getTokenPolicy, getStopConditions } from "./runtime-config";
const policy = getTokenPolicy();

// Using providers
import { getProviderRegistry } from "./providers/index";
const registry = await getProviderRegistry();
const provider = registry.getProviderForAgent("backend_engineer");
const result = await provider.complete({ systemPrompt, messages, maxTokens });

// Inter-agent messaging
import { AgentMessageBus } from "./agent-messaging";
const bus = new AgentMessageBus(projectId);
bus.registerAgent({ agent_id: "qa_engineer", ... });
bus.sendMessage("qa_engineer", "web_frontend_engineer", "Review complete", "feedback");
```

## Do NOT
- Hard-code Anthropic API calls anywhere except `providers/anthropic.ts`
- Put full file contents in agent messages (use summaries + paths)
- Exceed 600 LOC in a single file without splitting
- Commit without running the committer script
- Modify `runs/` directory structure — it's generated output
- Use `console.log` for debugging (use proper logging or remove before commit)
- Use "intermediate" in capability levels (only: none, basic, advanced)
- Commit `.env`, `.env.local`, or any file containing API keys
- Run `eval()` or `Function()` with user-provided input

## Skills System
Skills extend agent capabilities without modifying YAML. Each has `config.yaml` + `SKILL.md`:
- `code-quality/` — Linting and code standards
- `prd-analysis/` — PRD evaluation and scoring
- `deploy-checklist/` — Pre-deployment verification
- `pr-review/` — Pull request code review
- `pr-lifecycle/` — PR creation, labeling, merging
- `security-audit/` — OWASP Top 10, supply chain, secrets
- `accessibility-check/` — WCAG 2.1 AA compliance
- `performance-budget/` — Core Web Vitals, bundle size limits
- `api-contract-validation/` — REST conventions, backward compat
- `design-system-lint/` — Design token and component consistency

## Testing
- **Vitest** for unit tests (config: `vitest.config.ts`)
- **Playwright** for E2E tests
- Test files: adjacent to source (`module.test.ts`)
- Coverage: V8 provider, 50% thresholds
- Run: `npx vitest run` (all) or `npx vitest run orchestrator/` (subset)
- Release readiness: `npx ts-node scripts/release-check.ts`

## CI/CD Workflows
| Workflow | File | Trigger |
|----------|------|---------|
| CI (lint, build, test) | `ci.yml` | Push/PR to main |
| Docker Release | `docker-release.yml` | Tag push (v*) |
| Stale Issues | `stale.yml` | Weekly cron |
| Install Smoke | `install-smoke.yml` | package.json changes |
| Workflow Sanity | `workflow-sanity.yml` | Workflow file changes |
| Labeler | `labeler.yml` | PR opens |

## Security
- Secrets via env vars only — never in code/config
- `.detect-secrets.cfg` + `.secrets.baseline` for secret scanning
- Dependabot monitors dependencies
- SECURITY.md documents vulnerability disclosure
- Agent outputs sandboxed to `runs/artifacts/<project-id>/`
