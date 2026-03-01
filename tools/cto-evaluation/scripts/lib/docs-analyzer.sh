#!/bin/bash

# =============================================================================
# API & DOCUMENTATION ANALYZER
# =============================================================================
# Analyzes API documentation and specifications:
#   - OpenAPI/Swagger detection and validation
#   - GraphQL schema analysis
#   - API versioning detection
#   - Documentation coverage
#   - README quality analysis
#   - Code comments density
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/math-utils.sh"

# =============================================================================
# OPENAPI/SWAGGER DETECTION
# =============================================================================

analyze_openapi() {
    local codebase="$1"
    local result='{
        "found": false,
        "spec_files": [],
        "version": null,
        "endpoints_count": 0,
        "has_descriptions": false,
        "has_examples": false,
        "has_security": false,
        "validation_errors": [],
        "score": 0
    }'
    
    echo "  Analyzing OpenAPI/Swagger specifications..." >&2
    
    # Find OpenAPI/Swagger files
    local spec_files=$(find "$codebase" \
        \( -name "openapi*.yaml" -o -name "openapi*.yml" -o -name "openapi*.json" \
           -o -name "swagger*.yaml" -o -name "swagger*.yml" -o -name "swagger*.json" \
           -o -name "api-spec*.yaml" -o -name "api-spec*.json" \) \
        -not -path "*/node_modules/*" 2>/dev/null)
    
    if [ -z "$spec_files" ]; then
        # Check for inline swagger in source files
        if grep -rq "swagger:" "$codebase" --include="*.yaml" --include="*.yml" 2>/dev/null; then
            result=$(echo "$result" | jq '.found = true | .spec_files = ["inline"]')
        fi
        echo "$result"
        return
    fi
    
    result=$(echo "$result" | jq '.found = true')
    
    for spec_file in $spec_files; do
        echo "    Processing: $spec_file" >&2
        result=$(echo "$result" | jq --arg f "$spec_file" '.spec_files += [$f]')
        
        # Determine file type
        local is_json=false
        [[ "$spec_file" == *.json ]] && is_json=true
        
        # Extract version
        local version=""
        if $is_json; then
            version=$(jq -r '.openapi // .swagger // "unknown"' "$spec_file" 2>/dev/null)
        else
            version=$(grep -E '^openapi:|^swagger:' "$spec_file" | head -1 | awk '{print $2}' | tr -d '"' || echo "unknown")
        fi
        result=$(echo "$result" | jq --arg v "$version" '.version = $v')
        
        # Count endpoints
        local endpoints=0
        if $is_json; then
            endpoints=$(jq '[.paths | to_entries[] | .value | keys | length] | add // 0' "$spec_file" 2>/dev/null)
        else
            # Count HTTP methods under paths
            endpoints=$(grep -cE '^\s{4}(get|post|put|patch|delete|options|head):' "$spec_file" 2>/dev/null || echo "0")
        fi
        result=$(echo "$result" | jq --argjson e "$endpoints" '.endpoints_count = $e')
        
        # Check for descriptions
        if grep -qE 'description:' "$spec_file" 2>/dev/null; then
            result=$(echo "$result" | jq '.has_descriptions = true')
        fi
        
        # Check for examples
        if grep -qE 'example:|examples:' "$spec_file" 2>/dev/null; then
            result=$(echo "$result" | jq '.has_examples = true')
        fi
        
        # Check for security definitions
        if grep -qE 'security:|securitySchemes:|securityDefinitions:' "$spec_file" 2>/dev/null; then
            result=$(echo "$result" | jq '.has_security = true')
        fi
        
        # Validate with spectral if available
        if command -v spectral &> /dev/null; then
            echo "    Running Spectral validation..." >&2
            local validation=$(spectral lint "$spec_file" --format json 2>/dev/null || echo "[]")
            local error_count=$(echo "$validation" | jq 'length')
            if [ "$error_count" -gt 0 ]; then
                result=$(echo "$result" | jq --argjson errors "$(echo "$validation" | jq '.[0:5]')" \
                    '.validation_errors = $errors')
            fi
        fi
    done
    
    # Calculate score
    local score=0
    [ "$(echo "$result" | jq '.found')" == "true" ] && score=$((score + 4))
    [ "$(echo "$result" | jq '.has_descriptions')" == "true" ] && score=$((score + 2))
    [ "$(echo "$result" | jq '.has_examples')" == "true" ] && score=$((score + 2))
    [ "$(echo "$result" | jq '.has_security')" == "true" ] && score=$((score + 2))
    
    [ "$score" -gt 10 ] && score=10
    result=$(echo "$result" | jq --argjson s "$score" '.score = $s')
    
    echo "$result"
}

