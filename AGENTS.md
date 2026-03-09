# AGENTS.md — Instructions for AI Coding Agents

> **This file is for AI agents working in this codebase** (GitHub Copilot, Claude Code,
> Cursor, Cody, Antigravity, or any other AI-assisted development tool). It describes
> the project structure, coding standards, safety guardrails, and multi-agent conventions
> so you can produce correct, idiomatic contributions on the first attempt.

---

## Quick Reference

| Item | Value |
|------|-------|
| **Language** | TypeScript (strict mode) |
| **Runtime** | Node.js ≥ 18 |
| **Package manager** | npm |
| **Web framework** | Next.js 15 (App Router) |
| **UI** | React 18, Tailwind CSS, shadcn/ui |
| **Database** | Prisma — SQLite (dev) / PostgreSQL (prod) |
| **Auth** | NextAuth.js v5 |
| **Test runner** | Vitest (unit) · Playwright (E2E) |
| **Lint / Format** | ESLint · Prettier · markdownlint |
| **Orchestrator TSConfig** | `tsconfig.orchestrator.json` (ES2020, CommonJS) |
| **Web app TSConfig** | `tsconfig.json` (Next.js defaults) |
| **Dev server port** | 1000 |

---

## 1 — Project Structure

```
vibecoded-orchestrator/
├── src/                    # Next.js web app (TaskFlow dashboard)
│   ├── app/                #   App Router pages (home, auth, dashboard, PRD, orchestrator)
│   ├── components/         #   React components (auth, dashboard, layout, shadcn/ui)
│   ├── lib/                #   Prisma client, utilities
│   ├── styles/             #   Global CSS
│   └── types/              #   Shared TypeScript types
├── orchestrator/           # CLI agent execution engine
│   ├── index.ts            #   Entry point (discovery/execute/manual/hybrid/list/help)
│   ├── discovery.ts        #   Discovery Agent interview logic
│   ├── prd-generator.ts    #   PRD generation + agent selection
│   ├── agent-configurator.ts # Session creation + agent loading
│   ├── executor.ts         #   Agent execution engine (Claude API / manual / hybrid)
│   ├── runtime-config.ts   #   Loads globals.yaml and exposes typed accessors
│   ├── agent-messaging.ts  #   Inter-agent message bus + shared memory
│   ├── agent-skills.ts     #   Dynamic skill loader (per-agent skill modules)
│   └── providers/          #   LLM provider abstraction layer
│       ├── base.ts         #     Interfaces, types, utilities
│       ├── anthropic.ts    #     Claude API provider
│       ├── openai-compatible.ts # Local LLM / OpenAI-compatible provider
│       ├── manual.ts       #     File-queue provider (for API-less tools)
│       └── index.ts        #     Provider registry + factory
├── agents/                 # Agent definitions
│   ├── chiefs/             #   CEO, CMO, CTO, COO YAML definitions
│   ├── pool/tech/          #   46 technical specialist agents
│   ├── pool/marketing/     #   28 marketing specialist agents
│   └── personas/           #   81 expert persona enrichment documents
├── config/                 # Configuration
│   ├── globals.yaml        #   Brand, voice, token policy, providers, routing
│   ├── mentors.yaml        #   30 world-class mentor definitions
│   ├── orchestrator-schema.yaml
│   ├── prd-templates/      #   35+ PRD templates (core, specialized, companion)
│   ├── project-sessions/   #   Per-project runtime state
│   └── registries/         #   Agent + MCP tool registries
├── skills/                 # Dynamic skill modules (loaded per agent)
│   ├── code-quality/       #   Linting and code analysis
│   ├── prd-analysis/       #   PRD evaluation and scoring
│   ├── deploy-checklist/   #   Pre-deployment verification
│   ├── pr-review/          #   Pull request review automation
│   └── pr-lifecycle/       #   PR creation, labeling, merging
├── scripts/                # CLI tooling
│   ├── committer           #   Safe git commit with pre-checks (bash script)
│   ├── validate-agents.ts  #   Validate all agent YAML definitions
│   ├── check-ts-max-loc.ts #   Enforce 600 LOC file limit
│   ├── bench-model.ts      #   Benchmark LLM model performance
│   ├── usage-report.ts     #   Token usage analytics
│   ├── check-local-llm.ts  #   Verify local LLM availability
│   ├── queue-manager.ts    #   Manual mode queue management
│   ├── pr                  #   Create/list/merge PRs via GitHub API (bash script)
│   └── sync-labels.ts      #   Sync GitHub labels from config
├── runs/                   # Generated outputs (gitignored)
│   ├── prds/               #   Generated master PRDs
│   ├── artifacts/          #   Agent-produced outputs per project
│   ├── generated-prds/     #   Full PRD suite outputs
│   └── logs/               #   Execution logs
├── prisma/                 # Database schema + migrations
├── docs/                   # Workflow guides, API docs, playbooks
│   └── playbooks/          #   AI agent playbooks (shadcn, design)
└── .github/                # CI/CD, issue templates, instructions
```

