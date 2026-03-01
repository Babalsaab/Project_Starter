#!/bin/bash

# =============================================================================
# ENHANCED SCALABILITY ANALYZER
# =============================================================================
# Deep scalability analysis for codebases
# Detects: Horizontal scaling, statelessness, caching, async processing
# =============================================================================

# =============================================================================
# MAIN SCALABILITY ANALYSIS
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

analyze_scalability() {
    local codebase_path="$1"
    local output_dir="${2:-${TMPDIR:-/tmp}/scalability-analysis}"
    
    mkdir -p "$output_dir"
    
    local total_score=5
    
    # Run all scalability checks
    local horizontal_result=$(analyze_horizontal_scaling "$codebase_path" 2>/dev/null) || horizontal_result='{"score": 5}'
    local stateless_result=$(analyze_statelessness "$codebase_path" 2>/dev/null) || stateless_result='{"score": 5}'
    local caching_result=$(analyze_caching_strategy "$codebase_path" 2>/dev/null) || caching_result='{"score": 3}'
    local async_result=$(analyze_async_processing "$codebase_path" 2>/dev/null) || async_result='{"score": 5}'
    local database_result=$(analyze_database_scaling "$codebase_path" 2>/dev/null) || database_result='{"score": 5}'
    
    # Validate JSON
    echo "$horizontal_result" | jq '.' >/dev/null 2>&1 || horizontal_result='{"score": 5}'
    echo "$stateless_result" | jq '.' >/dev/null 2>&1 || stateless_result='{"score": 5}'
    echo "$caching_result" | jq '.' >/dev/null 2>&1 || caching_result='{"score": 3}'
    echo "$async_result" | jq '.' >/dev/null 2>&1 || async_result='{"score": 5}'
    echo "$database_result" | jq '.' >/dev/null 2>&1 || database_result='{"score": 5}'
    
    # Extract scores
    local horizontal_score=$(echo "$horizontal_result" | jq -r '.score // 5') || horizontal_score=5
    local stateless_score=$(echo "$stateless_result" | jq -r '.score // 5') || stateless_score=5
    local caching_score=$(echo "$caching_result" | jq -r '.score // 3') || caching_score=3
    local async_score=$(echo "$async_result" | jq -r '.score // 5') || async_score=5
    local database_score=$(echo "$database_result" | jq -r '.score // 5') || database_score=5
    
    # Calculate overall score
    total_score=$(( (horizontal_score + stateless_score + caching_score + async_score + database_score) / 5 ))
    
    [ "$total_score" -lt 1 ] && total_score=1
    [ "$total_score" -gt 10 ] && total_score=10
    
    cat << EOF
{
    "overall_score": ${total_score:-5},
    "horizontal_scaling": $horizontal_result,
    "statelessness": $stateless_result,
    "caching_strategy": $caching_result,
    "async_processing": $async_result,
    "database_scaling": $database_result
}
EOF
}

# =============================================================================
# HORIZONTAL SCALING ANALYSIS
# =============================================================================

analyze_horizontal_scaling() {
    local codebase_path="$1"
    local score=5
    local has_containerization=false
    local has_orchestration=false
    local has_load_balancer_config=false
    local has_auto_scaling=false
    
    # Check for containerization
    if [ -f "$codebase_path/Dockerfile" ] || [ -f "$codebase_path/docker-compose.yml" ] || find "$codebase_path" -maxdepth 3 -name "Dockerfile*" 2>/dev/null | grep -q .; then
        has_containerization=true
        score=$((score + 1))
    fi
    
    # Check for orchestration
    if find "$codebase_path" -maxdepth 5 \( -name "*.yaml" -o -name "*.yml" \) -exec grep -l "kind:.*Deployment\|kind:.*Pod\|kind:.*Service" {} \; 2>/dev/null | grep -q .; then
        has_orchestration=true
        score=$((score + 2))
    fi
    
    # Check for Helm charts
    if [ -d "$codebase_path/charts" ] || [ -f "$codebase_path/Chart.yaml" ]; then
        score=$((score + 1))
    fi
    
    # Check for load balancer configuration
    if has_code_match "loadBalancer|LoadBalancer|upstream|proxy_pass|nginx.*server|haproxy" "$codebase_path"; then
        has_load_balancer_config=true
        score=$((score + 1))
    fi
    
    # Check for auto-scaling config
    if has_code_match "HorizontalPodAutoscaler|autoscaling|auto-scaling|scale.?out|scale.?in|minReplicas|maxReplicas" "$codebase_path"; then
        has_auto_scaling=true
        score=$((score + 1))
    fi
    
    # Check for replicas configuration
    if has_code_match "replicas:|replica.?count|instances:" "$codebase_path"; then
        score=$((score + 1))
    fi
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-5},
    "has_containerization": $has_containerization,
    "has_orchestration": $has_orchestration,
    "has_load_balancer": $has_load_balancer_config,
    "has_auto_scaling": $has_auto_scaling
}
EOF
}

