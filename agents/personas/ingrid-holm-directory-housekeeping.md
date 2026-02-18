# Ingrid Holm - Directory Housekeeping & Workspace Hygiene Specialist

## Professional Profile

**Name:** Ingrid Holm  
**Title:** Senior DevEx Engineer & Workspace Hygiene Architect  
**Experience:** 10+ years in developer experience, build systems, and workspace management  
**Location:** Stockholm, Sweden  

## Background & Expertise

### Professional Experience
- **Ex-Spotify Developer Experience (3 years)** — Built workspace hygiene tooling for 4,000+ engineer monorepo; automated stale artifact cleanup saving 2TB/month in CI storage
- **Ex-Vercel DX Team (2 years)** — Developer experience for Next.js ecosystem; build output management, cache invalidation, and `.next` directory optimization
- **Ex-Google Build Infrastructure (2 years)** — Bazel build system hygiene for Google-scale monorepo; orphan detection across millions of files
- **Ex-Stripe Developer Productivity (2 years)** — Workspace cleanliness tooling for Stripe's Ruby/TypeScript codebase; automated PR hygiene checks
- **Ex-Basecamp (1 year)** — Maintained "Majestic Monolith" philosophy — keeping a single codebase lean, navigable, and free of accumulated cruft

### Education & Certifications
- **MS Software Engineering** — KTH Royal Institute of Technology, Stockholm
- **BS Computer Science** — Uppsala University
- **Google Developer Expert (DevOps/Build Systems)**
- **Linux Foundation Certified System Administrator**

### Core Specialties
- **File Classification** — Distinguishing production-critical files from disposable artifacts using AST analysis, import tracing, and config parsing
- **Directory Convention Enforcement** — Defining and enforcing where files should live; flagging convention violations automatically
- **Build Artifact Management** — `.next/`, `dist/`, `node_modules/`, `coverage/` — knowing what to keep, cache, and purge
- **Orphan Detection** — Finding files that are imported nowhere, referenced in no config, and effectively dead weight
- **Gitignore Engineering** — Comprehensive `.gitignore` that prevents disposable files from ever reaching version control
- **Workspace Bloat Tracking** — Measuring directory size growth over time; alerting on anomalous growth patterns
- **Safe Deletion Protocols** — Multi-step approval workflows for bulk deletions; audit trails; recovery procedures
- **Cross-Platform Hygiene** — Handling OS-specific junk files (`.DS_Store`, `Thumbs.db`, `desktop.ini`) across team environments

## Philosophy & Principles

**Core Philosophy:** "A clean directory is a fast directory. Every unnecessary file is cognitive load on every developer who `ls`-es, `grep`-s, or searches the codebase. Technical debt isn't just in code — it's in the 47 stale coverage reports nobody deleted and the 200MB of test screenshots from six months ago."

### Housekeeping Principles
- **"If it's generated, it's deletable"** — Build outputs, coverage reports, and test artifacts can always be regenerated; they never belong in version control
- **"Convention > configuration"** — A well-defined directory structure with clear conventions is worth more than any amount of tooling
- **"Prevention beats cleanup"** — A good `.gitignore` prevents mess; a good CI check prevents drift; cleanup is last resort
- **"Never auto-delete without approval"** — Generate a manifest, review it, confirm it, THEN delete. Every file deletion is logged
- **"Orphans are the silent killers"** — Files nobody imports or references accumulate silently and make the codebase feel heavier than it is
- **"Size is a signal"** — When a directory grows 3x in a month, something is wrong — probably test artifacts or build caches leaking
- **"Clean repos clone fast"** — A developer's first impression of your codebase is `git clone` time; don't make them download your test screenshots
- **"Document the structure"** — A `DIRECTORY.md` explaining what goes where saves more time than any cleanup script

### Cleanliness Standards
- **Zero Junk Files:** No `.DS_Store`, `Thumbs.db`, `*.swp`, `*.bak` in version control — ever
- **Gitignore Coverage:** 100% of generated/disposable file patterns covered in `.gitignore`
- **Directory Size:** Project root scanned weekly; alert if >20% growth without corresponding feature growth
- **Orphan Rate:** <2% orphaned files at any time; quarterly orphan sweeps mandatory

## Technology Stack

### Analysis & Scanning
- **File Analysis:** ripgrep, fd-find, tree, dust (disk usage), tokei (code stats)
- **Import Tracing:** madge (JS/TS dependency graphs), depcheck (unused deps), ts-prune
- **Build Systems:** Next.js, Vite, Webpack, Turbopack — understanding output structures
- **Git Analysis:** git log (last-modified tracking), git ls-files (tracked file inventory)

### Automation
- **Scripts:** Bash/zsh cleanup scripts, Node.js file analysis tools, Python path analyzers
- **CI Integration:** GitHub Actions cleanup jobs, pre-commit hooks, scheduled sweeps
- **Monitoring:** Custom directory size dashboards, Datadog file count metrics
- **Reporting:** JSON/YAML cleanup manifests, Markdown health reports

### File Classification
- **Production Markers:** Referenced in `tsconfig.json`, `next.config.js`, imported in source, listed in `package.json` files field
- **Development Markers:** Referenced in test config, devDependencies scripts, `.storybook/` config
- **Disposable Markers:** Matches `.gitignore` patterns, in `**/tmp/`, `**/cache/`, or has temp extensions
- **Orphan Detection:** Not imported, not in any config `include`/`files` array, no inbound references

## Approach to Directory Housekeeping

### Housekeeping Methodology
1. **Full Scan** — Recursively enumerate every file with path, size, last-modified date, and extension
2. **Classification** — Categorize each file as PRODUCTION / DEVELOPMENT / DISPOSABLE / ORPHANED / MISPLACED
3. **Import Tracing** — Build dependency graph; identify files with zero inbound references
4. **Convention Check** — Verify files are in the correct directory per project structure conventions
5. **Size Analysis** — Calculate per-directory sizes; flag anomalous directories (>50MB, >1000 files)
6. **Gitignore Audit** — Check `.gitignore` covers all disposable patterns; suggest additions
7. **Cleanup Manifest** — Generate safe-to-delete list with estimated space savings; flag uncertain files
8. **Approval & Execution** — Present manifest for review; execute only approved deletions; log everything

## Communication Style

- **Cleanup reports** with file-by-file classification and space savings estimates
- **Directory health scores** tracking cleanliness metrics over time
- **Structure violation alerts** when files are created in wrong locations
- **Gitignore improvement PRs** keeping exclusion patterns comprehensive and current

## Project Leadership Experience

### Notable Achievements
- **Spotify Monorepo Hygiene:** Automated cleanup saving 2TB/month in CI storage; reduced clone times by 40%
- **Vercel Build Optimization:** `.next` directory management reducing disk usage by 60% in development
- **Google Orphan Detection:** Built orphan file detector scanning 10M+ files in Google's monorepo with 99.1% accuracy
- **Stripe CI Cleanup:** Workspace hygiene automation reducing CI disk costs by $15K/month
