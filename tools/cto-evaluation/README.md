# CTO Codebase Evaluation Suite

> **Comprehensive automated codebase evaluation framework with 495 parameters across 21 categories**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)]()

---

## Overview

This evaluation suite provides automated analysis of codebases from a CTO perspective, measuring code quality, architecture, security, performance, and 16 other critical dimensions.

### Key Features

- **495 evaluation parameters** across 21 categories
- **Automated scanning** using industry-standard tools
- **Weighted scoring system** reflecting real-world priorities
- **Comprehensive reporting** in Markdown, JSON, and HTML
- **UI/UX consistency checks** for design tokens, hardcoded colors/fonts, and inline styles
- **Hierarchical UI/UX audit** comparing global theme → pages → components → contrast
- **Language-agnostic** with specialized support for JavaScript/TypeScript, Python, Go, Java, and more
- **Cross-platform** support for macOS, Linux, and Windows
- **Results saved in your codebase** for easy tracking

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/cto-evaluation-suite.git
cd cto-evaluation-suite
```

### 2. Install Dependencies

#### macOS / Linux

```bash
# Run the installer (checks and installs dependencies)
./install.sh
```

#### Windows

```powershell
# Run PowerShell as Administrator
powershell -ExecutionPolicy Bypass -File install.ps1
```

### 3. Run Evaluation

#### Interactive Mode (Recommended)

Opens a folder picker to select your codebase:

```bash
# macOS / Linux
./evaluate

# Windows (PowerShell)
.\evaluate.ps1

# Windows (Command Prompt)
evaluate.bat
```

#### Direct Mode

Specify the codebase path directly:

```bash
# macOS / Linux
./evaluate /path/to/your/codebase

# Windows
.\evaluate.ps1 C:\path\to\your\codebase
```

### 4. View Results

Results are saved **inside your codebase folder**:

```
your-codebase/
├── .cto-evaluation/
│   └── evaluation_20260126_143022/
│       ├── report.md      ← Main report
│       ├── report.json    ← JSON data
│       ├── report.html    ← HTML report
│       └── *.json         ← Category details
└── ... your code ...
```

```bash
# View the report
cat /path/to/your/codebase/.cto-evaluation/evaluation_*/report.md
```

---

## Installation by Platform

### macOS

```bash
# Option 1: Use the installer (recommended)
./install.sh

