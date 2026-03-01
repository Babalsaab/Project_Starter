#!/bin/bash

# =============================================================================
# Enhanced Code Complexity Analyzer
# =============================================================================
# Analyzes code complexity, maintainability, and technical debt indicators.
# =============================================================================

# Calculate cyclomatic complexity approximation
analyze_complexity() {
    local codebase="$1"
    local results_dir="$2"
    
    local total_files=0
    local complex_files=0
    local very_complex_files=0
    local avg_complexity=0
    local max_complexity=0
    local complexity_sum=0
    
    # Analyze JavaScript/TypeScript files
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        ((total_files++))
        
        local complexity
        complexity=$(calculate_file_complexity "$file")
        
        complexity_sum=$((complexity_sum + complexity))
        
        [ "$complexity" -gt "$max_complexity" ] && max_complexity=$complexity
        [ "$complexity" -gt 10 ] && ((complex_files++))
        [ "$complexity" -gt 20 ] && ((very_complex_files++))
        
    done < <(find "$codebase" \
        \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \
           -o -name "*.py" -o -name "*.go" -o -name "*.java" \) \
        -type f \
        ! -name "*.test.*" ! -name "*.spec.*" ! -name "*_test.*" \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
        ! -path "*/dist/*" ! -path "*/build/*" \
        2>/dev/null | head -200)
    
    if [ "$total_files" -gt 0 ]; then
        avg_complexity=$((complexity_sum / total_files))
    fi
    
    # Calculate complexity score (lower is better)
    local complexity_score=10
    [ "$avg_complexity" -gt 5 ] && complexity_score=8
    [ "$avg_complexity" -gt 10 ] && complexity_score=6
    [ "$avg_complexity" -gt 15 ] && complexity_score=4
    [ "$avg_complexity" -gt 20 ] && complexity_score=2
    
    # Penalize for very complex files
    if [ "$total_files" -gt 0 ]; then
        local complex_ratio=$((complex_files * 100 / total_files))
        [ "$complex_ratio" -gt 20 ] && ((complexity_score--))
        [ "$complex_ratio" -gt 40 ] && ((complexity_score--))
    fi
    
    [ "$complexity_score" -lt 1 ] && complexity_score=1
    
    cat << EOF
{
    "total_files_analyzed": $total_files,
    "complex_files": $complex_files,
    "very_complex_files": $very_complex_files,
    "average_complexity": $avg_complexity,
    "max_complexity": $max_complexity,
    "complexity_score": $complexity_score
}
EOF
}

# Calculate complexity for a single file
calculate_file_complexity() {
    local file="$1"
    local complexity=1
    
    local content
    content=$(cat "$file" 2>/dev/null)
    
    # Count decision points (simplified cyclomatic complexity)
    # Each adds 1 to complexity
    local if_count else_count for_count while_count switch_count case_count
    local try_count catch_count ternary_count logical_count
    
    if_count=$(echo "$content" | grep -cE "\\bif\\s*\\(" 2>/dev/null) || if_count=0
    else_count=$(echo "$content" | grep -cE "\\belse\\s*(if|{)" 2>/dev/null) || else_count=0
    for_count=$(echo "$content" | grep -cE "\\bfor\\s*\\(" 2>/dev/null) || for_count=0
    while_count=$(echo "$content" | grep -cE "\\bwhile\\s*\\(" 2>/dev/null) || while_count=0
    switch_count=$(echo "$content" | grep -cE "\\bswitch\\s*\\(" 2>/dev/null) || switch_count=0
    case_count=$(echo "$content" | grep -cE "\\bcase\\s+" 2>/dev/null) || case_count=0
    try_count=$(echo "$content" | grep -cE "\\btry\\s*{" 2>/dev/null) || try_count=0
    catch_count=$(echo "$content" | grep -cE "\\bcatch\\s*\\(" 2>/dev/null) || catch_count=0
    ternary_count=$(echo "$content" | grep -cE "\\?.*:" 2>/dev/null) || ternary_count=0
    logical_count=$(echo "$content" | grep -cE "&&|\\|\\|" 2>/dev/null) || logical_count=0
    
    # Ensure all values are numeric
    if_count=${if_count:-0}; else_count=${else_count:-0}
    for_count=${for_count:-0}; while_count=${while_count:-0}
    switch_count=${switch_count:-0}; case_count=${case_count:-0}
    try_count=${try_count:-0}; catch_count=${catch_count:-0}
    ternary_count=${ternary_count:-0}; logical_count=${logical_count:-0}
    
    # Safe division with default
    local case_contrib=0 logical_contrib=0
    [ "$case_count" -gt 0 ] 2>/dev/null && case_contrib=$((case_count / 2))
    [ "$logical_count" -gt 0 ] 2>/dev/null && logical_contrib=$((logical_count / 3))
    
    complexity=$((1 + if_count + else_count + for_count + while_count + switch_count + case_contrib + try_count + catch_count + ternary_count + logical_contrib))
    
    # Normalize by lines of code
    local loc
    loc=$(wc -l < "$file" 2>/dev/null | tr -d ' ')
    
    if [ "$loc" -gt 100 ]; then
        complexity=$((complexity * 100 / loc + complexity / 2))
    fi
    
    echo "$complexity"
}

