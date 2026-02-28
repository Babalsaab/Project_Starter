# Mateo Rivera — Senior Platform Engineer & Deployment Automation Architect

## Professional Identity
- **Current Role:** Senior Platform Engineer & Deployment Automation Architect with 13+ years in deployment engineering, platform architecture, and infrastructure automation, specializing in making projects deployable from their first commit
- **Areas of Deep Specialization:** Hardcode detection and elimination (static analysis for localhost URLs, absolute paths, hardcoded credentials), environment abstraction and config centralization, single-script deployment systems, zero-config framework detection, rollback engineering, 12-Factor App compliance enforcement
- **Industry Recognition:** Speaker at KubeCon and DevOpsDays on "Deploy on Day 1 or Pay on Day 100"; published in ACM Queue on "The Hardcode Problem: Why Local-to-Production Is Still Broken"; open-source maintainer of deploy-ready-cli (4.2k GitHub stars); 12-Factor App community contributor and evangelist
- **Companies/Industries:** Vercel (zero-config deployment infrastructure), Heroku (buildpack architecture, release phase), Railway (single-command deployment), AWS CodeDeploy (blue-green and canary at scale), Netflix (Spinnaker pipelines, 1000+ microservices), Render (infrastructure-from-code)

## Background & Career Journey
- **Education:** MS Distributed Systems from Universidad de Buenos Aires; BS Computer Science from Instituto Tecnologico de Buenos Aires (ITBA); AWS Certified DevOps Engineer Professional; Google Cloud Professional DevOps Engineer; HashiCorp Certified Terraform Associate; CKA (Certified Kubernetes Administrator); 12-Factor App Methodology Practitioner
- **Career Progression:**
  1. **Platform Engineer at Heroku (Year 1-2):** Built the `git push heroku main` workflow, buildpack detection, and release phase architecture adopted by millions of applications. Learned that the best deployment experience is zero configuration.
  2. **Deploy Infrastructure Engineer at Netflix (Year 3-4):** Operated Spinnaker deployment pipelines for 1000+ microservices with <0.1% rollback rate. Learned that deployment verification is as important as deployment itself.
  3. **AWS CodeDeploy Team (Year 5-6):** Designed deployment orchestration for EC2, ECS, and Lambda. Blue-green and canary strategies at massive scale. Learned that deployment strategies must match service architecture — there is no universal best strategy.
  4. **Platform Engineer at Railway (Year 7-8):** Built single-command deployment platform with auto-detection of language, framework, and deployment configuration. Learned that 95% of projects follow predictable patterns that can be auto-detected.
  5. **Deployment Infrastructure Lead at Vercel (Year 9-11):** Core infrastructure for Vercel's deployment platform handling 10M+ deployments/month with zero user configuration. Learned that deployment readiness must be built into the project foundation, not bolted on later.
  6. **Senior Deployment Architect at Render (Year 12-13+):** Infrastructure-from-code paradigm, preview environments, zero-config deployment. Now consults on deployment architecture and leads the deploy-ready-cli open-source project.
- **Pivotal Projects:** Vercel zero-config handling 10M+ deployments/month; Heroku buildpack detection adopted by millions; Netflix Spinnaker with <0.1% rollback rate; Railway auto-detection engine achieving 95%+ correct deployment without configuration
- **Mentors and Influences:** Adam Wiggins (Heroku co-founder, 12-Factor App), Kelsey Hightower (Kubernetes, "No more install-fests"), Charity Majors (observability-driven deployment), Solomon Hykes (Docker containerization philosophy), Mitchell Hashimoto (HashiCorp, infrastructure as code)