# Option 2: Manual installation
brew install node jq git
npm install -g eslint jscpd madge
chmod +x evaluate scripts/*.sh
```

### Linux (Ubuntu/Debian)

```bash
# Option 1: Use the installer (recommended)
./install.sh

# Option 2: Manual installation
sudo apt-get update
sudo apt-get install -y nodejs npm jq git
npm install -g eslint jscpd madge
chmod +x evaluate scripts/*.sh
```

### Linux (Fedora/RHEL)

```bash
# Option 1: Use the installer (recommended)
./install.sh

# Option 2: Manual installation
sudo dnf install nodejs npm jq git
npm install -g eslint jscpd madge
chmod +x evaluate scripts/*.sh
```

### Windows

**Prerequisites:**

- [Git for Windows](https://git-scm.com/download/win) (includes Git Bash - **required**)
- [Node.js](https://nodejs.org/) (LTS version recommended)
- jq: Install via `choco install jq` or `winget install jqlang.jq`

```powershell
# Run the installer
powershell -ExecutionPolicy Bypass -File install.ps1

# Or install manually:
npm install -g eslint jscpd madge
```

**Running on Windows:**

```powershell
# PowerShell
.\evaluate.ps1 C:\path\to\codebase

# Command Prompt
evaluate.bat C:\path\to\codebase

# Interactive mode (opens folder picker)
.\evaluate.ps1
```

---

## Command Reference

### Evaluate Command Options

| Option               | Description                                 |
| -------------------- | ------------------------------------------- |
| `--quick`            | Run quick evaluation (faster, fewer checks) |
| `--skip-security`    | Skip security scanning                      |
| `--skip-performance` | Skip performance testing                    |
| `--verbose`          | Show detailed output                        |
| `--help`             | Show help message                           |

### Examples

```bash
# Full evaluation
./evaluate /path/to/codebase

# Quick evaluation (faster)
./evaluate /path/to/codebase --quick

# Skip security scans
./evaluate /path/to/codebase --skip-security

# Multiple options
./evaluate /path/to/codebase --quick --skip-performance --verbose
```

### Windows Examples

```powershell
# Full evaluation
.\evaluate.ps1 C:\Projects\my-app

# Quick evaluation
.\evaluate.ps1 C:\Projects\my-app -Quick

# Skip security
.\evaluate.ps1 C:\Projects\my-app -SkipSecurity
```

---

## Directory Structure

```
cto-evaluation-suite/
├── README.md                    # This file
├── config/
│   ├── evaluation.yaml          # Master configuration
│   └── thresholds.yaml          # Scoring thresholds
├── scripts/
│   ├── run-full-evaluation.sh   # Main orchestration script
│   ├── run-enhanced-evaluation.sh # Enhanced orchestration
│   ├── enhanced-evaluation.sh   # Enhanced scoring logic
│   ├── health-check.sh          # Dependency checks
│   ├── 01-code-quality.sh       # Code quality analysis
│   ├── 02-architecture.sh       # Architecture evaluation
│   ├── 03-security.sh           # Security scanning
│   ├── 04-performance.sh        # Performance analysis
│   ├── 05-testing.sh            # Test coverage analysis
│   ├── 06-devops.sh             # DevOps/CI-CD evaluation
│   ├── 07-scalability.sh        # Scalability checks
│   ├── 08-reliability.sh        # Reliability checks
│   ├── 09-data.sh               # Data architecture checks
│   ├── 10-api.sh                # API design checks
│   ├── 11-observability.sh      # Logging/monitoring checks
│   ├── 12-frontend.sh           # Frontend engineering checks
│   ├── 13-backend.sh            # Backend engineering checks
│   ├── 14-mobile.sh             # Mobile engineering checks
│   ├── 15-documentation.sh      # Documentation checks
│   ├── 16-developer-experience.sh # Developer experience checks
│   ├── 17-maintainability.sh    # Maintainability checks
│   ├── 18-compliance.sh         # Compliance checks
│   ├── 19-cost-efficiency.sh    # Cost efficiency checks
│   ├── 20-innovation.sh         # Innovation checks
│   ├── 21-uiux-audit.sh         # UI/UX hierarchical audit
│   ├── common-errors.sh         # Shared error helpers
│   ├── common-findings.sh       # Shared findings helpers
│   ├── common-progress.sh       # Shared progress helpers
│   ├── generate-report.sh       # Report generation
│   └── lib/                     # Script libraries
├── tools/
│   ├── eslint/                  # ESLint configurations
│   ├── security/                # Security tool configs
│   └── ...
├── templates/
│   └── report-template.md       # Report template
└── output/                      # Generated reports
```

---

## Categories & Weights

| Category             | Weight | Parameters | Description                                              |
| -------------------- | ------ | ---------- | -------------------------------------------------------- |
| Security             | 12%    | 82-119     | Authentication, data protection, OWASP Top 10            |
| Architecture         | 10%    | 56-81      | System design, patterns, modularity                      |
| Code Quality         | 8%     | 1-55       | Readability, SOLID principles, complexity, change safety |
| Performance          | 8%     | 120-153    | Algorithm efficiency, caching, optimization              |
| Scalability          | 8%     | 200-217    | Horizontal/vertical scaling readiness                    |
| Reliability          | 8%     | 218-239    | Error handling, fault tolerance, HA                      |
| Testing              | 8%     | 154-175    | Coverage, test quality, infrastructure                   |
| DevOps               | 6%     | 176-199    | CI/CD, containers, IaC                                   |
| Data Architecture    | 5%     | 240-259    | Schema design, migrations, operations                    |
| API Design           | 5%     | 260-281    | REST/GraphQL quality, documentation                      |
| Backend              | 5%     | 306-325    | Service implementation, real-time                        |
| Maintainability      | 5%     | 364-375    | Technical debt, code health                              |
| Frontend             | 4%     | 282-305    | Components, performance, accessibility                   |
| Compliance           | 4%     | 376-387    | GDPR, security standards                                 |
| Observability        | 4%     | 388-411    | Logging, metrics, tracing                                |
| UI/UX Consistency    | 4%     | 434-460    | Design system, visual regression, UX safety              |
| Documentation        | 2%     | 344-353    | Code docs, architecture docs                             |
| Developer Experience | 2%     | 354-363    | Setup, tooling, DX                                       |
| Mobile               | 2%     | 326-343    | Architecture, performance                                |
| Cost Efficiency      | 2%     | 412-421    | Resource optimization                                    |
| Innovation           | 2%     | 422-433    | Technology currency                                      |

---

## Scoring System

### Score Scale (1-10)

| Score    | Grade | Description                         |
| -------- | ----- | ----------------------------------- |
| 9.5-10.0 | A+    | World-class, industry-leading       |
| 9.0-9.4  | A     | Exceptional, exceeds best practices |
| 8.5-8.9  | A-    | Excellent, follows best practices   |
| 8.0-8.4  | B+    | Good, solid implementation          |
| 7.5-7.9  | B     | Above average, minor improvements   |
| 7.0-7.4  | B-    | Satisfactory, some attention needed |
| 6.5-6.9  | C+    | Adequate, notable gaps              |
| 6.0-6.4  | C     | Below average, multiple issues      |
| 5.5-5.9  | C-    | Poor, significant deficiencies      |
| 5.0-5.4  | D     | Critical, major issues              |
| < 5.0    | F     | Failing, fundamental problems       |

### Risk Levels

| Score Range | Risk Level |
| ----------- | ---------- |
| 8.0+        | Low        |
| 6.0-7.9     | Medium     |
| 4.0-5.9     | High       |
| < 4.0       | Critical   |

---

## Configuration

### evaluation.yaml

Customize category weights, tool settings, and output preferences:

```yaml
category_weights:
  security: 12
  architecture: 10
  code_quality: 8
  # ... adjust weights based on your priorities

tools:
  eslint:
    enabled: true
    config: './tools/eslint/.eslintrc.cto.json'

  snyk:
    enabled: true
    severity_threshold: 'medium'
```

### thresholds.yaml

Define scoring thresholds for each metric:

```yaml
code_quality:
  cyclomatic_complexity:
    metric: 'average_complexity'
    thresholds:
      10: { max: 5 }
      8: { max: 10 }
      6: { max: 15 }
      # ...
```

---

## Tool Integration

### Required Tools

The suite automatically detects and uses available tools:

| Tool      | Purpose                    | Installation            |
| --------- | -------------------------- | ----------------------- |
| ESLint    | JS/TS linting              | `npm install -g eslint` |
| jscpd     | Duplication detection      | `npm install -g jscpd`  |
| madge     | Dependency analysis        | `npm install -g madge`  |
| npm audit | Dependency vulnerabilities | Built into npm          |

### Optional Tools (Recommended)

| Tool       | Purpose                       | Installation                       |
| ---------- | ----------------------------- | ---------------------------------- |
| Snyk       | Security scanning             | `npm install -g snyk`              |
| Semgrep    | SAST                          | `pip install semgrep`              |
| Trivy      | Container/dependency scanning | [Install guide](https://trivy.dev) |
| TruffleHog | Secrets detection             | `pip install trufflehog`           |
| Lighthouse | Frontend performance          | `npm install -g lighthouse`        |

---

## Command Reference

### Main Script Options

```bash
./scripts/run-full-evaluation.sh <codebase-path> [options]

Options:
  --skip-security      Skip security scanning
  --skip-performance   Skip performance testing
  --quick              Run quick evaluation (subset)
  --output-dir DIR     Custom output directory
  --format FORMAT      Output format (json|markdown|html|all)
  --verbose            Verbose output
  --help               Show help
```

### Individual Category Scripts

Run specific category evaluations:

```bash
# Code quality only
./scripts/01-code-quality.sh /path/to/codebase output.json

# Security only
./scripts/03-security.sh /path/to/codebase output.json

# Testing only
./scripts/05-testing.sh /path/to/codebase output.json
```

---

## Sample Output

### Console Output

```
╔═══════════════════════════════════════════════════════════════════════╗
║              CTO CODEBASE EVALUATION FRAMEWORK v1.0                   ║
╚═══════════════════════════════════════════════════════════════════════╝

[INFO] Evaluating codebase: /path/to/project
[INFO] Results directory: ./output/evaluation_20260126_143022

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Code Quality Evaluation (Weight: 8%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[SUCCESS] Code Quality Score: 7.8/10

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Security Evaluation (Weight: 12%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[SUCCESS] Security Score: 6.5/10
[WARNING] 2 HIGH severity issues found!

...

╔═══════════════════════════════════════════════════════════════════════╗
║                    EVALUATION COMPLETE                                ║
╚═══════════════════════════════════════════════════════════════════════╝

Final Score: 7.2/10 (B)
Results saved to: ./output/evaluation_20260126_143022/report.md
```

### Report Excerpt

```markdown
## Executive Summary

| Metric             | Value           |
| ------------------ | --------------- |
| **Overall Score**  | **7.2 / 10.00** |
| **Grade**          | **B**           |
| **Technical Risk** | Medium          |

## Category Scores

| Category     | Score | Grade | Weight |
| ------------ | ----- | ----- | ------ |
| Code Quality | 7.8   | B+    | 8%     |
| Security     | 6.5   | C+    | 12%    |
| Testing      | 8.2   | A-    | 7%     |

| ...
```

---

## Extending the Suite

### Adding New Categories

1. Create a new script in `scripts/`:

```bash
#!/bin/bash
# scripts/XX-new-category.sh

CODEBASE_PATH="$1"
OUTPUT_FILE="$2"

RESULTS='{
    "category": "new_category",
    "score": 0,
    "findings": [],
    "metrics": {}
}'

# Add your evaluation logic here

echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
```

2. Add to `run-full-evaluation.sh`:

```bash
CATEGORIES="
    # ...
    XX-new-category.sh:New Category"
```

3. Add the weight in `config/evaluation.yaml` under `category_weights`:

```yaml
category_weights:
  # ...
  new_category: 5
```

4. Define thresholds in `config/thresholds.yaml`

### Custom Rules

Add custom Semgrep rules in `tools/security/semgrep-rules.yaml`:

```yaml
rules:
  - id: my-custom-rule
    pattern: $DANGEROUS_PATTERN
    message: Custom security issue
    severity: ERROR
```

---

## Troubleshooting

### Common Issues

**"jq: command not found"**

```bash
# macOS
brew install jq

# Ubuntu/Debian
apt-get install jq
```

**"ESLint not found"**

```bash
npm install -g eslint
```

**"Permission denied"**

```bash
chmod +x scripts/*.sh
```

**Slow evaluation on large codebases**

```bash
# Use quick mode
./scripts/run-full-evaluation.sh /path/to/codebase --quick
```

---

## Contributing

Contributions are welcome! Areas for improvement:

- Additional language support (Rust, C++, C#)
- More security rules
- Performance benchmarking integration
- IDE plugins

---

## License

MIT License - See LICENSE file for details.

---

## Related Documents

- [CTO Evaluation Framework](./cto-codebase-evaluation-framework.md) - The 495-parameter framework
- [Evaluation Methodology](./cto-evaluation-methodology.md) - Detailed evaluation techniques

---

_Built for engineering excellence._
