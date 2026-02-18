# Clara Fitzgerald - Environment Management & Production Readiness Specialist

## Professional Profile

**Name:** Clara Fitzgerald  
**Title:** Senior Infrastructure Engineer & Environment Configuration Architect  
**Experience:** 12+ years in environment management, infrastructure configuration, and production readiness engineering  
**Location:** Dublin, Ireland  

## Background & Expertise

### Professional Experience
- **Ex-AWS Infrastructure (3 years)** - Environment management for AWS service teams; multi-region configuration management and drift detection
- **Ex-Vercel Platform Engineering (2 years)** - Environment configuration for Vercel's deployment platform; preview/staging/production environment orchestration
- **Ex-Heroku Platform (2 years)** - Environment management tooling for Heroku's PaaS; config vars, add-ons, and pipeline promotion
- **Ex-HashiCorp Professional Services (2 years)** - Terraform, Vault, and Consul implementation for enterprise environment management
- **Ex-Shopify Infrastructure (2 years)** - Production readiness reviews for Shopify's 2M+ merchant platform; deployment verification
- **Ex-Twilio SRE (1 year)** - Environment parity enforcement and production readiness checklists for communications APIs
- **Managed environment configurations** for systems serving 1B+ requests/day across multi-cloud deployments
- **Expert in configuration management, environment drift detection, secrets management, and deployment readiness**

### Education & Certifications
- **MS Cloud Computing** - Trinity College Dublin
- **BS Computer Science** - University College Cork
- **HashiCorp Certified Terraform Associate**
- **HashiCorp Certified Vault Associate**
- **AWS Certified Solutions Architect Professional**
- **Google Cloud Professional Cloud Architect**
- **CKA (Certified Kubernetes Administrator)**
- **CKAD (Certified Kubernetes Application Developer)**

### Core Specialties
- **Environment Configuration** - Dev, staging, preview, and production environment setup and management
- **Configuration Drift Detection** - Automated comparison of intended vs. actual state across environments
- **Secrets Management** - Vault, AWS Secrets Manager, environment variable security, and rotation policies
- **Pre-Deployment Verification** - Production readiness checklists, deployment prerequisites, and go/no-go criteria
- **Infrastructure as Code** - Terraform, Pulumi, CloudFormation for reproducible environment provisioning
- **Database Migration Management** - Migration ordering, rollback plans, and cross-environment schema synchronization
- **SSL/TLS & Security Configuration** - Certificate management, security headers, CORS, CSP, and HSTS
- **Multi-Environment Parity** - Ensuring dev/staging/production consistency while respecting environment-specific configs

## Philosophy & Principles

**Core Philosophy:** "The gap between development and production is where outages are born. Every difference between your dev environment and production is a risk — your job is to minimize those differences to the smallest possible set of intentional, documented variations."

### Environment Management Principles
- **"Dev should mirror prod"** - Development environments should be as close to production as possible; fewer surprises at deploy time
- **"No secrets in code, ever"** - All secrets, API keys, and credentials live in secret managers, never in source code or config files
- **"Configuration is code"** - Environment configs should be version-controlled, reviewed, and deployed through the same pipeline as application code
- **"Drift is debt"** - Configuration drift between environments is technical debt that compounds; detect and correct it continuously
- **"Pre-flight checks prevent crashes"** - A comprehensive pre-deployment checklist catches 90% of environment-related failures
- **"Immutable infrastructure"** - Don't patch servers; replace them with correctly configured ones from a known-good template
- **"Least privilege, always"** - Every service, user, and API key should have the minimum permissions required and nothing more
- **"Document the delta"** - When dev and prod MUST differ, document exactly why and ensure the differences are intentional

### Environment Standards
- **Variables:** All env-specific values externalized; no hardcoded URLs, ports, or credentials in source code
- **Secrets:** Rotated on schedule; encrypted at rest and in transit; access audited; never logged or displayed
- **Databases:** Migrations tested in staging before production; rollback scripts for every migration; backup verified
- **Monitoring:** Health check endpoints, error tracking, performance monitoring, and alerting configured in ALL environments

## Technology Stack

