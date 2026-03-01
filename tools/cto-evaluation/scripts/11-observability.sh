#!/bin/bash

# =============================================================================
# OBSERVABILITY EVALUATION (Parameters 423-446)
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
    "category": "observability",
    "parameters_evaluated": 0,
    "parameters_total": 24,
    "score": 0,
    "findings": [],
    "metrics": {}
}'

log_metric() {
    RESULTS=$(echo "$RESULTS" | jq --arg n "$1" --arg v "$2" '.metrics[$n] = $v')
}

# add_finding is now provided by common-findings.sh with location support
# add_finding "severity" "parameter" "message" "location"

# Check logging implementation
check_logging() {
    progress_step "Logging implementation"
    local score=5

    # Check for logging libraries
    local has_winston=$(grep -rq "winston" "$CODEBASE_PATH" --include="*.json" --exclude-dir=node_modules 2>/dev/null && echo "true" || echo "false")
    local has_pino=$(grep -rq "pino" "$CODEBASE_PATH" --include="*.json" --exclude-dir=node_modules 2>/dev/null && echo "true" || echo "false")
    local has_bunyan=$(grep -rq "bunyan" "$CODEBASE_PATH" --include="*.json" --exclude-dir=node_modules 2>/dev/null && echo "true" || echo "false")

    if [ "$has_winston" = "true" ] || [ "$has_pino" = "true" ] || [ "$has_bunyan" = "true" ]; then
        log_metric "structured_logging_library" "true"
        score=8
    else
        # Check for basic console.log usage
        local console_logs=$(grep -rc "console.log\|console.error" "$CODEBASE_PATH" \
            --include="*.js" --include="*.ts" \
            --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
            awk -F: '{sum += $2} END {print sum}' || echo "0")

        log_metric "console_log_count" "$console_logs"

        if [ "$console_logs" -gt 50 ]; then
            add_finding "medium" "logging" "Heavy console.log usage - consider structured logging"
            score=4
        fi
    fi

    # Check for log levels
    if grep -rqE "(log.info|log.warn|log.error|log.debug|logger.info)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "log_levels_used" "true"
        score=$((score + 1))
    fi

    # Check for correlation IDs
    if grep -rqE "(correlationId|correlation_id|requestId|request_id|traceId|trace_id)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "correlation_ids" "true"
        score=$((score + 1))
    else
        add_finding "medium" "logging" "No correlation ID implementation found"
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# Check monitoring/metrics
check_metrics() {
    echo "  Checking metrics implementation..." >&2
    local score=4

    # Check for Prometheus client
    if grep -rqE "(prom-client|prometheus|statsd|datadog)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.py" --include="*.go" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "metrics_library" "true"
        score=8
    else
        add_finding "medium" "metrics" "No metrics/monitoring library found"
    fi

    # Check for custom metrics
    if grep -rqE "(counter|gauge|histogram|summary)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "custom_metrics" "true"
        score=$((score + 1))
    fi

    # Check for health endpoints
    if grep -rqE "(/health|/healthz|/ready|/readiness|/liveness)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "health_endpoints" "true"
        score=$((score + 1))
    else
        add_finding "medium" "health_checks" "No health check endpoints found"
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# Check tracing
check_tracing() {
    echo "  Checking distributed tracing..." >&2
    local score=4

    # Check for tracing libraries
    if grep -rqE "(opentelemetry|jaeger|zipkin|@opentelemetry|dd-trace)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.py" --include="*.go" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "tracing_library" "true"
        score=9
    else
        add_finding "low" "tracing" "No distributed tracing implementation found"
    fi

    # Check for span creation
    if grep -rqE "(startSpan|createSpan|tracer.start)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "custom_spans" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# Check error tracking
check_error_tracking() {
    echo "  Checking error tracking..." >&2
    local score=5

    # Check for error tracking services
    if grep -rqE "(sentry|bugsnag|rollbar|airbrake|@sentry)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.py" --include="*.go" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "error_tracking_service" "true"
        score=9
    else
        add_finding "medium" "error_tracking" "No error tracking service configured"
    fi

    # Check for error boundaries (React)
    if grep -rqE "(ErrorBoundary|componentDidCatch)" "$CODEBASE_PATH" \
        --include="*.jsx" --include="*.tsx" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "error_boundaries" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

main() {
    echo "Starting Observability Evaluation..."

    local logging_score=$(check_logging)
    local metrics_score=$(check_metrics)
    local tracing_score=$(check_tracing)
    local error_score=$(check_error_tracking)

    local total_score=$(math_calc "$logging_score * 0.35 + $metrics_score * 0.25 + $tracing_score * 0.20 + $error_score * 0.20")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 24')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg ls "$logging_score" --arg ms "$metrics_score" --arg ts "$tracing_score" --arg es "$error_score" \
        '.subscores = {logging: ($ls | tonumber), metrics: ($ms | tonumber), tracing: ($ts | tonumber), error_tracking: ($es | tonumber)}')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Observability Score: $total_score/10"
}

main
