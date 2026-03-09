# 🎯 Vibecoded Orchestrator

> A unified multi-agent system structured like a real IT company — 74 specialist agents (46 tech + 28 marketing) coordinated by a CEO orchestrator, with CMO and CTO chiefs managing their respective teams, guided by a **Mentors Layer** of 30 world-class influences. Includes a comprehensive PRD generation system with 35+ templates, 81 expert personas, a CTO Codebase Evaluation Suite (495 parameters, 21 categories), cross-tool compatibility (7+ AI coding tools), multi-model provider support (Anthropic, OpenAI, Gemini, Bedrock), and a production-ready Next.js 15 web app (TaskFlow) — all in one project with a single `npm install`.

---

## What Is This?

Most "AI agent" setups use 1–2 skills. This repo gives you the equivalent of a **full IT company** — a CEO-level orchestrator routing work through a CMO/CTO hierarchy down to 74 dedicated specialists, each operating with deep domain expertise from 81 expert personas and guidance from 30 world-class mentors.

**Three ways to run it:**

| Mode | Command | LLM Source |
|------|---------|------------|
| **Cloud API** | `npm run orchestrator` | Anthropic Claude (failover across models) |
| **Multi-Model** | Configure `globals.yaml` | OpenAI, Gemini, Bedrock, Ollama, LM Studio |
| **Manual / AI Coder** | `npm run orchestrator -- manual <id>` | Copilot, Claude Code, Cursor, Antigravity — no API needed |
| **Hybrid** | `npm run orchestrator -- hybrid <id>` | Mix any of the above per agent |

