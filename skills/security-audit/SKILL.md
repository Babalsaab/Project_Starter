```skill
# Security Audit Skill

When reviewing code or infrastructure, apply this comprehensive security analysis:

## OWASP Top 10 Checks

1. **Injection** — SQL, NoSQL, OS command, LDAP injection via unsanitized input
2. **Broken Authentication** — Weak password policies, missing MFA, session fixation
3. **Sensitive Data Exposure** — Secrets in code, unencrypted data at rest/in transit
4. **XML External Entities (XXE)** — Unsafe XML parsing configurations
5. **Broken Access Control** — Missing authorization, IDOR, privilege escalation
6. **Security Misconfiguration** — Default credentials, verbose errors, open cloud storage
7. **Cross-Site Scripting (XSS)** — Reflected, stored, and DOM-based XSS vectors
8. **Insecure Deserialization** — Untrusted data deserialization without validation
9. **Using Components with Known Vulnerabilities** — Outdated dependencies
10. **Insufficient Logging & Monitoring** — Missing audit trails, no alerting

## Supply Chain Security

- Verify dependency integrity (lock files, checksums)
- Check for typosquatting in package names
- Audit transitive dependencies for known CVEs
- Verify GitHub Actions use pinned SHA versions, not tags

## Secret Detection

- Scan for API keys, tokens, passwords, private keys
- Check environment variable usage (never hardcoded)
- Verify `.gitignore` covers all secret files
- Check for secrets in CI/CD workflow files

## Infrastructure Review

- Docker: non-root user, minimal base image, no secrets in layers
- Network: TLS everywhere, CORS properly configured
- Database: parameterized queries, least privilege access
- Cloud: IAM roles scoped, no wildcard permissions

## Output Format

```
## Security Audit Report

### Risk Level: [CRITICAL | HIGH | MEDIUM | LOW]

### Findings
| # | Severity | Category | Description | File/Location | Remediation |
|---|----------|----------|-------------|---------------|-------------|
| 1 | HIGH     | Injection | ... | src/api/... | ... |

### Summary
- Critical: N
- High: N
- Medium: N
- Low: N
- Total: N

### Recommended Actions (Priority Order)
1. [Immediate] ...
2. [Short-term] ...
3. [Long-term] ...
```
```