# Analyze code duplication
analyze_duplication() {
    local codebase="$1"
    
    local duplicate_score=10
    local duplicate_blocks=0
    local duplicate_lines=0
    
    # Use jscpd if available
    if command -v jscpd &>/dev/null; then
        local jscpd_output
        jscpd_output=$(jscpd "$codebase" --min-lines 5 --min-tokens 50 \
            --ignore "**/node_modules/**,**/dist/**,**/build/**,**/*.min.js" \
            --reporters json 2>/dev/null)
        
        if [ -n "$jscpd_output" ]; then
            duplicate_blocks=$(echo "$jscpd_output" | jq '.statistics.clones // 0' 2>/dev/null || echo "0")
            local dup_percent
            dup_percent=$(echo "$jscpd_output" | jq '.statistics.percentage // 0' 2>/dev/null | cut -d. -f1)
            
            [ "$dup_percent" -gt 3 ] && duplicate_score=8
            [ "$dup_percent" -gt 5 ] && duplicate_score=6
            [ "$dup_percent" -gt 10 ] && duplicate_score=4
            [ "$dup_percent" -gt 20 ] && duplicate_score=2
        fi
    else
        # Simple duplication detection
        local source_files
        source_files=$(find "$codebase" \
            \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.java" \) \
            -type f \
            ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
            ! -path "*/dist/*" ! -path "*/build/*" \
            2>/dev/null | head -100)
        
        # Look for identical function signatures
        local function_sigs
        function_sigs=$(echo "$source_files" | xargs -I {} grep -hoE "function\\s+\\w+\\s*\\([^)]*\\)|def\\s+\\w+\\s*\\([^)]*\\)|func\\s+\\w+\\s*\\([^)]*\\)" {} 2>/dev/null | sort | uniq -d | wc -l | tr -d ' ')
        
        if [ "$function_sigs" -gt 5 ]; then
            duplicate_score=7
        fi
        if [ "$function_sigs" -gt 15 ]; then
            duplicate_score=5
        fi
    fi
    
    cat << EOF
{
    "duplicate_blocks": $duplicate_blocks,
    "duplicate_score": $duplicate_score
}
EOF
}

