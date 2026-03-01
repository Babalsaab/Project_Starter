#!/bin/bash

# =============================================================================
# ENHANCED PERFORMANCE ANALYZER
# =============================================================================
# Deep performance analysis for codebases
# Detects: Memory issues, N+1 queries, bundle size, caching, async patterns
# =============================================================================

# =============================================================================
# MAIN PERFORMANCE ANALYSIS
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

count_files() {
    local pattern="$1"
    local path="$2"
    shift 2
    if type grep_code >/dev/null 2>&1; then
        { grep_code "$pattern" "$path" -l "$@" || true; } | wc -l | tr -d ' '
    else
        { grep -R -n -E -l "$@" "$pattern" "$path" 2>/dev/null || true; } | wc -l | tr -d ' '
    fi
}

has_code_match() {
    local pattern="$1"
    local path="$2"
    shift 2
    if type grep_code_quiet >/dev/null 2>&1; then
        grep_code_quiet "$pattern" "$path" "$@"
    else
        grep -R -n -E -q "$@" "$pattern" "$path" 2>/dev/null
    fi
}

list_files_with_match() {
    local pattern="$1"
    local path="$2"
    shift 2
    if type grep_code >/dev/null 2>&1; then
        grep_code "$pattern" "$path" -l "$@"
    else
        grep -R -n -E -l "$@" "$pattern" "$path" 2>/dev/null
    fi
}

analyze_performance() {
    local codebase_path="$1"
    local output_dir="${2:-${TMPDIR:-/tmp}/performance-analysis}"
    
    mkdir -p "$output_dir"
    
    local total_score=10
    local issues_found=0
    
    # Run all performance checks with default fallbacks
    local memory_result=$(check_memory_issues "$codebase_path" 2>/dev/null) || memory_result='{"issues_count": 0}'
    local query_result=$(check_database_performance "$codebase_path" 2>/dev/null) || query_result='{"issues_count": 0}'
    local bundle_result=$(check_bundle_optimization "$codebase_path" 2>/dev/null) || bundle_result='{"issues_count": 0}'
    local caching_result=$(check_caching_patterns "$codebase_path" 2>/dev/null) || caching_result='{"score": 5}'
    local async_result=$(check_async_patterns "$codebase_path" 2>/dev/null) || async_result='{"score": 5}'
    local resource_result=$(check_resource_management "$codebase_path" 2>/dev/null) || resource_result='{"score": 5}'
    local lazy_result=$(check_lazy_loading "$codebase_path" 2>/dev/null) || lazy_result='{"detected": false}'
    
    # Validate JSON and provide defaults
    echo "$memory_result" | jq '.' >/dev/null 2>&1 || memory_result='{"issues_count": 0}'
    echo "$query_result" | jq '.' >/dev/null 2>&1 || query_result='{"issues_count": 0}'
    echo "$bundle_result" | jq '.' >/dev/null 2>&1 || bundle_result='{"issues_count": 0}'
    echo "$caching_result" | jq '.' >/dev/null 2>&1 || caching_result='{"score": 5}'
    echo "$async_result" | jq '.' >/dev/null 2>&1 || async_result='{"score": 5}'
    echo "$resource_result" | jq '.' >/dev/null 2>&1 || resource_result='{"score": 5}'
    echo "$lazy_result" | jq '.' >/dev/null 2>&1 || lazy_result='{"detected": false}'
    
    # Calculate issues with safe defaults
    local memory_issues=$(echo "$memory_result" | jq -r '.issues_count // 0' 2>/dev/null) || memory_issues=0
    local query_issues=$(echo "$query_result" | jq -r '.issues_count // 0' 2>/dev/null) || query_issues=0
    local bundle_issues=$(echo "$bundle_result" | jq -r '.issues_count // 0' 2>/dev/null) || bundle_issues=0
    local caching_score=$(echo "$caching_result" | jq -r '.score // 5' 2>/dev/null) || caching_score=5
    local async_score=$(echo "$async_result" | jq -r '.score // 5' 2>/dev/null) || async_score=5
    
    # Ensure numeric values
    memory_issues=${memory_issues:-0}
    query_issues=${query_issues:-0}
    bundle_issues=${bundle_issues:-0}
    caching_score=${caching_score:-5}
    async_score=${async_score:-5}
    
    issues_found=$((memory_issues + query_issues + bundle_issues))
    
    # Calculate overall score
    total_score=$((total_score - issues_found))
    total_score=$(( (total_score + caching_score + async_score) / 3 ))
    
    [ "$total_score" -lt 1 ] && total_score=1
    [ "$total_score" -gt 10 ] && total_score=10
    
    cat << EOF
{
    "overall_score": $total_score,
    "memory_analysis": $memory_result,
    "database_analysis": $query_result,
    "bundle_analysis": $bundle_result,
    "caching_analysis": $caching_result,
    "async_analysis": $async_result,
    "resource_analysis": $resource_result,
    "lazy_loading": $lazy_result
}
EOF
}

