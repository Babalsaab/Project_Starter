#!/bin/bash

# =============================================================================
# ENHANCED EVALUATION ORCHESTRATOR
# =============================================================================
# Main entry point for enhanced codebase evaluation
# Coordinates all specialized analyzers for comprehensive assessment
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source all enhanced analyzers
source_analyzer() {
    local analyzer="$1"
    if [ -f "$LIB_DIR/$analyzer" ]; then
        source "$LIB_DIR/$analyzer"
        return 0
    fi
    return 1
}

# Source analyzers
source_analyzer "framework-detector.sh" 2>/dev/null || true
source_analyzer "test-analyzer.sh" 2>/dev/null || true
source_analyzer "complexity-analyzer.sh" 2>/dev/null || true
source_analyzer "api-analyzer.sh" 2>/dev/null || true
source_analyzer "security-analyzer.sh" 2>/dev/null || true
source_analyzer "performance-analyzer.sh" 2>/dev/null || true
source_analyzer "observability-analyzer.sh" 2>/dev/null || true
source_analyzer "devops-analyzer.sh" 2>/dev/null || true
source_analyzer "code-quality-analyzer.sh" 2>/dev/null || true
source_analyzer "architecture-analyzer.sh" 2>/dev/null || true
source_analyzer "documentation-analyzer.sh" 2>/dev/null || true
source_analyzer "reliability-analyzer.sh" 2>/dev/null || true
source_analyzer "scalability-analyzer.sh" 2>/dev/null || true

source "$SCRIPT_DIR/lib/math-utils.sh"

determine_project_category() {
    local codebase_path="$1"
    local project_info="$2"
    local has_frontend=false
    local has_backend=false

    local frameworks
    frameworks=$(echo "$project_info" | jq -r '.frameworks[]?')
    for fw in $frameworks; do
        case "$fw" in
            react|nextjs|vue|nuxt|angular|svelte|sveltekit|gatsby|remix)
                has_frontend=true
                ;;
            express|nestjs|fastify|hapi|koa|django|flask|fastapi|rails|spring-boot|laravel|aspnet|gin|echo|fiber|phoenix)
                has_backend=true
                ;;
        esac
    done

    if [ "$has_frontend" = true ] && [ "$has_backend" = false ]; then
        echo "frontend"
        return
    fi

    if [ "$has_backend" = true ] && [ "$has_frontend" = false ]; then
        echo "backend"
        return
    fi

    if [ "$has_frontend" = true ] && [ "$has_backend" = true ]; then
        echo "backend"
        return
    fi

    if [ -f "$codebase_path/package.json" ]; then
        if jq -e '.main or .module or .types' "$codebase_path/package.json" >/dev/null 2>&1; then
            echo "library"
            return
        fi
    fi

    if [ -f "$codebase_path/pyproject.toml" ] || [ -f "$codebase_path/setup.py" ]; then
        if ! grep -qiE 'django|flask|fastapi|starlette' "$codebase_path/pyproject.toml" "$codebase_path/setup.py" 2>/dev/null; then
            echo "library"
            return
        fi
    fi

    echo "backend"
}

get_weight() {
    local category="$1"
    local project_type="$2"

    case "$project_type" in
        frontend)
            case "$category" in
                performance) echo "1.2" ;;
                security) echo "1.1" ;;
                testing) echo "1.1" ;;
                observability) echo "0.9" ;;
                devops) echo "0.8" ;;
                api) echo "0.8" ;;
                architecture) echo "0.9" ;;
                documentation) echo "0.9" ;;
                scalability) echo "0.9" ;;
                *) echo "1.0" ;;
            esac
            ;;
        backend)
            case "$category" in
                security) echo "1.2" ;;
                performance) echo "1.1" ;;
                observability) echo "1.2" ;;
                devops) echo "1.1" ;;
                scalability) echo "1.1" ;;
                reliability) echo "1.1" ;;
                api) echo "1.1" ;;
                documentation) echo "0.9" ;;
                *) echo "1.0" ;;
            esac
            ;;
        library)
            case "$category" in
                code_quality) echo "1.2" ;;
                testing) echo "1.2" ;;
                documentation) echo "1.2" ;;
                complexity) echo "1.1" ;;
                security) echo "1.1" ;;
                performance) echo "0.9" ;;
                observability) echo "0.7" ;;
                devops) echo "0.6" ;;
                scalability) echo "0.8" ;;
                reliability) echo "0.9" ;;
                *) echo "1.0" ;;
            esac
            ;;
        *)
            echo "1.0"
            ;;
    esac
}

