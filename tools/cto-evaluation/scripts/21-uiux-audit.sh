#!/bin/bash

# =============================================================================
# WORLD-CLASS UI/UX CONSISTENCY AUDIT (Parameters 469-495)
# =============================================================================
# Comprehensive design system analysis covering:
#   1. Design Tokens & CSS Variables (semantic vs primitive)
#   2. Color System Analysis (palette extraction, near-duplicates, orphans)
#   3. Typography Audit (font scale, line heights, weights)
#   4. Spacing System (8px grid adherence, magic numbers)
#   5. Component Inventory (buttons, inputs, cards, modals)
#   6. Responsive Design (breakpoints, mobile-first detection)
#   7. Animation & Motion (transitions, easing, reduced-motion)
#   8. Accessibility (contrast ratios, focus states, touch targets)
#   9. CSS Architecture (specificity, !important abuse, methodologies)
#  10. Dark Mode Analysis (theme switching, color coverage)
#  11. Z-index & Layering System
#  12. Hierarchical Consistency (global → page → component)
# =============================================================================

set -euo pipefail

CODEBASE_PATH="${1:-}"
OUTPUT_FILE="${2:-}"
RESULTS_DIR="${3:-${TMPDIR:-/tmp}}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/math-utils.sh"

if [ -z "$CODEBASE_PATH" ] || [ ! -d "$CODEBASE_PATH" ]; then
    echo "Usage: $0 <codebase_path> [output_file] [results_dir]" >&2
    exit 1
fi

[ -z "$OUTPUT_FILE" ] && OUTPUT_FILE="$RESULTS_DIR/uiux-audit.json"

# Exclusion patterns
EXCLUDE_PATTERN="node_modules|\.git|dist|build|coverage|\.next|\.nuxt|out|\.cto-evaluation|vendor|\.cache"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Safe grep count for single file
count_in_file() {
    local pattern="$1"
    local file="$2"
    grep -cE "$pattern" "$file" 2>/dev/null | tr -d '[:space:]' || echo "0"
}

