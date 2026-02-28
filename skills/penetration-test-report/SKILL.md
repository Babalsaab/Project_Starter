---
name: penetration-test-report
description: "Use when writing or reviewing penetration test findings, structuring vulnerability reports, or preparing executive summaries for security assessments."
version: "1.0.0"
compatible_agents:
  - penetration_tester
  - security_engineer
  - cloud_security_engineer
  - soc_analyst
domain: "tech/security"
priority: 14
user_invocable: true
argument-hint: "[scope: web|network|cloud|api|mobile]"
---

```skill
# Penetration Test Report Skill

When writing or reviewing penetration test findings, apply this structured reporting framework:

## Finding Severity Classification (CVSS v3.1)

Score each finding using the full CVSS v3.1 vector:

| Metric | Values |
|--------|--------|
| Attack Vector (AV) | Network / Adjacent / Local / Physical |
| Attack Complexity (AC) | Low / High |
| Privileges Required (PR) | None / Low / High |
| User Interaction (UI) | None / Required |
| Scope (S) | Unchanged / Changed |
| Confidentiality (C) | None / Low / High |
| Integrity (I) | None / Low / High |
| Availability (A) | None / Low / High |

| Score Range | Severity |
|-------------|----------|
| 9.0 - 10.0 | Critical |
| 7.0 - 8.9 | High |
| 4.0 - 6.9 | Medium |
| 0.1 - 3.9 | Low |
| 0.0 | Informational |

## Finding Documentation Template

For each vulnerability discovered, document:

```
### Finding [#]: [Title]

**Severity:** [Critical|High|Medium|Low] (CVSS: X.X)
**CVSS Vector:** AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H
**CWE Reference:** CWE-XXX — [CWE Name]
**CVE Reference:** CVE-XXXX-XXXXX (if applicable)
**OWASP Category:** [OWASP Top 10 category]

**Affected System:** [URL/IP/service/component]

**Description:**
[Clear description of the vulnerability and its business impact]

**Reproduction Steps:**
1. [Step-by-step instructions to reproduce]
2. [Include specific payloads, requests, or tools used]
3. [Include screenshots or evidence]

**Proof of Concept:**
[Safe, non-destructive PoC code or demonstration]

**Business Impact:**
[What an attacker could achieve — data theft, privilege escalation, etc.]

**Remediation:**
[Specific fix with code examples where applicable]

**Verification Steps:**
[How to confirm the fix works]
```

## Executive Summary Format

The executive summary must be:
- Maximum 2 pages
- Written in business risk language (not technical jargon)
- Understandable by a non-technical executive in under 5 minutes

```
## Executive Summary

### Assessment Overview
- **Scope:** [Systems/applications tested]
- **Methodology:** [Black-box/White-box/Grey-box]
- **Testing Period:** [Start date — End date]
- **Rules of Engagement:** [Key constraints]

### Overall Risk Rating: [CRITICAL|HIGH|MEDIUM|LOW]

### Findings Summary
| Severity | Count |
|----------|-------|
| Critical | N |
| High | N |
| Medium | N |
| Low | N |
| Informational | N |

### Top 3 Business Risks
1. [Risk description in business terms with potential impact]
2. [Risk description in business terms with potential impact]
3. [Risk description in business terms with potential impact]

### Strategic Recommendations
1. [Immediate action required]
2. [Short-term improvement]
3. [Long-term security posture enhancement]
```

## Remediation Checklist

Prioritize remediation by CVSS score and exploitation likelihood:

```
## Remediation Checklist

### Immediate (within 48 hours)
- [ ] [Critical finding remediation with acceptance criteria]

### Short-term (within 2 weeks)
- [ ] [High finding remediation with acceptance criteria]

### Medium-term (within 30 days)
- [ ] [Medium finding remediation with acceptance criteria]

### Long-term (next quarter)
- [ ] [Low finding and architectural improvements]
```

## Retesting Procedure

After remediation is applied:
1. Re-execute the exact reproduction steps from each finding
2. Verify the original attack vector no longer works
3. Test for regression — verify the fix did not introduce new vulnerabilities
4. Test for bypass — attempt alternative exploitation of the same root cause
5. Document retesting results with pass/fail status for each finding

## Chained Vulnerability Assessment

Always check for vulnerability chaining:
- Can individually low-severity findings combine into higher impact?
- Does one finding enable exploitation of another?
- What is the maximum achievable impact through the full kill chain?

Document chained findings separately with the combined severity rating.
```