# =============================================================================
# ENHANCED EVALUATION
# =============================================================================

run_enhanced_evaluation() {
    local codebase_path="$1"
    local output_dir="${2:-${TMPDIR:-/tmp}/enhanced-evaluation}"
    local verbose="${3:-false}"
    
    mkdir -p "$output_dir"
    
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║           ENHANCED CODEBASE EVALUATION SUITE v2.0                ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📂 Analyzing: $codebase_path"
    echo ""
    
    # Detect project information first
    echo "🔍 Detecting project characteristics..."
    local project_info='{}'
    
    if type detect_project_type &>/dev/null; then
        project_info=$(detect_project_type "$codebase_path")
        local primary_lang=$(echo "$project_info" | jq -r '.primary_language // "unknown"')
        local frameworks=$(echo "$project_info" | jq -r '.frameworks | join(", ") // "none"')
        echo "   📋 Primary Language: $primary_lang"
        echo "   🛠️  Frameworks: $frameworks"
    fi

    local project_type="backend"
    project_type=$(determine_project_category "$codebase_path" "$project_info")
    project_info=$(echo "$project_info" | jq --arg pt "$project_type" '.project_type = $pt')
    echo "   🧭 Project Type: $project_type"
    
    if type detect_architecture &>/dev/null; then
        local arch_info=$(detect_architecture "$codebase_path")
        local arch_type=$(echo "$arch_info" | jq -r '.type // "unknown"')
        echo "   🏗️  Architecture: $arch_type"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Initialize results
    local results='{
        "project_info": {},
        "evaluations": {},
        "scores": {},
        "meta": {},
        "overall_score": 0,
        "grade": "",
        "timestamp": ""
    }'
    
    results=$(echo "$results" | jq --argjson pi "$project_info" '.project_info = $pi')
    results=$(echo "$results" | jq --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '.timestamp = $ts')
    
    # Capture scan metadata
    local source_files
    local total_files
    source_files=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \
           -o -name "*.py" -o -name "*.go" -o -name "*.java" -o -name "*.rs" \
           -o -name "*.rb" -o -name "*.php" -o -name "*.cs" -o -name "*.c" \
           -o -name "*.cpp" -o -name "*.swift" -o -name "*.kt" -o -name "*.scala" \
        \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
        ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.venv/*" ! -path "*/venv/*" \
        2>/dev/null | wc -l | tr -d ' ')
    total_files=$(find "$codebase_path" -type f \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" \
        ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.venv/*" ! -path "*/venv/*" \
        2>/dev/null | wc -l | tr -d ' ')
    local confidence="high"
    if [ "${source_files:-0}" -lt 20 ]; then
        confidence="low"
    elif [ "${source_files:-0}" -lt 100 ]; then
        confidence="medium"
    fi
    results=$(echo "$results" | jq --arg sf "${source_files:-0}" --arg tf "${total_files:-0}" --arg c "$confidence" '.meta.source_files = ($sf | tonumber) | .meta.total_files = ($tf | tonumber) | .meta.confidence = $c')
    
    # Initialize scores (using string for decimal accumulation)
    local total_score="0"
    local total_weight="0"
    
    # Helper function to add decimal scores
    add_score() {
        echo "$1 $2" | awk '{printf "%.2f", $1 + $2}'
    }

    mul_score() {
        echo "$1 $2" | awk '{printf "%.2f", $1 * $2}'
    }
    
    # Helper to round score to integer
    round_score() {
        echo "$1" | awk '{printf "%d", $1 + 0.5}'
    }
    
    # Run Code Quality Analysis
    echo "📊 Running Code Quality Analysis..."
    if type analyze_code_quality &>/dev/null; then
        local quality_result=$(analyze_code_quality "$codebase_path" "$output_dir")
        local quality_score=$(echo "$quality_result" | jq -r '.overall_score // 5')
        results=$(echo "$results" | jq --argjson r "$quality_result" '.evaluations.code_quality = $r')
        results=$(echo "$results" | jq --arg s "$quality_score" '.scores.code_quality = ($s | tonumber)')
        local weight=$(get_weight "code_quality" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.code_quality = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$quality_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ Code Quality Score: $quality_score/10"
    fi
    
    # Run Security Analysis
    echo "🔒 Running Security Analysis..."
    if type analyze_security &>/dev/null; then
        local security_result=$(analyze_security "$codebase_path" "$output_dir")
        local security_score=$(echo "$security_result" | jq -r '.overall_score // 5')
        local critical=$(echo "$security_result" | jq -r '.critical_issues // 0')
        results=$(echo "$results" | jq --argjson r "$security_result" '.evaluations.security = $r')
        results=$(echo "$results" | jq --arg s "$security_score" '.scores.security = ($s | tonumber)')
        local weight=$(get_weight "security" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.security = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$security_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ Security Score: $security_score/10 (Critical Issues: $critical)"
    fi
    
    # Run Test Analysis
    echo "🧪 Running Test Analysis..."
    if type analyze_test_coverage &>/dev/null; then
        local test_result=$(analyze_test_coverage "$codebase_path" "$output_dir")
        local test_score=$(echo "$test_result" | jq -r '.overall_score // 5')
        local coverage=$(echo "$test_result" | jq -r '.coverage_percent // 0')
        results=$(echo "$results" | jq --argjson r "$test_result" '.evaluations.testing = $r')
        results=$(echo "$results" | jq --arg s "$test_score" '.scores.testing = ($s | tonumber)')
        local weight=$(get_weight "testing" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.testing = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$test_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ Testing Score: $test_score/10 (Coverage: ${coverage}%)"
    fi
    
    # Run Complexity Analysis
    echo "📈 Running Complexity Analysis..."
    if type analyze_complexity &>/dev/null; then
        local complexity_result=$(analyze_complexity "$codebase_path" "$output_dir")
        local complexity_score=$(echo "$complexity_result" | jq -r '.overall_score // 5')
        local avg_complexity=$(echo "$complexity_result" | jq -r '.average_complexity // 0')
        results=$(echo "$results" | jq --argjson r "$complexity_result" '.evaluations.complexity = $r')
        results=$(echo "$results" | jq --arg s "$complexity_score" '.scores.complexity = ($s | tonumber)')
        local weight=$(get_weight "complexity" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.complexity = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$complexity_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ Maintainability Score: $complexity_score/10 (Avg Complexity: $avg_complexity)"
    fi
    
    # Run API Analysis
    echo "🔌 Running API Analysis..."
    if type analyze_api_design &>/dev/null; then
        local api_result=$(analyze_api_design "$codebase_path")
        local api_score=$(echo "$api_result" | jq -r '.score // 5')
        results=$(echo "$results" | jq --argjson r "$api_result" '.evaluations.api = $r')
        results=$(echo "$results" | jq --arg s "$api_score" '.scores.api = ($s | tonumber)')
        local weight=$(get_weight "api" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.api = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$api_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ API Design Score: $api_score/10"
    fi
    
    # Run Performance Analysis
    echo "⚡ Running Performance Analysis..."
    if type analyze_performance &>/dev/null; then
        local perf_result=$(analyze_performance "$codebase_path" "$output_dir")
        local perf_score=$(echo "$perf_result" | jq -r '.overall_score // 5')
        results=$(echo "$results" | jq --argjson r "$perf_result" '.evaluations.performance = $r')
        results=$(echo "$results" | jq --arg s "$perf_score" '.scores.performance = ($s | tonumber)')
        local weight=$(get_weight "performance" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.performance = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$perf_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ Performance Score: $perf_score/10"
    fi
    
    # Run DevOps Analysis
    echo "🚀 Running DevOps Analysis..."
    if type analyze_devops &>/dev/null; then
        local devops_result=$(analyze_devops "$codebase_path" "$output_dir")
        local devops_score=$(echo "$devops_result" | jq -r '.overall_score // 5')
        local pipeline=$(echo "$devops_result" | jq -r '.cicd_analysis.pipeline_type // "none"')
        results=$(echo "$results" | jq --argjson r "$devops_result" '.evaluations.devops = $r')
        results=$(echo "$results" | jq --arg s "$devops_score" '.scores.devops = ($s | tonumber)')
        local weight=$(get_weight "devops" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.devops = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$devops_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ DevOps Score: $devops_score/10 (CI/CD: $pipeline)"
    fi
    
    # Run Observability Analysis
    echo "📡 Running Observability Analysis..."
    if type analyze_observability &>/dev/null; then
        local obs_result=$(analyze_observability "$codebase_path" "$output_dir")
        local obs_score=$(echo "$obs_result" | jq -r '.overall_score // 5')
        results=$(echo "$results" | jq --argjson r "$obs_result" '.evaluations.observability = $r')
        results=$(echo "$results" | jq --arg s "$obs_score" '.scores.observability = ($s | tonumber)')
        local weight=$(get_weight "observability" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.observability = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$obs_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ Observability Score: $obs_score/10"
    fi
    
    # Run Architecture Analysis
    echo "🏛️  Running Architecture Analysis..."
    if type analyze_architecture &>/dev/null; then
        local arch_result=$(analyze_architecture "$codebase_path" "$output_dir")
        local arch_score=$(echo "$arch_result" | jq -r '.overall_score // 5')
        results=$(echo "$results" | jq --argjson r "$arch_result" '.evaluations.architecture = $r')
        results=$(echo "$results" | jq --arg s "$arch_score" '.scores.architecture = ($s | tonumber)')
        local weight=$(get_weight "architecture" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.architecture = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$arch_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ Architecture Score: $arch_score/10"
    fi
    
    # Run Documentation Analysis
    echo "📚 Running Documentation Analysis..."
    if type analyze_documentation &>/dev/null; then
        local doc_result=$(analyze_documentation "$codebase_path" "$output_dir")
        local doc_score=$(echo "$doc_result" | jq -r '.overall_score // 5')
        results=$(echo "$results" | jq --argjson r "$doc_result" '.evaluations.documentation = $r')
        results=$(echo "$results" | jq --arg s "$doc_score" '.scores.documentation = ($s | tonumber)')
        local weight=$(get_weight "documentation" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.documentation = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$doc_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ Documentation Score: $doc_score/10"
    fi
    
    # Run Reliability Analysis
    echo "🛡️  Running Reliability Analysis..."
    if type analyze_reliability &>/dev/null; then
        local rel_result=$(analyze_reliability "$codebase_path" "$output_dir")
        local rel_score=$(echo "$rel_result" | jq -r '.overall_score // 5')
        results=$(echo "$results" | jq --argjson r "$rel_result" '.evaluations.reliability = $r')
        results=$(echo "$results" | jq --arg s "$rel_score" '.scores.reliability = ($s | tonumber)')
        local weight=$(get_weight "reliability" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.reliability = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$rel_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ Reliability Score: $rel_score/10"
    fi
    
    # Run Scalability Analysis
    echo "📈 Running Scalability Analysis..."
    if type analyze_scalability &>/dev/null; then
        local scale_result=$(analyze_scalability "$codebase_path" "$output_dir")
        local scale_score=$(echo "$scale_result" | jq -r '.overall_score // 5')
        results=$(echo "$results" | jq --argjson r "$scale_result" '.evaluations.scalability = $r')
        results=$(echo "$results" | jq --arg s "$scale_score" '.scores.scalability = ($s | tonumber)')
        local weight=$(get_weight "scalability" "$project_type")
        results=$(echo "$results" | jq --arg w "$weight" '.meta.weights.scalability = ($w | tonumber)')
        total_score=$(add_score "$total_score" "$(mul_score "$scale_score" "$weight")")
        total_weight=$(add_score "$total_weight" "$weight")
        echo "   ✓ Scalability Score: $scale_score/10"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Calculate overall score
    if [ "${total_weight:-0}" != "0" ]; then
        local overall=$(echo "$total_score $total_weight" | awk '{printf "%.2f", $1 / $2}')
        local overall_rounded=$(round_score "$overall")
        results=$(echo "$results" | jq --arg s "$overall" '.overall_score = ($s | tonumber)')
        
        # Assign grade based on decimal comparison
        local grade=""
        grade=$(math_grade "$overall")
        
        results=$(echo "$results" | jq --arg g "$grade" '.grade = $g')
        
        # Display summary
        echo "╔══════════════════════════════════════════════════════════════════╗"
        echo "║                      EVALUATION SUMMARY                          ║"
        echo "╚══════════════════════════════════════════════════════════════════╝"
        echo ""
        printf "   Overall Score: %s/10\n" "$overall"
        printf "   Grade: %s\n" "$grade"
        echo ""
        echo "   Score Breakdown:"
        echo "$results" | jq -r '.scores | to_entries[] | "   • \(.key): \(.value)/10"'
        echo ""
    fi
    
    # Save results
    echo "$results" | jq '.' > "$output_dir/enhanced-evaluation-results.json"
    echo "📄 Detailed results saved to: $output_dir/enhanced-evaluation-results.json"
    echo ""
    
    echo "$results"
}

# =============================================================================
# QUICK EVALUATION (Faster, less detailed)
# =============================================================================

run_quick_evaluation() {
    local codebase_path="$1"
    
    echo "Running quick evaluation..."
    
    local score=5
    local findings=0
    
    # Quick checks
    
    # Has tests?
    local has_tests=$(find "$codebase_path" -type f \( -name "*test*" -o -name "*spec*" \) 2>/dev/null | head -10 | wc -l)
    [ "$has_tests" -gt 5 ] && score=$((score + 1))
    
    # Has CI/CD?
    if [ -d "$codebase_path/.github/workflows" ] || [ -f "$codebase_path/.gitlab-ci.yml" ]; then
        score=$((score + 1))
    fi
    
    # Has TypeScript?
    [ -f "$codebase_path/tsconfig.json" ] && score=$((score + 1))
    
    # Has linting?
    [ -f "$codebase_path/.eslintrc.js" ] || [ -f "$codebase_path/.eslintrc.json" ] && score=$((score + 1))
    
    # Has Docker?
    [ -f "$codebase_path/Dockerfile" ] && score=$((score + 1))
    
    [ "$score" -gt 10 ] && score=10
    
    echo "Quick Score: $score/10"
}

# =============================================================================
# COMPARE EVALUATIONS
# =============================================================================

compare_evaluations() {
    local result1="$1"
    local result2="$2"
    
    echo "Comparing evaluations..."
    
    local score1=$(jq -r '.overall_score' "$result1")
    local score2=$(jq -r '.overall_score' "$result2")
    
    local diff=$((score2 - score1))
    
    echo "Previous Score: $score1/10"
    echo "Current Score: $score2/10"
    echo "Change: $diff"
    
    # Show category changes
    echo ""
    echo "Category Changes:"
    jq -s '.[0].scores as $old | .[1].scores | to_entries[] | "\(.key): \($old[.key] // 0) -> \(.value) (\(.value - ($old[.key] // 0)))"' "$result1" "$result2"
}

# =============================================================================
# MAIN
# =============================================================================

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    case "${1:-}" in
        --quick)
            run_quick_evaluation "${2:-.}"
            ;;
        --compare)
            compare_evaluations "$2" "$3"
            ;;
        --help)
            echo "Usage: $0 [OPTIONS] <codebase_path>"
            echo ""
            echo "Options:"
            echo "  --quick          Run quick evaluation (faster, less detailed)"
            echo "  --compare <a> <b> Compare two evaluation results"
            echo "  --help           Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 /path/to/codebase"
            echo "  $0 --quick /path/to/codebase"
            ;;
        *)
            run_enhanced_evaluation "${1:-.}" "${2:-./output/enhanced}"
            ;;
    esac
fi
