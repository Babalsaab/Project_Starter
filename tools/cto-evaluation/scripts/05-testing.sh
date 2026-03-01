#!/bin/bash

# =============================================================================
# TESTING EVALUATION (Parameters 154-210) - ELITE WORLD-CLASS VERSION
# =============================================================================
# Philosophy: Signal over coverage. Confidence over counts. Failure meaning over green builds.
#
# Elite Dimensions Evaluated:
#   1.  Test Coverage & Types (154-160)
#   2.  Test Infrastructure & Tooling (161-165)
#   3.  Flakiness & Test Trustworthiness (166-170)
#   4.  Mutation Testing Awareness (171-173)
#   5.  Assertion Quality & Depth (174-178)
#   6.  Test Intent & Readability (179-183)
#   7.  Isolation & Determinism (184-188)
#   8.  Mocking Strategy Quality (189-192)
#   9.  Integration vs Unit Balance (193-196)
#   10. Failure Diagnostics Quality (197-199)
#   11. Regression Intent Detection (200-202)
#   12. Test Execution Performance (203-205)
#   13. Risk-Weighted Coverage (206-208)
#   14. Property-Based & Fuzz Testing (209-210)
#
# Scoring Model: Confidence Multipliers
#   final_score = base_score × trust_multiplier × signal_multiplier × risk_alignment
# =============================================================================

set -euo pipefail

CODEBASE_PATH="${1:-}"
OUTPUT_FILE="${2:-}"
RESULTS_DIR="${3:-}"

# Validate inputs
if [ -z "$CODEBASE_PATH" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <codebase_path> <output_file> [results_dir]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-progress.sh"
source "$SCRIPT_DIR/common-findings.sh"
source "$SCRIPT_DIR/lib/math-utils.sh"
init_findings

# Source enhanced analyzers if available
if [ -f "$SCRIPT_DIR/lib/test-analyzer.sh" ]; then
    source "$SCRIPT_DIR/lib/test-analyzer.sh"
fi

set_total_steps 16

# Initialize results with elite structure
RESULTS='{
    "category": "testing",
    "parameters_evaluated": 0,
    "parameters_total": 57,
    "score": 0,
    "confidence_score": 0,
    "trust_multiplier": 1.0,
    "signal_multiplier": 1.0,
    "risk_alignment_multiplier": 1.0,
    "findings": [],
    "metrics": {},
    "elite_metrics": {},
    "subscores": {}
}'

# Confidence multipliers (adjusted based on findings)
TRUST_MULTIPLIER=1.0
SIGNAL_MULTIPLIER=1.0
RISK_ALIGNMENT_MULTIPLIER=1.0

log_metric() {
    local name="$1"
    local value="$2"
    RESULTS=$(echo "$RESULTS" | jq --arg n "$name" --arg v "$value" '.metrics[$n] = $v')
}

log_elite_metric() {
    local name="$1"
    local value="$2"
    RESULTS=$(echo "$RESULTS" | jq --arg n "$name" --arg v "$value" '.elite_metrics[$n] = $v')
}

# Adjust multipliers based on findings
adjust_trust_multiplier() {
    local adjustment="$1"
    TRUST_MULTIPLIER=$(math_calc "$TRUST_MULTIPLIER * $adjustment")
}

adjust_signal_multiplier() {
    local adjustment="$1"
    SIGNAL_MULTIPLIER=$(math_calc "$SIGNAL_MULTIPLIER * $adjustment")
}

adjust_risk_multiplier() {
    local adjustment="$1"
    RISK_ALIGNMENT_MULTIPLIER=$(math_calc "$RISK_ALIGNMENT_MULTIPLIER * $adjustment")
}

# Safe grep count - handles exit code properly
grep_count() {
    local pattern="$1"
    local file="$2"
    local count
    count=$(grep -cE "$pattern" "$file" 2>/dev/null) || count=0
    echo "$count"
}

# Safe grep count for multiple files
grep_count_files() {
    local pattern="$1"
    shift
    local count=0
    for file in "$@"; do
        local c
        c=$(grep -cE "$pattern" "$file" 2>/dev/null) || c=0
        count=$((count + c))
    done
    echo "$count"
}

parse_lcov_coverage() {
    local file="$1"
    [ ! -f "$file" ] && echo "0" && return
    awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END {if(lf>0){printf "%.0f", (lh/lf*100)} else {print 0}}' "$file" 2>/dev/null || echo "0"
}

parse_coverage_xml() {
    local file="$1"
    [ ! -f "$file" ] && echo "0" && return
    local rate
    rate=$(grep -o 'line-rate="[0-9.]*"' "$file" 2>/dev/null | head -1 | awk -F'"' '{print $2}')
    [ -z "$rate" ] && echo "0" && return
    math_int "$rate * 100"
}

# =============================================================================
# 1. FLAKINESS & TEST TRUSTWORTHINESS ANALYSIS
# =============================================================================
# A flaky test is worse than no test. This detects unreliable test patterns.
# =============================================================================

analyze_flakiness() {
    progress_step "Analyzing test flakiness & trustworthiness"
    
    local flakiness_score=10
    local flaky_indicators=0
    local time_based_tests=0
    local randomness_tests=0
    local retry_configured=false
    local network_tests=0
    
    # Find all test files
    local test_files
    test_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.test.js" -o -name "*.test.ts" -o -name "*.test.tsx" -o \
        -name "*.spec.js" -o -name "*.spec.ts" -o -name "*.spec.tsx" -o \
        -name "test_*.py" -o -name "*_test.py" -o -name "*_test.go" \
        \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null || true)
    
    if [ -n "$test_files" ]; then
        while IFS= read -r test_file; do
            [ -z "$test_file" ] && continue
            
            # Detect time-based operations without mocks
            local time_patterns
            time_patterns=$(grep_count "(setTimeout|setInterval|Date\.now\(\)|new Date\(\)|time\.sleep|time\.time\(\)|\.sleep\()" "$test_file")
            if [ "$time_patterns" -gt 0 ]; then
                # Check if there's mocking
                if ! grep -qE "(jest\.useFakeTimers|sinon\.useFakeTimers|freezegun|@freeze_time|mock.*time)" "$test_file" 2>/dev/null; then
                    time_based_tests=$((time_based_tests + time_patterns))
                    add_finding "medium" "flakiness" "Time-based test without mocking detected" "$test_file"
                fi
            fi
            
            # Detect randomness without seeding
            local random_patterns
            random_patterns=$(grep_count "(Math\.random\(\)|random\.|randint|randrange|uuid\(\))" "$test_file")
            if [ "$random_patterns" -gt 0 ]; then
                if ! grep -qE "(seed|mockRandom|jest\.spyOn.*random)" "$test_file" 2>/dev/null; then
                    randomness_tests=$((randomness_tests + random_patterns))
                fi
            fi
            
            # Detect network calls without mocking
            local network_patterns
            network_patterns=$(grep_count "(fetch\(|axios\.|http\.|requests\.|urllib)" "$test_file")
            if [ "$network_patterns" -gt 0 ]; then
                if ! grep -qE "(nock|msw|responses|httpretty|mock.*request|jest\.mock.*axios)" "$test_file" 2>/dev/null; then
                    network_tests=$((network_tests + network_patterns))
                fi
            fi
        done <<< "$test_files"
    fi
    
    # Check for retry configuration (often masks flakiness)
    if [ -f "$CODEBASE_PATH/jest.config.js" ] || [ -f "$CODEBASE_PATH/jest.config.ts" ]; then
        if grep -qE "(retry|retries)" "$CODEBASE_PATH"/jest.config.* 2>/dev/null; then
            retry_configured=true
            add_finding "medium" "flakiness" "Test retries configured - may mask flaky tests" "$CODEBASE_PATH/jest.config.js"
            adjust_trust_multiplier 0.9
        fi
    fi
    
    if [ -f "$CODEBASE_PATH/vitest.config.ts" ]; then
        if grep -qE "(retry|retries)" "$CODEBASE_PATH/vitest.config.ts" 2>/dev/null; then
            retry_configured=true
        fi
    fi
    
    # Check pytest for flaky markers
    if grep -rq "@pytest.mark.flaky" "$CODEBASE_PATH" 2>/dev/null; then
        flaky_indicators=$((flaky_indicators + $({ grep -r "@pytest.mark.flaky" "$CODEBASE_PATH" 2>/dev/null || true; } | wc -l)))
        add_finding "high" "flakiness" "Explicit flaky test markers found - tests are known unreliable"
        adjust_trust_multiplier 0.7
    fi
    
    # Calculate flakiness indicators
    flaky_indicators=$((time_based_tests + randomness_tests + network_tests))
    
    log_elite_metric "flaky_test_indicators" "$flaky_indicators"
    log_elite_metric "time_based_test_count" "$time_based_tests"
    log_elite_metric "randomness_usage_count" "$randomness_tests"
    log_elite_metric "unmocked_network_tests" "$network_tests"
    log_elite_metric "retry_configured" "$retry_configured"
    
    # Score calculation
    if [ "$flaky_indicators" -gt 20 ]; then
        flakiness_score=2
        add_finding "critical" "flakiness" "High flakiness risk: $flaky_indicators unreliable patterns detected"
        adjust_trust_multiplier 0.6
    elif [ "$flaky_indicators" -gt 10 ]; then
        flakiness_score=4
        add_finding "high" "flakiness" "Moderate flakiness risk: $flaky_indicators unreliable patterns"
        adjust_trust_multiplier 0.8
    elif [ "$flaky_indicators" -gt 5 ]; then
        flakiness_score=6
    elif [ "$flaky_indicators" -gt 0 ]; then
        flakiness_score=8
    fi
    
    log_elite_metric "flakiness_score" "$flakiness_score"
    echo "$flakiness_score"
}

