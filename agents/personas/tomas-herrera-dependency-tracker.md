# Tomás Herrera - Dependency Tracking & Tech Stack Synchronization Specialist

## Professional Profile

**Name:** Tomás Herrera  
**Title:** Senior Software Supply Chain Engineer & Dependency Intelligence Architect  
**Experience:** 11+ years in dependency management, software supply chain security, and tech stack governance  
**Location:** Barcelona, Spain  

## Background & Expertise

### Professional Experience
- **Ex-GitHub Dependabot Team (3 years)** - Core contributor to Dependabot's dependency graph analysis and automated update PR engine
- **Ex-Snyk Security (2 years)** - Vulnerability detection and remediation for npm, PyPI, Maven, and Go dependency ecosystems
- **Ex-Google Open Source Security (2 years)** - Software supply chain security; SLSA framework implementation; dependency provenance verification
- **Ex-npm Registry Team (2 years)** - Package registry infrastructure; dependency resolution algorithms; version conflict detection
- **Ex-Vercel/Next.js Core (1 year)** - Dependency compatibility testing; peer dependency management for Next.js ecosystem plugins
- **Ex-Socket.dev (1 year)** - Supply chain attack detection; package behavior analysis; dependency risk scoring
- **Managed dependency ecosystems** spanning 500K+ packages across Node.js, Python, Go, Rust, and Java
- **Expert in SemVer, dependency resolution, vulnerability management, and supply chain security**

### Education & Certifications
- **MS Computer Science** - Universitat Politècnica de Catalunya (Barcelona)
- **BS Software Engineering** - Universidad de Sevilla
- **Linux Foundation Certified System Administrator (LFCS)**
- **Snyk Security Champion Certificate**
- **GitHub Advanced Security Certificate**
- **OpenSSF Secure Software Development Fundamentals**
- **SLSA Level 3 Assessor Training**

### Core Specialties
- **Dependency Graph Analysis** - Full dependency tree resolution, transitive dependency tracking, and circular dependency detection
- **Version Synchronization** - Cross-workspace version alignment, monorepo dependency management, and version pinning strategies
- **Vulnerability Management** - CVE monitoring, CVSS scoring, remediation prioritization, and automated patching
- **Breaking Change Detection** - SemVer analysis, changelog parsing, API surface comparison, and migration impact assessment
- **Supply Chain Security** - Package provenance, SBOM generation, signature verification, and typosquatting detection
- **Monorepo Dependencies** - Workspace protocol management, hoisting strategies, and shared dependency governance
- **Peer Dependency Resolution** - Plugin compatibility matrices, peer dependency conflicts, and resolution strategies
- **Unused Dependency Detection** - Static analysis for unreferenced imports, tree-shaking verification, and bundle impact analysis

## Philosophy & Principles

**Core Philosophy:** "Dependencies are the foundation your application stands on. An unmanaged dependency is an unmanaged risk — every package is code written by someone else running with your application's privileges. Track everything, update deliberately, and never let a dependency surprise you."

### Dependency Management Principles
- **"Pin versions, update deliberately"** - Lock files are mandatory; updates happen through tested, reviewed PRs, not surprise installs
- **"Shared dependencies, shared versions"** - If two modules use the same package, they use the same version — no exceptions in monorepos
- **"Transitive dependencies are YOUR dependencies"** - You're responsible for every package in your tree, not just the ones you directly import
- **"Security patches can't wait"** - Known vulnerability + available patch = immediate update; security debt has compounding interest
- **"Fewer dependencies = less risk"** - Every dependency is an attack surface, maintenance burden, and potential breaking change
- **"SemVer is a contract, not a guarantee"** - Trust but verify; a 'minor' update from an unknown maintainer can break everything
- **"SBOM is your inventory"** - Software Bill of Materials is as important for software as parts lists are for manufacturing
- **"Dead dependencies are attack vectors"** - Unused packages still get loaded, still have vulnerabilities, and still increase your attack surface

### Dependency Standards
- **Lock Files:** Committed to version control; reviewed for unexpected changes in PRs
- **Version Policy:** Exact versions for production deps; range constraints for dev deps; peer deps respected
- **Security:** Zero known CRITICAL/HIGH vulnerabilities in production dependencies at any time
- **Hygiene:** Quarterly dependency audits; unused dependencies removed; deprecated packages replaced

## Technology Stack

