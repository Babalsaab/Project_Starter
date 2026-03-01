#!/bin/bash

# =============================================================================
# CODE QUALITY EVALUATION (Parameters 1-55)
# =============================================================================
# Evaluates:
#   - Readability & Clarity (1-12)
#   - Design Principles (13-24)
#   - Code Complexity Metrics (25-32)
#   - Testing, Docs, Types, Maintainability (33-40)
#   - Change Risk, API Stability, Errors, Async, Config, Security, Logging,
#     Test Quality, Governance, Refactorability, Cognitive Load (41-55)
# =============================================================================

set -euo pipefail

CODEBASE_PATH="${1:-}"
OUTPUT_FILE="${2:-}"
RESULTS_DIR="${3:-${TMPDIR:-/tmp}}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(dirname "$SCRIPT_DIR")"
TOOLS_DIR="$SUITE_DIR/tools"

if [ -z "$CODEBASE_PATH" ] || [ ! -d "$CODEBASE_PATH" ]; then
    echo "Usage: $0 <codebase_path> [output_file] [results_dir]" >&2
    exit 1
fi

[ -z "$OUTPUT_FILE" ] && OUTPUT_FILE="$RESULTS_DIR/code-quality.json"

# Source common findings helper for cross-subshell findings accumulation
source "$SCRIPT_DIR/common-findings.sh"
source "$SCRIPT_DIR/lib/math-utils.sh"
init_findings

# Colors
CYAN='\033[0;36m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

# Progress tracking
TOTAL_STEPS=15
CURRENT_STEP=0

progress_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local msg="$1"
    echo "Evaluating: [$CURRENT_STEP/$TOTAL_STEPS] $msg" >&2
}

scan_file() {
    local file="$1"
    local filename=$(basename "$file")
    echo "Scanning: $filename" >&2
}

# Exclude dirs
EXCLUDE_PATTERN="*/node_modules/*|*/.git/*|*/dist/*|*/build/*|*/coverage/*|*/.next/*|*/.nuxt/*|*/out/*|*/vendor/*|*/.cache/*"

list_source_files() {
    find "$CODEBASE_PATH" -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" -o -name "*.java" -o -name "*.rb" \) \
        -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/coverage/*" -print0 2>/dev/null
}

list_test_files() {
    find "$CODEBASE_PATH" -type f \( -name "*test*.*" -o -name "*_test.*" -o -name "*.spec.*" \) \
        -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/coverage/*" -print0 2>/dev/null
}

# Initialize results
RESULTS='{
    "category": "code_quality",
    "parameters_evaluated": 0,
    "parameters_total": 55,
    "score": 0,
    "findings": [],
    "metrics": {}
}'

log_metric() {
    local name="$1"
    local value="$2"
    RESULTS=$(echo "$RESULTS" | jq --arg n "$name" --arg v "$value" '.metrics[$n] = $v')
}

# add_finding is now provided by common-findings.sh (uses temp file for cross-subshell support)

# =============================================================================
# Parameter 1-3: Naming, Self-Documentation, Formatting
# =============================================================================

evaluate_naming_and_formatting() {
    progress_step "Naming conventions & formatting"

    local formatting_score=10
    local naming_score=10

    # Check if ESLint is available
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        (
            cd "$CODEBASE_PATH"

            # Check for ESLint config
            if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.yaml" ] || [ -f ".eslintrc" ]; then
                log_metric "eslint_configured" "true"

                # Run ESLint and count violations
                if command -v npx &> /dev/null; then
                    echo "Scanning: Running ESLint analysis..." >&2
                    local eslint_output
                    eslint_output=$(npx eslint . --format json 2>/dev/null || echo "[]")
                    local error_count
                    error_count=$(echo "$eslint_output" | jq '[.[].errorCount] | add // 0')
                    local warning_count
                    warning_count=$(echo "$eslint_output" | jq '[.[].warningCount] | add // 0')

                    log_metric "eslint_errors" "$error_count"
                    log_metric "eslint_warnings" "$warning_count"

                    # Extract files with most errors for findings
                    if [ "$error_count" -gt 0 ]; then
                        echo "$eslint_output" | jq -r '.[] | select(.errorCount > 0) | .filePath' | head -5 | while read -r file; do
                            local file_errors=$(echo "$eslint_output" | jq --arg f "$file" '.[] | select(.filePath == $f) | .errorCount')
                            add_finding "medium" "linting" "ESLint: $file_errors errors" "$file"
                        done
                    fi

                    # Calculate score based on violations
                    if [ "$error_count" -eq 0 ] && [ "$warning_count" -eq 0 ]; then
                        formatting_score=10
                    elif [ "$error_count" -lt 10 ]; then
                        formatting_score=8
                    elif [ "$error_count" -lt 50 ]; then
                        formatting_score=6
                        add_finding "medium" "formatting" "Moderate ESLint errors: $error_count total" "$CODEBASE_PATH"
                    elif [ "$error_count" -lt 100 ]; then
                        formatting_score=4
                        add_finding "high" "formatting" "High ESLint errors: $error_count total" "$CODEBASE_PATH"
                    else
                        formatting_score=2
                        add_finding "critical" "formatting" "Critical ESLint errors: $error_count total" "$CODEBASE_PATH"
                    fi
                fi
            else
                log_metric "eslint_configured" "false"
                add_finding "medium" "formatting" "No ESLint configuration found" "$CODEBASE_PATH"
                formatting_score=5
            fi

            # Check for Prettier config
            if [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ]; then
                log_metric "prettier_configured" "true"
            else
                log_metric "prettier_configured" "false"
                add_finding "low" "formatting" "No Prettier configuration found" "$CODEBASE_PATH"
                formatting_score=$((formatting_score - 1))
            fi
        )
    fi

    # Python: Check for flake8/black
    if ls "$CODEBASE_PATH"/*.py "$CODEBASE_PATH"/**/*.py 2>/dev/null | head -1 > /dev/null; then
        if [ -f "$CODEBASE_PATH/setup.cfg" ] || [ -f "$CODEBASE_PATH/.flake8" ] || [ -f "$CODEBASE_PATH/pyproject.toml" ]; then
            log_metric "python_linter_configured" "true"
        else
            log_metric "python_linter_configured" "false"
            add_finding "low" "formatting" "No Python linter configuration found" "$CODEBASE_PATH"
        fi
    fi

    log_metric "formatting_score" "$formatting_score"
    log_metric "naming_score" "$naming_score"

    echo "$formatting_score"
}