# =============================================================================
# 2. MUTATION TESTING AWARENESS
# =============================================================================
# Coverage tells you what ran. Mutation tells you what mattered.
# =============================================================================

analyze_mutation_testing() {
    progress_step "Analyzing mutation testing"
    
    local mutation_score=5
    local mutation_detected=false
    local mutation_configured=false
    local mutation_result=0
    
    # JavaScript/TypeScript - Stryker
    if [ -f "$CODEBASE_PATH/stryker.conf.js" ] || [ -f "$CODEBASE_PATH/stryker.conf.json" ] || \
       [ -f "$CODEBASE_PATH/stryker.conf.mjs" ]; then
        mutation_configured=true
        mutation_detected=true
        mutation_score=8
        log_elite_metric "mutation_framework" "stryker"
    fi
    
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        if grep -q '"@stryker-mutator' "$CODEBASE_PATH/package.json" 2>/dev/null; then
            mutation_detected=true
            mutation_score=8
        fi
    fi
    
    # Python - MutPy, CosmicRay, mutmut
    if [ -f "$CODEBASE_PATH/setup.cfg" ] || [ -f "$CODEBASE_PATH/pyproject.toml" ]; then
        if grep -qE "(mutmut|cosmic-ray|mutpy)" "$CODEBASE_PATH/setup.cfg" "$CODEBASE_PATH/pyproject.toml" "$CODEBASE_PATH/requirements"*.txt 2>/dev/null; then
            mutation_detected=true
            mutation_score=8
            log_elite_metric "mutation_framework" "python-mutation"
        fi
    fi
    
    # Check for mutation reports
    if [ -d "$CODEBASE_PATH/reports/mutation" ] || [ -f "$CODEBASE_PATH/mutation.log" ] || \
       [ -d "$CODEBASE_PATH/.stryker-tmp" ]; then
        mutation_detected=true
        mutation_score=9
        
        # Try to parse mutation score from reports
        if [ -f "$CODEBASE_PATH/reports/mutation/mutation.json" ]; then
            mutation_result=$(jq '.mutationScore // 0' "$CODEBASE_PATH/reports/mutation/mutation.json" 2>/dev/null || echo "0")
            log_elite_metric "mutation_score_result" "$mutation_result"
            
            if [ "$mutation_result" -ge 80 ]; then
                mutation_score=10
                adjust_signal_multiplier 1.2
            fi
        fi
    fi
    
    # Check CI for mutation testing
    if find "$CODEBASE_PATH/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | \
       xargs grep -lE "(stryker|mutmut|mutation)" 2>/dev/null | head -1 > /dev/null; then
        mutation_detected=true
        mutation_score=$((mutation_score + 1))
        [ "$mutation_score" -gt 10 ] && mutation_score=10
    fi
    
    if [ "$mutation_detected" = false ]; then
        add_finding "medium" "mutation_testing" "No mutation testing detected - coverage may be misleading"
        mutation_score=3
    else
        add_finding "info" "mutation_testing" "Mutation testing detected - high confidence in test effectiveness"
        adjust_signal_multiplier 1.15
    fi
    
    log_elite_metric "mutation_testing_detected" "$mutation_detected"
    log_elite_metric "mutation_configured" "$mutation_configured"
    log_elite_metric "mutation_testing_score" "$mutation_score"
    
    echo "$mutation_score"
}

# =============================================================================
# 3. ASSERTION QUALITY ANALYSIS
# =============================================================================
# Tests fail because assertions are weak, not missing.
# =============================================================================

analyze_assertion_quality() {
    progress_step "Analyzing assertion quality"
    
    local assertion_score=5
    local total_assertions=0
    local weak_assertions=0
    local snapshot_count=0
    local test_count=0
    local deep_assertions=0
    
    local test_files
    test_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.test.js" -o -name "*.test.ts" -o -name "*.test.tsx" -o \
        -name "*.spec.js" -o -name "*.spec.ts" -o -name "*.spec.tsx" -o \
        -name "test_*.py" -o -name "*_test.py" \
        \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -100 || true)
    
    if [ -n "$test_files" ]; then
        while IFS= read -r test_file; do
            [ -z "$test_file" ] && continue
            
            # Count test cases
            local file_tests
            file_tests=$(grep_count "(it\(|test\(|def test_|func Test)" "$test_file")
            test_count=$((test_count + file_tests))
            
            # Count all assertions
            local file_assertions
            file_assertions=$(grep_count "(expect\(|assert|should\.|toBe|toEqual|toHave|assertEqual|assertTrue)" "$test_file")
            total_assertions=$((total_assertions + file_assertions))
            
            # Count weak/shallow assertions
            local file_weak
            file_weak=$(grep_count "(toBeTruthy|toBeFalsy|toBeDefined|toBeNull|toBeUndefined|\.exist|\.ok\b|assertIsNotNone|assertIsNone|\.to\.exist)" "$test_file")
            weak_assertions=$((weak_assertions + file_weak))
            
            # Count deep/specific assertions
            local file_deep
            file_deep=$(grep_count "(toEqual|toMatchObject|toHaveProperty|toContain|toHaveBeenCalledWith|assertEqual.*,.*,|assertDictEqual|assertListEqual)" "$test_file")
            deep_assertions=$((deep_assertions + file_deep))
            
            # Count snapshots
            local file_snapshots
            file_snapshots=$(grep_count "(toMatchSnapshot|toMatchInlineSnapshot)" "$test_file")
            snapshot_count=$((snapshot_count + file_snapshots))
            
        done <<< "$test_files"
    fi
    
    # Calculate metrics
    local assertion_density=0
    local weak_assertion_ratio=0
    local snapshot_overuse_score=0
    
    if [ "$test_count" -gt 0 ]; then
        assertion_density=$(math_calc "$total_assertions / $test_count")
    fi
    
    if [ "$total_assertions" -gt 0 ]; then
        weak_assertion_ratio=$(math_calc "$weak_assertions / $total_assertions")
        snapshot_overuse_score=$(math_calc "$snapshot_count / $total_assertions")
    fi
    
    log_elite_metric "total_assertions" "$total_assertions"
    log_elite_metric "weak_assertions" "$weak_assertions"
    log_elite_metric "deep_assertions" "$deep_assertions"
    log_elite_metric "snapshot_count" "$snapshot_count"
    log_elite_metric "assertion_density" "$assertion_density"
    log_elite_metric "weak_assertion_ratio" "$weak_assertion_ratio"
    log_elite_metric "snapshot_overuse_score" "$snapshot_overuse_score"
    
    # Score based on assertion quality
    if math_compare "$assertion_density" ">=" "5" && math_compare "$weak_assertion_ratio" "<" "0.2"; then
        assertion_score=10
    elif math_compare "$assertion_density" ">=" "3" && math_compare "$weak_assertion_ratio" "<" "0.3"; then
        assertion_score=8
    elif math_compare "$assertion_density" ">=" "2"; then
        assertion_score=6
    elif math_compare "$assertion_density" ">=" "1"; then
        assertion_score=4
    else
        assertion_score=2
        add_finding "high" "assertion_quality" "Very low assertion density ($assertion_density per test)"
    fi
    
    # Penalize weak assertions
    if math_compare "$weak_assertion_ratio" ">" "0.5"; then
        add_finding "high" "assertion_quality" "High weak assertion ratio (${weak_assertion_ratio}) - tests may pass incorrectly"
        assertion_score=$((assertion_score - 2))
        adjust_signal_multiplier 0.8
    elif math_compare "$weak_assertion_ratio" ">" "0.3"; then
        add_finding "medium" "assertion_quality" "Moderate weak assertion ratio (${weak_assertion_ratio})"
        assertion_score=$((assertion_score - 1))
    fi
    
    # Penalize snapshot overuse
    if math_compare "$snapshot_overuse_score" ">" "0.5"; then
        add_finding "high" "assertion_quality" "High snapshot overuse masking assertion intent"
        assertion_score=$((assertion_score - 2))
        adjust_signal_multiplier 0.85
    elif math_compare "$snapshot_overuse_score" ">" "0.3"; then
        add_finding "medium" "assertion_quality" "Moderate snapshot usage - consider explicit assertions"
        assertion_score=$((assertion_score - 1))
    fi
    
    [ "$assertion_score" -lt 1 ] && assertion_score=1
    [ "$assertion_score" -gt 10 ] && assertion_score=10
    
    log_elite_metric "assertion_quality_score" "$assertion_score"
    echo "$assertion_score"
}