**The flow:**
```
You give a project idea
  → Discovery Agent interviews you
  → Master PRD is generated (35+ template library)
  → Orchestrator selects the right agents (from 74 specialists)
  → Mentors inject quality principles at review gates
  → Agents execute in 9 phases and produce artifacts
  → Notifications sent to Slack/Discord/Telegram
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
- [CTO Evaluation Suite](#cto-evaluation-suite)
- [Cross-Tool Compatibility](#cross-tool-compatibility)
- [Environment Auto-Detection](#environment-auto-detection)
- [Notifications](#notifications)
- [MCP Server](#mcp-server)
- [TaskFlow Web App](#taskflow-web-app)
- [Scripts & Tooling](#scripts--tooling)
- [CI/CD & Quality Gates](#cicd--quality-gates)
- [Configuration](#configuration)
- [Token Optimisation](#token-optimisation)
- [Customisation](#customisation)
- [Documentation](#documentation)
- [Roadmap](#roadmap)

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/Babalsaab/Project_Starter.git
cd Project_Starter

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
3. **Agent Selection** — picks the right specialists from 74 agents
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
│   ├── env-detect.ts               # Auto-detect AI tool, project context, stack
│   ├── notifications.ts            # Slack/Discord/Telegram notifications
│   ├── coders/                      # Pluggable coder backends (Claude API, Claude Code, Cursor, Aider, Manual)
│   └── providers/                   # LLM provider abstraction
│       ├── base.ts                  # Universal LLMProvider interface
│       ├── anthropic.ts             # Anthropic Claude (cloud API, model failover)
│       ├── openai.ts                # OpenAI (GPT-4o, o1)
│       ├── gemini.ts                # Google Gemini (2.5-pro, 2.0-flash)
│       ├── bedrock.ts               # AWS Bedrock (Claude, Llama, Mistral via SigV4)
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
│   │   ├── tech/                    # 46 tech specialist agents (incl. 7 cybersecurity + 6 operations)
│   │   └── marketing/               # 28 marketing specialist agents
│   └── personas/                    # 81 expert persona docs (enrich agent prompts)
│
├── skills/                          # 14 reusable agent skills (injected at runtime)
│   ├── code-quality/                # Code review checklists & linting context
│   ├── security-audit/              # Security vulnerability assessment
│   ├── accessibility-check/         # WCAG compliance checks
│   ├── api-contract-validation/     # API contract verification
│   ├── deploy-checklist/            # Deployment readiness verification
│   ├── design-system-lint/          # Design system consistency
│   ├── performance-budget/          # Performance budget enforcement
│   ├── prd-analysis/                # PRD completeness & gap analysis
│   ├── pr-review/                   # Pull request review skill
│   ├── pr-lifecycle/                # Commit messages, changelogs, merge readiness
│   ├── penetration-test-report/     # Penetration testing report generation
│   ├── cloud-security-audit/        # Cloud infrastructure security review
│   ├── compliance-control-check/    # Regulatory compliance verification
│   ├── cto-evaluation/              # CTO-level codebase evaluation
│   └── external/                    # Skills installed from external registries
│
├── config/
│   ├── globals.yaml                 # Global brand, voice, token policies, provider config
│   ├── mentors.yaml                 # 30 world-class mentors layer
│   ├── orchestrator-schema.yaml     # Runtime execution schema
│   ├── registries/                  # Agent, MCP tool, and upstream sync registries
│   ├── project-sessions/            # Per-project session state
│   ├── workflows/                   # YAML workflow definitions
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
│   │   │   ├── agents/page.tsx      # Agent registry browser (all 74 agents + personas)
│   │   │   └── live/page.tsx        # Live agent dashboard — SSE streaming
│   │   └── api/                     # API routes
│   │       └── orchestrator/        # Sessions, artifacts, agents, events API
│   ├── components/                  # React components (auth, dashboard, layout, shadcn/ui)
│   ├── lib/                         # Prisma client, utilities, event emitter
│   └── styles/                      # Global styles
│
├── mcp-server/                      # MCP server (44 tools, stdio transport)
│   └── src/
│       ├── index.ts                 # Server entry point
│       ├── tools/                   # Tool modules (agents, personas, mentors, skills, PRD, sessions, memory, workflows, evaluation)
│       └── lib/                     # Shared loaders, TF-IDF, vector store, workflow engine
│
├── tools/
│   └── cto-evaluation/              # 495-parameter codebase evaluation engine
│       ├── scripts/                 # 21 category evaluation scripts + orchestration
│       └── config/                  # Evaluation weights, patterns, scoring thresholds
│
├── integrations/                    # Auto-generated agent files for 7 AI tools
│
├── scripts/                         # Developer tooling
│   ├── convert.sh                   # Convert agents to 7 tool formats
│   ├── install.sh                   # Interactive installer for AI tools
│   ├── lint-agents.sh               # Validate agent YAML structure
│   ├── validate-skills.sh           # Validate skills against agentskills.io spec
│   ├── sync-upstream.sh             # Sync skills from 4 upstream registries
│   ├── update.sh                    # User-facing update script with version checking
│   ├── validate-agents.ts           # Validate all agent YAML files
│   ├── generate-master-prd.ts       # Generate a master PRD
│   ├── generate-all-prds.ts         # Generate complete PRD suite (35+ docs)
│   └── ...                          # Benchmarking, usage reports, queue manager, etc.
│
├── runs/                            # Runtime outputs (gitignored)
│   ├── prds/                        # Generated Master PRDs
│   ├── artifacts/                   # Agent-produced outputs (per project)
│   ├── generated-prds/              # Full PRD suite outputs
│   ├── workflows/                   # Persisted workflow execution state
│   ├── queue/                       # Manual mode file-queue
│   └── logs/                        # Execution logs
│
├── memory/                          # Long-term curated project facts
│
├── prisma/                          # Database (SQLite dev / PostgreSQL prod)
│
├── .github/                         # CI/CD, issue templates, Copilot instructions
│
├── .claude/skills/                  # Native Claude Code skills (3 slash commands)
│
├── docs/                            # Guides, references & playbooks
│
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
npm run list-agents                               # List all 74 agents
npm run validate                                  # Validate all agent YAML files
npm run queue -- status                           # Manual queue status dashboard
npm run queue -- list                             # List all queue entries
npm run queue -- respond <step> <file>            # Submit a response to a queue step
npm run queue -- export                           # Export all pending as one .md doc

# ─── CTO Evaluation ────────────────────────────────────────────
npm run evaluate                                  # Run CTO codebase evaluation (interactive)
npm run evaluate:quick                            # Quick evaluation of current directory

# ─── Cross-Tool Compatibility ──────────────────────────────────
npm run convert                                   # Convert agents to all 7 tool formats
npm run convert:cursor                            # Convert for Cursor only
npm run convert:gemini                            # Convert for Gemini CLI only
npm run install:tools                             # Interactive installer for AI tools

# ─── LLM & Benchmarking ──────────────────────────────────────
npm run bench:model                               # Benchmark LLM providers/models
npm run usage:report                              # Token usage & cost reports
npm run check:llm                                 # Verify local LLM servers are running

# ─── PRD Generation ──────────────────────────────────────────
npm run generate:master-prd                       # Generate a master PRD
npm run generate:all-prds                         # Generate complete PRD suite (35+ docs)

# ─── Quality & Validation ──────────────────────────────────────
npm run lint:agents                               # Validate all 74 agent YAMLs
npm run lint:skills                               # Validate skills against agentskills.io spec
npm run check:loc                                 # Enforce max LOC per file
npm run commit                                    # Safe commit wrapper (blocks secrets)
npm run lint                                      # ESLint
npm run type-check                                # TypeScript type check

# ─── Auto-Update & Sync ────────────────────────────────────────
npm run sync:upstream                             # Sync skills from 4 upstream registries
npm run update                                    # Check for updates and apply
npm run update:check                              # Check for updates (dry run)

# ─── Database ────────────────────────────────────────────────
npm run db:push                                   # Push Prisma schema
npm run db:studio                                 # Open Prisma Studio GUI
npm run db:migrate                                # Run migrations
npm run db:seed                                   # Seed database

# ─── Testing ─────────────────────────────────────────────────
npm run test                                      # Jest unit tests
npm run test:e2e                                  # Playwright E2E tests
npm run test:coverage                             # Coverage report
```

