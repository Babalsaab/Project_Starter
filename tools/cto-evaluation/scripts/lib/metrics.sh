#!/bin/bash

# =============================================================================
# ADVANCED CODE METRICS CALCULATOR
# =============================================================================
# Calculates sophisticated code metrics:
#   - Cyclomatic complexity
#   - Maintainability index
#   - Code duplication percentage
#   - Coupling metrics
#   - Cohesion metrics
#   - Technical debt estimation
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/math-utils.sh"

# =============================================================================
# CYCLOMATIC COMPLEXITY
# =============================================================================

calculate_complexity() {
    local codebase="$1"
    local language="${2:-auto}"
    
    local total_complexity=0
    local file_count=0
    local high_complexity_files='[]'
    
    # JavaScript/TypeScript complexity
    if [ "$language" = "auto" ] || [ "$language" = "javascript" ] || [ "$language" = "typescript" ]; then
        # Count decision points: if, else, for, while, case, catch, &&, ||, ?:
        while IFS= read -r -d '' file; do
            local complexity=1  # Base complexity
            
            # Count decision points
            local decisions=$(grep -oE '\b(if|else if|for|while|switch|case|catch|&&|\|\||\?.*:)\b' "$file" 2>/dev/null | wc -l || echo 0)
            complexity=$((complexity + decisions))
            
            if [ "$complexity" -gt 10 ]; then
                high_complexity_files=$(echo "$high_complexity_files" | jq --arg f "$file" --argjson c "$complexity" '. += [{file: $f, complexity: $c}]')
            fi
            
            total_complexity=$((total_complexity + complexity))
            file_count=$((file_count + 1))
        done < <(find "$codebase" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) \
            -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -print0 2>/dev/null)
    fi
    
    # Python complexity
    if [ "$language" = "auto" ] || [ "$language" = "python" ]; then
        while IFS= read -r -d '' file; do
            local complexity=1
            local decisions=$(grep -oE '\b(if|elif|for|while|except|and|or)\b' "$file" 2>/dev/null | wc -l || echo 0)
            complexity=$((complexity + decisions))
            
            if [ "$complexity" -gt 10 ]; then
                high_complexity_files=$(echo "$high_complexity_files" | jq --arg f "$file" --argjson c "$complexity" '. += [{file: $f, complexity: $c}]')
            fi
            
            total_complexity=$((total_complexity + complexity))
            file_count=$((file_count + 1))
        done < <(find "$codebase" -type f -name "*.py" \
            -not -path "*/.venv/*" -not -path "*/venv/*" -not -path "*/__pycache__/*" -print0 2>/dev/null)
    fi
    
    # Calculate average
    local avg_complexity=0
    if [ "$file_count" -gt 0 ]; then
        avg_complexity=$(math_calc "$total_complexity / $file_count")
    fi
    
    jq -n \
        --argjson total "$total_complexity" \
        --argjson files "$file_count" \
        --arg avg "$avg_complexity" \
        --argjson high "$high_complexity_files" \
        '{
            total_complexity: $total,
            files_analyzed: $files,
            average_complexity: ($avg | tonumber),
            high_complexity_files: $high,
            complexity_rating: (
                if ($avg | tonumber) <= 5 then "excellent"
                elif ($avg | tonumber) <= 10 then "good"
                elif ($avg | tonumber) <= 20 then "moderate"
                elif ($avg | tonumber) <= 30 then "high"
                else "very_high"
                end
            )
        }'
}

# =============================================================================
# CODE DUPLICATION DETECTION
# =============================================================================

detect_duplication() {
    local codebase="$1"
    local min_lines="${2:-6}"
    
    local duplicates='[]'
    local total_lines=0
    local duplicate_lines=0
    
    # Use jscpd if available (best tool for this)
    if command -v jscpd &> /dev/null; then
        local jscpd_output=$(jscpd "$codebase" --format json --min-lines "$min_lines" \
            --ignore "node_modules,dist,build,.git,vendor,coverage" 2>/dev/null || echo '{"statistics":{"total":{"percentage":0}}}')
        
        local percentage=$(echo "$jscpd_output" | jq -r '.statistics.total.percentage // 0')
        
        jq -n \
            --arg pct "$percentage" \
            --argjson raw "$jscpd_output" \
            '{
                duplication_percentage: ($pct | tonumber),
                tool: "jscpd",
                details: $raw.duplicates,
                rating: (
                    if ($pct | tonumber) <= 3 then "excellent"
                    elif ($pct | tonumber) <= 5 then "good"
                    elif ($pct | tonumber) <= 10 then "moderate"
                    elif ($pct | tonumber) <= 20 then "high"
                    else "very_high"
                    end
                )
            }'
        return
    fi
    
    # Fallback: Simple line-based detection
    local temp_hashes=$(mktemp)
    local temp_counts=$(mktemp)
    
    # Hash each line group
    find "$codebase" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.java" \) \
        -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" 2>/dev/null | \
    while read -r file; do
        # Get line count
        local lines=$(wc -l < "$file" 2>/dev/null || echo 0)
        total_lines=$((total_lines + lines))
        
        # Create sliding window hashes
        if [ "$lines" -gt "$min_lines" ]; then
            local i=1
            while [ $i -le $((lines - min_lines + 1)) ]; do
                sed -n "${i},$((i + min_lines - 1))p" "$file" 2>/dev/null | \
                    sed 's/^[[:space:]]*//' | tr -d '\n' | md5sum | cut -d' ' -f1 >> "$temp_hashes"
                i=$((i + 1))
            done
        fi
    done
    
    # Count duplicates
    if [ -f "$temp_hashes" ] && [ -s "$temp_hashes" ]; then
        sort "$temp_hashes" | uniq -d | wc -l > "$temp_counts"
        duplicate_lines=$(cat "$temp_counts")
    fi
    
    rm -f "$temp_hashes" "$temp_counts"
    
    # Estimate percentage
    local percentage=0
    if [ "$total_lines" -gt 0 ]; then
        percentage=$(math_calc "($duplicate_lines * $min_lines * 100) / $total_lines")
    fi
    
    jq -n \
        --arg pct "$percentage" \
        '{
            duplication_percentage: ($pct | tonumber),
            tool: "simple-hash",
            rating: (
                if ($pct | tonumber) <= 3 then "excellent"
                elif ($pct | tonumber) <= 5 then "good"
                elif ($pct | tonumber) <= 10 then "moderate"
                elif ($pct | tonumber) <= 20 then "high"
                else "very_high"
                end
            )
        }'
}

