#!/bin/bash

# =============================================================================
# CONFIGURATION READER -- Single Source of Truth
# =============================================================================
# Reads category weights and parameters from config/evaluation.yaml.
# Eliminates weight duplication across run-full-evaluation.sh,
# generate-report.sh, and run-enhanced-evaluation.sh.
#
# Usage:
#   source "$SCRIPT_DIR/lib/config-reader.sh"
#   weight=$(get_category_weight "security")      # Returns: 12
#   params=$(get_total_parameters)                 # Returns: 495
# =============================================================================

_CONFIG_WEIGHTS_LOADED=false
_CONFIG_WEIGHTS_FILE=""
_CONFIG_DIR=""

# Resolve the config directory relative to this script
_resolve_config_dir() {
    if [ -z "$_CONFIG_DIR" ]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        _CONFIG_DIR="$(cd "$script_dir/../.." && pwd)/config"
    fi
}

# Load category weights from evaluation.yaml into a temp lookup file.
# Parses the YAML category_weights block using simple sed/grep (no YAML library needed).
load_config_weights() {
    _resolve_config_dir
    local config_file="$_CONFIG_DIR/evaluation.yaml"

    if [ ! -f "$config_file" ]; then
        echo "WARNING: Config file not found: $config_file" >&2
        return 1
    fi

    _CONFIG_WEIGHTS_FILE="${TMPDIR:-/tmp}/cto_config_weights_$$.txt"
    # Extract category_weights block: lines starting with 2 spaces after category_weights:
    # Stop at next top-level key (line not starting with space or #)
    sed -n '/^category_weights:/,/^[a-zA-Z]/{/^  [a-z]/p}' "$config_file" \
        | sed 's/^  //; s/:  */=/; s/ *#.*//' \
        > "$_CONFIG_WEIGHTS_FILE"
    _CONFIG_WEIGHTS_LOADED=true
}

# Get weight for a category. Falls back to 5 if not found.
# Usage: weight=$(get_category_weight "security")
get_category_weight() {
    local category="$1"
    if [ "$_CONFIG_WEIGHTS_LOADED" != "true" ]; then
        load_config_weights
    fi
    local weight
    weight=$(grep "^${category}=" "$_CONFIG_WEIGHTS_FILE" 2>/dev/null | head -1 | cut -d= -f2)
    echo "${weight:-5}"
}

# Get total parameter count from config.
# Usage: count=$(get_total_parameters)
get_total_parameters() {
    _resolve_config_dir
    local config_file="$_CONFIG_DIR/evaluation.yaml"
    grep "total_parameters:" "$config_file" 2>/dev/null | awk '{print $2}'
}

# Cleanup temp files on exit
cleanup_config() {
    rm -f "$_CONFIG_WEIGHTS_FILE" 2>/dev/null
}

# Register cleanup trap if not already set by another module
if ! trap -p EXIT | grep -q "cleanup_config"; then
    _existing_trap=$(trap -p EXIT | sed "s/trap -- '//;s/' EXIT//")
    if [ -n "$_existing_trap" ]; then
        trap "${_existing_trap}; cleanup_config" EXIT
    else
        trap "cleanup_config" EXIT
    fi
fi
