# Architecture Documentation

## Overview

The CTO Codebase Evaluation Suite is a comprehensive static analysis and code quality assessment framework designed to evaluate codebases across 21 categories with 495 parameters.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CTO Evaluation Suite                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐    ┌─────────────────────┐    ┌──────────────────┐   │
│  │   Entry     │    │   Orchestration     │    │    Reporting     │   │
│  │   Points    │───▶│      Layer          │───▶│      Layer       │   │
│  │             │    │                     │    │                  │   │
│  │ • evaluate  │    │ • run-full-         │    │ • generate-      │   │
│  │ • evaluate. │    │   evaluation.sh     │    │   report.sh      │   │
│  │   bat/ps1   │    │ • common-progress.sh│    │ • Templates      │   │
│  └─────────────┘    └─────────────────────┘    └──────────────────┘   │
│                              │                                         │
│                              ▼                                         │
│  ┌──────────────────────────────────────────────────────────────┐     │
│  │                 Shared Utilities Layer                        │     │
│  ├──────────────────────────────────────────────────────────────┤     │
│  │ • lib/math-utils.sh     (cross-platform math, replaces bc)  │     │
│  │ • lib/config-reader.sh  (single source of truth for weights)│     │
│  │ • lib/banner.sh         (shared ASCII banner)               │     │
│  │ • common-findings.sh    (JSONL-based findings accumulator)  │     │
│  │ • common-errors.sh      (error handling, timeouts, retries) │     │
│  │ • common-progress.sh    (progress indicators)               │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                              │                                         │
│                              ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │              Evaluation Scripts (21, run in parallel)            │  │
│  ├─────────────────────────────────────────────────────────────────┤  │
│  │ 01-code-quality   │ 06-devops      │ 11-observability │ 16-dx   │  │
│  │ 02-architecture   │ 07-scalability │ 12-frontend      │ 17-maint│  │
│  │ 03-security       │ 08-reliability │ 13-backend       │ 18-compl│  │
│  │ 04-performance    │ 09-data        │ 14-mobile        │ 19-cost │  │
│  │ 05-testing        │ 10-api         │ 15-documentation │ 20-innov│  │
│  │                 │                │ 21-uiux-audit    │         │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                              │                                         │
│                              ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                    External Tools Layer                          │  │
│  ├─────────────────────────────────────────────────────────────────┤  │
│  │ • ESLint (JavaScript/TypeScript)   • Semgrep (Security SAST)   │  │
│  │ • cloc (Lines of Code)             • Git (Version Control)      │  │
│  │ • Lighthouse (Web Performance)     • Docker (Containerization)  │  │
│  │ • SonarQube (Optional)             • Python tools               │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
cto-evaluation-suite/
├── evaluate                    # Main entry point (Unix)
├── evaluate.bat                # Windows batch entry point
├── evaluate.ps1                # PowerShell entry point
├── install.sh                  # Unix installation script
├── install.ps1                 # Windows installation script
│
├── config/                     # Configuration files
│   ├── evaluation.yaml         # Evaluation settings & weights
│   └── thresholds.yaml         # Scoring thresholds & grading
│
├── scripts/                    # Evaluation scripts
│   ├── run-full-evaluation.sh  # Master orchestration
│   ├── generate-report.sh      # Report generation
│   ├── common-progress.sh      # Shared progress utilities
│   ├── common-findings.sh      # Shared finding utilities (JSONL-based)
│   ├── common-errors.sh        # Error handling, timeouts, retries
│   ├── 01-21-*.sh              # Category-specific evaluators (21 total)
│   └── lib/                    # Shared utility libraries
│       ├── math-utils.sh       # Cross-platform math (awk, no bc)
│       ├── config-reader.sh    # Weight config single source of truth
│       ├── banner.sh           # Shared ASCII banner
│       ├── analyzer.sh         # Advanced codebase analyzer
│       └── *.sh                # Other analyzer modules
│
├── templates/                  # Report templates
│   └── report-template.md      # Markdown report template
│
├── tools/                      # External tool configurations
│   ├── docker/                 # Docker configurations
│   ├── eslint/                 # ESLint configurations
│   ├── lighthouse/             # Lighthouse configurations
│   ├── python/                 # Python tool configurations
│   ├── security/               # Security scanning rules
│   └── sonarqube/              # SonarQube configurations
│
├── docs/                       # Documentation
│   └── ARCHITECTURE.md         # This file
│
└── output/                     # Default output directory
```

## Component Details

### Entry Points

| File           | Platform           | Purpose                                            |
| -------------- | ------------------ | -------------------------------------------------- |
| `evaluate`     | Unix/macOS         | Main entry point with interactive folder selection |
| `evaluate.bat` | Windows CMD        | Windows batch wrapper                              |
| `evaluate.ps1` | Windows PowerShell | PowerShell wrapper with enhanced features          |

### Orchestration Layer

**`scripts/run-full-evaluation.sh`**

- Master script that coordinates all 21 evaluation categories
- Handles dependency checking and environment setup
- **Parallel execution** with configurable throttle (`CTO_MAX_PARALLEL`, default 4)
- Category weights loaded at runtime from `config/evaluation.yaml` via `config-reader.sh`
- Collects and aggregates results from all categories

**Shared Utilities**

- `common-progress.sh` -- Progress display and timing functions
- `common-findings.sh` -- JSONL-based findings accumulator (O(1) appends, cross-subshell safe)
- `common-errors.sh` -- Error handling, timeouts, retries, and cleanup traps
- `lib/math-utils.sh` -- Cross-platform math using `awk` (replaces `bc` for Windows Git Bash compatibility)
- `lib/config-reader.sh` -- Single source of truth for category weights, reads from `config/evaluation.yaml`
- `lib/banner.sh` -- Shared ASCII banner (deduplicated from entry points)

### Evaluation Categories

Each category evaluator follows a standard structure:

```bash
#!/bin/bash
# Category initialization
source "$SCRIPT_DIR/common-progress.sh"

