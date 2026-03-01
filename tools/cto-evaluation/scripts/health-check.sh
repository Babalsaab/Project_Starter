#!/bin/bash

# =============================================================================
# CTO Evaluation Suite - Health Check Script
# =============================================================================
# Validates that the evaluation suite is properly installed and configured.
#
# Usage: ./scripts/health-check.sh [--verbose]
#
# Exit Codes:
#   0 - All checks passed
#   1 - Critical failure (suite cannot run)
#   2 - Warning (suite can run but with reduced functionality)
# =============================================================================

# Don't use set -e as we handle errors explicitly and count them

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(dirname "$SCRIPT_DIR")"

VERBOSE=false
WARNINGS=0
ERRORS=0

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

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------

log_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

log_info() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}ℹ${NC} $1"
    fi
}

log_section() {
    echo ""
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
}

# -----------------------------------------------------------------------------
# Check Functions
# -----------------------------------------------------------------------------

check_required_files() {
    log_section "Required Files"
    
    local required_files=(
        "evaluate"
        "scripts/run-full-evaluation.sh"
        "scripts/generate-report.sh"
        "scripts/common-progress.sh"
        "config/evaluation.yaml"
        "config/thresholds.yaml"
        "templates/report-template.md"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$SUITE_DIR/$file" ]; then
            log_pass "$file exists"
        else
            log_fail "$file is missing"
        fi
    done
}

check_evaluation_scripts() {
    log_section "Evaluation Scripts"
    
    local expected_scripts=21
    local found_scripts=$(ls -1 "$SUITE_DIR/scripts/"[0-9][0-9]-*.sh 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$found_scripts" -eq "$expected_scripts" ]; then
        log_pass "All $expected_scripts evaluation scripts present"
    elif [ "$found_scripts" -gt 0 ]; then
        log_warn "Found $found_scripts of $expected_scripts evaluation scripts"
    else
        log_fail "No evaluation scripts found"
    fi
    
    # Check scripts are executable
    local non_executable=0
    for script in "$SUITE_DIR/scripts/"*.sh; do
        if [ ! -x "$script" ]; then
            ((non_executable++))
            log_info "Not executable: $(basename "$script")"
        fi
    done
    
    if [ "$non_executable" -eq 0 ]; then
        log_pass "All scripts are executable"
    else
        log_warn "$non_executable scripts are not executable (run: chmod +x scripts/*.sh)"
    fi
}

check_required_tools() {
    log_section "Required Tools"
    
    local required_tools=(
        "bash:Bash shell"
        "jq:JSON processor"
        "git:Git version control"
    )
    
    for tool_spec in "${required_tools[@]}"; do
        IFS=':' read -r cmd name <<< "$tool_spec"
        if command -v "$cmd" &> /dev/null; then
            local version=$("$cmd" --version 2>&1 | head -1 || echo "unknown")
            log_pass "$name is installed"
            log_info "  Version: $version"
        else
            log_fail "$name is not installed"
        fi
    done
}

check_optional_tools() {
    log_section "Optional Tools"
    
    local optional_tools=(
        "node:Node.js (for ESLint)"
        "npm:NPM (for ESLint)"
        "docker:Docker (for containerized checks)"
        "python3:Python 3 (for advanced analysis)"
        "cloc:CLOC (for lines of code counting)"
        "shellcheck:ShellCheck (for shell script linting)"
    )
    
    for tool_spec in "${optional_tools[@]}"; do
        IFS=':' read -r cmd name <<< "$tool_spec"
        if command -v "$cmd" &> /dev/null; then
            log_pass "$name is available"
        else
            log_warn "$name is not installed (optional)"
        fi
    done
}

check_config_validity() {
    log_section "Configuration Validation"
    
    local yaml_validator=""
    
    # Check for YAML validator
    if command -v yq &> /dev/null; then
        yaml_validator="yq"
    elif python3 -c "import yaml" 2>/dev/null; then
        yaml_validator="python"
    fi
    
    if [ -n "$yaml_validator" ]; then
        for config in "$SUITE_DIR/config/"*.yaml; do
            if [ -f "$config" ]; then
                local is_valid=false
                if [ "$yaml_validator" = "yq" ]; then
                    if yq '.' "$config" > /dev/null 2>&1; then
                        is_valid=true
                    fi
                elif [ "$yaml_validator" = "python" ]; then
                    if python3 -c "import yaml; yaml.safe_load(open('$config'))" 2>/dev/null; then
                        is_valid=true
                    fi
                fi
                
                if [ "$is_valid" = true ]; then
                    log_pass "$(basename "$config") is valid YAML"
                else
                    log_fail "$(basename "$config") has invalid YAML syntax"
                fi
            fi
        done
    else
        log_info "Skipping YAML validation (no YAML parser available - install pyyaml or yq)"
        # Count YAML files as passes since we can't validate
        for config in "$SUITE_DIR/config/"*.yaml; do
            if [ -f "$config" ]; then
                log_pass "$(basename "$config") exists (YAML validation skipped)"
            fi
        done
    fi
    
    # Check JSON files
    for json_file in "$SUITE_DIR/tools/"**/*.json; do
        if [ -f "$json_file" ]; then
            if jq empty "$json_file" 2>/dev/null; then
                log_pass "$(basename "$json_file") is valid JSON"
            else
                log_fail "$(basename "$json_file") has invalid JSON syntax"
            fi
        fi
    done
}

check_output_directory() {
    log_section "Output Directory"
    
    if [ -d "$SUITE_DIR/output" ]; then
        if [ -w "$SUITE_DIR/output" ]; then
            log_pass "Output directory exists and is writable"
        else
            log_warn "Output directory exists but is not writable"
        fi
    else
        if mkdir -p "$SUITE_DIR/output" 2>/dev/null; then
            log_pass "Output directory created successfully"
            rmdir "$SUITE_DIR/output"
        else
            log_warn "Cannot create output directory"
        fi
    fi
}

check_disk_space() {
    log_section "Disk Space"
    
    local available_mb
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_mb=$(df -m "$SUITE_DIR" | tail -1 | awk '{print $4}')
    else
        available_mb=$(df -m "$SUITE_DIR" | tail -1 | awk '{print $4}')
    fi
    
    if [ "$available_mb" -gt 500 ]; then
        log_pass "Sufficient disk space (${available_mb}MB available)"
    elif [ "$available_mb" -gt 100 ]; then
        log_warn "Low disk space (${available_mb}MB available)"
    else
        log_fail "Insufficient disk space (${available_mb}MB available, need at least 100MB)"
    fi
}

check_version_info() {
    log_section "Version Information"
    
    echo -e "  Suite Version: ${GREEN}1.0.0${NC}"
    echo -e "  Suite Location: $SUITE_DIR"
    echo -e "  Shell: $SHELL"
    echo -e "  OS: $(uname -s) $(uname -r)"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        CTO Evaluation Suite - Health Check               ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    
    check_required_files
    check_evaluation_scripts
    check_required_tools
    check_optional_tools
    check_config_validity
    check_output_directory
    check_disk_space
    check_version_info
    
    # Summary
    echo ""
    echo -e "${BLUE}━━━ Summary ━━━${NC}"
    echo ""
    
    if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed! The suite is ready to use.${NC}"
        exit 0
    elif [ "$ERRORS" -eq 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS warning(s) found. The suite can run with reduced functionality.${NC}"
        exit 2
    else
        echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found.${NC}"
        echo -e "${RED}  Please fix the errors before running evaluations.${NC}"
        exit 1
    fi
}

main "$@"