---

## Agent System

### Hierarchy

```
MENTORS (30 world-class influences — advisory layer)
  └── CEO (Chief Orchestrator)
        ├── CTO ← Tech Domain (46 agents)
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
        │     ├── Cybersecurity (7 specialists)
        │     │   ├── penetration_tester       ├── cloud_security_engineer
        │     │   ├── devsecops_engineer       ├── soc_analyst
        │     │   ├── compliance_engineer      ├── iam_engineer
        │     │   └── ai_security_engineer
        │     ├── Release & Docs
        │     │   ├── release_engineer
        │     │   ├── technical_writer
        │     │   └── technical_auditor
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

Each phase has dependency tracking, quality gates, optional mentor reviews, and notifications.

---

## LLM Provider Architecture

The provider system abstracts away the LLM backend so agents can run on any model source:

```
┌──────────────────────────────────────────────────────────────────┐
│                      ProviderRegistry                             │
│  (factory, routing, retry, health checks, agent maps)             │
├────────────┬──────────────┬──────────────┬──────────────┬────────┤
│  Anthropic │   OpenAI     │   Gemini     │   Bedrock    │ Manual │
│  Provider  │   Provider   │   Provider   │   Provider   │ Prov.  │
├────────────┼──────────────┼──────────────┼──────────────┼────────┤
│ Claude     │ GPT-4o, o1   │ 2.5-pro      │ Claude,      │ File-  │
│ (Sonnet,   │              │ 2.0-flash    │ Llama,       │ queue  │
│  Haiku,    │              │              │ Mistral      │        │
│  Opus)     │              │              │ (via SigV4)  │        │
└────────────┴──────────────┴──────────────┴──────────────┴────────┘
```

### Provider Types

| Provider | Type | Use Case |
|----------|------|----------|
| **AnthropicProvider** | `anthropic` | Cloud Claude API with automatic model failover (Sonnet → Haiku) |
| **OpenAIProvider** | `openai` | OpenAI GPT-4o, o1 models |
| **GeminiProvider** | `gemini` | Google Gemini 2.5-pro, 2.0-flash |
| **BedrockProvider** | `bedrock` | AWS Bedrock (Claude, Llama, Mistral via SigV4 signing) |
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

  - id: "openai"
    name: "OpenAI"
    type: "openai"
    api_key_env: "OPENAI_API_KEY"
    enabled: false
    priority: 2

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

For developers using AI coders (GitHub Copilot, Claude Code, Cursor, Antigravity) or who want human-in-the-loop:

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

14 reusable capability modules injected into agents at runtime:

| Skill | Purpose |
|-------|---------|
| **code-quality** | Code review checklists, linting context, best practices |
| **security-audit** | Security vulnerability assessment |
| **accessibility-check** | WCAG compliance verification |
| **api-contract-validation** | API contract verification |
| **deploy-checklist** | Pre-deploy verification, environment checks |
| **design-system-lint** | Design system consistency enforcement |
| **performance-budget** | Performance budget enforcement |
| **prd-analysis** | PRD completeness scoring, gap detection |
| **pr-review** | PR review checklists (security, quality, architecture) |
| **pr-lifecycle** | Commit messages, changelogs, merge readiness |
| **penetration-test-report** | Penetration testing report generation |
| **cloud-security-audit** | Cloud infrastructure security review |
| **compliance-control-check** | Regulatory compliance verification |
| **cto-evaluation** | CTO-level codebase evaluation |

Add new skills by creating a directory under `skills/` with:
- `skill.json` — metadata, applicable agents, input/output spec
- `index.ts` — skill logic (context builder, output parser)

### Claude Code Native Skills

3 native Claude Code skills available as slash commands:

| Skill | Command | Description |
|-------|---------|-------------|
| Skill Builder | `/skill-builder` | Create and audit skills following best practices |
| Image Generation | `/image-gen` | Generate AI images via Kie.ai API |
| AntiGravity Creator | `/antigravity-skill-creator` | Create cross-platform skills |

---

## Mentors Layer

30 world-class influences shape agent decisions at review gates:

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
| + 15 more | Ancient Strategy to Modern AI | See `config/mentors.yaml` |

Mentors are defined in `config/mentors.yaml` and injected into agents via `influences_agents` mappings.

---

## Personas

81 expert personas provide deep domain expertise to agents. Each persona is a detailed markdown profile including:

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
| Kai Blackwell (Penetration Testing) | `penetration_tester` |
| Priya Mehta (Cloud Security) | `cloud_security_engineer` |
| Jordan Lee (DevSecOps) | `devsecops_engineer` |
| Alex Kim (DevOps) | `devops_engineer`, `release_engineer` |
| Jennifer Wu (QA) | `qa_engineer`, `test_automation_engineer` |
| Thomas Clark (Mobile) | `ios_engineer`, `android_engineer`, `cross_platform_engineer` |
| Maria Santos (Database) | `database_engineer` |
| Amara Osei (ML) | `ml_engineer` |

See `agents/personas/` for the full set of 81 persona documents.

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

## CTO Evaluation Suite

A comprehensive 495-parameter codebase evaluation engine across 21 categories:

```bash
npm run evaluate        # Interactive evaluation (standard mode)
npm run evaluate:quick  # Quick evaluation of current directory
```

Categories include: code quality, architecture, security, testing, documentation, performance, accessibility, API design, database, DevOps, error handling, and more.

Results include scores, trends, and actionable recommendations. Compare evaluations over time:

```bash
# Via MCP tools
run_evaluation    # Start evaluation
get_evaluation    # View results (summary, full, or per-category)
list_evaluations  # View history
compare_evaluations  # Compare two runs
```

---

## Cross-Tool Compatibility

Agents are auto-converted to work with 7+ AI coding tools:

```bash
npm run convert          # All formats
npm run convert:cursor   # Cursor only
npm run convert:gemini   # Gemini CLI only
npm run install:tools    # Interactive installer
```

Supported tools: Claude Code, Cursor, Aider, Windsurf, Copilot, Gemini CLI, AntiGravity.

Generated files are stored in `integrations/`.

---

## Environment Auto-Detection

On first run, the orchestrator automatically detects:

1. **Which AI coding tool** is running (Claude Code, Cursor, Aider, AntiGravity, Windsurf, Copilot, Gemini CLI, Augment, or generic terminal)
2. **Project context** — whether the orchestrator is standalone, cloned into an existing project, or part of a monorepo
3. **Tech stack** — languages, frameworks, package managers, test/CI presence

Detection uses environment variables, parent process inspection, and filesystem markers. Results are cached for 24 hours.

```typescript
// Auto-runs on orchestrator start
const env = await detectEnvironment({ autoConfig: true });
// env.tool → "claude-code" | "cursor" | "antigravity" | ...
// env.context → "standalone" | "cloned-into" | "monorepo-child"
// env.stack → { languages: [...], frameworks: [...], ... }
```

---

## Notifications

Pipeline events are sent to Slack, Discord, and/or Telegram:

```bash
# Set in .env.local
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T.../B.../...
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/.../...
TELEGRAM_BOT_TOKEN=123456:ABC-DEF...
TELEGRAM_CHAT_ID=-100...
```

Notification levels (set in `config/globals.yaml`):
| Level | What's sent |
|-------|------------|
| `all` | Every agent start/complete, phase transitions, quality gates |
| `phases` | Phase transitions, errors, quality gates, pipeline start/complete |
| `errors` | Errors and warnings only |
| `summary` | Pipeline start and complete only |

---

## MCP Server

44 tools available via MCP protocol for AI coder integration:

| Category | Tools | Description |
|----------|-------|-------------|
| **Agent System** | 4 | List, get, invoke, suggest agents |
| **Personas & Mentors** | 4 | Browse personas, mentors, apply mentor reviews |
| **Skills & Quality** | 4 | List/get skills, check applicability, create Claude skills |
| **PRD Templates** | 3 | Browse templates, generate PRD outlines |
| **Sessions & Pipelines** | 4 | Manage orchestrator sessions |
| **Structured Memory** | 9 | Read/write/search/update facts with semantic search |
| **Workflow Engine** | 8 | Define, run, approve YAML workflows |
| **Self-Extending Skills** | 4 | Discover and install from 8 external registries |
| **CTO Evaluation** | 4 | Run, view, compare codebase evaluations |

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
| `/orchestrator/agents` | Agent registry browser (all 74 agents + personas) |
| `/orchestrator/live` | Live agent dashboard — SSE streaming with Framer Motion |

### API Routes

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/orchestrator/sessions` | GET | List all sessions with progress |
| `/api/orchestrator/sessions/[id]` | GET/POST | Session details / trigger execution |
| `/api/orchestrator/artifacts/[id]` | GET | Artifact content by project |
| `/api/orchestrator/agents` | GET | Full agent registry |
| `/api/orchestrator/events` | GET (SSE) | Live agent activity streaming |

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
npm run lint:agents
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