# =============================================================================
# MEMORY ISSUES DETECTION
# =============================================================================

check_memory_issues() {
    local codebase_path="$1"
    local issues_count=0
    local findings='[]'
    
    # Check for memory leaks in JavaScript
    # Event listeners without cleanup
    local event_leaks=$(list_files_with_match "addEventListener" "$codebase_path" \
        --include=*.js --include=*.jsx --include=*.ts --include=*.tsx)
    
    for file in $event_leaks; do
        # Check if there's removeEventListener
        if ! grep -q "removeEventListener" "$file" 2>/dev/null; then
            issues_count=$((issues_count + 1))
            local relative_path="${file#$codebase_path/}"
            findings=$(echo "$findings" | jq --arg f "$relative_path" \
                '. + [{"file": $f, "type": "potential_event_listener_leak"}]')
        fi
    done
    
    # Check for setInterval without cleanup
    local interval_leaks=$(list_files_with_match "setInterval" "$codebase_path" \
        --include=*.js --include=*.jsx --include=*.ts --include=*.tsx)
    
    for file in $interval_leaks; do
        if ! grep -q "clearInterval" "$file" 2>/dev/null; then
            issues_count=$((issues_count + 1))
        fi
    done
    
    # Check for large array operations without pagination
    local large_array_ops=$(count_matches "\\.map|\\.filter|\\.reduce" "$codebase_path" --include=*.js --include=*.ts)
    
    # Check for proper cleanup in React useEffect
    local react_effects=$(count_matches "useEffect" "$codebase_path" --include=*.jsx --include=*.tsx)
    
    local effects_with_cleanup=$(count_matches "useEffect.*return\\s*\\(\\)" "$codebase_path" --include=*.jsx --include=*.tsx)
    
    if [ "$react_effects" -gt 0 ]; then
        local cleanup_ratio=$((effects_with_cleanup * 100 / react_effects))
        if [ "$cleanup_ratio" -lt 30 ]; then
            issues_count=$((issues_count + 1))
        fi
    fi
    
    # Python memory issues
    local python_global_lists=$(count_matches "^[A-Z_]*\\s*=\\s*\\[\\]" "$codebase_path" --include=*.py)
    
    if [ "$python_global_lists" -gt 5 ]; then
        issues_count=$((issues_count + 1))
    fi
    
    # Go memory issues - check for defer in loops
    local go_defer_loop=$(count_files "defer" "$codebase_path" --include=*.go)
    
    issues_count=$((issues_count + go_defer_loop))
    
    cat << EOF
{
    "issues_count": ${issues_count:-0},
    "array_operations": ${large_array_ops:-0},
    "react_effects": ${react_effects:-0},
    "effects_cleanup_ratio": ${cleanup_ratio:-0},
    "findings": ${findings:-[]}
}
EOF
}

# =============================================================================
# DATABASE PERFORMANCE CHECK
# =============================================================================