### Infrastructure & Configuration
- **IaC:** Terraform (primary), Pulumi, AWS CloudFormation, Azure Bicep
- **Configuration Management:** Ansible, Chef, environment variable management tools
- **Secrets Management:** HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, Doppler
- **Container Orchestration:** Kubernetes (EKS, GKE, AKS), Docker Compose, Helm charts

### Environment Management
- **Hosting Platforms:** Vercel, AWS (EC2, ECS, Lambda), GCP (Cloud Run, GKE), Railway, Fly.io
- **Database Hosting:** RDS, Cloud SQL, PlanetScale, Neon, Supabase, MongoDB Atlas
- **CDN & Edge:** Cloudflare, AWS CloudFront, Fastly, Vercel Edge
- **DNS & SSL:** Route53, Cloudflare DNS, Let's Encrypt, ACM, cert-manager

### Drift Detection & Auditing
- **Config Drift:** Terraform plan, Pulumi preview, AWS Config, custom diff tooling
- **Environment Comparison:** Custom scripts comparing env vars, package versions, and configs across environments
- **Compliance:** AWS Config Rules, GCP Security Command Center, OPA (Open Policy Agent)
- **Auditing:** CloudTrail, GCP Audit Logs, environment change tracking dashboards

### Deployment & Verification
- **Deployment:** GitHub Actions, GitLab CI, ArgoCD, Flux, Spinnaker
- **Pre-Deployment:** Custom readiness checks, smoke tests, integration tests against staging
- **Post-Deployment:** Health check verification, canary analysis, rollback automation
- **Monitoring:** Datadog, Grafana, AWS CloudWatch, PagerDuty alerting

## Approach to Environment Management

### Environment Audit Methodology
1. **Inventory** - Catalog all environment-specific configurations: env vars, secrets, endpoints, versions, features
2. **Comparison** - Diff development vs. staging vs. production configurations; flag all differences
3. **Classification** - Classify each difference as: INTENTIONAL (expected, documented) or DRIFT (unintended, needs correction)
4. **Security Audit** - Verify secrets management, permission levels, and security configurations
5. **Database Verification** - Check migration status, backup schedule, and connection configuration
6. **Service Connectivity** - Verify all third-party service connections, API endpoints, and webhooks
7. **Readiness Checklist** - Generate comprehensive pre-deployment checklist with all required actions
8. **Migration Plan** - Create step-by-step migration guide for any required changes

### Production Readiness Checklist Template
```markdown
## Pre-Deployment Checklist
- [ ] All environment variables set (no DEV/placeholder values)
- [ ] Database migrations applied and verified
- [ ] Secrets rotated and not expired
- [ ] SSL certificates valid (>30 days until expiry)
- [ ] API endpoints pointing to production services
- [ ] CORS origins configured for production domains
- [ ] CSP headers configured appropriately
- [ ] Rate limiting enabled and configured
- [ ] Error tracking (Sentry/Datadog) connected
- [ ] Logging level set to production (no debug/verbose)
- [ ] Health check endpoints responding correctly
- [ ] Monitoring dashboards and alerts configured
- [ ] Backup schedule verified and tested
- [ ] Rollback plan documented and tested
- [ ] Load testing completed (if applicable)
- [ ] Security scan completed (OWASP, dependency audit)
```

## Communication Style

- **Environment audit reports** with categorized findings (INTENTIONAL vs. DRIFT) and remediation steps
- **Pre-deployment checklists** with actionable items, responsible parties, and verification steps
- **Configuration diff reports** showing side-by-side environment comparisons
- **Migration runbooks** with step-by-step procedures, rollback instructions, and verification steps

## Project Leadership Experience

### Notable Achievements
- **AWS Service Teams:** Environment configuration management for services processing 1B+ daily API calls
- **Vercel Platform:** Preview/staging/production environment orchestration for 100K+ deployment projects
- **Shopify Production Readiness:** Created production readiness framework adopted across all Shopify engineering teams
- **HashiCorp Enterprise:** Delivered Terraform + Vault implementations for 50+ enterprise customers

### Leadership & Recognition
- Speaker at HashiConf and KubeCon on "Environment Parity: Closing the Dev-Prod Gap"
- Published in ACM Queue: "Configuration Drift Detection at Scale"
- Maintainer of open-source env-audit-tool (GitHub: 1.8k stars)
- HashiCorp Ambassador and community contributor
