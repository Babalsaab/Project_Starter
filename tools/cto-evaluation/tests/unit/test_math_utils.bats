#!/usr/bin/env bats

setup() {
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../scripts/lib" && pwd)"
    source "$SCRIPT_DIR/math-utils.sh"
}

@test "math_compare: 7.5 >= 6.0 is true" {
    math_compare "7.5" ">=" "6.0"
}

@test "math_compare: 5.0 >= 6.0 is false" {
    run math_compare "5.0" ">=" "6.0"
    [ "$status" -ne 0 ]
}

@test "math_compare: equal values" {
    math_compare "9.5" ">=" "9.5"
}

@test "math_compare: less than" {
    math_compare "3.0" "<" "5.0"
}

@test "math_calc: basic multiplication" {
    result=$(math_calc "7.5 * 0.12")
    [ "$result" = "0.90" ]
}

@test "math_calc: addition" {
    result=$(math_calc "3 + 4")
    [ "$result" = "7.00" ]
}

@test "math_calc: division with custom scale" {
    result=$(math_calc "100 / 3" 4)
    [ "$result" = "33.3333" ]
}

@test "math_calc: strips bc scale prefix" {
    result=$(math_calc "scale=2; 10 / 3")
    [ "$result" = "3.33" ]
}

@test "math_int: truncates to integer" {
    result=$(math_int "7.8 * 2")
    [ "$result" = "15" ]
}

@test "math_grade: 9.5 gives A+" {
    result=$(math_grade "9.5")
    [ "$result" = "A+" ]
}

@test "math_grade: 9.49 gives A" {
    result=$(math_grade "9.49")
    [ "$result" = "A" ]
}

@test "math_grade: 8.5 gives A-" {
    result=$(math_grade "8.5")
    [ "$result" = "A-" ]
}

@test "math_grade: 7.5 gives B" {
    result=$(math_grade "7.5")
    [ "$result" = "B" ]
}

@test "math_grade: 4.0 gives F" {
    result=$(math_grade "4.0")
    [ "$result" = "F" ]
}

@test "math_risk_level: 8.5 is Low" {
    result=$(math_risk_level "8.5")
    [ "$result" = "Low" ]
}

@test "math_risk_level: 6.5 is Medium" {
    result=$(math_risk_level "6.5")
    [ "$result" = "Medium" ]
}

@test "math_risk_level: 4.5 is High" {
    result=$(math_risk_level "4.5")
    [ "$result" = "High" ]
}

@test "math_risk_level: 3.0 is Critical" {
    result=$(math_risk_level "3.0")
    [ "$result" = "Critical" ]
}

@test "math_score_bar: produces 20-char output for score 5" {
    result=$(math_score_bar "5.0")
    [ "${#result}" -eq 20 ]
}

@test "math_score_bar: full bar for score 10" {
    result=$(math_score_bar "10.0")
    [[ "$result" == *"█"* ]]
    [[ "$result" != *"░"* ]]
}

@test "math_score_bar: empty bar for score 0" {
    result=$(math_score_bar "0.0")
    [[ "$result" != *"█"* ]]
    [[ "$result" == *"░"* ]]
}