# =============================================================================
# 4. TEST INTENT & READABILITY
# =============================================================================
# Tests are executable documentation.
# =============================================================================

analyze_test_intent() {
    progress_step "Analyzing test intent & readability"
    
    local intent_score=5
    local behavioral_tests=0
    local total_tests=0
    local nested_describe_issues=0
    local magic_value_count=0
    
    local test_files
    test_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.test.js" -o -name "*.test.ts" -o -name "*.test.tsx" -o \
        -name "*.spec.js" -o -name "*.spec.ts" -o -name "*.spec.tsx" \
        \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -50 || true)
    
    if [ -n "$test_files" ]; then
        while IFS= read -r test_file; do
            [ -z "$test_file" ] && continue
            
            # Count tests with behavioral names (should/when/given patterns)
            local file_behavioral
            file_behavioral=$(grep_count "(should|when|given|then|returns|throws|handles|creates|updates|deletes)" "$test_file")
            behavioral_tests=$((behavioral_tests + file_behavioral))
            
            # Count total test declarations
            local file_tests
            file_tests=$(grep_count "(it\(|test\(|describe\()" "$test_file")
            total_tests=$((total_tests + file_tests))
            
            # Detect deeply nested describes (>3 levels is a smell)
            local max_depth
            max_depth=$(awk '/describe\(/{depth++; if(depth>max) max=depth} /}\);/{depth--} END{print max+0}' "$test_file" 2>/dev/null) || max_depth=0
            if [ "$max_depth" -gt 3 ]; then
                nested_describe_issues=$((nested_describe_issues + 1))
            fi
            
            # Count magic values (hardcoded numbers/strings in assertions)
            local file_magic
            file_magic=$(grep_count "toBe\([0-9]{3,}\)|toEqual\([0-9]{3,}\)|assertEqual.*[0-9]{4,}" "$test_file")
            magic_value_count=$((magic_value_count + file_magic))
            
        done <<< "$test_files"
    fi
    
    # Calculate behavioral ratio
    local behavioral_ratio=0
    if [ "$total_tests" -gt 0 ]; then
        behavioral_ratio=$(math_calc "$behavioral_tests / $total_tests")
    fi
    
    log_elite_metric "behavioral_test_count" "$behavioral_tests"
    log_elite_metric "behavioral_test_ratio" "$behavioral_ratio"
    log_elite_metric "nested_describe_issues" "$nested_describe_issues"
    log_elite_metric "magic_value_count" "$magic_value_count"
    
    # Score based on intent clarity
    if math_compare "$behavioral_ratio" ">=" "0.7"; then
        intent_score=10
    elif math_compare "$behavioral_ratio" ">=" "0.5"; then
        intent_score=8
    elif math_compare "$behavioral_ratio" ">=" "0.3"; then
        intent_score=6
    else
        intent_score=4
        add_finding "medium" "test_intent" "Test names lack behavioral descriptions"
    fi
    
    # Penalize nesting issues
    if [ "$nested_describe_issues" -gt 5 ]; then
        add_finding "medium" "test_intent" "Excessive describe nesting reduces readability"
        intent_score=$((intent_score - 2))
    fi
    
    # Penalize magic values
    if [ "$magic_value_count" -gt 20 ]; then
        add_finding "low" "test_intent" "Many magic values in tests - consider named constants"
        intent_score=$((intent_score - 1))
    fi
    
    [ "$intent_score" -lt 1 ] && intent_score=1
    [ "$intent_score" -gt 10 ] && intent_score=10
    
    log_elite_metric "test_intent_score" "$intent_score"
    echo "$intent_score"
}

# =============================================================================
# 5. ISOLATION & DETERMINISM
# =============================================================================
# Reliable tests control their universe.
# =============================================================================

analyze_isolation() {
    progress_step "Analyzing test isolation & determinism"
    
    local isolation_score=8
    local global_state_mutations=0
    local missing_cleanup=0
    local mock_reset_missing=0
    local shared_state_issues=0
    
    local test_files
    test_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.test.js" -o -name "*.test.ts" -o -name "*.test.tsx" -o \
        -name "*.spec.js" -o -name "*.spec.ts" -o -name "*.spec.tsx" -o \
        -name "test_*.py" -o -name "*_test.py" \
        \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -50 || true)
    
    if [ -n "$test_files" ]; then
        while IFS= read -r test_file; do
            [ -z "$test_file" ] && continue
            
            # Detect global state mutations
            local file_globals
            file_globals=$(grep_count "(global\.|window\.|process\.env\.|globalThis\.)" "$test_file")
            global_state_mutations=$((global_state_mutations + file_globals))
            
            # Check for beforeEach/afterEach without cleanup
            local has_before_each
            has_before_each=$(grep_count "beforeEach|setUp" "$test_file")
            local has_after_each
            has_after_each=$(grep_count "afterEach|tearDown" "$test_file")
            
            if [ "$has_before_each" -gt 0 ] && [ "$has_after_each" -eq 0 ]; then
                missing_cleanup=$((missing_cleanup + 1))
            fi
            
            # Check for mock resets
            local has_mocks
            has_mocks=$(grep_count "(jest\.mock|sinon\.|vi\.mock|@mock|@patch)" "$test_file")
            local has_reset
            has_reset=$(grep_count "(mockReset|mockClear|restore\(\)|reset_mock)" "$test_file")
            
            if [ "$has_mocks" -gt 2 ] && [ "$has_reset" -eq 0 ]; then
                mock_reset_missing=$((mock_reset_missing + 1))
            fi
            
            # Detect shared state between tests
            local shared_vars
            shared_vars=$(grep_count "^(let|var) [a-zA-Z]+" "$test_file")
            if [ "$shared_vars" -gt 5 ]; then
                shared_state_issues=$((shared_state_issues + 1))
            fi
            
        done <<< "$test_files"
    fi
    
    log_elite_metric "global_state_mutations" "$global_state_mutations"
    log_elite_metric "missing_cleanup_count" "$missing_cleanup"
    log_elite_metric "mock_reset_missing" "$mock_reset_missing"
    log_elite_metric "shared_state_issues" "$shared_state_issues"
    
    # Score based on isolation
    if [ "$global_state_mutations" -gt 20 ]; then
        add_finding "high" "isolation" "Heavy global state mutation in tests - order dependency risk"
        isolation_score=$((isolation_score - 3))
        adjust_trust_multiplier 0.85
    elif [ "$global_state_mutations" -gt 10 ]; then
        add_finding "medium" "isolation" "Moderate global state mutation in tests"
        isolation_score=$((isolation_score - 1))
    fi
    
    if [ "$missing_cleanup" -gt 5 ]; then
        add_finding "medium" "isolation" "Tests with setup but no cleanup ($missing_cleanup files)"
        isolation_score=$((isolation_score - 2))
    fi
    
    if [ "$mock_reset_missing" -gt 5 ]; then
        add_finding "medium" "isolation" "Mocks not being reset between tests ($mock_reset_missing files)"
        isolation_score=$((isolation_score - 1))
        adjust_trust_multiplier 0.9
    fi
    
    [ "$isolation_score" -lt 1 ] && isolation_score=1
    [ "$isolation_score" -gt 10 ] && isolation_score=10
    
    log_elite_metric "isolation_score" "$isolation_score"
    echo "$isolation_score"
}

# =============================================================================
# 6. MOCKING STRATEGY QUALITY
# =============================================================================
# Bad mocks lie.
# =============================================================================

