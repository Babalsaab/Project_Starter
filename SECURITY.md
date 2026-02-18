# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 2.x     | :white_check_mark: |
| 1.x     | :x:                |

## Reporting a Vulnerability

**Do NOT open a public issue for security vulnerabilities.**

Instead, please report security concerns via one of these channels:

1. **GitHub Security Advisories** — Use the "Report a vulnerability" button on the
   [Security tab](../../security/advisories) of this repository (preferred)
2. **Email** — Send details to the repository maintainers (see CODEOWNERS or package.json)

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Affected version(s)
- Potential impact assessment
- Suggested fix (if you have one)

### Response Timeline

| Action | Target |
|--------|--------|
| Acknowledge receipt | 48 hours |
| Initial assessment | 5 business days |
| Fix development | 14 business days |
| Security advisory published | With fix release |

## Security Practices

### Secrets Management

- **Environment variables only** — All secrets (API keys, database URLs, auth secrets)
  must be stored in `.env.local` (dev) or platform environment variables (prod)
- **Never commit secrets** — `.env*` files are gitignored; CI runs `detect-secrets` baseline checks
- **Rotate keys** — API keys should be rotated quarterly; revoke immediately if exposed

### Dependency Security

- `npm audit` runs on every CI build
- Dependabot monitors for vulnerable dependencies (see `.github/dependabot.yml`)
- Critical vulnerabilities must be patched within 7 days
- High severity within 30 days

### Code Security

- Input validation on all API route handlers
- YAML inputs are validated before processing (`scripts/validate-agents.ts`)
- File path sanitization to prevent directory traversal
- No `eval()`, `Function()`, or dynamic code execution from user input
- SQL injection prevention via Prisma ORM (parameterized queries)

### Authentication & Authorization

- NextAuth.js v5 handles authentication
- Session tokens are HTTP-only, secure, SameSite cookies
- API routes validate session before processing
- No sensitive data in client-side state or localStorage

### Agent System Security

- Agent YAML definitions are validated at load time
- Agent outputs are sandboxed to `runs/artifacts/<project-id>/`
- Token budgets prevent runaway API consumption
- Manual mode file queue uses strict path validation
- Inter-agent messages go through `AgentMessageBus` (no direct file sharing)

### CI/CD Security

- GitHub Actions use pinned action versions
- Secrets are never printed in CI logs
- Build artifacts are ephemeral (not persisted beyond the pipeline)
- Docker images use multi-stage builds with minimal attack surface

### Container Security (Docker)

- Base image: `node:18-alpine` (minimal surface area)
- Non-root user in production container
- No privileged mode
- Health checks enabled
- Resource limits recommended in `docker-compose.yml`

## Security-Related Configuration

| File | Purpose |
|------|---------|
| `.env.local` | Local development secrets (gitignored) |
| `.detect-secrets.cfg` | Secret detection configuration |
| `.secrets.baseline` | Known false positive secret patterns |
| `.github/dependabot.yml` | Automated dependency updates |
| `.husky/pre-commit` | Pre-commit safety checks |

## Disclosure Policy

We follow responsible disclosure. Security researchers who report valid
vulnerabilities will be acknowledged in the security advisory (unless they
prefer to remain anonymous). We do not pursue legal action against researchers
acting in good faith.