check_database_performance() {
    local codebase_path="$1"
    local issues_count=0
    local n_plus_one_risk=0
    local missing_indexes=0
    
    # Check for N+1 query patterns in ORM usage
    
    # JavaScript/TypeScript (Prisma, TypeORM, Sequelize)
    local js_n_plus_one=$(count_matches "\\.findMany|\\.findAll" "$codebase_path" --include=*.js --include=*.ts)
    
    # Check for includes/joins
    local js_eager_loading=$(count_matches "include:|\\.include|\\.populate|relations:" "$codebase_path" --include=*.js --include=*.ts)
    
    if [ "$js_n_plus_one" -gt "$js_eager_loading" ]; then
        n_plus_one_risk=$((n_plus_one_risk + 1))
    fi
    
    # Python (Django, SQLAlchemy)
    local python_n_plus_one=$(count_matches "\\.objects\\.all|\\.query\\.all|session\\.query" "$codebase_path" --include=*.py)
    
    local python_prefetch=$(count_matches "select_related|prefetch_related|joinedload|subqueryload" "$codebase_path" --include=*.py)
    
    if [ "$python_n_plus_one" -gt 0 ] && [ "$python_prefetch" -eq 0 ]; then
        n_plus_one_risk=$((n_plus_one_risk + 2))
    fi
    
    # Ruby (ActiveRecord)
    local ruby_n_plus_one=$(count_matches "\\.all|\\.each|\\.map" "$codebase_path" --include=*.rb)
    
    local ruby_includes=$(count_matches "\\.includes|\\.preload|\\.eager_load" "$codebase_path" --include=*.rb)
    
    if [ "$ruby_n_plus_one" -gt "$((ruby_includes * 3))" ]; then
        n_plus_one_risk=$((n_plus_one_risk + 1))
    fi
    
    # Check for missing database indexes
    # Look for queries on fields without apparent indexes
    local queries_without_index=$(count_matches "findBy|where|filter|ORDER BY" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.rb)
    
    # Check for index definitions
    local index_definitions=$(count_matches "CREATE INDEX|INDEX|@@index|add_index|db_index" "$codebase_path" --include=*.sql --include=*migration* --include=*schema*)
    
    if [ "$queries_without_index" -gt "$((index_definitions * 5))" ]; then
        missing_indexes=$((missing_indexes + 1))
    fi
    
    # Check for unbounded queries
    local unbounded_queries=$(count_matches "\\.findMany\\(\\)|\\.all\\(\\)|SELECT \\* FROM" "$codebase_path" --include=*.js --include=*.ts --include=*.py)
    
    local pagination_usage=$(count_matches "take:|limit|LIMIT|skip:|offset|paginate|per_page" "$codebase_path" --include=*.js --include=*.ts --include=*.py)
    
    if [ "$unbounded_queries" -gt "$pagination_usage" ]; then
        issues_count=$((issues_count + 1))
    fi
    
    issues_count=$((issues_count + n_plus_one_risk + missing_indexes))
    
    cat << EOF
{
    "issues_count": ${issues_count:-0},
    "n_plus_one_risk": ${n_plus_one_risk:-0},
    "missing_indexes": ${missing_indexes:-0},
    "unbounded_queries": ${unbounded_queries:-0},
    "pagination_usage": ${pagination_usage:-0}
}
EOF
}

# =============================================================================
# BUNDLE OPTIMIZATION CHECK
# =============================================================================