# =============================================================================
# Parameter 4-6: Function Length, File Organization, Imports
# =============================================================================

evaluate_structure() {
    progress_step "Code structure & file organization"

    local structure_score=10

    # Count average lines per file
    local total_lines=0
    local file_count=0
    local files_scanned=0

    while IFS= read -r -d '' file; do
        files_scanned=$((files_scanned + 1))
        if [ $((files_scanned % 10)) -eq 0 ]; then
            scan_file "$file"
        fi
        
        lines=$(wc -l < "$file")
        total_lines=$((total_lines + lines))
        file_count=$((file_count + 1))

        # Flag large files
        if [ "$lines" -gt 500 ]; then
            add_finding "medium" "file_organization" "Large file ($lines lines)" "$file"
        fi
    done < <(list_source_files)

    echo "Scanning: Analyzed $file_count source files" >&2

    if [ "$file_count" -gt 0 ]; then
        local avg_lines=$((total_lines / file_count))
        log_metric "average_lines_per_file" "$avg_lines"
        log_metric "total_files" "$file_count"

        if [ "$avg_lines" -lt 200 ]; then
            structure_score=10
        elif [ "$avg_lines" -lt 300 ]; then
            structure_score=8
        elif [ "$avg_lines" -lt 500 ]; then
            structure_score=6
        else
            structure_score=4
        fi
    fi

    log_metric "structure_score" "$structure_score"
    echo "$structure_score"
}

# =============================================================================
# Parameter 18: DRY (Code Duplication)
# =============================================================================

evaluate_duplication() {
    progress_step "Code duplication analysis"

    local duplication_score=10

    # Use jscpd if available
    if command -v npx &> /dev/null && [ -f "$CODEBASE_PATH/package.json" ]; then
        (
            cd "$CODEBASE_PATH"

            echo "Scanning: Running copy-paste detection..." >&2
            local jscpd_output
            jscpd_output=$(npx jscpd . --min-lines 5 --min-tokens 50 --format json --silent 2>/dev/null || echo '{"statistics":{"total":{"percentage":0}}}')

            local duplication_percentage
            duplication_percentage=$(echo "$jscpd_output" | jq '.statistics.total.percentage // 0')

            log_metric "duplication_percentage" "$duplication_percentage"

            # Score based on duplication percentage
            if math_compare "$duplication_percentage" "<" "1"; then
                duplication_score=10
            elif math_compare "$duplication_percentage" "<" "3"; then
                duplication_score=8
            elif math_compare "$duplication_percentage" "<" "5"; then
                duplication_score=6
            elif math_compare "$duplication_percentage" "<" "10"; then
                duplication_score=4
            else
                duplication_score=2
                add_finding "high" "duplication" "High code duplication: ${duplication_percentage}%" "$CODEBASE_PATH"
            fi
        )
    else
        log_metric "duplication_percentage" "unknown"
        duplication_score=5
    fi

    log_metric "duplication_score" "$duplication_score"
    echo "$duplication_score"
}

# =============================================================================
# Parameter 25-27: Cyclomatic Complexity, Cognitive Complexity, Nesting
# =============================================================================

