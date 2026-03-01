#!/bin/bash

# =============================================================================
# CTO CODEBASE EVALUATION SUITE - Master Orchestration Script
# =============================================================================
# Usage: ./run-full-evaluation.sh /path/to/codebase [options]
#
# Options:
#   --skip-security     Skip security scanning
#   --skip-performance  Skip performance testing
#   --quick             Run quick evaluation (subset of checks)
#   --output-dir DIR    Custom output directory
#   --format FORMAT     Output format (json|markdown|html|all)
#   --verbose           Verbose output
#   --help              Show this help message
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$SUITE_DIR/config"
TOOLS_DIR="$SUITE_DIR/tools"
TEMPLATES_DIR="$SUITE_DIR/templates"

# Source config-reader for category weights (single source of truth)
source "$SCRIPT_DIR/lib/config-reader.sh"

# Default settings
OUTPUT_DIR="$SUITE_DIR/output"
OUTPUT_FORMAT="all"
VERBOSE=false
QUICK_MODE=false
SKIP_SECURITY=false
SKIP_PERFORMANCE=false
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

source "$SCRIPT_DIR/lib/banner.sh"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

show_help() {
    echo "Usage: $0 /path/to/codebase [options]"
    echo ""
    echo "Options:"
    echo "  --skip-security     Skip security scanning"
    echo "  --skip-performance  Skip performance testing"
    echo "  --quick             Run quick evaluation (subset of checks)"
    echo "  --output-dir DIR    Custom output directory"
    echo "  --format FORMAT     Output format (json|markdown|html|all)"
    echo "  --verbose           Verbose output"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/project"
    echo "  $0 /path/to/project --quick --format markdown"
    echo "  $0 /path/to/project --skip-security --output-dir ./reports"
}

check_dependencies() {
    log_section "Checking Dependencies"

    local missing_deps=()

    # Required tools
    local required_tools=(
        "node:Node.js"
        "npm:NPM"
        "jq:jq (JSON processor)"
        "git:Git"
    )

    # Optional but recommended tools
    local optional_tools=(
        "docker:Docker"
        "python3:Python 3"
        "go:Go"
    )

    for tool_spec in "${required_tools[@]}"; do
        IFS=':' read -r tool name <<< "$tool_spec"
        if ! command -v "$tool" &> /dev/null; then
            missing_deps+=("$name")
            log_error "$name is required but not installed"
        else
            log_success "$name found"
        fi
    done

    for tool_spec in "${optional_tools[@]}"; do
        IFS=':' read -r tool name <<< "$tool_spec"
        if ! command -v "$tool" &> /dev/null; then
            log_warning "$name not found (optional)"
        else
            log_success "$name found"
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

detect_languages() {
    log_section "Detecting Languages & Frameworks"

    local codebase_path="$1"
    
    # Use simple variables instead of associative arrays for compatibility
    LANG_JAVASCRIPT=""
    LANG_PYTHON=""
    LANG_GO=""
    LANG_JAVA=""
    LANG_RUBY=""
    LANG_RUST=""
    FRAMEWORK_LIST=""

    # JavaScript/TypeScript
    if find "$codebase_path" -maxdepth 3 -type f \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) 2>/dev/null | head -1 | grep -q .; then
        LANG_JAVASCRIPT="true"
        log_info "Detected: JavaScript/TypeScript"

        # Check for frameworks
        if [ -f "$codebase_path/package.json" ]; then
            if grep -q '"react"' "$codebase_path/package.json" 2>/dev/null; then
                FRAMEWORK_LIST="$FRAMEWORK_LIST react"
                log_info "  Framework: React"
            fi
            if grep -q '"vue"' "$codebase_path/package.json" 2>/dev/null; then
                FRAMEWORK_LIST="$FRAMEWORK_LIST vue"
                log_info "  Framework: Vue"
            fi
            if grep -q '"@angular/core"' "$codebase_path/package.json" 2>/dev/null; then
                FRAMEWORK_LIST="$FRAMEWORK_LIST angular"
                log_info "  Framework: Angular"
            fi
            if grep -q '"next"' "$codebase_path/package.json" 2>/dev/null; then
                FRAMEWORK_LIST="$FRAMEWORK_LIST nextjs"
                log_info "  Framework: Next.js"
            fi
            if grep -q '"express"' "$codebase_path/package.json" 2>/dev/null; then
                FRAMEWORK_LIST="$FRAMEWORK_LIST express"
                log_info "  Framework: Express"
            fi
            if grep -q '"@nestjs/core"' "$codebase_path/package.json" 2>/dev/null; then
                FRAMEWORK_LIST="$FRAMEWORK_LIST nestjs"
                log_info "  Framework: NestJS"
            fi
        fi
    fi

    # Python
    if find "$codebase_path" -maxdepth 3 -type f -name "*.py" 2>/dev/null | head -1 | grep -q .; then
        LANG_PYTHON="true"
        log_info "Detected: Python"

        if [ -f "$codebase_path/requirements.txt" ] || [ -f "$codebase_path/pyproject.toml" ]; then
            if grep -qi "django" "$codebase_path/requirements.txt" 2>/dev/null || \
               grep -qi "django" "$codebase_path/pyproject.toml" 2>/dev/null; then
                FRAMEWORK_LIST="$FRAMEWORK_LIST django"
                log_info "  Framework: Django"
            fi
            if grep -qi "fastapi" "$codebase_path/requirements.txt" 2>/dev/null || \
               grep -qi "fastapi" "$codebase_path/pyproject.toml" 2>/dev/null; then
                FRAMEWORK_LIST="$FRAMEWORK_LIST fastapi"
                log_info "  Framework: FastAPI"
            fi
            if grep -qi "flask" "$codebase_path/requirements.txt" 2>/dev/null || \
               grep -qi "flask" "$codebase_path/pyproject.toml" 2>/dev/null; then
                FRAMEWORK_LIST="$FRAMEWORK_LIST flask"
                log_info "  Framework: Flask"
            fi
        fi
    fi

    # Go
    if find "$codebase_path" -maxdepth 3 -type f -name "*.go" 2>/dev/null | head -1 | grep -q .; then
        LANG_GO="true"
        log_info "Detected: Go"
    fi

    # Java
    if find "$codebase_path" -maxdepth 3 -type f -name "*.java" 2>/dev/null | head -1 | grep -q .; then
        LANG_JAVA="true"
        log_info "Detected: Java"
    fi

    # Ruby
    if find "$codebase_path" -maxdepth 3 -type f -name "*.rb" 2>/dev/null | head -1 | grep -q .; then
        LANG_RUBY="true"
        log_info "Detected: Ruby"
    fi

    # Rust
    if find "$codebase_path" -maxdepth 3 -type f -name "*.rs" 2>/dev/null | head -1 | grep -q .; then
        LANG_RUST="true"
        log_info "Detected: Rust"
    fi
    
    # Check if any language was detected
    if [ -z "$LANG_JAVASCRIPT" ] && [ -z "$LANG_PYTHON" ] && [ -z "$LANG_GO" ] && \
       [ -z "$LANG_JAVA" ] && [ -z "$LANG_RUBY" ] && [ -z "$LANG_RUST" ]; then
        log_warning "No common programming languages detected"
    fi
}

