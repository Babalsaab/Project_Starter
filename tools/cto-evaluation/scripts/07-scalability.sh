#!/bin/bash

# =============================================================================
# SCALABILITY EVALUATION (Parameters 235-252)
# =============================================================================
# Evaluates:
#   - Horizontal Scaling (177-186)
#   - Vertical Scaling & Optimization (187-194)
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
source "$SCRIPT_DIR/common-progress.sh" 2>/dev/null || true
source "$SCRIPT_DIR/common-findings.sh"
source "$SCRIPT_DIR/lib/math-utils.sh"
init_findings

# Colors
CYAN='\033[0;36m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Progress tracking
TOTAL_STEPS=5
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

RESULTS='{
    "category": "scalability",
    "parameters_evaluated": 0,
    "parameters_total": 18,
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
# Check Stateless Design (Parameter 177)
# =============================================================================
check_stateless_design() {
    progress_step "Stateless design patterns"
    local score=5
    local found_files=0

    # Check for session usage patterns
    if grep -rqE "(express-session|session\.|req\.session|flask.session)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=venv 2>/dev/null; then
        
        # Check if sessions are externalized (Redis, etc.)
        if grep -rqE "(connect-redis|redis-store|RedisStore|SESSION_REDIS)" "$CODEBASE_PATH" \
            --include="*.js" --include="*.ts" --include="*.py" --include="*.env*" \
            --exclude-dir=node_modules 2>/dev/null; then
            log_metric "session_externalized" "true"
            score=8
            echo "Scanning: Found externalized session storage" >&2
        else
            log_metric "session_externalized" "false"
            add_finding "high" "stateless" "Sessions stored locally - prevents horizontal scaling"
            score=4
        fi
    else
        log_metric "session_externalized" "n/a"
        score=7
    fi

    # Check for file-based storage (anti-pattern for scalability)
    local file_storage=$(grep -rcE "(fs\.write|writeFileSync|open\(.*'w'\)|with open)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=test* 2>/dev/null | \
        awk -F: '{sum += $2} END {print sum+0}')
    
    log_metric "file_write_operations" "$file_storage"
    
    if [ "$file_storage" -gt 20 ]; then
        add_finding "medium" "stateless" "Heavy file system writes may impede scaling"
        score=$((score - 1))
    fi

    echo "$score"
}

# =============================================================================
# Check Database Scaling Readiness (Parameters 202-203)
# =============================================================================
check_database_scaling() {
    progress_step "Database scaling patterns"
    local score=5

    # Check for read replica configuration
    if grep -rqE "(readReplica|read_replica|slave|secondary|REPLICA_HOST)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.yaml" --include="*.json" --include="*.env*" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "read_replicas" "true"
        score=$((score + 2))
        echo "Scanning: Found read replica configuration" >&2
    fi

    # Check for sharding patterns
    if grep -rqE "(shard|partition|hashKey|shardKey)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.yaml" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "sharding_ready" "true"
        score=$((score + 1))
        echo "Scanning: Found sharding patterns" >&2
    fi

    # Check for connection pooling
    if grep -rqE "(connectionPool|pool|maxConnections|poolSize|max_connections)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.yaml" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "connection_pooling" "true"
        score=$((score + 1))
        echo "Scanning: Found connection pooling" >&2
    else
        add_finding "medium" "database" "No connection pooling detected"
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Caching Scalability (Parameter 180)
# =============================================================================
check_cache_scaling() {
    progress_step "Cache scaling patterns"
    local score=5

    # Check for Redis/Memcached (distributed cache)
    if grep -rqE "(redis|ioredis|memcached|elasticache)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.json" --include="*.yaml" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "distributed_cache" "true"
        score=8
        echo "Scanning: Found distributed cache implementation" >&2

        # Check for cache cluster configuration
        if grep -rqE "(cluster|CLUSTER|sentinels|Sentinel)" "$CODEBASE_PATH" \
            --include="*.js" --include="*.ts" --include="*.py" --include="*.yaml" --include="*.env*" \
            --exclude-dir=node_modules 2>/dev/null; then
            log_metric "cache_cluster" "true"
            score=9
        fi
    else
        # Check for in-memory cache (not scalable)
        if grep -rqE "(node-cache|memory-cache|lru-cache|@cache)" "$CODEBASE_PATH" \
            --include="*.js" --include="*.ts" --include="*.py" \
            --exclude-dir=node_modules 2>/dev/null; then
            log_metric "local_cache_only" "true"
            add_finding "medium" "cache" "Using local in-memory cache - consider distributed cache for scaling"
            score=5
        else
            log_metric "distributed_cache" "false"
            add_finding "low" "cache" "No caching implementation found"
        fi
    fi

    echo "$score"
}

# =============================================================================
# Check Queue/Message Scaling (Parameter 181)
# =============================================================================
check_queue_scaling() {
    progress_step "Message queue scaling"
    local score=5

    # Check for message queues
    if grep -rqE "(rabbitmq|amqp|kafka|bull|bee-queue|sqs|pubsub)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.json" --include="*.yaml" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "message_queue" "true"
        score=8
        echo "Scanning: Found message queue implementation" >&2

        # Check for multiple consumers pattern
        if grep -rqE "(consumer|Consumer|subscriber|Subscriber|prefetch|concurrency)" "$CODEBASE_PATH" \
            --include="*.js" --include="*.ts" --include="*.py" \
            --exclude-dir=node_modules 2>/dev/null; then
            score=$((score + 1))
        fi
    else
        log_metric "message_queue" "false"
        add_finding "low" "scaling" "No message queue found - async processing may not scale"
    fi

    # Check for CDN usage (Parameter 183)
    if grep -rqE "(cloudfront|cdn|CloudFront|CDN_URL|fastly|akamai)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.yaml" --include="*.env*" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "cdn_usage" "true"
        score=$((score + 1))
        echo "Scanning: Found CDN configuration" >&2
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Resource Optimization (Parameters 210-217)
# =============================================================================
check_resource_optimization() {
    progress_step "Resource optimization patterns"
    local score=5

    # Check for memory optimization patterns
    if grep -rqE "(stream|Stream|pipe|Pipe|BufferedReader|generator|yield)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=test* 2>/dev/null; then
        log_metric "streaming_used" "true"
        score=$((score + 1))
        echo "Scanning: Found streaming patterns" >&2
    fi

    # Check for worker threads/multiprocessing
    if grep -rqE "(worker_threads|Worker|cluster|multiprocessing|ProcessPoolExecutor|ThreadPoolExecutor)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "parallel_processing" "true"
        score=$((score + 2))
        echo "Scanning: Found parallel processing patterns" >&2
    fi

    # Check for batch processing patterns
    if grep -rqE "(batch|Batch|bulkWrite|bulk_create|executemany|insertMany)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "batch_processing" "true"
        score=$((score + 1))
        echo "Scanning: Found batch processing patterns" >&2
    fi

    # Check for object pooling
    if grep -rqE "(pool|Pool|reuse|objectPool)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "object_pooling" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Scalability Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local stateless_score=$(check_stateless_design)
    local db_score=$(check_database_scaling)
    local cache_score=$(check_cache_scaling)
    local queue_score=$(check_queue_scaling)
    local resource_score=$(check_resource_optimization)

    # Weighted average
    local total_score=$(math_calc "$stateless_score * 0.25 + $db_score * 0.20 + $cache_score * 0.20 + $queue_score * 0.20 + $resource_score * 0.15")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 18')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg ss "$stateless_score" \
        --arg ds "$db_score" \
        --arg cs "$cache_score" \
        --arg qs "$queue_score" \
        --arg rs "$resource_score" \
        '.subscores = {
            stateless_design: ($ss | tonumber),
            database_scaling: ($ds | tonumber),
            cache_scaling: ($cs | tonumber),
            queue_scaling: ($qs | tonumber),
            resource_optimization: ($rs | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Scalability Score: $total_score/10"
}

main
