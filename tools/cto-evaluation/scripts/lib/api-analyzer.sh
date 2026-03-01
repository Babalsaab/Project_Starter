#!/bin/bash

# =============================================================================
# Enhanced API Analyzer
# =============================================================================
# Analyzes API design quality, documentation, versioning, and best practices.
# =============================================================================

# Analyze API design quality
analyze_api_design() {
    local codebase="$1"
    
    local api_score=5
    local has_openapi=false
    local has_graphql=false
    local has_grpc=false
    local has_rest=false
    local has_versioning=false
    local has_rate_limiting=false
    local has_pagination=false
    local has_authentication=false
    local has_validation=false
    
    # Check for OpenAPI/Swagger
    if [ -f "$codebase/openapi.yaml" ] || [ -f "$codebase/openapi.json" ] || \
       [ -f "$codebase/swagger.yaml" ] || [ -f "$codebase/swagger.json" ] || \
       find "$codebase" -maxdepth 3 \( -name "openapi*.yaml" -o -name "swagger*.yaml" \) 2>/dev/null | head -1 | grep -q .; then
        has_openapi=true
        ((api_score += 2))
    fi
    
    # Check for GraphQL
    if [ -f "$codebase/schema.graphql" ] || \
       find "$codebase" -name "*.graphql" 2>/dev/null | head -1 | grep -q . || \
       grep -rql "graphql\|apollo\|@Query\|@Mutation" "$codebase" \
           --include="*.js" --include="*.ts" --include="*.py" --include="*.go" \
           ! -path "*/node_modules/*" 2>/dev/null; then
        has_graphql=true
        ((api_score++))
    fi
    
    # Check for gRPC
    if find "$codebase" -name "*.proto" 2>/dev/null | head -1 | grep -q . || \
       grep -rql "grpc\|protobuf" "$codebase" \
           --include="*.go" --include="*.java" --include="*.py" \
           ! -path "*/node_modules/*" ! -path "*/vendor/*" 2>/dev/null; then
        has_grpc=true
        ((api_score++))
    fi
    
    # Check for REST patterns
    if grep -rqE "app\\.(get|post|put|patch|delete)\\s*\\(|@(Get|Post|Put|Patch|Delete)|router\\.(get|post)" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" ! -path "*/vendor/*" 2>/dev/null; then
        has_rest=true
    fi
    
    # Check for API versioning
    if grep -rqE "/v[0-9]+/|/api/v[0-9]+|version.*=.*['\"]v?[0-9]|@Version" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        --include="*.yaml" --include="*.yml" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_versioning=true
        ((api_score++))
    fi
    
    # Check for rate limiting
    if grep -rqE "rateLimit|rate-limit|throttle|RateLimiter|@Throttle|slowDown" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_rate_limiting=true
        ((api_score++))
    fi
    
    # Check for pagination
    if grep -rqE "page|limit|offset|cursor|nextToken|hasMore|totalPages|pageSize" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_pagination=true
        ((api_score++))
    fi
    
    # Check for authentication/authorization
    if grep -rqE "auth|jwt|bearer|passport|oauth|@Authorized|@RequiresPermission|@PreAuthorize" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_authentication=true
        ((api_score++))
    fi
    
    # Check for input validation
    if grep -rqE "validate|validator|@IsString|@IsNumber|@IsEmail|joi\\.|yup\\.|zod\\.|class-validator" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_validation=true
        ((api_score++))
    fi
    
    [ "$api_score" -gt 10 ] && api_score=10
    
    cat << EOF
{
    "api_score": $api_score,
    "has_openapi": $has_openapi,
    "has_graphql": $has_graphql,
    "has_grpc": $has_grpc,
    "has_rest": $has_rest,
    "has_versioning": $has_versioning,
    "has_rate_limiting": $has_rate_limiting,
    "has_pagination": $has_pagination,
    "has_authentication": $has_authentication,
    "has_validation": $has_validation
}
EOF
}

# Analyze API documentation quality
analyze_api_documentation() {
    local codebase="$1"
    
    local doc_score=5
    local has_api_docs=false
    local has_examples=false
    local has_error_docs=false
    
    # Check for OpenAPI/Swagger documentation
    local openapi_files
    openapi_files=$(find "$codebase" \( -name "openapi*.yaml" -o -name "openapi*.json" \
        -o -name "swagger*.yaml" -o -name "swagger*.json" \) 2>/dev/null)
    
    if [ -n "$openapi_files" ]; then
        has_api_docs=true
        ((doc_score += 2))
        
        # Check for examples in OpenAPI
        if echo "$openapi_files" | head -1 | xargs grep -qE "example:|examples:" 2>/dev/null; then
            has_examples=true
            ((doc_score++))
        fi
        
        # Check for error responses
        if echo "$openapi_files" | head -1 | xargs grep -qE "4[0-9][0-9]:|5[0-9][0-9]:" 2>/dev/null; then
            has_error_docs=true
            ((doc_score++))
        fi
    fi
    
    # Check for API documentation in markdown
    if [ -f "$codebase/API.md" ] || [ -f "$codebase/docs/api.md" ] || \
       [ -d "$codebase/docs/api" ]; then
        has_api_docs=true
        ((doc_score++))
    fi
    
    # Check for JSDoc/docstrings on API endpoints
    local endpoint_files
    endpoint_files=$(find "$codebase" \( -path "*/routes/*" -o -path "*/controllers/*" \
        -o -path "*/api/*" -o -path "*/endpoints/*" \) \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" 2>/dev/null | head -20)
    
    if [ -n "$endpoint_files" ]; then
        local documented_endpoints=0
        local total_endpoints=0
        
        while IFS= read -r file; do
            [ -z "$file" ] && continue
            local content
            content=$(cat "$file" 2>/dev/null)
            
            # Count endpoints
            local endpoints_in_file
            endpoints_in_file=$(echo "$content" | grep -cE "@(Get|Post|Put|Delete|Patch)|\\.(get|post|put|delete|patch)\\s*\\(" 2>/dev/null || echo "0")
            total_endpoints=$((total_endpoints + endpoints_in_file))
            
            # Count documented endpoints (JSDoc/docstrings before endpoint)
            local docs_in_file
            docs_in_file=$(echo "$content" | grep -cE "/\\*\\*|'''|\"\"\"" 2>/dev/null || echo "0")
            documented_endpoints=$((documented_endpoints + docs_in_file))
            
        done <<< "$endpoint_files"
        
        if [ "$total_endpoints" -gt 0 ]; then
            local doc_ratio=$((documented_endpoints * 100 / total_endpoints))
            [ "$doc_ratio" -gt 50 ] && ((doc_score++))
            [ "$doc_ratio" -gt 80 ] && ((doc_score++))
        fi
    fi
    
    [ "$doc_score" -gt 10 ] && doc_score=10
    
    cat << EOF
{
    "doc_score": $doc_score,
    "has_api_docs": $has_api_docs,
    "has_examples": $has_examples,
    "has_error_docs": $has_error_docs
}
EOF
}

# Analyze error handling in API
analyze_api_error_handling() {
    local codebase="$1"
    
    local error_score=5
    local has_error_middleware=false
    local has_custom_errors=false
    local has_error_codes=false
    local has_error_logging=false
    
    # Check for error middleware
    if grep -rqE "errorHandler|ErrorMiddleware|@Catch|exception_handler|error_handler" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_error_middleware=true
        ((error_score++))
    fi
    
    # Check for custom error classes
    if grep -rqE "extends\\s+Error|class.*Error|class.*Exception|CustomError|AppError|HttpException" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_custom_errors=true
        ((error_score++))
    fi
    
    # Check for error codes/types
    if grep -rqE "errorCode|error_code|ErrorCode|ERROR_|statusCode.*[45][0-9][0-9]" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_error_codes=true
        ((error_score++))
    fi
    
    # Check for error logging
    if grep -rqE "logger\\.error|console\\.error|log\\.Error|logging\\.error" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_error_logging=true
        ((error_score++))
    fi
    
    # Check for structured error responses
    if grep -rqE "\\{\\s*error:|message.*:.*error|code.*:.*[A-Z_]+|details.*:" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        ((error_score++))
    fi
    
    [ "$error_score" -gt 10 ] && error_score=10
    
    cat << EOF
{
    "error_score": $error_score,
    "has_error_middleware": $has_error_middleware,
    "has_custom_errors": $has_custom_errors,
    "has_error_codes": $has_error_codes,
    "has_error_logging": $has_error_logging
}
EOF
}

# Analyze API security
analyze_api_security() {
    local codebase="$1"
    
    local security_score=5
    local has_cors=false
    local has_helmet=false
    local has_csrf=false
    local has_input_sanitization=false
    local has_rate_limiting=false
    
    # Check for CORS configuration
    if grep -rqE "cors|Access-Control-Allow|CORS_|CorsMiddleware" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        --include="*.yaml" --include="*.yml" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_cors=true
        ((security_score++))
    fi
    
    # Check for security headers (helmet, etc.)
    if grep -rqE "helmet|security-headers|X-Content-Type-Options|X-Frame-Options" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_helmet=true
        ((security_score++))
    fi
    
    # Check for CSRF protection
    if grep -rqE "csrf|csurf|CSRFProtect|@csrf|X-CSRF-Token" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_csrf=true
        ((security_score++))
    fi
    
    # Check for input sanitization
    if grep -rqE "sanitize|escape|DOMPurify|bleach|validator\\.escape|xss" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_input_sanitization=true
        ((security_score++))
    fi
    
    # Check for rate limiting
    if grep -rqE "rateLimit|rate-limit|throttle|RateLimiter" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" 2>/dev/null; then
        has_rate_limiting=true
        ((security_score++))
    fi
    
    [ "$security_score" -gt 10 ] && security_score=10
    
    cat << EOF
{
    "security_score": $security_score,
    "has_cors": $has_cors,
    "has_helmet": $has_helmet,
    "has_csrf": $has_csrf,
    "has_input_sanitization": $has_input_sanitization,
    "has_rate_limiting": $has_rate_limiting
}
EOF
}

# Export functions
export -f analyze_api_design 2>/dev/null || true
export -f analyze_api_documentation 2>/dev/null || true
export -f analyze_api_error_handling 2>/dev/null || true
export -f analyze_api_security 2>/dev/null || true
