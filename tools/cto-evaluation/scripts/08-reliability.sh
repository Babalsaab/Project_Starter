#!/bin/bash

# =============================================================================
# RELIABILITY & FAULT TOLERANCE EVALUATION (Parameters 253-274)
# =============================================================================
# Evaluates:
#   - Error Handling & Recovery (195-206)
#   - High Availability (207-216)
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

# Colors
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# Progress tracking
TOTAL_STEPS=5
CURRENT_STEP=0

progress_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "Evaluating: [$CURRENT_STEP/$TOTAL_STEPS] $1" >&2
}

RESULTS='{
    "category": "reliability",
    "parameters_evaluated": 0,
    "parameters_total": 22,
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
# Check Exception Handling (Parameters 218-219)
# =============================================================================
check_exception_handling() {
    progress_step "Exception handling patterns"
    local score=5

    # Count try-catch blocks
    local try_catch_count=$(grep -rcE "(try\s*{|try:|except|catch\s*\()" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=venv 2>/dev/null | \
        awk -F: '{sum += $2} END {print sum+0}')
    
    log_metric "try_catch_blocks" "$try_catch_count"
    echo "Scanning: Found $try_catch_count try-catch blocks" >&2

    if [ "$try_catch_count" -gt 50 ]; then
        score=8
    elif [ "$try_catch_count" -gt 20 ]; then
        score=6
    elif [ "$try_catch_count" -lt 5 ]; then
        add_finding "high" "error_handling" "Very few try-catch blocks found"
        score=3
    fi

    # Check for global error handlers
    if grep -rqE "(process\.on\('uncaughtException|process\.on\('unhandledRejection|@ExceptionHandler|app\.use\(.*err|errorHandler)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.java" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "global_error_handler" "true"
        score=$((score + 1))
        echo "Scanning: Found global error handler" >&2
    else
        add_finding "medium" "error_handling" "No global error handler found"
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Retry & Circuit Breaker (Parameters 220-221)
# =============================================================================
check_retry_patterns() {
    progress_step "Retry and circuit breaker patterns"
    local score=4

    # Check for retry patterns
    if grep -rqE "(retry|Retry|exponential.*backoff|backoff|retryWhen|@Retryable)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "retry_pattern" "true"
        score=$((score + 2))
        echo "Scanning: Found retry patterns" >&2
    else
        add_finding "medium" "reliability" "No retry logic found"
    fi

    # Check for circuit breaker
    if grep -rqE "(circuit.*breaker|CircuitBreaker|opossum|hystrix|resilience4j|cockatiel)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.java" --include="*.json" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "circuit_breaker" "true"
        score=$((score + 2))
        echo "Scanning: Found circuit breaker pattern" >&2
    else
        add_finding "medium" "reliability" "No circuit breaker pattern found"
    fi

    # Check for bulkhead pattern
    if grep -rqE "(bulkhead|Bulkhead|semaphore|Semaphore|rate.*limit|RateLimit)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "bulkhead_pattern" "true"
        score=$((score + 1))
        echo "Scanning: Found bulkhead/rate limiting" >&2
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Timeout Management (Parameter 200)
# =============================================================================
check_timeout_management() {
    progress_step "Timeout management"
    local score=5

    # Count timeout configurations
    local timeout_count=$(grep -rcE "(timeout|Timeout|TIMEOUT|deadline|connectTimeout|readTimeout|requestTimeout)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.java" --include="*.yaml" --include="*.env*" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
        awk -F: '{sum += $2} END {print sum+0}')
    
    log_metric "timeout_configurations" "$timeout_count"
    echo "Scanning: Found $timeout_count timeout configurations" >&2

    if [ "$timeout_count" -gt 20 ]; then
        score=9
    elif [ "$timeout_count" -gt 10 ]; then
        score=7
    elif [ "$timeout_count" -lt 3 ]; then
        add_finding "high" "reliability" "Very few timeout configurations - operations may hang"
        score=3
    fi

    # Check for request timeouts
    if grep -rqE "(AbortController|axios.*timeout|request.*timeout|http.*timeout)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "http_timeouts" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Graceful Degradation (Parameters 224-225)
# =============================================================================
check_graceful_degradation() {
    progress_step "Graceful degradation & fallbacks"
    local score=4

    # Check for fallback patterns
    if grep -rqE "(fallback|Fallback|default.*value|defaultValue|optional|getOrElse|orElse|coalesce)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "fallback_patterns" "true"
        score=$((score + 2))
        echo "Scanning: Found fallback patterns" >&2
    fi

    # Check for feature flags (for gradual degradation)
    if grep -rqE "(feature.*flag|featureFlag|FeatureToggle|launchdarkly|unleash|flagsmith|FEATURE_)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.java" --include="*.env*" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "feature_flags" "true"
        score=$((score + 2))
        echo "Scanning: Found feature flags" >&2
    fi

    # Check for health checks
    if grep -rqE "(health|Health|healthcheck|healthCheck|liveness|readiness|\/health|\/ready)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.yaml" --include="*.java" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "health_checks" "true"
        score=$((score + 1))
        echo "Scanning: Found health check endpoints" >&2
    else
        add_finding "high" "reliability" "No health check endpoints found"
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Idempotency & Transactions (Parameters 227-229)
# =============================================================================
check_idempotency() {
    progress_step "Idempotency and transaction management"
    local score=5

    # Check for idempotency patterns
    if grep -rqE "(idempotent|Idempotent|idempotency.*key|IdempotencyKey|X-Idempotency-Key)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "idempotency_pattern" "true"
        score=$((score + 2))
        echo "Scanning: Found idempotency patterns" >&2
    fi

    # Check for transaction management
    if grep -rqE "(transaction|Transaction|@Transactional|BEGIN|COMMIT|ROLLBACK|atomic|session\.begin)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "transaction_management" "true"
        score=$((score + 2))
        echo "Scanning: Found transaction management" >&2
    fi

    # Check for dead letter queue
    if grep -rqE "(dead.*letter|deadLetter|DLQ|dlq)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.yaml" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "dead_letter_queue" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Reliability Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local exception_score=$(check_exception_handling)
    local retry_score=$(check_retry_patterns)
    local timeout_score=$(check_timeout_management)
    local degradation_score=$(check_graceful_degradation)
    local idempotency_score=$(check_idempotency)

    # Weighted average
    local total_score=$(math_calc "$exception_score * 0.25 + $retry_score * 0.20 + $timeout_score * 0.20 + $degradation_score * 0.20 + $idempotency_score * 0.15")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 22')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg es "$exception_score" \
        --arg rs "$retry_score" \
        --arg ts "$timeout_score" \
        --arg ds "$degradation_score" \
        --arg is "$idempotency_score" \
        '.subscores = {
            exception_handling: ($es | tonumber),
            retry_patterns: ($rs | tonumber),
            timeout_management: ($ts | tonumber),
            graceful_degradation: ($ds | tonumber),
            idempotency: ($is | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Reliability Score: $total_score/10"
}

main