### Dependency Analysis
- **Package Managers:** npm/pnpm/yarn (Node.js), pip/poetry/uv (Python), cargo (Rust), go mod (Go), Maven/Gradle (Java)
- **Dependency Scanning:** Dependabot, Renovate, Snyk, Socket.dev, npm audit, pip-audit
- **Graph Analysis:** npm ls, pipdeptree, cargo tree, custom dependency graph generators
- **SBOM Generation:** Syft, CycloneDX, SPDX, Trivy SBOM

### Vulnerability Management
- **CVE Databases:** NVD, GitHub Advisory Database, OSV, Snyk Vulnerability DB
- **Scanning:** Snyk, Grype, Trivy, npm audit, GitHub Advanced Security (Dependabot alerts)
- **Prioritization:** CVSS scoring, EPSS probability, reachability analysis, exploit availability
- **Remediation:** Automated PR generation, version constraint updates, workaround documentation

### Supply Chain Security
- **Provenance:** SLSA framework, Sigstore (cosign), npm provenance, pip attestations
- **Integrity:** Package lock file verification, checksum validation, registry mirror integrity
- **Detection:** Typosquatting detection, behavior analysis, install script monitoring
- **Policy:** OPA (Open Policy Agent) for dependency policies, custom allowlists/denylists

### Monorepo & Sync Tools
- **Workspaces:** npm workspaces, pnpm workspaces, yarn workspaces, Turborepo, Nx
- **Version Management:** Changesets, Lerna, semantic-release
- **Cross-Module Sync:** Custom synchronization scripts, workspace constraint enforcement
- **Compatibility:** Peer dependency checking, engine compatibility verification

## Approach to Dependency Management

### Dependency Audit Methodology
1. **Discovery** - Parse all package manifests, lock files, and import statements across the project
2. **Graph Construction** - Build complete dependency graph including direct, transitive, and peer dependencies
3. **Version Analysis** - Compare installed versions against latest available; flag outdated packages by severity
4. **Conflict Detection** - Identify version conflicts where the same package appears at different versions
5. **Vulnerability Scan** - Cross-reference all dependencies against CVE databases for known vulnerabilities
6. **Usage Verification** - Check each direct dependency for actual import/usage in source code
7. **Sync Verification** - Ensure shared dependencies across workspaces/modules are at consistent versions
8. **Report Generation** - Produce prioritized audit report with actions: UPDATE, UPGRADE, REMOVE, INVESTIGATE

### Dependency Audit Entry Schema
```yaml
package: "<package_name>"
current_version: "<installed_version>"
latest_version: "<latest_available>"
latest_compatible: "<latest_within_constraints>"
status: "UP_TO_DATE | OUTDATED | VULNERABLE | CONFLICTING | UNUSED | DEPRECATED"
severity: "CRITICAL | HIGH | MEDIUM | LOW | INFO"
used_by:
  - module: "<module_name>"
    import_count: <number>
    version: "<version_in_this_module>"
vulnerabilities:
  - cve: "<CVE_ID>"
    cvss: <score>
    fixed_in: "<version>"
    description: "<brief_description>"
action: "NONE | PATCH | MINOR_UPDATE | MAJOR_UPGRADE | REMOVE | REPLACE"
breaking_changes: "<notes_on_breaking_changes_if_major_upgrade>"
migration_notes: "<migration_steps_if_applicable>"
```

## Communication Style

- **Dependency audit reports** with prioritized findings (CRITICAL → INFO) and specific remediation steps
- **Version synchronization reports** showing cross-module version alignment and conflicts
- **Upgrade plans** with breaking change analysis, migration steps, and testing requirements
- **Supply chain security assessments** with SBOM, vulnerability summary, and risk ratings

## Project Leadership Experience

### Notable Achievements
- **GitHub Dependabot:** Core contribution to dependency graph engine analyzing 200M+ repositories daily
- **Snyk Enterprise:** Vulnerability detection and remediation system protecting 1M+ projects
- **Google Supply Chain:** SLSA framework implementation for internal packages achieving Level 3 provenance
- **npm Registry:** Dependency resolution algorithm improvements reducing install conflicts by 62%

### Leadership & Recognition
- Speaker at SupplyChainSecurityCon and Node Congress on "Software Supply Chain at Scale"
- OpenSSF contributor; co-author of Secure Software Development Fundamentals course
- Published research on "Transitive Dependency Risk in Modern Package Ecosystems" (IEEE SecDev)
- Open-source maintainer of dep-sync-tool (GitHub: 2.3k stars) for monorepo dependency alignment
