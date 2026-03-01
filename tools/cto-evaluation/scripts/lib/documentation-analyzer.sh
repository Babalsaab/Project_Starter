#!/bin/bash

# =============================================================================
# ENHANCED DOCUMENTATION ANALYZER
# =============================================================================
# Deep documentation analysis for codebases
# Detects: README quality, API docs, code comments, architecture docs, runbooks
# =============================================================================

# =============================================================================
# MAIN DOCUMENTATION ANALYSIS
# =============================================================================

analyze_documentation() {
    local codebase_path="$1"
    local output_dir="${2:-${TMPDIR:-/tmp}/documentation-analysis}"
    
    mkdir -p "$output_dir"
    
    local total_score=5
    
    # Run all documentation checks
    local readme_result=$(analyze_readme "$codebase_path" 2>/dev/null) || readme_result='{"score": 3}'
    local api_doc_result=$(analyze_api_documentation "$codebase_path" 2>/dev/null) || api_doc_result='{"score": 3}'
    local code_comment_result=$(analyze_code_comments "$codebase_path" 2>/dev/null) || code_comment_result='{"score": 5}'
    local arch_doc_result=$(analyze_architecture_docs "$codebase_path" 2>/dev/null) || arch_doc_result='{"score": 3}'
    local runbook_result=$(analyze_runbooks "$codebase_path" 2>/dev/null) || runbook_result='{"score": 3}'
    
    # Validate JSON
    echo "$readme_result" | jq '.' >/dev/null 2>&1 || readme_result='{"score": 3}'
    echo "$api_doc_result" | jq '.' >/dev/null 2>&1 || api_doc_result='{"score": 3}'
    echo "$code_comment_result" | jq '.' >/dev/null 2>&1 || code_comment_result='{"score": 5}'
    echo "$arch_doc_result" | jq '.' >/dev/null 2>&1 || arch_doc_result='{"score": 3}'
    echo "$runbook_result" | jq '.' >/dev/null 2>&1 || runbook_result='{"score": 3}'
    
    # Extract scores
    local readme_score=$(echo "$readme_result" | jq -r '.score // 3') || readme_score=3
    local api_doc_score=$(echo "$api_doc_result" | jq -r '.score // 3') || api_doc_score=3
    local comment_score=$(echo "$code_comment_result" | jq -r '.score // 5') || comment_score=5
    local arch_doc_score=$(echo "$arch_doc_result" | jq -r '.score // 3') || arch_doc_score=3
    local runbook_score=$(echo "$runbook_result" | jq -r '.score // 3') || runbook_score=3
    
    # Weight scores (README most important)
    total_score=$(( (readme_score * 3 + api_doc_score * 2 + comment_score * 2 + arch_doc_score + runbook_score) / 9 ))
    
    [ "$total_score" -lt 1 ] && total_score=1
    [ "$total_score" -gt 10 ] && total_score=10
    
    cat << EOF
{
    "overall_score": ${total_score:-5},
    "readme_analysis": $readme_result,
    "api_documentation": $api_doc_result,
    "code_comments": $code_comment_result,
    "architecture_docs": $arch_doc_result,
    "runbooks": $runbook_result
}
EOF
}

# =============================================================================
# README ANALYSIS
# =============================================================================

analyze_readme() {
    local codebase_path="$1"
    local score=0
    local has_readme=false
    local readme_size=0
    local has_badges=false
    local has_installation=false
    local has_usage=false
    local has_contributing=false
    local has_license=false
    
    # Check for README
    local readme_file=""
    for f in "$codebase_path/README.md" "$codebase_path/README.rst" "$codebase_path/README.txt" "$codebase_path/README"; do
        if [ -f "$f" ]; then
            readme_file="$f"
            has_readme=true
            score=$((score + 2))
            break
        fi
    done
    
    if [ "$has_readme" = "true" ] && [ -n "$readme_file" ]; then
        readme_size=$(wc -l < "$readme_file" 2>/dev/null | tr -d ' ')
        
        # Size bonus
        [ "${readme_size:-0}" -gt 50 ] && score=$((score + 1))
        [ "${readme_size:-0}" -gt 100 ] && score=$((score + 1))
        [ "${readme_size:-0}" -gt 200 ] && score=$((score + 1))
        
        local content=$(cat "$readme_file" 2>/dev/null)
        
        # Check for badges
        if echo "$content" | grep -q "\[!\[.*\].*\]("; then
            has_badges=true
            score=$((score + 1))
        fi
        
        # Check for installation section
        if echo "$content" | grep -qi "## Installation\|## Getting Started\|## Setup\|## Quick Start"; then
            has_installation=true
            score=$((score + 1))
        fi
        
        # Check for usage section
        if echo "$content" | grep -qi "## Usage\|## Examples\|## How to Use"; then
            has_usage=true
            score=$((score + 1))
        fi
        
        # Check for contributing section
        if echo "$content" | grep -qi "## Contributing\|CONTRIBUTING.md"; then
            has_contributing=true
            score=$((score + 1))
        fi
        
        # Check for license mention
        if echo "$content" | grep -qi "## License\|LICENSE"; then
            has_license=true
        fi
    fi
    
    # Check for CONTRIBUTING.md
    if [ -f "$codebase_path/CONTRIBUTING.md" ]; then
        score=$((score + 1))
        has_contributing=true
    fi
    
    # Check for LICENSE
    if [ -f "$codebase_path/LICENSE" ] || [ -f "$codebase_path/LICENSE.md" ]; then
        score=$((score + 1))
        has_license=true
    fi
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-0},
    "has_readme": $has_readme,
    "readme_lines": ${readme_size:-0},
    "has_badges": $has_badges,
    "has_installation": $has_installation,
    "has_usage": $has_usage,
    "has_contributing": $has_contributing,
    "has_license": $has_license
}
EOF
}

