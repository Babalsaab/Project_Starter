#!/bin/bash

# =============================================================================
# ARCHITECTURE EVALUATION (Parameters 56-81)
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
source "$SCRIPT_DIR/common-progress.sh"
source "$SCRIPT_DIR/common-findings.sh"
source "$SCRIPT_DIR/lib/math-utils.sh"
init_findings

set_total_steps 4

RESULTS='{
    "category": "architecture",
    "parameters_evaluated": 0,
    "parameters_total": 26,
    "score": 0,
    "findings": [],
    "metrics": {}
}'

log_metric() {
    RESULTS=$(echo "$RESULTS" | jq --arg n "$1" --arg v "$2" '.metrics[$n] = $v')
}

# add_finding is provided by common-findings.sh with location support

# Analyze folder structure
analyze_structure() {
    progress_step "Folder structure & patterns"
    local score=7

    # Check for common architectural patterns
    show_action "Source directory structure"
    local has_src=$([ -d "$CODEBASE_PATH/src" ] && echo "true" || echo "false")
    local has_lib=$([ -d "$CODEBASE_PATH/lib" ] && echo "true" || echo "false")
    
    show_action "Component layers"
    local has_components=$(find "$CODEBASE_PATH" -type d -name "components" 2>/dev/null | head -1)
    local has_services=$(find "$CODEBASE_PATH" -type d -name "services" 2>/dev/null | head -1)
    local has_models=$(find "$CODEBASE_PATH" -type d -name "models" -o -name "entities" 2>/dev/null | head -1)
    local has_controllers=$(find "$CODEBASE_PATH" -type d -name "controllers" -o -name "handlers" 2>/dev/null | head -1)

    log_metric "has_src_directory" "$has_src"

    # Check for missing layers and add findings
    if [ -z "$has_components" ]; then
        add_finding "low" "structure" "No components directory - consider adding UI component layer" "$CODEBASE_PATH"
    else
        log_metric "has_components_layer" "true"
        score=$((score + 1))
    fi

    if [ -z "$has_services" ]; then
        add_finding "low" "structure" "No services directory - consider separating business logic" "$CODEBASE_PATH"
    else
        log_metric "has_services_layer" "true"
        score=$((score + 1))
    fi

    if [ -z "$has_models" ]; then
        add_finding "low" "structure" "No models/entities directory - consider adding data layer" "$CODEBASE_PATH"
    else
        log_metric "has_models_layer" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# Check for architectural documentation
check_documentation() {
    progress_step "Architecture documentation"
    local score=5

    show_action "Architecture markdown files"
    if [ -f "$CODEBASE_PATH/ARCHITECTURE.md" ] || [ -f "$CODEBASE_PATH/docs/architecture.md" ]; then
        log_metric "architecture_docs" "true"
        score=$((score + 3))
    else
        add_finding "low" "architecture_docs" "No architecture documentation found"
    fi

    # Check for ADRs
    show_action "Architecture Decision Records"
    if [ -d "$CODEBASE_PATH/docs/adr" ] || [ -d "$CODEBASE_PATH/adr" ]; then
        log_metric "has_adrs" "true"
        score=$((score + 2))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# Analyze dependencies
analyze_dependencies() {
    echo "  Analyzing dependency structure..." >&2
    local score=8

    if [ -f "$CODEBASE_PATH/package.json" ]; then
        cd "$CODEBASE_PATH"

        # Count dependencies
        local deps=$(jq '.dependencies | length' package.json 2>/dev/null || echo "0")
        local devDeps=$(jq '.devDependencies | length' package.json 2>/dev/null || echo "0")

        log_metric "dependencies_count" "$deps"
        log_metric "dev_dependencies_count" "$devDeps"

        # Check for circular dependencies
        if command -v npx &> /dev/null; then
            local circular=$(npx madge --circular . 2>/dev/null | grep -c "Circular" 2>/dev/null || echo "0")
            circular=$(echo "$circular" | tr -d '[:space:]')
            [ -z "$circular" ] && circular=0
            log_metric "circular_dependencies" "$circular"

            if [ "$circular" -gt 0 ]; then
                add_finding "high" "circular_dependencies" "$circular circular dependencies found" "$CODEBASE_PATH"
                score=$((score - circular))
            fi
        fi
    fi

    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

main() {
    echo "Starting Architecture Evaluation..."

    local structure_score=$(analyze_structure)
    local docs_score=$(check_documentation)
    local deps_score=$(analyze_dependencies)

    local total_score=$(math_calc "$structure_score * 0.4 + $docs_score * 0.2 + $deps_score * 0.4")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 26')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg ss "$structure_score" --arg ds "$docs_score" --arg dps "$deps_score" \
        '.subscores = {structure: ($ss | tonumber), documentation: ($ds | tonumber), dependencies: ($dps | tonumber)}')

    # Merge findings from temp file
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Architecture Score: $total_score/10"
}

main