count_lines_of_code() {
    local codebase_path="$1"
    
    # Progress messages go to stderr so they don't interfere with the returned value
    echo -e "${BLUE}[INFO]${NC} Counting lines of code..." >&2
    
    # Count files first
    local file_count=0
    local total_lines=0
    local extensions=("js" "ts" "jsx" "tsx" "py" "go" "java" "rb" "rs" "php" "cs" "cpp" "c" "swift" "kt")
    
    for ext in "${extensions[@]}"; do
        local count=$(find "$codebase_path" -type f -name "*.$ext" \
            -not -path "*/node_modules/*" \
            -not -path "*/.git/*" \
            -not -path "*/vendor/*" \
            -not -path "*/dist/*" \
            -not -path "*/build/*" \
            2>/dev/null | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ]; then
            printf "\r\033[K  ${BLUE}→${NC} Found ${CYAN}%d${NC} .%s files" "$count" "$ext" >&2
            file_count=$((file_count + count))
        fi
    done
    
    printf "\r\033[K  ${BLUE}→${NC} Total: ${CYAN}%d${NC} source files found\n" "$file_count" >&2
    
    if command -v cloc &> /dev/null; then
        echo -e "${BLUE}[INFO]${NC} Running cloc analysis..." >&2
        cloc --json "$codebase_path" --exclude-dir=node_modules,.git,vendor,dist,build 2>/dev/null | jq '.SUM.code // 0'
    else
        # Fallback: simple line count with progress
        echo -e "${BLUE}[INFO]${NC} Counting lines (cloc not installed, using fallback)..." >&2
        local counted=0
        while IFS= read -r -d '' file; do
            lines=$(wc -l < "$file" 2>/dev/null || echo 0)
            total_lines=$((total_lines + lines))
            counted=$((counted + 1))
            if [ $((counted % 100)) -eq 0 ]; then
                printf "\r\033[K  ${BLUE}→${NC} Processed ${CYAN}%d${NC} files (%d lines so far)" "$counted" "$total_lines" >&2
            fi
        done < <(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.java" -o -name "*.rb" -o -name "*.rs" \) \
            -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/vendor/*" -print0 2>/dev/null)
        printf "\r\033[K" >&2
        echo "$total_lines"
    fi
}

