#!/bin/bash

# =============================================================================
# TEST COVERAGE EXTRACTOR
# =============================================================================
# Extracts and analyzes test coverage data from multiple formats:
#   - LCOV (lcov.info)
#   - Cobertura XML
#   - JUnit/xUnit XML
#   - Jest JSON
#   - Coverage.py JSON
#   - Go coverage profiles
#   - JaCoCo XML
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/math-utils.sh"

# =============================================================================
# COVERAGE FILE DETECTION
# =============================================================================

find_coverage_files() {
    local codebase="$1"
    local coverage_files='{
        "lcov": [],
        "cobertura": [],
        "jest": [],
        "pytest": [],
        "go": [],
        "jacoco": [],
        "junit": [],
        "other": []
    }'
    
    # LCOV files
    for f in $(find "$codebase" -name "lcov.info" -o -name "*.lcov" 2>/dev/null | head -20); do
        coverage_files=$(echo "$coverage_files" | jq --arg f "$f" '.lcov += [$f]')
    done
    
    # Cobertura XML
    for f in $(find "$codebase" -name "cobertura*.xml" -o -name "coverage.xml" 2>/dev/null | head -20); do
        if grep -q "cobertura" "$f" 2>/dev/null || grep -q "line-rate" "$f" 2>/dev/null; then
            coverage_files=$(echo "$coverage_files" | jq --arg f "$f" '.cobertura += [$f]')
        fi
    done
    
    # Jest coverage
    for f in $(find "$codebase" -path "*/coverage/coverage-summary.json" -o -name "jest-coverage.json" 2>/dev/null | head -20); do
        coverage_files=$(echo "$coverage_files" | jq --arg f "$f" '.jest += [$f]')
    done
    
    # Pytest/Coverage.py
    for f in $(find "$codebase" -name ".coverage" -o -path "*/.coverage" -o -name "coverage.json" 2>/dev/null | head -20); do
        coverage_files=$(echo "$coverage_files" | jq --arg f "$f" '.pytest += [$f]')
    done
    
    # Go coverage
    for f in $(find "$codebase" -name "coverage.out" -o -name "*.coverprofile" 2>/dev/null | head -20); do
        coverage_files=$(echo "$coverage_files" | jq --arg f "$f" '.go += [$f]')
    done
    
    # JaCoCo
    for f in $(find "$codebase" -name "jacoco*.xml" -o -path "*/jacoco/jacoco.xml" 2>/dev/null | head -20); do
        coverage_files=$(echo "$coverage_files" | jq --arg f "$f" '.jacoco += [$f]')
    done
    
    # JUnit test results
    for f in $(find "$codebase" -name "junit*.xml" -o -name "test-results*.xml" 2>/dev/null | head -20); do
        coverage_files=$(echo "$coverage_files" | jq --arg f "$f" '.junit += [$f]')
    done
    
    echo "$coverage_files"
}

# =============================================================================
# LCOV PARSER
# =============================================================================