# =============================================================================
# GRAPHQL SCHEMA ANALYSIS
# =============================================================================

analyze_graphql() {
    local codebase="$1"
    local result='{
        "found": false,
        "schema_files": [],
        "types_count": 0,
        "queries_count": 0,
        "mutations_count": 0,
        "has_descriptions": false,
        "has_deprecations": false,
        "score": 0
    }'
    
    echo "  Analyzing GraphQL schemas..." >&2
    
    # Find GraphQL schema files
    local schema_files=$(find "$codebase" \
        \( -name "*.graphql" -o -name "*.gql" -o -name "schema.graphql" \) \
        -not -path "*/node_modules/*" 2>/dev/null)
    
    if [ -z "$schema_files" ]; then
        # Check for inline schema definitions
        if grep -rqE 'type Query|type Mutation|gql\`' "$codebase" --include="*.ts" --include="*.js" 2>/dev/null; then
            result=$(echo "$result" | jq '.found = true | .schema_files = ["inline"]')
        fi
        echo "$result"
        return
    fi
    
    result=$(echo "$result" | jq '.found = true')
    
    for schema_file in $schema_files; do
        echo "    Processing: $schema_file" >&2
        result=$(echo "$result" | jq --arg f "$schema_file" '.schema_files += [$f]')
        
        # Count types
        local types=$(grep -cE '^type\s+\w+' "$schema_file" 2>/dev/null || echo "0")
        result=$(echo "$result" | jq --argjson t "$types" '.types_count += $t')
        
        # Count queries (fields under type Query)
        local queries=$(sed -n '/^type Query/,/^}/p' "$schema_file" 2>/dev/null | grep -cE '^\s+\w+.*:' || echo "0")
        result=$(echo "$result" | jq --argjson q "$queries" '.queries_count += $q')
        
        # Count mutations
        local mutations=$(sed -n '/^type Mutation/,/^}/p' "$schema_file" 2>/dev/null | grep -cE '^\s+\w+.*:' || echo "0")
        result=$(echo "$result" | jq --argjson m "$mutations" '.mutations_count += $m')
        
        # Check for descriptions (""" comments)
        if grep -qE '"""' "$schema_file" 2>/dev/null; then
            result=$(echo "$result" | jq '.has_descriptions = true')
        fi
        
        # Check for deprecations
        if grep -qE '@deprecated' "$schema_file" 2>/dev/null; then
            result=$(echo "$result" | jq '.has_deprecations = true')
        fi
    done
    
    # Calculate score
    local score=0
    [ "$(echo "$result" | jq '.found')" == "true" ] && score=$((score + 5))
    [ "$(echo "$result" | jq '.has_descriptions')" == "true" ] && score=$((score + 3))
    local types=$(echo "$result" | jq '.types_count')
    [ "$types" -gt 10 ] && score=$((score + 2))
    
    [ "$score" -gt 10 ] && score=10
    result=$(echo "$result" | jq --argjson s "$score" '.score = $s')
    
    echo "$result"
}

# =============================================================================
# README QUALITY ANALYSIS
# =============================================================================

