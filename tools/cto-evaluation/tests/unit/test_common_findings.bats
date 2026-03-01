#!/usr/bin/env bats

setup() {
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../scripts" && pwd)"
    source "$SCRIPT_DIR/common-findings.sh"
    init_findings
}

teardown() {
    rm -f "$FINDINGS_FILE" 2>/dev/null || true
}

@test "init_findings creates file" {
    [ -f "$FINDINGS_FILE" ]
}

@test "init_findings creates empty file" {
    [ ! -s "$FINDINGS_FILE" ]
}

@test "add_finding appends to findings file" {
    add_finding "critical" "test_param" "test message" "file.js"
    [ -s "$FINDINGS_FILE" ]
}

@test "add_finding with CWE includes cwe field" {
    add_finding "critical" "secrets" "found secret" "app.js" "CWE-798"
    result=$(get_findings)
    cwe=$(echo "$result" | jq -r '.[0].cwe')
    [ "$cwe" = "CWE-798" ]
}

@test "get_findings returns empty array when no findings" {
    result=$(get_findings)
    [ "$result" = "[]" ]
}

@test "get_findings returns array with findings" {
    add_finding "high" "p1" "msg1" "f1.js"
    add_finding "low" "p2" "msg2" "f2.js"
    result=$(get_findings)
    count=$(echo "$result" | jq 'length')
    [ "$count" -eq 2 ]
}

@test "count_findings_by_severity filters correctly" {
    add_finding "critical" "p1" "msg1" "f1"
    add_finding "high" "p2" "msg2" "f2"
    add_finding "critical" "p3" "msg3" "f3"
    count=$(count_findings_by_severity "critical")
    [ "$count" -eq 2 ]
}

@test "merge_findings adds findings to JSON" {
    add_finding "medium" "test" "test msg" "test.js"
    local input='{"category": "test", "score": 5, "findings": []}'
    result=$(merge_findings "$input")
    count=$(echo "$result" | jq '.findings | length')
    [ "$count" -eq 1 ]
}
