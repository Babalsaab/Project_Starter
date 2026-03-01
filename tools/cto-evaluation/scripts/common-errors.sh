#!/bin/bash

# =============================================================================
# CTO Evaluation Suite - Error Handling Utilities
# =============================================================================
# Provides robust error handling, timeouts, and retry logic for scripts.
#
# Usage: source "$SCRIPT_DIR/common-errors.sh"
# =============================================================================

# Global error handling settings
set -o pipefail

# Default timeout in seconds
DEFAULT_TIMEOUT=${CTO_SCRIPT_TIMEOUT:-300}
DEFAULT_RETRY_COUNT=${CTO_RETRY_COUNT:-3}
DEFAULT_RETRY_DELAY=${CTO_RETRY_DELAY:-2}

# Error log file
ERROR_LOG=""

# =============================================================================
# Initialize Error Handling
# =============================================================================

init_error_handling() {
    local results_dir="${1:-${TMPDIR:-/tmp}}"
    ERROR_LOG="$results_dir/error.log"
    
    # Set up trap for script errors
    trap 'handle_error $? $LINENO "$BASH_COMMAND"' ERR
    trap 'cleanup_on_exit' EXIT
    
    # Initialize error log
    echo "# Error Log - $(date '+%Y-%m-%d %H:%M:%S')" > "$ERROR_LOG"
}

# =============================================================================
# Error Handler
# =============================================================================

handle_error() {
    local exit_code=$1
    local line_number=$2
    local command=$3
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local script_name=$(basename "${BASH_SOURCE[1]:-unknown}")
    
    # Log the error
    {
        echo "[$timestamp] ERROR in $script_name at line $line_number"
        echo "  Exit code: $exit_code"
        echo "  Command: $command"
        echo ""
    } >> "$ERROR_LOG"
    
    # Also print to stderr
    echo -e "\033[0;31m[ERROR]\033[0m Script error at line $line_number: $command (exit code: $exit_code)" >&2
}

# =============================================================================
# Cleanup Handler
# =============================================================================

cleanup_on_exit() {
    local exit_code=$?
    
    # Kill any background processes started by this script
    jobs -p 2>/dev/null | xargs -r kill 2>/dev/null || true
    
    # Remove temporary files
    rm -f "${TMPDIR:-/tmp}"/cto_eval_$$.* 2>/dev/null || true
    
    return $exit_code
}

# =============================================================================
# Run with Timeout
# =============================================================================
# Usage: run_with_timeout <timeout_seconds> <command...>
# Returns: Exit code of command, or 124 if timed out

run_with_timeout() {
    local timeout_secs="${1:-$DEFAULT_TIMEOUT}"
    shift
    
    if command -v timeout &> /dev/null; then
        # GNU coreutils timeout
        timeout --signal=TERM --kill-after=10 "$timeout_secs" "$@"
    elif command -v gtimeout &> /dev/null; then
        # macOS with coreutils installed via brew
        gtimeout --signal=TERM --kill-after=10 "$timeout_secs" "$@"
    else
        # Fallback: Use bash built-in (less reliable)
        local pid
        "$@" &
        pid=$!
        
        (
            sleep "$timeout_secs"
            kill -TERM "$pid" 2>/dev/null
            sleep 5
            kill -KILL "$pid" 2>/dev/null
        ) &
        local watchdog_pid=$!
        
        wait "$pid" 2>/dev/null
        local exit_code=$?
        
        kill "$watchdog_pid" 2>/dev/null
        wait "$watchdog_pid" 2>/dev/null
        
        return $exit_code
    fi
}

# =============================================================================
# Retry with Backoff
# =============================================================================
# Usage: retry_with_backoff <max_attempts> <delay_seconds> <command...>
# Returns: Exit code of last attempt

retry_with_backoff() {
    local max_attempts="${1:-$DEFAULT_RETRY_COUNT}"
    local delay="${2:-$DEFAULT_RETRY_DELAY}"
    shift 2
    
    local attempt=1
    local exit_code=0
    
    while [ $attempt -le $max_attempts ]; do
        if "$@"; then
            return 0
        fi
        exit_code=$?
        
        if [ $attempt -lt $max_attempts ]; then
            echo -e "\033[1;33m[RETRY]\033[0m Attempt $attempt/$max_attempts failed, retrying in ${delay}s..." >&2
            sleep "$delay"
            # Exponential backoff
            delay=$((delay * 2))
        fi
        
        ((attempt++))
    done
    
    echo -e "\033[0;31m[FAILED]\033[0m All $max_attempts attempts failed" >&2
    return $exit_code
}