analyze_readme() {
    local codebase="$1"
    local result='{
        "found": false,
        "file": null,
        "word_count": 0,
        "sections": {
            "has_title": false,
            "has_description": false,
            "has_installation": false,
            "has_usage": false,
            "has_api": false,
            "has_contributing": false,
            "has_license": false,
            "has_badges": false,
            "has_examples": false,
            "has_table_of_contents": false
        },
        "has_images": false,
        "has_code_blocks": false,
        "score": 0
    }'
    
    echo "  Analyzing README quality..." >&2
    
    # Find README file
    local readme_file=""
    for f in "$codebase/README.md" "$codebase/readme.md" "$codebase/README.MD" \
             "$codebase/README.rst" "$codebase/README.txt" "$codebase/README"; do
        if [ -f "$f" ]; then
            readme_file="$f"
            break
        fi
    done
    
    if [ -z "$readme_file" ]; then
        echo "$result"
        return
    fi
    
    result=$(echo "$result" | jq --arg f "$readme_file" '.found = true | .file = $f')
    
    local content=$(cat "$readme_file")
    local word_count=$(wc -w < "$readme_file" | tr -d ' ')
    result=$(echo "$result" | jq --argjson wc "$word_count" '.word_count = $wc')
    
    # Check for title (first # heading)
    if echo "$content" | head -5 | grep -qE '^#\s'; then
        result=$(echo "$result" | jq '.sections.has_title = true')
    fi
    
    # Check for common sections
    echo "$content" | grep -qiE '^#+\s*(description|overview|about)' && \
        result=$(echo "$result" | jq '.sections.has_description = true')
    
    echo "$content" | grep -qiE '^#+\s*(install|getting started|setup|quick start)' && \
        result=$(echo "$result" | jq '.sections.has_installation = true')
    
    echo "$content" | grep -qiE '^#+\s*(usage|how to use|examples?)' && \
        result=$(echo "$result" | jq '.sections.has_usage = true')
    
    echo "$content" | grep -qiE '^#+\s*(api|endpoints|reference)' && \
        result=$(echo "$result" | jq '.sections.has_api = true')
    
    echo "$content" | grep -qiE '^#+\s*(contribut|development)' && \
        result=$(echo "$result" | jq '.sections.has_contributing = true')
    
    echo "$content" | grep -qiE '^#+\s*license' && \
        result=$(echo "$result" | jq '.sections.has_license = true')
    
    # Check for badges
    echo "$content" | grep -qE '!\[.*\]\(.*badge|shields\.io' && \
        result=$(echo "$result" | jq '.sections.has_badges = true')
    
    # Check for code examples
    echo "$content" | grep -qE '^\`\`\`' && \
        result=$(echo "$result" | jq '.has_code_blocks = true | .sections.has_examples = true')
    
    # Check for images
    echo "$content" | grep -qE '!\[.*\]\(' && \
        result=$(echo "$result" | jq '.has_images = true')
    
    # Check for table of contents
    echo "$content" | grep -qiE '(table of contents|\- \[.*\]\(#)' && \
        result=$(echo "$result" | jq '.sections.has_table_of_contents = true')
    
    # Calculate score based on sections present
    local score=0
    local sections=$(echo "$result" | jq '.sections')
    
    [ "$(echo "$sections" | jq '.has_title')" == "true" ] && score=$((score + 1))
    [ "$(echo "$sections" | jq '.has_description')" == "true" ] && score=$((score + 1))
    [ "$(echo "$sections" | jq '.has_installation')" == "true" ] && score=$((score + 2))
    [ "$(echo "$sections" | jq '.has_usage')" == "true" ] && score=$((score + 2))
    [ "$(echo "$sections" | jq '.has_examples')" == "true" ] && score=$((score + 1))
    [ "$(echo "$sections" | jq '.has_contributing')" == "true" ] && score=$((score + 1))
    [ "$(echo "$sections" | jq '.has_license')" == "true" ] && score=$((score + 1))
    [ "$(echo "$sections" | jq '.has_badges')" == "true" ] && score=$((score + 0.5))
    [ "$(echo "$sections" | jq '.has_table_of_contents')" == "true" ] && score=$((score + 0.5))
    
    # Bonus for length
    [ "$word_count" -gt 500 ] && score=$(math_calc "$score + 0.5")
    [ "$word_count" -gt 1000 ] && score=$(math_calc "$score + 0.5")

    # Cap at 10
    if math_compare "$score" ">" "10"; then score=10; fi
    result=$(echo "$result" | jq --argjson s "$score" '.score = $s')
    
    echo "$result"
}

# =============================================================================
# CODE COMMENT DENSITY ANALYSIS
# =============================================================================

