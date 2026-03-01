#!/bin/bash

# =============================================================================
# DEVELOPER EXPERIENCE (DX) EVALUATION (Parameters 389-398)
# =============================================================================

set -euo pipefail

CODEBASE_PATH="${1:-}"
OUTPUT_FILE="${2:-}"
RESULTS_DIR="${3:-${TMPDIR:-/tmp}}"

if [ -z "$CODEBASE_PATH" ] || [ ! -d "$CODEBASE_PATH" ]; then
    echo "Usage: $0 <codebase_path> [output_file] [results_dir]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-findings.sh"
source "$SCRIPT_DIR/lib/math-utils.sh"
init_findings

# Progress tracking
TOTAL_STEPS=5
CURRENT_STEP=0

progress_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "Evaluating: [$CURRENT_STEP/$TOTAL_STEPS] $1" >&2
}

RESULTS='{
    "category": "developer_experience",
    "parameters_evaluated": 0,
    "parameters_total": 10,
    "score": 0,
    "findings": [],
    "metrics": {}
}'

log_metric() {
    RESULTS=$(echo "$RESULTS" | jq --arg n "$1" --arg v "$2" '.metrics[$n] = $v')
}

# add_finding is now provided by common-findings.sh with location support
# add_finding "severity" "parameter" "message" "location"

