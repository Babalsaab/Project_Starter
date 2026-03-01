#!/bin/bash

# =============================================================================
# FRONTEND ENGINEERING EVALUATION (Parameters 317-340)
# =============================================================================
# Evaluates:
#   - Architecture & Performance (259-270)
#   - Quality & UX (271-282)
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
TOTAL_STEPS=6
CURRENT_STEP=0

progress_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "Evaluating: [$CURRENT_STEP/$TOTAL_STEPS] $1" >&2
}

RESULTS='{
    "category": "frontend",
    "parameters_evaluated": 0,
    "parameters_total": 24,
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
# Check Component Architecture (Parameter 259)
# =============================================================================
check_component_architecture() {
    progress_step "Component architecture"
    local score=5

    # Count component files
    local component_count=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.tsx" -o -name "*.jsx" -o -name "*.vue" -o -name "*.svelte" \
        \) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l)
    
    log_metric "component_files" "$component_count"
    echo "Scanning: Found $component_count component files" >&2

    if [ "$component_count" -gt 50 ]; then
        score=8
    elif [ "$component_count" -gt 20 ]; then
        score=7
    elif [ "$component_count" -eq 0 ]; then
        log_metric "frontend_framework" "none"
        # Not a frontend project, give neutral score
        score=5
    fi

    # Check for component organization
    if [ -d "$CODEBASE_PATH/src/components" ] || [ -d "$CODEBASE_PATH/components" ]; then
        log_metric "component_folder" "true"
        score=$((score + 1))
    fi

    # Check for atomic design / organized structure
    if [ -d "$CODEBASE_PATH/src/components/atoms" ] || \
       [ -d "$CODEBASE_PATH/src/components/molecules" ] || \
       [ -d "$CODEBASE_PATH/src/components/ui" ]; then
        log_metric "atomic_design" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check State Management (Parameter 260)
# =============================================================================
check_state_management() {
    progress_step "State management"
    local score=5

    # Check for state management libraries
    if grep -rqE "(redux|zustand|recoil|mobx|@ngrx|pinia|vuex|effector)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.ts" --include="*.tsx" --include="*.js" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "state_management_library" "true"
        score=8
        echo "Scanning: Found state management library" >&2
    fi

    # Check for React Context usage
    if grep -rqE "(createContext|useContext|Provider)" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.ts" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "react_context" "true"
        score=$((score + 1))
    fi

    # Check for React Query / SWR (server state)
    if grep -rqE "(@tanstack/react-query|swr|react-query|useQuery|useSWR)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.tsx" --include="*.ts" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "server_state_library" "true"
        score=$((score + 1))
        echo "Scanning: Found server state management" >&2
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Performance Patterns (Parameters 284-293)
# =============================================================================
check_performance() {
    progress_step "Performance patterns"
    local score=5

    # Check for code splitting / lazy loading
    if grep -rqE "(React\.lazy|dynamic\(|import\(|loadable|Suspense)" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "code_splitting" "true"
        score=$((score + 1))
        echo "Scanning: Found code splitting" >&2
    fi

    # Check for memoization
    if grep -rqE "(useMemo|useCallback|React\.memo|memo\()" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "memoization" "true"
        score=$((score + 1))
    fi

    # Check for image optimization
    if grep -rqE "(next/image|Image|srcSet|lazy.*load|loading=\"lazy\")" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.vue" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "image_optimization" "true"
        score=$((score + 1))
    fi

    # Check for SSR/SSG
    if grep -rqE "(getServerSideProps|getStaticProps|getStaticPaths|generateStaticParams)" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.ts" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "ssr_ssg" "true"
        score=$((score + 1))
        echo "Scanning: Found SSR/SSG implementation" >&2
    fi

    # Check for service workers
    if find "$CODEBASE_PATH" -name "sw.js" -o -name "service-worker.js" -o -name "serviceWorker.ts" \
        ! -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
        log_metric "service_worker" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Accessibility (Parameter 272)
# =============================================================================
check_accessibility() {
    progress_step "Accessibility (a11y)"
    local score=5

    # Check for ARIA attributes
    local aria_count=$(grep -rcE "(aria-|role=|tabIndex|tabindex)" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.html" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
        awk -F: '{sum += $2} END {print sum+0}')
    
    log_metric "aria_attributes" "$aria_count"
    echo "Scanning: Found $aria_count ARIA attributes" >&2

    if [ "$aria_count" -gt 50 ]; then
        score=8
    elif [ "$aria_count" -gt 20 ]; then
        score=7
    elif [ "$aria_count" -lt 5 ]; then
        add_finding "medium" "accessibility" "Very few ARIA attributes found"
    fi

    # Check for a11y testing tools
    if grep -rqE "(jest-axe|@axe-core|cypress-axe|pa11y|lighthouse)" "$CODEBASE_PATH" \
        --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "a11y_testing" "true"
        score=$((score + 1))
    fi

    # Check for alt text patterns
    if grep -rcE "alt=" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" \
        --exclude-dir=node_modules 2>/dev/null | \
        awk -F: '{sum += $2} END {if(sum > 10) exit 0; else exit 1}'; then
        log_metric "alt_text_usage" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Forms & Error Handling (Parameters 298-300)
# =============================================================================
check_forms_errors() {
    progress_step "Forms and error handling"
    local score=5

    # Check for form libraries
    if grep -rqE "(react-hook-form|formik|final-form|vee-validate)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.tsx" --include="*.ts" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "form_library" "true"
        score=$((score + 2))
        echo "Scanning: Found form library" >&2
    fi

    # Check for error boundaries
    if grep -rqE "(ErrorBoundary|componentDidCatch|getDerivedStateFromError)" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.ts" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "error_boundaries" "true"
        score=$((score + 1))
    else
        add_finding "medium" "frontend" "No error boundaries found"
    fi

    # Check for loading states
    if grep -rqE "(isLoading|loading|Skeleton|Spinner|CircularProgress)" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.vue" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "loading_states" "true"
        score=$((score + 1))
    fi

    # Check for toast/notification system
    if grep -rqE "(toast|Toast|snackbar|Snackbar|notification|react-toastify)" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "notifications" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# UI/UX Consistency & Theming Check (Design Tokens / Hardcoded Styles)
# =============================================================================
check_uiux_consistency() {
    progress_step "UI/UX consistency & theming"
    local score=5

    local color_pattern='#[0-9a-fA-F]{3,8}\b|rgba?\([^)]*\)|hsla?\([^)]*\)'

    local color_hits=$(grep -R -n -E "$color_pattern" "$CODEBASE_PATH" \
        --include="*.css" --include="*.scss" --include="*.sass" --include="*.less" --include="*.styl" \
        --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" --include="*.vue" --include="*.svelte" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
        --exclude-dir=coverage --exclude-dir=output --exclude-dir=.cto-evaluation 2>/dev/null | head -500)

    local hardcoded_color_count=$(echo "$color_hits" | wc -l | tr -d ' ')
    log_metric "hardcoded_color_instances" "${hardcoded_color_count:-0}"

    local unique_colors=$( (echo "$color_hits" | grep -oE "$color_pattern" || true) | tr '[:upper:]' '[:lower:]' | sort -u | wc -l | tr -d ' ')
    log_metric "unique_colors" "${unique_colors:-0}"

    local color_file_summary=$(echo "$color_hits" | awk -F: '{print $1}' | sort | uniq -c | sort -nr | head -5 | awk '{print $2":"$1}' | tr '\n' ' ' | sed 's/ $//')
    if [ -n "$color_file_summary" ]; then
        log_metric "top_color_files" "$color_file_summary"
    fi

    local inline_style_hits=$(grep -R -n -E "style=\"[^\"]*(color|background|font|border)[^\"]*\"|style=\{[^}]*?(color|background|font|border)[^}]*?\}" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.html" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
        --exclude-dir=coverage --exclude-dir=output --exclude-dir=.cto-evaluation 2>/dev/null | head -300)

    local inline_style_count=$(echo "$inline_style_hits" | wc -l | tr -d ' ')
    log_metric "inline_style_instances" "${inline_style_count:-0}"

    local css_var_defs=$( (grep -R -n -E "--[A-Za-z0-9_-]+\s*:" "$CODEBASE_PATH" \
        --include="*.css" --include="*.scss" --include="*.sass" --include="*.less" --include="*.styl" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
        --exclude-dir=coverage --exclude-dir=output --exclude-dir=.cto-evaluation 2>/dev/null || true) | wc -l | tr -d ' ')
    log_metric "css_variables_defined" "${css_var_defs:-0}"

    local css_var_usage=$( (grep -R -n -E "var\(--[A-Za-z0-9_-]+" "$CODEBASE_PATH" \
        --include="*.css" --include="*.scss" --include="*.sass" --include="*.less" --include="*.styl" \
        --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" --include="*.vue" --include="*.svelte" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
        --exclude-dir=coverage --exclude-dir=output --exclude-dir=.cto-evaluation 2>/dev/null || true) | wc -l | tr -d ' ')
    log_metric "css_variable_usage" "${css_var_usage:-0}"

    local font_hits=$(grep -R -n -E "font-family\s*:\s*[^;]+|fontFamily\s*:\s*['\"][^'\"]+['\"]" "$CODEBASE_PATH" \
        --include="*.css" --include="*.scss" --include="*.sass" --include="*.less" --include="*.styl" \
        --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" --include="*.vue" --include="*.svelte" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
        --exclude-dir=coverage --exclude-dir=output --exclude-dir=.cto-evaluation 2>/dev/null | head -300)
    local hardcoded_font_count=$(echo "$font_hits" | wc -l | tr -d ' ')
    log_metric "hardcoded_font_instances" "${hardcoded_font_count:-0}"

    local font_file_summary=$(echo "$font_hits" | awk -F: '{print $1}' | sort | uniq -c | sort -nr | head -5 | awk '{print $2":"$1}' | tr '\n' ' ' | sed 's/ $//')
    if [ -n "$font_file_summary" ]; then
        log_metric "top_font_files" "$font_file_summary"
    fi

    local has_tokens=false
    if [ -f "$CODEBASE_PATH/tailwind.config.js" ] || [ -f "$CODEBASE_PATH/tailwind.config.ts" ] || \
       [ -f "$CODEBASE_PATH/tokens.json" ] || [ -f "$CODEBASE_PATH/design-tokens.json" ] || \
       [ -f "$CODEBASE_PATH/src/theme.ts" ] || [ -f "$CODEBASE_PATH/src/theme.js" ] || \
       [ -d "$CODEBASE_PATH/src/theme" ] || [ -d "$CODEBASE_PATH/src/styles/tokens" ]; then
        has_tokens=true
    fi

    local theme_provider=false
    if grep -rqE "ThemeProvider|ChakraProvider|MantineProvider|CssVarsProvider|createTheme|theme\s*=|Theme\(" "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" --include="*.vue" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        theme_provider=true
    fi

    log_metric "design_tokens_present" "$has_tokens"
    log_metric "theme_provider_present" "$theme_provider"

    if [ "$css_var_defs" -gt 0 ] || [ "$css_var_usage" -gt 5 ]; then
        score=$((score + 2))
    fi

    if [ "$has_tokens" = true ] || [ "$theme_provider" = true ]; then
        score=$((score + 2))
    fi

    if [ "$hardcoded_color_count" -gt 200 ]; then
        score=$((score - 3))
    elif [ "$hardcoded_color_count" -gt 80 ]; then
        score=$((score - 2))
    elif [ "$hardcoded_color_count" -gt 30 ]; then
        score=$((score - 1))
    fi

    if [ "$hardcoded_font_count" -gt 40 ]; then
        score=$((score - 2))
    elif [ "$hardcoded_font_count" -gt 15 ]; then
        score=$((score - 1))
    fi

    if [ "$inline_style_count" -gt 30 ]; then
        score=$((score - 2))
    elif [ "$inline_style_count" -gt 10 ]; then
        score=$((score - 1))
    fi

    if [ "$hardcoded_color_count" -gt 80 ] && [ "$css_var_usage" -lt 5 ]; then
        add_finding "high" "uiux" "High number of hardcoded colors without design tokens or CSS variables" "${color_file_summary:-"multiple files"}"
    elif [ "$hardcoded_color_count" -gt 30 ]; then
        add_finding "medium" "uiux" "Many hardcoded colors detected; consider centralizing into tokens" "${color_file_summary:-"multiple files"}"
    fi

    if [ "$hardcoded_font_count" -gt 15 ] && [ "$theme_provider" = false ]; then
        add_finding "medium" "uiux" "Hardcoded font declarations detected; consider central font tokens" "${font_file_summary:-"multiple files"}"
    fi

    if [ "$inline_style_count" -gt 10 ]; then
        add_finding "low" "uiux" "Inline styles used in UI components; consider shared styling system" "$(echo "$inline_style_hits" | head -5 | awk -F: '{print $1":"$2}' | tr '\n' ' ' | sed 's/ $//')"
    fi

    if [ "$has_tokens" = false ] && [ "$theme_provider" = false ] && [ "$css_var_defs" -eq 0 ]; then
        add_finding "medium" "uiux" "No design tokens or theming system detected; UI updates may be manual" "-"
    fi

    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Frontend Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local component_score=$(check_component_architecture)
    local state_score=$(check_state_management)
    local perf_score=$(check_performance)
    local a11y_score=$(check_accessibility)
    local forms_score=$(check_forms_errors)
    local uiux_score=$(check_uiux_consistency)

    # Weighted average
    local total_score=$(math_calc "$component_score * 0.18 + $state_score * 0.18 + $perf_score * 0.22 + $a11y_score * 0.17 + $forms_score * 0.10 + $uiux_score * 0.15")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 24')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg cs "$component_score" \
        --arg ss "$state_score" \
        --arg ps "$perf_score" \
        --arg as "$a11y_score" \
        --arg fs "$forms_score" \
        --arg us "$uiux_score" \
        '.subscores = {
            component_architecture: ($cs | tonumber),
            state_management: ($ss | tonumber),
            performance: ($ps | tonumber),
            accessibility: ($as | tonumber),
            forms_errors: ($fs | tonumber),
            uiux_consistency: ($us | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Frontend Score: $total_score/10"
}

main
