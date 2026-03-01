#!/bin/bash

# =============================================================================
# ENHANCED OBSERVABILITY ANALYZER
# =============================================================================
# Deep analysis of logging, monitoring, tracing, and alerting
# Supports: OpenTelemetry, Prometheus, Datadog, New Relic, etc.
# =============================================================================

# =============================================================================
# MAIN OBSERVABILITY ANALYSIS
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/search-utils.sh" ]; then
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/search-utils.sh"
fi

count_matches() {
    local pattern="$1"
    local path="$2"
    shift 2
    if type grep_code_count >/dev/null 2>&1; then
        grep_code_count "$pattern" "$path" "$@"
    else
        { grep -R -n -E "$@" "$pattern" "$path" 2>/dev/null || true; } | wc -l | tr -d ' '
    fi
}

analyze_observability() {
    local codebase_path="$1"
    local output_dir="${2:-${TMPDIR:-/tmp}/observability-analysis}"
    
    mkdir -p "$output_dir"
    
    # Run all observability checks
    local logging_result=$(check_logging_practices "$codebase_path")
    local metrics_result=$(check_metrics_implementation "$codebase_path")
    local tracing_result=$(check_distributed_tracing "$codebase_path")
    local alerting_result=$(check_alerting_config "$codebase_path")
    local health_result=$(check_health_endpoints "$codebase_path")
    local error_result=$(check_error_tracking "$codebase_path")
    
    # Calculate scores
    local logging_score=$(echo "$logging_result" | jq -r '.score // 5')
    local metrics_score=$(echo "$metrics_result" | jq -r '.score // 5')
    local tracing_score=$(echo "$tracing_result" | jq -r '.score // 5')
    local health_score=$(echo "$health_result" | jq -r '.score // 5')
    local error_score=$(echo "$error_result" | jq -r '.score // 5')
    
    local overall_score=$(( (logging_score + metrics_score + tracing_score + health_score + error_score) / 5 ))
    
    cat << EOF
{
    "overall_score": $overall_score,
    "logging_analysis": $logging_result,
    "metrics_analysis": $metrics_result,
    "tracing_analysis": $tracing_result,
    "alerting_analysis": $alerting_result,
    "health_analysis": $health_result,
    "error_tracking": $error_result
}
EOF
}

# =============================================================================
# LOGGING PRACTICES CHECK
# =============================================================================