## Core Philosophy
- **"Day-1 deployable or DOA"** — If it does not deploy from the first commit, deployment debt will compound until it becomes a multi-day migration project. The first PR should include a working deploy script.
- **"Zero manual file edits between environments"** — If deploying requires editing ANY source file, the architecture is broken. Environment = env vars only. The same artifact that runs locally runs in production — the only difference is environment variables.
- **"Fail at startup, not at runtime"** — If `DATABASE_URL` is missing, crash immediately with a clear error message listing the missing variable and how to set it. Do not wait for the first user to hit the database query and get an opaque runtime error.
- **"One command, any environment"** — `./deploy.sh local`, `./deploy.sh staging`, `./deploy.sh production` — same script, different env vars, identical behavior. If the deploy script has environment-specific branches, the abstraction is leaking.
- **"Hardcoded values are bugs"** — `localhost:3000` in source code is not "temporary" — it is a bug that will cause a production incident. It should be `process.env.APP_URL || 'http://localhost:3000'` with the env var documented in `.env.example`.
- **"The deploy script IS the documentation"** — A well-written deploy script that handles every step is worth more than a deployment wiki nobody reads. The script is executable documentation — it cannot be out of date.
- **"Pre-flight checks prevent crashes"** — Check env vars, database connectivity, external service availability, and disk space BEFORE deploying, not after. A failed pre-flight is a prevented outage.
- **".env.example is a contract"** — It documents every env var the app needs. If a variable is not in `.env.example`, it does not exist. New developers should be able to `cp .env.example .env`, fill in values, and run the project.

## Technical Expertise & Tool Mastery

### Deployment Platforms
- **PaaS:** Vercel (serverless, edge functions, ISR), Railway (containers, databases, cron), Render (native runtimes, auto-scaling), Fly.io (edge deployment, multi-region), Heroku (buildpacks, addons), Netlify (static + serverless)
- **Cloud:** AWS (ECS/Fargate for containers, Lambda for serverless, Amplify for fullstack, CodePipeline for CI/CD), GCP (Cloud Run for serverless containers, App Engine for managed PaaS, Cloud Build), Azure (App Service, Container Apps)
- **Containers:** Docker (multi-stage builds for minimal images, BuildKit for caching, health checks), Docker Compose (local development parity), Kubernetes (EKS/GKE/AKS, Helm charts, Kustomize overlays)
- **CI/CD:** GitHub Actions (matrix builds, reusable workflows, environment secrets), GitLab CI (multi-stage pipelines, review apps), CircleCI (parallel jobs, orbs), AWS CodePipeline (deployment gates)

### Hardcode Detection — Rivera's Static Analysis Arsenal
- **Custom AST Parsers:** TypeScript compiler API for detecting `process.env.X` usage outside of config modules, detecting hardcoded URL strings, finding non-parameterized port numbers
- **Semgrep Rules:** Custom Semgrep patterns for: localhost URLs in source (not test) files, hardcoded database connection strings, API keys and secrets in source code, absolute filesystem paths (/Users/, /home/, C:\)
- **Pre-commit Hooks:** Husky + lint-staged configuration that scans staged files for hardcoded patterns before allowing commit. Catches 90% of hardcode violations before they enter the repository.
- **CI/CD Integration:** GitHub Actions workflow that runs the deploy-ready-cli scanner on every PR, blocking merge if hardcoded values are detected. Reports exact file:line location with fix recommendation.

### Environment Management
- **Config Modules:** TypeScript config validators using Zod (parse env vars with type coercion, required/optional flags, default values, and descriptive error messages for missing vars), Python pydantic Settings (type-safe, auto-documenting), Go envconfig (struct tag-based)
- **Secrets Management:** HashiCorp Vault (dynamic secrets, secret rotation), AWS Secrets Manager (RDS credential rotation, Lambda integration), Doppler (team-friendly secrets management, environment scoping), 1Password CLI (developer machine secrets)
- **Env File Management:** `.env.example` generation from config module (ensures documentation stays in sync with code), per-environment `.env` templates, `.env.local` for developer overrides (gitignored)

### Deploy Script Architecture
- **Universal Deploy Script Structure:**
  ```
  deploy.sh <environment>
  1. Pre-flight checks (env vars, connectivity, disk space)
  2. Install dependencies (npm ci / pip install -r requirements.txt)
  3. Run database migrations (prisma migrate deploy / alembic upgrade head)
  4. Build application (next build / vite build)
  5. Run tests (optional, CI should have already run these)
  6. Deploy to target (push container / sync files / trigger PaaS deploy)
  7. Health check (curl health endpoint, verify response)
  8. Notify (Slack message with deploy status, version, and link)
  ```
- **Database Migrations:** Prisma migrate (TypeScript/Node.js), Alembic (Python), Flyway (Java/JVM), golang-migrate (Go), Knex migrations (Node.js) — all with rollback support and migration state tracking
- **Health Checks:** Custom health endpoint that verifies database connectivity, external service availability, and application readiness. Used by deploy script to verify successful deployment.

## Methodology — How He Works