### Token Usage Reports
```bash
npm run usage:report                     # Full report
npm run usage:report -- --session my-id  # Filter by session
npm run usage:report -- --days 7         # Last 7 days
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
| `release.yml` | Tags | Automated releases |
| `sync-upstream.yml` | Scheduled | Upstream skill sync |

### Dependabot

- **npm:** Weekly updates (grouped by ecosystem)
- **GitHub Actions:** Weekly updates
- **Docker:** Monthly updates
- Major version bumps ignored by default

---

## Configuration

### `config/globals.yaml`

Central configuration for brand, voice, token policies, providers, notifications, and env detection:

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

  notifications:
    enabled: true
    level: "phases"   # all | phases | errors | summary

  env_detection:
    enabled: true
    auto_configure: true
    cache_ttl_hours: 24
```

### `config/mentors.yaml`

30 mentor definitions with principles, quotes, and agent influence mappings.

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

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started-guide.md) | From scattered prompts to a professional production pipeline |
| [MCP Setup Guide](docs/MCP-SETUP-GUIDE.md) | Complete MCP server setup for Claude Code, Cursor, and other AI tools |
| [Architecture Overview](docs/architecture/README.md) | System architecture, ADRs, and design decisions |
| [PRD Generation Workflow](docs/prd-generation-workflow.md) | 3-part workflow for creating comprehensive PRDs |
| [Deployment Checklist](docs/DEPLOYMENT_CHECKLIST.md) | Pre-deployment validation checklist |
| [Setup Guide](docs/SETUP.md) | TaskFlow quick-start (< 5 minutes) |
| [Playwright Workflow](docs/playwright-workflow.md) | E2E testing + iterative UI design workflow |
| [Best Practices](docs/agent-orchestrator-best-practices.md) | 317+ best practice rules for agents and marketing |
| [Design Playbooks](docs/playbooks/) | shadcn/ui design workflows and component standards |

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | No* | Anthropic Claude API key (*not needed for manual/local mode) |
| `OPENAI_API_KEY` | No | OpenAI API key (enables GPT-4o, o1) |
| `GOOGLE_API_KEY` | No | Google Gemini API key |
| `AWS_ACCESS_KEY_ID` | No | AWS Bedrock access key |
| `AWS_SECRET_ACCESS_KEY` | No | AWS Bedrock secret key |
| `DATABASE_URL` | No | Prisma database URL (defaults to SQLite) |
| `NEXTAUTH_SECRET` | For auth | NextAuth.js secret |
| `NEXTAUTH_URL` | For auth | NextAuth.js base URL |
| `SLACK_WEBHOOK_URL` | No | Slack incoming webhook for notifications |
| `DISCORD_WEBHOOK_URL` | No | Discord webhook for notifications |
| `TELEGRAM_BOT_TOKEN` | No | Telegram Bot API token |
| `TELEGRAM_CHAT_ID` | No | Telegram chat ID for notifications |
| `GITHUB_TOKEN` | For `sync:labels` | GitHub API token for label management |

