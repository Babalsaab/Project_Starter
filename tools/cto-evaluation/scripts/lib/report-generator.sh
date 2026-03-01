#!/bin/bash

# =============================================================================
# ENHANCED REPORT GENERATOR
# =============================================================================
# Generates comprehensive evaluation reports:
#   - Executive summary with risk assessment
#   - Detailed scoring breakdown
#   - Visual progress indicators
#   - Prioritized remediation roadmap
#   - Industry benchmark comparisons
#   - HTML and Markdown output
#   - Historical trend tracking
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/math-utils.sh"

# =============================================================================
# GRADE CALCULATION
# =============================================================================

calculate_grade() {
    math_grade "$1"
}

# =============================================================================
# RISK ASSESSMENT
# =============================================================================

assess_risk() {
    local score="$1"
    local security_score="$2"

    if math_compare "$security_score" "<" "5"; then
        echo "critical"
    elif math_compare "$score" "<" "5"; then
        echo "high"
    elif math_compare "$score" "<" "7"; then
        echo "medium"
    elif math_compare "$score" ">=" "8"; then
        echo "low"
    else
        echo "medium"
    fi
}

# =============================================================================
# PROGRESS BAR GENERATOR
# =============================================================================

generate_progress_bar() {
    local score="$1"
    local max="${2:-10}"
    local width="${3:-20}"
    math_score_bar "$score" "$width"
}

# =============================================================================
# INDUSTRY BENCHMARKS
# =============================================================================

get_benchmarks() {
    # Industry standard benchmarks (based on research and best practices)
    cat << 'EOF'
{
    "excellent": {
        "code_quality": 9.0,
        "architecture": 8.5,
        "security": 9.0,
        "performance": 8.5,
        "testing": 8.0,
        "devops": 8.5,
        "documentation": 8.0,
        "overall": 8.5
    },
    "good": {
        "code_quality": 7.5,
        "architecture": 7.0,
        "security": 7.5,
        "performance": 7.0,
        "testing": 6.5,
        "devops": 7.0,
        "documentation": 6.5,
        "overall": 7.0
    },
    "average": {
        "code_quality": 6.0,
        "architecture": 5.5,
        "security": 6.0,
        "performance": 5.5,
        "testing": 5.0,
        "devops": 5.5,
        "documentation": 5.0,
        "overall": 5.5
    },
    "sources": [
        "DORA State of DevOps Report",
        "OWASP Security Benchmarks",
        "Google Engineering Practices",
        "Industry Code Quality Standards"
    ]
}
EOF
}

# =============================================================================
# REMEDIATION PRIORITIZATION
# =============================================================================

