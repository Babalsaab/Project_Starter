#!/bin/bash

# =============================================================================
# Enhanced Test Coverage Analyzer
# =============================================================================
# Analyzes test coverage across multiple frameworks and languages with
# smart detection of test quality, coverage metrics, and testing patterns.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/framework-detector.sh" 2>/dev/null || true
source "$SCRIPT_DIR/math-utils.sh"

# Calculate comprehensive test metrics
analyze_test_coverage() {
    local codebase="$1"
    local results_dir="$2"
    
    local test_score=0
    local test_count=0
    local source_count=0
    local coverage_percent=0
    local test_quality=0
    
    # Count test files
    test_count=$(find "$codebase" \
        \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" -o -name "test_*.*" \
           -o -path "*/__tests__/*" -o -path "*/tests/*" -o -path "*/test/*" \) \
        -type f \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
        ! -path "*/dist/*" ! -path "*/build/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    # Count source files (excluding tests)
    source_count=$(find "$codebase" \
        \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \
           -o -name "*.py" -o -name "*.go" -o -name "*.java" -o -name "*.rb" \
           -o -name "*.rs" -o -name "*.php" -o -name "*.cs" \) \
        -type f \
        ! -name "*.test.*" ! -name "*.spec.*" ! -name "*_test.*" ! -name "test_*.*" \
        ! -path "*/__tests__/*" ! -path "*/tests/*" ! -path "*/test/*" \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
        ! -path "*/dist/*" ! -path "*/build/*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    # Calculate test-to-source ratio
    local test_ratio=0
    if [ "$source_count" -gt 0 ]; then
        test_ratio=$(math_calc "$test_count * 100 / $source_count")
    fi
    
    # Try to extract actual coverage from coverage reports
    coverage_percent=$(extract_coverage_metrics "$codebase")
    
    # Analyze test quality
    test_quality=$(analyze_test_quality "$codebase")
    
    # Calculate test framework score
    local framework_score
    framework_score=$(analyze_test_frameworks "$codebase")
    
    # Calculate overall test score
    # Weights: coverage (40%), test ratio (20%), quality (25%), framework (15%)
    if [ "$coverage_percent" -gt 0 ]; then
        local coverage_score=$((coverage_percent / 10))
        [ "$coverage_score" -gt 10 ] && coverage_score=10
        
        local ratio_score
        if math_compare "$test_ratio" ">" "50"; then
            ratio_score=10
        elif math_compare "$test_ratio" ">" "30"; then
            ratio_score=8
        elif math_compare "$test_ratio" ">" "15"; then
            ratio_score=6
        elif math_compare "$test_ratio" ">" "5"; then
            ratio_score=4
        else
            ratio_score=2
        fi
        
        test_score=$(math_calc "($coverage_score * 0.4) + ($ratio_score * 0.2) + ($test_quality * 0.25) + ($framework_score * 0.15)")
    else
        # No coverage data, use estimates
        local ratio_score=2
        [ "$test_count" -gt 0 ] && ratio_score=4
        [ "$test_count" -gt 10 ] && ratio_score=6
        math_compare "$test_ratio" ">" "20" && ratio_score=7
        math_compare "$test_ratio" ">" "40" && ratio_score=8

        test_score=$(math_calc "($ratio_score * 0.5) + ($test_quality * 0.35) + ($framework_score * 0.15)")
    fi
    
    # Output results as JSON
    cat << EOF
{
    "test_count": $test_count,
    "source_count": $source_count,
    "test_ratio": $test_ratio,
    "coverage_percent": $coverage_percent,
    "test_quality_score": $test_quality,
    "framework_score": $framework_score,
    "overall_score": $test_score
}
EOF
}

# Extract coverage from various coverage report formats
extract_coverage_metrics() {
    local codebase="$1"
    local coverage=0
    
    # Check for coverage directory
    local coverage_dirs=(
        "$codebase/coverage"
        "$codebase/.coverage"
        "$codebase/htmlcov"
        "$codebase/target/site/jacoco"
        "$codebase/build/reports/jacoco"
    )
    
    for cov_dir in "${coverage_dirs[@]}"; do
        if [ -d "$cov_dir" ]; then
            # Try to parse coverage-summary.json (Jest)
            if [ -f "$cov_dir/coverage-summary.json" ]; then
                coverage=$(jq -r '.total.lines.pct // .total.statements.pct // 0' "$cov_dir/coverage-summary.json" 2>/dev/null | cut -d. -f1)
                [ -n "$coverage" ] && [ "$coverage" != "null" ] && break
            fi
            
            # Try to parse lcov.info
            if [ -f "$cov_dir/lcov.info" ]; then
                local lines_found lines_hit
                lines_found=$(grep -c "^DA:" "$cov_dir/lcov.info" 2>/dev/null || echo "0")
                lines_hit=$(grep "^DA:" "$cov_dir/lcov.info" 2>/dev/null | { grep -v ",0$" || true; } | wc -l | tr -d ' ')
                if [ "$lines_found" -gt 0 ]; then
                    coverage=$((lines_hit * 100 / lines_found))
                    break
                fi
            fi
            
            # Try clover.xml
            if [ -f "$cov_dir/clover.xml" ]; then
                coverage=$(grep -oP 'coverage="[0-9.]+' "$cov_dir/clover.xml" 2>/dev/null | head -1 | grep -oP '[0-9.]+' | cut -d. -f1)
                [ -n "$coverage" ] && break
            fi
        fi
    done
    
    # Check for Python coverage files
    if [ -f "$codebase/.coverage" ] && command -v coverage &>/dev/null; then
        coverage=$(cd "$codebase" && coverage report 2>/dev/null | tail -1 | awk '{print $NF}' | tr -d '%' | cut -d. -f1)
    fi
    
    # Check for coverage.xml (Cobertura format)
    if [ -f "$codebase/coverage.xml" ]; then
        coverage=$(grep -oP 'line-rate="[0-9.]+' "$codebase/coverage.xml" 2>/dev/null | head -1 | grep -oP '[0-9.]+')
        if [ -n "$coverage" ]; then
            coverage=$(math_int "$coverage * 100")
        fi
    fi
    
    # Check for Go coverage
    if [ -f "$codebase/coverage.out" ]; then
        if command -v go &>/dev/null; then
            coverage=$(go tool cover -func="$codebase/coverage.out" 2>/dev/null | tail -1 | awk '{print $NF}' | tr -d '%' | cut -d. -f1)
        fi
    fi
    
    echo "${coverage:-0}"
}

# Analyze test quality based on patterns
analyze_test_quality() {
    local codebase="$1"
    local quality_score=5
    
    # Find test files
    local test_files
    test_files=$(find "$codebase" \
        \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" -o -name "test_*.*" \) \
        -type f \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
        2>/dev/null | head -50)
    
    if [ -z "$test_files" ]; then
        echo "3"
        return
    fi
    
    local positive_indicators=0
    local negative_indicators=0
    
    # Check for good testing patterns
    while IFS= read -r test_file; do
        [ -z "$test_file" ] && continue
        local content
        content=$(cat "$test_file" 2>/dev/null)
        
        # Positive: Multiple assertions per test
        echo "$content" | grep -qE "expect\(|assert|should\." && ((positive_indicators++))
        
        # Positive: Setup/teardown
        echo "$content" | grep -qE "beforeEach|afterEach|setUp|tearDown|@Before|@After" && ((positive_indicators++))
        
        # Positive: Mocking
        echo "$content" | grep -qE "mock|stub|spy|jest\.fn|sinon\.|@Mock|MagicMock|patch\(" && ((positive_indicators++))
        
        # Positive: Descriptive test names
        echo "$content" | grep -qE "it\(['\"]should|test_[a-z]+_|def test_.*:" && ((positive_indicators++))
        
        # Positive: Async test handling
        echo "$content" | grep -qE "async.*await|done\(\)|waitFor\(|eventually" && ((positive_indicators++))
        
        # Negative: Skipped tests
        echo "$content" | grep -qE "\.skip\(|xit\(|xdescribe\(|@Ignore|@pytest\.mark\.skip" && ((negative_indicators++))
        
        # Negative: Focused tests (should not be committed)
        echo "$content" | grep -qE "\.only\(|fit\(|fdescribe\(" && ((negative_indicators+=2))
        
        # Negative: Empty tests
        echo "$content" | grep -qE "it\([^)]+,\s*\(\)\s*=>\s*\{\s*\}\)" && ((negative_indicators++))
        
        # Negative: TODO in tests
        echo "$content" | grep -qE "TODO|FIXME" && ((negative_indicators++))
        
    done <<< "$test_files"
    
    # Calculate quality score (base 5, +/- based on indicators)
    local file_count
    file_count=$(echo "$test_files" | wc -l | tr -d ' ')
    
    if [ "$file_count" -gt 0 ]; then
        local pos_ratio=$((positive_indicators * 100 / file_count / 5))
        local neg_ratio=$((negative_indicators * 100 / file_count / 5))
        
        quality_score=$((5 + pos_ratio - neg_ratio))
        [ "$quality_score" -lt 1 ] && quality_score=1
        [ "$quality_score" -gt 10 ] && quality_score=10
    fi
    
    echo "$quality_score"
}

# Analyze testing frameworks and infrastructure
analyze_test_frameworks() {
    local codebase="$1"
    local score=5
    
    # Check for testing frameworks in package.json
    if [ -f "$codebase/package.json" ]; then
        local pkg
        pkg=$(cat "$codebase/package.json" 2>/dev/null)
        
        # Modern test runners
        echo "$pkg" | grep -qE '"jest"|"vitest"' && ((score++))
        
        # E2E frameworks
        echo "$pkg" | grep -qE '"cypress"|"playwright"|"puppeteer"' && ((score++))
        
        # Testing utilities
        echo "$pkg" | grep -qE '"@testing-library|"enzyme"' && ((score++))
        
        # Coverage tools
        echo "$pkg" | grep -qE '"nyc"|"c8"|"istanbul"' && ((score++))
        
        # Test scripts defined
        echo "$pkg" | grep -qE '"test":|"test:unit":|"test:e2e":' && ((score++))
    fi
    
    # Check for Python test configuration
    if [ -f "$codebase/pytest.ini" ] || [ -f "$codebase/setup.cfg" ] || [ -f "$codebase/pyproject.toml" ]; then
        local config
        config=$(cat "$codebase/pytest.ini" "$codebase/setup.cfg" "$codebase/pyproject.toml" 2>/dev/null)
        
        echo "$config" | grep -qE "\[tool\.pytest|pytest" && ((score++))
        echo "$config" | grep -qE "coverage|cov" && ((score++))
    fi
    
    # Check for CI test configuration
    if ls "$codebase/.github/workflows/"*.yml 1>/dev/null 2>&1; then
        local workflows
        workflows=$(cat "$codebase/.github/workflows/"*.yml 2>/dev/null)
        echo "$workflows" | grep -qE "test|jest|pytest|go test" && ((score++))
        echo "$workflows" | grep -qE "coverage|codecov|coveralls" && ((score++))
    fi
    
    # Check for test configuration files
    [ -f "$codebase/jest.config.js" ] || [ -f "$codebase/jest.config.ts" ] && ((score++))
    [ -f "$codebase/vitest.config.ts" ] && ((score++))
    [ -f "$codebase/cypress.config.js" ] || [ -f "$codebase/cypress.config.ts" ] && ((score++))
    [ -f "$codebase/playwright.config.ts" ] && ((score++))
    
    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# Analyze test types and categorize them
categorize_tests() {
    local codebase="$1"
    
    local unit_tests=0
    local integration_tests=0
    local e2e_tests=0
    local snapshot_tests=0
    local performance_tests=0
    
    # Count by file location and naming patterns
    unit_tests=$(find "$codebase" \
        \( -path "*/unit/*" -o -name "*.unit.*" \) \
        -type f ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
    
    integration_tests=$(find "$codebase" \
        \( -path "*/integration/*" -o -name "*.integration.*" -o -name "*.int.*" \) \
        -type f ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
    
    e2e_tests=$(find "$codebase" \
        \( -path "*/e2e/*" -o -path "*/cypress/*" -o -path "*/playwright/*" \
           -o -name "*.e2e.*" -o -name "*.cy.*" \) \
        -type f ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
    
    # Check for snapshot tests in test files
    snapshot_tests=$(grep -rl "toMatchSnapshot\|toMatchInlineSnapshot" "$codebase" \
        --include="*.test.*" --include="*.spec.*" \
        2>/dev/null | wc -l | tr -d ' ')
    
    # Check for performance tests
    performance_tests=$(find "$codebase" \
        \( -path "*/perf/*" -o -path "*/performance/*" -o -path "*/benchmark/*" \
           -o -name "*.perf.*" -o -name "*.bench.*" \) \
        -type f ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
    
    cat << EOF
{
    "unit_tests": $unit_tests,
    "integration_tests": $integration_tests,
    "e2e_tests": $e2e_tests,
    "snapshot_tests": $snapshot_tests,
    "performance_tests": $performance_tests
}
EOF
}

# Export functions
export -f analyze_test_coverage 2>/dev/null || true
export -f extract_coverage_metrics 2>/dev/null || true
export -f analyze_test_quality 2>/dev/null || true
export -f analyze_test_frameworks 2>/dev/null || true
export -f categorize_tests 2>/dev/null || true