# Get elapsed time formatted
format_duration() {
    local seconds="$1"
    if [ "$seconds" -lt 60 ]; then
        echo "${seconds}s"
    elif [ "$seconds" -lt 3600 ]; then
        echo "$((seconds / 60))m $((seconds % 60))s"
    else
        echo "$((seconds / 3600))h $(((seconds % 3600) / 60))m"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_banner

    # Parse arguments
    if [ $# -lt 1 ]; then
        show_help
        exit 1
    fi

    CODEBASE_PATH="$1"
    shift

    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-security)
                SKIP_SECURITY=true
                shift
                ;;
            --skip-performance)
                SKIP_PERFORMANCE=true
                shift
                ;;
            --quick)
                QUICK_MODE=true
                shift
                ;;
            --output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validate codebase path
    if [ ! -d "$CODEBASE_PATH" ]; then
        log_error "Codebase path does not exist: $CODEBASE_PATH"
        exit 1
    fi

    CODEBASE_PATH="$(cd "$CODEBASE_PATH" && pwd)"

    # Validate path doesn't contain control characters
    if [[ "$CODEBASE_PATH" =~ [[:cntrl:]] ]]; then
        log_error "Codebase path contains control characters"
        exit 1
    fi

    log_info "Evaluating codebase: $CODEBASE_PATH"

    # Create output directory
    RESULTS_DIR="$OUTPUT_DIR/evaluation_$TIMESTAMP"
    mkdir -p "$RESULTS_DIR"
    log_info "Results directory: $RESULTS_DIR"

    # Check dependencies
    check_dependencies

    # Detect languages and frameworks
    detect_languages "$CODEBASE_PATH"

    # Count LOC
    log_section "Codebase Statistics"
    LOC=$(count_lines_of_code "$CODEBASE_PATH")
    log_info "Lines of Code: $LOC"

    # Initialize results
    RESULTS="{}"
    RESULTS=$(echo "$RESULTS" | jq --arg path "$CODEBASE_PATH" --arg ts "$TIMESTAMP" --arg loc "$LOC" \
        '.metadata = {codebase: $path, timestamp: $ts, lines_of_code: ($loc | tonumber)}')

    # ==========================================================================
    # RUN EVALUATIONS
    # ==========================================================================

    # Category format: "script:name"
    # Weights are fetched at runtime from config/evaluation.yaml via config-reader.sh
    # All 21 categories from the 495-parameter framework
    CATEGORIES="01-code-quality.sh:Code Quality