analyze_mocking_quality() {
    progress_step "Analyzing mocking strategy"
    
    local mocking_score=7
    local total_mocks=0
    local implementation_mocks=0
    local network_mocks=0
    local database_mocks=0
    
    local test_files
    test_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.test.js" -o -name "*.test.ts" -o -name "*.test.tsx" -o \
        -name "*.spec.js" -o -name "*.spec.ts" -o -name "*.spec.tsx" -o \
        -name "test_*.py" -o -name "*_test.py" \
        \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -50 || true)
    
    local source_file_count
    source_file_count=$(find "$CODEBASE_PATH" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        -not -path "*/node_modules/*" -not -name "*.test.*" -not -name "*.spec.*" 2>/dev/null | wc -l)
    
    if [ -n "$test_files" ]; then
        while IFS= read -r test_file; do
            [ -z "$test_file" ] && continue
            
            # Count total mocks
            local file_mocks
            file_mocks=$(grep_count "(jest\.mock|jest\.spyOn|sinon\.|vi\.mock|@mock|@patch|MagicMock|Mock\()" "$test_file")
            total_mocks=$((total_mocks + file_mocks))
            
            # Detect implementation detail mocking (bad practice)
            local file_impl_mocks
            file_impl_mocks=$(grep_count "\.mockImplementation|mockReturnValue\(.*\{" "$test_file")
            implementation_mocks=$((implementation_mocks + file_impl_mocks))
            
            # Count network mocking (good practice)
            local file_network
            file_network=$(grep_count "(nock|msw|fetchMock|responses|httpretty)" "$test_file")
            network_mocks=$((network_mocks + file_network))
            
            # Count database mocking
            local file_db
            file_db=$(grep_count "(mockDatabase|@mock.*db|mock.*repository|InMemory.*Repository)" "$test_file")
            database_mocks=$((database_mocks + file_db))
            
        done <<< "$test_files"
    fi
    
    # Calculate mock density
    local mock_density=0
    if [ "$source_file_count" -gt 0 ]; then
        mock_density=$(math_calc "$total_mocks / $source_file_count")
    fi
    
    # Calculate overmocking score
    local overmocking_score=0
    if [ "$total_mocks" -gt 0 ]; then
        overmocking_score=$(math_calc "$implementation_mocks / $total_mocks")
    fi
    
    log_elite_metric "total_mocks" "$total_mocks"
    log_elite_metric "implementation_mocks" "$implementation_mocks"
    log_elite_metric "network_mocks" "$network_mocks"
    log_elite_metric "database_mocks" "$database_mocks"
    log_elite_metric "mock_density" "$mock_density"
    log_elite_metric "overmocking_score" "$overmocking_score"
    
    # Score based on mocking quality
    if [ "$network_mocks" -gt 0 ] && [ "$database_mocks" -gt 0 ]; then
        mocking_score=$((mocking_score + 2))
    fi
    
    if math_compare "$overmocking_score" ">" "0.5"; then
        add_finding "high" "mocking" "High implementation mocking - tests coupled to internals"
        mocking_score=$((mocking_score - 3))
        adjust_signal_multiplier 0.85
    elif math_compare "$overmocking_score" ">" "0.3"; then
        add_finding "medium" "mocking" "Moderate implementation mocking detected"
        mocking_score=$((mocking_score - 1))
    fi
    
    if math_compare "$mock_density" ">" "5"; then
        add_finding "medium" "mocking" "Very high mock density - consider integration tests"
        mocking_score=$((mocking_score - 1))
    fi
    
    [ "$mocking_score" -lt 1 ] && mocking_score=1
    [ "$mocking_score" -gt 10 ] && mocking_score=10
    
    log_elite_metric "mocking_quality_score" "$mocking_score"
    echo "$mocking_score"
}

# =============================================================================
# 7. INTEGRATION VS UNIT BALANCE (Test Pyramid)
# =============================================================================
# 1,000 unit tests won't catch a broken system.
# =============================================================================

