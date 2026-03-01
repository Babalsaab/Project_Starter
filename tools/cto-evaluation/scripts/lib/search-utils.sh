#!/bin/bash

# =============================================================================
# SEARCH UTILITIES (Common exclusions and safe grep helpers)
# =============================================================================

CODE_EXCLUDE_DIRS=(
    "node_modules"
    ".git"
    "vendor"
    "dist"
    "build"
    ".venv"
    "venv"
    "coverage"
    "output"
    ".cto-evaluation"
)

build_exclude_args() {
    local args=()
    local d
    for d in "${CODE_EXCLUDE_DIRS[@]}"; do
        args+=("--exclude-dir=$d")
    done
    echo "${args[@]}"
}

# Grep with exclusions and extended regex
# Usage: grep_code "pattern" "path"
grep_code() {
    local pattern="$1"
    local path="$2"
    shift 2
    local exclude_args
    exclude_args=$(build_exclude_args)
    # shellcheck disable=SC2086
    grep -R -n -E $exclude_args "$@" "$pattern" "$path" 2>/dev/null
}

# Quiet grep (true if match)
# Usage: grep_code_quiet "pattern" "path"
grep_code_quiet() {
    local pattern="$1"
    local path="$2"
    shift 2
    local exclude_args
    exclude_args=$(build_exclude_args)
    # shellcheck disable=SC2086
    grep -R -n -E -q $exclude_args "$@" "$pattern" "$path" 2>/dev/null
}

# Count matches with exclusions
# Usage: grep_code_count "pattern" "path" [--include=*.js ...]
grep_code_count() {
    local pattern="$1"
    local path="$2"
    shift 2
    local exclude_args
    exclude_args=$(build_exclude_args)
    # shellcheck disable=SC2086
    { grep -R -n -E $exclude_args "$@" "$pattern" "$path" 2>/dev/null || true; } | wc -l | tr -d ' '
}

export -f grep_code grep_code_quiet grep_code_count build_exclude_args