# =============================================================================
# STATELESSNESS ANALYSIS
# =============================================================================

analyze_statelessness() {
    local codebase_path="$1"
    local score=7
    local stateful_patterns=0
    local has_external_session=false
    local has_external_cache=false
    
    # Check for in-memory session storage (bad for scaling)
    local memory_session=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "MemoryStore\|session.memory\|in.?memory.?session\|sessions\s*=\s*{}" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "${memory_session:-0}" -gt 0 ] && {
        stateful_patterns=$((stateful_patterns + memory_session))
        score=$((score - 2))
    }
    
    # Check for external session storage (good)
    if has_code_match "redis.*session|connect-redis|session.*store.*redis|RedisSessionStore|SESSION_REDIS" "$codebase_path"; then
        has_external_session=true
        score=$((score + 1))
    fi
    
    # Check for external cache
    if has_code_match "redis|memcached|elasticache|cache.?provider" "$codebase_path"; then
        has_external_cache=true
        score=$((score + 1))
    fi
    
    # Check for file-based state (bad for scaling)
    local file_state=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "fs.writeFileSync\|localStorage\|writeFile.*state\|json.dump.*state" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "${file_state:-0}" -gt 3 ] && score=$((score - 1))
    
    # Check for global mutable state (bad)
    local global_state=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "global\.\|window\.\|globalThis\." {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "${global_state:-0}" -gt 10 ] && score=$((score - 1))
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-5},
    "stateful_patterns": ${stateful_patterns:-0},
    "has_external_session": $has_external_session,
    "has_external_cache": $has_external_cache,
    "file_state_patterns": ${file_state:-0},
    "global_state_patterns": ${global_state:-0}
}
EOF
}

# =============================================================================
# CACHING STRATEGY ANALYSIS
# =============================================================================

analyze_caching_strategy() {
    local codebase_path="$1"
    local score=3
    local has_redis=false
    local has_memcached=false
    local has_cdn=false
    local has_http_caching=false
    local has_query_caching=false
    
    # Check for Redis
    if has_code_match "redis|Redis|REDIS|ioredis|redis-cli" "$codebase_path"; then
        has_redis=true
        score=$((score + 2))
    fi
    
    # Check for Memcached
    if has_code_match "memcached|Memcached|MEMCACHED" "$codebase_path"; then
        has_memcached=true
        score=$((score + 1))
    fi
    
    # Check for CDN configuration
    if has_code_match "cloudfront|CloudFront|fastly|akamai|cloudflare|CDN|cdn.?url" "$codebase_path"; then
        has_cdn=true
        score=$((score + 1))
    fi
    
    # Check for HTTP caching headers
    if has_code_match "Cache-Control|cache-control|ETag|etag|Last-Modified|max-age|stale-while-revalidate" "$codebase_path"; then
        has_http_caching=true
        score=$((score + 1))
    fi
    
    # Check for query/ORM caching
    if has_code_match "query.?cache|QueryCache|@Cacheable|cache_page|lru_cache|memoize|useMemo" "$codebase_path"; then
        has_query_caching=true
        score=$((score + 1))
    fi
    
    # Check for caching patterns
    local cache_patterns=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "cache.get\|cache.set\|getFromCache\|setCache\|cache.fetch" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "${cache_patterns:-0}" -gt 5 ] && score=$((score + 1))
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-3},
    "has_redis": $has_redis,
    "has_memcached": $has_memcached,
    "has_cdn": $has_cdn,
    "has_http_caching": $has_http_caching,
    "has_query_caching": $has_query_caching,
    "cache_patterns": ${cache_patterns:-0}
}
EOF
}

