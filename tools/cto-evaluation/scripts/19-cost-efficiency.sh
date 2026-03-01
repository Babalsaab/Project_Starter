#!/bin/bash

# =============================================================================
# COST EFFICIENCY & RESOURCE OPTIMIZATION EVALUATION (Parameters 447-456)
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
TOTAL_STEPS=4
CURRENT_STEP=0

progress_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "Evaluating: [$CURRENT_STEP/$TOTAL_STEPS] $1" >&2
}

RESULTS='{
    "category": "cost_efficiency",
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
# Check Infrastructure Efficiency (Parameters 412-415)
# =============================================================================
check_infrastructure() {
    progress_step "Infrastructure efficiency patterns"
    local score=5

    # Check for auto-scaling configuration
    if grep -rqE "(autoscal|AutoScal|HPA|HorizontalPodAutoscaler|scaling.*policy|minReplicas|maxReplicas)" "$CODEBASE_PATH" \
        --include="*.yaml" --include="*.yml" --include="*.json" --include="*.tf" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "auto_scaling" "true"
        score=$((score + 2))
        echo "Scanning: Found auto-scaling configuration" >&2
    fi

    # Check for resource limits
    if grep -rqE "(resources:|limits:|requests:|cpu:|memory:)" "$CODEBASE_PATH" \
        --include="*.yaml" --include="*.yml" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "resource_limits" "true"
        score=$((score + 1))
    fi

    # Check for spot/preemptible instances
    if grep -rqE "(spot|preemptible|nodeSelector|tolerations|taint)" "$CODEBASE_PATH" \
        --include="*.yaml" --include="*.yml" --include="*.tf" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "spot_instances" "true"
        score=$((score + 1))
    fi

    # Check for IaC (infrastructure as code)
    local terraform_files=$(find "$CODEBASE_PATH" -name "*.tf" ! -path "*/node_modules/*" 2>/dev/null | wc -l)
    local cloudformation=$(find "$CODEBASE_PATH" -name "*cloudformation*" -o -name "*cfn*" ! -path "*/node_modules/*" 2>/dev/null | wc -l)
    
    if [ "$terraform_files" -gt 0 ] || [ "$cloudformation" -gt 0 ]; then
        log_metric "infrastructure_as_code" "true"
        score=$((score + 1))
        echo "Scanning: Found Infrastructure as Code" >&2
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Storage Optimization (Parameter 393)
# =============================================================================
check_storage() {
    progress_step "Storage optimization"
    local score=5

    # Check for tiered storage
    if grep -rqE "(storageClass|STANDARD_IA|GLACIER|INTELLIGENT_TIERING|lifecycle)" "$CODEBASE_PATH" \
        --include="*.yaml" --include="*.yml" --include="*.tf" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "tiered_storage" "true"
        score=$((score + 2))
        echo "Scanning: Found tiered storage configuration" >&2
    fi

    # Check for caching (reduces storage reads)
    if grep -rqE "(redis|memcached|cache|Cache|CDN|CloudFront)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.yaml" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "caching_enabled" "true"
        score=$((score + 1))
    fi

    # Check for compression
    if grep -rqE "(gzip|compression|brotli|deflate)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.yaml" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "compression" "true"
        score=$((score + 1))
    fi

    # Check for cleanup/expiry policies
    if grep -rqE "(ttl|TTL|expire|retention|lifecycle.*rule)" "$CODEBASE_PATH" \
        --include="*.yaml" --include="*.yml" --include="*.tf" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "expiry_policies" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Serverless & Compute Efficiency (Parameter 395)
# =============================================================================
check_compute() {
    progress_step "Compute efficiency"
    local score=5

    # Check for serverless
    if grep -rqE "(serverless|lambda|Lambda|functions|cloud.*function|@azure/functions)" "$CODEBASE_PATH" \
        --include="*.yaml" --include="*.yml" --include="*.json" --include="*.ts" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "serverless" "true"
        score=$((score + 2))
        echo "Scanning: Found serverless configuration" >&2
    fi

    # Check for connection pooling (database efficiency)
    if grep -rqE "(pool|Pool|connectionLimit|max.*connections)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.yaml" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "connection_pooling" "true"
        score=$((score + 1))
    fi

    # Check for batch processing
    if grep -rqE "(batch|Batch|bulk|bulkWrite|insertMany|executemany)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "batch_processing" "true"
        score=$((score + 1))
    fi

    # Check for async/queue-based processing
    if grep -rqE "(queue|Queue|sqs|rabbitmq|bull|celery)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "queue_processing" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Cost Monitoring (Parameter 398)
# =============================================================================
check_monitoring() {
    progress_step "Cost monitoring and visibility"
    local score=5

    # Check for cost tagging
    if grep -rqE "(tags|Tags|cost.*center|costCenter|billing|environment)" "$CODEBASE_PATH" \
        --include="*.tf" --include="*.yaml" --include="*.yml" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "resource_tagging" "true"
        score=$((score + 2))
        echo "Scanning: Found resource tagging" >&2
    fi

    # Check for budget alerts
    if grep -rqE "(budget|Budget|cost.*alert|billing.*alert)" "$CODEBASE_PATH" \
        --include="*.tf" --include="*.yaml" --include="*.yml" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "budget_alerts" "true"
        score=$((score + 2))
    fi

    # Check for monitoring/observability
    if grep -rqE "(prometheus|datadog|cloudwatch|newrelic|grafana)" "$CODEBASE_PATH" \
        --include="*.yaml" --include="*.yml" --include="*.json" --include="*.ts" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "monitoring_enabled" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Cost Efficiency Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local infra_score=$(check_infrastructure)
    local storage_score=$(check_storage)
    local compute_score=$(check_compute)
    local monitor_score=$(check_monitoring)

    # Weighted average
    local total_score=$(math_calc "$infra_score * 0.30 + $storage_score * 0.25 + $compute_score * 0.25 + $monitor_score * 0.20")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 10')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg is "$infra_score" \
        --arg ss "$storage_score" \
        --arg cs "$compute_score" \
        --arg ms "$monitor_score" \
        '.subscores = {
            infrastructure: ($is | tonumber),
            storage: ($ss | tonumber),
            compute: ($cs | tonumber),
            monitoring: ($ms | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Cost Efficiency Score: $total_score/10"
}

main
