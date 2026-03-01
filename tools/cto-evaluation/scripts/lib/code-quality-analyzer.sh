#!/bin/bash

# =============================================================================
# ENHANCED CODE QUALITY ANALYZER
# =============================================================================
# Deep analysis of code quality, style, and best practices
# Supports: Multi-language detection, complexity analysis, code smells
# =============================================================================

# =============================================================================
# MAIN CODE QUALITY ANALYSIS
# =============================================================================

analyze_code_quality() {
    local codebase_path="$1"
    local output_dir="${2:-${TMPDIR:-/tmp}/quality-analysis}"
    
    mkdir -p "$output_dir"
    
    # Run all quality checks
    local style_result=$(check_code_style "$codebase_path")
    local smell_result=$(check_code_smells "$codebase_path")
    local naming_result=$(check_naming_conventions "$codebase_path")
    local doc_result=$(check_code_documentation "$codebase_path")
    local type_result=$(check_type_safety "$codebase_path")
    local lint_result=$(check_linting_config "$codebase_path")
    
    # Calculate scores
    local style_score=$(echo "$style_result" | jq -r '.score // 5')
    local smell_score=$(echo "$smell_result" | jq -r '.score // 5')
    local naming_score=$(echo "$naming_result" | jq -r '.score // 5')
    local doc_score=$(echo "$doc_result" | jq -r '.score // 5')
    local type_score=$(echo "$type_result" | jq -r '.score // 5')
    local lint_score=$(echo "$lint_result" | jq -r '.score // 5')
    
    local overall_score=$(( (style_score + smell_score + naming_score + doc_score + type_score + lint_score) / 6 ))
    
    cat << EOF
{
    "overall_score": $overall_score,
    "style_analysis": $style_result,
    "smell_analysis": $smell_result,
    "naming_analysis": $naming_result,
    "documentation_analysis": $doc_result,
    "type_safety": $type_result,
    "linting_config": $lint_result
}
EOF
}

# =============================================================================
# CODE STYLE CHECK
# =============================================================================