# =============================================================================
# Safe Command Execution
# =============================================================================
# Usage: safe_exec <description> <command...>
# Returns: 0 on success, 1 on failure (never fails the script)

safe_exec() {
    local description="$1"
    shift
    
    local output
    local exit_code
    
    output=$("$@" 2>&1)
    exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        {
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $description failed"
            echo "  Command: $*"
            echo "  Exit code: $exit_code"
            echo "  Output: $output"
            echo ""
        } >> "$ERROR_LOG"
        return 1
    fi
    
    echo "$output"
    return 0
}

# =============================================================================
# Check Command Exists
# =============================================================================
# Usage: require_command <command_name> [fallback_message]
# Returns: 0 if exists, 1 if not

require_command() {
    local cmd="$1"
    local message="${2:-Command '$cmd' is required but not installed}"
    
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "\033[0;31m[MISSING]\033[0m $message" >&2
        return 1
    fi
    return 0
}

# =============================================================================
# Optional Command Check
# =============================================================================
# Usage: optional_command <command_name>
# Returns: 0 if exists, 1 if not (no error message)

optional_command() {
    command -v "$1" &> /dev/null
}

# =============================================================================
# Safe File Operations
# =============================================================================

safe_read_file() {
    local filepath="$1"
    
    if [ ! -f "$filepath" ]; then
        echo ""
        return 1
    fi
    
    if [ ! -r "$filepath" ]; then
        echo ""
        return 1
    fi
    
    cat "$filepath"
}

safe_write_file() {
    local filepath="$1"
    local content="$2"
    
    local dir=$(dirname "$filepath")
    
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || return 1
    fi
    
    echo "$content" > "$filepath" || return 1
}

# =============================================================================
# JSON Safe Operations
# =============================================================================

safe_json_get() {
    local json="$1"
    local path="$2"
    local default="${3:-null}"
    
    if [ -z "$json" ]; then
        echo "$default"
        return 0
    fi
    
    local result
    result=$(echo "$json" | jq -r "$path" 2>/dev/null)
    
    if [ -z "$result" ] || [ "$result" = "null" ]; then
        echo "$default"
    else
        echo "$result"
    fi
}

safe_json_set() {
    local json="$1"
    local path="$2"
    local value="$3"
    
    echo "$json" | jq "$path = $value" 2>/dev/null || echo "$json"
}

# =============================================================================
# Progress Indicator with Timeout
# =============================================================================

run_with_progress() {
    local message="$1"
    local timeout_secs="${2:-$DEFAULT_TIMEOUT}"
    shift 2
    
    local pid
    local exit_code
    
    # Start spinner
    printf "  ⏳ %s..." "$message"
    
    # Run command in background
    "$@" &
    pid=$!
    
    # Wait with timeout
    local elapsed=0
    while kill -0 "$pid" 2>/dev/null; do
        if [ $elapsed -ge $timeout_secs ]; then
            kill -TERM "$pid" 2>/dev/null
            printf "\r  ⏱️  %s (timed out after %ds)\n" "$message" "$timeout_secs"
            return 124
        fi
        sleep 1
        ((elapsed++))
        printf "."
    done
    
    wait "$pid"
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        printf "\r  ✅ %s (completed in %ds)\n" "$message" "$elapsed"
    else
        printf "\r  ❌ %s (failed with code %d)\n" "$message" "$exit_code"
    fi
    
    return $exit_code
}

# =============================================================================
# Logging Helpers
# =============================================================================

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $message" >> "$ERROR_LOG"
    echo -e "\033[0;31m[ERROR]\033[0m $message" >&2
}

log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] WARN: $message" >> "$ERROR_LOG"
    echo -e "\033[1;33m[WARN]\033[0m $message" >&2
}

log_debug() {
    if [ "${CTO_VERBOSE:-false}" = "true" ]; then
        echo -e "\033[0;34m[DEBUG]\033[0m $1" >&2
    fi
}

# =============================================================================
# Export Functions
# =============================================================================

export -f run_with_timeout 2>/dev/null || true
export -f retry_with_backoff 2>/dev/null || true
export -f safe_exec 2>/dev/null || true
export -f require_command 2>/dev/null || true
export -f optional_command 2>/dev/null || true
export -f safe_read_file 2>/dev/null || true
export -f safe_write_file 2>/dev/null || true
export -f safe_json_get 2>/dev/null || true
export -f safe_json_set 2>/dev/null || true
export -f log_error 2>/dev/null || true
export -f log_warning 2>/dev/null || true
export -f log_debug 2>/dev/null || true
