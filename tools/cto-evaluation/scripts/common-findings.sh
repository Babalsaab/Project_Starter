#!/bin/bash

# =============================================================================
# CTO Evaluation Suite - Common Findings Helper
# =============================================================================
# Source this file to enable cross-subshell findings accumulation.
# Uses JSONL (one JSON object per line) for O(1) appends instead of
# O(n²) read-modify-write of a JSON array.
#
# Usage:
#   source "$SCRIPT_DIR/common-findings.sh"
#   init_findings
#   add_finding "severity" "parameter" "message" "location" "CWE-798"
#   findings_json=$(get_findings)
#   RESULTS=$(merge_findings "$RESULTS")
# =============================================================================

# Initialize findings accumulator (JSONL format - one object per line)
init_findings() {
    export FINDINGS_FILE="${TMPDIR:-/tmp}/cto_findings_$$.jsonl"
    > "$FINDINGS_FILE"
}

# Add a finding (works across subshells via file append - O(1))
# Parameters: severity, parameter, message, location (optional), cwe (optional)
add_finding() {
    local severity="$1"
    local parameter="$2"
    local message="$3"
    local location="${4:-}"
    local cwe="${5:-}"

    if [ -n "$FINDINGS_FILE" ] && [ -f "$FINDINGS_FILE" ]; then
        jq -n -c \
            --arg sev "$severity" \
            --arg param "$parameter" \
            --arg msg "$message" \
            --arg loc "$location" \
            --arg cwe "$cwe" \
            '{severity: $sev, parameter: $param, message: $msg, location: $loc, cwe: $cwe}' \
            >> "$FINDINGS_FILE"
    fi
}

# Get all findings as a JSON array (converts JSONL to array)
get_findings() {
    if [ -n "$FINDINGS_FILE" ] && [ -f "$FINDINGS_FILE" ] && [ -s "$FINDINGS_FILE" ]; then
        jq -s '.' "$FINDINGS_FILE"
    else
        echo "[]"
    fi
}

# Merge findings into a JSON result object
# Usage: RESULTS=$(merge_findings "$RESULTS")
merge_findings() {
    local input_results="$1"
    local all_findings
    all_findings=$(get_findings)
    echo "$input_results" | jq --argjson findings "$all_findings" '.findings = $findings'
    rm -f "$FINDINGS_FILE" 2>/dev/null
}

# Count findings by severity
count_findings_by_severity() {
    local severity="$1"
    if [ -n "$FINDINGS_FILE" ] && [ -f "$FINDINGS_FILE" ] && [ -s "$FINDINGS_FILE" ]; then
        local count
        # Use || true (not || echo "0") because grep -c prints "0" AND exits 1 on zero matches,
        # causing "|| echo" to produce a second "0", resulting in "0\n0" which breaks --argjson.
        count=$(grep -c "\"severity\":\"${severity}\"" "$FINDINGS_FILE" 2>/dev/null || true)
        count="${count:-0}"
        # Strip Windows carriage returns to prevent jq --argjson failures
        echo "${count}" | tr -d '\r'
    else
        echo "0"
    fi
}
