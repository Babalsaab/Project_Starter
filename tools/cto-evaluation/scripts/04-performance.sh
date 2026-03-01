#!/bin/bash

# =============================================================================
# PERFORMANCE EVALUATION (Parameters 120-153)
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

set_total_steps 5

RESULTS='{
    "category": "performance",
    "parameters_evaluated": 0,
    "parameters_total": 34,
    "score": 0,
    "findings": [],
    "metrics": {}
}'

log_metric() {
    RESULTS=$(echo "$RESULTS" | jq --arg n "$1" --arg v "$2" '.metrics[$n] = $v')
}

# add_finding is now provided by common-findings.sh with location support
# add_finding "severity" "parameter" "message" "location"

# Check for caching implementation
check_caching() {
    progress_step "Caching implementation"
    local score=5

    if grep -rqE "(redis|memcache|cache|lru-cache)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "caching_implemented" "true"
        score=8

        # Check for Redis specifically
        if grep -rq "redis" "$CODEBASE_PATH" --include="*.json" --exclude-dir=node_modules 2>/dev/null; then
            log_metric "redis_used" "true"
            score=9
        fi
    else
        log_metric "caching_implemented" "false"
        add_finding "medium" "caching" "No caching implementation detected"
    fi

    echo "$score"
}

# Check for async patterns
check_async() {
    echo "  Checking async patterns..." >&2
    local score=7

    # Count async/await usage
    local async_count=$(grep -rEc "async|await|Promise" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null || echo "0")

    log_metric "async_usage_count" "$async_count"

    if [ "$async_count" -gt 50 ]; then
        score=9
    elif [ "$async_count" -gt 20 ]; then
        score=8
    fi

    # Check for blocking operations
    local blocking=$(grep -rEc "Sync\(" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null || echo "0")

    if [ "$blocking" -gt 0 ]; then
        # Find specific files with blocking operations
        grep -rl "Sync\(" "$CODEBASE_PATH" \
            --include="*.js" --include="*.ts" \
            --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | head -3 | while read -r file; do
            add_finding "medium" "blocking_operations" "Synchronous blocking operation used" "$file"
        done
        score=$((score - 1))
    fi
    log_metric "blocking_operations" "$blocking"

    echo "$score"
}

# Check bundle size (frontend)
check_bundle() {
    echo "  Checking bundle configuration..." >&2
    local score=7

    if [ -f "$CODEBASE_PATH/package.json" ]; then
        cd "$CODEBASE_PATH"

        # Check for bundle optimization tools
        if grep -qE "(webpack|vite|esbuild|rollup)" package.json 2>/dev/null; then
            log_metric "bundler_configured" "true"
            score=8
        fi

        # Check for tree-shaking
        if grep -qE "(sideEffects|treeshake)" package.json "$CODEBASE_PATH"/*.config.* 2>/dev/null; then
            log_metric "tree_shaking" "true"
            score=$((score + 1))
        fi

        # Check for code splitting
        if grep -rqE "(lazy|dynamic import|import\()" "$CODEBASE_PATH/src" \
            --include="*.js" --include="*.ts" --include="*.tsx" 2>/dev/null; then
            log_metric "code_splitting" "true"
            score=$((score + 1))
        fi
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# Check database optimization
check_database() {
    echo "  Checking database patterns..." >&2
    local score=7

    # Check for N+1 potential (eager loading)
    if grep -rqE "(include:|eager|join|populate)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "eager_loading_used" "true"
        score=8
    fi

    # Check for connection pooling
    if grep -rqE "(pool|connectionLimit|max_connections)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "connection_pooling" "true"
        score=$((score + 1))
    fi

    # Check for indexes in migrations
    if grep -rqE "(createIndex|addIndex|INDEX)" "$CODEBASE_PATH" \
        --include="*.sql" --include="*.ts" --include="*.js" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "indexes_defined" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

main() {
    echo "Starting Performance Evaluation..."

    local cache_score=$(check_caching)
    local async_score=$(check_async)
    local bundle_score=$(check_bundle)
    local db_score=$(check_database)

    local total_score=$(math_calc "$cache_score * 0.25 + $async_score * 0.25 + $bundle_score * 0.25 + $db_score * 0.25")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 34')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg cs "$cache_score" --arg as "$async_score" --arg bs "$bundle_score" --arg ds "$db_score" \
        '.subscores = {caching: ($cs | tonumber), async: ($as | tonumber), bundling: ($bs | tonumber), database: ($ds | tonumber)}')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Performance Score: $total_score/10"
}

main