---

## Roadmap

- [x] 74 specialist agents (46 tech + 28 marketing) with 81 expert personas
- [x] 30-mentor advisory layer
- [x] Multi-provider LLM architecture (Anthropic, OpenAI, Gemini, Bedrock, local, manual)
- [x] Hybrid mode — per-agent provider routing
- [x] Manual file-queue for API-less AI coders
- [x] 35+ PRD template library
- [x] 9-phase execution pipeline with quality gates
- [x] Web dashboard with session, agent browser, and live streaming
- [x] 14 agent skills + 3 Claude Code native skills
- [x] PR lifecycle tooling (create, review, merge)
- [x] Comprehensive CI/CD (pre-commit, labeler, dependabot)
- [x] LLM benchmarking & usage reporting
- [x] MCP server (44 tools) for AI coder integration
- [x] Structured memory with TF-IDF + BM25 semantic search (9 tools)
- [x] YAML workflow engine with approval gates and resume tokens (8 tools)
- [x] Self-extending skill system with 8 curated external registries
- [x] CTO Evaluation Suite (495 parameters, 21 categories)
- [x] Cross-tool compatibility (7+ AI coding tools)
- [x] Environment auto-detection (AI tool, project context, stack)
- [x] Slack/Discord/Telegram notifications
- [x] 7 cybersecurity specialist agents
- [ ] Multi-product session management
- [ ] Agent output quality scoring with ML
- [ ] Visual pipeline editor (drag-and-drop phases)

---

## License

See [LICENSE](LICENSE) for details.

---

*Built to match how a real IT company is structured — not a toy 2-agent demo.*