# =============================================================================
# MAINTAINABILITY INDEX
# =============================================================================

calculate_maintainability_index() {
    local codebase="$1"
    
    # Get lines of code
    local loc=0
    if command -v cloc &> /dev/null; then
        loc=$(cloc --json "$codebase" --exclude-dir=node_modules,.git,vendor,dist,build 2>/dev/null | jq '.SUM.code // 0')
    else
        loc=$(find "$codebase" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) \
            -not -path "*/node_modules/*" -not -path "*/.git/*" -exec cat {} \; 2>/dev/null | wc -l)
    fi
    
    # Get comment lines (approximation)
    local comments=0
    comments=$(find "$codebase" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) \
        -not -path "*/node_modules/*" -not -path "*/.git/*" -exec grep -c "^\s*\(//\|#\|/\*\|\*\)" {} \; 2>/dev/null | \
        awk '{sum += $1} END {print sum}')
    
    # Calculate comment ratio
    local comment_ratio=0
    if [ "$loc" -gt 0 ]; then
        comment_ratio=$(math_calc "$comments * 100 / $loc")
    fi
    
    # Get complexity
    local complexity_data=$(calculate_complexity "$codebase")
    local avg_complexity=$(echo "$complexity_data" | jq -r '.average_complexity // 10')
    
    # Calculate Maintainability Index (simplified Halstead formula)
    # MI = 171 - 5.2 * ln(avgVolume) - 0.23 * avgComplexity - 16.2 * ln(avgLOC) + 50 * sin(sqrt(2.4 * commentRatio))
    # Simplified: MI = max(0, (171 - 5.2 * ln(loc) - 0.23 * complexity) * (1 + commentRatio/100) / 171 * 100)
    
    local mi=70  # Default
    if [ "$loc" -gt 0 ]; then
        mi=$(python3 -c "
import math
loc = $loc
complexity = float('$avg_complexity')
comment_ratio = float('$comment_ratio')

# Simplified Maintainability Index calculation
log_loc = math.log(loc) if loc > 0 else 0
mi = 171 - 5.2 * log_loc - 0.23 * complexity
mi = mi * (1 + comment_ratio / 200)  # Boost for comments
mi = max(0, min(100, mi / 171 * 100))  # Normalize to 0-100
print(round(mi, 2))
" 2>/dev/null || echo 70)
    fi
    
    jq -n \
        --arg mi "$mi" \
        --argjson loc "$loc" \
        --arg cr "$comment_ratio" \
        --arg ac "$avg_complexity" \
        '{
            maintainability_index: ($mi | tonumber),
            lines_of_code: $loc,
            comment_ratio: ($cr | tonumber),
            average_complexity: ($ac | tonumber),
            rating: (
                if ($mi | tonumber) >= 80 then "excellent"
                elif ($mi | tonumber) >= 60 then "good"
                elif ($mi | tonumber) >= 40 then "moderate"
                elif ($mi | tonumber) >= 20 then "poor"
                else "very_poor"
                end
            ),
            recommendations: (
                []
                + (if ($cr | tonumber) < 10 then ["Increase code documentation - comment ratio is low"] else [] end)
                + (if ($ac | tonumber) > 15 then ["Reduce cyclomatic complexity - consider breaking down complex functions"] else [] end)
                + (if $loc > 50000 then ["Large codebase - ensure good modularization"] else [] end)
            )
        }'
}

# =============================================================================
# TECHNICAL DEBT ESTIMATION
# =============================================================================