# =============================================================================
# Check Setup Simplicity (Parameters 354-355)
# =============================================================================
check_setup() {
    progress_step "Setup simplicity"
    local score=5

    # Check for Makefile or npm scripts
    if [ -f "$CODEBASE_PATH/Makefile" ]; then
        log_metric "makefile" "true"
        score=$((score + 1))
        echo "Scanning: Found Makefile" >&2
    fi

    # Check package.json scripts
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        local script_count=$(jq '.scripts | length' "$CODEBASE_PATH/package.json" 2>/dev/null || echo "0")
        log_metric "npm_scripts" "$script_count"
        echo "Scanning: Found $script_count npm scripts" >&2

        if [ "$script_count" -gt 10 ]; then
            score=$((score + 2))
        elif [ "$script_count" -gt 5 ]; then
            score=$((score + 1))
        fi

        # Check for standard scripts
        if jq -e '.scripts.dev or .scripts.start' "$CODEBASE_PATH/package.json" >/dev/null 2>&1; then
            log_metric "has_dev_script" "true"
        fi
        if jq -e '.scripts.build' "$CODEBASE_PATH/package.json" >/dev/null 2>&1; then
            log_metric "has_build_script" "true"
        fi
        if jq -e '.scripts.test' "$CODEBASE_PATH/package.json" >/dev/null 2>&1; then
            log_metric "has_test_script" "true"
        fi
    fi

    # Check for docker-compose (easy setup)
    if [ -f "$CODEBASE_PATH/docker-compose.yml" ] || [ -f "$CODEBASE_PATH/docker-compose.yaml" ]; then
        log_metric "docker_compose" "true"
        score=$((score + 1))
        echo "Scanning: Found docker-compose.yml" >&2
    fi

    # Check for .env.example
    if [ -f "$CODEBASE_PATH/.env.example" ] || [ -f "$CODEBASE_PATH/.env.sample" ]; then
        log_metric "env_example" "true"
        score=$((score + 1))
    else
        add_finding "low" "setup" "No .env.example file found"
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Dev Container (Parameter 335)
# =============================================================================
check_dev_container() {
    progress_step "Dev container and IDE setup"
    local score=4

    # Check for devcontainer
    if [ -d "$CODEBASE_PATH/.devcontainer" ] || [ -f "$CODEBASE_PATH/.devcontainer.json" ]; then
        log_metric "devcontainer" "true"
        score=$((score + 3))
        echo "Scanning: Found devcontainer configuration" >&2
    fi

    # Check for VS Code settings
    if [ -d "$CODEBASE_PATH/.vscode" ]; then
        log_metric "vscode_config" "true"
        score=$((score + 1))

        if [ -f "$CODEBASE_PATH/.vscode/launch.json" ]; then
            log_metric "debug_config" "true"
            score=$((score + 1))
        fi
        if [ -f "$CODEBASE_PATH/.vscode/extensions.json" ]; then
            log_metric "recommended_extensions" "true"
        fi
    fi

    # Check for EditorConfig
    if [ -f "$CODEBASE_PATH/.editorconfig" ]; then
        log_metric "editorconfig" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Linting & Formatting (Parameter 336)
# =============================================================================
check_linting() {
    progress_step "Linting and formatting setup"
    local score=4

    # Check for ESLint
    if [ -f "$CODEBASE_PATH/.eslintrc.js" ] || [ -f "$CODEBASE_PATH/.eslintrc.json" ] || \
       [ -f "$CODEBASE_PATH/eslint.config.js" ] || [ -f "$CODEBASE_PATH/.eslintrc" ]; then
        log_metric "eslint" "true"
        score=$((score + 2))
        echo "Scanning: Found ESLint configuration" >&2
    else
        if [ -f "$CODEBASE_PATH/package.json" ]; then
            add_finding "medium" "linting" "No ESLint configuration found - code quality may vary" "$CODEBASE_PATH"
        fi
    fi

    # Check for Prettier
    if [ -f "$CODEBASE_PATH/.prettierrc" ] || [ -f "$CODEBASE_PATH/.prettierrc.json" ] || \
       [ -f "$CODEBASE_PATH/prettier.config.js" ]; then
        log_metric "prettier" "true"
        score=$((score + 1))
    else
        if [ -f "$CODEBASE_PATH/package.json" ]; then
            add_finding "low" "formatting" "No Prettier configuration - inconsistent code formatting possible" "$CODEBASE_PATH"
        fi
    fi

    # Check for TypeScript
    if [ -f "$CODEBASE_PATH/tsconfig.json" ]; then
        log_metric "typescript" "true"
        score=$((score + 1))
        echo "Scanning: Found TypeScript configuration" >&2
    fi

    # Check for Python linters
    if [ -f "$CODEBASE_PATH/.flake8" ] || [ -f "$CODEBASE_PATH/pyproject.toml" ] || \
       [ -f "$CODEBASE_PATH/setup.cfg" ]; then
        log_metric "python_linter" "true"
        score=$((score + 1))
    fi

    # Check for Stylelint
    if [ -f "$CODEBASE_PATH/.stylelintrc" ] || [ -f "$CODEBASE_PATH/stylelint.config.js" ]; then
        log_metric "stylelint" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Pre-commit Hooks (Parameter 337)
# =============================================================================
check_precommit() {
    progress_step "Pre-commit hooks and automation"
    local score=4

    # Check for Husky
    if [ -d "$CODEBASE_PATH/.husky" ] || grep -q "husky" "$CODEBASE_PATH/package.json" 2>/dev/null; then
        log_metric "husky" "true"
        score=$((score + 2))
        echo "Scanning: Found Husky git hooks" >&2
    else
        add_finding "low" "precommit" "No pre-commit hooks configured - code quality checks may be bypassed" "$CODEBASE_PATH"
    fi

    # Check for lint-staged
    if grep -q "lint-staged" "$CODEBASE_PATH/package.json" 2>/dev/null || \
       [ -f "$CODEBASE_PATH/.lintstagedrc" ]; then
        log_metric "lint_staged" "true"
        score=$((score + 1))
    fi

    # Check for pre-commit (Python)
    if [ -f "$CODEBASE_PATH/.pre-commit-config.yaml" ]; then
        log_metric "precommit_python" "true"
        score=$((score + 2))
        echo "Scanning: Found pre-commit configuration" >&2
    fi

    # Check for commitlint
    if [ -f "$CODEBASE_PATH/commitlint.config.js" ] || grep -q "commitlint" "$CODEBASE_PATH/package.json" 2>/dev/null; then
        log_metric "commitlint" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Hot Reload & Dependency Management (Parameters 333, 339)
# =============================================================================
check_dev_tools() {
    progress_step "Development tools and dependency management"
    local score=5

    # Check for hot reload tools
    if grep -qE "(nodemon|ts-node-dev|vite|next|webpack.*hot|HotModuleReplacement)" "$CODEBASE_PATH/package.json" 2>/dev/null; then
        log_metric "hot_reload" "true"
        score=$((score + 1))
    fi

    # Check for lock files (dependency management)
    if [ -f "$CODEBASE_PATH/package-lock.json" ]; then
        log_metric "npm_lockfile" "true"
        score=$((score + 1))
    elif [ -f "$CODEBASE_PATH/yarn.lock" ]; then
        log_metric "yarn_lockfile" "true"
        score=$((score + 1))
    elif [ -f "$CODEBASE_PATH/pnpm-lock.yaml" ]; then
        log_metric "pnpm_lockfile" "true"
        score=$((score + 1))
    fi

    # Check for dependency bots
    if [ -f "$CODEBASE_PATH/.github/dependabot.yml" ] || [ -f "$CODEBASE_PATH/renovate.json" ]; then
        log_metric "dependency_bot" "true"
        score=$((score + 1))
        echo "Scanning: Found dependency update automation" >&2
    fi

    # Check for engine specification
    if jq -e '.engines' "$CODEBASE_PATH/package.json" >/dev/null 2>&1; then
        log_metric "engine_spec" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Developer Experience Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local setup_score=$(check_setup)
    local container_score=$(check_dev_container)
    local lint_score=$(check_linting)
    local precommit_score=$(check_precommit)
    local tools_score=$(check_dev_tools)

    # Weighted average
    local total_score=$(math_calc "$setup_score * 0.25 + $container_score * 0.15 + $lint_score * 0.25 + $precommit_score * 0.20 + $tools_score * 0.15")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 10')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg ss "$setup_score" \
        --arg cs "$container_score" \
        --arg ls "$lint_score" \
        --arg ps "$precommit_score" \
        --arg ts "$tools_score" \
        '.subscores = {
            setup_simplicity: ($ss | tonumber),
            dev_container: ($cs | tonumber),
            linting: ($ls | tonumber),
            precommit: ($ps | tonumber),
            dev_tools: ($ts | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Developer Experience Score: $total_score/10"
}

main
