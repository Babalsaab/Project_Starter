#!/usr/bin/env bats

setup() {
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../scripts/lib" && pwd)"
    source "$SCRIPT_DIR/config-reader.sh"
}

teardown() {
    cleanup_config 2>/dev/null || true
}

@test "get_category_weight: security returns 12" {
    result=$(get_category_weight "security")
    [ "$result" = "12" ]
}

@test "get_category_weight: code_quality returns 8" {
    result=$(get_category_weight "code_quality")
    [ "$result" = "8" ]
}

@test "get_category_weight: architecture returns 10" {
    result=$(get_category_weight "architecture")
    [ "$result" = "10" ]
}

@test "get_category_weight: unknown category returns default 5" {
    result=$(get_category_weight "nonexistent_category")
    [ "$result" = "5" ]
}

@test "get_category_weight: uiux_consistency returns 4" {
    result=$(get_category_weight "uiux_consistency")
    [ "$result" = "4" ]
}

@test "get_total_parameters: returns 495" {
    result=$(get_total_parameters)
    [ "$result" = "495" ]
}

@test "load_config_weights: creates temp file" {
    load_config_weights
    [ -f "$_CONFIG_WEIGHTS_FILE" ]
}

@test "load_config_weights: temp file has content" {
    load_config_weights
    [ -s "$_CONFIG_WEIGHTS_FILE" ]
}
