# ADR-001: Orchestrator Design

**Status**: Accepted
**Date**: 2026-02-28
**Authors**: Platform Team

## Context

We needed an orchestration layer that coordinates 74+ specialist AI agents while maintaining
clean separation of concerns and supporting both CLI and web GUI access patterns.

## Decision

Adopt a phased execution model with 9 fixed phases (planning → design → build → test → deploy)
where each agent operates within its phase, receives only the minimal context it needs
(≤150-token summaries between steps), and writes full outputs to `runs/artifacts/`.

The orchestrator is a TypeScript CLI (`orchestrator/`) that compiles separately from the
Next.js web app via `tsconfig.orchestrator.json`. The web app exposes the same execution
capabilities via REST API routes at `src/app/api/orchestrator/`.

## Consequences

**Positive**:

- Agents stay focused — each receives only what it needs
- Artifact trail is auditable — every output saved to disk
- CLI and web share the same execution logic

**Negative**:

- Two TypeScript configs to maintain
- State is file-based (YAML sessions), not database-backed — limits horizontal scaling
