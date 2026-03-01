#!/bin/bash

# =============================================================================
# INNOVATION & FUTURE-READINESS EVALUATION (Parameters 457-468)
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
    "category": "innovation",
    "parameters_evaluated": 0,
    "parameters_total": 12,
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
# Check Technology Currency (Parameters 422-424)
# =============================================================================
check_tech_currency() {
    progress_step "Technology currency"
    local score=5

    # Check Node.js version (if applicable)
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        local node_version=$(jq -r '.engines.node // ""' "$CODEBASE_PATH/package.json" 2>/dev/null)
        if [ -n "$node_version" ]; then
            log_metric "node_version_spec" "$node_version"
            # Check if it's a recent version (18+)
            if echo "$node_version" | grep -qE "(18|20|21|22)"; then
                score=$((score + 1))
            fi
        fi
    fi

    # Check TypeScript version
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        local ts_version=$(jq -r '.devDependencies.typescript // .dependencies.typescript // ""' "$CODEBASE_PATH/package.json" 2>/dev/null)
        if [ -n "$ts_version" ] && [ "$ts_version" != "null" ]; then
            log_metric "typescript_version" "$ts_version"
            score=$((score + 1))
            echo "Scanning: TypeScript $ts_version" >&2
        fi
    fi

    # Check for modern JavaScript features
    if grep -rqE "(async.*await|import.*from|export|const|let|=>|optional.*chaining|\?\.|nullish.*coalescing|\?\?)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "modern_js_features" "true"
        score=$((score + 1))
    fi

    # Check for React version (if applicable)
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        local react_version=$(jq -r '.dependencies.react // ""' "$CODEBASE_PATH/package.json" 2>/dev/null)
        if [ -n "$react_version" ] && [ "$react_version" != "null" ]; then
            log_metric "react_version" "$react_version"
            if echo "$react_version" | grep -qE "(18|19)"; then
                score=$((score + 1))
            fi
        fi
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Cloud-Native Design (Parameters 425-426)
# =============================================================================
check_cloud_native() {
    progress_step "Cloud-native design"
    local score=5

    # Check for containerization
    if [ -f "$CODEBASE_PATH/Dockerfile" ] || [ -f "$CODEBASE_PATH/docker-compose.yml" ]; then
        log_metric "containerized" "true"
        score=$((score + 2))
        echo "Scanning: Found Docker configuration" >&2
    fi

    # Check for Kubernetes
    local k8s_files=$( (find "$CODEBASE_PATH" -type f \( -name "*.yaml" -o -name "*.yml" \) \
        ! -path "*/node_modules/*" 2>/dev/null | xargs grep -l "apiVersion\|kind:" 2>/dev/null || true) | wc -l)
    
    if [ "$k8s_files" -gt 0 ]; then
        log_metric "kubernetes" "true"
        score=$((score + 1))
    fi

    # Check for 12-factor app patterns
    if [ -f "$CODEBASE_PATH/.env.example" ] || grep -rqE "process\.env|os\.environ|getenv" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "env_config" "true"
        score=$((score + 1))
    fi

    # Check for health endpoints
    if grep -rqE "(health|ready|live|\/health|\/ready)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.yaml" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "health_endpoints" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check AI/ML Integration Readiness (Parameter 404)
# =============================================================================
check_ai_ml() {
    progress_step "AI/ML integration readiness"
    local score=5

    # Check for AI/ML libraries
    if grep -rqE "(tensorflow|pytorch|openai|langchain|anthropic|@ai-sdk|ollama|huggingface)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.ts" --include="*.py" --include="*.txt" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "ai_libraries" "true"
        score=$((score + 3))
        echo "Scanning: Found AI/ML integration" >&2
    fi

    # Check for vector databases
    if grep -rqE "(pinecone|weaviate|qdrant|milvus|chroma|pgvector)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "vector_db" "true"
        score=$((score + 1))
    fi

    # Check for embeddings
    if grep -rqE "(embedding|Embedding|vector|Vector|semantic.*search)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "embeddings" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Modern Architecture Patterns (Parameters 428-433)
# =============================================================================
check_modern_patterns() {
    progress_step "Modern architecture patterns"
    local score=5

    # Check for API-first design
    if find "$CODEBASE_PATH" -type f \( -name "openapi*.yaml" -o -name "swagger*.yaml" -o -name "*.graphql" \) \
        ! -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
        log_metric "api_first" "true"
        score=$((score + 1))
    fi

    # Check for event-driven patterns
    if grep -rqE "(event.*driven|EventEmitter|EventBus|pubsub|kafka|rabbitmq|sns|sqs)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "event_driven" "true"
        score=$((score + 1))
        echo "Scanning: Found event-driven patterns" >&2
    fi

    # Check for microservices indicators
    local service_count=$(find "$CODEBASE_PATH" -name "docker-compose.yml" -exec grep -c "services:" {} + 2>/dev/null | head -1)
    if [ -n "$service_count" ] && [ "$service_count" -gt 0 ]; then
        log_metric "multi_service" "true"
        score=$((score + 1))
    fi

    # Check for edge/serverless
    if grep -rqE "(edge|vercel|cloudflare.*worker|deno.*deploy|@edge-runtime)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "edge_ready" "true"
        score=$((score + 1))
    fi

    # Check for GraphQL
    if grep -rqE "(graphql|GraphQL|@Query|@Mutation|type Query)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.graphql" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "graphql" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Innovation Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local tech_score=$(check_tech_currency)
    local cloud_score=$(check_cloud_native)
    local ai_score=$(check_ai_ml)
    local pattern_score=$(check_modern_patterns)

    # Weighted average
    local total_score=$(math_calc "$tech_score * 0.25 + $cloud_score * 0.30 + $ai_score * 0.20 + $pattern_score * 0.25")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 12')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg ts "$tech_score" \
        --arg cs "$cloud_score" \
        --arg as "$ai_score" \
        --arg ps "$pattern_score" \
        '.subscores = {
            technology_currency: ($ts | tonumber),
            cloud_native: ($cs | tonumber),
            ai_ml_readiness: ($as | tonumber),
            modern_patterns: ($ps | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Innovation Score: $total_score/10"
}

main