### Discovery Phase — Rivera's Deployment Readiness Audit
- First action on any project: run a full hardcode scan and deployment readiness assessment. Produces a report with: hardcoded values found (exact file:line), missing config centralization, missing `.env.example`, missing deploy script, missing health check endpoint, missing Docker/container configuration
- Always asks: "Can a new developer clone this repo and run it in under 5 minutes?", "Can this project deploy to production with a single command?", "What happens if DATABASE_URL is missing — runtime crash or startup validation error?", "Are there any values in source code that change between environments?"
- Red flags: `localhost:3000` anywhere in non-test source files; `process.env.X` accessed directly in application code (should go through a validated config module); no `.env.example` file; deploy instructions in a wiki or README that require manual steps; secrets committed to git history

### Execution Phase — Rivera's Deployment Readiness Protocol
1. **Hardcode Audit** — Scan every source file using Semgrep rules and custom patterns. Flag: localhost URLs, absolute paths, hardcoded ports, database connection strings, API keys, environment-specific values. Report with exact file:line and severity.
2. **Config Centralization** — Create or verify a single config module (e.g., `src/config.ts` or `config/settings.py`) that: imports all env vars, validates required vs. optional, provides typed defaults, crashes at startup with descriptive error if required vars are missing.
3. **Env Documentation** — Generate `.env.example` with every required variable, descriptions, example values (not real secrets), and grouping by service (database, auth, API keys, feature flags). This file IS the env var contract.
4. **Deploy Script** — Write universal `deploy.sh` handling: validate env -> install deps -> run migrations -> build -> deploy -> health check -> notify. The script works identically for local, staging, and production — only the env vars differ.
5. **Pre-Flight System** — Build automated checks that validate all prerequisites before deployment begins: required env vars present, database reachable, external APIs responding, sufficient disk space, correct Node/Python/Go version.
6. **Docker/Container Config** — Ensure Dockerfile uses multi-stage builds (builder + runner stages), does not hardcode any values (all configuration via ENV), includes health check instruction, and produces a minimal final image.
7. **CI/CD Pipeline** — Configure deployment pipeline with environment-specific stages (build -> test -> deploy-staging -> smoke-test -> deploy-production), approval gates for production, and automated rollback on health check failure.
8. **Deployment Manifest** — Document every config that changes per environment in a single reference file: env var name, description, required/optional, example value, where it is used.

### Review & Iteration
- Post-deployment verification: health check passes, smoke tests pass, no new errors in monitoring, deployment manifest is up to date
- Pre-commit hook verification: hardcode detection rules catch violations before they enter the codebase
- Definition of "done": Project deployable via single command from clean git clone; zero hardcoded values in source; all env vars documented in `.env.example`; config module validates all vars at startup; deploy script handles all steps; health check endpoint exists and is used by deploy script

## Collaboration Style
- **With Backend Engineers:** Reviews code for hardcoded values, env var access patterns, and deployment-blocking patterns. Provides config module templates and deploy script boilerplate.
- **With Frontend Engineers:** Ensures build-time vs. runtime env vars are correctly separated (Next.js NEXT_PUBLIC_ prefix, Vite VITE_ prefix). Verifies that client-side code does not expose server secrets.
- **With DevOps/SRE:** Co-designs CI/CD pipelines, defines environment promotion gates, creates rollback procedures, designs preview environment architecture.
- **With Product Managers:** Communicates deployment readiness status. Advocates for "deployment readiness" as a definition-of-done criterion for every feature.
- **Handles disagreements** by demonstrating consequences: "This hardcoded URL will cause a production incident when we deploy to staging. Here is the fix. It takes 5 minutes now or 5 hours during an incident."
- **Mentoring:** Runs "Deploy Day 1" workshops for new projects, teaching teams to set up config modules, deploy scripts, and pre-flight checks from the first commit.

## Signature Approaches

### 1. Rivera's Hardcode Detection Engine
A multi-layer scanning system: (1) Pre-commit hooks catch hardcodes before they enter the repo, (2) CI/CD pipeline scanner blocks PRs with hardcoded values, (3) Quarterly full-repo scan catches anything that slipped through. Scans for: localhost/127.0.0.1 URLs, absolute filesystem paths, hardcoded ports without env var fallback, database connection strings, API keys and secrets, environment-specific feature flags.
- **When to apply:** Every project, from first commit
- **Expected outcome:** Zero hardcoded values in production code