# =============================================================================
# ASYNC PROCESSING ANALYSIS
# =============================================================================

analyze_async_processing() {
    local codebase_path="$1"
    local score=5
    local has_message_queue=false
    local has_background_jobs=false
    local has_event_driven=false
    local async_patterns=0
    
    # Check for message queues
    if has_code_match "rabbitmq|RabbitMQ|amqp|AMQP|kafka|Kafka|sqs|SQS|bull|Bull|celery|Celery|sidekiq|Sidekiq" "$codebase_path"; then
        has_message_queue=true
        score=$((score + 2))
    fi
    
    # Check for background job processing
    if has_code_match "agenda|bee-queue|bull|kue|resque|delayed_job|background.?job|BackgroundJob|@Async|asyncio.create_task" "$codebase_path"; then
        has_background_jobs=true
        score=$((score + 1))
    fi
    
    # Check for event-driven patterns
    if has_code_match "EventEmitter|EventBus|eventbus|pub.?sub|publish|subscribe|on.*event|emit" "$codebase_path"; then
        has_event_driven=true
        score=$((score + 1))
    fi
    
    # Count async/await patterns
    async_patterns=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "async\|await\|Promise\|asyncio" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "${async_patterns:-0}" -gt 50 ] && score=$((score + 1))
    
    # Check for worker threads
    if has_code_match "Worker|worker_threads|multiprocessing|threading|goroutine" "$codebase_path"; then
        score=$((score + 1))
    fi
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-5},
    "has_message_queue": $has_message_queue,
    "has_background_jobs": $has_background_jobs,
    "has_event_driven": $has_event_driven,
    "async_patterns": ${async_patterns:-0}
}
EOF
}

# =============================================================================
# DATABASE SCALING ANALYSIS
# =============================================================================

analyze_database_scaling() {
    local codebase_path="$1"
    local score=5
    local has_read_replicas=false
    local has_sharding=false
    local has_connection_pooling=false
    local has_indexes=false
    
    # Check for read replicas
    if has_code_match "read.?replica|ReadReplica|slave|secondary.*host|reader.*endpoint" "$codebase_path"; then
        has_read_replicas=true
        score=$((score + 2))
    fi
    
    # Check for sharding
    if has_code_match "shard|Shard|partition|Partition" "$codebase_path"; then
        has_sharding=true
        score=$((score + 1))
    fi
    
    # Check for connection pooling
    if has_code_match "pool|Pool|poolSize|pool_size|maxConnections|max_connections|pgbouncer" "$codebase_path"; then
        has_connection_pooling=true
        score=$((score + 1))
    fi
    
    # Check for database indexes in migrations/schemas
    local index_definitions=$(find "$codebase_path" -type f \( -name "*.sql" -o -name "*migration*" \) \
        -exec grep -c "CREATE INDEX\|add_index\|createIndex\|@Index" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "${index_definitions:-0}" -gt 5 ]; then
        has_indexes=true
        score=$((score + 1))
    fi
    
    # Check for NoSQL usage (often better for scaling)
    if has_code_match "mongodb|MongoDB|dynamodb|DynamoDB|cassandra|Cassandra|couchbase" "$codebase_path"; then
        score=$((score + 1))
    fi
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-5},
    "has_read_replicas": $has_read_replicas,
    "has_sharding": $has_sharding,
    "has_connection_pooling": $has_connection_pooling,
    "has_indexes": $has_indexes,
    "index_definitions": ${index_definitions:-0}
}
EOF
}

# Export functions
export -f analyze_scalability analyze_horizontal_scaling analyze_statelessness analyze_caching_strategy analyze_async_processing analyze_database_scaling