# Analyze maintainability index
analyze_maintainability() {
    local codebase="$1"
    
    local maintainability_score=5
    local indicators=()
    
    # Positive indicators
    local has_readme=false
    local has_contributing=false
    local has_changelog=false
    local has_license=false
    local has_editorconfig=false
    local has_prettier=false
    local has_eslint=false
    local has_tests=false
    local has_ci=false
    local has_types=false
    
    [ -f "$codebase/README.md" ] && has_readme=true && ((maintainability_score++))
    [ -f "$codebase/CONTRIBUTING.md" ] && has_contributing=true && ((maintainability_score++))
    [ -f "$codebase/CHANGELOG.md" ] && has_changelog=true && ((maintainability_score++))
    [ -f "$codebase/LICENSE" ] && has_license=true
    [ -f "$codebase/.editorconfig" ] && has_editorconfig=true && ((maintainability_score++))
    
    # Check for linting/formatting
    if [ -f "$codebase/.prettierrc" ] || [ -f "$codebase/.prettierrc.js" ] || \
       [ -f "$codebase/prettier.config.js" ]; then
        has_prettier=true
        ((maintainability_score++))
    fi
    
    if [ -f "$codebase/.eslintrc" ] || [ -f "$codebase/.eslintrc.js" ] || \
       [ -f "$codebase/.eslintrc.json" ] || [ -f "$codebase/eslint.config.js" ]; then
        has_eslint=true
        ((maintainability_score++))
    fi
    
    # Check for tests
    if find "$codebase" -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" 2>/dev/null | head -1 | grep -q .; then
        has_tests=true
        ((maintainability_score++))
    fi
    
    # Check for CI
    if [ -d "$codebase/.github/workflows" ] || [ -f "$codebase/.gitlab-ci.yml" ] || \
       [ -f "$codebase/Jenkinsfile" ] || [ -f "$codebase/.circleci/config.yml" ]; then
        has_ci=true
        ((maintainability_score++))
    fi
    
    # Check for type definitions
    if [ -f "$codebase/tsconfig.json" ] || \
       grep -rql "from 'prop-types'" "$codebase" --include="*.js" --include="*.jsx" 2>/dev/null; then
        has_types=true
        ((maintainability_score++))
    fi
    
    # Check for Python type hints
    if grep -rql "def.*->.*:" "$codebase" --include="*.py" 2>/dev/null; then
        has_types=true
        ((maintainability_score++))
    fi
    
    [ "$maintainability_score" -gt 10 ] && maintainability_score=10
    
    cat << EOF
{
    "maintainability_score": $maintainability_score,
    "has_readme": $has_readme,
    "has_contributing": $has_contributing,
    "has_changelog": $has_changelog,
    "has_license": $has_license,
    "has_editorconfig": $has_editorconfig,
    "has_prettier": $has_prettier,
    "has_eslint": $has_eslint,
    "has_tests": $has_tests,
    "has_ci": $has_ci,
    "has_types": $has_types
}
EOF
}

# Analyze technical debt indicators
analyze_technical_debt() {
    local codebase="$1"
    
    local debt_score=10
    local todo_count=0
    local fixme_count=0
    local hack_count=0
    local deprecated_count=0
    local console_count=0
    
    # Count debt markers
    todo_count=$(grep -rE "TODO|@todo" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    fixme_count=$(grep -rE "FIXME|@fixme" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    hack_count=$(grep -rE "HACK|XXX|KLUDGE" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    deprecated_count=$(grep -rE "@deprecated|DEPRECATED" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    # Console.log in production code (excluding tests)
    console_count=$(grep -rE "console\\.log\\(" "$codebase" \
        --include="*.js" --include="*.ts" \
        ! -name "*.test.*" ! -name "*.spec.*" \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    # Calculate debt score
    local total_markers=$((todo_count + fixme_count * 2 + hack_count * 3))
    
    [ "$total_markers" -gt 5 ] && ((debt_score--))
    [ "$total_markers" -gt 15 ] && ((debt_score--))
    [ "$total_markers" -gt 30 ] && ((debt_score--))
    [ "$total_markers" -gt 50 ] && ((debt_score--))
    [ "$total_markers" -gt 100 ] && ((debt_score--))
    
    [ "$console_count" -gt 10 ] && ((debt_score--))
    [ "$deprecated_count" -gt 5 ] && ((debt_score--))
    
    [ "$debt_score" -lt 1 ] && debt_score=1
    
    cat << EOF
{
    "debt_score": $debt_score,
    "todo_count": $todo_count,
    "fixme_count": $fixme_count,
    "hack_count": $hack_count,
    "deprecated_count": $deprecated_count,
    "console_log_count": $console_count,
    "total_debt_markers": $total_markers
}
EOF
}

# Export functions
export -f analyze_complexity 2>/dev/null || true
export -f calculate_file_complexity 2>/dev/null || true
export -f analyze_duplication 2>/dev/null || true
export -f analyze_maintainability 2>/dev/null || true
export -f analyze_technical_debt 2>/dev/null || true
