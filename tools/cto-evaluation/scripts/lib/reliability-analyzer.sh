#!/bin/bash

# =============================================================================
# ENHANCED RELIABILITY ANALYZER
# =============================================================================
# Deep reliability analysis for codebases
# Detects: Error handling, fault tolerance, retry mechanisms, circuit breakers
# =============================================================================

# =============================================================================
# MAIN RELIABILITY ANALYSIS
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/search-utils.sh" ]; then
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/search-utils.sh"
fi

has_code_match() {
    local pattern="$1"
    local path="$2"
    if type grep_code_quiet >/dev/null 2>&1; then
        grep_code_quiet "$pattern" "$path"
    else
        grep -rq "$pattern" "$path" 2>/dev/null
    fi
}

analyze_reliability() {
    local codebase_path="$1"
    local output_dir="${2:-${TMPDIR:-/tmp}/reliability-analysis}"
    
    mkdir -p "$output_dir"
    
    local total_score=5
    
    # Run all reliability checks
    local error_handling=$(analyze_error_handling "$codebase_path" 2>/dev/null) || error_handling='{"score": 5}'
    local fault_tolerance=$(analyze_fault_tolerance "$codebase_path" 2>/dev/null) || fault_tolerance='{"score": 5}'
    local retry_mechanisms=$(analyze_retry_mechanisms "$codebase_path" 2>/dev/null) || retry_mechanisms='{"score": 3}'
    local graceful_degradation=$(analyze_graceful_degradation "$codebase_path" 2>/dev/null) || graceful_degradation='{"score": 3}'
    local data_validation=$(analyze_data_validation "$codebase_path" 2>/dev/null) || data_validation='{"score": 5}'
    
    # Validate JSON
    echo "$error_handling" | jq '.' >/dev/null 2>&1 || error_handling='{"score": 5}'
    echo "$fault_tolerance" | jq '.' >/dev/null 2>&1 || fault_tolerance='{"score": 5}'
    echo "$retry_mechanisms" | jq '.' >/dev/null 2>&1 || retry_mechanisms='{"score": 3}'
    echo "$graceful_degradation" | jq '.' >/dev/null 2>&1 || graceful_degradation='{"score": 3}'
    echo "$data_validation" | jq '.' >/dev/null 2>&1 || data_validation='{"score": 5}'
    
    # Extract scores
    local error_score=$(echo "$error_handling" | jq -r '.score // 5') || error_score=5
    local fault_score=$(echo "$fault_tolerance" | jq -r '.score // 5') || fault_score=5
    local retry_score=$(echo "$retry_mechanisms" | jq -r '.score // 3') || retry_score=3
    local degrade_score=$(echo "$graceful_degradation" | jq -r '.score // 3') || degrade_score=3
    local validation_score=$(echo "$data_validation" | jq -r '.score // 5') || validation_score=5
    
    # Weight scores (error handling most important)
    total_score=$(( (error_score * 3 + fault_score * 2 + retry_score + degrade_score + validation_score * 2) / 9 ))
    
    [ "$total_score" -lt 1 ] && total_score=1
    [ "$total_score" -gt 10 ] && total_score=10
    
    cat << EOF
{
    "overall_score": ${total_score:-5},
    "error_handling": $error_handling,
    "fault_tolerance": $fault_tolerance,
    "retry_mechanisms": $retry_mechanisms,
    "graceful_degradation": $graceful_degradation,
    "data_validation": $data_validation
}
EOF
}

# =============================================================================
# ERROR HANDLING ANALYSIS
# =============================================================================

