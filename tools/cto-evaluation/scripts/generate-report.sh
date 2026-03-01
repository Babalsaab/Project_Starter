#!/bin/bash

# =============================================================================
# REPORT GENERATOR
# =============================================================================
# Aggregates all category results and generates comprehensive report
# =============================================================================

set -euo pipefail

RESULTS_DIR="$1"
CODEBASE_PATH="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SUITE_DIR/templates"

source "$SCRIPT_DIR/common-progress.sh"
source "$SCRIPT_DIR/lib/math-utils.sh"
source "$SCRIPT_DIR/lib/config-reader.sh"

set_total_steps 4

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
REPORT_FILE="$RESULTS_DIR/report.md"
JSON_REPORT="$RESULTS_DIR/report.json"

get_weight() {
    get_category_weight "$1"
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

get_grade() {
    math_grade "$1"
}

get_risk_level() {
    math_risk_level "$1"
}

get_score_bar() {
    math_score_bar "$1"
}

# =============================================================================
# COLLECT RESULTS
# =============================================================================

progress_step "Collecting evaluation results"

# Initialize aggregated results - use files for bash 3.x compatibility
SCORES_FILE="$RESULTS_DIR/.category_scores.tmp"
> "$SCORES_FILE"

TOTAL_WEIGHTED_SCORE=0
TOTAL_WEIGHT=0

# Read each category result file
for result_file in "$RESULTS_DIR"/*.json; do
    if [ -f "$result_file" ]; then
        filename=$(basename "$result_file" .json)

        # Skip the final report file
        if [ "$filename" = "report" ]; then
            continue
        fi

        echo "Scanning: $filename results"
        
        category=$(jq -r '.category // "unknown"' "$result_file")
        score=$(jq -r '.score // 0' "$result_file")

        if [ "$category" != "unknown" ] && [ "$score" != "0" ]; then
            # Store score in temp file
            echo "$category:$score" >> "$SCORES_FILE"

            # Get weight using function
            weight=$(get_weight "$category")

            # Add to weighted total
            weighted=$(math_calc "$score * $weight" 4)
            TOTAL_WEIGHTED_SCORE=$(math_calc "$TOTAL_WEIGHTED_SCORE + $weighted" 4)
            TOTAL_WEIGHT=$((TOTAL_WEIGHT + weight))

            echo "Checking: $category: $score/10 (weight: $weight%)"
        fi
    fi
done

# Calculate final score
if [ "$TOTAL_WEIGHT" -gt 0 ]; then
    FINAL_SCORE=$(math_calc "$TOTAL_WEIGHTED_SCORE / $TOTAL_WEIGHT")
else
    FINAL_SCORE=0
fi

FINAL_GRADE=$(get_grade "$FINAL_SCORE")

progress_step "Calculating final scores"
echo "Analyzing: Final Score: $FINAL_SCORE/10 ($FINAL_GRADE)"

# =============================================================================
# GENERATE MARKDOWN REPORT
# =============================================================================

progress_step "Generating report files"

cat > "$REPORT_FILE" << EOF
# CTO Codebase Evaluation Report

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Codebase** | \`$CODEBASE_PATH\` |
| **Evaluation Date** | $TIMESTAMP |
| **Overall Score** | **$FINAL_SCORE / 10.00** |
| **Grade** | **$FINAL_GRADE** |
| **Technical Risk** | $(get_risk_level "$FINAL_SCORE") |

### Score Visualization

\`\`\`
Overall: $(get_score_bar "$FINAL_SCORE") $FINAL_SCORE/10
\`\`\`

---

## Category Scores

| Category | Score | Grade | Weight | Bar |
|----------|-------|-------|--------|-----|
EOF

# Add category scores to table from temp file
while IFS=':' read -r category score; do
    [ -z "$category" ] && continue
    
    grade=$(get_grade "$score")
    weight=$(get_weight "$category")
    bar=$(get_score_bar "$score")

    # Format category name
    display_name=$(echo "$category" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

    echo "| $display_name | $score | $grade | ${weight}% | \`$bar\` |" >> "$REPORT_FILE"
done < "$SCORES_FILE"

# Continue report
cat >> "$REPORT_FILE" << EOF

---

## Detailed Analysis

EOF

# Add detailed analysis for each category
for result_file in "$RESULTS_DIR"/*.json; do
    if [ -f "$result_file" ]; then
        filename=$(basename "$result_file" .json)

        if [ "$filename" = "report" ]; then
            continue
        fi

        category=$(jq -r '.category // "unknown"' "$result_file")
        score=$(jq -r '.score // 0' "$result_file")

        if [ "$category" != "unknown" ]; then
            display_name=$(echo "$category" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

            cat >> "$REPORT_FILE" << EOF

### $display_name

**Score: $score/10** ($(get_grade "$score"))

EOF

            # Add subscores if available
            subscores=$(jq -r '.subscores // empty' "$result_file")
            if [ -n "$subscores" ] && [ "$subscores" != "null" ]; then
                echo "#### Subscores" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "| Component | Score |" >> "$REPORT_FILE"
                echo "|-----------|-------|" >> "$REPORT_FILE"

                echo "$subscores" | jq -r 'to_entries[] | "| \(.key | gsub("_"; " ") | ascii_upcase) | \(.value) |"' >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
            fi

            # Add findings if available
            findings=$(jq -r '.findings // []' "$result_file")
            findings_count=$(echo "$findings" | jq 'length')

            if [ "$findings_count" -gt 0 ]; then
                echo "#### Findings" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"

                # Group by severity
                for severity in critical high medium low; do
                    severity_findings=$(echo "$findings" | jq -r "[.[] | select(.severity == \"$severity\")]")
                    severity_count=$(echo "$severity_findings" | jq 'length')

                    if [ "$severity_count" -gt 0 ]; then
                        severity_upper=$(echo "$severity" | tr '[:lower:]' '[:upper:]')
                        echo "**$severity_upper ($severity_count)**" >> "$REPORT_FILE"
                        echo "" >> "$REPORT_FILE"

                        # Include location if available
                        echo "$severity_findings" | jq -r '.[] | if .location != "" and .location != null then "- **\(.message)** → `\(.location)`" else "- \(.message)" end' >> "$REPORT_FILE"
                        echo "" >> "$REPORT_FILE"
                    fi
                done
            fi

            # Add key metrics
            metrics=$(jq -r '.metrics // empty' "$result_file")
            if [ -n "$metrics" ] && [ "$metrics" != "null" ] && [ "$(echo "$metrics" | jq 'keys | length')" -gt 0 ]; then
                echo "#### Key Metrics" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "| Metric | Value |" >> "$REPORT_FILE"
                echo "|--------|-------|" >> "$REPORT_FILE"

                echo "$metrics" | jq -r 'to_entries | .[:10][] | "| \(.key | gsub("_"; " ")) | \(.value) |"' >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
            fi
        fi
    fi
done

# Add recommendations section
cat >> "$REPORT_FILE" << EOF

---

## Recommendations

### Immediate Actions (Critical/High Priority)

EOF

# Collect critical and high findings
for result_file in "$RESULTS_DIR"/*.json; do
    if [ -f "$result_file" ]; then
        filename=$(basename "$result_file" .json)
        if [ "$filename" = "report" ]; then
            continue
        fi

        category=$(jq -r '.category // "unknown"' "$result_file")
        findings=$(jq -r '.findings // []' "$result_file")

        echo "$findings" | jq -r '.[] | select(.severity == "critical" or .severity == "high") | "- **[\(.parameter | gsub("_"; " ") | ascii_upcase)]**: \(.message)"' >> "$REPORT_FILE"
    fi
done

cat >> "$REPORT_FILE" << EOF

### Strategic Improvements (Medium Priority)

EOF

for result_file in "$RESULTS_DIR"/*.json; do
    if [ -f "$result_file" ]; then
        filename=$(basename "$result_file" .json)
        if [ "$filename" = "report" ]; then
            continue
        fi

        findings=$(jq -r '.findings // []' "$result_file")
        echo "$findings" | jq -r '.[] | select(.severity == "medium") | "- \(.message)"' >> "$REPORT_FILE" 2>/dev/null || true
    fi
done

cat >> "$REPORT_FILE" << EOF

---

## Risk Assessment

| Area | Risk Level | Score | Mitigation Priority |
|------|------------|-------|---------------------|
EOF

# Read scores from temp file for risk assessment
for area in security reliability scalability maintainability; do
    area_score=$(grep "^${area}:" "$SCORES_FILE" 2>/dev/null | cut -d: -f2)
    area_score="${area_score:-5}"
    area_display=$(echo "$area" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    priority="Normal"
    if math_compare "$area_score" "<" "7"; then
        priority="High"
    fi
    echo "| $area_display | $(get_risk_level "$area_score") | $area_score | $priority |" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF

---

## Investment Recommendation

EOF

if math_compare "$FINAL_SCORE" ">=" "8.0"; then
    echo "✅ **Excellent investment** - Continue/Expand" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "The codebase demonstrates strong engineering practices and is well-positioned for growth." >> "$REPORT_FILE"
elif math_compare "$FINAL_SCORE" ">=" "7.0"; then
    echo "✅ **Good investment** - Minor improvements needed" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "The codebase is solid with some areas for improvement. Address high-priority items." >> "$REPORT_FILE"
elif math_compare "$FINAL_SCORE" ">=" "6.0"; then
    echo "⚠️ **Cautious investment** - Significant work required" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "The codebase has notable gaps that should be addressed before major scaling." >> "$REPORT_FILE"
elif math_compare "$FINAL_SCORE" ">=" "5.0"; then
    echo "⚠️ **High risk** - Major overhaul needed" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Significant technical debt and issues present. Plan for substantial remediation." >> "$REPORT_FILE"
else
    echo "❌ **Not recommended** - Fundamental issues" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Critical issues that may require architectural redesign or rewrite consideration." >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

---

*Generated by CTO Codebase Evaluation Suite v1.0*
*Report Date: $TIMESTAMP*
EOF

# =============================================================================
# GENERATE JSON REPORT
# =============================================================================

cat > "$JSON_REPORT" << EOF
{
  "metadata": {
    "codebase": "$CODEBASE_PATH",
    "timestamp": "$TIMESTAMP",
    "suite_version": "1.0"
  },
  "summary": {
    "final_score": $FINAL_SCORE,
    "grade": "$FINAL_GRADE",
    "risk_level": "$(get_risk_level "$FINAL_SCORE")"
  },
  "category_scores": {
EOF

first=true
while IFS=':' read -r category score; do
    [ -z "$category" ] && continue
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> "$JSON_REPORT"
    fi
    echo -n "    \"$category\": $score" >> "$JSON_REPORT"
done < "$SCORES_FILE"

cat >> "$JSON_REPORT" << EOF

  }
}
EOF

echo ""
echo "Report generated successfully!"
echo "  Markdown: $REPORT_FILE"
echo "  JSON: $JSON_REPORT"
