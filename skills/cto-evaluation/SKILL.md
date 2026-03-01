---
name: cto-evaluation
description: 'Use when performing comprehensive codebase evaluations, technical due diligence, engineering health assessments, or generating CTO-grade quality reports.'
version: '1.0.0'
compatible_agents:
  - technical_auditor
  - backend_engineer
  - security_engineer
  - devops_engineer
  - qa_engineer
  - cloud_security_engineer
  - compliance_engineer
  - web_frontend_engineer
domain: 'tech/'
priority: 16
user_invocable: true
argument-hint: '[mode: quick|standard|enhanced] [path]'
---

```skill
# CTO Codebase Evaluation Skill

Evaluate codebases across 495 parameters in 21 weighted categories. Apply this framework for technical due diligence, engineering health assessments, or quality gate enforcement.

## Category Weights (must sum to 100%)

| # | Category | Weight | Primary Agent | Script |
|---|----------|--------|---------------|--------|
| 1 | Security | 12% | security_engineer | 03-security.sh |
| 2 | Architecture | 10% | backend_engineer | 02-architecture.sh |
| 3 | Code Quality | 8% | qa_engineer | 01-code-quality.sh |
| 4 | Performance | 8% | frontend_performance_engineer | 04-performance.sh |
| 5 | Testing | 8% | test_automation_engineer | 05-testing.sh |
| 6 | Scalability | 8% | backend_engineer | 07-scalability.sh |
| 7 | Reliability | 8% | devops_engineer | 08-reliability.sh |
| 8 | DevOps | 6% | devops_engineer | 06-devops.sh |
| 9 | Data Architecture | 5% | database_engineer | 09-data.sh |
| 10 | API Design | 5% | api_designer | 10-api.sh |
| 11 | Backend | 5% | backend_engineer | 13-backend.sh |
| 12 | Maintainability | 5% | qa_engineer | 17-maintainability.sh |
| 13 | Frontend | 4% | web_frontend_engineer | 12-frontend.sh |
| 14 | Compliance | 4% | compliance_engineer | 18-compliance.sh |
| 15 | Observability | 4% | devops_engineer | 11-observability.sh |
| 16 | UI/UX Consistency | 4% | design_systems_engineer | 21-uiux-audit.sh |
| 17 | Documentation | 2% | technical_writer | 15-documentation.sh |
| 18 | Developer Experience | 2% | devops_engineer | 16-developer-experience.sh |
| 19 | Mobile | 2% | cross_platform_engineer | 14-mobile.sh |
| 20 | Cost Efficiency | 2% | cloud_security_engineer | 19-cost-efficiency.sh |
| 21 | Innovation | 2% | product_manager | 20-innovation.sh |

## Scoring Scale

| Grade | Score Range | Risk Level | Action |
|-------|-----------|------------|--------|
| A+ | 9.5 – 10.0 | Low | Maintain excellence |
| A | 9.0 – 9.49 | Low | Minor refinements |
| A- | 8.5 – 8.99 | Low | Targeted improvements |
| B+ | 8.0 – 8.49 | Low | Scheduled improvements |
| B | 7.5 – 7.99 | Medium | Planned remediation |
| B- | 7.0 – 7.49 | Medium | Active improvement needed |
| C+ | 6.5 – 6.99 | Medium | Significant gaps |
| C | 6.0 – 6.49 | Medium | Multiple issues |
| C- | 5.5 – 5.99 | High | Major concerns |
| D | 5.0 – 5.49 | High | Serious deficiencies |
| F | < 5.0 | Critical | Immediate intervention |

## Severity Classification

| Severity | Score Threshold | Required Action | Timeline |
|----------|----------------|-----------------|----------|
| Critical | < 3.0 | Immediate remediation required | This sprint |
| High | < 5.0 | Priority fix | Within 2 sprints |
| Medium | < 7.0 | Scheduled improvement | This quarter |
| Low | < 9.0 | Backlog item | Next quarter |

## Key Parameters per Category

### Security (12%) — 38 parameters
- [ ] OWASP Top 10 coverage (injection, XSS, SSRF, broken auth, etc.)
- [ ] Dependency vulnerability scanning (critical/high CVEs)
- [ ] Secret detection (API keys, passwords, tokens in code)
- [ ] Authentication strength (MFA, session management, token lifecycle)
- [ ] Authorization model (RBAC/ABAC, least privilege enforcement)
- [ ] Encryption at rest and in transit (AES-256, TLS 1.2+)
- [ ] Security headers (CSP, HSTS, X-Frame-Options)
- [ ] Input validation and output encoding

### Architecture (10%) — 26 parameters
- [ ] Separation of concerns (layered architecture)
- [ ] Circular dependency count (target: 0)
- [ ] Module coupling (low coupling, high cohesion)
- [ ] Design pattern usage (appropriate, not forced)
- [ ] API contract consistency
- [ ] Database schema design quality
- [ ] Error handling architecture

### Code Quality (8%) — 55 parameters
- [ ] Naming conventions consistency
- [ ] Cyclomatic complexity (< 15 per function)
- [ ] Code duplication (< 5%)
- [ ] File size limits (< 500 lines)
- [ ] Function size limits (< 50 lines)
- [ ] Type safety (no `any` types in TypeScript)
- [ ] Dead code detection
- [ ] Comment quality (meaningful, not redundant)

### Performance (8%) — 34 parameters
- [ ] Lighthouse scores (Performance > 90)
- [ ] Bundle size analysis
- [ ] N+1 query detection
- [ ] Caching strategy implementation
- [ ] Memory leak patterns
- [ ] Async/await best practices
- [ ] Image optimization

### Testing (8%) — 22 parameters
- [ ] Line coverage (target: > 80%)
- [ ] Branch coverage (target: > 75%)
- [ ] Test architecture (unit/integration/e2e pyramid)
- [ ] Mutation testing readiness
- [ ] Test isolation (no shared state)
- [ ] CI test execution speed

### Scalability (8%) — 18 parameters
- [ ] Statelessness of services
- [ ] Horizontal scaling readiness
- [ ] Connection pooling
- [ ] Queue-based async processing
- [ ] Database indexing strategy

### Reliability (8%) — 22 parameters
- [ ] Error handling coverage
- [ ] Circuit breaker patterns
- [ ] Retry policies with exponential backoff
- [ ] Graceful degradation
- [ ] Health check endpoints
- [ ] Disaster recovery readiness

### DevOps (6%) — 24 parameters
- [ ] CI/CD pipeline exists and passes
- [ ] Build reproducibility
- [ ] Infrastructure as Code coverage
- [ ] Container security (no root, minimal images)
- [ ] Environment parity (dev/staging/prod)
- [ ] Deployment automation

## Evaluation Modes

| Mode | Categories | Depth | Typical Duration |
|------|-----------|-------|-----------------|
| Quick | All 21 | Surface patterns only | 2-5 minutes |
| Standard | All 21 | Full automated analysis | 10-20 minutes |
| Enhanced | All 21 + deep compliance | Deep + manual patterns | 30-60 minutes |

## Evaluation Output Format

```