analyze_test_pyramid() {
    progress_step "Analyzing test pyramid balance"
    
    local pyramid_score=5
    local unit_tests=0
    local integration_tests=0
    local e2e_tests=0
    local contract_tests=0
    
    # Count unit tests
    unit_tests=$(find "$CODEBASE_PATH" -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" \) \
        -not -path "*/node_modules/*" -not -path "*/e2e/*" -not -path "*/integration/*" \
        -not -path "*/cypress/*" -not -path "*/playwright/*" 2>/dev/null | wc -l)
    
    # Count integration tests
    integration_tests=$(find "$CODEBASE_PATH" -type f \( -name "*integration*" -o -name "*int.*" \) \
        -not -path "*/node_modules/*" 2>/dev/null | wc -l)
    integration_tests=$((integration_tests + $(find "$CODEBASE_PATH" -path "*/integration/*" -type f \
        \( -name "*.test.*" -o -name "*.spec.*" \) 2>/dev/null | wc -l)))
    
    # Count E2E tests
    e2e_tests=$(find "$CODEBASE_PATH" -type f -path "*/e2e/*" 2>/dev/null | wc -l)
    e2e_tests=$((e2e_tests + $(find "$CODEBASE_PATH" -type f -path "*/cypress/*" -name "*.cy.*" 2>/dev/null | wc -l)))
    e2e_tests=$((e2e_tests + $(find "$CODEBASE_PATH" -type f -path "*/playwright/*" -name "*.spec.*" 2>/dev/null | wc -l)))
    
    # Check for contract tests
    if find "$CODEBASE_PATH" -type f \( -name "*contract*" -o -name "*pact*" \) 2>/dev/null | head -1 > /dev/null; then
        contract_tests=$(find "$CODEBASE_PATH" -type f \( -name "*contract*" -o -name "*pact*" \) 2>/dev/null | wc -l)
        log_elite_metric "contract_tests_present" "true"
    else
        log_elite_metric "contract_tests_present" "false"
    fi
    
    local total_tests=$((unit_tests + integration_tests + e2e_tests))
    
    log_elite_metric "unit_test_count" "$unit_tests"
    log_elite_metric "integration_test_count" "$integration_tests"
    log_elite_metric "e2e_test_count" "$e2e_tests"
    log_elite_metric "contract_test_count" "$contract_tests"
    
    # Determine pyramid shape
    local pyramid_balance="unknown"
    if [ "$total_tests" -gt 0 ]; then
        local unit_ratio
        unit_ratio=$(math_calc "$unit_tests / $total_tests")
        local integration_ratio
        integration_ratio=$(math_calc "$integration_tests / $total_tests")
        local e2e_ratio
        e2e_ratio=$(math_calc "$e2e_tests / $total_tests")
        
        log_elite_metric "unit_ratio" "$unit_ratio"
        log_elite_metric "integration_ratio" "$integration_ratio"
        log_elite_metric "e2e_ratio" "$e2e_ratio"
        
        # Ideal pyramid: ~70% unit, ~20% integration, ~10% e2e
        if math_compare "$unit_ratio" ">" "0.8" && math_compare "$integration_ratio" "<" "0.1"; then
            pyramid_balance="unit-heavy"
            add_finding "medium" "test_pyramid" "Test pyramid is unit-heavy - may miss integration bugs"
            pyramid_score=5
        elif math_compare "$e2e_ratio" ">" "0.5"; then
            pyramid_balance="e2e-heavy"
            add_finding "high" "test_pyramid" "Test pyramid is inverted (e2e-heavy) - slow and brittle"
            pyramid_score=3
            adjust_trust_multiplier 0.9
        elif math_compare "$integration_ratio" ">=" "0.1" && math_compare "$e2e_ratio" ">=" "0.05"; then
            pyramid_balance="balanced"
            pyramid_score=9
        else
            pyramid_balance="needs-work"
            pyramid_score=5
        fi
    fi
    
    log_elite_metric "test_pyramid_balance" "$pyramid_balance"
    
    # Bonus for contract tests
    if [ "$contract_tests" -gt 0 ]; then
        pyramid_score=$((pyramid_score + 1))
        adjust_signal_multiplier 1.1
    fi
    
    # Penalty if no integration or e2e tests
    if [ "$integration_tests" -eq 0 ] && [ "$e2e_tests" -eq 0 ]; then
        add_finding "high" "test_pyramid" "No integration or E2E tests - system-level bugs may go undetected"
        pyramid_score=$((pyramid_score - 2))
        adjust_risk_multiplier 0.7
    fi
    
    [ "$pyramid_score" -lt 1 ] && pyramid_score=1
    [ "$pyramid_score" -gt 10 ] && pyramid_score=10
    
    log_elite_metric "test_pyramid_score" "$pyramid_score"
    echo "$pyramid_score"
}

# =============================================================================
# 8. FAILURE DIAGNOSTICS QUALITY
# =============================================================================
# When a test fails at 2am, does it help or hurt?
# =============================================================================

analyze_failure_diagnostics() {
    progress_step "Analyzing failure diagnostics quality"
    
    local diagnostics_score=6
    local custom_matchers=0
    local descriptive_errors=0
    local context_assertions=0
    
    local test_files
    test_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.test.js" -o -name "*.test.ts" -o -name "*.test.tsx" -o \
        -name "*.spec.js" -o -name "*.spec.ts" -o -name "*.spec.tsx" -o \
        -name "test_*.py" -o -name "*_test.py" \
        \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -50 || true)
    
    if [ -n "$test_files" ]; then
        while IFS= read -r test_file; do
            [ -z "$test_file" ] && continue
            
            # Count custom matchers
            local file_matchers
            file_matchers=$(grep_count "(expect\.extend|addMatcher|register_assert)" "$test_file")
            custom_matchers=$((custom_matchers + file_matchers))
            
            # Count assertions with descriptive messages
            local file_descriptive
            file_descriptive=$(grep_count "(expect\(.*\)\..*\(.*,\s*['\"]|assert.*,\s*['\"]|assertEqual\(.*,.*,\s*['\"])" "$test_file")
            descriptive_errors=$((descriptive_errors + file_descriptive))
            
            # Count context in assertions (objects, arrays with meaning)
            local file_context
            file_context=$(grep_count "(toMatchObject|toHaveProperty.*,|assertDictContainsSubset)" "$test_file")
            context_assertions=$((context_assertions + file_context))
            
        done <<< "$test_files"
    fi
    
    # Check for custom test utilities
    local has_test_utils=false
    if find "$CODEBASE_PATH" -type f \( -name "test-utils.*" -o -name "testUtils.*" -o -name "testing.*" \) \
        -not -path "*/node_modules/*" 2>/dev/null | head -1 > /dev/null; then
        has_test_utils=true
        diagnostics_score=$((diagnostics_score + 1))
    fi
    
    log_elite_metric "custom_matcher_count" "$custom_matchers"
    log_elite_metric "descriptive_error_count" "$descriptive_errors"
    log_elite_metric "context_assertion_count" "$context_assertions"
    log_elite_metric "has_test_utilities" "$has_test_utils"
    
    # Score based on diagnostics quality
    if [ "$custom_matchers" -gt 5 ]; then
        diagnostics_score=$((diagnostics_score + 2))
        add_finding "info" "diagnostics" "Good use of custom matchers for better error messages"
    fi
    
    if [ "$descriptive_errors" -gt 20 ]; then
        diagnostics_score=$((diagnostics_score + 1))
    elif [ "$descriptive_errors" -eq 0 ]; then
        add_finding "low" "diagnostics" "No descriptive error messages in assertions"
        diagnostics_score=$((diagnostics_score - 1))
    fi
    
    [ "$diagnostics_score" -lt 1 ] && diagnostics_score=1
    [ "$diagnostics_score" -gt 10 ] && diagnostics_score=10
    
    log_elite_metric "failure_diagnostics_score" "$diagnostics_score"
    echo "$diagnostics_score"
}

# =============================================================================
# 9. REGRESSION INTENT DETECTION
# =============================================================================
# Good tests remember why bugs happened.
# =============================================================================

analyze_regression_intent() {
    progress_step "Analyzing regression intent"
    
    local regression_score=5
    local bug_references=0
    local issue_references=0
    local regression_markers=0
    
    local test_files
    test_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.test.js" -o -name "*.test.ts" -o -name "*.test.tsx" -o \
        -name "*.spec.js" -o -name "*.spec.ts" -o -name "*.spec.tsx" -o \
        -name "test_*.py" -o -name "*_test.py" \
        \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null || true)
    
    if [ -n "$test_files" ]; then
        # Search for issue/bug references
        bug_references=$(grep -rE "(bug|fix|issue|ticket|jira|github\.com/.*/(issues|pull))" $test_files 2>/dev/null | wc -l)
        issue_references=$(grep -rE "(#[0-9]{2,}|[A-Z]+-[0-9]+)" $test_files 2>/dev/null | wc -l)
        regression_markers=$(grep -rE "(regression|reproduces|prevents|ensures.*fixed)" $test_files 2>/dev/null | wc -l)
    fi
    
    local total_markers=$((bug_references + issue_references + regression_markers))
    
    log_elite_metric "bug_reference_count" "$bug_references"
    log_elite_metric "issue_reference_count" "$issue_references"
    log_elite_metric "regression_marker_count" "$regression_markers"
    
    # Calculate regression test ratio
    local test_count
    test_count=$(find "$CODEBASE_PATH" -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" \) \
        -not -path "*/node_modules/*" 2>/dev/null | wc -l)
    
    local regression_ratio=0
    if [ "$test_count" -gt 0 ]; then
        regression_ratio=$(math_calc "$total_markers / $test_count")
    fi
    
    log_elite_metric "regression_test_ratio" "$regression_ratio"
    
    # Score based on regression intent
    if math_compare "$regression_ratio" ">=" "0.3"; then
        regression_score=10
        add_finding "info" "regression" "Excellent regression test documentation"
    elif math_compare "$regression_ratio" ">=" "0.15"; then
        regression_score=8
    elif math_compare "$regression_ratio" ">=" "0.05"; then
        regression_score=6
    elif [ "$total_markers" -gt 0 ]; then
        regression_score=5
    else
        regression_score=3
        add_finding "low" "regression" "No regression test markers found - bug history not documented"
    fi
    
    log_elite_metric "regression_intent_score" "$regression_score"
    echo "$regression_score"
}

# =============================================================================
# 10. TEST EXECUTION PERFORMANCE
# =============================================================================
# Slow tests don't run often. Untested code ships.
# =============================================================================

analyze_test_performance() {
    progress_step "Analyzing test execution performance"
    
    local performance_score=7
    local slow_test_indicators=0
    local parallelization_configured=false
    local watch_mode_configured=false
    
    # Check for parallelization configuration
    if [ -f "$CODEBASE_PATH/jest.config.js" ] || [ -f "$CODEBASE_PATH/jest.config.ts" ]; then
        if grep -qE "(maxWorkers|--runInBand=false)" "$CODEBASE_PATH"/jest.config.* 2>/dev/null; then
            parallelization_configured=true
        fi
        if grep -qE "(--watch|watchAll)" "$CODEBASE_PATH/package.json" 2>/dev/null; then
            watch_mode_configured=true
        fi
    fi
    
    if [ -f "$CODEBASE_PATH/vitest.config.ts" ]; then
        if grep -qE "(pool|threads)" "$CODEBASE_PATH/vitest.config.ts" 2>/dev/null; then
            parallelization_configured=true
        fi
    fi
    
    # Check pytest configuration
    if [ -f "$CODEBASE_PATH/pytest.ini" ] || [ -f "$CODEBASE_PATH/pyproject.toml" ]; then
        if grep -qE "(pytest-xdist|-n auto|-n [0-9])" "$CODEBASE_PATH/pytest.ini" "$CODEBASE_PATH/pyproject.toml" "$CODEBASE_PATH/setup.cfg" 2>/dev/null; then
            parallelization_configured=true
        fi
    fi
    
    # Detect slow test patterns
    local test_files
    test_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.test.js" -o -name "*.test.ts" -o -name "*.test.tsx" -o \
        -name "*.spec.js" -o -name "*.spec.ts" -o -name "*.spec.tsx" -o \
        -name "test_*.py" -o -name "*_test.py" \
        \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -50 || true)
    
    if [ -n "$test_files" ]; then
        # Count tests with explicit timeouts (indication of slow tests)
        slow_test_indicators=$(grep -rE "(timeout:\s*[0-9]{4,}|jest\.setTimeout\([0-9]{4,}\)|@pytest\.mark\.timeout\([0-9]{2,}\))" $test_files 2>/dev/null | wc -l)
        
        # Count tests with explicit delays
        slow_test_indicators=$((slow_test_indicators + $(grep -rE "(\.sleep\([0-9]+\)|setTimeout.*[0-9]{4,})" $test_files 2>/dev/null | wc -l)))
    fi
    
    log_elite_metric "parallelization_configured" "$parallelization_configured"
    log_elite_metric "watch_mode_configured" "$watch_mode_configured"
    log_elite_metric "slow_test_indicators" "$slow_test_indicators"
    
    # Score based on performance setup
    if [ "$parallelization_configured" = true ]; then
        performance_score=$((performance_score + 2))
    else
        add_finding "medium" "performance" "Test parallelization not configured - slower CI"
        performance_score=$((performance_score - 1))
    fi
    
    if [ "$watch_mode_configured" = true ]; then
        performance_score=$((performance_score + 1))
    fi
    
    if [ "$slow_test_indicators" -gt 10 ]; then
        add_finding "medium" "performance" "Multiple slow tests detected ($slow_test_indicators indicators)"
        performance_score=$((performance_score - 2))
    elif [ "$slow_test_indicators" -gt 5 ]; then
        performance_score=$((performance_score - 1))
    fi
    
    [ "$performance_score" -lt 1 ] && performance_score=1
    [ "$performance_score" -gt 10 ] && performance_score=10
    
    log_elite_metric "test_performance_score" "$performance_score"
    echo "$performance_score"
}

# =============================================================================
# 11. RISK-WEIGHTED COVERAGE
# =============================================================================
# Not all code deserves equal coverage.
# =============================================================================

analyze_risk_weighted_coverage() {
    progress_step "Analyzing risk-weighted coverage"
    
    local risk_coverage_score=5
    local high_risk_files=0
    local high_risk_tested=0
    
    # Identify high-risk files (payment, auth, security, API)
    local high_risk_patterns="(payment|billing|auth|login|security|crypto|password|token|api|handler)"
    
    high_risk_files=$(find "$CODEBASE_PATH" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        -not -path "*/node_modules/*" -not -name "*.test.*" -not -name "*.spec.*" \
        2>/dev/null | { grep -iE "$high_risk_patterns" || true; } | wc -l)
    
    # Check if high-risk files have tests
    while IFS= read -r risk_file; do
        [ -z "$risk_file" ] && continue
        local base_name
        base_name=$(basename "$risk_file" | sed 's/\.[^.]*$//')
        
        if find "$CODEBASE_PATH" -type f \( \
            -name "${base_name}.test.*" -o -name "${base_name}.spec.*" -o \
            -name "test_${base_name}.*" -o -name "${base_name}_test.*" \
            \) -not -path "*/node_modules/*" 2>/dev/null | head -1 > /dev/null; then
            high_risk_tested=$((high_risk_tested + 1))
        else
            add_finding "high" "risk_coverage" "High-risk file lacks test coverage" "$risk_file"
        fi
    done < <(find "$CODEBASE_PATH" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        -not -path "*/node_modules/*" -not -name "*.test.*" -not -name "*.spec.*" \
        2>/dev/null | grep -iE "$high_risk_patterns" | head -20)
    
    # Calculate risk coverage ratio
    local risk_coverage_ratio=0
    if [ "$high_risk_files" -gt 0 ]; then
        risk_coverage_ratio=$(math_calc "$high_risk_tested / $high_risk_files")
    fi
    
    log_elite_metric "high_risk_file_count" "$high_risk_files"
    log_elite_metric "high_risk_files_tested" "$high_risk_tested"
    log_elite_metric "risk_weighted_coverage" "$risk_coverage_ratio"
    
    # Score based on risk coverage
    if math_compare "$risk_coverage_ratio" ">=" "0.9"; then
        risk_coverage_score=10
    elif math_compare "$risk_coverage_ratio" ">=" "0.7"; then
        risk_coverage_score=8
    elif math_compare "$risk_coverage_ratio" ">=" "0.5"; then
        risk_coverage_score=6
    elif math_compare "$risk_coverage_ratio" ">=" "0.3"; then
        risk_coverage_score=4
        add_finding "high" "risk_coverage" "Critical code paths have low test coverage"
        adjust_risk_multiplier 0.8
    else
        risk_coverage_score=2
        add_finding "critical" "risk_coverage" "High-risk code largely untested - production safety at risk"
        adjust_risk_multiplier 0.6
    fi
    
    log_elite_metric "risk_weighted_coverage_score" "$risk_coverage_score"
    echo "$risk_coverage_score"
}

# =============================================================================
# 12. PROPERTY-BASED & FUZZ TESTING
# =============================================================================
# Edge cases don't write themselves.
# =============================================================================

analyze_property_testing() {
    progress_step "Analyzing property-based & fuzz testing"
    
    local property_score=3
    local property_testing_detected=false
    local fuzz_testing_detected=false
    
    # JavaScript - fast-check
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        if grep -q '"fast-check"' "$CODEBASE_PATH/package.json" 2>/dev/null; then
            property_testing_detected=true
            property_score=8
            log_elite_metric "property_framework" "fast-check"
        fi
    fi
    
    # Python - Hypothesis
    if grep -rqE "(from hypothesis|import hypothesis|@given)" "$CODEBASE_PATH" 2>/dev/null; then
        property_testing_detected=true
        property_score=8
        log_elite_metric "property_framework" "hypothesis"
    fi
    
    # Check for fuzz testing
    if find "$CODEBASE_PATH" -type f -name "*fuzz*" 2>/dev/null | head -1 > /dev/null; then
        fuzz_testing_detected=true
        property_score=$((property_score + 1))
    fi
    
    # Go - fuzzing support
    if find "$CODEBASE_PATH" -type f -name "*_test.go" 2>/dev/null | \
       xargs grep -lE "func Fuzz" 2>/dev/null | head -1 > /dev/null; then
        fuzz_testing_detected=true
        property_score=9
    fi
    
    log_elite_metric "property_testing_detected" "$property_testing_detected"
    log_elite_metric "fuzz_testing_detected" "$fuzz_testing_detected"
    
    if [ "$property_testing_detected" = true ] || [ "$fuzz_testing_detected" = true ]; then
        add_finding "info" "property_testing" "Property-based/fuzz testing detected - excellent edge case coverage"
        adjust_signal_multiplier 1.15
    else
        add_finding "low" "property_testing" "No property-based or fuzz testing - edge cases may be missed"
    fi
    
    [ "$property_score" -lt 1 ] && property_score=1
    [ "$property_score" -gt 10 ] && property_score=10
    
    log_elite_metric "property_testing_score" "$property_score"
    echo "$property_score"
}

# =============================================================================
# 13. ENVIRONMENT PARITY
# =============================================================================
# Tests that only pass locally are lies.
# =============================================================================

analyze_env_parity() {
    progress_step "Analyzing environment parity"
    
    local parity_score=7
    local conditional_skips=0
    local env_specific_tests=0
    local ci_local_drift=0
    
    local test_files
    test_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.test.js" -o -name "*.test.ts" -o -name "*.test.tsx" -o \
        -name "*.spec.js" -o -name "*.spec.ts" -o -name "*.spec.tsx" -o \
        -name "test_*.py" -o -name "*_test.py" \
        \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null || true)
    
    if [ -n "$test_files" ]; then
        # Count conditional skips
        conditional_skips=$(grep -rE "(\.skip\(|@skip|skipIf|xdescribe|xit|@pytest\.mark\.skip)" $test_files 2>/dev/null | wc -l)
        
        # Count environment-specific tests
        env_specific_tests=$(grep -rE "(process\.env\.|os\.environ|CI=|GITHUB_ACTIONS)" $test_files 2>/dev/null | wc -l)
    fi
    
    # Check for CI vs local config differences
    if [ -f "$CODEBASE_PATH/.github/workflows/"*".yml" ]; then
        # Check if CI uses different test command
        if grep -qE "npm run test:ci|yarn test:ci|--ci" "$CODEBASE_PATH/.github/workflows/"* 2>/dev/null; then
            ci_local_drift=$((ci_local_drift + 1))
        fi
    fi
    
    log_elite_metric "conditional_skip_count" "$conditional_skips"
    log_elite_metric "env_specific_test_count" "$env_specific_tests"
    log_elite_metric "ci_local_drift_indicators" "$ci_local_drift"
    
    # Score based on environment parity
    if [ "$conditional_skips" -gt 20 ]; then
        add_finding "high" "env_parity" "Many conditional test skips ($conditional_skips) - tests not reliable across environments"
        parity_score=$((parity_score - 3))
        adjust_trust_multiplier 0.85
    elif [ "$conditional_skips" -gt 10 ]; then
        add_finding "medium" "env_parity" "Moderate conditional test skips ($conditional_skips)"
        parity_score=$((parity_score - 1))
    fi
    
    if [ "$env_specific_tests" -gt 10 ]; then
        add_finding "medium" "env_parity" "Many environment-specific tests - may behave differently in CI"
        parity_score=$((parity_score - 1))
    fi
    
    [ "$parity_score" -lt 1 ] && parity_score=1
    [ "$parity_score" -gt 10 ] && parity_score=10
    
    log_elite_metric "env_parity_score" "$parity_score"
    echo "$parity_score"
}

# =============================================================================
# 14. BASE COVERAGE ANALYSIS (Enhanced)
# =============================================================================
# Traditional coverage metrics with enhanced detection
# =============================================================================

analyze_coverage() {
    progress_step "Analyzing test coverage"

    local coverage_score=5
    local line_coverage=0
    local branch_coverage=0

    # Use enhanced analyzer if available
    if type analyze_test_coverage &>/dev/null; then
        local enhanced_results
        enhanced_results=$(analyze_test_coverage "$CODEBASE_PATH" "$RESULTS_DIR")
        
        if [ -n "$enhanced_results" ]; then
            line_coverage=$(echo "$enhanced_results" | jq -r '.coverage_percent // 0')
            local test_ratio=$(echo "$enhanced_results" | jq -r '.test_ratio // 0')
            local test_quality=$(echo "$enhanced_results" | jq -r '.test_quality_score // 5')
            local framework_score=$(echo "$enhanced_results" | jq -r '.framework_score // 5')
            
            log_metric "test_count" "$(echo "$enhanced_results" | jq -r '.test_count // 0')"
            log_metric "source_count" "$(echo "$enhanced_results" | jq -r '.source_count // 0')"
            log_metric "test_ratio" "$test_ratio"
            log_metric "test_quality_score" "$test_quality"
            log_metric "framework_score" "$framework_score"
            
            if [ "$line_coverage" -gt 0 ]; then
                coverage_score=$(echo "$enhanced_results" | jq -r '.overall_score // 5' | cut -d. -f1)
            fi
        fi
    fi

    # JavaScript/TypeScript coverage detection
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        cd "$CODEBASE_PATH"

        local has_jest=false
        local has_vitest=false
        local has_mocha=false

        if grep -q '"jest"' package.json 2>/dev/null; then
            has_jest=true
            log_metric "test_framework" "jest"
        fi
        if grep -q '"vitest"' package.json 2>/dev/null; then
            has_vitest=true
            log_metric "test_framework" "vitest"
        fi
        if grep -q '"mocha"' package.json 2>/dev/null; then
            has_mocha=true
            log_metric "test_framework" "mocha"
        fi

        # Check multiple coverage report locations
        local coverage_found=false
        
        # Standard Jest/Vitest coverage locations
        for cov_file in "coverage/coverage-summary.json" "coverage/coverage-final.json" \
                        ".nyc_output/coverage-summary.json" "coverage-summary.json"; do
            if [ -f "$cov_file" ]; then
                line_coverage=$(jq '.total.lines.pct // 0' "$cov_file" 2>/dev/null || echo "0")
                branch_coverage=$(jq '.total.branches.pct // 0' "$cov_file" 2>/dev/null || echo "0")
                coverage_found=true
                echo "    Found coverage report: $cov_file (Lines=$line_coverage%, Branches=$branch_coverage%)" >&2
                break
            fi
        done
        
        # LCOV format
        if [ "$coverage_found" = false ]; then
            for lcov_file in "coverage/lcov.info" "lcov.info" ".coverage/lcov.info"; do
                if [ -f "$lcov_file" ]; then
                    line_coverage=$(parse_lcov_coverage "$lcov_file")
                    coverage_found=true
                    echo "    Found LCOV coverage: $lcov_file (Lines=$line_coverage%)" >&2
                    break
                fi
            done
        fi
        
        log_metric "line_coverage" "$line_coverage"
        log_metric "branch_coverage" "$branch_coverage"

        # Check coverage configuration
        if [ "$line_coverage" -eq 0 ]; then
            if grep -qE '"(nyc|c8|coverage)"' package.json 2>/dev/null || \
               grep -q '"collectCoverage"' package.json 2>/dev/null; then
                log_metric "coverage_configured" "true"
                add_finding "medium" "coverage" "Coverage configured but no report found - run tests with coverage"
            else
                log_metric "coverage_configured" "false"
                add_finding "high" "coverage" "No coverage configuration found" "$CODEBASE_PATH/package.json"
            fi
        fi
    fi

    # Python coverage detection
    if [ -f "$CODEBASE_PATH/requirements.txt" ] || [ -f "$CODEBASE_PATH/pyproject.toml" ]; then
        cd "$CODEBASE_PATH"

        if grep -qE "(pytest-cov|coverage)" requirements.txt pyproject.toml 2>/dev/null; then
            log_metric "python_coverage_configured" "true"
        fi

        # Check multiple Python coverage locations
        for py_cov in "coverage.xml" ".coverage.xml" "htmlcov/coverage.xml"; do
            if [ -f "$py_cov" ]; then
                local xml_coverage
                xml_coverage=$(parse_coverage_xml "$py_cov")
                log_metric "python_line_coverage" "$xml_coverage"
                [ "$xml_coverage" -gt "$line_coverage" ] && line_coverage=$xml_coverage
                break
            fi
        done

        if [ -f ".coverage" ] && command -v coverage &> /dev/null; then
            local py_coverage
            py_coverage=$(coverage report 2>/dev/null | tail -1 | awk '{print $NF}' | tr -d '%' || echo "0")
            log_metric "python_line_coverage" "$py_coverage"
            [ "$py_coverage" -gt "$line_coverage" ] && line_coverage=$py_coverage
        fi
    fi

    # Calculate coverage score
    if [ "$line_coverage" -ge 90 ]; then
        coverage_score=10
    elif [ "$line_coverage" -ge 80 ]; then
        coverage_score=9
    elif [ "$line_coverage" -ge 70 ]; then
        coverage_score=7
    elif [ "$line_coverage" -ge 60 ]; then
        coverage_score=6
    elif [ "$line_coverage" -ge 50 ]; then
        coverage_score=5
    elif [ "$line_coverage" -ge 30 ]; then
        coverage_score=4
        add_finding "high" "coverage" "Test coverage below 50% ($line_coverage%)"
    else
        coverage_score=2
        add_finding "critical" "coverage" "Test coverage critically low ($line_coverage%)"
        adjust_risk_multiplier 0.7
    fi

    log_metric "final_line_coverage" "$line_coverage"
    log_metric "coverage_score" "$coverage_score"
    echo "$coverage_score"
}

# =============================================================================
# 15. TEST QUALITY ANALYSIS (Enhanced)
# =============================================================================

analyze_test_quality() {
    progress_step "Analyzing test quality"

    local quality_score=5
    local test_file_count=0
    local source_file_count=0

    # JavaScript/TypeScript
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        test_file_count=$(find "$CODEBASE_PATH" -type f \( -name "*.test.js" -o -name "*.test.ts" -o -name "*.spec.js" -o -name "*.spec.ts" \) \
            -not -path "*/node_modules/*" 2>/dev/null | wc -l)

        source_file_count=$(find "$CODEBASE_PATH" -type f \( -name "*.js" -o -name "*.ts" \) \
            -not -path "*/node_modules/*" -not -name "*.test.*" -not -name "*.spec.*" -not -name "*.d.ts" 2>/dev/null | wc -l)
    fi

    # Python
    if ls "$CODEBASE_PATH"/*.py "$CODEBASE_PATH"/**/*.py 2>/dev/null | head -1 > /dev/null; then
        local py_test_count
        py_test_count=$(find "$CODEBASE_PATH" -type f \( -name "test_*.py" -o -name "*_test.py" \) \
            -not -path "*/.venv/*" -not -path "*/venv/*" 2>/dev/null | wc -l)
        test_file_count=$((test_file_count + py_test_count))

        local py_source_count
        py_source_count=$(find "$CODEBASE_PATH" -type f -name "*.py" -not -name "test_*" -not -name "*_test.py" \
            -not -path "*/.venv/*" -not -path "*/venv/*" 2>/dev/null | wc -l)
        source_file_count=$((source_file_count + py_source_count))
    fi

    log_metric "test_file_count" "$test_file_count"
    log_metric "source_file_count" "$source_file_count"

    # Calculate test-to-source ratio
    if [ "$source_file_count" -gt 0 ]; then
        local test_ratio
        test_ratio=$(math_calc "$test_file_count / $source_file_count")
        log_metric "test_to_source_ratio" "$test_ratio"

        if math_compare "$test_ratio" ">=" "0.8"; then
            quality_score=10
        elif math_compare "$test_ratio" ">=" "0.5"; then
            quality_score=8
        elif math_compare "$test_ratio" ">=" "0.3"; then
            quality_score=6
        elif math_compare "$test_ratio" ">=" "0.1"; then
            quality_score=4
        else
            quality_score=2
            add_finding "high" "test_quality" "Very low test-to-source file ratio ($test_ratio)"
        fi
    fi

    log_metric "quality_score" "$quality_score"
    echo "$quality_score"
}

# =============================================================================
# 16. TEST INFRASTRUCTURE ANALYSIS (Enhanced)
# =============================================================================

analyze_test_infrastructure() {
    progress_step "Analyzing test infrastructure"

    local infra_score=5

    if [ -f "$CODEBASE_PATH/package.json" ]; then
        cd "$CODEBASE_PATH"

        # Check for mocking libraries
        if grep -qE '"(jest|@testing-library|sinon|nock|msw)"' package.json 2>/dev/null; then
            log_metric "mocking_library" "true"
            infra_score=$((infra_score + 1))
        fi

        # Check for testing-library
        if grep -q '"@testing-library"' package.json 2>/dev/null; then
            log_metric "testing_library" "true"
            infra_score=$((infra_score + 1))
        fi

        # Check for E2E testing
        if grep -qE '"(cypress|playwright|puppeteer)"' package.json 2>/dev/null; then
            log_metric "e2e_testing" "true"
            infra_score=$((infra_score + 2))
        else
            log_metric "e2e_testing" "false"
            add_finding "medium" "test_infrastructure" "No E2E testing framework found"
        fi
    fi

    # Check for fixtures/factories
    if [ -d "$CODEBASE_PATH/tests/fixtures" ] || [ -d "$CODEBASE_PATH/__fixtures__" ] || \
       [ -d "$CODEBASE_PATH/test/fixtures" ]; then
        log_metric "test_fixtures" "true"
        infra_score=$((infra_score + 1))
    fi

    # Check for CI test configuration
    local has_ci_tests=false
    if [ -d "$CODEBASE_PATH/.github/workflows" ]; then
        if grep -rqE "(npm test|yarn test|pnpm test|pytest|go test)" "$CODEBASE_PATH/.github/workflows/"* 2>/dev/null; then
            has_ci_tests=true
            log_metric "ci_tests_configured" "true"
            infra_score=$((infra_score + 1))
        fi
    fi

    if [ "$has_ci_tests" = false ]; then
        add_finding "high" "test_infrastructure" "No CI test configuration found"
    fi

    [ "$infra_score" -gt 10 ] && infra_score=10
    log_metric "infrastructure_score" "$infra_score"
    echo "$infra_score"
}

# =============================================================================
# CALCULATE TEST TRUST SCORE
# =============================================================================
# The ultimate metric: How confident should I be changing this code today?
# =============================================================================

calculate_test_trust_score() {
    local base_score="$1"
    
    # Apply confidence multipliers
    local final_score
    final_score=$(math_calc "$base_score * $TRUST_MULTIPLIER * $SIGNAL_MULTIPLIER * $RISK_ALIGNMENT_MULTIPLIER")

    # Cap at 10
    if math_compare "$final_score" ">" "10"; then
        final_score=10
    fi
    
    log_elite_metric "base_score" "$base_score"
    log_elite_metric "trust_multiplier_final" "$TRUST_MULTIPLIER"
    log_elite_metric "signal_multiplier_final" "$SIGNAL_MULTIPLIER"
    log_elite_metric "risk_alignment_multiplier_final" "$RISK_ALIGNMENT_MULTIPLIER"
    log_elite_metric "test_trust_score" "$final_score"
    
    echo "$final_score"
}

# =============================================================================
# MAIN EXECUTION - ELITE WORLD-CLASS TESTING AUDIT
# =============================================================================

main() {
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║     ELITE TESTING EVALUATION - World-Class Analysis                ║"
    echo "║     Philosophy: Signal > Coverage | Confidence > Counts            ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Codebase: $CODEBASE_PATH"
    echo ""

    # =========================================================================
    # ELITE DIMENSION ANALYSIS
    # =========================================================================
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  PHASE 1: Trust & Signal Analysis"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local flakiness_score
    flakiness_score=$(analyze_flakiness)
    echo "    ✓ Flakiness & Trustworthiness: $flakiness_score/10" >&2
    
    local assertion_score
    assertion_score=$(analyze_assertion_quality)
    echo "    ✓ Assertion Quality: $assertion_score/10" >&2
    
    local intent_score
    intent_score=$(analyze_test_intent)
    echo "    ✓ Test Intent & Readability: $intent_score/10" >&2
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  PHASE 2: Depth & Truth Analysis"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local mutation_score
    mutation_score=$(analyze_mutation_testing)
    echo "    ✓ Mutation Testing: $mutation_score/10" >&2
    
    local isolation_score
    isolation_score=$(analyze_isolation)
    echo "    ✓ Isolation & Determinism: $isolation_score/10" >&2
    
    local mocking_score
    mocking_score=$(analyze_mocking_quality)
    echo "    ✓ Mocking Strategy: $mocking_score/10" >&2
    
    local pyramid_score
    pyramid_score=$(analyze_test_pyramid)
    echo "    ✓ Test Pyramid Balance: $pyramid_score/10" >&2
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  PHASE 3: Elite Differentiators"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local diagnostics_score
    diagnostics_score=$(analyze_failure_diagnostics)
    echo "    ✓ Failure Diagnostics: $diagnostics_score/10" >&2
    
    local regression_score
    regression_score=$(analyze_regression_intent)
    echo "    ✓ Regression Intent: $regression_score/10" >&2
    
    local performance_score
    performance_score=$(analyze_test_performance)
    echo "    ✓ Test Performance: $performance_score/10" >&2
    
    local risk_coverage_score
    risk_coverage_score=$(analyze_risk_weighted_coverage)
    echo "    ✓ Risk-Weighted Coverage: $risk_coverage_score/10" >&2
    
    local property_score
    property_score=$(analyze_property_testing)
    echo "    ✓ Property/Fuzz Testing: $property_score/10" >&2
    
    local env_parity_score
    env_parity_score=$(analyze_env_parity)
    echo "    ✓ Environment Parity: $env_parity_score/10" >&2
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  PHASE 4: Traditional Metrics (Enhanced)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local coverage_score
    coverage_score=$(analyze_coverage)
    echo "    ✓ Base Coverage: $coverage_score/10" >&2
    
    local quality_score
    quality_score=$(analyze_test_quality)
    echo "    ✓ Test Quality: $quality_score/10" >&2
    
    local infra_score
    infra_score=$(analyze_test_infrastructure)
    echo "    ✓ Infrastructure: $infra_score/10" >&2

    # =========================================================================
    # CALCULATE WEIGHTED SCORE
    # =========================================================================
    # Elite weighting prioritizes trust and signal over raw coverage
    #
    # Trust & Signal (40%):
    #   - Flakiness: 10%
    #   - Assertion Quality: 12%
    #   - Test Intent: 8%
    #   - Isolation: 10%
    #
    # Depth & Truth (30%):
    #   - Mutation Testing: 8%
    #   - Mocking Quality: 7%
    #   - Test Pyramid: 8%
    #   - Risk Coverage: 7%
    #
    # Traditional + Elite (30%):
    #   - Base Coverage: 10%
    #   - Quality: 5%
    #   - Infrastructure: 5%
    #   - Diagnostics: 3%
    #   - Performance: 3%
    #   - Property Testing: 2%
    #   - Env Parity: 2%
    # =========================================================================
    
    local base_score
    base_score=$(math_calc "($flakiness_score * 0.10) + ($assertion_score * 0.12) + ($intent_score * 0.08) + ($isolation_score * 0.10) + ($mutation_score * 0.08) + ($mocking_score * 0.07) + ($pyramid_score * 0.08) + ($risk_coverage_score * 0.07) + ($coverage_score * 0.10) + ($quality_score * 0.05) + ($infra_score * 0.05) + ($diagnostics_score * 0.03) + ($performance_score * 0.03) + ($property_score * 0.02) + ($env_parity_score * 0.02)")
    
    # Apply confidence multipliers for final trust score
    local final_score
    final_score=$(calculate_test_trust_score "$base_score")

    # =========================================================================
    # UPDATE RESULTS
    # =========================================================================
    
    RESULTS=$(echo "$RESULTS" | jq \
        --arg score "$final_score" \
        --arg base "$base_score" \
        --arg trust "$TRUST_MULTIPLIER" \
        --arg signal "$SIGNAL_MULTIPLIER" \
        --arg risk "$RISK_ALIGNMENT_MULTIPLIER" \
        '.score = ($score | tonumber) |
         .confidence_score = ($score | tonumber) |
         .base_score = ($base | tonumber) |
         .trust_multiplier = ($trust | tonumber) |
         .signal_multiplier = ($signal | tonumber) |
         .risk_alignment_multiplier = ($risk | tonumber)')
    
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 57')

    # Add comprehensive subscores
    RESULTS=$(echo "$RESULTS" | jq \
        --arg flakiness "$flakiness_score" \
        --arg assertion "$assertion_score" \
        --arg intent "$intent_score" \
        --arg mutation "$mutation_score" \
        --arg isolation "$isolation_score" \
        --arg mocking "$mocking_score" \
        --arg pyramid "$pyramid_score" \
        --arg diagnostics "$diagnostics_score" \
        --arg regression "$regression_score" \
        --arg performance "$performance_score" \
        --arg risk_coverage "$risk_coverage_score" \
        --arg property "$property_score" \
        --arg env_parity "$env_parity_score" \
        --arg coverage "$coverage_score" \
        --arg quality "$quality_score" \
        --arg infra "$infra_score" \
        '.subscores = {
            trust_signal: {
                flakiness: ($flakiness | tonumber),
                assertion_quality: ($assertion | tonumber),
                test_intent: ($intent | tonumber),
                isolation: ($isolation | tonumber)
            },
            depth_truth: {
                mutation_testing: ($mutation | tonumber),
                mocking_quality: ($mocking | tonumber),
                test_pyramid: ($pyramid | tonumber),
                risk_weighted_coverage: ($risk_coverage | tonumber)
            },
            elite_differentiators: {
                failure_diagnostics: ($diagnostics | tonumber),
                regression_intent: ($regression | tonumber),
                test_performance: ($performance | tonumber),
                property_testing: ($property | tonumber),
                env_parity: ($env_parity | tonumber)
            },
            traditional: {
                coverage: ($coverage | tonumber),
                quality: ($quality | tonumber),
                infrastructure: ($infra | tonumber)
            }
        }')

    # Merge findings
    RESULTS=$(merge_findings "$RESULTS")

    # Write output
    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"

    # =========================================================================
    # ELITE SUMMARY OUTPUT
    # =========================================================================
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                    ELITE TESTING EVALUATION RESULTS                ║"
    echo "╠════════════════════════════════════════════════════════════════════╣"
    printf "║  Base Score:              %5.2f/10                                ║\n" "$base_score"
    printf "║  Trust Multiplier:        ×%.2f                                   ║\n" "$TRUST_MULTIPLIER"
    printf "║  Signal Multiplier:       ×%.2f                                   ║\n" "$SIGNAL_MULTIPLIER"
    printf "║  Risk Alignment:          ×%.2f                                   ║\n" "$RISK_ALIGNMENT_MULTIPLIER"
    echo "╠════════════════════════════════════════════════════════════════════╣"
    printf "║  ★ CONFIDENCE SCORE:      %5.2f/10                                ║\n" "$final_score"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Key Question Answered:"
    echo "  \"How confident should I be changing this code today?\""
    echo ""
    
    if math_compare "$final_score" ">=" "8"; then
        echo "  → HIGH CONFIDENCE: Tests provide strong safety net"
    elif math_compare "$final_score" ">=" "6"; then
        echo "  → MODERATE CONFIDENCE: Tests are helpful but have gaps"
    elif math_compare "$final_score" ">=" "4"; then
        echo "  → LOW CONFIDENCE: Significant testing improvements needed"
    else
        echo "  → CRITICAL: Tests may not catch production issues"
    fi
    
    echo ""
    echo "Results saved to: $OUTPUT_FILE"
}

main
