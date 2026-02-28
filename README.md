# 🎯 Vibecoded Orchestrator

> A unified multi-agent system structured like a real IT company — 66 specialist agents (38 tech + 28 marketing) coordinated by a CEO orchestrator, with CMO and CTO chiefs managing their respective teams, guided by a Mentors Layer of 15 world-class influences. Includes a comprehensive PRD generation system with 35+ templates, 70 expert personas, a pluggable LLM provider architecture (cloud APIs, local models, and API-less AI coders), and a production-ready Next.js 15 web app (TaskFlow) — all in one project with a single `npm install`.

---

## What Is This?

Most "AI agent" setups use 1–2 skills. This repo gives you the equivalent of a **full IT company** — a CEO-level orchestrator routing work through a CMO/CTO hierarchy down to 66 dedicated specialists, each operating with deep domain expertise from 70 expert personas and guidance from 15 world-class mentors.

**Three ways to run it:**

| Mode | Command | LLM Source |
|------|---------|------------|
| **Cloud API** | `npm run orchestrator` | Anthropic Claude (failover across models) |
| **Local LLM** | Configure `globals.yaml` | Ollama, LM Studio, llama.cpp, Jan.ai, vLLM |
| **Manual / AI Coder** | `npm run orchestrator -- manual <id>` | Copilot, Claude Code, Antigravity — no API needed |
| **Hybrid** | `npm run orchestrator -- hybrid <id>` | Mix any of the above per agent |

**The flow:**
```
You give a project idea
  → Discovery Agent interviews you
  → Master PRD is generated (35+ template library)
  → Orchestrator selects the right agents (from 66 specialists)
  → Mentors inject quality principles at review gates
  → Agents execute in 9 phases and produce artifacts
  → Dashboard shows real-time progress
```

---

## Table of Contents

- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [CLI Reference](#cli-reference)
- [Agent System](#agent-system)
- [LLM Provider Architecture](#llm-provider-architecture)
- [Agent Skills](#agent-skills)
- [Mentors Layer](#mentors-layer)
- [Personas](#personas)
- [PRD Generation System](#prd-generation-system)
- [TaskFlow Web App](#taskflow-web-app)
- [Scripts & Tooling](#scripts--tooling)
- [CI/CD & Quality Gates](#cicd--quality-gates)
- [Configuration](#configuration)
- [Token Optimisation](#token-optimisation)
- [Customisation](#customisation)
- [Roadmap](#roadmap)

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/yourname/vibecoded-orchestrator.git
cd vibecoded-orchestrator

# 2. Install dependencies (single command for everything)
npm install

# 3. Set your API key (optional — manual mode works without any API)
cp .env.example .env.local
# Add: ANTHROPIC_API_KEY=sk-ant-...

# 4. Start a new project (full flow)
npm run orchestrator

# 5. Or start the web dashboard
npm run dev
# → http://localhost:1000
```

### First Run

The orchestrator walks you through:

1. **Discovery** — answers 10–15 questions about your project
2. **PRD Generation** — creates a comprehensive Master PRD
3. **Agent Selection** — picks the right specialists from 66 agents
4. **Execution** — runs agents in 9 phases with mentor reviews

Outputs land in:
- `runs/prds/<project-id>-prd.md` — Master PRD
- `runs/artifacts/<project-id>/` — Agent outputs
- `config/project-sessions/<project-id>/` — Session state & execution plan

---

## Project Structure

```
vibecoded-orchestrator/
│
├── orchestrator/                    # Core engine
│   ├── index.ts                     # CLI entry point (discovery → PRD → config → execute)
│   ├── discovery.ts                 # Discovery Agent interview logic
│   ├── prd-generator.ts            # PRD generation & agent selection
│   ├── agent-configurator.ts       # Session creation & agent loading
│   ├── executor.ts                  # Execution engine (9-phase pipeline, retries, mentor reviews)
│   ├── runtime-config.ts           # Dynamic runtime configuration
│   ├── agent-messaging.ts          # Inter-agent message bus
│   ├── agent-skills.ts             # Skill loader & injector
│   └── providers/                   # LLM provider abstraction
│       ├── base.ts                  # Universal LLMProvider interface
│       ├── anthropic.ts             # Anthropic Claude (cloud API, model failover)
│       ├── openai-compatible.ts     # Any OpenAI-compatible server (Ollama, LM Studio, etc.)
│       ├── manual.ts                # File-queue provider (API-less AI coders)
│       └── index.ts                 # Provider registry, factory, routing, retry logic
│
├── agents/
│   ├── chiefs/                      # Leadership layer
│   │   ├── ceo.yaml                 # Chief orchestrator
│   │   ├── cto.yaml                 # Tech domain chief
│   │   ├── cmo.yaml                 # Marketing domain chief
│   │   └── coo.yaml                 # Operations chief
│   ├── pool/
│   │   ├── tech/                    # 38 tech specialist agents
│   │   └── marketing/               # 28 marketing specialist agents
│   └── personas/                    # 70 expert persona docs (enrich agent prompts)
│
├── skills/                          # Reusable agent skills (injected at runtime)
│   ├── code-quality/                # Code review checklists & linting context
│   ├── prd-analysis/                # PRD completeness & gap analysis
│   ├── deploy-checklist/            # Deployment readiness verification
│   ├── pr-review/                   # Pull request review skill
│   └── pr-lifecycle/                # Commit messages, changelogs, merge readiness
│
├── config/
│   ├── globals.yaml                 # Global brand, voice, token policies, provider config
│   ├── mentors.yaml                 # 15 world-class mentors layer
│   ├── orchestrator-schema.yaml     # Runtime execution schema
│   ├── registries/                  # Agent & MCP tool registries
│   ├── project-sessions/            # Per-project session state
│   └── prd-templates/
│       ├── core/                    # 29 core domain PRD templates
│       ├── specialized/             # 4 specialized templates (AI/ML, DevOps, etc.)
│       └── companion/               # Design + Tasks companion templates
│
├── src/                             # TaskFlow Web App (Next.js 15)
│   ├── app/
│   │   ├── page.tsx                 # Landing page
│   │   ├── auth/                    # Authentication pages
│   │   ├── dashboard/               # User dashboard
│   │   ├── prd-generator/           # PRD generation UI
│   │   ├── prd-templates/           # Template browser
│   │   ├── orchestrator/            # Orchestrator dashboard
│   │   │   ├── page.tsx             # Sessions list, stats, CLI reference
│   │   │   ├── [id]/page.tsx        # Session detail — pipeline view, PRD, artifacts
│   │   │   └── agents/page.tsx      # Agent registry browser (all 66 agents + personas)
│   │   └── api/                     # API routes
│   │       └── orchestrator/        # Sessions, artifacts, agents API
│   ├── components/                  # React components (auth, dashboard, layout, shadcn/ui)
│   ├── lib/                         # Prisma client, utilities
│   └── styles/                      # Global styles
│
├── scripts/                         # Developer tooling
│   ├── validate-agents.ts           # Validate all agent YAML files
│   ├── check-ts-max-loc.ts          # Enforce max lines-of-code per file
│   ├── committer                    # Safe git commit wrapper (blocks secrets, large files)
│   ├── pr                           # Unified PR lifecycle manager (create/review/merge)
│   ├── bench-model.ts               # Benchmark LLM providers & models
│   ├── usage-report.ts              # Token usage & cost reports
│   ├── check-local-llm.ts           # Verify local LLM servers are reachable
│   ├── queue-manager.ts             # Manual file-queue CLI (list/status/respond/export)
│   ├── sync-labels.ts               # Sync GitHub labels from predefined set
│   ├── list-agents.js               # List all available agents
│   ├── generate-master-prd.ts       # Generate a master PRD
│   ├── generate-all-prds.ts         # Generate complete PRD suite (35+ docs)
│   └── setup-project.ts             # Project setup wizard
│
├── runs/                            # Runtime outputs
│   ├── prds/                        # Generated Master PRDs
│   ├── artifacts/                   # Agent-produced outputs (per project)
│   ├── generated-prds/              # Full PRD suite outputs
│   ├── queue/                       # Manual mode file-queue
│   └── logs/                        # Execution logs
│
├── prisma/                          # Database (SQLite dev / PostgreSQL prod)
│   ├── schema.prisma
│   └── seed.ts
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                   # CI pipeline
│   │   └── labeler.yml              # Auto-label PRs by file paths
│   ├── dependabot.yml               # Automated dependency updates
│   ├── labeler.yml                  # PR label rules (11 labels)
│   ├── instructions/
│   │   └── copilot.instructions.md  # AI coder conventions
│   ├── ISSUE_TEMPLATE/              # Issue templates
│   └── pull_request_template.md     # PR template
│
├── .husky/
│   └── pre-commit                   # Pre-commit hook (secrets, compilation)
│
├── docs/                            # Guides & references
├── implementations/                 # AI agent playbooks (shadcn, design, components)
└── docker-compose.yml               # Docker deployment
```

---

## CLI Reference

```bash
# ─── Orchestrator ──────────────────────────────────────────────
npm run orchestrator                              # Full flow: Discovery → PRD → Configure → Execute
npm run orchestrator -- list                      # List all project sessions
npm run orchestrator -- execute <project-id>      # Resume execution for a project
npm run orchestrator -- manual <project-id>       # Run in manual mode (file-queue, no API)
npm run orchestrator -- hybrid <project-id>       # Run with mixed providers per agent
npm run orchestrator -- hybrid <id> --map "qa_engineer=manual,ux_designer=ollama"
npm run orchestrator -- help                      # Show CLI help

# ─── Web App ──────────────────────────────────────────────────
npm run dev                                       # Start TaskFlow (http://localhost:1000)
npm run build                                     # Production build
npm run start:web                                 # Start production server

# ─── Agent Tools ──────────────────────────────────────────────
npm run list-agents                               # List all 66 agents
npm run validate                                  # Validate all agent YAML files
npm run queue -- status                           # Manual queue status dashboard
npm run queue -- list                             # List all queue entries
npm run queue -- respond <step> <file>            # Submit a response to a queue step
npm run queue -- export                           # Export all pending as one .md doc

# ─── LLM & Benchmarking ──────────────────────────────────────
npm run bench:model                               # Benchmark LLM providers/models
npm run usage:report                              # Token usage & cost reports
npm run check:llm                                 # Verify local LLM servers are running

# ─── PRD Generation ──────────────────────────────────────────
npm run generate:master-prd                       # Generate a master PRD
npm run generate:all-prds                         # Generate complete PRD suite (35+ docs)

# ─── Code Quality ────────────────────────────────────────────
npm run check:loc                                 # Enforce max LOC per file
npm run commit                                    # Safe commit wrapper (blocks secrets)
npm run lint                                      # ESLint
npm run type-check                                # TypeScript type check

# ─── Database ────────────────────────────────────────────────
npm run db:push                                   # Push Prisma schema
npm run db:studio                                 # Open Prisma Studio GUI
npm run db:migrate                                # Run migrations
npm run db:seed                                   # Seed database

# ─── Testing ─────────────────────────────────────────────────
npm run test                                      # Jest unit tests
npm run test:e2e                                  # Playwright E2E tests
npm run test:coverage                             # Coverage report

# ─── CI/CD ───────────────────────────────────────────────────
npm run sync:labels                               # Sync GitHub labels (25 labels)
scripts/pr create                                 # Create PR with pre-flight checks
scripts/pr review                                 # Automated PR review checklist
scripts/pr merge                                  # Squash merge + branch cleanup
```

---

## Agent System

### Hierarchy

```
MENTORS (15 world-class influences — advisory layer)
  └── CEO (Chief Orchestrator)
        ├── CTO ← Tech Domain (38 agents)
        │     ├── Product & Research
        │     │   ├── product_manager
        │     │   ├── ux_researcher
        │     │   └── product_analyst
        │     ├── Design
        │     │   ├── ux_designer          ├── interaction_designer
        │     │   ├── ui_designer          ├── information_architect
        │     │   ├── art_director         ├── design_systems_engineer
        │     │   ├── motion_designer      ├── prototype_engineer
        │     │   └── 3d_designer
        │     ├── Engineering
        │     │   ├── web_frontend_engineer    ├── backend_engineer
        │     │   ├── ios_engineer             ├── api_designer
        │     │   ├── android_engineer         ├── database_engineer
        │     │   ├── cross_platform_engineer  ├── data_engineer
        │     │   ├── design_engineer          ├── ml_engineer
        │     │   ├── webgl_engineer           ├── devops_engineer
        │     │   └── frontend_performance_engineer
        │     ├── Quality & Security
        │     │   ├── qa_engineer              ├── security_engineer
        │     │   ├── test_automation_engineer ├── accessibility_engineer
        │     │   └── experimentation_engineer
        │     ├── Release & Docs
        │     │   ├── release_engineer
        │     │   └── technical_writer
        │     └── Operations (utility agents)
        │         ├── feedback_agent               ├── environment_checker_agent
        │         ├── error_logging_agent           ├── dependency_tracker_agent
        │         ├── directory_housekeeping_agent  └── deployment_readiness_agent
        │
        └── CMO ← Marketing Domain (28 agents)
              ├── Strategy
              │   ├── marketing_strategist     ├── brand_strategist
              │   ├── growth_marketer          ├── performance_marketer
              │   └── marketing_analytics
              ├── Acquisition
              │   ├── seo_specialist       ├── sem_specialist
              │   ├── media_buyer          ├── affiliate_manager
              │   ├── aso_specialist        └── partnership_manager
              ├── Social & Community
              │   ├── social_media_marketer    ├── influencer_manager
              │   ├── community_manager        └── social_video_creator
              ├── Content & Copy
              │   ├── content_strategist       ├── marketing_copywriter
              │   ├── ux_writer                ├── editorial_writer
              │   └── marketing_designer
              ├── Email & CRM
              │   ├── email_strategist         ├── email_copywriter
              │   ├── email_designer           ├── email_platform_builder
              │   ├── crm_automation_specialist └── push_messaging_specialist
              ├── Conversion
              │   └── cro_specialist
              └── Video
                  └── video_producer
```

### Agent YAML Structure

Each agent in `agents/pool/` is a YAML file:

```yaml
id: "web_frontend_engineer"
title: "Web Frontend Engineer"
domain: "tech/frontend"
reports_to: "CTO"
responsibilities:
  - "Build responsive, accessible web interfaces"
  - "Implement component architecture and state management"
expected_inputs: ["product_spec", "ui_designs", "api_contracts"]
expected_outputs: ["frontend_code", "component_library", "build_config"]
token_cap: 4000
mentors: ["steve_jobs", "dieter_rams"]
system_prompt: |
  You are a senior frontend engineer. Given the product spec and UI designs,
  produce production-ready component code with proper accessibility.
```

The orchestrator reads these at runtime, selects the relevant subset for the project, configures them with persona context and mentor principles, and feeds them into the 9-phase execution pipeline.

### Execution Pipeline (9 Phases)

```
Phase 1: Planning          → product_manager, ux_researcher
Phase 2: Architecture      → backend_engineer, api_designer, database_engineer
Phase 3: Design            → ux_designer, ui_designer, design_systems_engineer
Phase 4: Implementation    → web_frontend_engineer, backend_engineer, etc.
Phase 5: Integration       → api_designer, data_engineer
Phase 6: Testing           → qa_engineer, test_automation_engineer, security_engineer
Phase 7: Review            → mentor review pass, feedback_agent
Phase 8: Documentation     → technical_writer, release_engineer
Phase 9: Deployment        → devops_engineer, deployment_readiness_agent
```

Each phase has dependency tracking, quality gates, and optional mentor reviews.

---

## LLM Provider Architecture

The provider system abstracts away the LLM backend so agents can run on any model source:

```
┌─────────────────────────────────────────────────────────┐
│                   ProviderRegistry                       │
│  (factory, routing, retry, health checks, agent maps)    │
├─────────────┬─────────────────┬─────────────────────────┤
│  Anthropic  │ OpenAI-Compat   │     Manual              │
│  Provider   │ Provider        │     Provider            │
├─────────────┼─────────────────┼─────────────────────────┤
│ Claude API  │ Ollama          │ File-queue for          │
│ (Sonnet,    │ LM Studio       │ Copilot, Claude Code,   │
│  Haiku,     │ llama.cpp       │ Antigravity, or any     │
│  Opus)      │ Jan.ai / vLLM   │ human operator          │
└─────────────┴─────────────────┴─────────────────────────┘
```

### Provider Types

| Provider | Type | Use Case |
|----------|------|----------|
| **AnthropicProvider** | `anthropic` | Cloud Claude API with automatic model failover (Sonnet → Haiku) |
| **OpenAICompatibleProvider** | `openai-compatible` | Any `/v1/chat/completions` endpoint — Ollama, LM Studio, llama.cpp, Jan.ai, vLLM |
| **ManualProvider** | `manual` | File-queue: writes instructions as `.md`, polls for human/AI-coder responses |

### Configuring Providers

Providers are configured in `config/globals.yaml`:

```yaml
providers:
  - id: "anthropic-cloud"
    name: "Anthropic Claude"
    type: "anthropic"
    api_key_env: "ANTHROPIC_API_KEY"
    models: ["claude-sonnet-4-20250514", "claude-haiku-4-20250514"]
    enabled: true
    priority: 1

  - id: "ollama-local"
    name: "Ollama Local"
    type: "openai-compatible"
    base_url: "http://localhost:11434/v1"
    models: ["llama3.1", "codellama"]
    enabled: true
    priority: 5

  - id: "manual-queue"
    name: "Manual File Queue"
    type: "manual"
    queue_dir: "./runs/queue"
    poll_interval_ms: 3000
    enabled: true
    priority: 10
```

### Hybrid Mode — Per-Agent Routing

Map specific agents to specific providers:

```yaml
# In globals.yaml
agent_provider_overrides:
  security_engineer: "anthropic-cloud"    # Always use cloud for security
  web_frontend_engineer: "manual-queue"   # Let Copilot handle frontend
  qa_engineer: "ollama-local"             # Local model for QA
```

Or at runtime:
```bash
npm run orchestrator -- hybrid my-project \
  --map "qa_engineer=manual-queue,backend_engineer=ollama-local"
```

### Manual Mode — No API Required

For developers using AI coders (GitHub Copilot, Claude Code, Antigravity) or who want human-in-the-loop:

```bash
# Start manual mode
npm run orchestrator -- manual my-project

# Instructions appear at runs/queue/my-project/
# Each step gets a file like: step-001-ux_designer-instruction.md
# Create the matching: step-001-ux_designer-response.md
# The orchestrator picks it up and continues

# Monitor queue status
npm run queue -- status

# Submit a response
npm run queue -- respond 001 my-response.md

# Export all pending as one doc
npm run queue -- export
```

---

## Agent Skills

Skills are reusable capability modules injected into agents at runtime:

| Skill | Applicable Agents | Purpose |
|-------|-------------------|---------|
| **code-quality** | `qa_engineer`, `web_frontend_engineer`, `backend_engineer` | Code review checklists, linting context, best practices |
| **prd-analysis** | `product_manager`, `ux_researcher`, `feedback_agent` | PRD completeness scoring, gap detection |
| **deploy-checklist** | `devops_engineer`, `deployment_readiness_agent`, `release_engineer` | Pre-deploy verification, environment checks |
| **pr-review** | `qa_engineer`, `security_engineer`, `feedback_agent`, `ceo` | PR review checklists (security, quality, architecture, testing) |
| **pr-lifecycle** | `release_engineer`, `devops_engineer`, `deployment_readiness_agent` | Commit messages, changelogs, merge readiness checks |

Add new skills by creating a directory under `skills/` with:
- `skill.json` — metadata, applicable agents, input/output spec
- `index.ts` — skill logic (context builder, output parser)

---

## Mentors Layer

15 world-class influences shape agent decisions at review gates:

| Mentor | Domain Focus | Key Principle |
|--------|-------------|---------------|
| **Steve Jobs** | Product, UX, Storytelling | "Ruthless simplicity — remove everything non-essential" |
| **Dieter Rams** | Industrial Design | "Good design is as little design as possible" |
| **Jeff Bezos** | Customer Obsession, Scale | "Start with the customer and work backwards" |
| **Satya Nadella** | Platform Thinking | "Empathy-driven engineering" |
| **Jensen Huang** | AI/GPU/Performance | "Accelerated computing changes everything" |
| **Marc Benioff** | SaaS, Cloud, CRM | "The business of business is improving the world" |
| **Tobi Lütke** | Commerce, Developer Tools | "Build something people want, then make it simple" |
| **Brian Chesky** | Design-Led, Marketplace | "Design every detail of the experience" |
| **Whitney Wolfe Herd** | Social, Safety, Community | "Safety-first product design" |
| **Stewart Butterfield** | Collaboration, UX | "Focus on the 'magic' moments" |
| **Patrick Collison** | Payments, API Design | "Move fast, but build for decades" |
| **Ev Williams** | Publishing, Content | "Content is the starting point for everything" |
| **Daniel Ek** | Audio, Personalization | "Personalization at scale" |
| **Drew Houston** | File Sync, Simplicity | "Make the complex invisible" |
| **Jack Dorsey** | Real-time, Payments | "Constraint breeds creativity" |

Mentors are defined in `config/mentors.yaml` and injected into agents via `influences_agents` mappings.

---

## Personas

70 expert personas provide deep domain expertise to agents. Each persona is a detailed markdown profile including:

- Professional background & specialization
- Design/engineering philosophy
- Preferred tool stack & methodology
- Quality benchmarks & review criteria

Example mapping:

| Persona | Agent(s) |
|---------|----------|
| Sarah Chen (UX/UI) | `ux_designer`, `ui_designer` |
| Marcus Rodriguez (Backend) | `backend_engineer`, `api_designer` |
| Jordan Park (Frontend) | `web_frontend_engineer`, `design_engineer` |
| Rachel Thompson (Security) | `security_engineer` |
| Alex Kim (DevOps) | `devops_engineer`, `release_engineer` |
| Jennifer Wu (QA) | `qa_engineer`, `test_automation_engineer` |
| Thomas Clark (Mobile) | `ios_engineer`, `android_engineer`, `cross_platform_engineer` |
| Maria Santos (Database) | `database_engineer` |
| Amara Osei (ML) | `ml_engineer` |
| Raj Krishnamurthy (WebGL) | `webgl_engineer` |

See `agents/personas/` for the full set of 70 persona documents.

---

## PRD Generation System

35+ PRD templates covering every domain:

### Core Templates (29)

| Category | Templates |
|----------|-----------|
| **Frontend** | Frontend architecture, UI/UX design, accessibility, performance |
| **Backend** | Backend architecture, API documentation, database design |
| **Infrastructure** | DevOps, security, error handling |
| **Mobile** | Mobile development (iOS, Android, cross-platform) |
| **Data** | Analytics, data engineering |
| **Quality** | QA & testing, integration testing |
| **Content** | Content strategy |

### Specialized Templates (4)

- AI/ML Integration Agent PRD
- DevOps Infrastructure Agent PRD
- shadcn UI Agent PRD
- Testing & QA Agent PRD

### Companion Templates (2)

- Design Companion Template
- Tasks Companion Template

Generate the full suite with:
```bash
npm run generate:all-prds    # Generates 35+ documents
npm run generate:master-prd  # Single master PRD
```

---

## TaskFlow Web App

A production-ready Next.js 15 dashboard running on port 1000:

```bash
npm run dev  # → http://localhost:1000
```

### Pages

| Path | Description |
|------|-------------|
| `/` | Landing page |
| `/auth/*` | Authentication (NextAuth.js 5) |
| `/dashboard` | User dashboard |
| `/prd-generator` | Interactive PRD generation UI |
| `/prd-templates` | Browse PRD template library |
| `/orchestrator` | Session list, stats, CLI reference |
| `/orchestrator/<id>` | Session detail — pipeline view, PRD, artifact viewer |
| `/orchestrator/agents` | Agent registry browser (all 66 agents + personas) |

### API Routes

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/orchestrator/sessions` | GET | List all sessions with progress |
| `/api/orchestrator/sessions/[id]` | GET/POST | Session details / trigger execution |
| `/api/orchestrator/artifacts/[id]` | GET | Artifact content by project |
| `/api/orchestrator/agents` | GET | Full agent registry |

### Tech Stack

- **Framework:** Next.js 15 (App Router)
- **Auth:** NextAuth.js 5
- **Database:** Prisma (SQLite dev / PostgreSQL prod)
- **UI:** shadcn/ui + Tailwind CSS
- **Deployment:** Docker + docker-compose

---

## Scripts & Tooling

### Agent Validation
```bash
npm run validate
```
Validates every agent YAML in `agents/pool/` and `agents/chiefs/`. Checks required fields, unique IDs, `reports_to` references, cross-references between inputs/outputs, persona file existence, mentor references, and token cap bounds.

### Code Quality Enforcement
```bash
npm run check:loc              # Enforce max 600 LOC per file
npm run check:loc -- --max 400 # Custom threshold
npm run check:loc -- --fix-hint # Suggest how to split large files
```

### Safe Git Commits
```bash
npm run commit                 # or: scripts/committer
npm run commit -- --dry-run    # Preview without committing
```
Blocks `.env` files, API key patterns, large files (>500KB), merge conflict markers, and debug statements. Runs TypeScript compilation and agent validation before committing.

### PR Lifecycle
```bash
scripts/pr create              # Pre-flight checks + auto-generate PR body
scripts/pr review              # Automated review checklist + code checks
scripts/pr prepare             # Rebase + verify before merge
scripts/pr merge               # Squash merge + delete branch
scripts/pr status              # Current PR status
scripts/pr list                # List open PRs
```

### LLM Benchmarking
```bash
npm run bench:model                          # Benchmark all configured providers
npm run bench:model -- --provider ollama     # Benchmark specific provider
npm run bench:model -- --output results.json # Save results as JSON
```
Runs 3 standardized test prompts (structured output, code generation, analysis) across all providers. Reports latency, p95, token statistics, and quality scores.

### Token Usage Reports
```bash
npm run usage:report                     # Full report
npm run usage:report -- --session my-id  # Filter by session
npm run usage:report -- --days 7         # Last 7 days
npm run usage:report -- --format json    # JSON output
```

### Local LLM Health Check
```bash
npm run check:llm
```
Verifies local LLM servers are reachable, lists available models, compares with configured models, and provides setup hints.

### Manual Queue Manager
```bash
npm run queue -- list           # Show all queue entries
npm run queue -- status         # Dashboard with progress bars
npm run queue -- show <step>    # Display instruction content
npm run queue -- respond <step> <file>  # Submit response
npm run queue -- clear          # Remove completed entries
npm run queue -- export         # All pending as one .md doc
```

### GitHub Label Sync
```bash
npm run sync:labels              # Sync 25 labels to GitHub
npm run sync:labels -- --dry-run # Preview only
```

---

## CI/CD & Quality Gates

### Pre-Commit Hook (`.husky/pre-commit`)

Runs automatically on every commit (<5s):
- Blocks `.env` files from being committed
- Scans for API key patterns
- Checks for merge conflict markers
- TypeScript compilation check on orchestrator changes

### GitHub Actions

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push/PR | Full CI pipeline |
| `labeler.yml` | PR events | Auto-label PRs by changed file paths |

### PR Auto-Labels (`.github/labeler.yml`)

PRs are automatically labeled based on changed files:

| Label | Triggered By |
|-------|-------------|
| `area: orchestrator` | `orchestrator/**` changes |
| `area: agents` | `agents/**` changes |
| `area: providers` | `orchestrator/providers/**` changes |
| `area: skills` | `skills/**` changes |
| `area: config` | `config/**` changes |
| `area: web-app` | `src/**` changes |
| `area: scripts` | `scripts/**` changes |
| `area: ci` | `.github/**` changes |
| `area: docs` | `docs/**`, `*.md` changes |
| `area: prd` | PRD template changes |
| `dependencies` | `package.json`, `prisma/` changes |

### Dependabot (`.github/dependabot.yml`)

- **npm:** Weekly updates (grouped by ecosystem)
- **GitHub Actions:** Weekly updates
- **Docker:** Monthly updates
- Major version bumps ignored by default

---

## Configuration

### `config/globals.yaml`

Central configuration for brand, voice, token policies, and providers:

```yaml
globals:
  brand_name: "Your Brand"
  brand_voice: "Professional, friendly, technical"
  default_token_cap: 4000
  max_retries: 3

  providers:
    - id: "anthropic-cloud"
      type: "anthropic"
      # ... (see Provider Architecture section)

  agent_provider_overrides: {}
```

### `config/mentors.yaml`

15 mentor definitions with principles, quotes, and agent influence mappings.

### `config/orchestrator-schema.yaml`

Runtime execution schema — defines phases, step dependencies, quality gates.

### `config/project-sessions/<id>/`

Per-project state:
- `session.yaml` — project config, selected agents, status
- `execution-plan.yaml` — generated task plan
- `execution-metrics.json` — runtime metrics (tokens, timing, retries)

---

## Token Optimisation

- **Scoped context:** Agents receive only the slice of the PRD they need, not the full document
- **Summary compression:** Outputs are summarized (≤150 tokens) before being passed to downstream agents
- **File-based artifacts:** Full outputs are stored as files; agents receive file paths, not content
- **Per-agent caps:** Each agent has a `token_cap` field enforced at runtime
- **Model failover:** Automatic fallback from larger to smaller models on rate limits (e.g., Sonnet → Haiku)
- **Inter-agent messaging:** The message bus passes metadata and references, not full payloads

---

## Customisation

### Add a New Agent

Drop a YAML file in `agents/pool/tech/` or `agents/pool/marketing/`:

```yaml
id: "my_new_agent"
title: "My New Agent"
domain: "tech/frontend"   # or marketing/email, etc.
reports_to: "CTO"         # or CMO
responsibilities:
  - "What this agent does"
expected_inputs: ["product_spec"]
expected_outputs: ["my_output"]
token_cap: 2000
system_prompt: |
  You are a [role]. Given [inputs], produce [outputs].
  Be specific. Stay within token_cap.
```

Validate with: `npm run validate`

### Add a New Persona

Drop a markdown file in `agents/personas/` following the naming pattern: `firstname-lastname-role.md`.

Include: professional profile, background, philosophy, tool stack, methodology.

### Add a New Skill

Create a directory under `skills/` with:
1. `skill.json` — metadata, applicable agents, input/output spec
2. `index.ts` — `buildContext()` and `parseOutput()` functions

### Add a New Provider

1. Create a class implementing `LLMProvider` in `orchestrator/providers/`
2. Register the type in `orchestrator/providers/index.ts` → `createProvider()`
3. Add config to `config/globals.yaml` → `providers`

### Change Global Settings

Edit `config/globals.yaml` — brand name, voice, token policies, retry behaviour.

### Project-Specific Overrides

Create `config/project-sessions/<id>/overrides.yaml` for per-project config.

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | No* | Anthropic Claude API key (*not needed for manual/local mode) |
| `DATABASE_URL` | No | Prisma database URL (defaults to SQLite) |
| `NEXTAUTH_SECRET` | For auth | NextAuth.js secret |
| `NEXTAUTH_URL` | For auth | NextAuth.js base URL |
| `GITHUB_TOKEN` | For `sync:labels` | GitHub API token for label management |

---

## Roadmap

- [x] 66 specialist agents with 70 expert personas
- [x] 15-mentor advisory layer
- [x] Multi-provider LLM architecture (cloud, local, manual)
- [x] Hybrid mode — per-agent provider routing
- [x] Manual file-queue for API-less AI coders
- [x] 35+ PRD template library
- [x] 9-phase execution pipeline with quality gates
- [x] Web dashboard with session and agent browser
- [x] Agent skills system (10 orchestrator skills + 3 Claude Code native skills)
- [x] PR lifecycle tooling (create, review, merge)
- [x] Comprehensive CI/CD (pre-commit, labeler, dependabot)
- [x] LLM benchmarking & usage reporting
- [x] MCP server (40 tools) for AI coder integration (Claude Code, Cursor, Windsurf, Copilot)
- [x] Structured memory with TF-IDF + BM25 semantic search (9 tools)
- [x] YAML workflow engine with approval gates and resume tokens (8 tools)
- [x] Self-extending skill system with 8 curated external registries
- [x] Live agent dashboard with SSE streaming
- [ ] Slack/Discord bot interface
- [ ] Multi-product session management
- [ ] Agent output quality scoring with ML
- [ ] Visual pipeline editor (drag-and-drop phases)

---

## License

See [LICENSE](LICENSE) for details.

---

*Built to match how a real IT company is structured — not a toy 2-agent demo.*
