#!/bin/bash

# =============================================================================
# CROSS-PLATFORM MATH UTILITIES
# =============================================================================
# Replaces `bc` with `awk` for Windows Git Bash compatibility.
# `bc` is not available in Windows Git Bash by default, but `awk` is.
#
# Usage: source "$SCRIPT_DIR/lib/math-utils.sh"
# =============================================================================

# Compare two decimal numbers. Returns 0 (true) if comparison holds, 1 otherwise.
# Usage: math_compare "7.5" ">=" "6.0" && echo "yes"
# Supported operators: >=, <=, >, <, ==, !=
math_compare() {
    local left="$1" op="$2" right="$3"
    awk -v l="$left" -v r="$right" "BEGIN { exit !(l $op r) }"
}

# Evaluate an arithmetic expression and print the result.
# Usage: result=$(math_calc "7.5 * 0.12 + 3.0 * 0.08")
# Usage: result=$(math_calc "7.5 * 0.12" 4)  # 4 decimal places
# Strips bc-style "scale=N;" prefixes automatically.
math_calc() {
    local expr="$1"
    local scale="${2:-2}"
    # Strip bc-style scale prefix if present
    expr="${expr//scale=[0-9]*;/}"
    # Trim whitespace
    expr="$(echo "$expr" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    awk "BEGIN { printf \"%.${scale}f\", $expr }"
}

# Integer calculation (no decimal places).
# Usage: result=$(math_int "7 * 2")
math_int() {
    local expr="$1"
    awk "BEGIN { printf \"%d\", int($expr) }"
}

# Grade lookup based on score. Replaces repeated if/elif bc chains.
# Usage: grade=$(math_grade "7.5")
math_grade() {
    local score="$1"
    awk -v s="$score" 'BEGIN {
        if (s >= 9.5) print "A+"
        else if (s >= 9.0) print "A"
        else if (s >= 8.5) print "A-"
        else if (s >= 8.0) print "B+"
        else if (s >= 7.5) print "B"
        else if (s >= 7.0) print "B-"
        else if (s >= 6.5) print "C+"
        else if (s >= 6.0) print "C"
        else if (s >= 5.5) print "C-"
        else if (s >= 5.0) print "D"
        else print "F"
    }'
}

# Risk level based on score. Replaces get_risk_level bc chains.
# Usage: risk=$(math_risk_level "7.5")
math_risk_level() {
    local score="$1"
    awk -v s="$score" 'BEGIN {
        if (s >= 8.0) print "Low"
        else if (s >= 6.0) print "Medium"
        else if (s >= 4.0) print "High"
        else print "Critical"
    }'
}

# Generate a visual score bar. Replaces get_score_bar bc usage.
# Usage: bar=$(math_score_bar "7.5")       # 20-char bar
# Usage: bar=$(math_score_bar "7.5" 40)    # 40-char bar
math_score_bar() {
    local score="$1" width="${2:-20}"
    awk -v s="$score" -v w="$width" 'BEGIN {
        filled = int(s * w / 10 + 0.5)
        if (filled > w) filled = w
        if (filled < 0) filled = 0
        bar = ""
        for (i = 0; i < filled; i++) bar = bar "█"
        for (i = filled; i < w; i++) bar = bar "░"
        print bar
    }'
}