check_code_style() {
    local codebase_path="$1"
    local score=5
    local good_practices=0
    local issues=0
    
    # Check for formatting tools
    
    # Prettier (JS/TS)
    if [ -f "$codebase_path/.prettierrc" ] || [ -f "$codebase_path/.prettierrc.js" ] || \
       [ -f "$codebase_path/.prettierrc.json" ] || [ -f "$codebase_path/prettier.config.js" ]; then
        good_practices=$((good_practices + 2))
    fi
    
    # Check for prettier in package.json
    if [ -f "$codebase_path/package.json" ]; then
        if grep -q '"prettier"' "$codebase_path/package.json" 2>/dev/null; then
            good_practices=$((good_practices + 1))
        fi
    fi
    
    # Black/autopep8 (Python)
    if [ -f "$codebase_path/pyproject.toml" ]; then
        if grep -qE '\[tool\.black\]|\[tool\.autopep8\]|\[tool\.yapf\]' "$codebase_path/pyproject.toml" 2>/dev/null; then
            good_practices=$((good_practices + 2))
        fi
    fi
    
    # Gofmt check - look for go.mod
    if [ -f "$codebase_path/go.mod" ]; then
        good_practices=$((good_practices + 1))  # Go has built-in formatting
    fi
    
    # Rustfmt
    if [ -f "$codebase_path/rustfmt.toml" ] || [ -f "$codebase_path/.rustfmt.toml" ]; then
        good_practices=$((good_practices + 2))
    fi
    
    # EditorConfig
    if [ -f "$codebase_path/.editorconfig" ]; then
        good_practices=$((good_practices + 1))
    fi
    
    # Check for consistent indentation
    # Sample some files and check for mixed tabs/spaces
    local mixed_indentation=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/venv/*" \
        -exec grep -l $'^\t' {} \; 2>/dev/null | head -20 | wc -l)
    
    local space_indentation=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/venv/*" \
        -exec grep -l '^  ' {} \; 2>/dev/null | head -20 | wc -l)
    
    # If both tabs and spaces are used significantly, that's an issue
    if [ "$mixed_indentation" -gt 3 ] && [ "$space_indentation" -gt 3 ]; then
        issues=$((issues + 1))
    fi
    
    # Check for format scripts
    if [ -f "$codebase_path/package.json" ]; then
        if grep -qE '"format"|"prettier"|"lint:fix"' "$codebase_path/package.json" 2>/dev/null; then
            good_practices=$((good_practices + 1))
        fi
    fi
    
    score=$((5 + good_practices - issues))
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "good_practices": $good_practices,
    "issues": $issues,
    "has_prettier": $([ -f "$codebase_path/.prettierrc" ] && echo "true" || echo "false"),
    "has_editorconfig": $([ -f "$codebase_path/.editorconfig" ] && echo "true" || echo "false"),
    "mixed_indentation": $([ "$mixed_indentation" -gt 3 ] && [ "$space_indentation" -gt 3 ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# CODE SMELLS CHECK
# =============================================================================

check_code_smells() {
    local codebase_path="$1"
    local score=8
    local smells_found=0
    
    # Long functions (>100 lines)
    # This is a simplified check - count functions with many lines
    local long_functions=0
    
    # JavaScript/TypeScript
    if [ -f "$codebase_path/package.json" ]; then
        # Count files with very long function definitions
        long_functions=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" \) \
            ! -path "*/node_modules/*" \
            ! -path "*/dist/*" \
            -exec awk '/^(export )?(async )?function|^const.*=.*\(.*\).*=>|^(export )?(async )?.*\(.*\).*{/ {count++} END {if(count>10) print FILENAME}' {} \; 2>/dev/null | wc -l)
    fi
    
    # Large files (>500 lines)
    local large_files=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.java" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/vendor/*" \
        ! -path "*/venv/*" \
        ! -path "*/dist/*" \
        -exec wc -l {} \; 2>/dev/null | awk '$1 > 500 {count++} END {print count+0}')
    
    smells_found=$((smells_found + large_files / 3))
    
    # God classes/files (many responsibilities)
    local god_classes=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/vendor/*" \
        ! -path "*/venv/*" \
        -exec grep -c "class\s\|export\s\+function\|def\s\+\w\+(" {} \; 2>/dev/null | awk '$1 > 20 {count++} END {print count+0}')
    
    smells_found=$((smells_found + god_classes))
    
    # Duplicated code patterns (simplified)
    # Look for files with identical structure
    local potential_duplication=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/dist/*" \
        -exec md5 -q {} \; 2>/dev/null | sort | uniq -d | wc -l)
    
    smells_found=$((smells_found + potential_duplication))
    
    # Magic numbers
    local magic_numbers=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/venv/*" \
        ! -path "*test*" \
        -exec grep -c '[^a-zA-Z0-9_][0-9]\{3,\}[^a-zA-Z0-9_]' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "$magic_numbers" -gt 50 ]; then
        smells_found=$((smells_found + 1))
    fi
    
    # Deeply nested code (>4 levels)
    local deep_nesting=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/venv/*" \
        -exec grep -c '^\s\{16,\}\S' {} \; 2>/dev/null | awk '$1 > 10 {count++} END {print count+0}')
    
    smells_found=$((smells_found + deep_nesting))
    
    # Commented out code
    local commented_code=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/venv/*" \
        -exec grep -c '^\s*//.*function\|^\s*//.*const\|^\s*#.*def\s' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "$commented_code" -gt 20 ]; then
        smells_found=$((smells_found + 1))
    fi
    
    score=$((8 - smells_found))
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "smells_found": $smells_found,
    "large_files": $large_files,
    "god_classes": $god_classes,
    "deep_nesting": $deep_nesting,
    "magic_numbers": $magic_numbers
}
EOF
}

# =============================================================================
# NAMING CONVENTIONS CHECK
# =============================================================================