evaluate_complexity() {
    echo "  Evaluating code complexity..." >&2

    local complexity_score=10

    # JavaScript/TypeScript complexity
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        (
            cd "$CODEBASE_PATH"

            # Try to use complexity-report or eslint complexity rule
            if command -v npx &> /dev/null; then
                # Check for complexity violations using ESLint
                local complexity_output
                complexity_output=$(npx eslint . --rule '{"complexity": ["error", 15]}' --format json 2>/dev/null || echo "[]")
                local complexity_violations
                complexity_violations=$(echo "$complexity_output" | jq '[.[].errorCount] | add // 0')

                log_metric "complexity_violations" "$complexity_violations"

                if [ "$complexity_violations" -eq 0 ]; then
                    complexity_score=10
                elif [ "$complexity_violations" -lt 5 ]; then
                    complexity_score=8
                elif [ "$complexity_violations" -lt 15 ]; then
                    complexity_score=6
                elif [ "$complexity_violations" -lt 30 ]; then
                    complexity_score=4
                else
                    complexity_score=2
                    add_finding "high" "complexity" "High cyclomatic complexity in $complexity_violations locations" "$CODEBASE_PATH"
                fi
            fi
        )
    fi

    # Python complexity using radon
    if command -v radon &> /dev/null && ls "$CODEBASE_PATH"/*.py "$CODEBASE_PATH"/**/*.py 2>/dev/null | head -1 > /dev/null; then
        (
            cd "$CODEBASE_PATH"
            local radon_output
            radon_output=$(radon cc . -a -s --json 2>/dev/null || echo '{}')

            # Count functions with high complexity (C, D, E, F grades)
            local high_complexity_count
            high_complexity_count=$(echo "$radon_output" | jq '[.. | objects | select(.complexity? > 10)] | length')

            log_metric "python_high_complexity_functions" "$high_complexity_count"

            if [ "$high_complexity_count" -gt 0 ]; then
                add_finding "medium" "complexity" "$high_complexity_count Python functions with high complexity" "$CODEBASE_PATH"
            fi
        )
    fi

    log_metric "complexity_score" "$complexity_score"
    echo "$complexity_score"
}

# =============================================================================
# Parameter 28: Circular Dependencies
# =============================================================================

evaluate_dependencies() {
    echo "  Evaluating dependencies..." >&2

    local dependency_score=10

    # JavaScript circular dependencies
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        (
            cd "$CODEBASE_PATH"

            if command -v npx &> /dev/null; then
                local madge_output
                madge_output=$(npx madge --circular . 2>/dev/null || echo "")

                local circular_count
                circular_count=$(echo "$madge_output" | grep -c "Circular" 2>/dev/null || echo "0")
                circular_count=$(echo "$circular_count" | tr -d '[:space:]')
                [ -z "$circular_count" ] && circular_count=0

                log_metric "circular_dependencies" "$circular_count"

                if [ "$circular_count" -eq 0 ]; then
                    dependency_score=10
                elif [ "$circular_count" -lt 3 ]; then
                    dependency_score=7
                    add_finding "medium" "dependencies" "$circular_count circular dependencies found" "$CODEBASE_PATH"
                elif [ "$circular_count" -lt 10 ]; then
                    dependency_score=4
                    add_finding "high" "dependencies" "$circular_count circular dependencies found" "$CODEBASE_PATH"
                else
                    dependency_score=2
                    add_finding "critical" "dependencies" "$circular_count circular dependencies found" "$CODEBASE_PATH"
                fi
            fi
        )
    fi

    log_metric "dependency_score" "$dependency_score"
    echo "$dependency_score"
}

# =============================================================================
# Parameter 29-32: Testing Quality & Coverage Signals
# =============================================================================

