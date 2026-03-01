#!/bin/bash

# =============================================================================
# MOBILE ENGINEERING EVALUATION (Parameters 361-378)
# =============================================================================
# Evaluates:
#   - Mobile Architecture (303-312)
#   - Mobile Performance (313-320)
# =============================================================================

set -euo pipefail

CODEBASE_PATH="${1:-}"
OUTPUT_FILE="${2:-}"
RESULTS_DIR="${3:-${TMPDIR:-/tmp}}"

if [ -z "$CODEBASE_PATH" ] || [ ! -d "$CODEBASE_PATH" ]; then
    echo "Usage: $0 <codebase_path> [output_file] [results_dir]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-findings.sh"
source "$SCRIPT_DIR/lib/math-utils.sh"
init_findings

# Progress tracking
TOTAL_STEPS=4
CURRENT_STEP=0

progress_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "Evaluating: [$CURRENT_STEP/$TOTAL_STEPS] $1" >&2
}

RESULTS='{
    "category": "mobile",
    "parameters_evaluated": 0,
    "parameters_total": 18,
    "score": 0,
    "findings": [],
    "metrics": {}
}'

log_metric() {
    RESULTS=$(echo "$RESULTS" | jq --arg n "$1" --arg v "$2" '.metrics[$n] = $v')
}

# add_finding is now provided by common-findings.sh with location support
# add_finding "severity" "parameter" "message" "location"

# =============================================================================
# Detect Mobile Project Type
# =============================================================================
detect_mobile_type() {
    progress_step "Detecting mobile project type"

    # React Native
    if [ -f "$CODEBASE_PATH/app.json" ] && grep -q "expo\|react-native" "$CODEBASE_PATH/app.json" 2>/dev/null; then
        log_metric "mobile_type" "react-native"
        echo "Scanning: React Native project detected" >&2
        return 0
    fi

    # Flutter
    if [ -f "$CODEBASE_PATH/pubspec.yaml" ]; then
        log_metric "mobile_type" "flutter"
        echo "Scanning: Flutter project detected" >&2
        return 0
    fi

    # iOS Native
    if find "$CODEBASE_PATH" -name "*.xcodeproj" -o -name "*.xcworkspace" 2>/dev/null | head -1 | grep -q .; then
        log_metric "mobile_type" "ios-native"
        echo "Scanning: iOS native project detected" >&2
        return 0
    fi

    # Android Native
    if [ -f "$CODEBASE_PATH/build.gradle" ] || [ -f "$CODEBASE_PATH/app/build.gradle" ]; then
        if grep -qE "android|com\.android" "$CODEBASE_PATH/build.gradle" "$CODEBASE_PATH/app/build.gradle" 2>/dev/null; then
            log_metric "mobile_type" "android-native"
            echo "Scanning: Android native project detected" >&2
            return 0
        fi
    fi

    log_metric "mobile_type" "none"
    echo "Scanning: No mobile project detected" >&2
    return 1
}

