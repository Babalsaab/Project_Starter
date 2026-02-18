# Deployment Readiness Checklist Skill

When evaluating deployment readiness, apply this comprehensive checklist:

## Infrastructure
- [ ] All environment variables documented and set
- [ ] Database migrations tested on staging
- [ ] Backup/restore procedure verified
- [ ] SSL certificates valid and auto-renewing
- [ ] CDN configured for static assets
- [ ] DNS records prepared (A, CNAME, TXT for verification)

## Application
- [ ] All tests passing (unit, integration, e2e)
- [ ] No critical or high severity security vulnerabilities
- [ ] Performance benchmarks met (LCP < 2.5s, FID < 100ms, CLS < 0.1)
- [ ] Error monitoring configured (Sentry, LogRocket, etc.)
- [ ] Health check endpoints responding
- [ ] Rate limiting configured
- [ ] CORS properly configured for all environments

## Operability
- [ ] Logging structured and queryable
- [ ] Alerting configured for critical paths
- [ ] Runbook documented for common failure scenarios
- [ ] Rollback procedure tested
- [ ] On-call rotation established
- [ ] Incident response playbook ready

## Compliance & Legal
- [ ] Privacy policy updated
- [ ] Terms of service reviewed
- [ ] Cookie consent implemented (if applicable)
- [ ] GDPR/CCPA data handling verified
- [ ] Accessibility audit passed (WCAG 2.1 AA)

## Launch Communication
- [ ] Stakeholder notification list prepared
- [ ] Launch announcement drafted
- [ ] Support team briefed on new features
- [ ] Documentation updated

## Output Format
Produce a deployment readiness report with:
1. **Overall Grade**: READY / READY_WITH_RISKS / NOT_READY
2. **Blocking Issues**: Must fix before deploy
3. **Known Risks**: Accepted risks with mitigation plans
4. **Recommended Deploy Window**: Based on traffic patterns and team availability