---

## 2 — Build & Test Commands

```bash
# Install
npm install

# Dev server (port 1000)
npm run dev

# Type checking
npx tsc --noEmit                                     # Web app
npx tsc --noEmit -p tsconfig.orchestrator.json       # Orchestrator + scripts

# Tests
npx vitest run                    # All unit tests
npx vitest run --coverage         # With V8 coverage report
npx vitest run orchestrator/      # Orchestrator tests only
npx playwright test               # E2E tests

# Linting & validation
npm run lint                      # ESLint
npm run validate                  # Validate agent YAML definitions
npm run check:loc                 # Enforce 600 LOC per file

# Orchestrator CLI
npm run orchestrator              # Full flow: discovery → PRD → config → execute
npm run orchestrator:list         # List project sessions
npm run list-agents               # List all 74 agents
npm run generate:master-prd       # Generate master PRD
npm run generate:all-prds         # Generate full PRD suite (35+ docs)

# Database
npm run db:push                   # Push Prisma schema
npm run db:studio                 # Prisma Studio GUI

# Git (use committer, not raw git commit)
npm run commit "feat: description"
```

---

## 3 — Coding Standards

### TypeScript
- **Strict mode** — no `any` unless absolutely required (document why)
- Use **named exports** in library/module code; avoid default exports
- **Max 600 LOC** per file — split into modules when exceeded
- Use `interface` over `type` for object shapes; use `type` for unions/aliases
- Prefer `const` over `let`; never use `var`
- Use `async/await` over raw Promises

### Naming
- Files: `kebab-case.ts` (e.g., `agent-messaging.ts`)
- Classes/interfaces: `PascalCase` (e.g., `AgentMessageBus`)
- Functions/variables: `camelCase` (e.g., `loadGlobalConfig`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `CAPABILITY_LEVELS`)
- Agent IDs: `snake_case` (e.g., `web_frontend_engineer`)

### Imports
- Group: Node builtins → external packages → internal modules → types
- Use relative paths within the same module (`./sibling`)
- Use `../` for parent module references

### Error Handling
- Always wrap file I/O and network calls in try/catch
- Log warnings for recoverable errors (use `console.warn` with `⚠` prefix)
- Throw for unrecoverable errors with descriptive messages
- Never silently swallow errors

### Comments
- JSDoc for exported functions and classes
- Inline comments only for non-obvious logic
- Section dividers: `// ─── Section Name ────...`

---

## 4 — Commit & PR Guidelines

