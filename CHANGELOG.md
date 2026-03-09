# Changelog

All notable changes to the Vibecoded Orchestrator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Provider abstraction layer** — Multi-LLM support via `orchestrator/providers/`
  - Anthropic (Claude API) provider
  - OpenAI-compatible provider (Ollama, LM Studio, vLLM, etc.)
  - Manual file-queue provider (for API-less AI coders: Copilot, Claude Code, Antigravity)
  - Provider registry with capability matching and per-agent overrides
- **Agent messaging bus** — Inter-agent communication with shared memory (`orchestrator/agent-messaging.ts`)
- **Dynamic skill system** — Per-agent skill modules in `skills/` directory
  - code-quality, prd-analysis, deploy-checklist, pr-review, pr-lifecycle
  - security-audit, accessibility-check, performance-budget, api-contract-validation, design-system-lint
- **Runtime configuration** — Typed config loader for `globals.yaml` (`orchestrator/runtime-config.ts`)
- **CLI subcommands** — `manual`, `hybrid`, `list`, `help` modes in orchestrator
- **CI/CD workflows** — docker-release, stale issues, install-smoke, workflow-sanity
- **Script tooling** — committer, validate-agents, check-ts-max-loc, bench-model, usage-report, check-local-llm, queue-manager, pr, sync-labels
- **Vitest + V8 coverage** — Unit test infrastructure with 58 tests across 3 suites
- **AGENTS.md** — Comprehensive instructions for AI coding agents
- **SECURITY.md** — Security policy with vulnerability disclosure process
- **CHANGELOG.md** — This file
- **Linting configs** — `.markdownlint-cli2.jsonc`, `.shellcheckrc`
- **detect-secrets** — Secret scanning configuration with baseline
- **Dependabot** — Automated dependency update monitoring
- **GitHub labeler** — Automatic PR labeling via path-based rules
- **Husky pre-commit hooks** — Validate agents, check LOC, type-check on commit
- **81 expert personas** — Domain expert enrichment for agent system prompts
- **30 world-class mentors** — Mentor layer guiding agent decisions
- **35+ PRD templates** — Core, specialized, and companion templates

### Changed
- **Executor v2.0** — Complete rewrite with provider integration, skill loading, messaging, retry logic
- **README.md** — Comprehensive rewrite covering full project scope
- **copilot.instructions.md** — Expanded with provider, skill, and testing guidance

## [1.0.0] — 2024-01-01

### Added
- Initial release with 74 specialist agents (46 tech + 28 marketing)
- CEO orchestrator with CMO/CTO/COO chiefs
- Discovery agent interview flow
- PRD generation pipeline
- Agent configurator and execution engine
- TaskFlow Next.js 15 web dashboard
- Orchestrator dashboard with session management
- Prisma database with SQLite (dev) / PostgreSQL (prod)
- NextAuth.js v5 authentication
- shadcn/ui component library integration