check_logging_practices() {
    local codebase_path="$1"
    local score=5
    local good_practices=0
    local bad_practices=0
    
    # Check for structured logging
    local structured_logging=0
    
    # JavaScript structured logging (winston, pino, bunyan)
    local js_structured=$(count_matches "winston|pino|bunyan|log4js" "$codebase_path" --include=*.js --include=*.ts)
    
    [ "$js_structured" -gt 0 ] && structured_logging=$((structured_logging + 1))
    
    # Python structured logging
    local python_structured=$(count_matches "structlog|loguru|python-json-logger" "$codebase_path" --include=*.py)
    
    [ "$python_structured" -gt 0 ] && structured_logging=$((structured_logging + 1))
    
    # Go structured logging
    local go_structured=$(count_matches "zap|logrus|zerolog" "$codebase_path" --include=*.go)
    
    [ "$go_structured" -gt 0 ] && structured_logging=$((structured_logging + 1))
    
    [ "$structured_logging" -gt 0 ] && good_practices=$((good_practices + 2))
    
    # Check for log levels usage
    local log_levels=$(count_matches "\\.debug|\\.info|\\.warn|\\.error|log\\.Debug|log\\.Info|log\\.Warn|log\\.Error" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$log_levels" -gt 10 ] && good_practices=$((good_practices + 1))
    
    # Check for console.log in production code (bad practice)
    local console_logs=$(count_matches "console\\.log" "$codebase_path" --include=*.js --include=*.ts --include=*.jsx --include=*.tsx --exclude=*test* --exclude=*spec*)
    
    if [ "$console_logs" -gt 20 ]; then
        bad_practices=$((bad_practices + 2))
    elif [ "$console_logs" -gt 5 ]; then
        bad_practices=$((bad_practices + 1))
    fi
    
    # Check for print statements in Python (bad practice)
    local print_statements=$(count_matches "^[[:space:]]*print\\(" "$codebase_path" --include=*.py --exclude=*test*)
    
    if [ "$print_statements" -gt 10 ]; then
        bad_practices=$((bad_practices + 1))
    fi
    
    # Check for correlation IDs / request IDs
    local correlation_ids=$(count_matches "correlationId|requestId|traceId|x-request-id|X-Request-ID" "$codebase_path" --include=*.js --include=*.ts --include=*.py)
    
    [ "$correlation_ids" -gt 0 ] && good_practices=$((good_practices + 2))
    
    # Check for log aggregation configuration
    local log_aggregation=$(count_matches "elasticsearch|logstash|fluentd|datadog|splunk|cloudwatch" "$codebase_path" --include=*.yaml --include=*.yml --include=*.json --include=*.js --include=*.ts)
    
    [ "$log_aggregation" -gt 0 ] && good_practices=$((good_practices + 1))
    
    # Check for sensitive data in logs (bad practice)
    local sensitive_logging=$(count_matches "log.*password|log.*token|log.*secret|logger.*password" "$codebase_path" --include=*.js --include=*.ts --include=*.py)
    
    if [ "$sensitive_logging" -gt 0 ]; then
        bad_practices=$((bad_practices + 2))
    fi
    
    # Calculate score
    score=$((5 + good_practices - bad_practices))
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "good_practices": $good_practices,
    "bad_practices": $bad_practices,
    "structured_logging": $([ "$structured_logging" -gt 0 ] && echo "true" || echo "false"),
    "correlation_ids": $([ "$correlation_ids" -gt 0 ] && echo "true" || echo "false"),
    "log_aggregation": $([ "$log_aggregation" -gt 0 ] && echo "true" || echo "false"),
    "console_logs_count": $console_logs
}
EOF
}

# =============================================================================
# METRICS IMPLEMENTATION CHECK
# =============================================================================