analyze_error_handling() {
    local codebase_path="$1"
    local score=5
    local try_catch_count=0
    local error_handling_patterns=0
    local uncaught_exceptions=0
    
    # Count try-catch blocks
    try_catch_count=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.jsx" -o -name "*.tsx" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "try\s*{" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    # Python exception handling
    local python_except=$(find "$codebase_path" -type f -name "*.py" \
        ! -path "*/venv/*" ! -path "*/.git/*" \
        -exec grep -c "except\|raise" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    # Go error handling
    local go_errors=$(find "$codebase_path" -type f -name "*.go" \
        ! -path "*/vendor/*" ! -path "*/.git/*" \
        -exec grep -c "if err != nil" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    error_handling_patterns=$((try_catch_count + python_except + go_errors))
    
    # Check for global error handlers
    local global_handlers=0
    
    # Express error middleware
    if has_code_match "app.use.*err.*req.*res.*next|errorHandler" "$codebase_path"; then
        global_handlers=$((global_handlers + 1))
        score=$((score + 1))
    fi
    
    # React Error Boundaries
    if has_code_match "componentDidCatch|ErrorBoundary|error-boundary" "$codebase_path"; then
        global_handlers=$((global_handlers + 1))
        score=$((score + 1))
    fi
    
    # Check for proper error logging
    local error_logging=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "console.error\|logger.error\|logging.error\|log.Error" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "${error_logging:-0}" -gt 10 ] && score=$((score + 1))
    
    # Check for custom error classes
    local custom_errors=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "extends Error\|class.*Error\|class.*Exception" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "${custom_errors:-0}" -gt 3 ] && score=$((score + 1))
    
    # Penalize for empty catch blocks
    local empty_catch=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "catch.*{[[:space:]]*}" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "${empty_catch:-0}" -gt 5 ] && score=$((score - 1))
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-5},
    "try_catch_count": ${try_catch_count:-0},
    "error_handling_patterns": ${error_handling_patterns:-0},
    "global_error_handlers": ${global_handlers:-0},
    "error_logging_count": ${error_logging:-0},
    "custom_error_classes": ${custom_errors:-0},
    "empty_catch_blocks": ${empty_catch:-0}
}
EOF
}

# =============================================================================
# FAULT TOLERANCE ANALYSIS
# =============================================================================

analyze_fault_tolerance() {
    local codebase_path="$1"
    local score=4
    local has_circuit_breaker=false
    local has_bulkhead=false
    local has_timeout=false
    local has_fallback=false
    
    # Check for circuit breaker pattern
    if has_code_match "circuitbreaker|circuit-breaker|CircuitBreaker|opossum|resilience4j|hystrix|polly" "$codebase_path"; then
        has_circuit_breaker=true
        score=$((score + 2))
    fi
    
    # Check for bulkhead pattern
    if has_code_match "bulkhead|Bulkhead|semaphore|connection.?pool|pool.?size" "$codebase_path"; then
        has_bulkhead=true
        score=$((score + 1))
    fi
    
    # Check for timeout handling
    local timeout_count=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "timeout\|Timeout\|TIMEOUT\|context.WithTimeout\|asyncio.timeout" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "${timeout_count:-0}" -gt 5 ]; then
        has_timeout=true
        score=$((score + 1))
    fi
    
    # Check for fallback patterns
    if has_code_match "fallback|Fallback|default.*value|catch.*return|or_else|getOrDefault" "$codebase_path"; then
        has_fallback=true
        score=$((score + 1))
    fi
    
    # Check for health checks
    if has_code_match "health.*check|healthcheck|/health|/ready|/live|readinessProbe|livenessProbe" "$codebase_path"; then
        score=$((score + 1))
    fi
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-4},
    "has_circuit_breaker": $has_circuit_breaker,
    "has_bulkhead": $has_bulkhead,
    "has_timeout": $has_timeout,
    "timeout_patterns": ${timeout_count:-0},
    "has_fallback": $has_fallback
}
EOF
}

# =============================================================================
# RETRY MECHANISMS ANALYSIS
# =============================================================================

