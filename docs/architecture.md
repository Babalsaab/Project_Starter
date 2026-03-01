# Architecture

> See [docs/architecture/README.md](./architecture/README.md) for the full architecture overview.

## Quick Reference

- **Web App**: Next.js 15 App Router — `src/`
- **Orchestrator**: TypeScript CLI engine — `orchestrator/`
- **Agents**: 74 specialist YAML agents — `agents/pool/`
- **Services**: Business logic layer — `src/services/`
- **MCP Server**: 44-tool AI integration server — `mcp-server/`
- **Evaluation**: 495-parameter codebase audit — `tools/cto-evaluation/`

## Architecture Decisions

See [architecture/decisions/](./architecture/decisions/) for ADRs:

- [ADR-001](./architecture/decisions/001-orchestrator-design.md) — Orchestrator Design
- [ADR-002](./architecture/decisions/002-database-strategy.md) — Database Strategy
- [ADR-003](./architecture/decisions/003-auth-approach.md) — Authentication Approach
- [ADR-004](./architecture/decisions/004-agent-communication.md) — Agent Communication Protocol