# Result JSON structure
RESULTS='{
    "category": "<category_name>",
    "parameters_evaluated": 0,
    "parameters_total": N,
    "score": 0,
    "findings": [],
    "metrics": {}
}'

# Evaluation functions
evaluate_aspect_1() { ... }
evaluate_aspect_2() { ... }

# Main execution
main() {
    evaluate_aspect_1
    evaluate_aspect_2
    calculate_score
    output_results
}
```

### Scoring System

```
Category Score = Σ(subscore × weight) / Σ(weights)

Final Score = Σ(category_score × category_weight) / 100

Grade Mapping:
  A+: 9.5-10.0  │  A: 9.0-9.4  │  A-: 8.5-8.9
  B+: 8.0-8.4   │  B: 7.5-7.9  │  B-: 7.0-7.4
  C+: 6.5-6.9   │  C: 6.0-6.4  │  C-: 5.5-5.9
  D+: 5.0-5.4   │  D: 4.5-4.9  │  D-: 4.0-4.4
  F:  < 4.0
```

## Data Flow

```
                    ┌──────────────┐
                    │   Codebase   │
                    │   (Input)    │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   evaluate   │
                    │   (Entry)    │
                    └──────┬───────┘
                           │
                           ▼
              ┌────────────────────────┐
              │  run-full-evaluation   │
              │    (Orchestrator)      │
              └───────────┬────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │ Script 1 │   │ Script 2 │   │ Script N │
    │ (JSON)   │   │ (JSON)   │   │ (JSON)   │
    └────┬─────┘   └────┬─────┘   └────┬─────┘
         │              │              │
         └──────────────┼──────────────┘
                        │
                        ▼
              ┌────────────────────┐
              │  generate-report   │
              │  (Aggregation)     │
              └─────────┬──────────┘
                        │
            ┌───────────┼───────────┐
            │           │           │
            ▼           ▼           ▼
       ┌────────┐  ┌────────┐  ┌────────┐
       │ JSON   │  │ Markdown│ │  HTML  │
       │ Report │  │ Report  │ │ Report │
       └────────┘  └────────┘  └────────┘
```

## Extension Points

### Adding a New Evaluation Category

1. Create script: `scripts/NN-category-name.sh`
2. Follow the standard template structure
3. Register in `config/evaluation.yaml` with weight
4. Add thresholds to `config/thresholds.yaml`
5. Update report template if needed

### Adding Custom Rules

**ESLint Rules:**

- Add to `tools/eslint/.eslintrc.cto.json`

**Security Rules (Semgrep):**

- Add to `tools/security/semgrep-rules.yaml`

### Integrating External Tools

1. Add tool configuration to appropriate `tools/` subdirectory
2. Check for tool availability in `run-full-evaluation.sh`
3. Update `install.sh` to install the tool

## Error Handling

The suite implements multiple error handling strategies:

1. **Graceful Degradation**: Missing optional tools don't fail the evaluation
2. **Timeout Protection**: Long-running checks have configurable timeouts
3. **Atomic Results**: Each category writes atomic JSON results
4. **Error Logging**: All errors are logged to the results directory

## Performance Considerations

- **Parallel Execution**: Independent evaluations can run in parallel
- **Caching**: Results are cached to avoid redundant analysis
- **Selective Evaluation**: `--quick` mode runs subset of checks
- **Skippable Categories**: Security and performance can be skipped

## Security Considerations

- No credentials are stored in the codebase
- Secret detection prevents accidental exposure
- All external tool inputs are sanitized
- Results contain no sensitive information from evaluated codebases