analyze_retry_mechanisms() {
    local codebase_path="$1"
    local score=3
    local has_retry=false
    local has_backoff=false
    local retry_count=0
    
    # Check for retry patterns
    retry_count=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.java" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
        -exec grep -c "retry\|Retry\|RETRY\|retries\|max.?attempts\|@Retryable" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "${retry_count:-0}" -gt 0 ]; then
        has_retry=true
        score=$((score + 2))
    fi
    
    # Check for exponential backoff
    if has_code_match "exponential.*backoff|ExponentialBackoff|backoff|jitter|sleep.*2\*\*" "$codebase_path"; then
        has_backoff=true
        score=$((score + 2))
    fi
    
    # Check for retry libraries
    if has_code_match "p-retry|async-retry|tenacity|backoff|retry-axios|got.?retry" "$codebase_path"; then
        score=$((score + 2))
    fi
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-3},
    "has_retry": $has_retry,
    "has_exponential_backoff": $has_backoff,
    "retry_patterns": ${retry_count:-0}
}
EOF
}

# =============================================================================
# GRACEFUL DEGRADATION ANALYSIS
# =============================================================================

analyze_graceful_degradation() {
    local codebase_path="$1"
    local score=3
    local has_feature_flags=false
    local has_graceful_shutdown=false
    local has_cache_fallback=false
    
    # Check for feature flags
    if has_code_match "feature.?flag|featureFlag|FeatureFlag|LaunchDarkly|split.io|unleash|flipper" "$codebase_path"; then
        has_feature_flags=true
        score=$((score + 2))
    fi
    
    # Check for graceful shutdown
    if has_code_match "graceful.*shutdown|SIGTERM|SIGINT|process.on.*exit|shutdown.?hook|@PreDestroy" "$codebase_path"; then
        has_graceful_shutdown=true
        score=$((score + 2))
    fi
    
    # Check for cache fallback
    if has_code_match "cache.*miss|cache.*fallback|stale.*while.*revalidate|getOrSet|cache.?aside" "$codebase_path"; then
        has_cache_fallback=true
        score=$((score + 2))
    fi
    
    # Check for service mesh / sidecar patterns
    if has_code_match "istio|envoy|linkerd|consul" "$codebase_path"; then
        score=$((score + 1))
    fi
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-3},
    "has_feature_flags": $has_feature_flags,
    "has_graceful_shutdown": $has_graceful_shutdown,
    "has_cache_fallback": $has_cache_fallback
}
EOF
}

# =============================================================================
# DATA VALIDATION ANALYSIS
# =============================================================================

analyze_data_validation() {
    local codebase_path="$1"
    local score=5
    local validation_patterns=0
    local has_schema_validation=false
    local has_input_validation=false
    
    # Check for validation libraries/patterns
    validation_patterns=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "validate\|Validate\|validator\|Validator\|@IsString\|@IsNumber\|@Valid" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "${validation_patterns:-0}" -gt 10 ] && score=$((score + 1))
    [ "${validation_patterns:-0}" -gt 30 ] && score=$((score + 1))
    
    # Check for schema validation (zod, yup, joi, etc.)
    if has_code_match "zod|yup|joi|ajv|class-validator|pydantic|marshmallow|cerberus" "$codebase_path"; then
        has_schema_validation=true
        score=$((score + 2))
    fi
    
    # Check for input sanitization
    if has_code_match "sanitize|escape|htmlspecialchars|DOMPurify|bleach" "$codebase_path"; then
        has_input_validation=true
        score=$((score + 1))
    fi
    
    # Check for type guards
    local type_guards=$(find "$codebase_path" -type f \( -name "*.ts" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "is.*:.*is\|typeof\|instanceof" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "${type_guards:-0}" -gt 20 ] && score=$((score + 1))
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-5},
    "validation_patterns": ${validation_patterns:-0},
    "has_schema_validation": $has_schema_validation,
    "has_input_sanitization": $has_input_validation,
    "type_guards": ${type_guards:-0}
}
EOF
}

# Export functions
export -f analyze_reliability analyze_error_handling analyze_fault_tolerance analyze_retry_mechanisms analyze_graceful_degradation analyze_data_validation
