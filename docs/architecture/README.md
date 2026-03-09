# Architecture Overview

This document describes the high-level architecture of the Vibecoded Orchestrator — a unified
multi-agent system structured as a real IT company, with a Next.js 15 web app (TaskFlow) bundled
in the same repository.

## System Components

```
┌──────────────────────────────────────────────────────────────────────┐
│                      Vibecoded Orchestrator                          │
│                                                                      │
│  ┌─────────────────┐   ┌──────────────────┐   ┌──────────────────┐  │
│  │  Next.js 15 App │   │  Orchestrator    │   │   MCP Server     │  │
│  │  (TaskFlow)     │◄──│  Engine (CLI)    │   │  (44 tools)      │  │
│  │  Port 1000      │   │  orchestrator/   │   │  mcp-server/     │  │
│  └────────┬────────┘   └────────┬─────────┘   └────────┬─────────┘  │
│           │                    │                       │            │
│           ▼                    ▼                       ▼            │
│  ┌─────────────────┐   ┌──────────────────┐   ┌──────────────────┐  │
│  │  Prisma ORM     │   │  74 Specialist   │   │  Memory Store    │  │
│  │  SQLite / PgSQL │   │  Agents (YAML)   │   │  TF-IDF Search   │  │
│  └─────────────────┘   └──────────────────┘   └──────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

## Key Layers

### 1. Web Application (`src/`)

- **Framework**: Next.js 15 with App Router, TypeScript, Tailwind CSS
- **Auth**: NextAuth.js v5 (credentials + OAuth providers)
- **Database**: Prisma ORM — SQLite for development, PostgreSQL for production
- **UI**: shadcn/ui component library with custom Tailwind theme

### 2. Orchestrator Engine (`orchestrator/`)

- **Entry**: `orchestrator/index.ts` — CLI discovery → PRD → agent config → execute flow
- **Executor**: `orchestrator/executor.ts` — phased execution engine (9 phases)
- **Feedback**: `orchestrator/agent-feedback.ts` — finding→agent mapping and performance tracking
- **CIL**: `orchestrator/cil-controller.ts` — Continuous Improvement Loop (N iterations)
- **Coders**: `orchestrator/coders/` — pluggable code-change backends (Claude API, Claude Code CLI)

### 3. Agent System (`agents/`)

- **Chiefs**: CEO, CMO, CTO, COO — coordinate specialist teams
- **Tech Pool** (`agents/pool/tech/`): 46 specialists (security, frontend, backend, DevOps, QA, etc.)
- **Marketing Pool** (`agents/pool/marketing/`): 28 specialists
- **Personas** (`agents/personas/`): 81 expert profiles enriching agent prompts
- **Mentors** (`config/mentors.yaml`): 30 world-class influences injected into agent reasoning

### 4. MCP Server (`mcp-server/`)

- 44 tools across 10 modules: agents, personas, mentors, skills, PRDs, sessions, memory,
  workflows, skill-discovery, CTO evaluation
- Transport: stdio (Claude Desktop / Claude Code compatible)
- Semantic search: BM25 + TF-IDF hybrid over 81 personas and structured memory

### 5. Services (`src/services/`)

Business logic decoupled from Next.js route handlers. See individual service files for details.

## Data Flow

```
User Request → Next.js API Route → src/services/ → Prisma → Database
                                ↓
                        Orchestrator Engine → Agent Pool → Claude API
                                ↓
                        Memory Store ← Findings ← CTO Evaluation
```

## Infrastructure

- **Development**: `npm run dev` — Next.js dev server on port 1000
- **Database**: `prisma/schema.prisma` — single schema for SQLite dev / PostgreSQL prod
- **CI/CD**: `.github/workflows/` — build, type-check, lint, test pipeline
- **Evaluation**: `tools/cto-evaluation/` — 495-parameter, 21-category codebase audit

## Architecture Decision Records (ADRs)

See [decisions/](./decisions/) for recorded architectural decisions:

- [ADR-001: Orchestrator Design](./decisions/001-orchestrator-design.md)
- [ADR-002: Database Strategy](./decisions/002-database-strategy.md)
- [ADR-003: Authentication Approach](./decisions/003-auth-approach.md)
- [ADR-004: Agent Communication Protocol](./decisions/004-agent-communication.md)