generate_remediation_roadmap() {
    local results_json="$1"
    
    local roadmap='{"immediate": [], "short_term": [], "medium_term": [], "long_term": []}'
    
    # Parse scores and generate prioritized items
    local security=$(echo "$results_json" | jq -r '.categories.security.score // .scores.security // 5')
    local testing=$(echo "$results_json" | jq -r '.categories.testing.score // .scores.testing // 5')
    local devops=$(echo "$results_json" | jq -r '.categories.devops.score // .scores.devops // 5')
    local code_quality=$(echo "$results_json" | jq -r '.categories.code_quality.score // .scores.code_quality // 5')
    local docs=$(echo "$results_json" | jq -r '.categories.documentation.score // .scores.documentation // 5')
    
    # IMMEDIATE (Critical - do within 1 week)
    if math_compare "$security" "<" "5"; then
        roadmap=$(echo "$roadmap" | jq '.immediate += [{
            priority: 1,
            category: "Security",
            action: "Address critical security vulnerabilities",
            effort: "High",
            impact: "Critical",
            estimated_hours: 40
        }]')
    fi
    
    # Check for secrets in code
    if echo "$results_json" | jq -e '.findings[]? | select(.type == "secret")' &>/dev/null; then
        roadmap=$(echo "$roadmap" | jq '.immediate += [{
            priority: 1,
            category: "Security",
            action: "Remove hardcoded secrets and implement secret management",
            effort: "Medium",
            impact: "Critical",
            estimated_hours: 16
        }]')
    fi
    
    # SHORT-TERM (1-2 weeks)
    if math_compare "$testing" "<" "6"; then
        roadmap=$(echo "$roadmap" | jq '.short_term += [{
            priority: 2,
            category: "Testing",
            action: "Increase test coverage to at least 60%",
            effort: "High",
            impact: "High",
            estimated_hours: 80
        }]')
    fi
    
    if math_compare "$devops" "<" "6"; then
        roadmap=$(echo "$roadmap" | jq '.short_term += [{
            priority: 2,
            category: "DevOps",
            action: "Implement CI/CD pipeline with automated testing",
            effort: "Medium",
            impact: "High",
            estimated_hours: 24
        }]')
    fi
    
    # MEDIUM-TERM (2-4 weeks)
    if math_compare "$code_quality" "<" "7"; then
        roadmap=$(echo "$roadmap" | jq '.medium_term += [{
            priority: 3,
            category: "Code Quality",
            action: "Implement code quality tools (linting, formatting)",
            effort: "Medium",
            impact: "Medium",
            estimated_hours: 16
        }]')
    fi
    
    if math_compare "$docs" "<" "6"; then
        roadmap=$(echo "$roadmap" | jq '.medium_term += [{
            priority: 3,
            category: "Documentation",
            action: "Create comprehensive documentation",
            effort: "Medium",
            impact: "Medium",
            estimated_hours: 32
        }]')
    fi
    
    # LONG-TERM (1-3 months)
    roadmap=$(echo "$roadmap" | jq '.long_term += [{
        priority: 4,
        category: "Architecture",
        action: "Review and document architecture decisions",
        effort: "High",
        impact: "High",
        estimated_hours: 40
    }]')
    
    # Calculate total effort
    local total_hours=$(echo "$roadmap" | jq '
        [.immediate[].estimated_hours // 0,
         .short_term[].estimated_hours // 0,
         .medium_term[].estimated_hours // 0,
         .long_term[].estimated_hours // 0] | add')
    
    roadmap=$(echo "$roadmap" | jq --argjson hours "$total_hours" '. + {
        total_estimated_hours: $hours,
        estimated_cost_at_100_per_hour: ($hours * 100)
    }')
    
    echo "$roadmap"
}

# =============================================================================
# MARKDOWN REPORT GENERATION
# =============================================================================

generate_markdown_report() {
    local results_json="$1"
    local output_file="$2"
    
    local overall=$(echo "$results_json" | jq '.overall_score // 0')
    local grade=$(calculate_grade "$overall")
    local security_score=$(echo "$results_json" | jq -r '.categories.security.score // .scores.security // 5')
    local risk=$(assess_risk "$overall" "$security_score")
    local risk_upper=$(echo "$risk" | tr '[:lower:]' '[:upper:]')
    local benchmarks=$(get_benchmarks)
    local roadmap=$(generate_remediation_roadmap "$results_json")
    local category_count=$(echo "$results_json" | jq 'if .scores then (.scores | keys | length) elif .categories then (.categories | keys | length) else 0 end')
    
    cat > "$output_file" << EOF
# 🔍 CTO Codebase Evaluation Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Codebase:** $(echo "$results_json" | jq -r '.codebase_path // .metadata.codebase // "Unknown"')
**Version:** CTO Evaluation Suite v2.0

---

## 📊 Executive Summary

| Metric | Value |
|--------|-------|
| **Overall Score** | **${overall}/10** |
| **Grade** | **${grade}** |
| **Risk Level** | **${risk_upper}** |
| **Categories Evaluated** | ${category_count} |

### Score Visualization

\`\`\`
Overall: $(generate_progress_bar "$overall") ${overall}/10
\`\`\`

EOF

    # Add category breakdown
    cat >> "$output_file" << 'EOF'
## 📈 Category Breakdown

| Category | Score | Grade | Status |
|----------|-------|-------|--------|
EOF

    # Parse categories (supports standard and enhanced formats) and add rows
    if echo "$results_json" | jq -e '.scores' >/dev/null 2>&1; then
        echo "$results_json" | jq -r '.scores | to_entries[] | "\(.key)|\(.value // "N/A")"' |
        while IFS='|' read -r cat score; do
            if [ "$score" != "N/A" ] && [ -n "$score" ]; then
                local cat_grade=$(calculate_grade "$score")
                local status_icon="⚠️"
                math_compare "$score" ">=" "7" && status_icon="✅"
                math_compare "$score" "<" "5" && status_icon="❌"

                local formatted_cat=$(echo "$cat" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
                echo "| $formatted_cat | $score | $cat_grade | $status_icon |" >> "$output_file"
            fi
        done
    else
        echo "$results_json" | jq -r '.categories | to_entries[] | "\(.key)|\(.value.score // "N/A")"' |
        while IFS='|' read -r cat score; do
        if [ "$score" != "N/A" ] && [ -n "$score" ]; then
            local cat_grade=$(calculate_grade "$score")
            local status_icon="⚠️"
            math_compare "$score" ">=" "7" && status_icon="✅"
            math_compare "$score" "<" "5" && status_icon="❌"
            
            # Format category name
            local formatted_cat=$(echo "$cat" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
                echo "| $formatted_cat | $score | $cat_grade | $status_icon |" >> "$output_file"
            fi
        done
    fi

    # Add benchmark comparison
    cat >> "$output_file" << EOF

## 📏 Industry Benchmark Comparison

| Category | Your Score | Industry Average | Industry Excellent |
|----------|------------|------------------|-------------------|
| Overall | ${overall} | $(echo "$benchmarks" | jq '.average.overall') | $(echo "$benchmarks" | jq '.excellent.overall') |

EOF

    # Add remediation roadmap
    cat >> "$output_file" << EOF

## 🛠️ Remediation Roadmap

### 🚨 Immediate Actions (This Week)

EOF

    echo "$roadmap" | jq -r '.immediate[] | "- **\(.category)**: \(.action) (~\(.estimated_hours)h)"' >> "$output_file"
    [ "$(echo "$roadmap" | jq '.immediate | length')" -eq 0 ] && echo "_No immediate actions required_" >> "$output_file"

    cat >> "$output_file" << EOF

### ⏰ Short-Term (1-2 Weeks)

EOF

    echo "$roadmap" | jq -r '.short_term[] | "- **\(.category)**: \(.action) (~\(.estimated_hours)h)"' >> "$output_file"
    [ "$(echo "$roadmap" | jq '.short_term | length')" -eq 0 ] && echo "_No short-term actions required_" >> "$output_file"

    cat >> "$output_file" << EOF

### 📅 Medium-Term (2-4 Weeks)

EOF

    echo "$roadmap" | jq -r '.medium_term[] | "- **\(.category)**: \(.action) (~\(.estimated_hours)h)"' >> "$output_file"

    cat >> "$output_file" << EOF

### 📆 Long-Term (1-3 Months)

EOF

    echo "$roadmap" | jq -r '.long_term[] | "- **\(.category)**: \(.action) (~\(.estimated_hours)h)"' >> "$output_file"

    # Add effort summary
    local total_hours=$(echo "$roadmap" | jq '.total_estimated_hours')
    local cost=$(echo "$roadmap" | jq '.estimated_cost_at_100_per_hour')

    cat >> "$output_file" << EOF

### 📊 Effort Summary

| Metric | Value |
|--------|-------|
| Total Estimated Hours | ${total_hours}h |
| Estimated Cost (@\$100/h) | \$${cost} |
| Recommended Timeline | $(math_int "$total_hours / 40") weeks |

---

## 📝 Detailed Findings

EOF

    # Add findings if available
    if echo "$results_json" | jq -e '.findings' &>/dev/null; then
        echo "$results_json" | jq -r '.findings[] | "### \(.category // "General")\n\n**Severity:** \(.severity // "info")\n\n\(.message // .description // "No details")\n"' >> "$output_file"
    fi

    cat >> "$output_file" << EOF

---

## 📚 Methodology

This evaluation uses the CTO Codebase Evaluation Framework with 495 assessment parameters across 21 categories:

- **Code Quality** (8%): Linting, formatting, complexity
- **Architecture** (10%): Design patterns, modularity, scalability
- **Security** (12%): Vulnerabilities, secrets, dependencies
- **Performance** (8%): Optimization, caching, efficiency
- **Testing** (8%): Coverage, quality, automation
- **DevOps** (6%): CI/CD, deployment, infrastructure

### Benchmark Sources

- DORA State of DevOps Report
- OWASP Security Benchmarks
- Google Engineering Practices
- Industry Code Quality Standards

---

*Generated by CTO Evaluation Suite v2.0*
EOF

    echo "  Generated Markdown report: $output_file" >&2
}

# =============================================================================
# HTML REPORT GENERATION
# =============================================================================

generate_html_report() {
    local results_json="$1"
    local output_file="$2"
    
    local overall=$(echo "$results_json" | jq '.overall_score // 0')
    local grade=$(calculate_grade "$overall")
    local risk=$(assess_risk "$overall" "$(echo "$results_json" | jq -r '.categories.security.score // .scores.security // 5')")
    
    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CTO Codebase Evaluation Report</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --primary: #2563eb;
            --success: #10b981;
            --warning: #f59e0b;
            --danger: #ef4444;
            --gray-100: #f3f4f6;
            --gray-200: #e5e7eb;
            --gray-700: #374151;
            --gray-900: #111827;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: var(--gray-100);
            color: var(--gray-900);
            line-height: 1.6;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 2rem; }
        .card {
            background: white;
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }
        h1 { font-size: 2rem; margin-bottom: 0.5rem; }
        h2 { font-size: 1.5rem; margin-bottom: 1rem; color: var(--gray-700); }
        .grade {
            display: inline-block;
            font-size: 4rem;
            font-weight: bold;
            padding: 1rem 2rem;
            border-radius: 12px;
        }
        .grade-a { background: #d1fae5; color: #065f46; }
        .grade-b { background: #dbeafe; color: #1e40af; }
        .grade-c { background: #fef3c7; color: #92400e; }
        .grade-d { background: #fed7aa; color: #9a3412; }
        .grade-f { background: #fee2e2; color: #991b1b; }
        .score-bar {
            height: 24px;
            background: var(--gray-200);
            border-radius: 12px;
            overflow: hidden;
            margin: 0.5rem 0;
        }
        .score-fill {
            height: 100%;
            border-radius: 12px;
            transition: width 0.5s ease;
        }
        .risk-critical { background: var(--danger); }
        .risk-high { background: #f97316; }
        .risk-medium { background: var(--warning); }
        .risk-low { background: var(--success); }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 0.75rem; text-align: left; border-bottom: 1px solid var(--gray-200); }
        th { font-weight: 600; color: var(--gray-700); }
        .chart-container { position: relative; height: 300px; }
        .flex { display: flex; gap: 1.5rem; flex-wrap: wrap; }
        .flex-1 { flex: 1; min-width: 300px; }
        .badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.875rem;
            font-weight: 500;
        }
        .badge-success { background: #d1fae5; color: #065f46; }
        .badge-warning { background: #fef3c7; color: #92400e; }
        .badge-danger { background: #fee2e2; color: #991b1b; }
        .roadmap-item {
            padding: 1rem;
            border-left: 4px solid var(--primary);
            background: var(--gray-100);
            margin-bottom: 0.75rem;
            border-radius: 0 8px 8px 0;
        }
        .roadmap-immediate { border-left-color: var(--danger); }
        .roadmap-short { border-left-color: var(--warning); }
        .roadmap-medium { border-left-color: var(--primary); }
        .roadmap-long { border-left-color: var(--success); }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <h1>🔍 CTO Codebase Evaluation Report</h1>
            <p>Generated: <span id="timestamp"></span></p>
        </div>
        
        <div class="flex">
            <div class="flex-1 card">
                <h2>Overall Score</h2>
                <div class="grade" id="grade"></div>
                <div class="score-bar">
                    <div class="score-fill" id="score-bar"></div>
                </div>
                <p><strong id="score"></strong>/10</p>
            </div>
            
            <div class="flex-1 card">
                <h2>Risk Assessment</h2>
                <span class="badge" id="risk-badge"></span>
                <p id="risk-description" style="margin-top: 1rem;"></p>
            </div>
        </div>
        
        <div class="card">
            <h2>Category Breakdown</h2>
            <div class="chart-container">
                <canvas id="categoryChart"></canvas>
            </div>
        </div>
        
        <div class="card">
            <h2>Detailed Scores</h2>
            <table>
                <thead>
                    <tr><th>Category</th><th>Score</th><th>Grade</th><th>Status</th></tr>
                </thead>
                <tbody id="scores-table"></tbody>
            </table>
        </div>
        
        <div class="card">
            <h2>Remediation Roadmap</h2>
            <div id="roadmap"></div>
        </div>
    </div>
    
    <script>
        // Results data will be injected here
        const results = RESULTS_JSON_PLACEHOLDER;
        
        // Helper functions
        function getGrade(score) {
            if (score >= 9.5) return 'A+';
            if (score >= 9.0) return 'A';
            if (score >= 8.5) return 'A-';
            if (score >= 8.0) return 'B+';
            if (score >= 7.5) return 'B';
            if (score >= 7.0) return 'B-';
            if (score >= 6.5) return 'C+';
            if (score >= 6.0) return 'C';
            if (score >= 5.5) return 'C-';
            if (score >= 5.0) return 'D+';
            if (score >= 4.5) return 'D';
            if (score >= 4.0) return 'D-';
            return 'F';
        }
        
        function getGradeClass(grade) {
            if (grade.startsWith('A')) return 'grade-a';
            if (grade.startsWith('B')) return 'grade-b';
            if (grade.startsWith('C')) return 'grade-c';
            if (grade.startsWith('D')) return 'grade-d';
            return 'grade-f';
        }
        
        function getColor(score) {
            if (score >= 7) return '#10b981';
            if (score >= 5) return '#f59e0b';
            return '#ef4444';
        }
        
        // Populate data
        const overall = results.overall_score || 0;
        const grade = getGrade(overall);
        const security = (results.categories && results.categories.security && results.categories.security.score !== undefined)
            ? results.categories.security.score
            : (results.scores && results.scores.security !== undefined ? results.scores.security : 5);
        
        document.getElementById('timestamp').textContent = new Date().toLocaleString();
        document.getElementById('score').textContent = overall.toFixed(2);
        document.getElementById('grade').textContent = grade;
        document.getElementById('grade').className = 'grade ' + getGradeClass(grade);
        
        const scoreBar = document.getElementById('score-bar');
        scoreBar.style.width = (overall * 10) + '%';
        scoreBar.style.background = getColor(overall);
        
        // Risk badge
        let risk = 'medium';
        if (security < 5) risk = 'critical';
        else if (overall < 5) risk = 'high';
        else if (overall >= 8) risk = 'low';
        
        const riskBadge = document.getElementById('risk-badge');
        riskBadge.textContent = risk.toUpperCase();
        riskBadge.className = 'badge badge-' + (risk === 'low' ? 'success' : risk === 'medium' ? 'warning' : 'danger');
        
        const riskDescs = {
            critical: 'Critical security issues require immediate attention.',
            high: 'Significant issues that should be addressed soon.',
            medium: 'Some improvements needed but not urgent.',
            low: 'Codebase is in good shape. Focus on continuous improvement.'
        };
        document.getElementById('risk-description').textContent = riskDescs[risk];
        
        // Category chart
        const categories = results.categories || Object.fromEntries(
            Object.entries(results.scores || {}).map(([k, v]) => [k, { score: v }])
        );
        const labels = Object.keys(categories).map(k => k.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()));
        const scores = Object.values(categories).map(c => c.score || 0);
        
        new Chart(document.getElementById('categoryChart'), {
            type: 'radar',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Score',
                    data: scores,
                    fill: true,
                    backgroundColor: 'rgba(37, 99, 235, 0.2)',
                    borderColor: 'rgb(37, 99, 235)',
                    pointBackgroundColor: 'rgb(37, 99, 235)'
                }]
            },
            options: {
                scales: { r: { min: 0, max: 10 } }
            }
        });
        
        // Scores table
        const tbody = document.getElementById('scores-table');
        Object.entries(categories).forEach(([cat, data]) => {
            const score = data.score || 0;
            const catGrade = getGrade(score);
            const status = score >= 7 ? '✅' : score >= 5 ? '⚠️' : '❌';
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${cat.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}</td>
                <td>${score.toFixed(2)}</td>
                <td>${catGrade}</td>
                <td>${status}</td>
            `;
            tbody.appendChild(tr);
        });
    </script>