parse_lcov() {
    local lcov_file="$1"
    
    if [ ! -f "$lcov_file" ]; then
        echo '{"error": "File not found"}'
        return
    fi
    
    local total_lines=0
    local covered_lines=0
    local total_functions=0
    local covered_functions=0
    local total_branches=0
    local covered_branches=0
    local files='[]'
    
    local current_file=""
    local file_lines=0
    local file_covered=0
    
    while IFS= read -r line; do
        case "$line" in
            SF:*)
                current_file="${line#SF:}"
                file_lines=0
                file_covered=0
                ;;
            LF:*)
                file_lines="${line#LF:}"
                total_lines=$((total_lines + file_lines))
                ;;
            LH:*)
                file_covered="${line#LH:}"
                covered_lines=$((covered_lines + file_covered))
                ;;
            FNF:*)
                total_functions=$((total_functions + ${line#FNF:}))
                ;;
            FNH:*)
                covered_functions=$((covered_functions + ${line#FNH:}))
                ;;
            BRF:*)
                total_branches=$((total_branches + ${line#BRF:}))
                ;;
            BRH:*)
                covered_branches=$((covered_branches + ${line#BRH:}))
                ;;
            end_of_record)
                if [ -n "$current_file" ] && [ "$file_lines" -gt 0 ]; then
                    local file_pct=$(math_calc "$file_covered * 100 / $file_lines")
                    files=$(echo "$files" | jq --arg f "$current_file" --arg p "$file_pct" \
                        '. += [{file: $f, coverage_percent: ($p | tonumber)}]')
                fi
                current_file=""
                ;;
        esac
    done < "$lcov_file"
    
    local line_pct=0
    local func_pct=0
    local branch_pct=0
    
    if [ "$total_lines" -gt 0 ]; then
        line_pct=$(math_calc "$covered_lines * 100 / $total_lines")
    fi
    if [ "$total_functions" -gt 0 ]; then
        func_pct=$(math_calc "$covered_functions * 100 / $total_functions")
    fi
    if [ "$total_branches" -gt 0 ]; then
        branch_pct=$(math_calc "$covered_branches * 100 / $total_branches")
    fi
    
    jq -n \
        --arg line_pct "$line_pct" \
        --arg func_pct "$func_pct" \
        --arg branch_pct "$branch_pct" \
        --argjson total_lines "$total_lines" \
        --argjson covered_lines "$covered_lines" \
        --argjson files "$files" \
        '{
            source: "lcov",
            line_coverage: ($line_pct | tonumber),
            function_coverage: ($func_pct | tonumber),
            branch_coverage: ($branch_pct | tonumber),
            total_lines: $total_lines,
            covered_lines: $covered_lines,
            file_count: ($files | length),
            files_summary: ($files | sort_by(-.coverage_percent) | .[0:10])
        }'
}

# =============================================================================
# COBERTURA PARSER
# =============================================================================

parse_cobertura() {
    local cobertura_file="$1"
    
    if [ ! -f "$cobertura_file" ]; then
        echo '{"error": "File not found"}'
        return
    fi
    
    # Extract metrics using grep/sed for portability
    local line_rate=$(grep -oE 'line-rate="[0-9.]+"' "$cobertura_file" | head -1 | grep -oE '[0-9.]+')
    local branch_rate=$(grep -oE 'branch-rate="[0-9.]+"' "$cobertura_file" | head -1 | grep -oE '[0-9.]+')
    local complexity=$(grep -oE 'complexity="[0-9.]+"' "$cobertura_file" | head -1 | grep -oE '[0-9.]+')
    
    # Default to 0 if not found
    line_rate=${line_rate:-0}
    branch_rate=${branch_rate:-0}
    complexity=${complexity:-0}
    
    local line_pct=$(math_calc "$line_rate * 100")
    local branch_pct=$(math_calc "$branch_rate * 100")
    
    jq -n \
        --arg line_pct "$line_pct" \
        --arg branch_pct "$branch_pct" \
        --arg complexity "$complexity" \
        '{
            source: "cobertura",
            line_coverage: ($line_pct | tonumber),
            branch_coverage: ($branch_pct | tonumber),
            complexity: ($complexity | tonumber)
        }'
}

# =============================================================================
# JEST COVERAGE PARSER
# =============================================================================

parse_jest_coverage() {
    local jest_file="$1"
    
    if [ ! -f "$jest_file" ]; then
        echo '{"error": "File not found"}'
        return
    fi
    
    # Jest coverage-summary.json format
    local total=$(jq '.total' "$jest_file" 2>/dev/null)
    
    if [ "$total" == "null" ] || [ -z "$total" ]; then
        echo '{"error": "Invalid Jest coverage format"}'
        return
    fi
    
    jq --argjson total "$total" -n '{
        source: "jest",
        line_coverage: $total.lines.pct,
        statement_coverage: $total.statements.pct,
        function_coverage: $total.functions.pct,
        branch_coverage: $total.branches.pct,
        total_lines: $total.lines.total,
        covered_lines: $total.lines.covered
    }'
}

# =============================================================================
# GO COVERAGE PARSER
# =============================================================================

parse_go_coverage() {
    local coverage_file="$1"
    
    if [ ! -f "$coverage_file" ]; then
        echo '{"error": "File not found"}'
        return
    fi
    
    # Go coverage format: mode: set/count/atomic followed by coverage lines
    local mode=$(head -1 "$coverage_file" | grep -oE 'mode: [a-z]+' | awk '{print $2}')
    
    local total_stmts=0
    local covered_stmts=0
    
    while IFS= read -r line; do
        # Skip mode line
        [[ "$line" == mode:* ]] && continue
        
        # Format: filename:startline.startcol,endline.endcol numstmts count
        local stmts=$(echo "$line" | awk '{print $(NF-1)}')
        local count=$(echo "$line" | awk '{print $NF}')
        
        if [[ "$stmts" =~ ^[0-9]+$ ]] && [[ "$count" =~ ^[0-9]+$ ]]; then
            total_stmts=$((total_stmts + stmts))
            if [ "$count" -gt 0 ]; then
                covered_stmts=$((covered_stmts + stmts))
            fi
        fi
    done < "$coverage_file"
    
    local coverage_pct=0
    if [ "$total_stmts" -gt 0 ]; then
        coverage_pct=$(math_calc "$covered_stmts * 100 / $total_stmts")
    fi
    
    jq -n \
        --arg mode "$mode" \
        --arg pct "$coverage_pct" \
        --argjson total "$total_stmts" \
        --argjson covered "$covered_stmts" \
        '{
            source: "go",
            mode: $mode,
            statement_coverage: ($pct | tonumber),
            total_statements: $total,
            covered_statements: $covered
        }'
}

# =============================================================================
# UNIFIED COVERAGE EXTRACTION
# =============================================================================

extract_coverage() {
    local codebase="$1"
    local coverage_data='{
        "found": false,
        "sources": [],
        "line_coverage": null,
        "branch_coverage": null,
        "function_coverage": null,
        "files_analyzed": 0
    }'
    
    echo "  Extracting test coverage data..." >&2
    
    local coverage_files=$(find_coverage_files "$codebase")
    
    local line_coverages=()
    local branch_coverages=()
    local func_coverages=()
    
    # Process LCOV files
    local lcov_files=$(echo "$coverage_files" | jq -r '.lcov[]' 2>/dev/null)
    for f in $lcov_files; do
        echo "    Processing LCOV: $f" >&2
        local result=$(parse_lcov "$f")
        local line_cov=$(echo "$result" | jq '.line_coverage')
        
        if [ "$line_cov" != "null" ] && [ "$line_cov" != "0" ]; then
            line_coverages+=("$line_cov")
            local branch=$(echo "$result" | jq '.branch_coverage')
            [ "$branch" != "null" ] && branch_coverages+=("$branch")
            local func=$(echo "$result" | jq '.function_coverage')
            [ "$func" != "null" ] && func_coverages+=("$func")
            coverage_data=$(echo "$coverage_data" | jq '.found = true | .sources += ["lcov"]')
        fi
    done
    
    # Process Cobertura files
    local cobertura_files=$(echo "$coverage_files" | jq -r '.cobertura[]' 2>/dev/null)
    for f in $cobertura_files; do
        echo "    Processing Cobertura: $f" >&2
        local result=$(parse_cobertura "$f")
        local line_cov=$(echo "$result" | jq '.line_coverage')
        
        if [ "$line_cov" != "null" ] && [ "$line_cov" != "0" ]; then
            line_coverages+=("$line_cov")
            local branch=$(echo "$result" | jq '.branch_coverage')
            [ "$branch" != "null" ] && branch_coverages+=("$branch")
            coverage_data=$(echo "$coverage_data" | jq '.found = true | .sources += ["cobertura"]')
        fi
    done
    
    # Process Jest files
    local jest_files=$(echo "$coverage_files" | jq -r '.jest[]' 2>/dev/null)
    for f in $jest_files; do
        echo "    Processing Jest: $f" >&2
        local result=$(parse_jest_coverage "$f")
        local line_cov=$(echo "$result" | jq '.line_coverage')
        
        if [ "$line_cov" != "null" ] && [ "$line_cov" != "0" ]; then
            line_coverages+=("$line_cov")
            local branch=$(echo "$result" | jq '.branch_coverage')
            [ "$branch" != "null" ] && branch_coverages+=("$branch")
            local func=$(echo "$result" | jq '.function_coverage')
            [ "$func" != "null" ] && func_coverages+=("$func")
            coverage_data=$(echo "$coverage_data" | jq '.found = true | .sources += ["jest"]')
        fi
    done
    
    # Process Go files
    local go_files=$(echo "$coverage_files" | jq -r '.go[]' 2>/dev/null)
    for f in $go_files; do
        echo "    Processing Go coverage: $f" >&2
        local result=$(parse_go_coverage "$f")
        local stmt_cov=$(echo "$result" | jq '.statement_coverage')
        
        if [ "$stmt_cov" != "null" ] && [ "$stmt_cov" != "0" ]; then
            line_coverages+=("$stmt_cov")
            coverage_data=$(echo "$coverage_data" | jq '.found = true | .sources += ["go"]')
        fi
    done
    
    # Calculate averages if we found coverage
    if [ ${#line_coverages[@]} -gt 0 ]; then
        local sum=0
        for v in "${line_coverages[@]}"; do
            sum=$(math_calc "$sum + $v")
        done
        local avg=$(math_calc "$sum / ${#line_coverages[@]}")
        coverage_data=$(echo "$coverage_data" | jq --arg avg "$avg" '.line_coverage = ($avg | tonumber)')
    fi

    if [ ${#branch_coverages[@]} -gt 0 ]; then
        local sum=0
        for v in "${branch_coverages[@]}"; do
            sum=$(math_calc "$sum + $v")
        done
        local avg=$(math_calc "$sum / ${#branch_coverages[@]}")
        coverage_data=$(echo "$coverage_data" | jq --arg avg "$avg" '.branch_coverage = ($avg | tonumber)')
    fi

    if [ ${#func_coverages[@]} -gt 0 ]; then
        local sum=0
        for v in "${func_coverages[@]}"; do
            sum=$(math_calc "$sum + $v")
        done
        local avg=$(math_calc "$sum / ${#func_coverages[@]}")
        coverage_data=$(echo "$coverage_data" | jq --arg avg "$avg" '.function_coverage = ($avg | tonumber)')
    fi
    
    # Calculate score
    local line_cov=$(echo "$coverage_data" | jq '.line_coverage // 0')
    local score=0
    
    if math_compare "$line_cov" ">" "80"; then
        score=10
    elif math_compare "$line_cov" ">" "70"; then
        score=8
    elif math_compare "$line_cov" ">" "60"; then
        score=7
    elif math_compare "$line_cov" ">" "50"; then
        score=6
    elif math_compare "$line_cov" ">" "40"; then
        score=5
    elif math_compare "$line_cov" ">" "30"; then
        score=4
    elif math_compare "$line_cov" ">" "20"; then
        score=3
    elif math_compare "$line_cov" ">" "10"; then
        score=2
    elif math_compare "$line_cov" ">" "0"; then
        score=1
    fi
    
    coverage_data=$(echo "$coverage_data" | jq --argjson score "$score" '. + {score: $score}')
    
    echo "$coverage_data"
}

# =============================================================================
# TEST RESULTS EXTRACTION
# =============================================================================

extract_test_results() {
    local codebase="$1"
    local results='{
        "found": false,
        "total_tests": 0,
        "passed": 0,
        "failed": 0,
        "skipped": 0,
        "duration_seconds": 0
    }'
    
    echo "  Extracting test results..." >&2
    
    # Find JUnit XML files
    for junit_file in $(find "$codebase" -name "junit*.xml" -o -name "test-results*.xml" 2>/dev/null | head -10); do
        echo "    Processing JUnit: $junit_file" >&2
        
        local tests=$(grep -oE 'tests="[0-9]+"' "$junit_file" 2>/dev/null | head -1 | grep -oE '[0-9]+')
        local failures=$(grep -oE 'failures="[0-9]+"' "$junit_file" 2>/dev/null | head -1 | grep -oE '[0-9]+')
        local errors=$(grep -oE 'errors="[0-9]+"' "$junit_file" 2>/dev/null | head -1 | grep -oE '[0-9]+')
        local skipped=$(grep -oE 'skipped="[0-9]+"' "$junit_file" 2>/dev/null | head -1 | grep -oE '[0-9]+')
        local time=$(grep -oE 'time="[0-9.]+"' "$junit_file" 2>/dev/null | head -1 | grep -oE '[0-9.]+')
        
        tests=${tests:-0}
        failures=${failures:-0}
        errors=${errors:-0}
        skipped=${skipped:-0}
        time=${time:-0}
        
        local passed=$((tests - failures - errors - skipped))
        
        results=$(echo "$results" | jq \
            --argjson tests "$tests" \
            --argjson passed "$passed" \
            --argjson failed "$((failures + errors))" \
            --argjson skipped "$skipped" \
            --argjson time "$time" \
            '.found = true | 
             .total_tests += $tests |
             .passed += $passed |
             .failed += $failed |
             .skipped += $skipped |
             .duration_seconds += $time')
    done
    
    # Check for Jest results
    for jest_file in $(find "$codebase" -name "jest-results.json" -o -path "*/test-results/*.json" 2>/dev/null | head -10); do
        if jq -e '.numTotalTests' "$jest_file" &>/dev/null; then
            echo "    Processing Jest results: $jest_file" >&2
            
            local tests=$(jq '.numTotalTests // 0' "$jest_file")
            local passed=$(jq '.numPassedTests // 0' "$jest_file")
            local failed=$(jq '.numFailedTests // 0' "$jest_file")
            
            results=$(echo "$results" | jq \
                --argjson tests "$tests" \
                --argjson passed "$passed" \
                --argjson failed "$failed" \
                '.found = true | 
                 .total_tests += $tests |
                 .passed += $passed |
                 .failed += $failed')
        fi
    done
    
    # Calculate pass rate
    local total=$(echo "$results" | jq '.total_tests')
    local passed=$(echo "$results" | jq '.passed')
    
    if [ "$total" -gt 0 ]; then
        local pass_rate=$(math_calc "$passed * 100 / $total")
        results=$(echo "$results" | jq --arg rate "$pass_rate" '. + {pass_rate: ($rate | tonumber)}')
    else
        results=$(echo "$results" | jq '. + {pass_rate: null}')
    fi
    
    echo "$results"
}

# =============================================================================
# COMPREHENSIVE TEST ANALYSIS
# =============================================================================

analyze_tests() {
    local codebase="$1"
    local output_file="${2:-/dev/stdout}"
    
    echo "Analyzing test coverage and results..." >&2
    
    local coverage=$(extract_coverage "$codebase")
    local results=$(extract_test_results "$codebase")
    
    # Detect test frameworks
    local frameworks='[]'
    
    [ -f "$codebase/package.json" ] && grep -qE '"jest"|"mocha"|"vitest"|"ava"' "$codebase/package.json" 2>/dev/null && \
        frameworks=$(echo "$frameworks" | jq '. += ["jest/mocha/vitest"]')
    
    [ -f "$codebase/pytest.ini" ] || [ -f "$codebase/pyproject.toml" ] && grep -q "pytest" "$codebase/pyproject.toml" 2>/dev/null && \
        frameworks=$(echo "$frameworks" | jq '. += ["pytest"]')
    
    [ -f "$codebase/go.mod" ] && \
        frameworks=$(echo "$frameworks" | jq '. += ["go test"]')
    
    find "$codebase" -name "*_test.rb" -o -name "*_spec.rb" 2>/dev/null | head -1 | grep -q . && \
        frameworks=$(echo "$frameworks" | jq '. += ["rspec"]')
    
    find "$codebase" -path "*/src/test/*" -name "*.java" 2>/dev/null | head -1 | grep -q . && \
        frameworks=$(echo "$frameworks" | jq '. += ["junit"]')
    
    # Calculate overall testing score
    local coverage_score=$(echo "$coverage" | jq '.score // 0')
    local has_results=$(echo "$results" | jq '.found')
    local pass_rate=$(echo "$results" | jq '.pass_rate // 0')
    
    local test_score=$coverage_score
    
    if [ "$has_results" == "true" ]; then
        local results_score=5
        if math_compare "$pass_rate" ">=" "99"; then
            results_score=10
        elif math_compare "$pass_rate" ">=" "95"; then
            results_score=8
        elif math_compare "$pass_rate" ">=" "90"; then
            results_score=6
        fi
        test_score=$(math_calc "($coverage_score + $results_score) / 2")
    fi
    
    jq -n \
        --argjson coverage "$coverage" \
        --argjson results "$results" \
        --argjson frameworks "$frameworks" \
        --arg score "$test_score" \
        '{
            testing_analysis_version: "2.0",
            coverage: $coverage,
            test_results: $results,
            frameworks_detected: $frameworks,
            overall_score: ($score | tonumber),
            recommendations: (
                []
                + (if $coverage.line_coverage == null then ["No coverage data found - configure coverage reporting"] else [] end)
                + (if ($coverage.line_coverage // 0) < 60 then ["Increase test coverage to at least 60%"] else [] end)
                + (if ($coverage.branch_coverage // 0) < 50 then ["Improve branch coverage to catch edge cases"] else [] end)
                + (if $results.failed > 0 then ["Fix failing tests before deployment"] else [] end)
                + (if ($frameworks | length) == 0 then ["Add a testing framework appropriate for your stack"] else [] end)
            )
        }' > "$output_file"
    
    cat "$output_file"
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    analyze_tests "$@"
fi