evaluate_testing_quality() {
    progress_step "Testing quality & coverage signals"

    local testing_score=10

    local test_files=0
    local source_files=0

    test_files=$(list_test_files | tr -cd '\0' | wc -c | tr -d '[:space:]')
    source_files=$(list_source_files | tr -cd '\0' | wc -c | tr -d '[:space:]')

    log_metric "test_files" "$test_files"
    log_metric "source_files" "$source_files"

    local test_ratio
    test_ratio=$(math_calc "($test_files / ($source_files + 1)) * 100")
    log_metric "test_to_source_ratio" "$test_ratio"

    local coverage_reports
    coverage_reports=$(find "$CODEBASE_PATH" -type f \( -name "lcov.info" -o -name "coverage.xml" -o -name "coverage-final.json" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    log_metric "coverage_reports" "$coverage_reports"

    local test_frameworks=0
    [ -f "$CODEBASE_PATH/package.json" ] && test_frameworks=$(jq -r '.devDependencies + .dependencies | keys[]' "$CODEBASE_PATH/package.json" 2>/dev/null | grep -E "jest|vitest|mocha|ava|cypress|playwright" | wc -l | tr -d '[:space:]')
    [ -f "$CODEBASE_PATH/pytest.ini" ] && test_frameworks=$((test_frameworks + 1))
    [ -f "$CODEBASE_PATH/pyproject.toml" ] && grep -q "\[tool.pytest.ini_options\]" "$CODEBASE_PATH/pyproject.toml" 2>/dev/null && test_frameworks=$((test_frameworks + 1))
    log_metric "test_frameworks_detected" "$test_frameworks"

    if math_compare "$test_ratio" ">=" "60"; then
        testing_score=10
    elif math_compare "$test_ratio" ">=" "30"; then
        testing_score=8
    elif math_compare "$test_ratio" ">=" "15"; then
        testing_score=6
    elif math_compare "$test_ratio" ">=" "5"; then
        testing_score=4
        add_finding "medium" "testing" "Low test coverage signal (test/source ratio: ${test_ratio}%)" "$CODEBASE_PATH"
    else
        testing_score=2
        add_finding "high" "testing" "Very low test coverage signal (test/source ratio: ${test_ratio}%)" "$CODEBASE_PATH"
    fi

    if [ "$coverage_reports" -eq 0 ]; then
        testing_score=$((testing_score - 1))
        add_finding "low" "testing" "No coverage reports detected" "$CODEBASE_PATH"
    fi

    [ "$test_frameworks" -eq 0 ] && add_finding "medium" "testing" "No test framework detected" "$CODEBASE_PATH"

    log_metric "testing_score" "$testing_score"
    echo "$testing_score"
}

# =============================================================================
# Parameter 33-34: Documentation & Self-Explanation Quality
# =============================================================================

evaluate_documentation_quality() {
    progress_step "Documentation & self-explanation"

    local doc_score=10

    [ -f "$CODEBASE_PATH/README.md" ] || { doc_score=$((doc_score - 2)); add_finding "medium" "documentation" "README.md missing" "$CODEBASE_PATH"; }
    [ -f "$CODEBASE_PATH/CONTRIBUTING.md" ] || { doc_score=$((doc_score - 1)); add_finding "low" "documentation" "CONTRIBUTING.md missing" "$CODEBASE_PATH"; }
    [ -d "$CODEBASE_PATH/docs" ] || { doc_score=$((doc_score - 1)); }

    local jsdoc_count
    jsdoc_count=$({ grep -r "^\s*/\*\*" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local py_docstring_count
    py_docstring_count=$({ grep -r '"""' "$CODEBASE_PATH" --include "*.py" --exclude-dir node_modules --exclude-dir .git 2>/dev/null || true; } | wc -l | tr -d '[:space:]')

    log_metric "jsdoc_count" "$jsdoc_count"
    log_metric "python_docstring_count" "$py_docstring_count"

    if [ "$jsdoc_count" -eq 0 ] && [ "$py_docstring_count" -eq 0 ]; then
        doc_score=$((doc_score - 2))
        add_finding "medium" "documentation" "Minimal inline documentation detected" "$CODEBASE_PATH"
    fi

    [ "$doc_score" -lt 2 ] && doc_score=2
    log_metric "documentation_score" "$doc_score"
    echo "$doc_score"
}

# =============================================================================
# Parameter 35-36: Type Safety & Static Analysis
# =============================================================================

evaluate_type_safety() {
    progress_step "Type safety & static analysis"

    local type_score=10

    if [ -f "$CODEBASE_PATH/tsconfig.json" ]; then
        if grep -q '"strict"\s*:\s*true' "$CODEBASE_PATH/tsconfig.json" 2>/dev/null; then
            log_metric "ts_strict" "true"
        else
            log_metric "ts_strict" "false"
            type_score=$((type_score - 2))
            add_finding "medium" "types" "TypeScript strict mode not enabled" "$CODEBASE_PATH/tsconfig.json"
        fi
    fi

    if [ -f "$CODEBASE_PATH/pyproject.toml" ]; then
        if grep -q "\[tool.mypy\]" "$CODEBASE_PATH/pyproject.toml" 2>/dev/null || grep -q "\[tool.pyright\]" "$CODEBASE_PATH/pyproject.toml" 2>/dev/null; then
            log_metric "python_type_checker" "true"
        else
            log_metric "python_type_checker" "false"
            type_score=$((type_score - 1))
        fi
    fi

    if [ -f "$CODEBASE_PATH/sonar-project.properties" ] || [ -f "$CODEBASE_PATH/.codeclimate.yml" ]; then
        log_metric "static_analysis_configured" "true"
    else
        log_metric "static_analysis_configured" "false"
        type_score=$((type_score - 1))
    fi

    [ "$type_score" -lt 2 ] && type_score=2
    log_metric "type_safety_score" "$type_score"
    echo "$type_score"
}

# =============================================================================
# Parameter 37-40: Maintainability Signals (TODO/FIXME/Deprecated)
# =============================================================================

evaluate_maintainability_signals() {
    progress_step "Maintainability signals (TODO/FIXME/Deprecated)"

    local maintain_score=10

    local todo_count
    todo_count=$(grep -rE "TODO|FIXME|XXX" "$CODEBASE_PATH" --exclude-dir node_modules --exclude-dir .git 2>/dev/null | wc -l | tr -d '[:space:]')
    local deprecated_count
    deprecated_count=$(grep -rE "@deprecated|DEPRECATED" "$CODEBASE_PATH" --exclude-dir node_modules --exclude-dir .git 2>/dev/null | wc -l | tr -d '[:space:]')

    log_metric "todo_fixme_count" "$todo_count"
    log_metric "deprecated_count" "$deprecated_count"

    if [ "$todo_count" -gt 200 ]; then
        maintain_score=4
        add_finding "high" "maintainability" "High TODO/FIXME count: $todo_count" "$CODEBASE_PATH"
    elif [ "$todo_count" -gt 50 ]; then
        maintain_score=6
        add_finding "medium" "maintainability" "Elevated TODO/FIXME count: $todo_count" "$CODEBASE_PATH"
    fi

    if [ "$deprecated_count" -gt 20 ]; then
        maintain_score=$((maintain_score - 2))
        add_finding "medium" "maintainability" "Deprecated usage count: $deprecated_count" "$CODEBASE_PATH"
    elif [ "$deprecated_count" -gt 0 ]; then
        maintain_score=$((maintain_score - 1))
    fi

    [ "$maintain_score" -lt 2 ] && maintain_score=2
    log_metric "maintainability_score" "$maintain_score"
    echo "$maintain_score"
}

# =============================================================================
# Parameter 41-44: Change Risk & Blast Radius (Git Hotspots)
# =============================================================================

evaluate_change_risk() {
    progress_step "Change risk & blast radius"

    local change_score=10

    if [ -d "$CODEBASE_PATH/.git" ] && command -v git &> /dev/null; then
        local churn_count
        churn_count=$(git -C "$CODEBASE_PATH" log --name-only --pretty=format: 2>/dev/null | grep -E '\.(js|jsx|ts|tsx|py|go|java|rb)$' | sort | uniq -c | sort -nr | head -1 | awk '{print $1}')
        churn_count=${churn_count:-0}

        local unique_authors
        unique_authors=$(git -C "$CODEBASE_PATH" log --format='%an' 2>/dev/null | sort -u | wc -l | tr -d '[:space:]')

        local import_count
        import_count=$(grep -rE "^\s*(import|from)\s" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null | wc -l | tr -d '[:space:]')

        log_metric "hotspot_score" "$churn_count"
        log_metric "author_count" "$unique_authors"
        log_metric "dependency_fanout" "$import_count"

        if [ "$churn_count" -gt 200 ]; then
            change_score=4
            add_finding "high" "change_risk" "Hotspot churn detected (top file changes: $churn_count)" "$CODEBASE_PATH"
        elif [ "$churn_count" -gt 100 ]; then
            change_score=6
            add_finding "medium" "change_risk" "Elevated churn in top files (top file changes: $churn_count)" "$CODEBASE_PATH"
        elif [ "$churn_count" -gt 50 ]; then
            change_score=8
        fi
    else
        change_score=5
        log_metric "hotspot_score" "unknown"
        log_metric "author_count" "unknown"
        log_metric "dependency_fanout" "unknown"
        add_finding "low" "change_risk" "Git history not available for hotspot analysis" "$CODEBASE_PATH"
    fi

    log_metric "change_risk_score" "$change_score"
    echo "$change_score"
}

# =============================================================================
# Parameter 45-46: API Stability & Public Surface Control
# =============================================================================

evaluate_api_stability() {
    progress_step "API stability & public surface"

    local api_score=10

    local export_count
    export_count=$({ grep -rE "^\s*export\s" "$CODEBASE_PATH" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    log_metric "public_api_surface_size" "$export_count"

    local internal_imports
    internal_imports=$(grep -rE "from\s+['\"]\.\./.*(internal|private)" "$CODEBASE_PATH" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null | wc -l | tr -d '[:space:]')
    log_metric "unstable_api_usage_count" "$internal_imports"

    local has_public_index
    has_public_index=$(find "$CODEBASE_PATH" -type f \( -name "index.ts" -o -name "index.tsx" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    log_metric "public_entrypoints" "$has_public_index"

    if [ "$export_count" -gt 500 ]; then
        api_score=5
        add_finding "medium" "api_stability" "Very large public API surface ($export_count exports)" "$CODEBASE_PATH"
    elif [ "$export_count" -gt 200 ]; then
        api_score=7
    fi

    if [ "$internal_imports" -gt 20 ]; then
        api_score=$((api_score - 2))
        add_finding "medium" "api_stability" "Potential unstable/internal API usage ($internal_imports)" "$CODEBASE_PATH"
    fi

    if [ "$has_public_index" -eq 0 ]; then
        api_score=$((api_score - 1))
        add_finding "low" "api_stability" "No clear public API entrypoints (index.ts) found" "$CODEBASE_PATH"
    fi

    [ "$api_score" -lt 2 ] && api_score=2
    log_metric "api_stability_score" "$api_score"
    echo "$api_score"
}

# =============================================================================
# Parameter 47: Error Handling & Failure Semantics
# =============================================================================

evaluate_error_handling() {
    progress_step "Error handling & failure semantics"

    local error_score=10

    local throw_string
    throw_string=$({ grep -rE "throw\s+['\"]" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local empty_catch
    empty_catch=$({ grep -rE "catch\s*\(.*\)\s*\{\s*\}" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null || true; } | wc -l | tr -d '[:space:]')

    log_metric "error_antipattern_count" "$((throw_string + empty_catch))"
    log_metric "throw_string_count" "$throw_string"
    log_metric "empty_catch_count" "$empty_catch"

    if [ "$throw_string" -gt 0 ]; then
        error_score=$((error_score - 2))
        add_finding "medium" "error_handling" "String throws detected ($throw_string)" "$CODEBASE_PATH"
    fi
    if [ "$empty_catch" -gt 0 ]; then
        error_score=$((error_score - 2))
        add_finding "high" "error_handling" "Empty catch blocks detected ($empty_catch)" "$CODEBASE_PATH"
    fi

    [ "$error_score" -lt 2 ] && error_score=2
    log_metric "error_handling_score" "$error_score"
    echo "$error_score"
}

# =============================================================================
# Parameter 48: Async & Concurrency Safety
# =============================================================================

evaluate_async_safety() {
    progress_step "Async & concurrency safety"

    local async_score=10

    local unawaited
    unawaited=$(grep -rE "forEach\(async|map\(async|setTimeout\(async" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null | wc -l | tr -d '[:space:]')
    local promise_all
    promise_all=$({ grep -rE "Promise\.all\(" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local await_all
    await_all=$({ grep -rE "await\s+Promise\.all\(" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null || true; } | wc -l | tr -d '[:space:]')

    local unhandled_promise=$((promise_all - await_all))
    [ "$unhandled_promise" -lt 0 ] && unhandled_promise=0

    log_metric "async_misuse_count" "$unawaited"
    log_metric "unhandled_promise_count" "$unhandled_promise"

    if [ "$unawaited" -gt 10 ] || [ "$unhandled_promise" -gt 10 ]; then
        async_score=5
        add_finding "medium" "async" "Potential async misuse (unawaited patterns: $unawaited, unawaited Promise.all: $unhandled_promise)" "$CODEBASE_PATH"
    elif [ "$unawaited" -gt 0 ] || [ "$unhandled_promise" -gt 0 ]; then
        async_score=8
    fi

    log_metric "async_safety_score" "$async_score"
    echo "$async_score"
}

# =============================================================================
# Parameter 49: Configuration & Environment Safety
# =============================================================================

evaluate_config_safety() {
    progress_step "Configuration & environment safety"

    local config_score=10

    local env_usage
    env_usage=$({ grep -rE "process\.env\.[A-Z0-9_]+" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    log_metric "env_usage_count" "$env_usage"

    local validation_libs=0
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        validation_libs=$(jq -r '.dependencies + .devDependencies | keys[]' "$CODEBASE_PATH/package.json" 2>/dev/null | grep -E "zod|joi|envalid|convict" | wc -l | tr -d '[:space:]')
    fi
    log_metric "env_validation_libs" "$validation_libs"

    if [ "$env_usage" -gt 0 ] && [ "$validation_libs" -eq 0 ]; then
        config_score=6
        add_finding "medium" "config" "Env vars used without schema validation" "$CODEBASE_PATH"
    fi

    log_metric "config_safety_score" "$config_score"
    echo "$config_score"
}

# =============================================================================
# Parameter 50: Security-Adjacent Code Smells
# =============================================================================

evaluate_security_smells() {
    progress_step "Security-adjacent code smells"

    local security_score=10

    local high_risk
    high_risk=$(grep -rE "\beval\(|new\s+Function\(|dangerouslySetInnerHTML" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null | wc -l | tr -d '[:space:]')
    local insecure_random
    insecure_random=$({ grep -rE "Math\.random\(" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null || true; } | wc -l | tr -d '[:space:]')

    log_metric "high_risk_apis_count" "$high_risk"
    log_metric "insecure_pattern_usage" "$insecure_random"

    if [ "$high_risk" -gt 0 ]; then
        security_score=5
        add_finding "high" "security" "High-risk APIs detected ($high_risk)" "$CODEBASE_PATH"
    fi

    if [ "$insecure_random" -gt 10 ]; then
        security_score=$((security_score - 2))
        add_finding "medium" "security" "Potential insecure randomness usage ($insecure_random)" "$CODEBASE_PATH"
    fi

    [ "$security_score" -lt 2 ] && security_score=2
    log_metric "security_smell_score" "$security_score"
    echo "$security_score"
}

# =============================================================================
# Parameter 51: Logging & Observability Quality
# =============================================================================

evaluate_logging_quality() {
    progress_step "Logging & observability quality"

    local logging_score=10

    local console_logs
    console_logs=$(grep -rE "\bconsole\.(log|warn|error)" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null | wc -l | tr -d '[:space:]')
    log_metric "console_log_count" "$console_logs"

    local logger_libs=0
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        logger_libs=$(jq -r '.dependencies + .devDependencies | keys[]' "$CODEBASE_PATH/package.json" 2>/dev/null | grep -E "pino|winston|bunyan|loglevel" | wc -l | tr -d '[:space:]')
    fi
    log_metric "logger_libs" "$logger_libs"

    if [ "$console_logs" -gt 200 ]; then
        logging_score=5
        add_finding "medium" "logging" "High console.* usage ($console_logs)" "$CODEBASE_PATH"
    elif [ "$console_logs" -gt 50 ]; then
        logging_score=7
    fi

    if [ "$logger_libs" -eq 0 ]; then
        logging_score=$((logging_score - 1))
        add_finding "low" "logging" "No structured logger detected" "$CODEBASE_PATH"
    fi

    [ "$logging_score" -lt 2 ] && logging_score=2
    log_metric "logging_quality_score" "$logging_score"
    echo "$logging_score"
}

# =============================================================================
# Parameter 52: Test Quality (Not Just Quantity)
# =============================================================================

evaluate_test_quality() {
    progress_step "Test quality (assertions, snapshots, smells)"

    local test_quality_score=10

    local test_count
    test_count=$(grep -rE "\b(describe|it|test)\(" "$CODEBASE_PATH" --include "*.test.*" --include "*.spec.*" --exclude-dir node_modules --exclude-dir .git 2>/dev/null | wc -l | tr -d '[:space:]')
    local assertion_count
    assertion_count=$(grep -rE "\b(expect|assert)\(" "$CODEBASE_PATH" --include "*.test.*" --include "*.spec.*" --exclude-dir node_modules --exclude-dir .git 2>/dev/null | wc -l | tr -d '[:space:]')
    local snapshot_count
    snapshot_count=$({ grep -r "toMatchSnapshot" "$CODEBASE_PATH" --include "*.test.*" --include "*.spec.*" --exclude-dir node_modules --exclude-dir .git 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local flaky_hints
    flaky_hints=$(grep -rE "setTimeout\(|retry\(" "$CODEBASE_PATH" --include "*.test.*" --include "*.spec.*" --exclude-dir node_modules --exclude-dir .git 2>/dev/null | wc -l | tr -d '[:space:]')

    local assertions_per_test
    assertions_per_test=$(math_calc "$assertion_count / ($test_count + 1)")
    local snapshot_ratio
    snapshot_ratio=$(math_calc "$snapshot_count / ($assertion_count + 1)")

    log_metric "assertions_per_test" "$assertions_per_test"
    log_metric "snapshot_ratio" "$snapshot_ratio"
    log_metric "test_smell_count" "$flaky_hints"

    if math_compare "$assertions_per_test" "<" "1"; then
        test_quality_score=5
        add_finding "medium" "testing" "Low assertion density (assertions/test: $assertions_per_test)" "$CODEBASE_PATH"
    fi

    if math_compare "$snapshot_ratio" ">" "0.5"; then
        test_quality_score=$((test_quality_score - 2))
        add_finding "low" "testing" "High snapshot reliance (ratio: $snapshot_ratio)" "$CODEBASE_PATH"
    fi

    if [ "$flaky_hints" -gt 0 ]; then
        test_quality_score=$((test_quality_score - 1))
        add_finding "low" "testing" "Potential flaky test patterns detected ($flaky_hints)" "$CODEBASE_PATH"
    fi

    [ "$test_quality_score" -lt 2 ] && test_quality_score=2
    log_metric "test_quality_score" "$test_quality_score"
    echo "$test_quality_score"
}

# =============================================================================
# Parameter 53: Governance & Consistency Enforcement
# =============================================================================

evaluate_governance() {
    progress_step "Governance & consistency enforcement"

    local governance_score=10

    local eslint_disable
    eslint_disable=$({ grep -rE "eslint-disable" "$CODEBASE_PATH" --include "*.js" --include "*.ts" --include "*.tsx" --exclude-dir node_modules --exclude-dir .git 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    log_metric "rule_override_count" "$eslint_disable"

    if [ "$eslint_disable" -gt 100 ]; then
        governance_score=5
        add_finding "medium" "governance" "High eslint-disable usage ($eslint_disable)" "$CODEBASE_PATH"
    elif [ "$eslint_disable" -gt 20 ]; then
        governance_score=7
    fi

    log_metric "governance_score" "$governance_score"
    echo "$governance_score"
}

# =============================================================================
# Parameter 54: Refactorability Index (Derived)
# =============================================================================

evaluate_refactorability() {
    progress_step "Refactorability index"

    local refactor_score
    refactor_score=$(math_calc "($complexity_score + $dependency_score + $testing_score + $type_safety_score) / 4")
    log_metric "refactorability_score" "$refactor_score"
    echo "$refactor_score"
}

# =============================================================================
# Parameter 55: Developer Cognitive Load Index
# =============================================================================

evaluate_cognitive_load() {
    progress_step "Developer cognitive load"

    local avg_lines
    avg_lines=$(echo "$RESULTS" | jq -r '.metrics.average_lines_per_file // 0')
    local complexity_violations
    complexity_violations=$(echo "$RESULTS" | jq -r '.metrics.complexity_violations // 0')
    local todo_count
    todo_count=$(echo "$RESULTS" | jq -r '.metrics.todo_fixme_count // 0')

    local cognitive_score=10
    if [ "$avg_lines" -gt 400 ]; then
        cognitive_score=$((cognitive_score - 2))
    elif [ "$avg_lines" -gt 250 ]; then
        cognitive_score=$((cognitive_score - 1))
    fi

    if [ "$complexity_violations" -gt 20 ]; then
        cognitive_score=$((cognitive_score - 2))
    elif [ "$complexity_violations" -gt 5 ]; then
        cognitive_score=$((cognitive_score - 1))
    fi

    if [ "$todo_count" -gt 100 ]; then
        cognitive_score=$((cognitive_score - 2))
    elif [ "$todo_count" -gt 30 ]; then
        cognitive_score=$((cognitive_score - 1))
    fi

    [ "$cognitive_score" -lt 2 ] && cognitive_score=2
    log_metric "cognitive_load_score" "$cognitive_score"
    echo "$cognitive_score"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo "Starting Code Quality Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local formatting_score
    formatting_score=$(evaluate_naming_and_formatting)

    local structure_score
    structure_score=$(evaluate_structure)

    local duplication_score
    duplication_score=$(evaluate_duplication)

    local complexity_score
    complexity_score=$(evaluate_complexity)

    local dependency_score
    dependency_score=$(evaluate_dependencies)

    local testing_score
    testing_score=$(evaluate_testing_quality)

    local documentation_score
    documentation_score=$(evaluate_documentation_quality)

    local type_safety_score
    type_safety_score=$(evaluate_type_safety)

    local maintainability_score
    maintainability_score=$(evaluate_maintainability_signals)

    local change_risk_score
    change_risk_score=$(evaluate_change_risk)

    local api_stability_score
    api_stability_score=$(evaluate_api_stability)

    local error_handling_score
    error_handling_score=$(evaluate_error_handling)

    local async_safety_score
    async_safety_score=$(evaluate_async_safety)

    local config_safety_score
    config_safety_score=$(evaluate_config_safety)

    local security_smell_score
    security_smell_score=$(evaluate_security_smells)

    local logging_quality_score
    logging_quality_score=$(evaluate_logging_quality)

    local test_quality_score
    test_quality_score=$(evaluate_test_quality)

    local governance_score
    governance_score=$(evaluate_governance)

    local refactorability_score
    refactorability_score=$(evaluate_refactorability)

    local cognitive_load_score
    cognitive_load_score=$(evaluate_cognitive_load)

    # Calculate weighted average (elite weights)
    # Core: Formatting 12%, Structure 10%, Duplication 8%, Complexity 12%, Dependencies 8%
    # Quality: Testing 8%, Doc 4%, Type Safety 6%, Maintainability 4%
    # Elite: Change Risk 8%, API 4%, Error Handling 4%, Async 4%, Config 3%, Security 3%, Logging 3%,
    #        Test Quality 3%, Governance 2%, Refactorability 4%, Cognitive Load 4%
    local total_score
    total_score=$(math_calc "$formatting_score * 0.12 + $structure_score * 0.10 + $duplication_score * 0.08 + $complexity_score * 0.12 + $dependency_score * 0.08 + $testing_score * 0.08 + $documentation_score * 0.04 + $type_safety_score * 0.06 + $maintainability_score * 0.04 + $change_risk_score * 0.08 + $api_stability_score * 0.04 + $error_handling_score * 0.04 + $async_safety_score * 0.04 + $config_safety_score * 0.03 + $security_smell_score * 0.03 + $logging_quality_score * 0.03 + $test_quality_score * 0.03 + $governance_score * 0.02 + $refactorability_score * 0.04 + $cognitive_load_score * 0.04")

    # Update results
    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 55')

    # Add subscores
    RESULTS=$(echo "$RESULTS" | jq \
        --arg fs "$formatting_score" \
        --arg ss "$structure_score" \
        --arg ds "$duplication_score" \
        --arg cs "$complexity_score" \
        --arg deps "$dependency_score" \
        --arg ts "$testing_score" \
        --arg doc "$documentation_score" \
        --arg types "$type_safety_score" \
        --arg ms "$maintainability_score" \
        --arg cr "$change_risk_score" \
        --arg api "$api_stability_score" \
        --arg eh "$error_handling_score" \
        --arg as "$async_safety_score" \
        --arg cs "$config_safety_score" \
        --arg sec "$security_smell_score" \
        --arg log "$logging_quality_score" \
        --arg tq "$test_quality_score" \
        --arg gov "$governance_score" \
        --arg ref "$refactorability_score" \
        --arg cog "$cognitive_load_score" \
        '.subscores = {
            formatting: ($fs | tonumber),
            structure: ($ss | tonumber),
            duplication: ($ds | tonumber),
            complexity: ($cs | tonumber),
            dependencies: ($deps | tonumber),
            testing: ($ts | tonumber),
            documentation: ($doc | tonumber),
            type_safety: ($types | tonumber),
            maintainability: ($ms | tonumber),
            change_risk: ($cr | tonumber),
            api_stability: ($api | tonumber),
            error_handling: ($eh | tonumber),
            async_safety: ($as | tonumber),
            config_safety: ($cs | tonumber),
            security_smells: ($sec | tonumber),
            logging_quality: ($log | tonumber),
            test_quality: ($tq | tonumber),
            governance: ($gov | tonumber),
            refactorability: ($ref | tonumber),
            cognitive_load: ($cog | tonumber)
        }')

    # Merge findings from temp file into results
    RESULTS=$(merge_findings "$RESULTS")

    # Write output
    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"

    echo "Code Quality Score: $total_score/10"
    echo "Results saved to: $OUTPUT_FILE"
}

main