### Commits
- Use `npm run commit "msg"` (runs pre-commit safety checks)
- **Conventional commits**: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`
- Keep commit messages under 72 characters
- Reference issue numbers when applicable: `feat: add skill loader (#42)`

### Pre-commit Checks (automated via Husky)
1. `npm run validate` — validate agent YAML
2. `npm run check:loc` — enforce 600 LOC limit
3. `npx tsc --noEmit -p tsconfig.orchestrator.json` — type check

### Pull Requests
- Use `npm run pr:create` to create PRs from CLI
- PRs auto-labeled via `.github/labeler.yml`
- CI must pass: lint, type-check, build, test, security scan

---

## 5 — Agent System Rules

### Agent Definition (YAML)
Every agent lives in `agents/pool/{tech,marketing}/<id>.yaml` with this structure:

```yaml
id: "agent_id"
title: "Human-Readable Title"
domain: "tech/frontend"     # or marketing/email, etc.
reports_to: "CTO"           # or CMO
responsibilities:
  - "What this agent does"
expected_inputs: ["product_spec", "design_system"]
expected_outputs: ["component_code", "test_suite"]
token_cap: 2000
mentors: ["mentor_id"]
system_prompt: |
  You are a [role]. Given [inputs], produce [outputs].
```

### Key Rules
1. **Token efficiency** — Pass summaries (≤150 tokens) between agents, never full content
2. **File-based artifacts** — Store outputs as files; pass file paths between agents
3. **Minimal context** — Each agent gets only the PRD sections and artifacts it needs
4. **Skills are additive** — Skills in `skills/` extend agent capabilities without modifying YAML
5. **Persona enrichment** — `agents/personas/*.md` files add deep expertise context

### Adding a New Agent
1. Create YAML in `agents/pool/{tech,marketing}/<id>.yaml`
2. Optionally create persona in `agents/personas/<name>.md`
3. Run `npm run validate` to verify
4. Update `config/registries/agent-registry.yaml` if using registry

---

## 6 — Provider Architecture

### The Golden Rule
> **Never call any LLM API directly** — always route through `orchestrator/providers/`.

### Provider Types
| Type | File | Use Case |
|------|------|----------|
| `anthropic` | `providers/anthropic.ts` | Claude API (cloud) |
| `openai-compatible` | `providers/openai-compatible.ts` | Local LLMs (Ollama, LM Studio, vLLM) |
| `manual` | `providers/manual.ts` | File-queue for API-less tools (Copilot, Claude Code) |

### Provider Selection Flow
1. Per-agent override in `globals.yaml` → 2. Capability matching → 3. Priority fallback

### Adding a New Provider
Implement the `LLMProvider` interface from `providers/base.ts`:
```typescript
export interface LLMProvider {
  readonly name: string;
  readonly type: "anthropic" | "openai-compatible" | "manual";
  complete(request: CompletionRequest): Promise<CompletionResult>;
  getCapabilities(): ModelCapabilities;
  healthCheck(): Promise<boolean>;
}
```

---

## 7 — Configuration

### globals.yaml Sections
| Section | Purpose |
|---------|---------|
| `brand_profile` | Project name, description, category, markets |
| `brand_voice` | Tone keywords, do/don't rules |
| `token_policy_defaults` | Max tokens, steps, parallel agents, summarization level |
| `stop_conditions` | Max failures, retries, abort behavior |
| `routing_policy` | Domain → chief mapping, classification hints |
| `providers` | LLM provider definitions + per-agent overrides |
| `artifact_store` | Output storage config (local/s3/gdrive) |

### Runtime Config Access
```typescript
import { getTokenPolicy, getStopConditions, getBrandVoice } from "./runtime-config";
const policy = getTokenPolicy();  // typed TokenPolicy object
```

---

## 8 — Security Guardrails

### Never Do
- Commit `.env`, `.env.local`, or any file containing API keys
- Store secrets in YAML, JSON, or TypeScript files
- Log API keys or tokens to console
- Execute user-provided code without sandboxing
- Commit files larger than 500KB

### Always Do
- Use environment variables for secrets (`process.env.ANTHROPIC_API_KEY`)
- Validate all YAML inputs before processing
- Sanitize file paths to prevent directory traversal
- Run `npm audit` in CI for dependency vulnerabilities
- Check `.secrets.baseline` for accidental secret commits

---

## 9 — Multi-Agent Safety

When multiple AI agents work on this codebase simultaneously:

1. **File locking** — Don't modify the same file from parallel agent runs
2. **Artifact isolation** — Each project gets its own `runs/artifacts/<id>/` directory
3. **Message bus** — Use `AgentMessageBus` for inter-agent communication, not shared files
4. **Idempotent operations** — Agent tasks should be safe to re-run
5. **Progress tracking** — Use `session.yaml` for execution state; don't rely on in-memory state

---

## 10 — Testing Guidelines

### What to Test
- Provider utilities (`meetsRequirements`, `approximateTokenCount`, `trimContextToFit`)
- Agent message bus (registration, messaging, memory, persistence)
- Runtime config (loading, caching, accessors)
- Skills (each skill's `execute()` function)
- Agent YAML validation
- API route handlers

### Test File Location
- Place test files adjacent to source: `module.ts` → `module.test.ts`
- Test config: `vitest.config.ts` (root)
- Coverage thresholds: 50% lines/branches/functions/statements (enforced in CI)

### Test Patterns
```typescript
import { describe, it, expect, beforeEach, vi } from "vitest";

describe("ModuleName", () => {
  beforeEach(() => { /* setup */ });

  it("should do the expected thing", () => {
    expect(result).toBe(expected);
  });
});
```

---

## 11 — Common Patterns

### Loading an Agent
```typescript
import { loadAgentFromPool } from "./agent-configurator";
const agent = loadAgentFromPool("web_frontend_engineer");
```

### Using the Provider Registry
```typescript
import { getProviderRegistry } from "./providers/index";
const registry = await getProviderRegistry();
const provider = registry.getProviderForAgent("backend_engineer");
const result = await provider.complete({ systemPrompt, messages, maxTokens });
```

### Inter-Agent Messaging
```typescript
import { AgentMessageBus } from "./agent-messaging";
const bus = new AgentMessageBus(projectId);
bus.registerAgent({ agent_id: "qa_engineer", ... });
bus.send("qa_engineer", "backend_engineer", "Tests pass", "feedback");
```

### Loading Skills
```typescript
import { loadSkillsForAgent } from "./agent-skills";
const skills = await loadSkillsForAgent("qa_engineer", projectContext);
```

---

## 12 — Troubleshooting

| Problem | Solution |
|---------|----------|
| `tsc` errors in orchestrator/ | Use `tsconfig.orchestrator.json`: `npx tsc --noEmit -p tsconfig.orchestrator.json` |
| Missing Prisma client | Run `npx prisma generate` |
| Port 1000 in use | Kill existing process: `lsof -ti:1000 \| xargs kill` |
| Agent YAML validation fails | Check YAML syntax + required fields (id, title, domain, system_prompt) |
| No `ANTHROPIC_API_KEY` | Executor uses structured placeholders; set in `.env.local` for real calls |
| Manual mode queue empty | Check `runs/queue/<project-id>/` for instruction files |
| Local LLM not detected | Run `npm run check:local-llm` to verify Ollama/LM Studio is running |

---

*Last updated: auto-generated — do not edit manually*