check_bundle_optimization() {
    local codebase_path="$1"
    local issues_count=0
    local optimizations_found=0
    
    # Check for code splitting
    if [ -f "$codebase_path/package.json" ]; then
        cd "$codebase_path"
        
        # React lazy loading
        local react_lazy=$(count_matches "React\\.lazy|lazy\\(" "$codebase_path" --include=*.jsx --include=*.tsx)
        
        # Dynamic imports
        local dynamic_imports=$(count_matches "import\\(" "$codebase_path" --include=*.js --include=*.ts --include=*.jsx --include=*.tsx)
        
        [ "$react_lazy" -gt 0 ] && optimizations_found=$((optimizations_found + 1))
        [ "$dynamic_imports" -gt 3 ] && optimizations_found=$((optimizations_found + 1))
        
        # Check for tree shaking support
        if grep -q '"sideEffects"' package.json 2>/dev/null; then
            optimizations_found=$((optimizations_found + 1))
        fi
        
        # Check for bundle analyzer
        if grep -qE '"webpack-bundle-analyzer"|"rollup-plugin-visualizer"|"source-map-explorer"' package.json 2>/dev/null; then
            optimizations_found=$((optimizations_found + 1))
        fi
        
        # Check for minification
        if grep -qE '"terser"|"uglify"|"esbuild"' package.json 2>/dev/null; then
            optimizations_found=$((optimizations_found + 1))
        fi
        
        # Check for large dependencies that should be avoided
        local large_deps=0
        for dep in "moment" "lodash" "jquery" "rxjs"; do
            if grep -q "\"$dep\"" package.json 2>/dev/null; then
                # Check if alternatives are used
                case $dep in
                    moment) 
                        if ! grep -qE '"dayjs"|"date-fns"|"luxon"' package.json 2>/dev/null; then
                            large_deps=$((large_deps + 1))
                        fi
                        ;;
                    lodash)
                        # Check if using lodash-es or individual imports
                        if ! grep -q '"lodash-es"' package.json 2>/dev/null; then
                            if ! has_code_match "from 'lodash/" "$codebase_path" --include=*.js --include=*.ts; then
                                large_deps=$((large_deps + 1))
                            fi
                        fi
                        ;;
                esac
            fi
        done
        
        issues_count=$((issues_count + large_deps))
        
        # Check for image optimization
        local has_image_opt=false
        if grep -qE '"next/image"|"gatsby-image"|"sharp"|"imagemin"' package.json 2>/dev/null; then
            has_image_opt=true
            optimizations_found=$((optimizations_found + 1))
        fi
        
        cd - > /dev/null
    fi
    
    # Check Next.js specific optimizations
    if [ -f "$codebase_path/next.config.js" ] || [ -f "$codebase_path/next.config.mjs" ]; then
        local next_config=$(find "$codebase_path" -maxdepth 1 -name "next.config.*" | head -1)
        
        # Check for image optimization config
        if grep -q "images:" "$next_config" 2>/dev/null; then
            optimizations_found=$((optimizations_found + 1))
        fi
        
        # Check for webpack config
        if grep -q "webpack:" "$next_config" 2>/dev/null; then
            optimizations_found=$((optimizations_found + 1))
        fi
    fi
    
    cat << EOF
{
    "issues_count": $issues_count,
    "optimizations_found": $optimizations_found,
    "code_splitting": $dynamic_imports,
    "react_lazy": ${react_lazy:-0}
}
EOF
}

# =============================================================================
# CACHING PATTERNS CHECK
# =============================================================================

check_caching_patterns() {
    local codebase_path="$1"
    local score=5
    local caching_implementations=0
    
    # Check for Redis/Memcached usage
    local has_redis=$(count_files "redis|ioredis|Redis|REDIS" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go --include=*.rb)
    
    local has_memcached=$(count_files "memcached|Memcached" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go --include=*.rb)
    
    [ "$has_redis" -gt 0 ] && caching_implementations=$((caching_implementations + 1))
    [ "$has_memcached" -gt 0 ] && caching_implementations=$((caching_implementations + 1))
    
    # Check for application-level caching
    local app_cache=$(count_matches "node-cache|lru-cache|cache-manager" "$codebase_path" --include=*.js --include=*.ts)
    
    [ "$app_cache" -gt 0 ] && caching_implementations=$((caching_implementations + 1))
    
    # Check for HTTP caching headers
    local http_caching=$(count_matches "Cache-Control|ETag|Last-Modified|max-age" "$codebase_path" --include=*.js --include=*.ts --include=*.py)
    
    [ "$http_caching" -gt 2 ] && caching_implementations=$((caching_implementations + 1))
    
    # Check for React/frontend caching
    local react_cache=$(count_matches "useMemo|useCallback|React\\.memo|memo\\(" "$codebase_path" --include=*.jsx --include=*.tsx)
    
    [ "$react_cache" -gt 5 ] && caching_implementations=$((caching_implementations + 1))
    
    # Check for query caching (React Query, SWR, Apollo)
    local query_cache=$(count_matches "useQuery|useSWR|useApolloClient|QueryClient" "$codebase_path" --include=*.js --include=*.ts --include=*.jsx --include=*.tsx)
    
    [ "$query_cache" -gt 0 ] && caching_implementations=$((caching_implementations + 1))
    
    # Check Django caching
    local django_cache=$(count_matches "@cache_page|cache\\.get|cache\\.set" "$codebase_path" --include=*.py)
    
    [ "$django_cache" -gt 0 ] && caching_implementations=$((caching_implementations + 1))
    
    # Calculate score based on implementations
    score=$((5 + caching_implementations))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "caching_implementations": $caching_implementations,
    "has_redis": $([ "$has_redis" -gt 0 ] && echo "true" || echo "false"),
    "http_caching": $http_caching,
    "react_memoization": $react_cache,
    "query_caching": $query_cache
}
EOF
}