# Safe grep count across codebase
count_matches() {
    local pattern="$1"
    local includes="$2"
    local result=$(grep -rE "$pattern" "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist \
        --exclude-dir=build --exclude-dir=coverage 2>/dev/null | wc -l | tr -d '[:space:]')
    echo "${result:-0}"
}

# Extract matches to array
extract_matches() {
    local pattern="$1"
    local includes="$2"
    grep -rohE "$pattern" "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist \
        --exclude-dir=build --exclude-dir=coverage 2>/dev/null | sort | uniq -c | sort -rn
}

# Convert hex to RGB
hex_to_rgb() {
    local hex="${1#\#}"
    [ ${#hex} -eq 3 ] && hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    echo "$r $g $b"
}

# Calculate relative luminance for contrast
get_luminance() {
    local hex="$1"
    local rgb=$(hex_to_rgb "$hex" 2>/dev/null) || echo "128 128 128"
    local r=$(echo "$rgb" | cut -d' ' -f1)
    local g=$(echo "$rgb" | cut -d' ' -f2)
    local b=$(echo "$rgb" | cut -d' ' -f3)
    math_calc "(0.2126 * $r + 0.7152 * $g + 0.0722 * $b) / 255" 4
}

# Calculate contrast ratio between two colors
contrast_ratio() {
    local l1=$(get_luminance "$1")
    local l2=$(get_luminance "$2")
    local lighter=$(echo "$l1 $l2" | awk '{print ($1 > $2) ? $1 : $2}')
    local darker=$(echo "$l1 $l2" | awk '{print ($1 < $2) ? $1 : $2}')
    math_calc "($lighter + 0.05) / ($darker + 0.05)"
}

# =============================================================================
# 1. DESIGN TOKENS & CSS VARIABLES ANALYSIS
# =============================================================================
analyze_design_tokens() {
    echo "  [1/12] Design Tokens & CSS Variables..." >&2
    
    local tokens='{"score": 5, "css_vars": {}, "findings": []}'
    local includes="--include=*.css --include=*.scss --include=*.sass --include=*.less"
    
    # Count CSS variable definitions
    local var_definitions=$(grep -rohE '\-\-[a-zA-Z][a-zA-Z0-9_-]*\s*:' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # Count CSS variable usages
    local var_usages=$(grep -rohE 'var\(\s*--[a-zA-Z][a-zA-Z0-9_-]*' "$CODEBASE_PATH" $includes \
        --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # Extract semantic tokens (--color-*, --spacing-*, --font-*, --radius-*, --shadow-*)
    local semantic_tokens=$(grep -rohE '\-\-(color|spacing|font|radius|shadow|border|size|z)-[a-zA-Z0-9_-]+' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | sort -u | wc -l | tr -d '[:space:]')
    
    # Extract primitive tokens (--blue-500, --gray-100, etc.)
    local primitive_tokens=$(grep -rohE '\-\-(red|blue|green|yellow|gray|grey|black|white|orange|purple|pink|cyan|teal)-[0-9]+' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | sort -u | wc -l | tr -d '[:space:]')
    
    # Check for :root definitions
    local root_vars=$(grep -c ':root' "$CODEBASE_PATH"/**/*.css 2>/dev/null | awk -F: '{sum+=$2} END{print sum+0}')
    
    # Check for theme files
    local has_theme_file=false
    [ -f "$CODEBASE_PATH/src/theme.ts" ] || [ -f "$CODEBASE_PATH/src/theme.js" ] || \
    [ -f "$CODEBASE_PATH/src/styles/theme.ts" ] || [ -f "$CODEBASE_PATH/theme/index.ts" ] || \
    [ -f "$CODEBASE_PATH/tailwind.config.js" ] || [ -f "$CODEBASE_PATH/tailwind.config.ts" ] && has_theme_file=true
    
    # Score calculation
    local score=3
    [ "$var_definitions" -gt 20 ] && score=$((score + 2))
    [ "$var_definitions" -gt 50 ] && score=$((score + 1))
    [ "$semantic_tokens" -gt 10 ] && score=$((score + 2))
    [ "$has_theme_file" = true ] && score=$((score + 1))
    [ "$var_usages" -gt "$var_definitions" ] && score=$((score + 1))  # Good usage ratio
    
    local findings='[]'
    [ "$var_definitions" -lt 10 ] && findings=$(echo "$findings" | jq '. + ["Few CSS variables defined - consider creating a token system"]')
    [ "$semantic_tokens" -lt 5 ] && [ "$var_definitions" -gt 0 ] && findings=$(echo "$findings" | jq '. + ["Missing semantic tokens (--color-primary, --spacing-md) - using primitive values directly"]')
    [ "$has_theme_file" = false ] && findings=$(echo "$findings" | jq '. + ["No centralized theme file detected"]')
    
    [ "$score" -gt 10 ] && score=10
    
    tokens=$(jq -n \
        --argjson score "$score" \
        --argjson definitions "${var_definitions:-0}" \
        --argjson usages "${var_usages:-0}" \
        --argjson semantic "${semantic_tokens:-0}" \
        --argjson primitive "${primitive_tokens:-0}" \
        --argjson root_vars "${root_vars:-0}" \
        --argjson has_theme "$has_theme_file" \
        --argjson findings "$findings" \
        '{score: $score, definitions: $definitions, usages: $usages, semantic_tokens: $semantic, primitive_tokens: $primitive, root_definitions: $root_vars, has_theme_file: $has_theme, findings: $findings}')
    
    echo "$tokens"
}

# =============================================================================
# 2. COLOR SYSTEM ANALYSIS
# =============================================================================
analyze_color_system() {
    echo "  [2/12] Color System Analysis..." >&2
    
    local includes="--include=*.css --include=*.scss --include=*.tsx --include=*.jsx --include=*.ts --include=*.js --include=*.vue --include=*.svelte"
    
    # Extract all hex colors
    local hex_colors=$(grep -rohE '#[0-9a-fA-F]{3,8}\b' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist 2>/dev/null | \
        tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -rn)
    
    local total_hex=$(echo "$hex_colors" | wc -l | tr -d '[:space:]')
    local unique_hex=$(echo "$hex_colors" | awk '{print $2}' | sort -u | wc -l | tr -d '[:space:]')
    
    # Extract rgba/hsla colors
    local rgba_count=$(count_matches 'rgba?\([^)]+\)' "$includes")
    local hsla_count=$(count_matches 'hsla?\([^)]+\)' "$includes")
    
    # Find near-duplicate colors (colors that are very similar)
    local near_duplicates='[]'
    local color_list=$(echo "$hex_colors" | awk '{print $2}' | head -50)
    
    # Categorize colors
    local grays=0 primary_candidates=0 semantic_colors=0
    while IFS= read -r color; do
        [ -z "$color" ] && continue
        local rgb=$(hex_to_rgb "$color" 2>/dev/null) || continue
        local r=$(echo "$rgb" | cut -d' ' -f1)
        local g=$(echo "$rgb" | cut -d' ' -f2)
        local b=$(echo "$rgb" | cut -d' ' -f3)
        
        # Check if grayscale (r ≈ g ≈ b)
        local diff_rg=$((r > g ? r - g : g - r))
        local diff_rb=$((r > b ? r - b : b - r))
        [ "$diff_rg" -lt 15 ] && [ "$diff_rb" -lt 15 ] && grays=$((grays + 1))
        
        # Check for semantic colors (red/green/blue dominant)
        [ "$r" -gt 180 ] && [ "$g" -lt 100 ] && [ "$b" -lt 100 ] && semantic_colors=$((semantic_colors + 1))  # Red
        [ "$g" -gt 150 ] && [ "$r" -lt 100 ] && [ "$b" -lt 100 ] && semantic_colors=$((semantic_colors + 1))  # Green
    done <<< "$color_list"
    
    # Find colors used only once (orphan colors)
    local orphan_colors=$(echo "$hex_colors" | awk '$1 == 1 {print $2}' | wc -l | tr -d '[:space:]')
    
    # Check for Tailwind/utility class color usage
    local tailwind_colors=$(count_matches '(bg|text|border|fill|stroke)-(red|blue|green|yellow|gray|slate|zinc|neutral|stone|orange|amber|lime|emerald|teal|cyan|sky|indigo|violet|purple|fuchsia|pink|rose)-[0-9]+' "$includes")
    
    # Top 10 most used colors
    local top_colors=$(echo "$hex_colors" | head -10 | awk '{printf "{\"color\": \"%s\", \"count\": %d},", $2, $1}' | sed 's/,$//')
    [ -n "$top_colors" ] && top_colors="[$top_colors]" || top_colors="[]"
    
    # Score calculation
    local score=5
    [ "$unique_hex" -lt 30 ] && score=$((score + 2))  # Good: limited palette
    [ "$unique_hex" -gt 100 ] && score=$((score - 2)) # Bad: too many colors
    [ "$orphan_colors" -lt 10 ] && score=$((score + 1))
    [ "$orphan_colors" -gt 30 ] && score=$((score - 1))
    [ "$tailwind_colors" -gt 50 ] && score=$((score + 1))  # Using design system
    
    local findings='[]'
    [ "$unique_hex" -gt 50 ] && findings=$(echo "$findings" | jq --arg c "$unique_hex" '. + ["Color sprawl detected: " + $c + " unique colors - consolidate to a palette"]')
    [ "$orphan_colors" -gt 20 ] && findings=$(echo "$findings" | jq --arg c "$orphan_colors" '. + [$c + " orphan colors (used once) - consider removing or adding to palette"]')
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson total "${total_hex:-0}" \
        --argjson unique "${unique_hex:-0}" \
        --argjson rgba "${rgba_count:-0}" \
        --argjson hsla "${hsla_count:-0}" \
        --argjson grays "${grays:-0}" \
        --argjson orphans "${orphan_colors:-0}" \
        --argjson tailwind "${tailwind_colors:-0}" \
        --argjson top_colors "$top_colors" \
        --argjson findings "$findings" \
        '{score: $score, total_color_instances: $total, unique_colors: $unique, rgba_colors: $rgba, hsla_colors: $hsla, grayscale_colors: $grays, orphan_colors: $orphans, tailwind_utility_colors: $tailwind, top_10_colors: $top_colors, findings: $findings}'
}

# =============================================================================
# 3. TYPOGRAPHY AUDIT
# =============================================================================
analyze_typography() {
    echo "  [3/12] Typography Audit..." >&2
    
    local includes="--include=*.css --include=*.scss --include=*.tsx --include=*.jsx --include=*.ts --include=*.js"
    
    # Font families
    local font_families=$(grep -rohE "font-family\s*:\s*[^;]+" "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
        sed 's/font-family\s*:\s*//' | sort | uniq -c | sort -rn | head -10)
    local unique_font_families=$(echo "$font_families" | wc -l | tr -d '[:space:]')
    
    # Font sizes - extract all
    local font_sizes=$(grep -rohE 'font-size\s*:\s*[0-9]+(\.[0-9]+)?(px|rem|em|pt|vw|vh|%)' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
        sed 's/font-size\s*:\s*//' | sort | uniq -c | sort -rn)
    local unique_font_sizes=$(echo "$font_sizes" | awk '{print $2}' | sort -u | wc -l | tr -d '[:space:]')
    
    # Check for rem usage (good practice)
    local rem_sizes=$(echo "$font_sizes" | grep -c 'rem' || echo "0")
    local px_sizes=$(echo "$font_sizes" | grep -c 'px' || echo "0")
    
    # Line heights
    local line_heights=$(grep -rohE 'line-height\s*:\s*[0-9]+(\.[0-9]+)?(px|rem|em|%|)' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # Font weights
    local font_weights=$(grep -rohE 'font-weight\s*:\s*(normal|bold|bolder|lighter|[1-9]00)' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
        sed 's/font-weight\s*:\s*//' | sort | uniq -c | sort -rn)
    local unique_weights=$(echo "$font_weights" | wc -l | tr -d '[:space:]')
    
    # Check for typography scale (common ratios: 1.125, 1.2, 1.25, 1.333, 1.5)
    local has_type_scale=false
    if grep -rqE 'text-(xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl)' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null; then
        has_type_scale=true
    fi
    
    # Check for clamp() usage (responsive typography)
    local clamp_usage=$(count_matches 'clamp\(' "$includes")
    
    # Format top fonts for JSON
    local top_fonts=$(echo "$font_families" | head -5 | awk '{gsub(/"/, "\\\""); printf "{\"family\": \"%s\", \"count\": %d},", substr($0, index($0,$2)), $1}' | sed 's/,$//')
    [ -n "$top_fonts" ] && top_fonts="[$top_fonts]" || top_fonts="[]"
    
    # Score calculation
    local score=5
    [ "$unique_font_families" -le 3 ] && score=$((score + 2))
    [ "$unique_font_families" -gt 5 ] && score=$((score - 1))
    [ "$unique_font_sizes" -le 10 ] && score=$((score + 1))
    [ "$unique_font_sizes" -gt 20 ] && score=$((score - 1))
    [ "$rem_sizes" -gt "$px_sizes" ] && score=$((score + 1))
    [ "$has_type_scale" = true ] && score=$((score + 1))
    [ "$clamp_usage" -gt 0 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$unique_font_families" -gt 4 ] && findings=$(echo "$findings" | jq --arg c "$unique_font_families" '. + [$c + " font families detected - consider limiting to 2-3"]')
    [ "$unique_font_sizes" -gt 15 ] && findings=$(echo "$findings" | jq --arg c "$unique_font_sizes" '. + [$c + " unique font sizes - implement a type scale"]')
    [ "$rem_sizes" -lt "$px_sizes" ] && findings=$(echo "$findings" | jq '. + ["More px than rem font sizes - prefer rem for accessibility"]')
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson families "${unique_font_families:-0}" \
        --argjson sizes "${unique_font_sizes:-0}" \
        --argjson rem "${rem_sizes:-0}" \
        --argjson px "${px_sizes:-0}" \
        --argjson weights "${unique_weights:-0}" \
        --argjson line_heights "${line_heights:-0}" \
        --argjson has_scale "$has_type_scale" \
        --argjson clamp "${clamp_usage:-0}" \
        --argjson top_fonts "$top_fonts" \
        --argjson findings "$findings" \
        '{score: $score, unique_font_families: $families, unique_font_sizes: $sizes, rem_sizes: $rem, px_sizes: $px, font_weights: $weights, line_height_declarations: $line_heights, has_type_scale: $has_scale, responsive_clamp: $clamp, top_fonts: $top_fonts, findings: $findings}'
}

# =============================================================================
# 4. SPACING SYSTEM ANALYSIS
# =============================================================================
analyze_spacing() {
    echo "  [4/12] Spacing System..." >&2
    
    local includes="--include=*.css --include=*.scss --include=*.tsx --include=*.jsx"
    
    # Extract all spacing values (margin, padding, gap)
    local spacing_values=$(grep -rohE '(margin|padding|gap)\s*:\s*[0-9]+(\.[0-9]+)?(px|rem|em)' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
        grep -oE '[0-9]+(\.[0-9]+)?(px|rem|em)' | sort | uniq -c | sort -rn)
    
    # Count values that follow 4px/8px grid
    local grid_aligned=0
    local non_aligned=0
    local magic_numbers='[]'
    
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local count=$(echo "$line" | awk '{print $1}')
        local value=$(echo "$line" | awk '{print $2}')
        local num=$(echo "$value" | grep -oE '[0-9]+(\.[0-9]+)?')
        
        # Check if divisible by 4 (8px grid system)
        if echo "$value" | grep -q 'px'; then
            local int_val=$(echo "$num" | cut -d. -f1)
            if [ $((int_val % 4)) -eq 0 ]; then
                grid_aligned=$((grid_aligned + count))
            else
                non_aligned=$((non_aligned + count))
                [ "$count" -gt 2 ] && magic_numbers=$(echo "$magic_numbers" | jq --arg v "$value" --arg c "$count" '. + [$v + " (used " + $c + "x)"]')
            fi
        fi
    done <<< "$spacing_values"
    
    # Check for spacing tokens/utilities
    local spacing_tokens=$(count_matches '\-\-spacing-[a-zA-Z0-9_-]+' "$includes")
    local tailwind_spacing=$(count_matches '(p|m|gap|space)-(x|y|t|r|b|l)?-?[0-9]+' "$includes")
    
    # Unique spacing values count
    local unique_spacing=$(echo "$spacing_values" | wc -l | tr -d '[:space:]')
    
    # Score calculation
    local total_spacing=$((grid_aligned + non_aligned))
    local score=5
    
    if [ "$total_spacing" -gt 0 ]; then
        local alignment_ratio=$(math_calc "$grid_aligned / $total_spacing")
        math_compare "$alignment_ratio" ">" "0.8" && score=$((score + 2))
        math_compare "$alignment_ratio" "<" "0.5" && score=$((score - 1))
    fi
    
    [ "$spacing_tokens" -gt 10 ] && score=$((score + 1))
    [ "$tailwind_spacing" -gt 50 ] && score=$((score + 1))
    [ "$unique_spacing" -lt 20 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$non_aligned" -gt "$grid_aligned" ] && findings=$(echo "$findings" | jq '. + ["Spacing values not aligned to 4px/8px grid - inconsistent spacing system"]')
    [ "$unique_spacing" -gt 30 ] && findings=$(echo "$findings" | jq --arg c "$unique_spacing" '. + [$c + " unique spacing values - implement spacing tokens"]')
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson grid_aligned "${grid_aligned:-0}" \
        --argjson non_aligned "${non_aligned:-0}" \
        --argjson unique "${unique_spacing:-0}" \
        --argjson tokens "${spacing_tokens:-0}" \
        --argjson tailwind "${tailwind_spacing:-0}" \
        --argjson magic_numbers "$magic_numbers" \
        --argjson findings "$findings" \
        '{score: $score, grid_aligned_values: $grid_aligned, non_grid_values: $non_aligned, unique_spacing_values: $unique, spacing_tokens: $tokens, tailwind_spacing_classes: $tailwind, magic_numbers: $magic_numbers, findings: $findings}'
}

# =============================================================================
# 5. COMPONENT INVENTORY
# =============================================================================
analyze_components() {
    echo "  [5/12] Component Inventory..." >&2
    
    local components='{}'
    
    # Button analysis
    local button_files=$(grep -rlE 'Button|<button|btn' "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.vue" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    local button_variants=$(grep -rohE '(variant|type|size)=["\x27][^"\x27]+["\x27]' "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | sort -u | wc -l | tr -d '[:space:]')
    
    # Input/Form analysis
    local input_files=$(grep -rlE 'Input|<input|TextField|FormControl' "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.vue" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # Card analysis
    local card_files=$(grep -rlE 'Card|<card|CardContent|CardHeader' "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.vue" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # Modal/Dialog analysis
    local modal_files=$(grep -rlE 'Modal|Dialog|Popup|Drawer|Sheet' "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.vue" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # Navigation analysis
    local nav_files=$(grep -rlE 'Nav|Menu|Sidebar|Header|Footer|Breadcrumb' "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --include="*.vue" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # Check for component library usage
    local has_ui_lib=false
    local ui_lib="none"
    if grep -rqE '@mui/material|@chakra-ui|@mantine|@radix-ui|shadcn|antd|@headlessui' "$CODEBASE_PATH" --include="*.json" --exclude-dir=node_modules 2>/dev/null; then
        has_ui_lib=true
        grep -oE '@mui/material|@chakra-ui|@mantine|@radix-ui|shadcn|antd|@headlessui' "$CODEBASE_PATH/package.json" 2>/dev/null | head -1 | read ui_lib || ui_lib="detected"
    fi
    
    # Check for Storybook
    local has_storybook=false
    [ -d "$CODEBASE_PATH/.storybook" ] || [ -f "$CODEBASE_PATH/storybook.config.js" ] && has_storybook=true
    
    # Score calculation
    local total_components=$((button_files + input_files + card_files + modal_files + nav_files))
    local score=5
    [ "$total_components" -gt 20 ] && score=$((score + 1))
    [ "$has_ui_lib" = true ] && score=$((score + 2))
    [ "$has_storybook" = true ] && score=$((score + 2))
    
    local findings='[]'
    [ "$has_ui_lib" = false ] && [ "$total_components" -gt 30 ] && findings=$(echo "$findings" | jq '. + ["Many custom components but no UI library - consider adopting one for consistency"]')
    [ "$has_storybook" = false ] && [ "$total_components" -gt 20 ] && findings=$(echo "$findings" | jq '. + ["No Storybook detected - component documentation would improve DX"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson buttons "${button_files:-0}" \
        --argjson button_variants "${button_variants:-0}" \
        --argjson inputs "${input_files:-0}" \
        --argjson cards "${card_files:-0}" \
        --argjson modals "${modal_files:-0}" \
        --argjson navigation "${nav_files:-0}" \
        --argjson has_ui_lib "$has_ui_lib" \
        --arg ui_lib "$ui_lib" \
        --argjson has_storybook "$has_storybook" \
        --argjson findings "$findings" \
        '{score: $score, buttons: {files: $buttons, variants: $button_variants}, inputs: $inputs, cards: $cards, modals: $modals, navigation: $navigation, ui_library: {detected: $has_ui_lib, name: $ui_lib}, storybook: $has_storybook, findings: $findings}'
}

# =============================================================================
# 6. RESPONSIVE DESIGN ANALYSIS
# =============================================================================
analyze_responsive() {
    echo "  [6/12] Responsive Design..." >&2
    
    local includes="--include=*.css --include=*.scss --include=*.tsx --include=*.jsx"
    
    # Extract media query breakpoints
    local breakpoints=$(grep -rohE '@media[^{]+' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
        grep -oE '[0-9]+(px|em|rem)' | sort | uniq -c | sort -rn)
    local unique_breakpoints=$(echo "$breakpoints" | wc -l | tr -d '[:space:]')
    
    # Check for mobile-first (min-width) vs desktop-first (max-width)
    local min_width_queries=$(count_matches 'min-width\s*:' "$includes")
    local max_width_queries=$(count_matches 'max-width\s*:' "$includes")
    
    local approach="mixed"
    [ "$min_width_queries" -gt $((max_width_queries * 2)) ] && approach="mobile-first"
    [ "$max_width_queries" -gt $((min_width_queries * 2)) ] && approach="desktop-first"
    
    # Check for container queries (modern CSS)
    local container_queries=$(count_matches '@container' "$includes")
    
    # Check for viewport units
    local vw_usage=$(count_matches '[0-9]+vw' "$includes")
    local vh_usage=$(count_matches '[0-9]+vh' "$includes")
    local dvh_usage=$(count_matches '[0-9]+dvh' "$includes")
    
    # Check for Tailwind responsive prefixes
    local tailwind_responsive=$(count_matches '(sm|md|lg|xl|2xl):' "$includes")
    
    # Check for aspect-ratio
    local aspect_ratio=$(count_matches 'aspect-ratio' "$includes")
    
    # Common breakpoints check (standard: 640, 768, 1024, 1280, 1536)
    local standard_breakpoints=0
    echo "$breakpoints" | grep -qE '(640|768|1024|1280|1536)px' && standard_breakpoints=$((standard_breakpoints + 1))
    
    # Score calculation
    local score=5
    [ "$unique_breakpoints" -ge 3 ] && [ "$unique_breakpoints" -le 6 ] && score=$((score + 2))
    [ "$approach" = "mobile-first" ] && score=$((score + 1))
    [ "$container_queries" -gt 0 ] && score=$((score + 1))
    [ "$tailwind_responsive" -gt 20 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$unique_breakpoints" -gt 8 ] && findings=$(echo "$findings" | jq --arg c "$unique_breakpoints" '. + [$c + " breakpoints detected - standardize to 4-6 breakpoints"]')
    [ "$approach" = "desktop-first" ] && findings=$(echo "$findings" | jq '. + ["Desktop-first approach detected - consider mobile-first for better progressive enhancement"]')
    [ "$unique_breakpoints" -lt 2 ] && findings=$(echo "$findings" | jq '. + ["Few breakpoints - responsive design may be limited"]')
    
    [ "$score" -gt 10 ] && score=10
    
    # Format breakpoints for JSON
    local bp_json=$(echo "$breakpoints" | head -6 | awk '{printf "{\"breakpoint\": \"%s\", \"count\": %d},", $2, $1}' | sed 's/,$//')
    [ -n "$bp_json" ] && bp_json="[$bp_json]" || bp_json="[]"
    
    jq -n \
        --argjson score "$score" \
        --argjson unique_bp "${unique_breakpoints:-0}" \
        --arg approach "$approach" \
        --argjson min_width "${min_width_queries:-0}" \
        --argjson max_width "${max_width_queries:-0}" \
        --argjson container "${container_queries:-0}" \
        --argjson vw "${vw_usage:-0}" \
        --argjson vh "${vh_usage:-0}" \
        --argjson dvh "${dvh_usage:-0}" \
        --argjson tailwind "${tailwind_responsive:-0}" \
        --argjson aspect "${aspect_ratio:-0}" \
        --argjson breakpoints "$bp_json" \
        --argjson findings "$findings" \
        '{score: $score, unique_breakpoints: $unique_bp, approach: $approach, min_width_queries: $min_width, max_width_queries: $max_width, container_queries: $container, viewport_units: {vw: $vw, vh: $vh, dvh: $dvh}, tailwind_responsive: $tailwind, aspect_ratio_usage: $aspect, breakpoints: $breakpoints, findings: $findings}'
}

# =============================================================================
# 7. ANIMATION & MOTION ANALYSIS
# =============================================================================
analyze_motion() {
    echo "  [7/12] Animation & Motion..." >&2
    
    local includes="--include=*.css --include=*.scss --include=*.tsx --include=*.jsx"
    
    # Transition analysis
    local transitions=$(grep -rohE 'transition\s*:[^;]+' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null)
    local transition_count=$(echo "$transitions" | grep -c 'transition' || echo "0")
    
    # Extract transition durations
    local durations=$(echo "$transitions" | grep -oE '[0-9]+(\.[0-9]+)?(ms|s)' | sort | uniq -c | sort -rn)
    local unique_durations=$(echo "$durations" | wc -l | tr -d '[:space:]')
    
    # Animation keyframes
    local keyframes=$(count_matches '@keyframes' "$includes")
    
    # Check for animation library
    local has_framer=false
    local has_gsap=false
    local has_anime=false
    grep -rqE 'framer-motion|motion' "$CODEBASE_PATH" --include="*.json" --exclude-dir=node_modules 2>/dev/null && has_framer=true
    grep -rqE '"gsap"' "$CODEBASE_PATH" --include="*.json" --exclude-dir=node_modules 2>/dev/null && has_gsap=true
    grep -rqE '"animejs"|"anime"' "$CODEBASE_PATH" --include="*.json" --exclude-dir=node_modules 2>/dev/null && has_anime=true
    
    # Easing functions
    local ease_in_out=$(count_matches 'ease-in-out' "$includes")
    local ease_linear=$(count_matches 'linear' "$includes")
    local cubic_bezier=$(count_matches 'cubic-bezier' "$includes")
    
    # Check for reduced-motion support (accessibility)
    local reduced_motion=$(count_matches 'prefers-reduced-motion' "$includes")
    
    # Check for will-change (performance)
    local will_change=$(count_matches 'will-change' "$includes")
    
    # Score calculation
    local score=5
    [ "$transition_count" -gt 10 ] && score=$((score + 1))
    [ "$reduced_motion" -gt 0 ] && score=$((score + 2))  # Accessibility is important
    [ "$has_framer" = true ] || [ "$has_gsap" = true ] && score=$((score + 1))
    [ "$unique_durations" -le 5 ] && score=$((score + 1))  # Consistent timing
    
    local findings='[]'
    [ "$reduced_motion" -eq 0 ] && [ "$transition_count" -gt 20 ] && findings=$(echo "$findings" | jq '. + ["No prefers-reduced-motion support - accessibility issue for motion-sensitive users"]')
    [ "$unique_durations" -gt 10 ] && findings=$(echo "$findings" | jq '. + ["Many different transition durations - consider standardizing to 2-4 values"]')
    [ "$will_change" -gt 20 ] && findings=$(echo "$findings" | jq '. + ["Excessive will-change usage - can cause performance issues"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson transitions "${transition_count:-0}" \
        --argjson unique_durations "${unique_durations:-0}" \
        --argjson keyframes "${keyframes:-0}" \
        --argjson framer "$has_framer" \
        --argjson gsap "$has_gsap" \
        --argjson reduced_motion "${reduced_motion:-0}" \
        --argjson will_change "${will_change:-0}" \
        --argjson cubic_bezier "${cubic_bezier:-0}" \
        --argjson findings "$findings" \
        '{score: $score, transitions: $transitions, unique_durations: $unique_durations, keyframes: $keyframes, animation_libraries: {framer_motion: $framer, gsap: $gsap}, reduced_motion_support: $reduced_motion, will_change_usage: $will_change, custom_easing: $cubic_bezier, findings: $findings}'
}

# =============================================================================
# 8. ACCESSIBILITY ANALYSIS
# =============================================================================
analyze_accessibility() {
    echo "  [8/12] Accessibility..." >&2
    
    local includes="--include=*.tsx --include=*.jsx --include=*.vue --include=*.html"
    local css_includes="--include=*.css --include=*.scss"
    
    # ARIA attributes
    local aria_count=$(count_matches 'aria-[a-z]+=' "$includes")
    local role_count=$(count_matches 'role=' "$includes")
    
    # Focus styles
    local focus_visible=$(count_matches ':focus-visible' "$css_includes")
    local focus_within=$(count_matches ':focus-within' "$css_includes")
    local outline_none=$(count_matches 'outline:\s*none|outline:\s*0' "$css_includes")
    
    # Semantic HTML
    local semantic_tags=$(count_matches '<(main|nav|header|footer|article|section|aside|figure|figcaption)' "$includes")
    
    # Alt text
    local img_tags=$(count_matches '<img' "$includes")
    local alt_attrs=$(count_matches 'alt=' "$includes")
    
    # Labels for inputs
    local label_tags=$(count_matches '<label' "$includes")
    local aria_label=$(count_matches 'aria-label=' "$includes")
    local aria_labelledby=$(count_matches 'aria-labelledby=' "$includes")
    
    # Skip links
    local skip_links=$(count_matches 'skip-to-|skip-link|skipLink|SkipNav' "$includes")
    
    # Touch target sizes (min 44px recommended)
    local small_touch_targets=$(grep -rohE '(width|height|min-width|min-height)\s*:\s*[0-3][0-9]?px' "$CODEBASE_PATH" $css_includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # Color contrast (check for problematic light grays on white)
    local light_gray_text=$(grep -cE 'color:\s*#[cdefCDEF][0-9a-fA-F]{5}' "$CODEBASE_PATH"/**/*.css 2>/dev/null | awk -F: '{sum+=$2} END{print sum+0}')
    
    # Screen reader only classes
    local sr_only=$(count_matches 'sr-only|visually-hidden|screen-reader' "$includes $css_includes")
    
    # Tab index usage
    local tabindex=$(count_matches 'tabindex|tabIndex' "$includes")
    
    # Score calculation
    local score=5
    [ "$aria_count" -gt 20 ] && score=$((score + 1))
    [ "$semantic_tags" -gt 10 ] && score=$((score + 1))
    [ "$focus_visible" -gt 0 ] && score=$((score + 1))
    [ "$outline_none" -lt 5 ] && score=$((score + 1))
    [ "$skip_links" -gt 0 ] && score=$((score + 1))
    [ "$sr_only" -gt 0 ] && score=$((score + 1))
    [ "$img_tags" -gt 0 ] && [ "$alt_attrs" -ge "$img_tags" ] && score=$((score + 1))
    
    local findings='[]'
    [ "$aria_count" -lt 10 ] && findings=$(echo "$findings" | jq '. + ["Limited ARIA usage - add aria labels for interactive elements"]')
    [ "$outline_none" -gt 10 ] && findings=$(echo "$findings" | jq --arg c "$outline_none" '. + [$c + " outline:none declarations - ensure custom focus styles exist"]')
    [ "$skip_links" -eq 0 ] && findings=$(echo "$findings" | jq '. + ["No skip links detected - add for keyboard navigation"]')
    [ "$focus_visible" -eq 0 ] && findings=$(echo "$findings" | jq '. + ["No :focus-visible usage - modern focus styling recommended"]')
    [ "$semantic_tags" -lt 5 ] && findings=$(echo "$findings" | jq '. + ["Limited semantic HTML - use <main>, <nav>, <section>, etc."]')
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson aria "${aria_count:-0}" \
        --argjson roles "${role_count:-0}" \
        --argjson focus_visible "${focus_visible:-0}" \
        --argjson outline_none "${outline_none:-0}" \
        --argjson semantic "${semantic_tags:-0}" \
        --argjson images "${img_tags:-0}" \
        --argjson alt "${alt_attrs:-0}" \
        --argjson labels "${label_tags:-0}" \
        --argjson skip_links "${skip_links:-0}" \
        --argjson sr_only "${sr_only:-0}" \
        --argjson tabindex "${tabindex:-0}" \
        --argjson findings "$findings" \
        '{score: $score, aria_attributes: $aria, role_attributes: $roles, focus_visible: $focus_visible, outline_none_removal: $outline_none, semantic_html: $semantic, images: $images, alt_attributes: $alt, labels: $labels, skip_links: $skip_links, screen_reader_text: $sr_only, tabindex_usage: $tabindex, findings: $findings}'
}

# =============================================================================
# 9. CSS ARCHITECTURE ANALYSIS
# =============================================================================
analyze_css_architecture() {
    echo "  [9/12] CSS Architecture..." >&2
    
    local includes="--include=*.css --include=*.scss --include=*.sass --include=*.less"
    
    # !important usage (code smell)
    local important_count=$(count_matches '!important' "$includes")
    
    # Deep nesting (more than 3 levels in SCSS)
    local deep_nesting=$(grep -rohE '^\s{12,}[a-z]' "$CODEBASE_PATH" --include="*.scss" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # ID selectors (high specificity)
    local id_selectors=$(count_matches '#[a-zA-Z][a-zA-Z0-9_-]*\s*\{' "$includes")
    
    # Inline styles in JSX
    local inline_styles=$(count_matches 'style=\{' "--include=*.tsx --include=*.jsx")
    
    # CSS Modules usage
    local css_modules=$(find "$CODEBASE_PATH" -name "*.module.css" -o -name "*.module.scss" \
        ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # Styled Components / Emotion
    local styled_components=$(count_matches 'styled\.|css\`|styled\(' "--include=*.tsx --include=*.jsx --include=*.ts")
    
    # Tailwind usage
    local tailwind_classes=$(count_matches 'className="[^"]*\b(flex|grid|p-|m-|text-|bg-|border-)' "--include=*.tsx --include=*.jsx")
    
    # BEM-like naming
    local bem_classes=$(count_matches '\.[a-z]+__[a-z]+|\.{a-z]+--[a-z]+' "$includes")
    
    # Determine primary methodology
    local methodology="traditional"
    [ "$tailwind_classes" -gt 100 ] && methodology="utility-first"
    [ "$styled_components" -gt 50 ] && methodology="css-in-js"
    [ "$css_modules" -gt 10 ] && methodology="css-modules"
    [ "$bem_classes" -gt 50 ] && methodology="BEM"
    
    # Calculate total CSS files
    local css_files=$(find "$CODEBASE_PATH" -type f \( -name "*.css" -o -name "*.scss" -o -name "*.sass" -o -name "*.less" \) \
        ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # Score calculation
    local score=5
    [ "$important_count" -lt 10 ] && score=$((score + 2))
    [ "$important_count" -gt 50 ] && score=$((score - 2))
    [ "$id_selectors" -lt 5 ] && score=$((score + 1))
    [ "$deep_nesting" -lt 20 ] && score=$((score + 1))
    [ "$css_modules" -gt 0 ] || [ "$styled_components" -gt 0 ] || [ "$tailwind_classes" -gt 50 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$important_count" -gt 20 ] && findings=$(echo "$findings" | jq --arg c "$important_count" '. + [$c + " !important declarations - specificity war indicator"]')
    [ "$id_selectors" -gt 10 ] && findings=$(echo "$findings" | jq --arg c "$id_selectors" '. + [$c + " ID selectors - avoid for styling, use classes"]')
    [ "$inline_styles" -gt 30 ] && findings=$(echo "$findings" | jq --arg c "$inline_styles" '. + [$c + " inline styles - consider extracting to CSS"]')
    [ "$deep_nesting" -gt 50 ] && findings=$(echo "$findings" | jq '. + ["Deep SCSS nesting detected - flatten selectors for maintainability"]')
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --arg methodology "$methodology" \
        --argjson important "${important_count:-0}" \
        --argjson id_selectors "${id_selectors:-0}" \
        --argjson inline "${inline_styles:-0}" \
        --argjson deep_nesting "${deep_nesting:-0}" \
        --argjson css_modules "${css_modules:-0}" \
        --argjson styled "${styled_components:-0}" \
        --argjson tailwind "${tailwind_classes:-0}" \
        --argjson bem "${bem_classes:-0}" \
        --argjson css_files "${css_files:-0}" \
        --argjson findings "$findings" \
        '{score: $score, methodology: $methodology, important_declarations: $important, id_selectors: $id_selectors, inline_styles: $inline, deep_nesting: $deep_nesting, css_modules: $css_modules, styled_components: $styled, tailwind_classes: $tailwind, bem_classes: $bem, total_css_files: $css_files, findings: $findings}'
}

# =============================================================================
# 10. DARK MODE ANALYSIS
# =============================================================================
analyze_dark_mode() {
    echo "  [10/12] Dark Mode..." >&2
    
    local includes="--include=*.css --include=*.scss --include=*.tsx --include=*.jsx --include=*.ts"
    
    # Check for prefers-color-scheme
    local prefers_dark=$(count_matches 'prefers-color-scheme:\s*dark' "$includes")
    local prefers_light=$(count_matches 'prefers-color-scheme:\s*light' "$includes")
    
    # Check for dark mode classes/attributes
    local dark_class=$(count_matches '\.dark\s|\.dark-mode|\.dark-theme|\[data-theme="dark"\]|html\.dark' "$includes")
    
    # Check for theme context/hook
    local theme_context=$(count_matches 'ThemeContext|useTheme|useColorMode|useDarkMode|ColorModeContext' "$includes")
    
    # Check for CSS variables for theming
    local theme_vars=$(grep -rohE '\-\-(light|dark)-[a-zA-Z0-9_-]+|\-\-color-[a-zA-Z]+-dark' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    
    # Check for next-themes or similar
    local theme_library=false
    grep -rqE 'next-themes|use-dark-mode|react-dark-mode|@theme-ui' "$CODEBASE_PATH" --include="*.json" --exclude-dir=node_modules 2>/dev/null && theme_library=true
    
    # Check Tailwind dark mode
    local tailwind_dark=$(count_matches 'dark:' "$includes")
    
    # Determine dark mode implementation
    local implementation="none"
    [ "$prefers_dark" -gt 0 ] && implementation="system-preference"
    [ "$dark_class" -gt 0 ] && implementation="class-based"
    [ "$tailwind_dark" -gt 20 ] && implementation="tailwind-dark"
    [ "$theme_context" -gt 0 ] && implementation="theme-context"
    
    local has_dark_mode=false
    [ "$prefers_dark" -gt 0 ] || [ "$dark_class" -gt 0 ] || [ "$tailwind_dark" -gt 10 ] && has_dark_mode=true
    
    # Score calculation
    local score=5
    [ "$has_dark_mode" = true ] && score=$((score + 2))
    [ "$theme_context" -gt 0 ] && score=$((score + 1))
    [ "$theme_vars" -gt 10 ] && score=$((score + 1))
    [ "$tailwind_dark" -gt 20 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$has_dark_mode" = false ] && findings=$(echo "$findings" | jq '. + ["No dark mode implementation detected - modern apps should support dark mode"]')
    [ "$prefers_dark" -eq 0 ] && [ "$has_dark_mode" = true ] && findings=$(echo "$findings" | jq '. + ["Dark mode exists but no prefers-color-scheme - consider respecting system preference"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson has_dark_mode "$has_dark_mode" \
        --arg implementation "$implementation" \
        --argjson prefers_dark "${prefers_dark:-0}" \
        --argjson dark_class "${dark_class:-0}" \
        --argjson tailwind_dark "${tailwind_dark:-0}" \
        --argjson theme_context "${theme_context:-0}" \
        --argjson theme_vars "${theme_vars:-0}" \
        --argjson theme_library "$theme_library" \
        --argjson findings "$findings" \
        '{score: $score, has_dark_mode: $has_dark_mode, implementation: $implementation, prefers_color_scheme: $prefers_dark, dark_class_selectors: $dark_class, tailwind_dark_classes: $tailwind_dark, theme_context_usage: $theme_context, theme_css_vars: $theme_vars, theme_library: $theme_library, findings: $findings}'
}

# =============================================================================
# 11. Z-INDEX & LAYERING ANALYSIS
# =============================================================================
analyze_zindex() {
    echo "  [11/12] Z-Index & Layering..." >&2
    
    # Extract all z-index values
    local zindex_values=$(grep -rohE 'z-index\s*:\s*-?[0-9]+' "$CODEBASE_PATH" \
        --include="*.css" --include="*.scss" --include="*.tsx" --include="*.jsx" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | \
        grep -oE '\-?[0-9]+$' | sort -n | uniq -c | sort -rn)
    
    local unique_zindex=0
    local max_zindex=0
    local min_zindex=0
    
    if [ -n "$zindex_values" ]; then
        unique_zindex=$(echo "$zindex_values" | wc -l | tr -d '[:space:]' | head -c 10)
        max_zindex=$(echo "$zindex_values" | awk '{print $2}' | sort -n | tail -1 | tr -d '[:space:]' | head -c 10)
        min_zindex=$(echo "$zindex_values" | awk '{print $2}' | sort -n | head -1 | tr -d '[:space:]' | head -c 10)
    fi
    
    # Sanitize - ensure they're single integers
    unique_zindex=$(echo "$unique_zindex" | grep -oE '^[0-9]+' | head -1)
    max_zindex=$(echo "$max_zindex" | grep -oE '^-?[0-9]+' | head -1)
    min_zindex=$(echo "$min_zindex" | grep -oE '^-?[0-9]+' | head -1)
    [ -z "$unique_zindex" ] && unique_zindex=0
    [ -z "$max_zindex" ] && max_zindex=0
    [ -z "$min_zindex" ] && min_zindex=0
    
    # Check for z-index tokens
    local zindex_tokens=$(grep -rohE '\-\-z-[a-zA-Z0-9_-]+' "$CODEBASE_PATH" \
        --include="*.css" --include="*.scss" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    zindex_tokens=$(echo "$zindex_tokens" | grep -oE '^[0-9]+' | head -1)
    [ -z "$zindex_tokens" ] && zindex_tokens=0
    
    # Check for magic numbers (9999, 99999, etc.)
    local magic_zindex=0
    if [ -n "$zindex_values" ]; then
        magic_zindex=$(echo "$zindex_values" | grep -cE '999|1000000' 2>/dev/null || echo "0")
    fi
    magic_zindex=$(echo "$magic_zindex" | grep -oE '^[0-9]+' | head -1)
    [ -z "$magic_zindex" ] && magic_zindex=0
    
    # Tailwind z-index classes
    local tailwind_z=$(grep -rohE 'z-[0-9]+|z-auto' "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    tailwind_z=$(echo "$tailwind_z" | grep -oE '^[0-9]+' | head -1)
    [ -z "$tailwind_z" ] && tailwind_z=0
    
    # Score calculation
    local score=5
    [ "$unique_zindex" -le 10 ] && score=$((score + 2))
    [ "$unique_zindex" -gt 20 ] && score=$((score - 1))
    [ "$magic_zindex" -eq 0 ] && score=$((score + 1))
    [ "$magic_zindex" -gt 3 ] && score=$((score - 1))
    [ "$zindex_tokens" -gt 0 ] && score=$((score + 1))
    [ "$max_zindex" -lt 100 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$unique_zindex" -gt 15 ] && findings=$(echo "$findings" | jq --arg c "$unique_zindex" '. + [$c + " unique z-index values - define a z-index scale"]')
    [ "$magic_zindex" -gt 0 ] && findings=$(echo "$findings" | jq '. + ["Magic z-index values (9999, etc.) detected - use a systematic scale"]')
    [ "$max_zindex" -gt 1000 ] && findings=$(echo "$findings" | jq --arg z "$max_zindex" '. + ["Very high z-index (" + $z + ") - indicates layering issues"]')
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    # Format z-index values for JSON
    local zindex_json="[]"
    if [ -n "$zindex_values" ]; then
        local tmp_json=$(echo "$zindex_values" | head -10 | awk 'NF>=2 {printf "{\"value\": %d, \"count\": %d},", $2, $1}' | sed 's/,$//')
        [ -n "$tmp_json" ] && zindex_json="[$tmp_json]"
    fi
    
    jq -n \
        --argjson score "$score" \
        --argjson unique "$unique_zindex" \
        --argjson max "$max_zindex" \
        --argjson min "$min_zindex" \
        --argjson tokens "$zindex_tokens" \
        --argjson magic "$magic_zindex" \
        --argjson tailwind "$tailwind_z" \
        --argjson values "$zindex_json" \
        --argjson findings "$findings" \
        '{score: $score, unique_values: $unique, max_value: $max, min_value: $min, z_index_tokens: $tokens, magic_numbers: $magic, tailwind_z_classes: $tailwind, top_values: $values, findings: $findings}'
}

# =============================================================================
# 12. HIERARCHICAL CONSISTENCY (Global → Page → Component)
# =============================================================================
analyze_hierarchy() {
    echo "  [12/12] Hierarchical Consistency..." >&2
    
    local hierarchy='{"global": {}, "pages": [], "components": {"consistent": 0, "inconsistent": 0, "issues": []}}'
    
    # Global theme detection
    local global_source="none"
    local global_type="missing"
    
    [ -f "$CODEBASE_PATH/tailwind.config.js" ] || [ -f "$CODEBASE_PATH/tailwind.config.ts" ] && global_source="tailwind" && global_type="utility-framework"
    [ -f "$CODEBASE_PATH/src/theme.ts" ] || [ -f "$CODEBASE_PATH/src/theme.js" ] && global_source="theme-file" && global_type="theme-object"
    [ -f "$CODEBASE_PATH/src/styles/globals.css" ] || [ -f "$CODEBASE_PATH/styles/globals.css" ] && global_source="globals.css" && global_type="css"
    
    # Provider detection
    local provider_file=$(grep -rlE 'ThemeProvider|ChakraProvider|MantineProvider' "$CODEBASE_PATH" \
        --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | head -1)
    local provider_rel="${provider_file#$CODEBASE_PATH/}"
    
    # Page analysis
    local page_files=$(find "$CODEBASE_PATH" -type f \( \
        -path "*/pages/*.tsx" -o -path "*/pages/*.jsx" \
        -o -path "*/app/*/page.tsx" -o -path "*/app/*/page.jsx" \
        -o -path "*/views/*.tsx" -o -path "*/views/*.jsx" \
        \) ! -path "*/node_modules/*" 2>/dev/null | head -20)
    
    local consistent_pages=0
    local inconsistent_pages=0
    local page_issues='[]'
    
    while IFS= read -r page; do
        [ -z "$page" ] || [ ! -f "$page" ] && continue
        local rel_path="${page#$CODEBASE_PATH/}"
        local page_name=$(basename "$page" | sed 's/\.[^.]*$//')
        
        local hardcoded=$(grep -cE '#[0-9a-fA-F]{3,8}\b' "$page" 2>/dev/null | tr -d '[:space:]')
        local css_vars=$(grep -cE 'var\(--' "$page" 2>/dev/null | tr -d '[:space:]')
        local theme_hooks=$(grep -cE 'useTheme|useColorMode|useStyles|styled\(' "$page" 2>/dev/null | tr -d '[:space:]')
        local tailwind=$(grep -cE 'className="[^"]*\b(bg-|text-|border-)' "$page" 2>/dev/null | tr -d '[:space:]')
        
        [ -z "$hardcoded" ] && hardcoded=0
        [ -z "$css_vars" ] && css_vars=0
        [ -z "$theme_hooks" ] && theme_hooks=0
        [ -z "$tailwind" ] && tailwind=0
        
        if [ "$hardcoded" -gt 5 ] && [ "$css_vars" -eq 0 ] && [ "$theme_hooks" -eq 0 ] && [ "$tailwind" -lt 5 ]; then
            inconsistent_pages=$((inconsistent_pages + 1))
            page_issues=$(echo "$page_issues" | jq --arg p "$rel_path" --arg h "$hardcoded" '. + [$p + " (" + $h + " hardcoded colors)"]')
        else
            consistent_pages=$((consistent_pages + 1))
        fi
    done <<< "$page_files"
    
    # Component analysis summary
    local component_files=$(find "$CODEBASE_PATH" -type f \( -name "*.tsx" -o -name "*.jsx" \) \
        -path "*/components/*" ! -path "*/node_modules/*" 2>/dev/null | head -50)
    
    local comp_consistent=0
    local comp_inconsistent=0
    local comp_issues='[]'
    
    while IFS= read -r comp; do
        [ -z "$comp" ] || [ ! -f "$comp" ] && continue
        local rel_path="${comp#$CODEBASE_PATH/}"
        
        local hardcoded=$(grep -cE '#[0-9a-fA-F]{3,8}\b' "$comp" 2>/dev/null | tr -d '[:space:]')
        [ -z "$hardcoded" ] && hardcoded=0
        
        if [ "$hardcoded" -gt 3 ]; then
            comp_inconsistent=$((comp_inconsistent + 1))
            comp_issues=$(echo "$comp_issues" | jq --arg p "$rel_path" '. + [$p]')
        else
            comp_consistent=$((comp_consistent + 1))
        fi
    done <<< "$component_files"
    
    # Score calculation
    local total_pages=$((consistent_pages + inconsistent_pages))
    local total_components=$((comp_consistent + comp_inconsistent))
    local score=5
    
    [ "$global_type" != "missing" ] && score=$((score + 2))
    [ -n "$provider_file" ] && score=$((score + 1))
    
    if [ "$total_pages" -gt 0 ]; then
        local page_ratio=$(math_calc "$consistent_pages / $total_pages")
        math_compare "$page_ratio" ">" "0.8" && score=$((score + 1))
    fi
    
    if [ "$total_components" -gt 0 ]; then
        local comp_ratio=$(math_calc "$comp_consistent / $total_components")
        math_compare "$comp_ratio" ">" "0.8" && score=$((score + 1))
    fi
    
    [ "$score" -gt 10 ] && score=10
    
    local findings='[]'
    [ "$global_type" = "missing" ] && findings=$(echo "$findings" | jq '. + ["No centralized theme system detected"]')
    [ "$inconsistent_pages" -gt 0 ] && findings=$(echo "$findings" | jq --arg c "$inconsistent_pages" '. + [$c + " pages with theme inconsistencies"]')
    [ "$comp_inconsistent" -gt 5 ] && findings=$(echo "$findings" | jq --arg c "$comp_inconsistent" '. + [$c + " components with hardcoded colors"]')
    
    jq -n \
        --argjson score "$score" \
        --arg global_source "$global_source" \
        --arg global_type "$global_type" \
        --arg provider "${provider_rel:-none}" \
        --argjson pages_consistent "$consistent_pages" \
        --argjson pages_inconsistent "$inconsistent_pages" \
        --argjson page_issues "$page_issues" \
        --argjson comp_consistent "$comp_consistent" \
        --argjson comp_inconsistent "$comp_inconsistent" \
        --argjson comp_issues "$comp_issues" \
        --argjson findings "$findings" \
        '{
            score: $score,
            global: {source: $global_source, type: $global_type, provider: $provider},
            pages: {consistent: $pages_consistent, inconsistent: $pages_inconsistent, issues: $page_issues},
            components: {consistent: $comp_consistent, inconsistent: $comp_inconsistent, issues: $comp_issues},
            findings: $findings
        }'
}

# =============================================================================
# 13. VISUAL REGRESSION & DRIFT DETECTION
# =============================================================================
analyze_visual_regression() {
    echo "  [13/27] Visual Regression & Drift Detection..." >&2
    
    # Check for visual testing infrastructure
    local has_chromatic=false
    local has_percy=false
    local has_playwright_visual=false
    local has_storybook_test=false
    local has_backstop=false
    
    grep -rqE '"chromatic"|"@chromatic"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_chromatic=true
    grep -rqE '"@percy/cli"|"percy"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_percy=true
    grep -rqE 'toHaveScreenshot|toMatchSnapshot.*visual' "$CODEBASE_PATH" --include="*.spec.ts" --include="*.test.ts" --exclude-dir=node_modules 2>/dev/null && has_playwright_visual=true
    grep -rqE '"@storybook/test-runner"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_storybook_test=true
    grep -rqE '"backstopjs"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_backstop=true
    
    # Count visual test files
    local visual_test_count=$(find "$CODEBASE_PATH" -type f \( -name "*.visual.spec.*" -o -name "*.screenshot.*" -o -name "*visual*.test.*" \) \
        ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    visual_test_count=$(echo "$visual_test_count" | grep -oE '^[0-9]+' | head -1)
    [ -z "$visual_test_count" ] && visual_test_count=0
    
    # Check for snapshot directories
    local snapshot_dirs=$(find "$CODEBASE_PATH" -type d -name "__snapshots__" -o -name "screenshots" -o -name "visual-baselines" \
        ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    snapshot_dirs=$(echo "$snapshot_dirs" | grep -oE '^[0-9]+' | head -1)
    [ -z "$snapshot_dirs" ] && snapshot_dirs=0
    
    # Check for CI visual testing config
    local ci_visual_testing=false
    grep -rqE 'chromatic|percy|visual.*test|screenshot' "$CODEBASE_PATH" --include="*.yml" --include="*.yaml" 2>/dev/null && ci_visual_testing=true
    
    local has_any_visual_testing=false
    [ "$has_chromatic" = true ] || [ "$has_percy" = true ] || [ "$has_playwright_visual" = true ] || \
    [ "$has_backstop" = true ] || [ "$visual_test_count" -gt 0 ] && has_any_visual_testing=true
    
    # Score
    local score=3
    [ "$has_any_visual_testing" = true ] && score=$((score + 3))
    [ "$has_chromatic" = true ] || [ "$has_percy" = true ] && score=$((score + 2))  # Pro tools
    [ "$ci_visual_testing" = true ] && score=$((score + 1))
    [ "$snapshot_dirs" -gt 0 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$has_any_visual_testing" = false ] && findings=$(echo "$findings" | jq '. + ["No visual regression testing detected - pixel drift goes unnoticed"]')
    [ "$ci_visual_testing" = false ] && [ "$has_any_visual_testing" = true ] && findings=$(echo "$findings" | jq '. + ["Visual tests exist but not integrated into CI"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson has_visual_testing "$has_any_visual_testing" \
        --argjson chromatic "$has_chromatic" \
        --argjson percy "$has_percy" \
        --argjson playwright "$has_playwright_visual" \
        --argjson backstop "$has_backstop" \
        --argjson visual_tests "$visual_test_count" \
        --argjson snapshot_dirs "$snapshot_dirs" \
        --argjson ci_integrated "$ci_visual_testing" \
        --argjson findings "$findings" \
        '{score: $score, has_visual_testing: $has_visual_testing, tools: {chromatic: $chromatic, percy: $percy, playwright_visual: $playwright, backstop: $backstop}, visual_test_files: $visual_tests, snapshot_directories: $snapshot_dirs, ci_integrated: $ci_integrated, findings: $findings}'
}

# =============================================================================
# 14. DESIGN TOKEN COVERAGE & ENFORCEMENT
# =============================================================================
analyze_token_coverage() {
    echo "  [14/27] Design Token Coverage & Enforcement..." >&2
    
    local includes="--include=*.css --include=*.scss --include=*.tsx --include=*.jsx --include=*.ts"
    
    # Count total style declarations
    local total_color_styles=$(grep -rohE '(color|background|border-color|fill|stroke)\s*:' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    total_color_styles=$(echo "$total_color_styles" | grep -oE '^[0-9]+' | head -1)
    [ -z "$total_color_styles" ] && total_color_styles=0
    
    # Count token-based styles (var(--*))
    local token_color_styles=$(grep -rohE '(color|background|border-color|fill|stroke)\s*:\s*var\(--' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    token_color_styles=$(echo "$token_color_styles" | grep -oE '^[0-9]+' | head -1)
    [ -z "$token_color_styles" ] && token_color_styles=0
    
    # Count hardcoded colors introduced (hex, rgb, hsl)
    local hardcoded_colors=$(grep -rohE '(color|background|border-color)\s*:\s*(#[0-9a-fA-F]+|rgb|hsl)' "$CODEBASE_PATH" $includes \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    hardcoded_colors=$(echo "$hardcoded_colors" | grep -oE '^[0-9]+' | head -1)
    [ -z "$hardcoded_colors" ] && hardcoded_colors=0
    
    # Calculate token usage ratio
    local token_ratio=0
    if [ "$total_color_styles" -gt 0 ]; then
        token_ratio=$(math_calc "$token_color_styles * 100 / $total_color_styles")
    fi
    
    # Find unused/dead tokens (defined but never used)
    local defined_tokens=$(grep -rohE '\-\-[a-zA-Z][a-zA-Z0-9_-]+\s*:' "$CODEBASE_PATH" --include="*.css" --include="*.scss" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | sed 's/\s*://' | sort -u)
    local dead_tokens=0
    while IFS= read -r token; do
        [ -z "$token" ] && continue
        local usage_count=$({ grep -r "var($token)" "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
        [ "$usage_count" = "0" ] && dead_tokens=$((dead_tokens + 1))
    done <<< "$(echo "$defined_tokens" | head -50)"  # Sample first 50
    
    # Check for token overrides at component level
    local component_overrides=$(grep -rohE '\.[\w-]+\s*\{[^}]*--[a-zA-Z]' "$CODEBASE_PATH" --include="*.css" --include="*.scss" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    component_overrides=$(echo "$component_overrides" | grep -oE '^[0-9]+' | head -1)
    [ -z "$component_overrides" ] && component_overrides=0
    
    # Tailwind usage (utility-first = 100% token coverage)
    local tailwind_usage=$(grep -rohE 'className="[^"]*\b(bg-|text-|border-)' "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d '[:space:]')
    tailwind_usage=$(echo "$tailwind_usage" | grep -oE '^[0-9]+' | head -1)
    [ -z "$tailwind_usage" ] && tailwind_usage=0
    
    # Score
    local score=4
    local ratio_int=$(echo "$token_ratio" | cut -d. -f1)
    [ -z "$ratio_int" ] && ratio_int=0
    [ "$ratio_int" -gt 50 ] && score=$((score + 2))
    [ "$ratio_int" -gt 80 ] && score=$((score + 2))
    [ "$tailwind_usage" -gt 100 ] && score=$((score + 2))  # Utility-first = good
    [ "$dead_tokens" -lt 5 ] && score=$((score + 1))
    [ "$hardcoded_colors" -lt 50 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$ratio_int" -lt 30 ] && findings=$(echo "$findings" | jq --arg r "$token_ratio" '. + ["Only " + $r + "% of color styles use tokens - poor token adoption"]')
    [ "$hardcoded_colors" -gt 100 ] && findings=$(echo "$findings" | jq --arg c "$hardcoded_colors" '. + [$c + " hardcoded colors exist despite having tokens"]')
    [ "$dead_tokens" -gt 10 ] && findings=$(echo "$findings" | jq --arg d "$dead_tokens" '. + [$d + " dead/unused tokens detected"]')
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson total_styles "$total_color_styles" \
        --argjson token_styles "$token_color_styles" \
        --arg token_ratio "${token_ratio}%" \
        --argjson hardcoded "$hardcoded_colors" \
        --argjson dead_tokens "$dead_tokens" \
        --argjson component_overrides "$component_overrides" \
        --argjson tailwind_usage "$tailwind_usage" \
        --argjson findings "$findings" \
        '{score: $score, total_color_styles: $total_styles, token_based_styles: $token_styles, token_usage_ratio: $token_ratio, hardcoded_colors: $hardcoded, dead_tokens: $dead_tokens, component_overrides: $component_overrides, tailwind_utility_usage: $tailwind_usage, findings: $findings}'
}

# =============================================================================
# 15. COMPONENT API CONSISTENCY
# =============================================================================
analyze_component_api() {
    echo "  [15/27] Component API Consistency..." >&2
    
    local includes="--include=*.tsx --include=*.jsx"
    
    # Prop naming analysis
    # Check for variant naming: variant vs type vs kind
    local variant_props=$({ grep -rohE '\bvariant\s*[=:]' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local type_props=$(grep -rohE '\btype\s*[=:].*["\x27](primary|secondary|outline|ghost)' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local kind_props=$({ grep -rohE '\bkind\s*[=:]' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    
    variant_props=$(echo "$variant_props" | grep -oE '^[0-9]+' | head -1); [ -z "$variant_props" ] && variant_props=0
    type_props=$(echo "$type_props" | grep -oE '^[0-9]+' | head -1); [ -z "$type_props" ] && type_props=0
    kind_props=$(echo "$kind_props" | grep -oE '^[0-9]+' | head -1); [ -z "$kind_props" ] && kind_props=0
    
    # Boolean prop consistency: isDisabled vs disabled
    local is_prefix=$({ grep -rohE '\bis[A-Z][a-zA-Z]+\s*[=:}]' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local no_prefix=$(grep -rohE '\b(disabled|loading|visible|open|checked|selected)\s*[=:}]' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    
    is_prefix=$(echo "$is_prefix" | grep -oE '^[0-9]+' | head -1); [ -z "$is_prefix" ] && is_prefix=0
    no_prefix=$(echo "$no_prefix" | grep -oE '^[0-9]+' | head -1); [ -z "$no_prefix" ] && no_prefix=0
    
    # Callback naming: onClick vs onPress vs handleClick
    local on_callbacks=$({ grep -rohE '\bon[A-Z][a-zA-Z]+\s*=' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local handle_callbacks=$({ grep -rohE '\bhandle[A-Z][a-zA-Z]+\s*=' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    
    on_callbacks=$(echo "$on_callbacks" | grep -oE '^[0-9]+' | head -1); [ -z "$on_callbacks" ] && on_callbacks=0
    handle_callbacks=$(echo "$handle_callbacks" | grep -oE '^[0-9]+' | head -1); [ -z "$handle_callbacks" ] && handle_callbacks=0
    
    # Size prop consistency: size vs sz vs dimensions
    local size_patterns=$(grep -rohE '\b(size|sz|dimensions)\s*=' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | \
        sed 's/\s*=//' | sort | uniq -c | sort -rn | head -5)
    
    # Children vs render props vs slots
    local children_usage=$(grep -cohE '\{children\}|\{props\.children\}' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | awk '{sum+=$1} END{print sum+0}')
    local render_props=$(grep -cohE 'render[A-Z][a-zA-Z]+\s*=' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | awk '{sum+=$1} END{print sum+0}')
    
    # Calculate consistency score
    local naming_conflicts=0
    [ "$variant_props" -gt 10 ] && [ "$type_props" -gt 10 ] && naming_conflicts=$((naming_conflicts + 1))
    [ "$is_prefix" -gt 20 ] && [ "$no_prefix" -gt 20 ] && naming_conflicts=$((naming_conflicts + 1))
    [ "$on_callbacks" -gt 10 ] && [ "$handle_callbacks" -gt 10 ] && naming_conflicts=$((naming_conflicts + 1))
    
    # Score
    local score=6
    [ "$naming_conflicts" -eq 0 ] && score=$((score + 2))
    [ "$naming_conflicts" -gt 2 ] && score=$((score - 2))
    [ "$variant_props" -gt "$type_props" ] && [ "$variant_props" -gt "$kind_props" ] && score=$((score + 1))  # Consistent naming
    
    local findings='[]'
    [ "$naming_conflicts" -gt 0 ] && findings=$(echo "$findings" | jq --arg c "$naming_conflicts" '. + [$c + " prop naming conflicts detected (variant/type, isDisabled/disabled, etc.)"]')
    [ "$handle_callbacks" -gt "$on_callbacks" ] && [ "$on_callbacks" -gt 10 ] && findings=$(echo "$findings" | jq '. + ["Mixed callback naming: handleX and onX both used - standardize"]')
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson naming_conflicts "$naming_conflicts" \
        --argjson variant_props "$variant_props" \
        --argjson type_props "$type_props" \
        --argjson is_prefix_booleans "$is_prefix" \
        --argjson plain_booleans "$no_prefix" \
        --argjson on_callbacks "$on_callbacks" \
        --argjson handle_callbacks "$handle_callbacks" \
        --argjson children_pattern "$children_usage" \
        --argjson render_props "$render_props" \
        --argjson findings "$findings" \
        '{score: $score, naming_conflicts: $naming_conflicts, variant_naming: {variant: $variant_props, type: $type_props}, boolean_naming: {is_prefix: $is_prefix_booleans, no_prefix: $plain_booleans}, callback_naming: {on_pattern: $on_callbacks, handle_pattern: $handle_callbacks}, composition: {children: $children_pattern, render_props: $render_props}, findings: $findings}'
}

# =============================================================================
# 16. STATE DESIGN COVERAGE
# =============================================================================
analyze_state_coverage() {
    echo "  [16/27] State Design Coverage..." >&2
    
    local includes="--include=*.tsx --include=*.jsx --include=*.css --include=*.scss"
    
    # Interactive states
    local hover_states=$(grep -rohE ':hover|onMouseEnter|onMouseOver' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local focus_states=$(grep -rohE ':focus|onFocus|:focus-visible|:focus-within' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local active_states=$(grep -rohE ':active|onMouseDown' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local disabled_states=$(grep -rohE ':disabled|\[disabled\]|disabled\s*[=:]|isDisabled' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    
    hover_states=$(echo "$hover_states" | grep -oE '^[0-9]+' | head -1); [ -z "$hover_states" ] && hover_states=0
    focus_states=$(echo "$focus_states" | grep -oE '^[0-9]+' | head -1); [ -z "$focus_states" ] && focus_states=0
    active_states=$(echo "$active_states" | grep -oE '^[0-9]+' | head -1); [ -z "$active_states" ] && active_states=0
    disabled_states=$(echo "$disabled_states" | grep -oE '^[0-9]+' | head -1); [ -z "$disabled_states" ] && disabled_states=0
    
    # Loading states
    local loading_states=$(grep -rohE 'isLoading|loading\s*[=:]|Spinner|Loader|Skeleton|\.loading' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    loading_states=$(echo "$loading_states" | grep -oE '^[0-9]+' | head -1); [ -z "$loading_states" ] && loading_states=0
    
    # Error states
    local error_states=$(grep -rohE 'isError|error\s*[=:]|Error|\.error|hasError' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    error_states=$(echo "$error_states" | grep -oE '^[0-9]+' | head -1); [ -z "$error_states" ] && error_states=0
    
    # Empty states
    local empty_states=$(grep -rohE 'isEmpty|empty\s*[=:]|EmptyState|NoData|NoResults' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    empty_states=$(echo "$empty_states" | grep -oE '^[0-9]+' | head -1); [ -z "$empty_states" ] && empty_states=0
    
    # Skeleton vs Spinner usage
    local skeleton_count=$(grep -rohE 'Skeleton|\.skeleton|skeleton-' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local spinner_count=$(grep -rohE 'Spinner|\.spinner|spinner-|CircularProgress' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    
    skeleton_count=$(echo "$skeleton_count" | grep -oE '^[0-9]+' | head -1); [ -z "$skeleton_count" ] && skeleton_count=0
    spinner_count=$(echo "$spinner_count" | grep -oE '^[0-9]+' | head -1); [ -z "$spinner_count" ] && spinner_count=0
    
    # Optimistic UI patterns
    local optimistic_ui=$(grep -rohE 'optimistic|mutate.*onMutate|setQueryData' "$CODEBASE_PATH" --include="*.ts" --include="*.tsx" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    optimistic_ui=$(echo "$optimistic_ui" | grep -oE '^[0-9]+' | head -1); [ -z "$optimistic_ui" ] && optimistic_ui=0
    
    # Score
    local score=5
    [ "$hover_states" -gt 20 ] && score=$((score + 1))
    [ "$focus_states" -gt 10 ] && score=$((score + 1))
    [ "$disabled_states" -gt 10 ] && score=$((score + 1))
    [ "$loading_states" -gt 5 ] && score=$((score + 1))
    [ "$error_states" -gt 5 ] && score=$((score + 1))
    [ "$empty_states" -gt 3 ] && score=$((score + 1))
    [ "$skeleton_count" -gt 5 ] && score=$((score + 1))  # Skeletons > spinners
    
    local findings='[]'
    [ "$focus_states" -lt 5 ] && findings=$(echo "$findings" | jq '. + ["Few focus states detected - keyboard navigation may be unclear"]')
    [ "$loading_states" -lt 3 ] && findings=$(echo "$findings" | jq '. + ["Limited loading state implementations"]')
    [ "$empty_states" -lt 2 ] && findings=$(echo "$findings" | jq '. + ["No empty state components - poor UX for empty data"]')
    [ "$skeleton_count" -eq 0 ] && [ "$spinner_count" -gt 5 ] && findings=$(echo "$findings" | jq '. + ["Using spinners but no skeletons - skeletons provide better perceived performance"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson hover "$hover_states" \
        --argjson focus "$focus_states" \
        --argjson active "$active_states" \
        --argjson disabled "$disabled_states" \
        --argjson loading "$loading_states" \
        --argjson error "$error_states" \
        --argjson empty "$empty_states" \
        --argjson skeletons "$skeleton_count" \
        --argjson spinners "$spinner_count" \
        --argjson optimistic "$optimistic_ui" \
        --argjson findings "$findings" \
        '{score: $score, interactive_states: {hover: $hover, focus: $focus, active: $active, disabled: $disabled}, async_states: {loading: $loading, error: $error, empty: $empty}, loading_patterns: {skeletons: $skeletons, spinners: $spinners}, optimistic_ui: $optimistic, findings: $findings}'
}

# =============================================================================
# 17. FORM UX & VALIDATION QUALITY
# =============================================================================
analyze_form_ux() {
    echo "  [17/27] Form UX & Validation Quality..." >&2
    
    local includes="--include=*.tsx --include=*.jsx --include=*.html"
    
    # Label-input association
    local labels=$(grep -rohE '<label|<Label|htmlFor=' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local inputs=$(grep -rohE '<input|<Input|<textarea|<Textarea|<select|<Select' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    
    labels=$(echo "$labels" | grep -oE '^[0-9]+' | head -1); [ -z "$labels" ] && labels=0
    inputs=$(echo "$inputs" | grep -oE '^[0-9]+' | head -1); [ -z "$inputs" ] && inputs=0
    
    # Required field indicators
    local required_indicators=$(grep -rohE 'required|isRequired|\*\s*required|aria-required' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    required_indicators=$(echo "$required_indicators" | grep -oE '^[0-9]+' | head -1); [ -z "$required_indicators" ] && required_indicators=0
    
    # Inline validation (onChange/onBlur)
    local inline_validation=$(grep -rohE 'onBlur.*valid|onChange.*valid|validateOnBlur|validateOnChange' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    inline_validation=$(echo "$inline_validation" | grep -oE '^[0-9]+' | head -1); [ -z "$inline_validation" ] && inline_validation=0
    
    # Form libraries
    local has_react_hook_form=false
    local has_formik=false
    local has_zod=false
    local has_yup=false
    
    grep -rqE '"react-hook-form"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_react_hook_form=true
    grep -rqE '"formik"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_formik=true
    grep -rqE '"zod"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_zod=true
    grep -rqE '"yup"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_yup=true
    
    # Error message quality - check for generic "invalid" messages
    local generic_errors=$(grep -rohE '"[Ii]nvalid( input)?"|"[Rr]equired"|"[Ee]rror"' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local specific_errors=$(grep -rohE '"[Pp]lease enter|"[Mm]ust be|"[Ss]hould contain|"[Aa]t least' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    
    generic_errors=$(echo "$generic_errors" | grep -oE '^[0-9]+' | head -1); [ -z "$generic_errors" ] && generic_errors=0
    specific_errors=$(echo "$specific_errors" | grep -oE '^[0-9]+' | head -1); [ -z "$specific_errors" ] && specific_errors=0
    
    # Autofill compatibility
    local autocomplete_attrs=$(grep -rohE 'autoComplete=|autocomplete=' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    autocomplete_attrs=$(echo "$autocomplete_attrs" | grep -oE '^[0-9]+' | head -1); [ -z "$autocomplete_attrs" ] && autocomplete_attrs=0
    
    # Score
    local score=5
    local label_ratio=0
    [ "$inputs" -gt 0 ] && label_ratio=$(math_int "$labels * 100 / $inputs")
    [ "$label_ratio" -gt 80 ] && score=$((score + 1))
    [ "$has_react_hook_form" = true ] || [ "$has_formik" = true ] && score=$((score + 1))
    [ "$has_zod" = true ] || [ "$has_yup" = true ] && score=$((score + 1))
    [ "$inline_validation" -gt 5 ] && score=$((score + 1))
    [ "$specific_errors" -gt "$generic_errors" ] && score=$((score + 1))
    [ "$autocomplete_attrs" -gt 5 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$label_ratio" -lt 50 ] && findings=$(echo "$findings" | jq '. + ["Many inputs without proper labels - accessibility issue"]')
    [ "$generic_errors" -gt "$specific_errors" ] && findings=$(echo "$findings" | jq '. + ["Generic error messages (\"Invalid input\") - use actionable messages"]')
    [ "$autocomplete_attrs" -lt 3 ] && [ "$inputs" -gt 10 ] && findings=$(echo "$findings" | jq '. + ["Missing autocomplete attributes - poor autofill support"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson labels "$labels" \
        --argjson inputs "$inputs" \
        --argjson required_indicators "$required_indicators" \
        --argjson inline_validation "$inline_validation" \
        --argjson react_hook_form "$has_react_hook_form" \
        --argjson formik "$has_formik" \
        --argjson zod "$has_zod" \
        --argjson yup "$has_yup" \
        --argjson generic_errors "$generic_errors" \
        --argjson specific_errors "$specific_errors" \
        --argjson autocomplete "$autocomplete_attrs" \
        --argjson findings "$findings" \
        '{score: $score, labels: $labels, inputs: $inputs, required_indicators: $required_indicators, inline_validation: $inline_validation, form_libraries: {react_hook_form: $react_hook_form, formik: $formik}, validation_libraries: {zod: $zod, yup: $yup}, error_quality: {generic: $generic_errors, specific: $specific_errors}, autocomplete_attrs: $autocomplete, findings: $findings}'
}

# =============================================================================
# 18. LAYOUT STABILITY (CLS-ORIENTED)
# =============================================================================
analyze_layout_stability() {
    echo "  [18/27] Layout Stability (CLS)..." >&2
    
    local includes="--include=*.tsx --include=*.jsx --include=*.css --include=*.scss"
    
    # Image dimension enforcement
    local images_with_dimensions=$(grep -rohE '<img[^>]*(width|height)=' "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local images_total=$(grep -rohE '<img|<Image' "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    
    images_with_dimensions=$(echo "$images_with_dimensions" | grep -oE '^[0-9]+' | head -1); [ -z "$images_with_dimensions" ] && images_with_dimensions=0
    images_total=$(echo "$images_total" | grep -oE '^[0-9]+' | head -1); [ -z "$images_total" ] && images_total=0
    
    # Aspect ratio usage
    local aspect_ratio_usage=$(grep -rohE 'aspect-ratio|aspectRatio|aspect-\[' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    aspect_ratio_usage=$(echo "$aspect_ratio_usage" | grep -oE '^[0-9]+' | head -1); [ -z "$aspect_ratio_usage" ] && aspect_ratio_usage=0
    
    # Font-display strategy
    local font_display=$(grep -rohE 'font-display\s*:\s*(swap|optional|fallback|block)' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    font_display=$(echo "$font_display" | grep -oE '^[0-9]+' | head -1); [ -z "$font_display" ] && font_display=0
    
    # Skeleton sizing (check if skeletons have explicit dimensions)
    local sized_skeletons=$(grep -rohE 'Skeleton[^>]*(width|height|h-|w-|size)' "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    sized_skeletons=$(echo "$sized_skeletons" | grep -oE '^[0-9]+' | head -1); [ -z "$sized_skeletons" ] && sized_skeletons=0
    
    # Dynamic content containers (potential CLS sources)
    local dynamic_height=$(grep -rohE 'height:\s*auto|h-auto|height:\s*fit-content' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    dynamic_height=$(echo "$dynamic_height" | grep -oE '^[0-9]+' | head -1); [ -z "$dynamic_height" ] && dynamic_height=0
    
    # min-height usage (good for CLS)
    local min_height=$(grep -rohE 'min-height|min-h-' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    min_height=$(echo "$min_height" | grep -oE '^[0-9]+' | head -1); [ -z "$min_height" ] && min_height=0
    
    # Next.js Image component (optimized)
    local next_image=$(grep -rohE "from ['\"]next/image['\"]|import.*Image.*from ['\"]next" "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    next_image=$(echo "$next_image" | grep -oE '^[0-9]+' | head -1); [ -z "$next_image" ] && next_image=0
    
    # Score
    local score=5
    [ "$images_total" -gt 0 ] && [ "$images_with_dimensions" -gt $((images_total / 2)) ] && score=$((score + 1))
    [ "$aspect_ratio_usage" -gt 5 ] && score=$((score + 1))
    [ "$font_display" -gt 0 ] && score=$((score + 1))
    [ "$min_height" -gt 10 ] && score=$((score + 1))
    [ "$next_image" -gt 0 ] && score=$((score + 1))
    [ "$sized_skeletons" -gt 3 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$images_total" -gt 10 ] && [ "$images_with_dimensions" -lt $((images_total / 3)) ] && findings=$(echo "$findings" | jq '. + ["Many images without explicit dimensions - causes layout shift"]')
    [ "$font_display" -eq 0 ] && findings=$(echo "$findings" | jq '. + ["No font-display strategy - FOUT/FOIT causes CLS"]')
    [ "$dynamic_height" -gt 20 ] && findings=$(echo "$findings" | jq '. + ["Excessive height:auto usage - reserve space with min-height"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson images_total "$images_total" \
        --argjson images_with_dimensions "$images_with_dimensions" \
        --argjson aspect_ratio "$aspect_ratio_usage" \
        --argjson font_display "$font_display" \
        --argjson sized_skeletons "$sized_skeletons" \
        --argjson dynamic_height "$dynamic_height" \
        --argjson min_height "$min_height" \
        --argjson next_image "$next_image" \
        --argjson findings "$findings" \
        '{score: $score, images: {total: $images_total, with_dimensions: $images_with_dimensions}, aspect_ratio_usage: $aspect_ratio, font_display_declarations: $font_display, sized_skeletons: $sized_skeletons, cls_risk: {dynamic_height: $dynamic_height, min_height_mitigation: $min_height}, next_image_optimized: $next_image, findings: $findings}'
}

# =============================================================================
# 19. CROSS-PLATFORM & INPUT MODALITY
# =============================================================================
analyze_input_modality() {
    echo "  [19/27] Cross-Platform & Input Modality..." >&2
    
    local includes="--include=*.tsx --include=*.jsx --include=*.css --include=*.scss"
    
    # Hover-only interactions (problematic for touch)
    local hover_only=$(grep -rohE ':hover\s*\{[^}]*display|:hover\s*\{[^}]*visibility|:hover\s*\{[^}]*opacity:\s*1' "$CODEBASE_PATH" --include="*.css" --include="*.scss" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    hover_only=$(echo "$hover_only" | grep -oE '^[0-9]+' | head -1); [ -z "$hover_only" ] && hover_only=0
    
    # Pointer media queries (touch vs mouse)
    local pointer_queries=$(grep -rohE '@media.*pointer|@media.*hover' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    pointer_queries=$(echo "$pointer_queries" | grep -oE '^[0-9]+' | head -1); [ -z "$pointer_queries" ] && pointer_queries=0
    
    # Touch events
    local touch_events=$(grep -rohE 'onTouchStart|onTouchEnd|onTouchMove|touch-action' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    touch_events=$(echo "$touch_events" | grep -oE '^[0-9]+' | head -1); [ -z "$touch_events" ] && touch_events=0
    
    # Small touch targets (width/height < 44px on interactive elements)
    local small_buttons=$(grep -rohE '<button[^>]*(w-[0-8]|h-[0-8]|width:\s*[0-3][0-9]px|height:\s*[0-3][0-9]px)' "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    small_buttons=$(echo "$small_buttons" | grep -oE '^[0-9]+' | head -1); [ -z "$small_buttons" ] && small_buttons=0
    
    # Keyboard event handlers
    local keyboard_handlers=$(grep -rohE 'onKeyDown|onKeyUp|onKeyPress' "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    keyboard_handlers=$(echo "$keyboard_handlers" | grep -oE '^[0-9]+' | head -1); [ -z "$keyboard_handlers" ] && keyboard_handlers=0
    
    # Click handlers (should have keyboard equivalents)
    local click_handlers=$({ grep -rohE 'onClick=' "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    click_handlers=$(echo "$click_handlers" | grep -oE '^[0-9]+' | head -1); [ -z "$click_handlers" ] && click_handlers=0
    
    # Custom scrollbar styling
    local custom_scrollbars=$(grep -rohE '::-webkit-scrollbar|scrollbar-width|scrollbar-color' "$CODEBASE_PATH" --include="*.css" --include="*.scss" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    custom_scrollbars=$(echo "$custom_scrollbars" | grep -oE '^[0-9]+' | head -1); [ -z "$custom_scrollbars" ] && custom_scrollbars=0
    
    # Score
    local score=5
    [ "$hover_only" -lt 5 ] && score=$((score + 1))
    [ "$pointer_queries" -gt 0 ] && score=$((score + 2))
    [ "$touch_events" -gt 5 ] && score=$((score + 1))
    [ "$small_buttons" -lt 3 ] && score=$((score + 1))
    [ "$keyboard_handlers" -gt $((click_handlers / 4)) ] && score=$((score + 1))
    
    local findings='[]'
    [ "$hover_only" -gt 10 ] && findings=$(echo "$findings" | jq --arg c "$hover_only" '. + [$c + " hover-only UI elements - unusable on touch devices"]')
    [ "$pointer_queries" -eq 0 ] && findings=$(echo "$findings" | jq '. + ["No pointer/hover media queries - not adapting to input modality"]')
    [ "$small_buttons" -gt 5 ] && findings=$(echo "$findings" | jq --arg c "$small_buttons" '. + [$c + " touch targets < 44px - accessibility issue"]')
    [ "$click_handlers" -gt 20 ] && [ "$keyboard_handlers" -lt 5 ] && findings=$(echo "$findings" | jq '. + ["Many click handlers but few keyboard handlers - keyboard users blocked"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson hover_only "$hover_only" \
        --argjson pointer_queries "$pointer_queries" \
        --argjson touch_events "$touch_events" \
        --argjson small_touch_targets "$small_buttons" \
        --argjson keyboard_handlers "$keyboard_handlers" \
        --argjson click_handlers "$click_handlers" \
        --argjson custom_scrollbars "$custom_scrollbars" \
        --argjson findings "$findings" \
        '{score: $score, hover_only_ui: $hover_only, pointer_media_queries: $pointer_queries, touch_events: $touch_events, small_touch_targets: $small_touch_targets, keyboard_handlers: $keyboard_handlers, click_handlers: $click_handlers, custom_scrollbars: $custom_scrollbars, findings: $findings}'
}

# =============================================================================
# 20. ICONOGRAPHY SYSTEM INTEGRITY
# =============================================================================
analyze_iconography() {
    echo "  [20/27] Iconography System..." >&2
    
    local includes="--include=*.tsx --include=*.jsx --include=*.svg"
    
    # Icon library detection
    local has_lucide=false
    local has_heroicons=false
    local has_fontawesome=false
    local has_material=false
    local has_feather=false
    local icon_libraries=0
    
    grep -rqE '"lucide-react"|"@lucide"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_lucide=true && icon_libraries=$((icon_libraries + 1))
    grep -rqE '"@heroicons"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_heroicons=true && icon_libraries=$((icon_libraries + 1))
    grep -rqE '"@fortawesome"|"font-awesome"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_fontawesome=true && icon_libraries=$((icon_libraries + 1))
    grep -rqE '"@mui/icons"|"@material-ui/icons"|"material-icons"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_material=true && icon_libraries=$((icon_libraries + 1))
    grep -rqE '"feather-icons"|"react-feather"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_feather=true && icon_libraries=$((icon_libraries + 1))
    
    # SVG icon count
    local svg_icons=$(find "$CODEBASE_PATH" -name "*.svg" ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    svg_icons=$(echo "$svg_icons" | grep -oE '^[0-9]+' | head -1); [ -z "$svg_icons" ] && svg_icons=0
    
    # Icon size consistency (check for various size patterns)
    local icon_sizes=$(grep -rohE '(Icon|icon)[^>]*(size|width|height)=["\x27]?[0-9]+' "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null | \
        grep -oE '[0-9]+' | sort | uniq -c | sort -rn)
    local unique_icon_sizes=$(echo "$icon_sizes" | wc -l | tr -d '[:space:]')
    unique_icon_sizes=$(echo "$unique_icon_sizes" | grep -oE '^[0-9]+' | head -1); [ -z "$unique_icon_sizes" ] && unique_icon_sizes=0
    
    # currentColor usage (good for inheritance)
    local current_color=$(grep -rohE 'currentColor|fill="currentColor"|stroke="currentColor"' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    current_color=$(echo "$current_color" | grep -oE '^[0-9]+' | head -1); [ -z "$current_color" ] && current_color=0
    
    # Hardcoded colors in icons
    local hardcoded_icon_colors=$(grep -rohE '<svg[^>]*>.*fill="#[0-9a-fA-F]+"|stroke="#[0-9a-fA-F]+"' "$CODEBASE_PATH" --include="*.svg" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    hardcoded_icon_colors=$(echo "$hardcoded_icon_colors" | grep -oE '^[0-9]+' | head -1); [ -z "$hardcoded_icon_colors" ] && hardcoded_icon_colors=0
    
    # Stroke width variance
    local stroke_widths=$(grep -rohE 'stroke-width="[0-9]+"' "$CODEBASE_PATH" --include="*.svg" --exclude-dir=node_modules 2>/dev/null | sort | uniq -c)
    local unique_strokes=$(echo "$stroke_widths" | wc -l | tr -d '[:space:]')
    unique_strokes=$(echo "$unique_strokes" | grep -oE '^[0-9]+' | head -1); [ -z "$unique_strokes" ] && unique_strokes=0
    
    # Score
    local score=5
    [ "$icon_libraries" -eq 1 ] && score=$((score + 2))  # Single library = consistent
    [ "$icon_libraries" -gt 2 ] && score=$((score - 1))  # Multiple = inconsistent
    [ "$unique_icon_sizes" -le 4 ] && score=$((score + 1))
    [ "$current_color" -gt 10 ] && score=$((score + 1))
    [ "$hardcoded_icon_colors" -lt 5 ] && score=$((score + 1))
    [ "$unique_strokes" -le 2 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$icon_libraries" -gt 2 ] && findings=$(echo "$findings" | jq --arg c "$icon_libraries" '. + [$c + " icon libraries mixed - visual inconsistency"]')
    [ "$unique_icon_sizes" -gt 6 ] && findings=$(echo "$findings" | jq --arg c "$unique_icon_sizes" '. + [$c + " different icon sizes - standardize to 3-4 sizes"]')
    [ "$hardcoded_icon_colors" -gt 10 ] && findings=$(echo "$findings" | jq '. + ["Icons with hardcoded colors - use currentColor for theming"]')
    [ "$unique_strokes" -gt 3 ] && findings=$(echo "$findings" | jq '. + ["Inconsistent icon stroke widths - visual discord"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson icon_libraries "$icon_libraries" \
        --argjson lucide "$has_lucide" \
        --argjson heroicons "$has_heroicons" \
        --argjson fontawesome "$has_fontawesome" \
        --argjson material "$has_material" \
        --argjson svg_icons "$svg_icons" \
        --argjson unique_sizes "$unique_icon_sizes" \
        --argjson current_color "$current_color" \
        --argjson hardcoded_colors "$hardcoded_icon_colors" \
        --argjson unique_strokes "$unique_strokes" \
        --argjson findings "$findings" \
        '{score: $score, icon_libraries_count: $icon_libraries, libraries: {lucide: $lucide, heroicons: $heroicons, fontawesome: $fontawesome, material: $material}, svg_icons: $svg_icons, size_consistency: {unique_sizes: $unique_sizes}, color_inheritance: {current_color_usage: $current_color, hardcoded: $hardcoded_colors}, stroke_consistency: {unique_strokes: $unique_strokes}, findings: $findings}'
}

# =============================================================================
# 21. COPY & MICROCOPY CONSISTENCY
# =============================================================================
analyze_microcopy() {
    echo "  [21/27] Copy & Microcopy Consistency..." >&2
    
    local includes="--include=*.tsx --include=*.jsx"
    
    # Button text patterns
    local submit_count=$({ grep -rohE '>[Ss]ubmit<' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local save_count=$({ grep -rohE '>[Ss]ave<' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local ok_count=$(grep -rohE '>OK<|>Ok<|>Okay<' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local done_count=$({ grep -rohE '>[Dd]one<' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    
    submit_count=$(echo "$submit_count" | grep -oE '^[0-9]+' | head -1); [ -z "$submit_count" ] && submit_count=0
    save_count=$(echo "$save_count" | grep -oE '^[0-9]+' | head -1); [ -z "$save_count" ] && save_count=0
    ok_count=$(echo "$ok_count" | grep -oE '^[0-9]+' | head -1); [ -z "$ok_count" ] && ok_count=0
    done_count=$(echo "$done_count" | grep -oE '^[0-9]+' | head -1); [ -z "$done_count" ] && done_count=0
    
    # Cancel/Close patterns
    local cancel_count=$({ grep -rohE '>[Cc]ancel<' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local close_count=$({ grep -rohE '>[Cc]lose<' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    
    cancel_count=$(echo "$cancel_count" | grep -oE '^[0-9]+' | head -1); [ -z "$cancel_count" ] && cancel_count=0
    close_count=$(echo "$close_count" | grep -oE '^[0-9]+' | head -1); [ -z "$close_count" ] && close_count=0
    
    # Casing consistency check
    local title_case=$({ grep -rohE '>[A-Z][a-z]+ [A-Z][a-z]+<' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local sentence_case=$({ grep -rohE '>[A-Z][a-z]+ [a-z]+<' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    
    title_case=$(echo "$title_case" | grep -oE '^[0-9]+' | head -1); [ -z "$title_case" ] && title_case=0
    sentence_case=$(echo "$sentence_case" | grep -oE '^[0-9]+' | head -1); [ -z "$sentence_case" ] && sentence_case=0
    
    # Ellipsis usage (loading states)
    local ellipsis=$(grep -rohE '\.\.\.|…' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    ellipsis=$(echo "$ellipsis" | grep -oE '^[0-9]+' | head -1); [ -z "$ellipsis" ] && ellipsis=0
    
    # Ambiguous CTAs (anti-patterns)
    local ambiguous_ctas=$((ok_count + done_count))
    
    # i18n setup (if copy is externalized)
    local has_i18n=false
    grep -rqE '"i18next"|"react-i18next"|"next-i18next"|"react-intl"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_i18n=true
    
    # Score
    local score=5
    [ "$ambiguous_ctas" -lt 5 ] && score=$((score + 1))
    [ "$has_i18n" = true ] && score=$((score + 2))
    # Check if one casing style dominates
    [ "$title_case" -gt $((sentence_case * 3)) ] || [ "$sentence_case" -gt $((title_case * 3)) ] && score=$((score + 1))
    # Check submit vs save consistency
    [ "$submit_count" -gt 0 ] && [ "$save_count" -eq 0 ] || [ "$save_count" -gt 0 ] && [ "$submit_count" -eq 0 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$ambiguous_ctas" -gt 10 ] && findings=$(echo "$findings" | jq --arg c "$ambiguous_ctas" '. + [$c + " ambiguous CTAs (OK, Done) - use action verbs"]')
    [ "$title_case" -gt 10 ] && [ "$sentence_case" -gt 10 ] && findings=$(echo "$findings" | jq '. + ["Mixed casing: title case and sentence case both used"]')
    [ "$submit_count" -gt 5 ] && [ "$save_count" -gt 5 ] && findings=$(echo "$findings" | jq '. + ["Inconsistent button labels: Submit and Save both used"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson submit "$submit_count" \
        --argjson save "$save_count" \
        --argjson ok "$ok_count" \
        --argjson done "$done_count" \
        --argjson cancel "$cancel_count" \
        --argjson close "$close_count" \
        --argjson title_case "$title_case" \
        --argjson sentence_case "$sentence_case" \
        --argjson ellipsis "$ellipsis" \
        --argjson has_i18n "$has_i18n" \
        --argjson findings "$findings" \
        '{score: $score, button_labels: {submit: $submit, save: $save, ok: $ok, done: $done, cancel: $cancel, close: $close}, casing: {title_case: $title_case, sentence_case: $sentence_case}, ellipsis_usage: $ellipsis, i18n_setup: $has_i18n, findings: $findings}'
}

# =============================================================================
# 22. PERFORMANCE-CENTRIC UI METRICS
# =============================================================================
analyze_ui_performance() {
    echo "  [22/27] UI Performance Metrics..." >&2
    
    local includes="--include=*.css --include=*.scss"
    
    # CSS file count and size estimation
    local css_files=$(find "$CODEBASE_PATH" -type f \( -name "*.css" -o -name "*.scss" \) ! -path "*/node_modules/*" 2>/dev/null)
    local css_file_count=$(echo "$css_files" | grep -c '.' || echo "0")
    
    # Expensive CSS properties
    local box_shadow=$({ grep -rohE 'box-shadow' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    local filter_blur=$(grep -rohE 'filter:\s*blur|backdrop-filter' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local gradients=$(grep -rohE 'linear-gradient|radial-gradient' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    
    box_shadow=$(echo "$box_shadow" | grep -oE '^[0-9]+' | head -1); [ -z "$box_shadow" ] && box_shadow=0
    filter_blur=$(echo "$filter_blur" | grep -oE '^[0-9]+' | head -1); [ -z "$filter_blur" ] && filter_blur=0
    gradients=$(echo "$gradients" | grep -oE '^[0-9]+' | head -1); [ -z "$gradients" ] && gradients=0
    
    # Layout thrashing patterns (top/left vs transform)
    local position_animation=$(grep -rohE 'transition[^;]*(top|left|right|bottom)' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local transform_animation=$(grep -rohE 'transition[^;]*transform|transform.*transition' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    
    position_animation=$(echo "$position_animation" | grep -oE '^[0-9]+' | head -1); [ -z "$position_animation" ] && position_animation=0
    transform_animation=$(echo "$transform_animation" | grep -oE '^[0-9]+' | head -1); [ -z "$transform_animation" ] && transform_animation=0
    
    # Shadow blur radius (large = expensive)
    local large_shadows=$({ grep -rohE 'box-shadow:[^;]*[2-9][0-9]px' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    large_shadows=$(echo "$large_shadows" | grep -oE '^[0-9]+' | head -1); [ -z "$large_shadows" ] && large_shadows=0
    
    # will-change usage
    local will_change=$({ grep -rohE 'will-change' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    will_change=$(echo "$will_change" | grep -oE '^[0-9]+' | head -1); [ -z "$will_change" ] && will_change=0
    
    # contain property (performance optimization)
    local contain=$(grep -rohE 'contain:\s*(layout|paint|content|strict)' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    contain=$(echo "$contain" | grep -oE '^[0-9]+' | head -1); [ -z "$contain" ] && contain=0
    
    # content-visibility (virtualization)
    local content_visibility=$({ grep -rohE 'content-visibility' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    content_visibility=$(echo "$content_visibility" | grep -oE '^[0-9]+' | head -1); [ -z "$content_visibility" ] && content_visibility=0
    
    # Score
    local score=5
    [ "$position_animation" -lt 5 ] && score=$((score + 1))
    [ "$transform_animation" -gt "$position_animation" ] && score=$((score + 1))
    [ "$large_shadows" -lt 10 ] && score=$((score + 1))
    [ "$contain" -gt 0 ] && score=$((score + 1))
    [ "$content_visibility" -gt 0 ] && score=$((score + 1))
    [ "$will_change" -lt 20 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$position_animation" -gt 10 ] && findings=$(echo "$findings" | jq --arg c "$position_animation" '. + [$c + " transitions on top/left - use transform for performance"]')
    [ "$large_shadows" -gt 20 ] && findings=$(echo "$findings" | jq --arg c "$large_shadows" '. + [$c + " large shadow blur radii (>20px) - expensive rendering"]')
    [ "$filter_blur" -gt 30 ] && findings=$(echo "$findings" | jq '. + ["Heavy filter/blur usage - GPU intensive"]')
    [ "$will_change" -gt 30 ] && findings=$(echo "$findings" | jq '. + ["Excessive will-change - can cause memory issues"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson css_files "$css_file_count" \
        --argjson box_shadows "$box_shadow" \
        --argjson filter_blur "$filter_blur" \
        --argjson gradients "$gradients" \
        --argjson position_animation "$position_animation" \
        --argjson transform_animation "$transform_animation" \
        --argjson large_shadows "$large_shadows" \
        --argjson will_change "$will_change" \
        --argjson contain "$contain" \
        --argjson content_visibility "$content_visibility" \
        --argjson findings "$findings" \
        '{score: $score, css_files: $css_files, expensive_properties: {box_shadows: $box_shadows, filter_blur: $filter_blur, gradients: $gradients}, animation_performance: {position_based: $position_animation, transform_based: $transform_animation}, large_shadow_blur: $large_shadows, optimizations: {will_change: $will_change, contain: $contain, content_visibility: $content_visibility}, findings: $findings}'
}

# =============================================================================
# 23. INTERNATIONALIZATION & TEXT RESILIENCE
# =============================================================================
analyze_i18n() {
    echo "  [23/27] Internationalization & Text Resilience..." >&2
    
    local includes="--include=*.tsx --include=*.jsx --include=*.ts --include=*.js"
    
    # Hardcoded strings in JSX
    local hardcoded_strings=$(grep -rohE '>[A-Za-z][A-Za-z ]{5,}<|"[A-Za-z][A-Za-z ]{10,}"' "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    hardcoded_strings=$(echo "$hardcoded_strings" | grep -oE '^[0-9]+' | head -1); [ -z "$hardcoded_strings" ] && hardcoded_strings=0
    
    # i18n function usage
    local t_function=$(grep -rohE '\bt\(["\x27]|useTranslation|<Trans' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    t_function=$(echo "$t_function" | grep -oE '^[0-9]+' | head -1); [ -z "$t_function" ] && t_function=0
    
    # Text overflow handling
    local text_overflow=$(grep -rohE 'text-overflow|truncate|line-clamp|overflow-ellipsis' "$CODEBASE_PATH" --include="*.css" --include="*.scss" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    text_overflow=$(echo "$text_overflow" | grep -oE '^[0-9]+' | head -1); [ -z "$text_overflow" ] && text_overflow=0
    
    # RTL support
    local rtl_support=$(grep -rohE 'dir=|direction:|rtl|ltr|logical|start|end' "$CODEBASE_PATH" $includes --include="*.css" --include="*.scss" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    rtl_support=$(echo "$rtl_support" | grep -oE '^[0-9]+' | head -1); [ -z "$rtl_support" ] && rtl_support=0
    
    # Locale files
    local locale_files=$(find "$CODEBASE_PATH" -type f \( -name "*.json" -path "*locales*" -o -name "*.json" -path "*i18n*" -o -name "*.json" -path "*translations*" \) ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    locale_files=$(echo "$locale_files" | grep -oE '^[0-9]+' | head -1); [ -z "$locale_files" ] && locale_files=0
    
    # Date/number formatting
    local intl_usage=$(grep -rohE 'Intl\.|toLocaleString|formatDate|formatNumber' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    intl_usage=$(echo "$intl_usage" | grep -oE '^[0-9]+' | head -1); [ -z "$intl_usage" ] && intl_usage=0
    
    # Fixed width containers (break with translations)
    local fixed_width=$(grep -rohE 'width:\s*[0-9]+px|w-\[[0-9]+px\]' "$CODEBASE_PATH" --include="*.css" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    fixed_width=$(echo "$fixed_width" | grep -oE '^[0-9]+' | head -1); [ -z "$fixed_width" ] && fixed_width=0
    
    # Score
    local score=5
    [ "$t_function" -gt 20 ] && score=$((score + 2))
    [ "$locale_files" -gt 0 ] && score=$((score + 1))
    [ "$text_overflow" -gt 10 ] && score=$((score + 1))
    [ "$intl_usage" -gt 5 ] && score=$((score + 1))
    [ "$rtl_support" -gt 5 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$hardcoded_strings" -gt 50 ] && [ "$t_function" -lt 10 ] && findings=$(echo "$findings" | jq --arg c "$hardcoded_strings" '. + [$c + " hardcoded strings - not i18n ready"]')
    [ "$text_overflow" -lt 5 ] && findings=$(echo "$findings" | jq '. + ["Limited text overflow handling - will break with longer translations"]')
    [ "$fixed_width" -gt 30 ] && findings=$(echo "$findings" | jq --arg c "$fixed_width" '. + [$c + " fixed pixel widths - inflexible for text expansion"]')
    [ "$rtl_support" -lt 3 ] && findings=$(echo "$findings" | jq '. + ["No RTL support detected"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson hardcoded_strings "$hardcoded_strings" \
        --argjson i18n_function_calls "$t_function" \
        --argjson locale_files "$locale_files" \
        --argjson text_overflow_handling "$text_overflow" \
        --argjson rtl_support "$rtl_support" \
        --argjson intl_formatting "$intl_usage" \
        --argjson fixed_width_containers "$fixed_width" \
        --argjson findings "$findings" \
        '{score: $score, hardcoded_strings: $hardcoded_strings, i18n_calls: $i18n_function_calls, locale_files: $locale_files, text_resilience: {overflow_handling: $text_overflow_handling, fixed_widths: $fixed_width_containers}, rtl_support: $rtl_support, intl_formatting: $intl_formatting, findings: $findings}'
}

# =============================================================================
# 24. ERROR PREVENTION & UX SAFETY
# =============================================================================
analyze_ux_safety() {
    echo "  [24/27] Error Prevention & UX Safety..." >&2
    
    local includes="--include=*.tsx --include=*.jsx"
    
    # Destructive action confirmations
    local confirm_dialogs=$(grep -rohE 'confirm\(|Confirm|ConfirmDialog|AlertDialog|Modal.*delete|Modal.*remove' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    confirm_dialogs=$(echo "$confirm_dialogs" | grep -oE '^[0-9]+' | head -1); [ -z "$confirm_dialogs" ] && confirm_dialogs=0
    
    # Delete/remove buttons
    local delete_actions=$(grep -rohE 'delete|Delete|remove|Remove|destroy|Destroy' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    delete_actions=$(echo "$delete_actions" | grep -oE '^[0-9]+' | head -1); [ -z "$delete_actions" ] && delete_actions=0
    
    # Undo patterns
    local undo_support=$(grep -rohE 'undo|Undo|revert|Revert|toast.*undo|Snackbar.*undo' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    undo_support=$(echo "$undo_support" | grep -oE '^[0-9]+' | head -1); [ -z "$undo_support" ] && undo_support=0
    
    # Warning colors (yellow/orange vs red for different severity)
    local warning_colors=$(grep -rohE 'warning|Warning|amber|yellow' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    local error_colors=$(grep -rohE 'error|Error|danger|destructive|red' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    
    warning_colors=$(echo "$warning_colors" | grep -oE '^[0-9]+' | head -1); [ -z "$warning_colors" ] && warning_colors=0
    error_colors=$(echo "$error_colors" | grep -oE '^[0-9]+' | head -1); [ -z "$error_colors" ] && error_colors=0
    
    # Form dirty state / unsaved changes
    local dirty_state=$(grep -rohE 'isDirty|hasChanges|unsaved|beforeunload|formState\.isDirty' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    dirty_state=$(echo "$dirty_state" | grep -oE '^[0-9]+' | head -1); [ -z "$dirty_state" ] && dirty_state=0
    
    # Auto-save
    local auto_save=$(grep -rohE 'autoSave|auto-save|debounce.*save|useAutoSave' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    auto_save=$(echo "$auto_save" | grep -oE '^[0-9]+' | head -1); [ -z "$auto_save" ] && auto_save=0
    
    # Double-click prevention
    local double_click_prevention=$(grep -rohE 'disabled.*loading|isSubmitting|onClick.*setLoading|debounce.*click' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    double_click_prevention=$(echo "$double_click_prevention" | grep -oE '^[0-9]+' | head -1); [ -z "$double_click_prevention" ] && double_click_prevention=0
    
    # Score
    local score=5
    [ "$delete_actions" -gt 0 ] && [ "$confirm_dialogs" -gt 0 ] && score=$((score + 2))
    [ "$undo_support" -gt 0 ] && score=$((score + 1))
    [ "$dirty_state" -gt 0 ] && score=$((score + 1))
    [ "$double_click_prevention" -gt 3 ] && score=$((score + 1))
    [ "$warning_colors" -gt 0 ] && [ "$error_colors" -gt 0 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$delete_actions" -gt 5 ] && [ "$confirm_dialogs" -lt 2 ] && findings=$(echo "$findings" | jq '. + ["Destructive actions without confirmation dialogs"]')
    [ "$undo_support" -eq 0 ] && [ "$delete_actions" -gt 5 ] && findings=$(echo "$findings" | jq '. + ["No undo support for destructive actions"]')
    [ "$dirty_state" -eq 0 ] && findings=$(echo "$findings" | jq '. + ["No unsaved changes detection - users may lose work"]')
    [ "$double_click_prevention" -lt 2 ] && findings=$(echo "$findings" | jq '. + ["Limited double-click prevention - risk of duplicate submissions"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson confirm_dialogs "$confirm_dialogs" \
        --argjson delete_actions "$delete_actions" \
        --argjson undo_support "$undo_support" \
        --argjson warning_colors "$warning_colors" \
        --argjson error_colors "$error_colors" \
        --argjson dirty_state "$dirty_state" \
        --argjson auto_save "$auto_save" \
        --argjson double_click_prevention "$double_click_prevention" \
        --argjson findings "$findings" \
        '{score: $score, destructive_actions: {delete_buttons: $delete_actions, confirmations: $confirm_dialogs}, recovery: {undo_support: $undo_support, dirty_state_detection: $dirty_state, auto_save: $auto_save}, severity_distinction: {warnings: $warning_colors, errors: $error_colors}, double_click_prevention: $double_click_prevention, findings: $findings}'
}

# =============================================================================
# 25. DESIGN-CODE PARITY
# =============================================================================
analyze_design_parity() {
    echo "  [25/27] Design-Code Parity..." >&2
    
    # Check for Figma integration
    local has_figma_tokens=false
    [ -f "$CODEBASE_PATH/figma-tokens.json" ] || [ -d "$CODEBASE_PATH/tokens" ] || \
    grep -rqE '"figma"|"@figma"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_figma_tokens=true
    
    # Style Dictionary / design token tools
    local has_style_dictionary=false
    grep -rqE '"style-dictionary"|"token-transformer"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_style_dictionary=true
    
    # Design token files
    local token_files=$(find "$CODEBASE_PATH" -type f \( -name "tokens.json" -o -name "*.tokens.json" -o -name "design-tokens.*" \) ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    token_files=$(echo "$token_files" | grep -oE '^[0-9]+' | head -1); [ -z "$token_files" ] && token_files=0
    
    # Component naming parity (check for consistent naming patterns)
    local components_dir=$(find "$CODEBASE_PATH" -type d -name "components" ! -path "*/node_modules/*" 2>/dev/null | head -1)
    local component_count=0
    local pascalcase_components=0
    
    if [ -n "$components_dir" ]; then
        component_count=$(find "$components_dir" -name "*.tsx" -o -name "*.jsx" 2>/dev/null | wc -l | tr -d '[:space:]')
        pascalcase_components=$(find "$components_dir" -name "[A-Z]*.tsx" -o -name "[A-Z]*.jsx" 2>/dev/null | wc -l | tr -d '[:space:]')
    fi
    component_count=$(echo "$component_count" | grep -oE '^[0-9]+' | head -1); [ -z "$component_count" ] && component_count=0
    pascalcase_components=$(echo "$pascalcase_components" | grep -oE '^[0-9]+' | head -1); [ -z "$pascalcase_components" ] && pascalcase_components=0
    
    # Deprecated component detection
    local deprecated_usage=$(grep -rohE '@deprecated|DEPRECATED|deprecated' "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" --include="*.ts" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    deprecated_usage=$(echo "$deprecated_usage" | grep -oE '^[0-9]+' | head -1); [ -z "$deprecated_usage" ] && deprecated_usage=0
    
    # Variant naming parity
    local variant_names=$(grep -rohE "variant=['\"][^'\"]+['\"]" "$CODEBASE_PATH" --include="*.tsx" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null | sort | uniq -c | sort -rn | head -10)
    local unique_variants=$(echo "$variant_names" | wc -l | tr -d '[:space:]')
    unique_variants=$(echo "$unique_variants" | grep -oE '^[0-9]+' | head -1); [ -z "$unique_variants" ] && unique_variants=0
    
    # Score
    local score=5
    [ "$has_figma_tokens" = true ] && score=$((score + 2))
    [ "$has_style_dictionary" = true ] && score=$((score + 1))
    [ "$token_files" -gt 0 ] && score=$((score + 1))
    [ "$component_count" -gt 0 ] && [ "$pascalcase_components" -gt $((component_count * 8 / 10)) ] && score=$((score + 1))
    [ "$deprecated_usage" -lt 5 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$has_figma_tokens" = false ] && findings=$(echo "$findings" | jq '. + ["No Figma token integration - design-code sync is manual"]')
    [ "$deprecated_usage" -gt 10 ] && findings=$(echo "$findings" | jq --arg c "$deprecated_usage" '. + [$c + " deprecated component usages - clean up needed"]')
    [ "$token_files" -eq 0 ] && [ "$has_style_dictionary" = false ] && findings=$(echo "$findings" | jq '. + ["No design token files or token transformation tools"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson figma_integration "$has_figma_tokens" \
        --argjson style_dictionary "$has_style_dictionary" \
        --argjson token_files "$token_files" \
        --argjson total_components "$component_count" \
        --argjson pascalcase_components "$pascalcase_components" \
        --argjson deprecated_usages "$deprecated_usage" \
        --argjson unique_variants "$unique_variants" \
        --argjson findings "$findings" \
        '{score: $score, design_tool_integration: {figma: $figma_integration, style_dictionary: $style_dictionary}, token_files: $token_files, component_naming: {total: $total_components, pascalcase: $pascalcase_components}, deprecated_usages: $deprecated_usages, variant_count: $unique_variants, findings: $findings}'
}

# =============================================================================
# 26. GOVERNANCE & ENTROPY METRICS
# =============================================================================
analyze_entropy() {
    echo "  [26/27] UI Entropy & Governance..." >&2
    
    local includes="--include=*.tsx --include=*.jsx"
    
    # Unique patterns vs total (entropy)
    # Count unique className patterns
    local unique_classnames=$(grep -rohE 'className="[^"]+"' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | sort -u | wc -l | tr -d '[:space:]')
    local total_classnames=$({ grep -rohE 'className="[^"]+"' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    
    unique_classnames=$(echo "$unique_classnames" | grep -oE '^[0-9]+' | head -1); [ -z "$unique_classnames" ] && unique_classnames=0
    total_classnames=$(echo "$total_classnames" | grep -oE '^[0-9]+' | head -1); [ -z "$total_classnames" ] && total_classnames=0
    
    # Calculate entropy score
    local entropy_ratio=100
    [ "$total_classnames" -gt 0 ] && entropy_ratio=$(math_int "$unique_classnames * 100 / $total_classnames")
    
    # One-off component detection (components used only once)
    local component_imports=$(grep -rohE "import.*from ['\"][^'\"]*components[^'\"]*['\"]" "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | sort | uniq -c | sort -n)
    local single_use_components=$(echo "$component_imports" | awk '$1 == 1' | wc -l | tr -d '[:space:]')
    single_use_components=$(echo "$single_use_components" | grep -oE '^[0-9]+' | head -1); [ -z "$single_use_components" ] && single_use_components=0
    
    # Style divergence (inline styles vs consistent)
    local inline_styles=$({ grep -rohE 'style=\{[^}]+\}' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    inline_styles=$(echo "$inline_styles" | grep -oE '^[0-9]+' | head -1); [ -z "$inline_styles" ] && inline_styles=0
    
    # Component reuse ratio
    local total_component_files=$(find "$CODEBASE_PATH" -path "*/components/*" -name "*.tsx" -o -path "*/components/*" -name "*.jsx" ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    total_component_files=$(echo "$total_component_files" | grep -oE '^[0-9]+' | head -1); [ -z "$total_component_files" ] && total_component_files=0
    
    local reuse_ratio=0
    [ "$total_component_files" -gt 0 ] && [ "$single_use_components" -ge 0 ] && \
        reuse_ratio=$(math_int "100 - ($single_use_components * 100 / $total_component_files)")
    [ "$reuse_ratio" -lt 0 ] && reuse_ratio=0
    
    # New component creation (check recent additions - proxy via TODO/FIXME)
    local tech_debt_markers=$(grep -rohE 'TODO|FIXME|HACK|XXX' "$CODEBASE_PATH" $includes --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    tech_debt_markers=$(echo "$tech_debt_markers" | grep -oE '^[0-9]+' | head -1); [ -z "$tech_debt_markers" ] && tech_debt_markers=0
    
    # Score (lower entropy = better)
    local score=5
    [ "$entropy_ratio" -lt 50 ] && score=$((score + 2))
    [ "$entropy_ratio" -gt 80 ] && score=$((score - 1))
    [ "$single_use_components" -lt 10 ] && score=$((score + 1))
    [ "$reuse_ratio" -gt 70 ] && score=$((score + 1))
    [ "$inline_styles" -lt 50 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$entropy_ratio" -gt 70 ] && findings=$(echo "$findings" | jq --arg r "$entropy_ratio" '. + ["UI entropy at " + $r + "% - high pattern uniqueness indicates inconsistency"]')
    [ "$single_use_components" -gt 20 ] && findings=$(echo "$findings" | jq --arg c "$single_use_components" '. + [$c + " single-use components - consider consolidation"]')
    [ "$reuse_ratio" -lt 50 ] && findings=$(echo "$findings" | jq --arg r "$reuse_ratio" '. + ["Component reuse at " + $r + "% - low reuse indicates fragmentation"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson unique_patterns "$unique_classnames" \
        --argjson total_patterns "$total_classnames" \
        --arg entropy_ratio "${entropy_ratio}%" \
        --argjson single_use_components "$single_use_components" \
        --argjson total_components "$total_component_files" \
        --arg reuse_ratio "${reuse_ratio}%" \
        --argjson inline_styles "$inline_styles" \
        --argjson tech_debt_markers "$tech_debt_markers" \
        --argjson findings "$findings" \
        '{score: $score, entropy: {unique_patterns: $unique_patterns, total_patterns: $total_patterns, entropy_ratio: $entropy_ratio}, component_reuse: {single_use: $single_use_components, total: $total_components, reuse_ratio: $reuse_ratio}, style_divergence: {inline_styles: $inline_styles}, tech_debt_markers: $tech_debt_markers, findings: $findings}'
}

# =============================================================================
# 27. DEVELOPER EXPERIENCE (DX) SIGNALS
# =============================================================================
analyze_dx() {
    echo "  [27/27] Developer Experience (DX)..." >&2
    
    # Storybook completeness
    local has_storybook=false
    local story_files=0
    [ -d "$CODEBASE_PATH/.storybook" ] && has_storybook=true
    story_files=$(find "$CODEBASE_PATH" -name "*.stories.tsx" -o -name "*.stories.jsx" -o -name "*.stories.ts" ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    story_files=$(echo "$story_files" | grep -oE '^[0-9]+' | head -1); [ -z "$story_files" ] && story_files=0
    
    # Component count for ratio
    local component_files=$(find "$CODEBASE_PATH" -path "*/components/*" \( -name "*.tsx" -o -name "*.jsx" \) ! -name "*.stories.*" ! -name "*.test.*" ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    component_files=$(echo "$component_files" | grep -oE '^[0-9]+' | head -1); [ -z "$component_files" ] && component_files=0
    
    local story_coverage=0
    [ "$component_files" -gt 0 ] && story_coverage=$(math_int "$story_files * 100 / $component_files")
    
    # TypeScript prop documentation
    local typed_props=$(grep -rohE 'interface.*Props|type.*Props' "$CODEBASE_PATH" --include="*.tsx" --include="*.ts" --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d '[:space:]')
    typed_props=$(echo "$typed_props" | grep -oE '^[0-9]+' | head -1); [ -z "$typed_props" ] && typed_props=0
    
    # JSDoc comments
    local jsdoc_comments=$({ grep -rohE '/\*\*' "$CODEBASE_PATH" --include="*.tsx" --include="*.ts" --include="*.jsx" --exclude-dir=node_modules 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
    jsdoc_comments=$(echo "$jsdoc_comments" | grep -oE '^[0-9]+' | head -1); [ -z "$jsdoc_comments" ] && jsdoc_comments=0
    
    # README in components directory
    local has_component_readme=false
    [ -f "$CODEBASE_PATH/src/components/README.md" ] || [ -f "$CODEBASE_PATH/components/README.md" ] && has_component_readme=true
    
    # Example usage files
    local example_files=$(find "$CODEBASE_PATH" -name "*.example.*" -o -name "*Example.tsx" -o -name "*Demo.tsx" ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    example_files=$(echo "$example_files" | grep -oE '^[0-9]+' | head -1); [ -z "$example_files" ] && example_files=0
    
    # Component generator/scaffolding
    local has_generators=false
    [ -f "$CODEBASE_PATH/plop-templates" ] || [ -f "$CODEBASE_PATH/plopfile.js" ] || \
    grep -rqE '"plop"|"hygen"' "$CODEBASE_PATH" --include="package.json" --exclude-dir=node_modules 2>/dev/null && has_generators=true
    
    # Testing coverage (test files exist)
    local test_files=$(find "$CODEBASE_PATH" -name "*.test.tsx" -o -name "*.spec.tsx" -o -name "*.test.ts" ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d '[:space:]')
    test_files=$(echo "$test_files" | grep -oE '^[0-9]+' | head -1); [ -z "$test_files" ] && test_files=0
    
    # Score
    local score=5
    [ "$has_storybook" = true ] && score=$((score + 1))
    [ "$story_coverage" -gt 50 ] && score=$((score + 1))
    [ "$typed_props" -gt 20 ] && score=$((score + 1))
    [ "$jsdoc_comments" -gt 10 ] && score=$((score + 1))
    [ "$has_generators" = true ] && score=$((score + 1))
    [ "$test_files" -gt 10 ] && score=$((score + 1))
    
    local findings='[]'
    [ "$has_storybook" = false ] && findings=$(echo "$findings" | jq '. + ["No Storybook - component discovery is difficult"]')
    [ "$story_coverage" -lt 30 ] && [ "$has_storybook" = true ] && findings=$(echo "$findings" | jq --arg c "$story_coverage" '. + ["Only " + $c + "% of components have stories"]')
    [ "$typed_props" -lt 10 ] && findings=$(echo "$findings" | jq '. + ["Few typed Props interfaces - poor IDE support"]')
    [ "$jsdoc_comments" -lt 5 ] && findings=$(echo "$findings" | jq '. + ["Minimal JSDoc documentation"]')
    
    [ "$score" -gt 10 ] && score=10
    
    jq -n \
        --argjson score "$score" \
        --argjson has_storybook "$has_storybook" \
        --argjson story_files "$story_files" \
        --argjson component_files "$component_files" \
        --arg story_coverage "${story_coverage}%" \
        --argjson typed_props "$typed_props" \
        --argjson jsdoc_comments "$jsdoc_comments" \
        --argjson has_component_readme "$has_component_readme" \
        --argjson example_files "$example_files" \
        --argjson has_generators "$has_generators" \
        --argjson test_files "$test_files" \
        --argjson findings "$findings" \
        '{score: $score, storybook: {exists: $has_storybook, story_files: $story_files, coverage: $story_coverage}, documentation: {typed_props: $typed_props, jsdoc_comments: $jsdoc_comments, component_readme: $has_component_readme}, examples: $example_files, generators: $has_generators, test_files: $test_files, findings: $findings}'
}

# =============================================================================
# GENERATE EXECUTIVE SUMMARY - 27 ELITE CATEGORIES
# =============================================================================
generate_summary() {
    # Core 12 categories
    local tokens="$1" colors="$2" typography="$3" spacing="$4" components="$5"
    local responsive="$6" motion="$7" accessibility="$8" architecture="$9" darkmode="${10}"
    local zindex="${11}" hierarchy="${12}"
    # Elite 15 categories (13-27)
    local visual_regression="${13}" token_coverage="${14}" component_api="${15}"
    local state_coverage="${16}" form_ux="${17}" layout_stability="${18}"
    local input_modality="${19}" iconography="${20}" microcopy="${21}"
    local ui_performance="${22}" i18n="${23}" ux_safety="${24}"
    local design_parity="${25}" entropy="${26}" dx="${27}"
    
    # Extract all 27 scores
    local s1=$(echo "$tokens" | jq -r '.score // 5')
    local s2=$(echo "$colors" | jq -r '.score // 5')
    local s3=$(echo "$typography" | jq -r '.score // 5')
    local s4=$(echo "$spacing" | jq -r '.score // 5')
    local s5=$(echo "$components" | jq -r '.score // 5')
    local s6=$(echo "$responsive" | jq -r '.score // 5')
    local s7=$(echo "$motion" | jq -r '.score // 5')
    local s8=$(echo "$accessibility" | jq -r '.score // 5')
    local s9=$(echo "$architecture" | jq -r '.score // 5')
    local s10=$(echo "$darkmode" | jq -r '.score // 5')
    local s11=$(echo "$zindex" | jq -r '.score // 5')
    local s12=$(echo "$hierarchy" | jq -r '.score // 5')
    local s13=$(echo "$visual_regression" | jq -r '.score // 5')
    local s14=$(echo "$token_coverage" | jq -r '.score // 5')
    local s15=$(echo "$component_api" | jq -r '.score // 5')
    local s16=$(echo "$state_coverage" | jq -r '.score // 5')
    local s17=$(echo "$form_ux" | jq -r '.score // 5')
    local s18=$(echo "$layout_stability" | jq -r '.score // 5')
    local s19=$(echo "$input_modality" | jq -r '.score // 5')
    local s20=$(echo "$iconography" | jq -r '.score // 5')
    local s21=$(echo "$microcopy" | jq -r '.score // 5')
    local s22=$(echo "$ui_performance" | jq -r '.score // 5')
    local s23=$(echo "$i18n" | jq -r '.score // 5')
    local s24=$(echo "$ux_safety" | jq -r '.score // 5')
    local s25=$(echo "$design_parity" | jq -r '.score // 5')
    local s26=$(echo "$entropy" | jq -r '.score // 5')
    local s27=$(echo "$dx" | jq -r '.score // 5')
    
    # Weighted scoring (total = 270 weight points)
    # Critical: accessibility (15), form_ux (12), ux_safety (12), layout_stability (10)
    # High: colors (10), responsive (10), architecture (10), components (8), token_coverage (8), state_coverage (8), i18n (8)
    # Medium: typography (7), spacing (7), tokens (6), darkmode (6), component_api (7), performance (7), entropy (7), dx (7)
    # Standard: motion (5), zindex (5), hierarchy (5), visual_regression (5), input_modality (5), iconography (5), microcopy (5), design_parity (5)
    
    local weight_sum=200
    local weighted_sum=$(math_calc "$s1*6 + $s2*10 + $s3*7 + $s4*7 + $s5*8 + $s6*10 + $s7*5 + $s8*15 + $s9*10 + $s10*6 + $s11*5 + $s12*5 + $s13*5 + $s14*8 + $s15*7 + $s16*8 + $s17*12 + $s18*10 + $s19*5 + $s20*5 + $s21*5 + $s22*7 + $s23*8 + $s24*12 + $s25*5 + $s26*7 + $s27*7")

    local overall=$(math_calc "$weighted_sum / $weight_sum" 1)
    
    # Collect all findings from 27 categories
    local all_findings=$(jq -s 'map(.findings // []) | add // []' <<< "$tokens
$colors
$typography
$spacing
$components
$responsive
$motion
$accessibility
$architecture
$darkmode
$zindex
$hierarchy
$visual_regression
$token_coverage
$component_api
$state_coverage
$form_ux
$layout_stability
$input_modality
$iconography
$microcopy
$ui_performance
$i18n
$ux_safety
$design_parity
$entropy
$dx")
    
    # ===========================================================================
    # SECOND-ORDER METRICS (Elite Team KPIs)
    # ===========================================================================
    
    # 1. Consistency Debt Index (lower is better, 0-100)
    # Measures accumulated inconsistencies across design system
    local token_ratio=$(echo "$token_coverage" | jq -r '.metrics.token_usage_ratio // 0')
    local entropy_ratio=$(echo "$entropy" | jq -r '.metrics.ui_entropy_ratio // 0')
    local important_count=$(echo "$architecture" | jq -r '.metrics.important_count // 0')
    local hardcoded=$(echo "$token_coverage" | jq -r '.metrics.hardcoded_colors // 0')
    local consistency_debt=$(math_calc "100 - ($token_ratio * 50) - ((10 - $entropy_ratio) * 3) + ($important_count / 10) + ($hardcoded / 5)" 1)
    math_compare "$consistency_debt" "<" "0" && consistency_debt=0
    math_compare "$consistency_debt" ">" "100" && consistency_debt=100
    
    # 2. Accessibility Risk Score (0-100, lower is better)
    # Aggregates all a11y-related issues
    local a11y_score=$s8
    local form_score=$s17
    local input_score=$s19
    local contrast_issues=$(echo "$colors" | jq -r '.metrics.potential_contrast_issues // 0')
    local accessibility_risk=$(math_calc "100 - ($a11y_score * 5) - ($form_score * 3) - ($input_score * 2) + ($contrast_issues * 2)" 1)
    math_compare "$accessibility_risk" "<" "0" && accessibility_risk=0
    math_compare "$accessibility_risk" ">" "100" && accessibility_risk=100
    
    # 3. UI Entropy Trend (derived from entropy analysis)
    local unique_patterns=$(echo "$entropy" | jq -r '.metrics.unique_patterns // 0')
    local total_components=$(echo "$components" | jq -r '.metrics.total_components // 1')
    local ui_entropy_trend=$(math_calc "$unique_patterns / ($total_components + 1)")
    
    # 4. Token Adoption Velocity (percentage of codebase using tokens)
    local token_files=$(echo "$token_coverage" | jq -r '.metrics.files_using_tokens // 0')
    local total_style_files=$(echo "$architecture" | jq -r '.metrics.total_css_files // 1')
    local token_adoption=$(math_calc "($token_files / ($total_style_files + 1)) * 100" 1)
    math_compare "$token_adoption" ">" "100" && token_adoption=100
    
    # 5. Component Reuse Ratio
    local reuse_ratio=$(echo "$entropy" | jq -r '.metrics.component_reuse_ratio // 0')
    
    # Grade calculation
    local grade=$(math_grade "$overall")
    
    # Maturity level based on elite metrics
    local maturity="Level 1: Ad-Hoc"
    math_compare "$overall" ">=" "5" && maturity="Level 2: Emerging"
    math_compare "$overall" ">=" "6.5" && maturity="Level 3: Defined"
    math_compare "$overall" ">=" "7.5" && maturity="Level 4: Managed"
    math_compare "$overall" ">=" "8.5" && maturity="Level 5: Optimizing"
    math_compare "$overall" ">=" "9.5" && maturity="Level 6: World-Class"
    
    jq -n \
        --argjson overall "$overall" \
        --arg grade "$grade" \
        --arg maturity "$maturity" \
        --argjson design_tokens "$s1" \
        --argjson color_system "$s2" \
        --argjson typography "$s3" \
        --argjson spacing "$s4" \
        --argjson components "$s5" \
        --argjson responsive "$s6" \
        --argjson motion "$s7" \
        --argjson accessibility "$s8" \
        --argjson architecture "$s9" \
        --argjson dark_mode "$s10" \
        --argjson z_index "$s11" \
        --argjson hierarchy "$s12" \
        --argjson visual_regression "$s13" \
        --argjson token_coverage "$s14" \
        --argjson component_api "$s15" \
        --argjson state_coverage "$s16" \
        --argjson form_ux "$s17" \
        --argjson layout_stability "$s18" \
        --argjson input_modality "$s19" \
        --argjson iconography "$s20" \
        --argjson microcopy "$s21" \
        --argjson ui_performance "$s22" \
        --argjson i18n "$s23" \
        --argjson ux_safety "$s24" \
        --argjson design_parity "$s25" \
        --argjson entropy "$s26" \
        --argjson dx "$s27" \
        --argjson consistency_debt "$consistency_debt" \
        --argjson accessibility_risk "$accessibility_risk" \
        --argjson ui_entropy_trend "$ui_entropy_trend" \
        --argjson token_adoption "$token_adoption" \
        --argjson component_reuse "$reuse_ratio" \
        --argjson all_findings "$all_findings" \
        '{
            overall_score: $overall,
            grade: $grade,
            maturity_level: $maturity,
            subscores: {
                core: {
                    design_tokens: $design_tokens,
                    color_system: $color_system,
                    typography: $typography,
                    spacing: $spacing,
                    components: $components,
                    responsive: $responsive,
                    motion: $motion,
                    accessibility: $accessibility,
                    architecture: $architecture,
                    dark_mode: $dark_mode,
                    z_index: $z_index,
                    hierarchy: $hierarchy
                },
                elite: {
                    visual_regression: $visual_regression,
                    token_coverage: $token_coverage,
                    component_api: $component_api,
                    state_coverage: $state_coverage,
                    form_ux: $form_ux,
                    layout_stability: $layout_stability,
                    input_modality: $input_modality,
                    iconography: $iconography,
                    microcopy: $microcopy,
                    ui_performance: $ui_performance,
                    i18n: $i18n,
                    ux_safety: $ux_safety,
                    design_parity: $design_parity,
                    entropy: $entropy,
                    dx: $dx
                }
            },
            second_order_metrics: {
                consistency_debt_index: $consistency_debt,
                accessibility_risk_score: $accessibility_risk,
                ui_entropy_trend: $ui_entropy_trend,
                token_adoption_velocity: $token_adoption,
                component_reuse_ratio: $component_reuse
            },
            total_findings: ($all_findings | length),
            critical_findings: [$all_findings[] | select(contains("accessibility") or contains("!important") or contains("outline") or contains("skip") or contains("CRITICAL") or contains("destructive") or contains("unsafe"))],
            all_findings: $all_findings
        }'
}

# =============================================================================
# MAIN - 27-CATEGORY WORLD-CLASS UI/UX AUDIT
# =============================================================================
main() {
    echo "╔═══════════════════════════════════════════════════════════════════════╗" >&2
    echo "║    🏆 WORLD-CLASS UI/UX CONSISTENCY AUDIT - 27 ELITE CATEGORIES 🏆    ║" >&2
    echo "║         The Most Comprehensive Design System Analysis Ever            ║" >&2
    echo "╚═══════════════════════════════════════════════════════════════════════╝" >&2
    echo "" >&2
    echo "📂 Codebase: $CODEBASE_PATH" >&2
    echo "" >&2
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "🔍 PHASE 1: Core Design System Analysis (1-12)" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    
    echo "  [1/27] Analyzing Design Tokens..." >&2
    local tokens=$(analyze_design_tokens)
    
    echo "  [2/27] Analyzing Color System..." >&2
    local colors=$(analyze_color_system)
    
    echo "  [3/27] Analyzing Typography..." >&2
    local typography=$(analyze_typography)
    
    echo "  [4/27] Analyzing Spacing System..." >&2
    local spacing=$(analyze_spacing)
    
    echo "  [5/27] Analyzing Component Library..." >&2
    local components=$(analyze_components)
    
    echo "  [6/27] Analyzing Responsive Design..." >&2
    local responsive=$(analyze_responsive)
    
    echo "  [7/27] Analyzing Motion & Animation..." >&2
    local motion=$(analyze_motion)
    
    echo "  [8/27] Analyzing Accessibility (a11y)..." >&2
    local accessibility=$(analyze_accessibility)
    
    echo "  [9/27] Analyzing CSS Architecture..." >&2
    local architecture=$(analyze_css_architecture)
    
    echo "  [10/27] Analyzing Dark Mode..." >&2
    local darkmode=$(analyze_dark_mode)
    
    echo "  [11/27] Analyzing Z-Index Management..." >&2
    local zindex=$(analyze_zindex)
    
    echo "  [12/27] Analyzing Visual Hierarchy..." >&2
    local hierarchy=$(analyze_hierarchy)
    
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "🚀 PHASE 2: Elite-Level Deep Analysis (13-27)" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    
    echo "  [13/27] Analyzing Visual Regression Testing..." >&2
    local visual_regression=$(analyze_visual_regression)
    
    echo "  [14/27] Analyzing Token Coverage & Enforcement..." >&2
    local token_coverage=$(analyze_token_coverage)
    
    echo "  [15/27] Analyzing Component API Consistency..." >&2
    local component_api=$(analyze_component_api)
    
    echo "  [16/27] Analyzing State Design Coverage..." >&2
    local state_coverage=$(analyze_state_coverage)
    
    echo "  [17/27] Analyzing Form UX & Validation..." >&2
    local form_ux=$(analyze_form_ux)
    
    echo "  [18/27] Analyzing Layout Stability (CLS)..." >&2
    local layout_stability=$(analyze_layout_stability)
    
    echo "  [19/27] Analyzing Input Modality Support..." >&2
    local input_modality=$(analyze_input_modality)
    
    echo "  [20/27] Analyzing Iconography System..." >&2
    local iconography=$(analyze_iconography)
    
    echo "  [21/27] Analyzing Microcopy Consistency..." >&2
    local microcopy=$(analyze_microcopy)
    
    echo "  [22/27] Analyzing UI Performance Patterns..." >&2
    local ui_performance=$(analyze_ui_performance)
    
    echo "  [23/27] Analyzing i18n & Text Resilience..." >&2
    local i18n=$(analyze_i18n)
    
    echo "  [24/27] Analyzing UX Safety & Error Prevention..." >&2
    local ux_safety=$(analyze_ux_safety)
    
    echo "  [25/27] Analyzing Design-Code Parity..." >&2
    local design_parity=$(analyze_design_parity)
    
    echo "  [26/27] Analyzing Entropy & Governance..." >&2
    local entropy=$(analyze_entropy)
    
    echo "  [27/27] Analyzing Developer Experience (DX)..." >&2
    local dx=$(analyze_dx)
    
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "📊 Generating Executive Summary & Second-Order Metrics..." >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    
    # Generate summary with all 27 categories
    local summary=$(generate_summary \
        "$tokens" "$colors" "$typography" "$spacing" "$components" \
        "$responsive" "$motion" "$accessibility" "$architecture" "$darkmode" \
        "$zindex" "$hierarchy" \
        "$visual_regression" "$token_coverage" "$component_api" \
        "$state_coverage" "$form_ux" "$layout_stability" \
        "$input_modality" "$iconography" "$microcopy" \
        "$ui_performance" "$i18n" "$ux_safety" \
        "$design_parity" "$entropy" "$dx")
    
    # Build final comprehensive output
    local RESULTS=$(jq -n \
        --arg category "uiux_audit_elite" \
        --argjson summary "$summary" \
        --argjson design_tokens "$tokens" \
        --argjson color_system "$colors" \
        --argjson typography "$typography" \
        --argjson spacing "$spacing" \
        --argjson components "$components" \
        --argjson responsive "$responsive" \
        --argjson motion "$motion" \
        --argjson accessibility "$accessibility" \
        --argjson css_architecture "$architecture" \
        --argjson dark_mode "$darkmode" \
        --argjson z_index "$zindex" \
        --argjson hierarchy "$hierarchy" \
        --argjson visual_regression "$visual_regression" \
        --argjson token_coverage "$token_coverage" \
        --argjson component_api "$component_api" \
        --argjson state_coverage "$state_coverage" \
        --argjson form_ux "$form_ux" \
        --argjson layout_stability "$layout_stability" \
        --argjson input_modality "$input_modality" \
        --argjson iconography "$iconography" \
        --argjson microcopy "$microcopy" \
        --argjson ui_performance "$ui_performance" \
        --argjson i18n "$i18n" \
        --argjson ux_safety "$ux_safety" \
        --argjson design_parity "$design_parity" \
        --argjson entropy "$entropy" \
        --argjson dx "$dx" \
        '{
            category: $category,
            summary: $summary,
            detailed_analysis: {
                core: {
                    design_tokens: $design_tokens,
                    color_system: $color_system,
                    typography: $typography,
                    spacing: $spacing,
                    components: $components,
                    responsive: $responsive,
                    motion: $motion,
                    accessibility: $accessibility,
                    css_architecture: $css_architecture,
                    dark_mode: $dark_mode,
                    z_index: $z_index,
                    hierarchy: $hierarchy
                },
                elite: {
                    visual_regression: $visual_regression,
                    token_coverage: $token_coverage,
                    component_api: $component_api,
                    state_coverage: $state_coverage,
                    form_ux: $form_ux,
                    layout_stability: $layout_stability,
                    input_modality: $input_modality,
                    iconography: $iconography,
                    microcopy: $microcopy,
                    ui_performance: $ui_performance,
                    i18n: $i18n,
                    ux_safety: $ux_safety,
                    design_parity: $design_parity,
                    entropy: $entropy,
                    dx: $dx
                }
            }
        }')
    
    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    
    # Extract summary data
    local overall=$(echo "$summary" | jq -r '.overall_score')
    local grade=$(echo "$summary" | jq -r '.grade')
    local maturity=$(echo "$summary" | jq -r '.maturity_level')
    local findings_count=$(echo "$summary" | jq -r '.total_findings')
    local critical_count=$(echo "$summary" | jq -r '.critical_findings | length')
    
    # Second-order metrics
    local debt=$(echo "$summary" | jq -r '.second_order_metrics.consistency_debt_index')
    local a11y_risk=$(echo "$summary" | jq -r '.second_order_metrics.accessibility_risk_score')
    local entropy_trend=$(echo "$summary" | jq -r '.second_order_metrics.ui_entropy_trend')
    local token_velocity=$(echo "$summary" | jq -r '.second_order_metrics.token_adoption_velocity')
    local reuse_ratio=$(echo "$summary" | jq -r '.second_order_metrics.component_reuse_ratio')
    
    # Print comprehensive results
    echo "" >&2
    echo "╔═══════════════════════════════════════════════════════════════════════╗" >&2
    echo "║                    🏆 ELITE AUDIT COMPLETE 🏆                         ║" >&2
    echo "╚═══════════════════════════════════════════════════════════════════════╝" >&2
    echo "" >&2
    echo "  📈 OVERALL SCORE: $overall/10 | Grade: $grade" >&2
    echo "  🎯 MATURITY: $maturity" >&2
    echo "  🔍 Total Findings: $findings_count | Critical: $critical_count" >&2
    echo "" >&2
    
    echo "┌─────────────────────────────────────────────────────────────────────┐" >&2
    echo "│                    CORE DESIGN SYSTEM (1-12)                       │" >&2
    echo "├─────────────────────────────────────────────────────────────────────┤" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "Design Tokens:" "$(echo "$tokens" | jq -r '.score')" "Color System:" "$(echo "$colors" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "Typography:" "$(echo "$typography" | jq -r '.score')" "Spacing:" "$(echo "$spacing" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "Components:" "$(echo "$components" | jq -r '.score')" "Responsive:" "$(echo "$responsive" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "Motion:" "$(echo "$motion" | jq -r '.score')" "Accessibility:" "$(echo "$accessibility" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "CSS Architecture:" "$(echo "$architecture" | jq -r '.score')" "Dark Mode:" "$(echo "$darkmode" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "Z-Index:" "$(echo "$zindex" | jq -r '.score')" "Hierarchy:" "$(echo "$hierarchy" | jq -r '.score')" >&2
    echo "└─────────────────────────────────────────────────────────────────────┘" >&2
    echo "" >&2
    
    echo "┌─────────────────────────────────────────────────────────────────────┐" >&2
    echo "│                    ELITE ANALYSIS (13-27)                          │" >&2
    echo "├─────────────────────────────────────────────────────────────────────┤" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "Visual Regression:" "$(echo "$visual_regression" | jq -r '.score')" "Token Coverage:" "$(echo "$token_coverage" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "Component API:" "$(echo "$component_api" | jq -r '.score')" "State Coverage:" "$(echo "$state_coverage" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "Form UX:" "$(echo "$form_ux" | jq -r '.score')" "Layout Stability:" "$(echo "$layout_stability" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "Input Modality:" "$(echo "$input_modality" | jq -r '.score')" "Iconography:" "$(echo "$iconography" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "Microcopy:" "$(echo "$microcopy" | jq -r '.score')" "UI Performance:" "$(echo "$ui_performance" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "i18n:" "$(echo "$i18n" | jq -r '.score')" "UX Safety:" "$(echo "$ux_safety" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │  %-22s %s/10  │\n" "Design Parity:" "$(echo "$design_parity" | jq -r '.score')" "Entropy:" "$(echo "$entropy" | jq -r '.score')" >&2
    printf "│  %-22s %s/10  │                                │\n" "Developer Experience:" "$(echo "$dx" | jq -r '.score')" >&2
    echo "└─────────────────────────────────────────────────────────────────────┘" >&2
    echo "" >&2
    
    echo "┌─────────────────────────────────────────────────────────────────────┐" >&2
    echo "│                  SECOND-ORDER METRICS (KPIs)                       │" >&2
    echo "├─────────────────────────────────────────────────────────────────────┤" >&2
    echo "│  📊 Consistency Debt Index:     $debt (lower is better)            │" >&2
    echo "│  ♿ Accessibility Risk Score:   $a11y_risk (lower is better)       │" >&2
    echo "│  📈 UI Entropy Trend:           $entropy_trend                     │" >&2
    echo "│  🎨 Token Adoption Velocity:    $token_velocity%                   │" >&2
    echo "│  ♻️  Component Reuse Ratio:      $reuse_ratio                       │" >&2
    echo "└─────────────────────────────────────────────────────────────────────┘" >&2
    echo "" >&2
    
    echo "  📁 Full results saved to: $OUTPUT_FILE" >&2
    echo "" >&2
    echo "═══════════════════════════════════════════════════════════════════════" >&2
}

main