# =============================================================================
# Check Mobile Architecture (Parameters 326-335)
# =============================================================================
check_mobile_architecture() {
    progress_step "Mobile architecture patterns"
    local score=5
    local mobile_type=$(echo "$RESULTS" | jq -r '.metrics.mobile_type // "none"')

    if [ "$mobile_type" = "none" ]; then
        echo "$score"
        return
    fi

    # Check for architecture patterns (MVVM, MVI, Clean)
    if grep -rqE "(ViewModel|UseCase|Repository|Provider|Bloc|Cubit|@observable|mobx)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.tsx" --include="*.dart" --include="*.kt" --include="*.swift" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=build 2>/dev/null; then
        log_metric "architecture_pattern" "true"
        score=$((score + 2))
        echo "Scanning: Found architecture pattern" >&2
    fi

    # Check for navigation
    if grep -rqE "(react-navigation|expo-router|Navigator|GoRouter|navigation|@react-navigation)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.tsx" --include="*.dart" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "navigation_library" "true"
        score=$((score + 1))
    fi

    # Check for offline support
    if grep -rqE "(AsyncStorage|@react-native-async-storage|sqlite|realm|hive|shared_preferences|WatermelonDB)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.tsx" --include="*.dart" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "offline_storage" "true"
        score=$((score + 1))
        echo "Scanning: Found offline storage" >&2
    fi

    # Check for biometric auth
    if grep -rqE "(biometric|touchID|faceID|fingerprint|LocalAuthentication|local_auth)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.tsx" --include="*.dart" --include="*.swift" --include="*.kt" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "biometric_auth" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Mobile Performance (Parameters 336-343)
# =============================================================================
check_mobile_performance() {
    progress_step "Mobile performance patterns"
    local score=5
    local mobile_type=$(echo "$RESULTS" | jq -r '.metrics.mobile_type // "none"')

    if [ "$mobile_type" = "none" ]; then
        echo "$score"
        return
    fi

    # Check for image optimization
    if grep -rqE "(FastImage|CachedNetworkImage|resizeMode|cached_network_image|Image\.asset)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.tsx" --include="*.dart" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "image_optimization" "true"
        score=$((score + 1))
    fi

    # Check for list optimization
    if grep -rqE "(FlatList|VirtualizedList|RecyclerView|ListView\.builder|SliverList)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.tsx" --include="*.dart" --include="*.kt" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "list_optimization" "true"
        score=$((score + 1))
        echo "Scanning: Found list optimization patterns" >&2
    fi

    # Check for memory management
    if grep -rqE "(useCallback|useMemo|memo|@computed|dispose|removeListener|cleanup)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.tsx" --include="*.dart" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "memory_management" "true"
        score=$((score + 1))
    fi

    # Check for crash reporting
    if grep -rqE "(sentry|crashlytics|bugsnag|instabug|@sentry)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.tsx" --include="*.dart" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "crash_reporting" "true"
        score=$((score + 1))
    fi

    # Check for push notifications
    if grep -rqE "(push.*notification|FCM|firebase.*messaging|expo-notifications|@notifee)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.tsx" --include="*.dart" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "push_notifications" "true"
        score=$((score + 1))
        echo "Scanning: Found push notification setup" >&2
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Mobile Testing (Additional)
# =============================================================================
check_mobile_testing() {
    progress_step "Mobile testing"
    local score=5
    local mobile_type=$(echo "$RESULTS" | jq -r '.metrics.mobile_type // "none"')

    if [ "$mobile_type" = "none" ]; then
        echo "$score"
        return
    fi

    # Check for testing libraries
    if grep -rqE "(detox|maestro|appium|flutter_test|@testing-library/react-native)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.yaml" --include="*.dart" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "e2e_testing" "true"
        score=$((score + 2))
        echo "Scanning: Found E2E testing setup" >&2
    fi

    # Check for unit tests
    local test_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.test.ts" -o -name "*.test.tsx" -o -name "*_test.dart" -o -name "*Test.kt" \
        \) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l)
    
    log_metric "mobile_test_files" "$test_files"

    if [ "$test_files" -gt 20 ]; then
        score=$((score + 2))
    elif [ "$test_files" -gt 5 ]; then
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Mobile Evaluation..." >&2
    echo "Codebase: $CODEBASE_PATH" >&2

    detect_mobile_type || true  # Allow non-mobile projects to continue
    local mobile_type=$(echo "$RESULTS" | jq -r '.metrics.mobile_type // "none"')

    if [ "$mobile_type" = "none" ]; then
        # Not a mobile project - assign neutral score
        RESULTS=$(echo "$RESULTS" | jq '.score = 5')
        RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 0')
        RESULTS=$(echo "$RESULTS" | jq '.findings += [{severity: "info", parameter: "mobile", message: "No mobile project detected"}]')
        # Merge findings from subshells
        RESULTS=$(merge_findings "$RESULTS")
        echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
        echo "Mobile Score: 5/10 (N/A - not a mobile project)" >&2
        return
    fi

    local arch_score=$(check_mobile_architecture)
    local perf_score=$(check_mobile_performance)
    local test_score=$(check_mobile_testing)

    # Weighted average
    local total_score=$(math_calc "$arch_score * 0.40 + $perf_score * 0.35 + $test_score * 0.25")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 18')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg as "$arch_score" \
        --arg ps "$perf_score" \
        --arg ts "$test_score" \
        '.subscores = {
            architecture: ($as | tonumber),
            performance: ($ps | tonumber),
            testing: ($ts | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Mobile Score: $total_score/10" >&2
}

main