# =============================================================================
# ASYNC PATTERNS CHECK
# =============================================================================

check_async_patterns() {
    local codebase_path="$1"
    local score=5
    local good_patterns=0
    local bad_patterns=0
    
    # JavaScript/TypeScript async patterns
    if [ -f "$codebase_path/package.json" ]; then
        # Check for proper async/await usage
        local async_await=$(count_matches "async.*await|await " "$codebase_path" --include=*.js --include=*.ts)
        
        # Check for unhandled promises
        local unhandled_promises=$(count_matches "\\.then\\(|new Promise" "$codebase_path" --include=*.js --include=*.ts)
        
        local catch_handlers=$(count_matches "\\.catch\\(|try.*catch" "$codebase_path" --include=*.js --include=*.ts)
        
        if [ "$async_await" -gt "$unhandled_promises" ]; then
            good_patterns=$((good_patterns + 1))
        fi
        
        if [ "$catch_handlers" -gt "$((unhandled_promises / 2))" ]; then
            good_patterns=$((good_patterns + 1))
        else
            bad_patterns=$((bad_patterns + 1))
        fi
        
        # Check for Promise.all for parallel execution
        local parallel_promises=$(count_matches "Promise\\.all|Promise\\.allSettled|Promise\\.race" "$codebase_path" --include=*.js --include=*.ts)
        
        [ "$parallel_promises" -gt 0 ] && good_patterns=$((good_patterns + 1))
        
        # Check for sequential awaits that could be parallel
        local sequential_awaits=$(count_matches "await.*await" "$codebase_path" --include=*.js --include=*.ts)
        
        if [ "$sequential_awaits" -gt 10 ] && [ "$parallel_promises" -lt 3 ]; then
            bad_patterns=$((bad_patterns + 1))
        fi
    fi
    
    # Python async patterns
    local python_async=$(count_matches "async def|await " "$codebase_path" --include=*.py)
    
    local python_asyncio=$(count_matches "asyncio|aiohttp|aiomysql|aiopg" "$codebase_path" --include=*.py)
    
    [ "$python_async" -gt 0 ] && [ "$python_asyncio" -gt 0 ] && good_patterns=$((good_patterns + 1))
    
    # Go goroutines and channels
    local go_goroutines=$(count_matches "go func|<-|chan " "$codebase_path" --include=*.go)
    
    local go_waitgroup=$(count_matches "sync\\.WaitGroup|errgroup" "$codebase_path" --include=*.go)
    
    if [ "$go_goroutines" -gt 0 ] && [ "$go_waitgroup" -gt 0 ]; then
        good_patterns=$((good_patterns + 1))
    elif [ "$go_goroutines" -gt 5 ] && [ "$go_waitgroup" -eq 0 ]; then
        bad_patterns=$((bad_patterns + 1))
    fi
    
    # Calculate score
    score=$((5 + good_patterns - bad_patterns))
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "good_patterns": $good_patterns,
    "bad_patterns": $bad_patterns,
    "async_await_usage": ${async_await:-0},
    "parallel_promises": ${parallel_promises:-0},
    "python_async": $python_async,
    "go_goroutines": $go_goroutines
}
EOF
}

# =============================================================================
# RESOURCE MANAGEMENT CHECK
# =============================================================================

