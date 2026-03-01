#!/bin/bash

# =============================================================================
# API DESIGN & INTEGRATION EVALUATION (Parameters 295-316)
# =============================================================================
# Evaluates:
#   - API Quality (237-248)
#   - API Security & Operations (249-258)
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
TOTAL_STEPS=5
CURRENT_STEP=0

progress_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "Evaluating: [$CURRENT_STEP/$TOTAL_STEPS] $1" >&2
}

RESULTS='{
    "category": "api_design",
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
# Check RESTful Design (Parameters 237, 241-243)
# =============================================================================
check_restful_design() {
    progress_step "RESTful design patterns"
    local score=5

    # Check for proper HTTP method usage
    local route_definitions=$(grep -rcE "(app\.(get|post|put|patch|delete)|@Get|@Post|@Put|@Patch|@Delete|router\.(get|post)|@api_view)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=test* 2>/dev/null | \
        awk -F: '{sum += $2} END {print sum+0}')
    
    log_metric "route_definitions" "$route_definitions"
    echo "Scanning: Found $route_definitions route definitions" >&2

    if [ "$route_definitions" -gt 50 ]; then
        score=8
    elif [ "$route_definitions" -gt 20 ]; then
        score=7
    elif [ "$route_definitions" -lt 5 ]; then
        score=4
    fi

    # Check for proper status code usage
    if grep -rqE "(res\.status\(|HttpStatus\.|status_code|return.*Response\()" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "status_codes_used" "true"
        score=$((score + 1))
    fi

    # Check for consistent error responses
    if grep -rqE "(errorResponse|ErrorResponse|ApiError|HttpException|APIException)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "error_response_pattern" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check API Documentation (Parameter 251)
# =============================================================================
check_api_documentation() {
    progress_step "API documentation"
    local score=4

    # Check for OpenAPI/Swagger
    if find "$CODEBASE_PATH" -type f \( -name "swagger*" -o -name "openapi*" -o -name "*.yaml" -o -name "*.yml" \) \
        ! -path "*/node_modules/*" 2>/dev/null | xargs grep -l "openapi\|swagger" 2>/dev/null | head -1 | grep -q .; then
        log_metric "openapi_spec" "true"
        score=8
        echo "Scanning: Found OpenAPI/Swagger specification" >&2
    fi

    # Check for Swagger decorators
    if grep -rqE "(@ApiTags|@ApiOperation|@ApiProperty|@api\.doc|swagger_auto_schema)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "swagger_decorators" "true"
        score=$((score + 1))
        echo "Scanning: Found API documentation decorators" >&2
    fi

    # Check for API versioning
    if grep -rqE "(\/v[0-9]+\/|\/api\/v[0-9]|@Version|api_version)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "api_versioning" "true"
        score=$((score + 1))
        echo "Scanning: Found API versioning" >&2
    else
        add_finding "medium" "api" "No API versioning found"
    fi

    if [ "$score" -lt 5 ]; then
        add_finding "high" "api" "No API documentation (OpenAPI/Swagger) found"
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Pagination & Filtering (Parameters 268-269)
# =============================================================================
check_pagination() {
    progress_step "Pagination and filtering"
    local score=5

    # Check for pagination
    if grep -rqE "(page|limit|offset|cursor|skip|take|per_page|pageSize)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "pagination" "true"
        score=$((score + 2))
        echo "Scanning: Found pagination patterns" >&2
    else
        add_finding "medium" "api" "No pagination implementation found"
    fi

    # Check for filtering
    if grep -rqE "(filter|sort|order|search|query.*param)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=test* 2>/dev/null; then
        log_metric "filtering" "true"
        score=$((score + 1))
    fi

    # Check for field selection (sparse fieldsets)
    if grep -rqE "(fields|select|include|exclude|\.only\(|\.select\()" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "field_selection" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Rate Limiting & Security (Parameters 272-273)
# =============================================================================
check_api_security() {
    progress_step "API security and rate limiting"
    local score=5

    # Check for rate limiting
    if grep -rqE "(rate.*limit|rateLimit|throttle|Throttle|express-rate-limit|slowDown)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "rate_limiting" "true"
        score=$((score + 2))
        echo "Scanning: Found rate limiting" >&2
    else
        add_finding "high" "api" "No rate limiting found"
    fi

    # Check for API authentication middleware
    if grep -rqE "(passport|jwt|bearer|apiKey|api-key|authenticate|@UseGuards|@Authorized)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "api_auth" "true"
        score=$((score + 2))
        echo "Scanning: Found API authentication" >&2
    fi

    # Check for CORS configuration
    if grep -rqE "(cors|CORS|Access-Control-Allow)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "cors_configured" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Webhooks & Integration (Parameters 276-277)
# =============================================================================
check_integrations() {
    progress_step "Webhooks and SDK patterns"
    local score=5

    # Check for webhook support
    if grep -rqE "(webhook|Webhook|callback.*url|callbackUrl|notify|notification.*endpoint)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "webhooks" "true"
        score=$((score + 2))
        echo "Scanning: Found webhook patterns" >&2
    fi

    # Check for GraphQL
    if grep -rqE "(graphql|GraphQL|@Query|@Mutation|@Resolver|type Query|type Mutation)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.graphql" --include="*.gql" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "graphql" "true"
        score=$((score + 1))
        echo "Scanning: Found GraphQL implementation" >&2
    fi

    # Check for gRPC
    if find "$CODEBASE_PATH" -name "*.proto" ! -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
        log_metric "grpc" "true"
        score=$((score + 1))
        echo "Scanning: Found gRPC/Protocol Buffers" >&2
    fi

    # Check for SDK/Client generation
    if grep -rqE "(openapi-generator|swagger-codegen|graphql-codegen|@openapitools)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.yaml" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "sdk_generation" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting API Design Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local rest_score=$(check_restful_design)
    local docs_score=$(check_api_documentation)
    local pagination_score=$(check_pagination)
    local security_score=$(check_api_security)
    local integration_score=$(check_integrations)

    # Weighted average
    local total_score=$(math_calc "$rest_score * 0.25 + $docs_score * 0.20 + $pagination_score * 0.15 + $security_score * 0.25 + $integration_score * 0.15")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 22')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg rs "$rest_score" \
        --arg ds "$docs_score" \
        --arg ps "$pagination_score" \
        --arg ss "$security_score" \
        --arg is "$integration_score" \
        '.subscores = {
            restful_design: ($rs | tonumber),
            documentation: ($ds | tonumber),
            pagination: ($ps | tonumber),
            security: ($ss | tonumber),
            integrations: ($is | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "API Design Score: $total_score/10"
}

main