analyze_comments() {
    local codebase="$1"
    local result='{
        "total_lines": 0,
        "comment_lines": 0,
        "comment_density": 0,
        "has_jsdoc": false,
        "has_docstrings": false,
        "has_godoc": false,
        "score": 0
    }'
    
    echo "  Analyzing code comment density..." >&2
    
    # Use cloc if available for accurate counting
    if command -v cloc &> /dev/null; then
        local cloc_out=$(cloc "$codebase" --json --quiet \
            --exclude-dir=node_modules,vendor,dist,build,.git,coverage 2>/dev/null)
        
        local total=$(echo "$cloc_out" | jq '.SUM.code // 0')
        local comments=$(echo "$cloc_out" | jq '.SUM.comment // 0')
        
        result=$(echo "$result" | jq --argjson t "$total" --argjson c "$comments" \
            '.total_lines = $t | .comment_lines = $c')
        
        if [ "$total" -gt 0 ]; then
            local density=$(math_calc "$comments * 100 / $total")
            result=$(echo "$result" | jq --arg d "$density" '.comment_density = ($d | tonumber)')
        fi
    else
        # Fallback to grep-based counting
        local code_files=$(find "$codebase" \
            \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \
               -o -name "*.java" -o -name "*.rb" -o -name "*.rs" \) \
            -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)
        
        local total=0
        local comments=0
        
        for file in $code_files; do
            local file_total=$(wc -l < "$file" | tr -d ' ')
            total=$((total + file_total))
            
            # Count comment lines (basic estimation)
            local file_comments=$(grep -cE '^\s*(//|#|/\*|\*|""")' "$file" 2>/dev/null || echo "0")
            comments=$((comments + file_comments))
        done
        
        result=$(echo "$result" | jq --argjson t "$total" --argjson c "$comments" \
            '.total_lines = $t | .comment_lines = $c')
        
        if [ "$total" -gt 0 ]; then
            local density=$(math_calc "$comments * 100 / $total")
            result=$(echo "$result" | jq --arg d "$density" '.comment_density = ($d | tonumber)')
        fi
    fi
    
    # Check for documentation patterns
    if grep -rqE '/\*\*|\* @param|\* @returns' "$codebase" --include="*.js" --include="*.ts" 2>/dev/null; then
        result=$(echo "$result" | jq '.has_jsdoc = true')
    fi
    
    if grep -rqE '""".*"""|\x27\x27\x27.*\x27\x27\x27' "$codebase" --include="*.py" 2>/dev/null; then
        result=$(echo "$result" | jq '.has_docstrings = true')
    fi
    
    if grep -rqE '^// [A-Z][a-z]+ ' "$codebase" --include="*.go" 2>/dev/null; then
        result=$(echo "$result" | jq '.has_godoc = true')
    fi
    
    # Calculate score
    local density=$(echo "$result" | jq '.comment_density')
    local score=5  # Base score
    
    if math_compare "$density" ">=" "15"; then
        score=10
    elif math_compare "$density" ">=" "10"; then
        score=8
    elif math_compare "$density" ">=" "5"; then
        score=6
    elif math_compare "$density" ">=" "2"; then
        score=4
    else
        score=2
    fi
    
    # Bonus for structured documentation
    [ "$(echo "$result" | jq '.has_jsdoc')" == "true" ] && score=$((score + 1))
    [ "$(echo "$result" | jq '.has_docstrings')" == "true" ] && score=$((score + 1))
    [ "$(echo "$result" | jq '.has_godoc')" == "true" ] && score=$((score + 1))
    
    [ "$score" -gt 10 ] && score=10
    result=$(echo "$result" | jq --argjson s "$score" '.score = $s')
    
    echo "$result"
}

# =============================================================================
# COMPREHENSIVE DOCUMENTATION ANALYSIS
# =============================================================================