check_resource_management() {
    local codebase_path="$1"
    local issues=0
    local good_practices=0
    
    # Check for connection pooling
    local connection_pools=$(count_matches "pool|Pool|connectionLimit|max_connections|SetMaxOpenConns" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go --include=*.java)
    
    [ "$connection_pools" -gt 0 ] && good_practices=$((good_practices + 1))
    
    # Check for file handle management
    local file_operations=$(count_matches "open\\(" "$codebase_path" --include=*.py)
    
    local with_statements=$(count_matches "with open" "$codebase_path" --include=*.py)
    
    if [ "$file_operations" -gt 0 ]; then
        if [ "$with_statements" -ge "$((file_operations * 80 / 100))" ]; then
            good_practices=$((good_practices + 1))
        else
            issues=$((issues + 1))
        fi
    fi
    
    # Check Go defer for cleanup
    local go_defer=$(count_matches "defer.*Close|defer.*Unlock|defer.*Done" "$codebase_path" --include=*.go)
    
    [ "$go_defer" -gt 0 ] && good_practices=$((good_practices + 1))
    
    # Check for timeout configurations
    local timeouts=$(count_matches "timeout|Timeout|TIMEOUT" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$timeouts" -gt 3 ] && good_practices=$((good_practices + 1))
    
    # Check for graceful shutdown
    local graceful_shutdown=$(count_matches "SIGTERM|SIGINT|graceful.*shutdown|process\\.on.*exit" "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.go)
    
    [ "$graceful_shutdown" -gt 0 ] && good_practices=$((good_practices + 1))
    
    cat << EOF
{
    "issues": $issues,
    "good_practices": $good_practices,
    "connection_pools": $connection_pools,
    "timeouts_configured": $timeouts,
    "graceful_shutdown": $([ "$graceful_shutdown" -gt 0 ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# LAZY LOADING CHECK
# =============================================================================

check_lazy_loading() {
    local codebase_path="$1"
    local implementations=0
    
    # React lazy loading
    local react_lazy=$(count_matches "React\\.lazy|Suspense" "$codebase_path" --include=*.jsx --include=*.tsx)
    
    [ "$react_lazy" -gt 0 ] && implementations=$((implementations + 1))
    
    # Vue async components
    local vue_async=$(count_matches "defineAsyncComponent|\\(\\) => import\\(" "$codebase_path" --include=*.vue)
    
    [ "$vue_async" -gt 0 ] && implementations=$((implementations + 1))
    
    # Angular lazy routes
    local angular_lazy=$(count_matches "loadChildren.*import\\(" "$codebase_path" --include=*.ts)
    
    [ "$angular_lazy" -gt 0 ] && implementations=$((implementations + 1))
    
    # Image lazy loading
    local img_lazy=$(count_matches 'loading="lazy"|lazy-load|lazyload' "$codebase_path" --include=*.jsx --include=*.tsx --include=*.vue --include=*.html)
    
    [ "$img_lazy" -gt 0 ] && implementations=$((implementations + 1))
    
    # Virtual scrolling
    local virtual_scroll=$(count_matches "react-virtualized|react-window|virtual-scroll|cdk-virtual-scroll" "$codebase_path" --include=*.js --include=*.ts --include=*.jsx --include=*.tsx)
    
    [ "$virtual_scroll" -gt 0 ] && implementations=$((implementations + 1))
    
    cat << EOF
{
    "implementations": $implementations,
    "react_lazy": $react_lazy,
    "vue_async": $vue_async,
    "angular_lazy": $angular_lazy,
    "image_lazy": $img_lazy,
    "virtual_scroll": $virtual_scroll
}
EOF
}

# =============================================================================
# API PERFORMANCE CHECK
# =============================================================================

check_api_performance() {
    local codebase_path="$1"
    local score=5
    local optimizations=0
    
    # Check for GraphQL batching/DataLoader
    local dataloader=$(count_matches "DataLoader|dataloader" "$codebase_path" --include=*.js --include=*.ts)
    
    [ "$dataloader" -gt 0 ] && optimizations=$((optimizations + 1))
    
    # Check for response compression
    local compression=$(count_matches "compression|gzip|brotli" "$codebase_path" --include=*.js --include=*.ts)
    
    [ "$compression" -gt 0 ] && optimizations=$((optimizations + 1))
    
    # Check for response streaming
    local streaming=$(count_matches "pipe|stream|createReadStream" "$codebase_path" --include=*.js --include=*.ts)
    
    [ "$streaming" -gt 3 ] && optimizations=$((optimizations + 1))
    
    # Check for query optimization (field selection)
    local field_selection=$(count_matches "select:|\\.select\\(|fields:" "$codebase_path" --include=*.js --include=*.ts)
    
    [ "$field_selection" -gt 0 ] && optimizations=$((optimizations + 1))
    
    score=$((5 + optimizations))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "optimizations": $optimizations,
    "dataloader": $dataloader,
    "compression": $compression,
    "streaming": $streaming
}
EOF
}