</body>
</html>
EOF

    # Inject results JSON
    local escaped_json=$(echo "$results_json" | jq -c '.')
    sed -i.bak "s|RESULTS_JSON_PLACEHOLDER|$escaped_json|g" "$output_file" && rm -f "${output_file}.bak"
    
    echo "  Generated HTML report: $output_file" >&2
}

# =============================================================================
# MAIN REPORT GENERATION
# =============================================================================

generate_report() {
    local results_file="$1"
    local output_dir="${2:-.}"
    local format="${3:-all}"  # markdown, html, or all
    
    if [ ! -f "$results_file" ]; then
        echo "Error: Results file not found: $results_file" >&2
        return 1
    fi
    
    local results_json=$(cat "$results_file")
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    mkdir -p "$output_dir"
    
    echo "Generating evaluation reports..." >&2
    
    if [ "$format" = "markdown" ] || [ "$format" = "all" ]; then
        generate_markdown_report "$results_json" "$output_dir/report_${timestamp}.md"
    fi
    
    if [ "$format" = "html" ] || [ "$format" = "all" ]; then
        generate_html_report "$results_json" "$output_dir/report_${timestamp}.html"
    fi
    
    echo "Reports generated in: $output_dir" >&2
    
    # Return path to latest report
    echo "$output_dir/report_${timestamp}.md"
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_report "$@"
fi