check_naming_conventions() {
    local codebase_path="$1"
    local score=7
    local good_patterns=0
    local bad_patterns=0
    
    # Check for consistent naming in JS/TS
    if [ -f "$codebase_path/package.json" ]; then
        # camelCase for functions
        local camel_functions=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" \) \
            ! -path "*/node_modules/*" \
            -exec grep -c 'function [a-z][a-zA-Z0-9]*\|const [a-z][a-zA-Z0-9]* = (' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        
        # PascalCase for classes/components
        local pascal_classes=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) \
            ! -path "*/node_modules/*" \
            -exec grep -c 'class [A-Z][a-zA-Z0-9]*\|function [A-Z][a-zA-Z0-9]*Component\|const [A-Z][a-zA-Z0-9]* =' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        
        # UPPER_SNAKE_CASE for constants
        local upper_constants=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" \) \
            ! -path "*/node_modules/*" \
            -exec grep -c 'const [A-Z][A-Z_0-9]* =' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        
        [ "$camel_functions" -gt 20 ] && good_patterns=$((good_patterns + 1))
        [ "$pascal_classes" -gt 5 ] && good_patterns=$((good_patterns + 1))
        [ "$upper_constants" -gt 5 ] && good_patterns=$((good_patterns + 1))
    fi
    
    # Check Python naming (PEP 8)
    local py_files=$(find "$codebase_path" -name "*.py" ! -path "*/venv/*" 2>/dev/null | wc -l)
    if [ "$py_files" -gt 0 ]; then
        # snake_case for functions
        local snake_functions=$(find "$codebase_path" -type f -name "*.py" \
            ! -path "*/venv/*" \
            -exec grep -c 'def [a-z][a-z_0-9]*(' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        
        # PascalCase for classes
        local pascal_py_classes=$(find "$codebase_path" -type f -name "*.py" \
            ! -path "*/venv/*" \
            -exec grep -c 'class [A-Z][a-zA-Z0-9]*' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        
        [ "$snake_functions" -gt 10 ] && good_patterns=$((good_patterns + 1))
        [ "$pascal_py_classes" -gt 3 ] && good_patterns=$((good_patterns + 1))
    fi
    
    # Check for bad naming patterns
    # Single letter variables (outside loops)
    local single_letter=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/venv/*" \
        -exec grep -c 'const [a-z] =\|let [a-z] =\|var [a-z] =\|[a-z] = ' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "$single_letter" -gt 50 ]; then
        bad_patterns=$((bad_patterns + 1))
    fi
    
    # Abbreviations
    local abbreviations=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/venv/*" \
        -exec grep -c '\bstr\b\|\bnum\b\|\barr\b\|\bobj\b\|\btmp\b\|\bval\b' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "$abbreviations" -gt 30 ]; then
        bad_patterns=$((bad_patterns + 1))
    fi
    
    score=$((6 + good_patterns - bad_patterns))
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "good_patterns": $good_patterns,
    "bad_patterns": $bad_patterns,
    "single_letter_vars": $single_letter,
    "abbreviations": $abbreviations
}
EOF
}

# =============================================================================
# CODE DOCUMENTATION CHECK
# =============================================================================

check_code_documentation() {
    local codebase_path="$1"
    local score=5
    local doc_coverage=0
    
    # Check for JSDoc/TSDoc comments
    local jsdoc_comments=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/dist/*" \
        -exec grep -c '/\*\*' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    local js_functions=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/dist/*" \
        -exec grep -c 'function\s\|=>\s*{' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "$js_functions" -gt 0 ]; then
        doc_coverage=$((jsdoc_comments * 100 / js_functions))
    fi
    
    # Check for Python docstrings
    local python_docstrings=$(find "$codebase_path" -type f -name "*.py" \
        ! -path "*/venv/*" \
        -exec grep -c '"""' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    local python_functions=$(find "$codebase_path" -type f -name "*.py" \
        ! -path "*/venv/*" \
        -exec grep -c 'def ' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "$python_functions" -gt 0 ]; then
        local py_doc_coverage=$((python_docstrings * 50 / python_functions))
        doc_coverage=$(( (doc_coverage + py_doc_coverage) / 2 ))
    fi
    
    # Check for Go documentation
    local go_comments=$(find "$codebase_path" -type f -name "*.go" \
        ! -path "*/vendor/*" \
        -exec grep -c '^// ' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    # Check for README in key directories
    local readme_count=$(find "$codebase_path" -name "README*" -type f 2>/dev/null | wc -l)
    [ "$readme_count" -gt 2 ] && doc_coverage=$((doc_coverage + 10))
    
    # Check for API documentation
    local api_docs=$(find "$codebase_path" -type f \( -name "openapi.*" -o -name "swagger.*" -o -name "*.apib" \) 2>/dev/null | wc -l)
    [ "$api_docs" -gt 0 ] && doc_coverage=$((doc_coverage + 10))
    
    # Check for inline comments ratio
    local inline_comments=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/venv/*" \
        -exec grep -c '^\s*//\|^\s*#' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    local total_lines=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/venv/*" \
        -exec wc -l {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "$total_lines" -gt 0 ]; then
        local comment_ratio=$((inline_comments * 100 / total_lines))
        if [ "$comment_ratio" -gt 5 ] && [ "$comment_ratio" -lt 30 ]; then
            doc_coverage=$((doc_coverage + 5))
        fi
    fi
    
    # Calculate score based on coverage
    if [ "$doc_coverage" -gt 50 ]; then
        score=9
    elif [ "$doc_coverage" -gt 30 ]; then
        score=7
    elif [ "$doc_coverage" -gt 15 ]; then
        score=5
    else
        score=3
    fi
    
    cat << EOF
{
    "score": $score,
    "doc_coverage_estimate": $doc_coverage,
    "jsdoc_comments": $jsdoc_comments,
    "python_docstrings": $python_docstrings,
    "readme_count": $readme_count,
    "api_docs": $([ "$api_docs" -gt 0 ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# TYPE SAFETY CHECK
# =============================================================================

check_type_safety() {
    local codebase_path="$1"
    local score=5
    local implementations=0
    
    # Check for TypeScript
    if [ -f "$codebase_path/tsconfig.json" ]; then
        implementations=$((implementations + 3))
        
        # Check for strict mode
        if grep -q '"strict":\s*true' "$codebase_path/tsconfig.json" 2>/dev/null; then
            implementations=$((implementations + 2))
        fi
        
        # Check for strictNullChecks
        if grep -q '"strictNullChecks":\s*true' "$codebase_path/tsconfig.json" 2>/dev/null; then
            implementations=$((implementations + 1))
        fi
        
        # Check for noImplicitAny
        if grep -q '"noImplicitAny":\s*true' "$codebase_path/tsconfig.json" 2>/dev/null; then
            implementations=$((implementations + 1))
        fi
    fi
    
    # Check for Python type hints
    local type_hints=$(find "$codebase_path" -type f -name "*.py" \
        ! -path "*/venv/*" \
        -exec grep -c ': str\|: int\|: bool\|: List\|: Dict\|-> ' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "$type_hints" -gt 50 ]; then
        implementations=$((implementations + 2))
    elif [ "$type_hints" -gt 10 ]; then
        implementations=$((implementations + 1))
    fi
    
    # Check for mypy configuration
    if [ -f "$codebase_path/mypy.ini" ] || [ -f "$codebase_path/.mypy.ini" ] || \
       grep -q '\[tool\.mypy\]' "$codebase_path/pyproject.toml" 2>/dev/null; then
        implementations=$((implementations + 2))
    fi
    
    # Check for Flow
    if [ -f "$codebase_path/.flowconfig" ]; then
        implementations=$((implementations + 2))
    fi
    
    # Check for PropTypes (React)
    local prop_types=$(find "$codebase_path" -type f \( -name "*.jsx" -o -name "*.js" \) \
        ! -path "*/node_modules/*" \
        -exec grep -c "PropTypes\." {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "$prop_types" -gt 10 ] && implementations=$((implementations + 1))
    
    # Check for Zod/Yup/Joi (runtime validation)
    local runtime_validation=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" \) \
        ! -path "*/node_modules/*" \
        -exec grep -c "zod\|z\.\|Yup\.|Joi\." {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    [ "$runtime_validation" -gt 5 ] && implementations=$((implementations + 1))
    
    score=$((3 + implementations))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "implementations": $implementations,
    "typescript": $([ -f "$codebase_path/tsconfig.json" ] && echo "true" || echo "false"),
    "typescript_strict": $(grep -q '"strict":\s*true' "$codebase_path/tsconfig.json" 2>/dev/null && echo "true" || echo "false"),
    "python_type_hints": $type_hints,
    "mypy": $([ -f "$codebase_path/mypy.ini" ] && echo "true" || echo "false"),
    "runtime_validation": $runtime_validation
}
EOF
}

# =============================================================================
# LINTING CONFIG CHECK
# =============================================================================

check_linting_config() {
    local codebase_path="$1"
    local score=5
    local configs=0
    
    # ESLint
    if [ -f "$codebase_path/.eslintrc" ] || [ -f "$codebase_path/.eslintrc.js" ] || \
       [ -f "$codebase_path/.eslintrc.json" ] || [ -f "$codebase_path/.eslintrc.yml" ] || \
       [ -f "$codebase_path/eslint.config.js" ]; then
        configs=$((configs + 2))
    fi
    
    # Check for ESLint in package.json
    if [ -f "$codebase_path/package.json" ]; then
        if grep -q '"eslint"' "$codebase_path/package.json" 2>/dev/null; then
            configs=$((configs + 1))
        fi
    fi
    
    # Pylint/Flake8/Ruff
    if [ -f "$codebase_path/.pylintrc" ] || [ -f "$codebase_path/pylintrc" ]; then
        configs=$((configs + 2))
    fi
    
    if [ -f "$codebase_path/.flake8" ] || [ -f "$codebase_path/setup.cfg" ]; then
        if grep -q '\[flake8\]' "$codebase_path/setup.cfg" 2>/dev/null || [ -f "$codebase_path/.flake8" ]; then
            configs=$((configs + 2))
        fi
    fi
    
    if [ -f "$codebase_path/ruff.toml" ] || grep -q '\[tool\.ruff\]' "$codebase_path/pyproject.toml" 2>/dev/null; then
        configs=$((configs + 2))
    fi
    
    # golangci-lint
    if [ -f "$codebase_path/.golangci.yml" ] || [ -f "$codebase_path/.golangci.yaml" ]; then
        configs=$((configs + 2))
    fi
    
    # Clippy (Rust)
    if [ -f "$codebase_path/clippy.toml" ] || [ -f "$codebase_path/.clippy.toml" ]; then
        configs=$((configs + 2))
    fi
    
    # RuboCop
    if [ -f "$codebase_path/.rubocop.yml" ]; then
        configs=$((configs + 2))
    fi
    
    # Check for lint scripts in package.json
    if [ -f "$codebase_path/package.json" ]; then
        if grep -qE '"lint":|"lint:' "$codebase_path/package.json" 2>/dev/null; then
            configs=$((configs + 1))
        fi
    fi
    
    # Check for pre-commit hooks
    if [ -f "$codebase_path/.pre-commit-config.yaml" ] || [ -f "$codebase_path/.husky/pre-commit" ]; then
        configs=$((configs + 1))
    fi
    
    score=$((3 + configs))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "configs": $configs,
    "eslint": $([ -f "$codebase_path/.eslintrc.js" ] || [ -f "$codebase_path/.eslintrc.json" ] && echo "true" || echo "false"),
    "pylint": $([ -f "$codebase_path/.pylintrc" ] && echo "true" || echo "false"),
    "flake8": $([ -f "$codebase_path/.flake8" ] && echo "true" || echo "false"),
    "ruff": $(grep -q '\[tool\.ruff\]' "$codebase_path/pyproject.toml" 2>/dev/null && echo "true" || echo "false"),
    "golangci": $([ -f "$codebase_path/.golangci.yml" ] && echo "true" || echo "false"),
    "pre_commit": $([ -f "$codebase_path/.pre-commit-config.yaml" ] && echo "true" || echo "false")
}
EOF
}
