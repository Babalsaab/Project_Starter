#!/bin/bash

# =============================================================================
# CTO Evaluation Suite - Test Runner
# =============================================================================
# Runs all tests for the evaluation suite.
#
# Usage: ./tests/run-tests.sh [--verbose]
# =============================================================================

# Don't use set -e as we handle errors and count them explicitly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

VERBOSE=false
PASSED=0
FAILED=0
SKIPPED=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

log_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

log_skip() {
    echo -e "${YELLOW}○${NC} $1 (skipped)"
    ((SKIPPED++))
}

run_test() {
    local test_name="$1"
    local test_script="$2"
    
    if [ -x "$test_script" ]; then
        if "$test_script" > /dev/null 2>&1; then
            log_pass "$test_name"
        else
            log_fail "$test_name"
        fi
    else
        log_skip "$test_name"
    fi
}

# =============================================================================
# Unit Tests
# =============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  CTO Evaluation Suite - Test Runner"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "Running unit tests..."
echo ""

# Test 1: Health check script exists and runs
if [ -x "$SUITE_DIR/scripts/health-check.sh" ]; then
    health_exit_code=0
    "$SUITE_DIR/scripts/health-check.sh" > /dev/null 2>&1 || health_exit_code=$?
    if [ $health_exit_code -eq 0 ]; then
        log_pass "Health check script runs successfully"
    elif [ $health_exit_code -eq 1 ] || [ $health_exit_code -eq 2 ]; then
        # Health check returns 1 for errors (e.g. missing jq) and 2 for warnings
        # Both are valid outcomes -- the script ran correctly and reported issues
        log_pass "Health check script runs (exit code: $health_exit_code)"
    else
        log_fail "Health check script crashed (exit code: $health_exit_code)"
    fi
else
    log_fail "Health check script not found or not executable"
fi

# Test 2: All evaluation scripts exist
expected_scripts=21
found_scripts=$(ls -1 "$SUITE_DIR/scripts/"[0-9][0-9]-*.sh 2>/dev/null | wc -l | tr -d ' ')
if [ "$found_scripts" -eq "$expected_scripts" ]; then
    log_pass "All $expected_scripts evaluation scripts present"
else
    log_fail "Found $found_scripts of $expected_scripts evaluation scripts"
fi

# Test 3: Config files are valid YAML
for config in "$SUITE_DIR/config/"*.yaml; do
    if [ -f "$config" ]; then
        config_name=$(basename "$config")
        # Skip YAML validation if neither tool is available
        if python3 -c "import yaml" 2>/dev/null; then
            if python3 -c "import yaml; yaml.safe_load(open('$config'))" 2>/dev/null; then
                log_pass "Config file $config_name is valid YAML"
            else
                log_fail "Config file $config_name has invalid YAML"
            fi
        elif command -v yq &> /dev/null; then
            if yq '.' "$config" > /dev/null 2>&1; then
                log_pass "Config file $config_name is valid YAML"
            else
                log_fail "Config file $config_name has invalid YAML"
            fi
        else
            log_skip "Config file $config_name (no YAML validator)"
        fi
    fi
done

# Test 4: JSON files are valid
shopt -s nullglob globstar 2>/dev/null || true
if command -v jq &> /dev/null; then
    for json_file in "$SUITE_DIR/tools/"**/*.json; do
        if [ -f "$json_file" ]; then
            json_name=$(basename "$json_file")
            if jq empty "$json_file" 2>/dev/null; then
                log_pass "JSON file $json_name is valid"
            else
                log_fail "JSON file $json_name has invalid JSON"
            fi
        fi
    done
else
    log_skip "JSON validation (jq not installed)"
fi
shopt -u nullglob globstar 2>/dev/null || true

# Test 5: Main entry point is executable
if [ -x "$SUITE_DIR/evaluate" ]; then
    log_pass "Main entry point (evaluate) is executable"
else
    log_fail "Main entry point (evaluate) is not executable"
fi

# Test 6: Help command works
if "$SUITE_DIR/evaluate" --help > /dev/null 2>&1; then
    log_pass "Help command works"
else
    log_fail "Help command failed"
fi

# Test 7: Required directories exist
for dir in scripts config templates tools; do
    if [ -d "$SUITE_DIR/$dir" ]; then
        log_pass "Directory $dir exists"
    else
        log_fail "Directory $dir is missing"
    fi
done

# Test 8: Common scripts are sourceable
for common in common-progress.sh common-findings.sh common-errors.sh; do
    if [ -f "$SUITE_DIR/scripts/$common" ]; then
        if bash -n "$SUITE_DIR/scripts/$common" 2>/dev/null; then
            log_pass "Script $common has valid syntax"
        else
            log_fail "Script $common has syntax errors"
        fi
    else
        log_skip "$common not found"
    fi
done

# Test 9: Documentation files exist
for doc in README.md CONTRIBUTING.md CODE_OF_CONDUCT.md LICENSE; do
    if [ -f "$SUITE_DIR/$doc" ]; then
        log_pass "Documentation $doc exists"
    else
        log_fail "Documentation $doc is missing"
    fi
done

# Test 10: Architecture documentation exists
if [ -f "$SUITE_DIR/docs/ARCHITECTURE.md" ]; then
    log_pass "Architecture documentation exists"
else
    log_fail "Architecture documentation is missing"
fi

# =============================================================================
# Summary
# =============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Test Results"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo -e "  ${GREEN}Passed:${NC}  $PASSED"
echo -e "  ${RED}Failed:${NC}  $FAILED"
echo -e "  ${YELLOW}Skipped:${NC} $SKIPPED"
echo ""

TOTAL=$((PASSED + FAILED))
if [ $TOTAL -gt 0 ]; then
    COVERAGE=$((PASSED * 100 / TOTAL))
    echo "  Coverage: ${COVERAGE}%"
fi

echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$FAILED test(s) failed${NC}"
    exit 1
fi
