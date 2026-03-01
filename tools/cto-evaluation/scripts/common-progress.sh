#!/bin/bash

# =============================================================================
# CTO Evaluation Suite - Common Progress Functions
# =============================================================================
# Source this file in evaluation scripts for progress indicators
# =============================================================================

# Colors
export CYAN='\033[0;36m'
export BLUE='\033[0;34m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export MAGENTA='\033[0;35m'
export NC='\033[0m'

# Progress tracking
TOTAL_STEPS=0
CURRENT_STEP=0
SECTION_START_TIME=0

# Set total steps for this evaluation
set_total_steps() {
    TOTAL_STEPS="$1"
    CURRENT_STEP=0
}

# Start timing a section
start_timer() {
    SECTION_START_TIME=$(date +%s)
}

# Get elapsed time in human readable format
get_elapsed_time() {
    local start="$1"
    local end=$(date +%s)
    local elapsed=$((end - start))
    
    if [ "$elapsed" -lt 60 ]; then
        echo "${elapsed}s"
    elif [ "$elapsed" -lt 3600 ]; then
        local mins=$((elapsed / 60))
        local secs=$((elapsed % 60))
        echo "${mins}m ${secs}s"
    else
        local hours=$((elapsed / 3600))
        local mins=$(((elapsed % 3600) / 60))
        echo "${hours}h ${mins}m"
    fi
}

# Show progress step with timing
progress_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local msg="$1"
    echo "Evaluating: [$CURRENT_STEP/$TOTAL_STEPS] $msg" >&2
}

# Show file being scanned
scan_file() {
    local file="$1"
    local filename=$(basename "$file")
    echo "Scanning: $filename" >&2
}

# Show current action
show_action() {
    local action="$1"
    echo "Checking: $action" >&2
}

# Show analysis in progress
analyzing() {
    local target="$1"
    echo "Analyzing: $target" >&2
}

# Show progress count
show_count() {
    local current="$1"
    local total="$2"
    local label="$3"
    echo "Scanning: $current/$total $label" >&2
}

# Show progress percentage
show_percentage() {
    local current="$1"
    local total="$2"
    local label="$3"
    if [ "$total" -gt 0 ]; then
        local percent=$((current * 100 / total))
        echo "Progress: $percent% ($current/$total) $label" >&2
    fi
}

# Print completion with time
print_completion() {
    local section="$1"
    local start_time="$2"
    local elapsed=$(get_elapsed_time "$start_time")
    echo "Completed: $section in $elapsed" >&2
}