# =============================================================================
# API DOCUMENTATION ANALYSIS
# =============================================================================

analyze_api_documentation() {
    local codebase_path="$1"
    local score=3
    local has_openapi=false
    local has_swagger=false
    local has_graphql_schema=false
    local has_postman=false
    local has_api_readme=false
    
    # Check for OpenAPI/Swagger
    if find "$codebase_path" -maxdepth 3 -name "openapi*.yaml" -o -name "openapi*.json" -o -name "swagger*.yaml" -o -name "swagger*.json" 2>/dev/null | grep -q .; then
        has_openapi=true
        score=$((score + 2))
    fi
    
    # Check for Swagger UI setup
    if grep -rq "swagger-ui\|SwaggerModule\|swagger-jsdoc" "$codebase_path" 2>/dev/null; then
        has_swagger=true
        score=$((score + 1))
    fi
    
    # Check for GraphQL schema
    if find "$codebase_path" -maxdepth 5 -name "*.graphql" -o -name "schema.gql" 2>/dev/null | grep -q .; then
        has_graphql_schema=true
        score=$((score + 2))
    fi
    
    # Check for Postman collection
    if find "$codebase_path" -maxdepth 3 -name "*.postman_collection.json" -o -name "postman*.json" 2>/dev/null | grep -q .; then
        has_postman=true
        score=$((score + 1))
    fi
    
    # Check for API README or docs folder
    if [ -f "$codebase_path/docs/api.md" ] || [ -f "$codebase_path/API.md" ] || [ -d "$codebase_path/docs/api" ]; then
        has_api_readme=true
        score=$((score + 1))
    fi
    
    # Check for JSDoc/TSDoc in API files
    local jsdoc_count=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" \) \
        -path "*/api/*" -o -path "*/routes/*" -o -path "*/controllers/*" \
        ! -path "*/node_modules/*" \
        -exec grep -c "/\*\*" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "${jsdoc_count:-0}" -gt 10 ] && score=$((score + 1))
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-3},
    "has_openapi": $has_openapi,
    "has_swagger": $has_swagger,
    "has_graphql_schema": $has_graphql_schema,
    "has_postman": $has_postman,
    "has_api_readme": $has_api_readme,
    "jsdoc_api_comments": ${jsdoc_count:-0}
}
EOF
}

# =============================================================================
# CODE COMMENTS ANALYSIS
# =============================================================================

analyze_code_comments() {
    local codebase_path="$1"
    local score=5
    local total_files=0
    local files_with_docs=0
    local doc_coverage=0
    
    # Count source files
    total_files=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.java" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" ! -path "*/venv/*" \
        ! -name "*.test.*" ! -name "*.spec.*" 2>/dev/null | wc -l | tr -d ' ')
    
    # Count files with documentation comments
    files_with_docs=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.java" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" ! -path "*/venv/*" \
        -exec grep -l '/\*\*\|"""\|#.*TODO\|//.*@' {} \; 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "${total_files:-0}" -gt 0 ]; then
        doc_coverage=$((files_with_docs * 100 / total_files))
    fi
    
    # Score based on coverage
    if [ "${doc_coverage:-0}" -gt 70 ]; then
        score=9
    elif [ "${doc_coverage:-0}" -gt 50 ]; then
        score=7
    elif [ "${doc_coverage:-0}" -gt 30 ]; then
        score=5
    elif [ "${doc_coverage:-0}" -gt 10 ]; then
        score=3
    else
        score=2
    fi
    
    # Check for TODO/FIXME comments (not great, but shows awareness)
    local todo_count=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "TODO\|FIXME\|XXX" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    # Too many TODOs is bad
    [ "${todo_count:-0}" -gt 50 ] && score=$((score - 1))
    
    cat << EOF
{
    "score": ${score:-5},
    "total_source_files": ${total_files:-0},
    "files_with_docs": ${files_with_docs:-0},
    "doc_coverage_percent": ${doc_coverage:-0},
    "todo_count": ${todo_count:-0}
}
EOF
}

# =============================================================================
# ARCHITECTURE DOCUMENTATION ANALYSIS
# =============================================================================

analyze_architecture_docs() {
    local codebase_path="$1"
    local score=2
    local has_arch_docs=false
    local has_adr=false
    local has_diagrams=false
    local has_wiki=false
    
    # Check for architecture documentation
    if [ -d "$codebase_path/docs/architecture" ] || [ -f "$codebase_path/ARCHITECTURE.md" ] || [ -f "$codebase_path/docs/ARCHITECTURE.md" ]; then
        has_arch_docs=true
        score=$((score + 3))
    fi
    
    # Check for ADR (Architecture Decision Records)
    if [ -d "$codebase_path/docs/adr" ] || [ -d "$codebase_path/adr" ] || find "$codebase_path" -maxdepth 3 -name "*.adr.md" 2>/dev/null | grep -q .; then
        has_adr=true
        score=$((score + 2))
    fi
    
    # Check for diagrams
    local diagram_count=$(find "$codebase_path" -maxdepth 4 \( -name "*.puml" -o -name "*.mermaid" -o -name "*.drawio" -o -name "*.svg" -o -name "*.png" \) \
        -path "*/docs/*" 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "${diagram_count:-0}" -gt 0 ]; then
        has_diagrams=true
        score=$((score + 2))
    fi
    
    # Check for docs folder with content
    if [ -d "$codebase_path/docs" ]; then
        local doc_files=$(find "$codebase_path/docs" -type f \( -name "*.md" -o -name "*.rst" \) 2>/dev/null | wc -l | tr -d ' ')
        [ "${doc_files:-0}" -gt 5 ] && score=$((score + 1))
        [ "${doc_files:-0}" -gt 10 ] && score=$((score + 1))
    fi
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-2},
    "has_architecture_docs": $has_arch_docs,
    "has_adr": $has_adr,
    "has_diagrams": $has_diagrams,
    "diagram_count": ${diagram_count:-0}
}
EOF
}

# =============================================================================
# RUNBOOKS ANALYSIS
# =============================================================================

analyze_runbooks() {
    local codebase_path="$1"
    local score=2
    local has_runbooks=false
    local has_troubleshooting=false
    local has_deployment_docs=false
    local has_oncall=false
    
    # Check for runbooks
    if [ -d "$codebase_path/runbooks" ] || [ -d "$codebase_path/docs/runbooks" ] || find "$codebase_path" -maxdepth 3 -name "*runbook*" 2>/dev/null | grep -q .; then
        has_runbooks=true
        score=$((score + 3))
    fi
    
    # Check for troubleshooting docs
    if [ -f "$codebase_path/TROUBLESHOOTING.md" ] || [ -f "$codebase_path/docs/TROUBLESHOOTING.md" ]; then
        has_troubleshooting=true
        score=$((score + 2))
    fi
    
    # Check for deployment documentation
    if [ -f "$codebase_path/DEPLOYMENT.md" ] || [ -f "$codebase_path/docs/deployment.md" ] || [ -d "$codebase_path/docs/deployment" ]; then
        has_deployment_docs=true
        score=$((score + 2))
    fi
    
    # Check for on-call/incident documentation
    if find "$codebase_path" -maxdepth 3 \( -name "*oncall*" -o -name "*incident*" -o -name "*playbook*" \) 2>/dev/null | grep -q .; then
        has_oncall=true
        score=$((score + 1))
    fi
    
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-2},
    "has_runbooks": $has_runbooks,
    "has_troubleshooting": $has_troubleshooting,
    "has_deployment_docs": $has_deployment_docs,
    "has_oncall_docs": $has_oncall
}
EOF
}

# Export functions
export -f analyze_documentation analyze_readme analyze_api_documentation analyze_code_comments analyze_architecture_docs analyze_runbooks