analyze_documentation() {
    local codebase="$1"
    local output_file="${2:-/dev/stdout}"
    
    echo "Analyzing API and documentation..." >&2
    
    local openapi=$(analyze_openapi "$codebase")
    local graphql=$(analyze_graphql "$codebase")
    local readme=$(analyze_readme "$codebase")
    local comments=$(analyze_comments "$codebase")
    
    # Check for additional documentation
    local additional='{
        "has_changelog": false,
        "has_contributing": false,
        "has_code_of_conduct": false,
        "has_architecture_docs": false,
        "has_docs_folder": false
    }'
    
    [ -f "$codebase/CHANGELOG.md" ] || [ -f "$codebase/HISTORY.md" ] && \
        additional=$(echo "$additional" | jq '.has_changelog = true')
    
    [ -f "$codebase/CONTRIBUTING.md" ] && \
        additional=$(echo "$additional" | jq '.has_contributing = true')
    
    [ -f "$codebase/CODE_OF_CONDUCT.md" ] && \
        additional=$(echo "$additional" | jq '.has_code_of_conduct = true')
    
    [ -f "$codebase/ARCHITECTURE.md" ] || [ -d "$codebase/docs/architecture" ] && \
        additional=$(echo "$additional" | jq '.has_architecture_docs = true')
    
    [ -d "$codebase/docs" ] && \
        additional=$(echo "$additional" | jq '.has_docs_folder = true')
    
    # Calculate overall score
    local openapi_score=$(echo "$openapi" | jq '.score')
    local graphql_score=$(echo "$graphql" | jq '.score')
    local readme_score=$(echo "$readme" | jq '.score')
    local comments_score=$(echo "$comments" | jq '.score')
    
    # Weighted average
    local weights_total=0
    local weighted_sum=0
    
    if [ "$(echo "$openapi" | jq '.found')" == "true" ]; then
        weighted_sum=$(math_calc "$weighted_sum + $openapi_score * 3")
        weights_total=$((weights_total + 3))
    fi

    if [ "$(echo "$graphql" | jq '.found')" == "true" ]; then
        weighted_sum=$(math_calc "$weighted_sum + $graphql_score * 3")
        weights_total=$((weights_total + 3))
    fi

    if [ "$(echo "$readme" | jq '.found')" == "true" ]; then
        weighted_sum=$(math_calc "$weighted_sum + $readme_score * 2")
        weights_total=$((weights_total + 2))
    fi

    weighted_sum=$(math_calc "$weighted_sum + $comments_score * 1")
    weights_total=$((weights_total + 1))
    
    local overall_score=0
    if [ "$weights_total" -gt 0 ]; then
        overall_score=$(math_calc "$weighted_sum / $weights_total")
    fi
    
    # Generate recommendations
    local recs='[]'
    
    [ "$(echo "$readme" | jq '.found')" == "false" ] && \
        recs=$(echo "$recs" | jq '. += ["Add a comprehensive README.md file"]')
    
    [ "$(echo "$readme" | jq '.sections.has_installation')" == "false" ] && \
        [ "$(echo "$readme" | jq '.found')" == "true" ] && \
        recs=$(echo "$recs" | jq '. += ["Add installation instructions to README"]')
    
    [ "$(echo "$openapi" | jq '.found')" == "false" ] && \
        [ "$(echo "$graphql" | jq '.found')" == "false" ] && \
        recs=$(echo "$recs" | jq '. += ["Consider adding OpenAPI/Swagger documentation for APIs"]')
    
    [ "$(echo "$openapi" | jq '.has_examples')" == "false" ] && \
        [ "$(echo "$openapi" | jq '.found')" == "true" ] && \
        recs=$(echo "$recs" | jq '. += ["Add examples to OpenAPI specification"]')
    
    local density=$(echo "$comments" | jq '.comment_density')
    math_compare "$density" "<" "5" && \
        recs=$(echo "$recs" | jq '. += ["Increase code comment density for better maintainability"]')
    
    [ "$(echo "$additional" | jq '.has_changelog')" == "false" ] && \
        recs=$(echo "$recs" | jq '. += ["Add a CHANGELOG.md to track version history"]')
    
    jq -n \
        --argjson openapi "$openapi" \
        --argjson graphql "$graphql" \
        --argjson readme "$readme" \
        --argjson comments "$comments" \
        --argjson additional "$additional" \
        --arg score "$overall_score" \
        --argjson recs "$recs" \
        '{
            documentation_analysis_version: "2.0",
            api_specifications: {
                openapi: $openapi,
                graphql: $graphql
            },
            readme: $readme,
            code_comments: $comments,
            additional_docs: $additional,
            overall_score: ($score | tonumber),
            recommendations: $recs
        }' > "$output_file"
    
    cat "$output_file"
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    analyze_documentation "$@"
fi
