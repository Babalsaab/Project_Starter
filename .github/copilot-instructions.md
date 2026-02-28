# GitHub Copilot Instructions for Vibecoded Orchestrator

## MCP Tools Available

This project has an MCP server ("orchestrator") with 40 tools across 9 modules for agent management, quality review, PRD generation, workflow orchestration, and semantic memory. If your environment supports MCP, use these tools:

- `list_agents` / `get_agent` / `invoke_agent` / `suggest_agents` — Discover and adopt 66 specialist agents
- `list_personas` / `get_persona` — Load 70 expert professional profiles
- `list_mentors` / `mentor_review` — Apply review lenses from 15 world-class mentors
- `list_skills` / `get_skill` / `check_skill_applicability` / `create_claude_skill` — 10 quality skills + create new Claude Code native skills
- `list_prd_templates` / `get_prd_template` / `generate_prd_outline` — 35+ PRD templates
- `list_sessions` / `get_session` / `get_artifact` / `pipeline_status` — Orchestrator sessions
- `memory_read` / `memory_write` / `memory_search` / `memory_update` / `memory_delete` / `memory_stats` / `memory_related` / `memory_migrate` / `memory_session_start` — Structured memory with TF-IDF + BM25 semantic search
- `list_workflows` / `get_workflow` / `run_workflow` / `workflow_complete_step` / `workflow_approve` / `workflow_resume` / `workflow_status` / `list_workflow_executions` — YAML workflow pipelines with approval gates
- `discover_skills` / `install_skill` / `create_skill` / `skill_status` — Browse 8 curated external skill registries

## Project Overview

This is a **multi-agent AI orchestrator** structured like an IT company.
66 specialist agents (38 tech + 28 marketing) coordinated by a CEO orchestrator,
with CMO and CTO chiefs managing their teams, guided by 15 world-class mentors.

**Stack**: Next.js 15, TypeScript, Tailwind CSS, Prisma (SQLite dev / PostgreSQL prod),
NextAuth.js 5, shadcn/ui components.

**Architecture**: Agent YAML definitions -> Provider abstraction -> Execution engine -> Artifact pipeline.

## Key Conventions

### File Organization
- `src/` — Next.js web app (TaskFlow dashboard)
- `orchestrator/` — CLI agent execution engine (separate tsconfig)
- `agents/` — Agent YAML definitions and persona documents
- `config/` — Global config, PRD templates, project sessions
- `scripts/` — CLI tools (validate, commit, bench, etc.)
- `skills/` — 10 orchestrator quality skills loaded per agent
- `.claude/skills/` — 3 Claude Code native skills (invocable as /slash-commands)
- `runs/` — Generated PRDs, artifacts, workflow state, logs (gitignored outputs)
- `mcp-server/` — MCP server (40 tools) exposing agents/personas/mentors/skills/workflows/memory
- `config/workflows/` — YAML workflow pipeline definitions
- `memory/` — Structured fact store with semantic search index

### TypeScript
- Use strict mode, no `any` unless truly necessary
- Orchestrator code compiles with `tsconfig.orchestrator.json`
- Next.js app compiles with `tsconfig.json`
- MCP server compiles with `mcp-server/tsconfig.json`
- Max 600 LOC per file — split into modules if exceeded
- Use named exports; avoid default exports in libraries

### Agent System
- Agents are defined in YAML at `agents/pool/{tech,marketing}/`
- Chiefs at `agents/chiefs/`
- Each agent has: `id`, `title`, `domain`, `reports_to`, `responsibilities`,
  `expected_inputs`, `expected_outputs`, `token_cap`, `system_prompt`, `mentors`
- Persona files in `agents/personas/` enrich agent system prompts
- Never put full outputs in agent-to-agent messages — use file paths + summaries (<=150 tokens)

### Provider Abstraction
- **Never call Anthropic API directly** — always route through `orchestrator/providers/`
- Three provider types: `anthropic` (cloud), `openai-compatible` (local LLMs), `manual` (file-queue)
- Provider selection: per-agent overrides in `globals.yaml` -> capability matching -> priority fallback
- Add new providers by implementing `LLMProvider` interface from `providers/base.ts`

### Configuration
- Global settings in `config/globals.yaml`
- Per-project state in `config/project-sessions/<id>/session.yaml`
- Mentors in `config/mentors.yaml`
- Agent registry in `config/registries/`

### Commit Guidelines
- Use `scripts/committer "msg"` instead of raw `git commit` — it runs safety checks
- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- Never commit `.env` files, API keys, or files > 500KB
- Run `npm run validate` before PRs to check agent definitions

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

## Skills System

### Orchestrator Skills (via MCP `get_skill`)
10 quality skills loaded per agent. Use `check_skill_applicability` to find relevant ones:
- `code-quality` — Linting and code standards
- `security-audit` — OWASP Top 10, supply chain, secrets
- `accessibility-check` — WCAG 2.1 AA compliance
- `performance-budget` — Core Web Vitals, bundle size limits
- `api-contract-validation` — REST conventions, backward compat
- `design-system-lint` — Design token and component consistency
- `deploy-checklist` — Pre-deployment verification
- `prd-analysis` — PRD evaluation and scoring
- `pr-review` — Structured PR review with security/quality/architecture checklists
- `pr-lifecycle` — Conventional commits, changelog, merge readiness

### External Skill Registries (via MCP `discover_skills`)
8 curated registries with 100+ installable skills from Anthropic, Google, and the community.

### Claude Code Native Skills (`.claude/skills/`)
3 skills invocable as `/slash-commands`: `skill-builder`, `image-gen`, `antigravity-skill-creator`

## Testing
- **Vitest** for unit tests (config: `vitest.config.ts`)
- **Playwright** for E2E tests
- Test files: adjacent to source (`module.test.ts`)
- Coverage: V8 provider, 50% thresholds
- Run: `npx vitest run` (all) or `npx vitest run orchestrator/` (subset)
- Agent validation: `npm run validate`
- TypeScript check: `npx tsc --noEmit -p tsconfig.orchestrator.json`
- LOC check: `npm run check:loc`
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

## Do NOT
- Hard-code API calls anywhere except providers/
- Put full file contents in agent messages (use summaries + paths)
- Exceed 600 LOC in a single file
- Commit `.env`, `.env.local`, or any file containing API keys
- Run `eval()` or `Function()` with user-provided input
- Use `console.log` for debugging (use proper logging or remove before commit)
- Use "intermediate" in capability levels (only: none, basic, advanced)
- Commit without running the committer script
- Modify `runs/` directory structure — it's generated output
