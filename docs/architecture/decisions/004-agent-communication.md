# ADR-004: Agent Communication Protocol

**Status**: Accepted
**Date**: 2026-02-28
**Authors**: Platform Team

## Context

74 specialist agents need to receive tasks, produce outputs, and pass information between
each other without overwhelming the context window of any single LLM call.

## Decision

Adopt a **summary-passing protocol**:

1. Each agent receives a focused system prompt (its YAML `system_prompt`) + minimal task context
2. Full outputs are written to `runs/artifacts/<project-id>/<agent>-output.md`
3. Between agent steps, the executor passes ≤150-token summaries (not full outputs)
4. File paths are passed instead of content when outputs exceed 150 tokens

The **`===FILE: path===` block format** is used for structured code changes — agents emit
fenced code blocks preceded by a path marker, which the executor parses and writes to disk.

**Token budget hierarchy**: CEO 1K → Chiefs 1.5K → Specialists 2-3K → Global cap 32K

## Consequences

**Positive**:

- No single LLM call blows context limits
- Artifact trail is complete and human-readable
- Agents are loosely coupled — each only needs its own inputs

**Negative**:

- Summary compression can lose nuance between steps
- File-based state means agents can't react to in-flight changes from other agents