check_metrics_implementation() {
    local codebase_path="$1"
    local score=5
    local implementations=0
    
    # Check for Prometheus metrics
    local prometheus=$(count_matches "prom-client|prometheus_client|prometheus|Counter|Gauge|Histogram|Summary" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$prometheus" -gt 0 ] && implementations=$((implementations + 2))
    
    # Check for StatsD
    local statsd=$(count_matches "statsd|StatsD|hot-shots" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$statsd" -gt 0 ] && implementations=$((implementations + 1))
    
    # Check for custom metrics
    local custom_metrics=$(count_matches "metric|\\.increment|\\.gauge|\\.timing|recordMetric" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$custom_metrics" -gt 5 ] && implementations=$((implementations + 1))
    
    # Check for OpenTelemetry metrics
    local otel_metrics=$(count_matches "@opentelemetry/sdk-metrics|opentelemetry\\.metrics|otel.*metrics" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$otel_metrics" -gt 0 ] && implementations=$((implementations + 2))
    
    # Check for APM tools
    local apm=$(count_matches "datadog|newrelic|dynatrace|appdynamics|elastic-apm" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.yaml --include=*.yml)
    
    [ "$apm" -gt 0 ] && implementations=$((implementations + 2))
    
    # Check for /metrics endpoint
    local metrics_endpoint=$(count_matches '"/metrics"|/metrics|@app\\.route.*/metrics' "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$metrics_endpoint" -gt 0 ] && implementations=$((implementations + 1))
    
    # Check for business metrics
    local business_metrics=$(count_matches "orders_total|revenue|users_active|conversion|latency_seconds|request_duration" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$business_metrics" -gt 0 ] && implementations=$((implementations + 1))
    
    score=$((4 + implementations))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "implementations": $implementations,
    "prometheus": $([ "$prometheus" -gt 0 ] && echo "true" || echo "false"),
    "opentelemetry": $([ "$otel_metrics" -gt 0 ] && echo "true" || echo "false"),
    "apm_tools": $([ "$apm" -gt 0 ] && echo "true" || echo "false"),
    "metrics_endpoint": $([ "$metrics_endpoint" -gt 0 ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# DISTRIBUTED TRACING CHECK
# =============================================================================

check_distributed_tracing() {
    local codebase_path="$1"
    local score=5
    local implementations=0
    
    # Check for OpenTelemetry tracing
    local otel_tracing=$(count_matches "@opentelemetry/api|opentelemetry|tracer\\.start|trace\\.get_tracer" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$otel_tracing" -gt 0 ] && implementations=$((implementations + 3))
    
    # Check for Jaeger
    local jaeger=$(count_matches "jaeger|JAEGER|jaeger-client" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go --include=*.yaml --include=*.yml)
    
    [ "$jaeger" -gt 0 ] && implementations=$((implementations + 2))
    
    # Check for Zipkin
    local zipkin=$(count_matches "zipkin|ZIPKIN" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go --include=*.yaml --include=*.yml)
    
    [ "$zipkin" -gt 0 ] && implementations=$((implementations + 2))
    
    # Check for AWS X-Ray
    local xray=$(count_matches "aws-xray|AWSXRay|X-Ray" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go --include=*.yaml --include=*.yml)
    
    [ "$xray" -gt 0 ] && implementations=$((implementations + 2))
    
    # Check for span creation
    local span_usage=$(count_matches "startSpan|start_span|WithSpan|tracer\\.Start" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$span_usage" -gt 3 ] && implementations=$((implementations + 1))
    
    # Check for trace context propagation
    local context_propagation=$(count_matches "traceparent|tracestate|propagate|inject|extract" "$codebase_path" --include=*.js --include=*.ts --include=*.py)
    
    [ "$context_propagation" -gt 0 ] && implementations=$((implementations + 1))
    
    # Check for automatic instrumentation
    local auto_instrumentation=$(count_matches "auto-instrumentations|registerInstrumentations|instrument_all" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$auto_instrumentation" -gt 0 ] && implementations=$((implementations + 1))
    
    score=$((3 + implementations))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "implementations": $implementations,
    "opentelemetry": $([ "$otel_tracing" -gt 0 ] && echo "true" || echo "false"),
    "jaeger": $([ "$jaeger" -gt 0 ] && echo "true" || echo "false"),
    "zipkin": $([ "$zipkin" -gt 0 ] && echo "true" || echo "false"),
    "aws_xray": $([ "$xray" -gt 0 ] && echo "true" || echo "false"),
    "span_usage": $span_usage,
    "context_propagation": $([ "$context_propagation" -gt 0 ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# ALERTING CONFIGURATION CHECK
# =============================================================================

check_alerting_config() {
    local codebase_path="$1"
    local score=5
    local configurations=0
    
    # Check for Prometheus alerting rules
    local prom_alerts=$(count_matches "alert:|AlertManager|alertmanager" "$codebase_path" --include=*.yaml --include=*.yml)
    
    [ "$prom_alerts" -gt 0 ] && configurations=$((configurations + 2))
    
    # Check for PagerDuty integration
    local pagerduty=$(count_matches "pagerduty|PAGERDUTY|PagerDuty" "$codebase_path" --include=*.yaml --include=*.yml --include=*.json --include=*.js --include=*.ts)
    
    [ "$pagerduty" -gt 0 ] && configurations=$((configurations + 1))
    
    # Check for Slack alerting
    local slack_alerts=$(count_matches "slack.*webhook|SLACK_WEBHOOK|slack_url" "$codebase_path" --include=*.yaml --include=*.yml --include=*.json --include=*.js --include=*.ts)
    
    [ "$slack_alerts" -gt 0 ] && configurations=$((configurations + 1))
    
    # Check for OpsGenie
    local opsgenie=$(count_matches "opsgenie|OpsGenie|OPSGENIE" "$codebase_path" --include=*.yaml --include=*.yml --include=*.json)
    
    [ "$opsgenie" -gt 0 ] && configurations=$((configurations + 1))
    
    # Check for CloudWatch Alarms (AWS)
    local cloudwatch=$(count_matches "CloudWatch.*Alarm|cloudwatch.*alarm|AWS::CloudWatch::Alarm" "$codebase_path" --include=*.yaml --include=*.yml --include=*.json)
    
    [ "$cloudwatch" -gt 0 ] && configurations=$((configurations + 1))
    
    # Check for Grafana alerting
    local grafana=$(count_matches "grafana.*alert|alertRules|alert_rules" "$codebase_path" --include=*.json --include=*.yaml --include=*.yml)
    
    [ "$grafana" -gt 0 ] && configurations=$((configurations + 1))
    
    # Check for on-call configuration
    local oncall=$(count_matches "oncall|on-call|escalation" "$codebase_path" --include=*.yaml --include=*.yml --include=*.json)
    
    [ "$oncall" -gt 0 ] && configurations=$((configurations + 1))
    
    score=$((4 + configurations))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "configurations": $configurations,
    "prometheus_alerts": $([ "$prom_alerts" -gt 0 ] && echo "true" || echo "false"),
    "pagerduty": $([ "$pagerduty" -gt 0 ] && echo "true" || echo "false"),
    "slack": $([ "$slack_alerts" -gt 0 ] && echo "true" || echo "false"),
    "cloudwatch": $([ "$cloudwatch" -gt 0 ] && echo "true" || echo "false"),
    "grafana": $([ "$grafana" -gt 0 ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# HEALTH ENDPOINTS CHECK
# =============================================================================

check_health_endpoints() {
    local codebase_path="$1"
    local score=5
    local endpoints=0
    
    # Check for /health endpoint
    local health_endpoint=$(count_matches '"/health"|/health|@app\\.route.*/health|/healthz|/healthcheck' "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go --include=*.java)
    
    [ "$health_endpoint" -gt 0 ] && endpoints=$((endpoints + 2))
    
    # Check for /ready endpoint
    local ready_endpoint=$(count_matches '"/ready"|/readiness|/readyz' "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$ready_endpoint" -gt 0 ] && endpoints=$((endpoints + 2))
    
    # Check for /live endpoint
    local live_endpoint=$(count_matches '"/live"|/liveness|/livez' "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$live_endpoint" -gt 0 ] && endpoints=$((endpoints + 2))
    
    # Check for Kubernetes probes
    local k8s_probes=$(count_matches "livenessProbe:|readinessProbe:|startupProbe:" "$codebase_path" --include=*.yaml --include=*.yml)
    
    [ "$k8s_probes" -gt 0 ] && endpoints=$((endpoints + 1))
    
    # Check for health check libraries
    local health_libs=$(count_matches "@godaddy/terminus|health-check|django-health-check|flask-healthz" "$codebase_path" --include=*.js --include=*.ts --include=*.py)
    
    [ "$health_libs" -gt 0 ] && endpoints=$((endpoints + 1))
    
    # Check for database health checks
    local db_health=$(count_matches "db.*ping|database.*check|SELECT 1|\\.raw.*SELECT" "$codebase_path" --include=*.js --include=*.ts --include=*.py)
    
    [ "$db_health" -gt 0 ] && endpoints=$((endpoints + 1))
    
    score=$((3 + endpoints))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "endpoints": $endpoints,
    "health": $([ "$health_endpoint" -gt 0 ] && echo "true" || echo "false"),
    "ready": $([ "$ready_endpoint" -gt 0 ] && echo "true" || echo "false"),
    "live": $([ "$live_endpoint" -gt 0 ] && echo "true" || echo "false"),
    "k8s_probes": $([ "$k8s_probes" -gt 0 ] && echo "true" || echo "false"),
    "db_health": $([ "$db_health" -gt 0 ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# ERROR TRACKING CHECK
# =============================================================================

check_error_tracking() {
    local codebase_path="$1"
    local score=5
    local implementations=0
    
    # Check for Sentry
    local sentry=$(count_matches "@sentry/|sentry-sdk|sentry_sdk|Sentry\\.init|sentry\\.Init" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$sentry" -gt 0 ] && implementations=$((implementations + 3))
    
    # Check for Bugsnag
    local bugsnag=$(count_matches "bugsnag|Bugsnag" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$bugsnag" -gt 0 ] && implementations=$((implementations + 2))
    
    # Check for Rollbar
    local rollbar=$(count_matches "rollbar|Rollbar" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$rollbar" -gt 0 ] && implementations=$((implementations + 2))
    
    # Check for error boundaries (React)
    local error_boundaries=$(count_matches "ErrorBoundary|componentDidCatch|getDerivedStateFromError" "$codebase_path" --include=*.jsx --include=*.tsx)
    
    [ "$error_boundaries" -gt 0 ] && implementations=$((implementations + 1))
    
    # Check for global error handlers
    local global_handlers=$(count_matches "process\\.on.*uncaughtException|process\\.on.*unhandledRejection|window\\.onerror" "$codebase_path" --include=*.js --include=*.ts)
    
    [ "$global_handlers" -gt 0 ] && implementations=$((implementations + 1))
    
    # Check for contextual error info
    local error_context=$(count_matches "setContext|setUser|setExtra|setTags|captureException.*context" "$codebase_path" --include=*.js --include=*.ts --include=*.py)
    
    [ "$error_context" -gt 2 ] && implementations=$((implementations + 1))
    
    score=$((3 + implementations))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "implementations": $implementations,
    "sentry": $([ "$sentry" -gt 0 ] && echo "true" || echo "false"),
    "bugsnag": $([ "$bugsnag" -gt 0 ] && echo "true" || echo "false"),
    "rollbar": $([ "$rollbar" -gt 0 ] && echo "true" || echo "false"),
    "error_boundaries": $([ "$error_boundaries" -gt 0 ] && echo "true" || echo "false"),
    "global_handlers": $([ "$global_handlers" -gt 0 ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# SLO/SLI CHECK
# =============================================================================

check_slo_sli() {
    local codebase_path="$1"
    local implementations=0
    
    # Check for SLO definitions
    local slo_definitions=$(count_matches "slo|SLO|service.*level.*objective" "$codebase_path" --include=*.yaml --include=*.yml --include=*.json)
    
    [ "$slo_definitions" -gt 0 ] && implementations=$((implementations + 1))
    
    # Check for error budget tracking
    local error_budget=$(count_matches "error.*budget|error_budget|burn.*rate" "$codebase_path" --include=*.yaml --include=*.yml --include=*.json)
    
    [ "$error_budget" -gt 0 ] && implementations=$((implementations + 1))
    
    # Check for latency percentiles
    local latency_percentiles=$(count_matches "p99|p95|p50|percentile|histogram_quantile" "$codebase_path" --include=*.yaml --include=*.yml --include=*.json)
    
    [ "$latency_percentiles" -gt 0 ] && implementations=$((implementations + 1))
    
    # Check for availability tracking
    local availability=$(count_matches "availability|uptime|success.*rate|error.*rate" "$codebase_path" --include=*.yaml --include=*.yml --include=*.json)
    
    [ "$availability" -gt 0 ] && implementations=$((implementations + 1))
    
    cat << EOF
{
    "implementations": $implementations,
    "slo_definitions": $([ "$slo_definitions" -gt 0 ] && echo "true" || echo "false"),
    "error_budget": $([ "$error_budget" -gt 0 ] && echo "true" || echo "false"),
    "latency_percentiles": $([ "$latency_percentiles" -gt 0 ] && echo "true" || echo "false"),
    "availability": $([ "$availability" -gt 0 ] && echo "true" || echo "false")
}
EOF
}