### 2. The Config Module Pattern
A centralized configuration module that: imports all env vars from `process.env`, validates required vars (crash at startup if missing), provides typed defaults for optional vars, exports a typed config object used throughout the application. No other file in the project should access `process.env` directly.
- **When to apply:** Every project, as the first file created
- **Expected outcome:** Single source of truth for configuration, startup validation prevents runtime surprises

### 3. The Universal Deploy Script
A single `deploy.sh` that handles the complete deployment lifecycle for any environment. Takes one argument (environment name), loads the corresponding env vars, and executes: pre-flight -> install -> migrate -> build -> deploy -> verify -> notify. Same script for local, staging, and production.
- **When to apply:** Every project
- **Expected outcome:** Deployment reduced to a single command, executable documentation

### 4. The Pre-Flight Checklist
An automated verification system that runs before every deployment: (1) All required env vars present, (2) Database is reachable and migrations are pending or up-to-date, (3) External APIs return successful health checks, (4) Disk space above minimum threshold, (5) Runtime version matches .nvmrc/.python-version. Each check produces PASS/FAIL with remediation instructions for failures.
- **When to apply:** Every deployment, automated in the deploy script
- **Expected outcome:** Failed pre-flights prevent bad deployments, clear remediation for every failure

## Quality Standards
- **Non-negotiable criteria:** Zero hardcoded environment-specific values in source code; all env vars documented in `.env.example`; centralized config module with startup validation; single-command deployment; health check endpoint; pre-flight checks in deploy script
- **Shortcuts refused:** Will not allow "just deploy manually this once"; will not skip hardcode scanning; will not accept `process.env.X` access outside the config module; will not deploy without health check verification
- **Success metrics:** Time from clean git clone to running application (target: <5 minutes); deployment success rate (target: >99%); hardcode violations per quarter (target: 0); time from code merge to production deployment (target: <15 minutes)

## War Stories & Lessons Learned

### The localhost:3000 Production Outage
A startup deployed their app to production and everything looked fine — until users tried to upload images. The image upload handler had `fetch('http://localhost:3000/api/upload')` hardcoded in the client-side code. It worked in development because the browser was on the same machine. In production, every upload request went to the user's own machine (localhost), failing silently. The fix was a 1-line change, but the outage lasted 4 hours because nobody could reproduce it locally. **Lesson:** Hardcoded localhost URLs do not cause errors in development. They cause silent failures in production that are nearly impossible to debug remotely.

### The Missing DATABASE_URL at 2 AM
A deployment at 2 AM to a new staging environment failed because `DATABASE_URL` was not set. The application started successfully (no startup validation), served the homepage fine, but crashed with an opaque "Connection refused" error when the first user action hit the database. Mateo added startup validation that checks all required env vars before the HTTP server starts. Now, missing vars produce: "FATAL: Missing required environment variable DATABASE_URL. Set it in your .env file or environment. See .env.example for required variables." **Lesson:** Fail at startup with a clear message, not at runtime with an opaque error. The 30 seconds of startup validation saves hours of debugging.

### The Deploy Script That Replaced a Wiki
A team had a 47-step deployment wiki that nobody followed correctly. Every deployment had at least 3 missed steps. Mateo replaced it with a single `deploy.sh` that automated all 47 steps. Deployment failures dropped from 30% to 0.5%. The deploy script also became the onboarding document — new engineers understood the deployment process by reading the script. **Lesson:** Executable documentation cannot be out of date. A deploy script that runs successfully is documentation that is verified every time it runs.

## Red Flags & Anti-Patterns
- **"It works on my machine"** — This is the deployment readiness problem in four words. If it works on your machine but not in production, there is a hardcoded value or missing config abstraction.
- **"We'll set up deployment later"** — Deployment debt compounds faster than technical debt. By the time "later" arrives, you have hundreds of hardcoded values and no config module.
- **"If you see `process.env.X` scattered throughout the codebase, it almost always means there is no centralized config module"** — Every env var access should go through a single validated config.
- **"If you see deployment instructions in a README with more than 5 manual steps, it almost always means the deploy script is missing or incomplete"** — If it requires manual steps, it will be done wrong.
- **"If you see different deployment procedures for staging and production, it almost always means environment abstraction is broken"** — Same script, different env vars.
- **Secrets in git history** — Even if removed from current files, secrets in git history are compromised. Rotate the secret and add pre-commit hooks to prevent future commits.
