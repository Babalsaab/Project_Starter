#!/bin/bash

# =============================================================================
# DOCUMENTATION & KNOWLEDGE MANAGEMENT EVALUATION (Parameters 379-388)
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
    "category": "documentation",
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
# Check README Quality (Parameter 321)
# =============================================================================
check_readme() {
    progress_step "README quality"
    local score=3

    if [ -f "$CODEBASE_PATH/README.md" ] || [ -f "$CODEBASE_PATH/readme.md" ]; then
        local readme_file=$(find "$CODEBASE_PATH" -maxdepth 1 -iname "readme.md" | head -1)
        local readme_lines=$(wc -l < "$readme_file" 2>/dev/null | tr -d ' ')
        
        log_metric "readme_exists" "true"
        log_metric "readme_lines" "$readme_lines"
        echo "Scanning: README.md ($readme_lines lines)" >&2

        if [ "$readme_lines" -gt 200 ]; then
            score=9
        elif [ "$readme_lines" -gt 100 ]; then
            score=8
        elif [ "$readme_lines" -gt 50 ]; then
            score=7
        elif [ "$readme_lines" -gt 20 ]; then
            score=6
        else
            add_finding "low" "readme" "README is quite short"
            score=5
        fi

        # Check for key sections
        if grep -qiE "install|setup|getting started" "$readme_file" 2>/dev/null; then
            log_metric "readme_has_install" "true"
        else
            add_finding "medium" "readme" "README missing installation/setup instructions"
            score=$((score - 1))
        fi

        if grep -qiE "usage|example|how to" "$readme_file" 2>/dev/null; then
            log_metric "readme_has_usage" "true"
        fi

        if grep -qiE "api|endpoint|reference" "$readme_file" 2>/dev/null; then
            log_metric "readme_has_api" "true"
        fi
    else
        log_metric "readme_exists" "false"
        add_finding "high" "readme" "No README.md found"
        score=1
    fi

    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check API Documentation (Parameter 322)
# =============================================================================
check_api_docs() {
    progress_step "API documentation"
    local score=4

    # Check for OpenAPI/Swagger
    local has_openapi=$( (find "$CODEBASE_PATH" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) \
        ! -path "*/node_modules/*" 2>/dev/null | xargs grep -l "openapi\|swagger" 2>/dev/null || true) | wc -l)
    
    if [ "$has_openapi" -gt 0 ]; then
        log_metric "openapi_docs" "true"
        score=8
        echo "Scanning: Found OpenAPI/Swagger documentation" >&2
    fi

    # Check for API doc folder
    if [ -d "$CODEBASE_PATH/docs/api" ] || [ -d "$CODEBASE_PATH/api-docs" ]; then
        log_metric "api_docs_folder" "true"
        score=$((score + 1))
    fi

    # Check for JSDoc/TypeDoc
    local jsdoc_count=$(grep -rcE "(/\*\*|@param|@returns|@description)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
        awk -F: '{sum += $2} END {print sum+0}')
    
    log_metric "jsdoc_comments" "$jsdoc_count"

    if [ "$jsdoc_count" -gt 100 ]; then
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Architecture Documentation (Parameter 325)
# =============================================================================
check_arch_docs() {
    progress_step "Architecture documentation"
    local score=4

    # Check for docs folder
    local docs_files=0
    if [ -d "$CODEBASE_PATH/docs" ]; then
        docs_files=$(find "$CODEBASE_PATH/docs" -type f \( -name "*.md" -o -name "*.adoc" \) 2>/dev/null | wc -l)
        log_metric "docs_folder" "true"
        log_metric "docs_files" "$docs_files"
        echo "Scanning: Found docs/ folder with $docs_files files" >&2
    fi

    if [ "$docs_files" -gt 10 ]; then
        score=8
    elif [ "$docs_files" -gt 5 ]; then
        score=7
    elif [ "$docs_files" -gt 0 ]; then
        score=6
    fi

    # Check for ADRs (Architecture Decision Records)
    if [ -d "$CODEBASE_PATH/docs/adr" ] || [ -d "$CODEBASE_PATH/adr" ] || \
       find "$CODEBASE_PATH" -name "*adr*" -type f 2>/dev/null | head -1 | grep -q .; then
        log_metric "adr_present" "true"
        score=$((score + 1))
        echo "Scanning: Found ADR documentation" >&2
    fi

    # Check for diagrams
    if find "$CODEBASE_PATH" -type f \( -name "*.mmd" -o -name "*.puml" -o -name "*.drawio" \) \
        ! -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
        log_metric "diagrams" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Contributing Guide (Parameter 330)
# =============================================================================
check_contributing() {
    progress_step "Contributing and operational docs"
    local score=4

    # Check for CONTRIBUTING.md
    if [ -f "$CODEBASE_PATH/CONTRIBUTING.md" ] || [ -f "$CODEBASE_PATH/.github/CONTRIBUTING.md" ]; then
        log_metric "contributing_guide" "true"
        score=$((score + 2))
        echo "Scanning: Found CONTRIBUTING.md" >&2
    else
        add_finding "low" "docs" "No CONTRIBUTING.md found"
    fi

    # Check for CHANGELOG
    if [ -f "$CODEBASE_PATH/CHANGELOG.md" ] || [ -f "$CODEBASE_PATH/HISTORY.md" ]; then
        log_metric "changelog" "true"
        score=$((score + 1))
    fi

    # Check for LICENSE
    if [ -f "$CODEBASE_PATH/LICENSE" ] || [ -f "$CODEBASE_PATH/LICENSE.md" ]; then
        log_metric "license" "true"
        score=$((score + 1))
    fi

    # Check for runbook/operational docs
    if find "$CODEBASE_PATH" -iname "*runbook*" -o -iname "*playbook*" -o -iname "*operations*" \
        ! -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
        log_metric "runbook" "true"
        score=$((score + 1))
    fi

    # Check for troubleshooting guide
    if grep -rqiE "troubleshoot|debug|common.*issue|faq" "$CODEBASE_PATH/docs" "$CODEBASE_PATH/README.md" \
        2>/dev/null; then
        log_metric "troubleshooting" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Code Comments (Parameter 323)
# =============================================================================
check_code_comments() {
    progress_step "Code comments quality"
    local score=5

    # Count comment lines
    local comment_lines=$(grep -rcE "(^[[:space:]]*(//|#|/\*|\*|'''))" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=test* 2>/dev/null | \
        awk -F: '{sum += $2} END {print sum+0}')
    
    # Count total code lines (rough estimate)
    local code_lines=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.java" \
        \) ! -path "*/node_modules/*" ! -path "*/.git/*" -exec wc -l {} + 2>/dev/null | \
        tail -1 | awk '{print $1+0}')
    
    log_metric "comment_lines" "$comment_lines"
    log_metric "code_lines_approx" "$code_lines"

    if [ "$code_lines" -gt 0 ]; then
        local comment_ratio=$(math_calc "$comment_lines * 100 / $code_lines")
        log_metric "comment_ratio" "$comment_ratio%"
        echo "Scanning: Comment ratio approximately ${comment_ratio}%" >&2

        # 10-20% comments is generally good
        local ratio_int=${comment_ratio%.*}
        if [ "$ratio_int" -ge 10 ] && [ "$ratio_int" -le 25 ]; then
            score=8
        elif [ "$ratio_int" -ge 5 ]; then
            score=6
        elif [ "$ratio_int" -lt 2 ]; then
            add_finding "medium" "comments" "Very low comment ratio"
            score=4
        fi
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Documentation Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local readme_score=$(check_readme)
    local api_score=$(check_api_docs)
    local arch_score=$(check_arch_docs)
    local contrib_score=$(check_contributing)
    local comments_score=$(check_code_comments)

    # Weighted average
    local total_score=$(math_calc "$readme_score * 0.25 + $api_score * 0.20 + $arch_score * 0.20 + $contrib_score * 0.15 + $comments_score * 0.20")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 10')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg rs "$readme_score" \
        --arg as "$api_score" \
        --arg ars "$arch_score" \
        --arg cs "$contrib_score" \
        --arg cms "$comments_score" \
        '.subscores = {
            readme: ($rs | tonumber),
            api_docs: ($as | tonumber),
            architecture_docs: ($ars | tonumber),
            contributing: ($cs | tonumber),
            code_comments: ($cms | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Documentation Score: $total_score/10"
}

main
