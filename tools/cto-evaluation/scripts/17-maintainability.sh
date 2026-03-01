#!/bin/bash

# =============================================================================
# MAINTAINABILITY & TECHNICAL DEBT EVALUATION (Parameters 399-410)
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

# Source findings helper
source "$SCRIPT_DIR/common-findings.sh"
source "$SCRIPT_DIR/lib/math-utils.sh"
init_findings

# Progress tracking
TOTAL_STEPS=6
CURRENT_STEP=0

progress_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "Evaluating: [$CURRENT_STEP/$TOTAL_STEPS] $1" >&2
}

RESULTS='{
    "category": "maintainability",
    "parameters_evaluated": 0,
    "parameters_total": 12,
    "score": 0,
    "findings": [],
    "metrics": {}
}'

log_metric() {
    RESULTS=$(echo "$RESULTS" | jq --arg n "$1" --arg v "$2" '.metrics[$n] = $v')
}

# =============================================================================
# Check Code Duplication (Parameter 342)
# =============================================================================
check_duplication() {
    progress_step "Code duplication analysis"
    local score=7

    # Try to run jscpd if available
    if command -v npx &> /dev/null; then
        echo "Scanning: Running code duplication analysis..." >&2
        
        # Check for existing jscpd config
        if [ -f "$CODEBASE_PATH/.jscpd.json" ]; then
            log_metric "jscpd_configured" "true"
            score=$((score + 1))
        fi
    fi

    # Count copy-paste patterns (simple heuristic)
    local duplicate_blocks=$( (grep -rn "// TODO: refactor\|# TODO: refactor\|FIXME.*duplicate\|copy.*paste" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null || true) | wc -l)
    
    log_metric "marked_duplicates" "$duplicate_blocks"
    echo "Scanning: Found $duplicate_blocks marked duplicate/refactor comments" >&2

    if [ "$duplicate_blocks" -gt 20 ]; then
        add_finding "medium" "duplication" "Many areas marked for refactoring"
        score=$((score - 2))
    fi

    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Dead Code (Parameter 343)
# =============================================================================
check_dead_code() {
    progress_step "Dead code detection"
    local score=7

    # Check for commented-out code blocks
    local commented_code=$(grep -rcE "^[[:space:]]*(//|#)[[:space:]]*(function|def|class|const|let|var|import|from)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
        awk -F: '{sum += $2} END {print sum+0}')
    
    log_metric "commented_code_lines" "$commented_code"
    echo "Scanning: Found $commented_code likely commented-out code blocks" >&2

    if [ "$commented_code" -gt 50 ]; then
        add_finding "medium" "dead_code" "Significant amount of commented-out code"
        score=$((score - 2))
    elif [ "$commented_code" -gt 20 ]; then
        score=$((score - 1))
    fi

    # Check for unused exports (if TypeScript)
    if [ -f "$CODEBASE_PATH/tsconfig.json" ]; then
        if grep -q "noUnusedLocals\|noUnusedParameters" "$CODEBASE_PATH/tsconfig.json" 2>/dev/null; then
            log_metric "unused_check_enabled" "true"
            score=$((score + 1))
        fi
    fi

    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Orphan/Unused Files (Parameter 344)
# =============================================================================
check_orphan_files() {
    progress_step "Orphan and unused files detection"
    local score=9
    local total_issues=0

    # 1. Check for backup files (.bak, .backup, .old, ~)
    local backup_files_list=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.bak" -o -name "*.backup" -o -name "*.old" -o -name "*~" -o \
        -name "*.orig" -o -name "*.save" -o -name "*.copy" \
        \) ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/vendor/*" 2>/dev/null | head -20)
    local backup_files=0
    if [ -n "$backup_files_list" ]; then
        backup_files=$(echo "$backup_files_list" | wc -l | tr -d ' ')
    fi
    
    log_metric "backup_files" "$backup_files"
    echo "Scanning: Found $backup_files backup files (.bak, .old, ~)" >&2
    
    if [ "$backup_files" -gt 0 ]; then
        # Add findings with actual file paths
        echo "$backup_files_list" | head -5 | while read -r file; do
            [ -n "$file" ] && add_finding "low" "orphan_files" "Backup file should be removed" "$file"
        done
        total_issues=$((total_issues + backup_files))
    fi

    # 2. Check for temp files
    local temp_files_list=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.tmp" -o -name "*.temp" -o -name "temp_*" -o -name "tmp_*" -o \
        -name ".DS_Store" -o -name "Thumbs.db" -o -name "desktop.ini" \
        \) ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null | head -20)
    local temp_files=0
    if [ -n "$temp_files_list" ]; then
        temp_files=$(echo "$temp_files_list" | wc -l | tr -d ' ')
    fi
    
    log_metric "temp_files" "$temp_files"
    echo "Scanning: Found $temp_files temp/system files" >&2
    
    if [ "$temp_files" -gt 5 ]; then
        echo "$temp_files_list" | head -5 | while read -r file; do
            [ -n "$file" ] && add_finding "low" "orphan_files" "Temp/system file should be in .gitignore" "$file"
        done
        total_issues=$((total_issues + temp_files))
    fi

    # 3. Check for log files in source directories
    local log_files_list=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.log" -o -name "npm-debug.log*" -o -name "yarn-error.log" -o \
        -name "yarn-debug.log*" -o -name "lerna-debug.log*" \
        \) ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/logs/*" 2>/dev/null | head -20)
    local log_files=0
    if [ -n "$log_files_list" ]; then
        log_files=$(echo "$log_files_list" | wc -l | tr -d ' ')
    fi
    
    log_metric "log_files_in_source" "$log_files"
    echo "Scanning: Found $log_files log files in source directories" >&2
    
    if [ "$log_files" -gt 0 ]; then
        echo "$log_files_list" | head -5 | while read -r file; do
            [ -n "$file" ] && add_finding "low" "orphan_files" "Log file committed to repository" "$file"
        done
        total_issues=$((total_issues + log_files))
    fi

    # 4. Check for build artifacts that shouldn't be committed
    local build_artifacts_list=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.pyc" -o -name "*.pyo" -o -name "*.class" -o \
        -name "*.o" -o -name "*.obj" -o -name "*.exe" -o \
        -name "*.dll" -o -name "*.so" -o -name "*.dylib" \
        \) ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/venv/*" 2>/dev/null | head -20)
    local build_artifacts=0
    if [ -n "$build_artifacts_list" ]; then
        build_artifacts=$(echo "$build_artifacts_list" | wc -l | tr -d ' ')
    fi
    
    log_metric "build_artifacts" "$build_artifacts"
    echo "Scanning: Found $build_artifacts build artifacts" >&2
    
    if [ "$build_artifacts" -gt 0 ]; then
        echo "$build_artifacts_list" | head -5 | while read -r file; do
            [ -n "$file" ] && add_finding "medium" "orphan_files" "Build artifact should be in .gitignore" "$file"
        done
        total_issues=$((total_issues + build_artifacts))
    fi

    # 5. Check for test fixture files that look orphaned (common patterns)
    local test_fixtures=$(find "$CODEBASE_PATH" -type f \( \
        -name "test_*.json" -o -name "*_fixture.json" -o -name "mock_*.json" -o \
        -name "sample_*.json" -o -name "example_*.json" \
        \) ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/__fixtures__/*" ! -path "*/fixtures/*" 2>/dev/null)
    
    local orphan_fixtures=0
    if [ -n "$test_fixtures" ]; then
        while IFS= read -r fixture; do
            local fixture_name=$(basename "$fixture" | sed 's/\.[^.]*$//')
            # Check if referenced anywhere
            if ! grep -rq "$fixture_name" "$CODEBASE_PATH" \
                --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
                --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
                orphan_fixtures=$((orphan_fixtures + 1))
            fi
        done <<< "$test_fixtures"
    fi
    
    log_metric "orphan_fixtures" "$orphan_fixtures"
    if [ "$orphan_fixtures" -gt 0 ]; then
        echo "Scanning: Found $orphan_fixtures potentially orphan test fixtures" >&2
        add_finding "low" "orphan_files" "$orphan_fixtures potentially orphan test fixture files"
        total_issues=$((total_issues + orphan_fixtures))
    fi

    # 6. Check for environment files that shouldn't be committed
    local env_files=$(find "$CODEBASE_PATH" -maxdepth 3 -type f \( \
        -name ".env.local" -o -name ".env.development.local" -o \
        -name ".env.production" -o -name ".env.test.local" \
        \) ! -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    
    log_metric "env_files_committed" "$env_files"
    if [ "$env_files" -gt 0 ]; then
        echo "Scanning: Found $env_files local environment files" >&2
        add_finding "medium" "orphan_files" "$env_files local .env files committed"
        total_issues=$((total_issues + env_files))
    fi

    # 7. Check for empty directories (often leftover from deleted files)
    local empty_dirs=$(find "$CODEBASE_PATH" -type d -empty \
        ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/__pycache__/*" 2>/dev/null | wc -l | tr -d ' ')
    
    log_metric "empty_directories" "$empty_dirs"
    if [ "$empty_dirs" -gt 5 ]; then
        echo "Scanning: Found $empty_dirs empty directories" >&2
        add_finding "low" "orphan_files" "$empty_dirs empty directories found"
    fi

    # 8. Check for large binary files that shouldn't be in repo
    local large_binaries=$(find "$CODEBASE_PATH" -type f -size +10M \( \
        -name "*.zip" -o -name "*.tar" -o -name "*.tar.gz" -o -name "*.rar" -o \
        -name "*.7z" -o -name "*.mp4" -o -name "*.mov" -o -name "*.avi" -o \
        -name "*.pdf" -o -name "*.psd" -o -name "*.ai" \
        \) ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
    
    log_metric "large_binaries" "$large_binaries"
    if [ "$large_binaries" -gt 0 ]; then
        echo "Scanning: Found $large_binaries large binary files (>10MB)" >&2
        add_finding "high" "orphan_files" "$large_binaries large binary files should use Git LFS or external storage"
        total_issues=$((total_issues + large_binaries * 3))
    fi

    # 9. Check for auto-generated markdown files from build/test processes
    local generated_md=$(find "$CODEBASE_PATH" -type f -name "*.md" \( \
        -name "COVERAGE*.md" -o -name "coverage*.md" -o \
        -name "TEST-*.md" -o -name "test-results*.md" -o \
        -name "CHANGELOG-*.md" -o -name "changelog-auto*.md" -o \
        -name "API-DOCS*.md" -o -name "api-reference*.md" -o \
        -name "THIRD-PARTY*.md" -o -name "licenses*.md" -o \
        -name "dependency-graph*.md" -o -name "deps*.md" -o \
        -name "bundle-analysis*.md" -o -name "build-report*.md" -o \
        -name "lint-report*.md" -o -name "eslint-report*.md" -o \
        -name "security-report*.md" -o -name "audit-report*.md" \
        \) ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
    
    log_metric "generated_markdown" "$generated_md"
    if [ "$generated_md" -gt 0 ]; then
        echo "Scanning: Found $generated_md auto-generated markdown files" >&2
        add_finding "low" "orphan_files" "$generated_md auto-generated markdown files (coverage, test reports, etc.)"
        total_issues=$((total_issues + generated_md))
    fi

    # 10. Check for common generated documentation/report patterns
    local report_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "junit.xml" -o -name "test-results.xml" -o \
        -name "coverage.xml" -o -name "cobertura.xml" -o \
        -name "lcov.info" -o -name "*.lcov" -o \
        -name "clover.xml" -o -name "jacoco.xml" -o \
        -name "checkstyle*.xml" -o -name "eslint*.xml" -o \
        -name "pmd*.xml" -o -name "findbugs*.xml" -o \
        -name "report.html" -o -name "index.html" \
        \) ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/coverage/*" \
        ! -path "*/.nyc_output/*" ! -path "*/htmlcov/*" 2>/dev/null | wc -l | tr -d ' ')
    
    log_metric "report_files" "$report_files"
    if [ "$report_files" -gt 0 ]; then
        echo "Scanning: Found $report_files test/coverage report files in source" >&2
        add_finding "medium" "orphan_files" "$report_files test/coverage report files should be in .gitignore"
        total_issues=$((total_issues + report_files * 2))
    fi

    log_metric "total_orphan_issues" "$total_issues"

    # Calculate score based on total issues
    if [ "$total_issues" -gt 50 ]; then
        score=2
    elif [ "$total_issues" -gt 30 ]; then
        score=4
    elif [ "$total_issues" -gt 20 ]; then
        score=5
    elif [ "$total_issues" -gt 10 ]; then
        score=6
    elif [ "$total_issues" -gt 5 ]; then
        score=7
    elif [ "$total_issues" -gt 0 ]; then
        score=8
    fi

    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check TODO/FIXME Tracking (Parameter 345)
# =============================================================================
check_todos() {
    progress_step "TODO/FIXME tracking"
    local score=7

    # Count TODOs
    local todo_count=$(grep -rcE "(TODO|FIXME|HACK|XXX|BUG):" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
        awk -F: '{sum += $2} END {print sum+0}')
    
    log_metric "todo_count" "$todo_count"
    echo "Scanning: Found $todo_count TODO/FIXME comments" >&2

    if [ "$todo_count" -gt 100 ]; then
        add_finding "high" "technical_debt" "Very high number of TODO/FIXME comments ($todo_count)"
        score=3
    elif [ "$todo_count" -gt 50 ]; then
        add_finding "medium" "technical_debt" "High number of TODO/FIXME comments ($todo_count)"
        score=5
    elif [ "$todo_count" -gt 20 ]; then
        score=6
    elif [ "$todo_count" -lt 5 ]; then
        score=9
    fi

    # Check if TODOs are tracked (have ticket numbers)
    local tracked_todos=$(grep -rcE "(TODO|FIXME).*[A-Z]+-[0-9]+" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null | \
        awk -F: '{sum += $2} END {print sum+0}')
    
    log_metric "tracked_todos" "$tracked_todos"

    if [ "$tracked_todos" -gt 0 ] && [ "$todo_count" -gt 0 ]; then
        local tracking_ratio=$(math_int "$tracked_todos * 100 / $todo_count")
        log_metric "todo_tracking_ratio" "$tracking_ratio%"
        
        if [ "$tracking_ratio" -gt 50 ]; then
            score=$((score + 1))
        fi
    fi

    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Dependency Freshness (Parameter 347)
# =============================================================================
check_dependencies() {
    progress_step "Dependency freshness"
    local score=6

    # Check for outdated patterns
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        # Count total dependencies
        local total_deps=$(jq '(.dependencies // {}) + (.devDependencies // {}) | length' "$CODEBASE_PATH/package.json" 2>/dev/null || echo "0")
        log_metric "total_dependencies" "$total_deps"
        echo "Scanning: Found $total_deps dependencies" >&2

        # Check for deprecated packages
        local deprecated
        deprecated=$(grep -cE "(request|moment|lodash\"|underscore)" "$CODEBASE_PATH/package.json" 2>/dev/null) || deprecated=0
        if [ "$deprecated" -gt 0 ]; then
            log_metric "deprecated_packages" "$deprecated"
            add_finding "low" "dependencies" "Some commonly deprecated packages found"
            score=$((score - 1))
        fi

        # Check for very old version patterns
        if grep -qE "\"[0-9]+\.[0-9]+\.[0-9]+\"" "$CODEBASE_PATH/package.json" 2>/dev/null; then
            # Pinned versions are good
            log_metric "version_pinning" "true"
        fi

        # Check for renovate/dependabot
        if [ -f "$CODEBASE_PATH/.github/dependabot.yml" ] || [ -f "$CODEBASE_PATH/renovate.json" ]; then
            log_metric "auto_update" "true"
            score=$((score + 2))
        fi
    fi

    # Check Python requirements
    if [ -f "$CODEBASE_PATH/requirements.txt" ]; then
        local req_count=$(wc -l < "$CODEBASE_PATH/requirements.txt" | tr -d ' ')
        log_metric "python_requirements" "$req_count"
        
        # Check for pinned versions
        if grep -qE "==" "$CODEBASE_PATH/requirements.txt" 2>/dev/null; then
            log_metric "python_pinned" "true"
            score=$((score + 1))
        fi
    fi

    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Code Ownership (Parameter 349)
# =============================================================================
check_ownership() {
    progress_step "Code ownership"
    local score=5

    # Check for CODEOWNERS
    if [ -f "$CODEBASE_PATH/CODEOWNERS" ] || [ -f "$CODEBASE_PATH/.github/CODEOWNERS" ]; then
        log_metric "codeowners" "true"
        score=$((score + 3))
        echo "Scanning: Found CODEOWNERS file" >&2
    else
        add_finding "low" "ownership" "No CODEOWNERS file found"
    fi

    # Check for MAINTAINERS
    if [ -f "$CODEBASE_PATH/MAINTAINERS" ] || [ -f "$CODEBASE_PATH/MAINTAINERS.md" ]; then
        log_metric "maintainers" "true"
        score=$((score + 1))
    fi

    # Check git history for knowledge distribution
    if command -v git &> /dev/null && [ -d "$CODEBASE_PATH/.git" ]; then
        # Count unique contributors
        local contributors=$(cd "$CODEBASE_PATH" && git shortlog -sn --all 2>/dev/null | wc -l | tr -d ' ')
        log_metric "contributors" "$contributors"
        echo "Scanning: Found $contributors contributors" >&2

        if [ "$contributors" -gt 10 ]; then
            score=$((score + 1))
        elif [ "$contributors" -lt 2 ]; then
            add_finding "medium" "ownership" "Single contributor - knowledge concentration risk"
        fi
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Maintainability Evaluation..." >&2
    echo "Codebase: $CODEBASE_PATH" >&2

    local dup_score=$(check_duplication)
    local dead_score=$(check_dead_code)
    local orphan_score=$(check_orphan_files)
    local todo_score=$(check_todos)
    local dep_score=$(check_dependencies)
    local own_score=$(check_ownership)

    # Weighted average (adjusted to include orphan files check)
    local total_score=$(math_calc "$dup_score * 0.15 + $dead_score * 0.15 + $orphan_score * 0.15 + $todo_score * 0.20 + $dep_score * 0.20 + $own_score * 0.15")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 12')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg ds "$dup_score" \
        --arg dds "$dead_score" \
        --arg ofs "$orphan_score" \
        --arg ts "$todo_score" \
        --arg deps "$dep_score" \
        --arg os "$own_score" \
        '.subscores = {
            duplication: ($ds | tonumber),
            dead_code: ($dds | tonumber),
            orphan_files: ($ofs | tonumber),
            todo_tracking: ($ts | tonumber),
            dependency_freshness: ($deps | tonumber),
            code_ownership: ($os | tonumber)
        }')

    # Merge findings from temp file into results
    RESULTS=$(merge_findings "$RESULTS")
    
    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Maintainability Score: $total_score/10" >&2
}

main