02-architecture.sh:Architecture
03-security.sh:Security
04-performance.sh:Performance
05-testing.sh:Testing
06-devops.sh:DevOps
07-scalability.sh:Scalability
08-reliability.sh:Reliability
09-data.sh:Data Architecture
10-api.sh:API Design
11-observability.sh:Observability
12-frontend.sh:Frontend
13-backend.sh:Backend
14-mobile.sh:Mobile
15-documentation.sh:Documentation
16-developer-experience.sh:Developer Experience
17-maintainability.sh:Maintainability
18-compliance.sh:Compliance
19-cost-efficiency.sh:Cost Efficiency
20-innovation.sh:Innovation
21-uiux-audit.sh:UI/UX Consistency"

    # Store scores in a temp file for compatibility
    SCORES_FILE="$RESULTS_DIR/.scores.tmp"
    echo "" > "$SCORES_FILE"

    # Maximum parallel jobs (configurable via environment)
    MAX_PARALLEL=${CTO_MAX_PARALLEL:-4}
    # Per-script timeout in seconds (default 8 minutes; configurable)
    SCRIPT_TIMEOUT=${CTO_SCRIPT_TIMEOUT:-480}
    RUNNING_PIDS=()
    RUNNING_NAMES=()
    RUNNING_SCRIPTS=()

    # Function to wait for a slot when max parallel reached
    wait_for_slot() {
        while [ ${#RUNNING_PIDS[@]} -ge $MAX_PARALLEL ]; do
            local new_pids=()
            local new_names=()
            local new_scripts=()
            for i in "${!RUNNING_PIDS[@]}"; do
                if kill -0 "${RUNNING_PIDS[$i]}" 2>/dev/null; then
                    new_pids+=("${RUNNING_PIDS[$i]}")
                    new_names+=("${RUNNING_NAMES[$i]}")
                    new_scripts+=("${RUNNING_SCRIPTS[$i]}")
                else
                    # Process completed, collect result
                    wait "${RUNNING_PIDS[$i]}" 2>/dev/null || true
                    local completed_script="${RUNNING_SCRIPTS[$i]}"
                    local completed_name="${RUNNING_NAMES[$i]}"
                    local output_file="$RESULTS_DIR/${completed_script%.sh}.json"
                    if [ -f "$output_file" ]; then
                        local score
                        score=$(jq -r '.score // 0' "$output_file")
                        local config_key
                        config_key=$(echo "${completed_script%.sh}" | sed 's/^[0-9]*-//; s/-/_/g')
                        case "$config_key" in
                            data) config_key="data_architecture" ;;
                            api) config_key="api_design" ;;
                            uiux_audit) config_key="uiux_consistency" ;;
                        esac
                        local weight
                        weight=$(get_category_weight "$config_key")
                        echo "$completed_name:$score:$weight" >> "$SCORES_FILE"
                        log_success "$completed_name Score: $score/10 (weight: ${weight}%)"
                    fi
                fi
            done
            RUNNING_PIDS=("${new_pids[@]+"${new_pids[@]}"}")
            RUNNING_NAMES=("${new_names[@]+"${new_names[@]}"}")
            RUNNING_SCRIPTS=("${new_scripts[@]+"${new_scripts[@]}"}")
            if [ ${#RUNNING_PIDS[@]} -ge $MAX_PARALLEL ]; then
                sleep 0.5
            fi
        done
    }

    log_section "Running Evaluations (up to $MAX_PARALLEL in parallel)"

    while IFS=':' read -r script name; do
        [ -z "$script" ] && continue

        # Skip based on options
        if [ "$SKIP_SECURITY" = "true" ] && [ "$script" = "03-security.sh" ]; then
            log_warning "Skipping: $name (--skip-security)"
            continue
        fi
        if [ "$SKIP_PERFORMANCE" = "true" ] && [ "$script" = "04-performance.sh" ]; then
            log_warning "Skipping: $name (--skip-performance)"
            continue
        fi

        wait_for_slot

        log_info "Starting: $name"

        # Launch category in background with per-script timeout
        (
            _script_path="$SCRIPT_DIR/$script"
            _output_file="$RESULTS_DIR/${script%.sh}.json"
            if [ -f "$_script_path" ]; then
                # Run script with timeout — if it exceeds SCRIPT_TIMEOUT, kill it
                # and write a partial result so the evaluation can continue
                bash "$_script_path" "$CODEBASE_PATH" "$_output_file" "$RESULTS_DIR" >/dev/null 2>&1 &
                _child_pid=$!
                _elapsed=0
                while kill -0 "$_child_pid" 2>/dev/null; do
                    sleep 2
                    _elapsed=$((_elapsed + 2))
                    if [ "$_elapsed" -ge "$SCRIPT_TIMEOUT" ]; then
                        kill "$_child_pid" 2>/dev/null || true
                        sleep 1
                        kill -9 "$_child_pid" 2>/dev/null || true
                        # Write a fallback result if the script didn't produce output
                        if [ ! -f "$_output_file" ]; then
                            echo '{"score":5.0,"findings":[{"severity":"medium","description":"Evaluation timed out after '"$SCRIPT_TIMEOUT"'s — partial results only","remediation":"Re-run with longer timeout or optimize codebase"}],"metrics":{},"timed_out":true}' > "$_output_file"
                        fi
                        break
                    fi
                done
                wait "$_child_pid" 2>/dev/null || true
            fi
        ) &

        RUNNING_PIDS+=($!)
        RUNNING_NAMES+=("$name")
        RUNNING_SCRIPTS+=("$script")
    done <<< "$CATEGORIES"

    # Wait for all remaining jobs
    for i in "${!RUNNING_PIDS[@]}"; do
        wait "${RUNNING_PIDS[$i]}" 2>/dev/null || true
        local completed_script="${RUNNING_SCRIPTS[$i]}"
        local completed_name="${RUNNING_NAMES[$i]}"
        local output_file="$RESULTS_DIR/${completed_script%.sh}.json"
        if [ -f "$output_file" ]; then
            local score
            score=$(jq -r '.score // 0' "$output_file")
            local config_key
            config_key=$(echo "${completed_script%.sh}" | sed 's/^[0-9]*-//; s/-/_/g')
            case "$config_key" in
                data) config_key="data_architecture" ;;
                api) config_key="api_design" ;;
                uiux_audit) config_key="uiux_consistency" ;;
            esac
            local weight
            weight=$(get_category_weight "$config_key")
            echo "$completed_name:$score:$weight" >> "$SCORES_FILE"
            log_success "$completed_name Score: $score/10 (weight: ${weight}%)"
        fi
    done

    # ==========================================================================
    # CALCULATE FINAL SCORE
    # ==========================================================================

    log_section "Final Score Calculation"

    # Generate report
    bash "$SCRIPT_DIR/generate-report.sh" "$RESULTS_DIR" "$CODEBASE_PATH"

    log_section "Evaluation Complete"
    log_success "Results saved to: $RESULTS_DIR"
    log_info "View report: $RESULTS_DIR/report.md"

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    EVALUATION COMPLETE                                ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

# Run main function
main "$@"