## CTO Codebase Evaluation Report

### Executive Summary

| Metric        | Value            |
| ------------- | ---------------- | ------ | ---- | --------- |
| Codebase      | `<path>`         |
| Date          | <timestamp>      |
| Overall Score | **X.XX / 10.00** |
| Grade         | **<grade>**      |
| Risk Level    | <Low             | Medium | High | Critical> |

### Category Scores

| Category | Weight | Score | Grade | Findings |
| -------- | ------ | ----- | ----- | -------- |
| Security | 12%    | X.X   | B+    | 5        |
| ...      | ...    | ...   | ...   | ...      |

### Findings Summary

- Critical: N
- High: N
- Medium: N
- Low: N

### Top Findings

| #   | Severity | Category | Description                 | Remediation               | Effort |
| --- | -------- | -------- | --------------------------- | ------------------------- | ------ |
| 1   | CRITICAL | Security | SQL injection in /api/users | Use parameterized queries | S      |

### Remediation Priority

1. [Immediate] Critical severity findings
2. [Short-term] High severity findings
3. [Medium-term] Medium severity findings
4. [Long-term] Low severity findings

### Trend Analysis (if previous evaluation exists)

| Category | Previous | Current | Change |
| -------- | -------- | ------- | ------ |
| Overall  | 6.5      | 7.2     | +0.7   |

````

## Cross-Category Correlation Patterns

When findings appear across multiple categories, identify root causes:

| Pattern | Categories Affected | Root Cause |
|---------|-------------------|------------|
| Low coverage + high incidents | Testing, Reliability | Engineering process immaturity |
| No CI/CD + manual deploys | DevOps, Reliability, Security | Missing automation foundation |
| Hardcoded secrets + no encryption | Security, Compliance | Missing secrets management |
| No monitoring + slow MTTR | Observability, Reliability | Operational blindness |
| Tight coupling + slow deploys | Architecture, DevOps, Scalability | Monolithic design debt |

## Running Evaluations

### Via MCP Tools
- `run_evaluation` — Execute evaluation against a codebase path
- `get_evaluation` — Retrieve latest results (summary, full, or category view)
- `list_evaluations` — View evaluation history with trend data
- `compare_evaluations` — Compare two runs for progress tracking

### Via CLI
```bash
npm run evaluate                    # Interactive folder picker
npm run evaluate:quick              # Quick scan of current directory
bash tools/cto-evaluation/evaluate /path/to/codebase
bash tools/cto-evaluation/evaluate /path/to/codebase --enhanced
````

### Via Workflow

Use the `cto-evaluation` workflow for multi-agent orchestrated evaluation with expert review and approval gates.

```

```
