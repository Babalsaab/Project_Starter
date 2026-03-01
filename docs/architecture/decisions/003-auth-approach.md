# ADR-003: Authentication Approach

**Status**: Accepted
**Date**: 2026-02-28
**Authors**: Platform Team

## Context

The TaskFlow web app needs authentication supporting both credentials (username/password)
and OAuth providers, with role-based access control for the orchestrator API.

## Decision

Use NextAuth.js v5 (Auth.js) with:

- **Credentials provider** for username/password (hashed via NextAuth's internal crypto)
- **Session strategy**: JWT (stateless, no DB session table)
- **Role RBAC**: user roles stored on the User model in Prisma, propagated to JWT token
- **Auth config**: `auth.ts` at project root, used by both API routes and middleware

Security headers (CSP, HSTS, X-Frame-Options, etc.) are configured in `next.config.js`
`headers()` function — no separate helmet.js needed for Next.js.

Rate limiting is implemented in `src/middleware.ts` using a sliding-window in-memory counter
per IP address (200 requests/minute per IP for all `/api/*` routes).

## Consequences

**Positive**:

- Stateless JWT sessions scale horizontally without shared session storage
- NextAuth handles CSRF protection, secure cookie settings, and provider OAuth flows
- Security headers centralized in one place (`next.config.js`)

**Negative**:

- JWT tokens can't be revoked server-side without additional blocklist infrastructure
- In-memory rate limiting resets on process restart (acceptable for development; use Redis in production)
