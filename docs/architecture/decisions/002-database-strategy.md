# ADR-002: Database Strategy

**Status**: Accepted
**Date**: 2026-02-28
**Authors**: Platform Team

## Context

We needed a database solution that works locally without Docker while being production-ready
for cloud deployment with minimal schema changes.

## Decision

Use Prisma ORM with a single `prisma/schema.prisma` that targets:

- **SQLite** in development (`DATABASE_URL="file:./prisma/dev.db"`)
- **PostgreSQL** in production (`DATABASE_URL=postgres://...`)

Prisma's provider-agnostic query API means zero code changes between environments.
Migrations are tracked in `prisma/migrations/`.

## Consequences

**Positive**:

- Zero-config local development — `npm install` is sufficient
- Type-safe queries via generated Prisma client
- Migration history tracked in version control

**Negative**:

- SQLite limitations (no concurrent writes) in development
- Must use `prisma migrate deploy` (not `dev`) in production CI/CD