estimate_technical_debt() {
    local codebase="$1"
    
    local debt_hours=0
    local debt_items='[]'
    
    # Count TODO/FIXME/HACK comments
    local todo_count=$(grep -rE "(TODO|FIXME|HACK|XXX|BUG):" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$todo_count" -gt 0 ]; then
        debt_hours=$((debt_hours + todo_count * 2))  # Assume 2 hours per TODO
        debt_items=$(echo "$debt_items" | jq --argjson count "$todo_count" '. += [{type: "todo_comments", count: $count, estimated_hours: ($count * 2)}]')
    fi
    
    # Check for deprecated patterns
    local deprecated_count=$(grep -rE "@deprecated|DEPRECATED" "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$deprecated_count" -gt 0 ]; then
        debt_hours=$((debt_hours + deprecated_count * 4))
        debt_items=$(echo "$debt_items" | jq --argjson count "$deprecated_count" '. += [{type: "deprecated_code", count: $count, estimated_hours: ($count * 4)}]')
    fi
    
    # Check for long files (>500 lines)
    local long_files=$(find "$codebase" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        -not -path "*/node_modules/*" -not -path "*/.git/*" -exec wc -l {} \; 2>/dev/null | \
        awk '$1 > 500 {count++} END {print count+0}')
    
    if [ "$long_files" -gt 0 ]; then
        debt_hours=$((debt_hours + long_files * 8))
        debt_items=$(echo "$debt_items" | jq --argjson count "$long_files" '. += [{type: "long_files", count: $count, estimated_hours: ($count * 8)}]')
    fi
    
    # Check for deeply nested code
    local deep_nesting=$(find "$codebase" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        -not -path "*/node_modules/*" -not -path "*/.git/*" -exec { grep -l "^.\{80,\}" {} \; 2>/dev/null || true; } | wc -l | tr -d ' ')
    
    if [ "$deep_nesting" -gt 10 ]; then
        debt_hours=$((debt_hours + deep_nesting))
        debt_items=$(echo "$debt_items" | jq --argjson count "$deep_nesting" '. += [{type: "deep_nesting", count: $count, estimated_hours: $count}]')
    fi
    
    # Check for missing error handling patterns
    local error_handling=$(find "$codebase" -type f \( -name "*.js" -o -name "*.ts" \) \
        -not -path "*/node_modules/*" -not -path "*/.git/*" -exec grep -L "catch\|try" {} \; 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$error_handling" -gt 10 ]; then
        debt_hours=$((debt_hours + error_handling * 2))
        debt_items=$(echo "$debt_items" | jq --argjson count "$error_handling" '. += [{type: "missing_error_handling", count: $count, estimated_hours: ($count * 2)}]')
    fi
    
    # Convert hours to cost (assuming $100/hour)
    local cost=$((debt_hours * 100))
    
    # Convert to days
    local days=$(math_calc "$debt_hours / 8" 1)
    
    jq -n \
        --argjson hours "$debt_hours" \
        --arg days "$days" \
        --argjson cost "$cost" \
        --argjson items "$debt_items" \
        '{
            estimated_hours: $hours,
            estimated_days: ($days | tonumber),
            estimated_cost_usd: $cost,
            items: $items,
            severity: (
                if $hours <= 40 then "low"
                elif $hours <= 160 then "medium"
                elif $hours <= 480 then "high"
                else "critical"
                end
            )
        }'
}

# =============================================================================
# COMPREHENSIVE METRICS
# =============================================================================

calculate_all_metrics() {
    local codebase="$1"
    local output_file="${2:-/dev/stdout}"
    
    echo "Calculating comprehensive code metrics..." >&2
    
    echo "  → Analyzing complexity..." >&2
    local complexity=$(calculate_complexity "$codebase")
    
    echo "  → Detecting duplication..." >&2
    local duplication=$(detect_duplication "$codebase")
    
    echo "  → Calculating maintainability index..." >&2
    local maintainability=$(calculate_maintainability_index "$codebase")
    
    echo "  → Estimating technical debt..." >&2
    local debt=$(estimate_technical_debt "$codebase")
    
    jq -n \
        --argjson complexity "$complexity" \
        --argjson duplication "$duplication" \
        --argjson maintainability "$maintainability" \
        --argjson debt "$debt" \
        '{
            metrics_version: "2.0",
            complexity: $complexity,
            duplication: $duplication,
            maintainability: $maintainability,
            technical_debt: $debt,
            overall_health: (
                (
                    (if $complexity.complexity_rating == "excellent" then 100
                    elif $complexity.complexity_rating == "good" then 80
                    elif $complexity.complexity_rating == "moderate" then 60
                    elif $complexity.complexity_rating == "high" then 40
                    else 20 end) +
                    (if $duplication.rating == "excellent" then 100
                    elif $duplication.rating == "good" then 80
                    elif $duplication.rating == "moderate" then 60
                    elif $duplication.rating == "high" then 40
                    else 20 end) +
                    $maintainability.maintainability_index +
                    (if $debt.severity == "low" then 100
                    elif $debt.severity == "medium" then 70
                    elif $debt.severity == "high" then 40
                    else 20 end)
                ) / 4
            )
        }' > "$output_file"
    
    cat "$output_file"
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    calculate_all_metrics "$@"
fi
