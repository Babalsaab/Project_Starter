#!/bin/bash

# =============================================================================
# ENHANCED EVALUATION ORCHESTRATOR v2.0
# =============================================================================
# Master orchestrator that integrates all advanced analysis modules:
#   - Intelligent codebase analysis
#   - Advanced code metrics
#   - Comprehensive security scanning
#   - Test coverage extraction
#   - CI/CD configuration analysis
#   - Documentation quality assessment
#   - Enhanced report generation
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
OUTPUT_DIR="$SCRIPT_DIR/../output"

# Source all library modules
source "$LIB_DIR/math-utils.sh"
source "$LIB_DIR/analyzer.sh" 2>/dev/null || echo "Warning: analyzer.sh not found"
source "$LIB_DIR/metrics.sh" 2>/dev/null || echo "Warning: metrics.sh not found"
source "$LIB_DIR/security-scanner.sh" 2>/dev/null || echo "Warning: security-scanner.sh not found"
source "$LIB_DIR/coverage-extractor.sh" 2>/dev/null || echo "Warning: coverage-extractor.sh not found"
source "$LIB_DIR/cicd-analyzer.sh" 2>/dev/null || echo "Warning: cicd-analyzer.sh not found"
source "$LIB_DIR/docs-analyzer.sh" 2>/dev/null || echo "Warning: docs-analyzer.sh not found"
source "$LIB_DIR/report-generator.sh" 2>/dev/null || echo "Warning: report-generator.sh not found"

# =============================================================================
# CONFIGURATION
# =============================================================================

VERSION="2.0.0"
VERBOSE=${VERBOSE:-false}

# Category weights (must sum to 100)
declare -A WEIGHTS=(
    ["code_quality"]=8
    ["architecture"]=10
    ["security"]=12
    ["performance"]=8
    ["testing"]=7
    ["devops"]=6
    ["scalability"]=8
    ["reliability"]=8
    ["data"]=5
    ["api"]=5
    ["observability"]=4
    ["frontend"]=4
    ["backend"]=4
    ["documentation"]=5
    ["developer_experience"]=3
    ["maintainability"]=3
)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)  echo -e "\033[0;32m[$timestamp] INFO:\033[0m $message" ;;
        WARN)  echo -e "\033[0;33m[$timestamp] WARN:\033[0m $message" ;;
        ERROR) echo -e "\033[0;31m[$timestamp] ERROR:\033[0m $message" >&2 ;;
        DEBUG) [ "$VERBOSE" = "true" ] && echo -e "\033[0;36m[$timestamp] DEBUG:\033[0m $message" ;;
    esac
}

show_progress() {
    local current="$1"
    local total="$2"
    local category="$3"
    local width=40
    local pct=$((current * 100 / total))
    local filled=$((current * width / total))
    
    printf "\r["
    printf "%*s" "$filled" | tr ' ' '█'
    printf "%*s" "$((width - filled))" | tr ' ' '░'
    printf "] %3d%% - %s" "$pct" "$category"
}

# =============================================================================
# ENHANCED ANALYSIS FUNCTIONS
# =============================================================================

run_intelligent_analysis() {
    local codebase="$1"
    
    log INFO "Running intelligent codebase analysis..."
    
    local analysis_result='{}'
    
    # Run full analysis from analyzer.sh
    if type run_full_analysis &>/dev/null; then
        analysis_result=$(run_full_analysis "$codebase")
    else
        # Fallback to basic detection
        analysis_result=$(jq -n '{
            languages: {},
            frameworks: [],
            project_type: "unknown",
            databases: []
        }')
    fi
    
    echo "$analysis_result"
}

run_code_metrics() {
    local codebase="$1"
    
    log INFO "Calculating code metrics..."
    
    local metrics_result='{}'
    
    if type calculate_all_metrics &>/dev/null; then
        metrics_result=$(calculate_all_metrics "$codebase")
    else
        metrics_result=$(jq -n '{
            complexity: {average: 5},
            duplication: {percentage: 5},
            maintainability: {index: 70},
            technical_debt: {hours: 0}
        }')
    fi
    
    echo "$metrics_result"
}

run_security_analysis() {
    local codebase="$1"
    
    log INFO "Running comprehensive security scan..."
    
    local security_result='{}'
    
    if type run_full_security_scan &>/dev/null; then
        security_result=$(run_full_security_scan "$codebase")
    else
        # Run basic security checks
        local secrets_count=$(grep -rE "(password|api_key|secret).*=.*['\"][^'\"]+['\"]" "$codebase" \
            --include="*.js" --include="*.py" --include="*.ts" \
            --exclude-dir=node_modules 2>/dev/null | wc -l)
        
        local score=10
        [ "$secrets_count" -gt 0 ] && score=$((10 - secrets_count))
        [ "$score" -lt 0 ] && score=0
        
        security_result=$(jq -n --argjson score "$score" '{
            secrets: {total_secrets_found: 0},
            dependencies: {totals: {critical: 0, high: 0}},
            overall_score: $score
        }')
    fi
    
    echo "$security_result"
}

run_testing_analysis() {
    local codebase="$1"
    
    log INFO "Analyzing test coverage and results..."
    
    local testing_result='{}'
    
    if type analyze_tests &>/dev/null; then
        testing_result=$(analyze_tests "$codebase")
    else
        # Basic test detection
        local test_files=$(find "$codebase" \
            \( -name "*test*.js" -o -name "*spec*.js" -o -name "test_*.py" -o -name "*_test.go" \) \
            -not -path "*/node_modules/*" 2>/dev/null | wc -l)
        
        local score=5
        [ "$test_files" -gt 10 ] && score=7
        [ "$test_files" -gt 50 ] && score=9
        
        testing_result=$(jq -n --argjson score "$score" --argjson files "$test_files" '{
            coverage: {found: false},
            test_results: {found: false},
            overall_score: $score,
            test_files_found: $files
        }')
    fi
    
    echo "$testing_result"
}

run_cicd_analysis() {
    local codebase="$1"
    
    log INFO "Analyzing CI/CD configuration..."
    
    local cicd_result='{}'
    
    if type analyze_cicd &>/dev/null; then
        cicd_result=$(analyze_cicd "$codebase")
    else
        # Basic CI/CD detection
        local has_ci=false
        [ -d "$codebase/.github/workflows" ] && has_ci=true
        [ -f "$codebase/.gitlab-ci.yml" ] && has_ci=true
        [ -f "$codebase/Jenkinsfile" ] && has_ci=true
        
        local score=0
        [ "$has_ci" = "true" ] && score=7
        
        cicd_result=$(jq -n --argjson score "$score" --argjson has_ci "$has_ci" '{
            platforms_detected: [],
            overall_score: $score,
            has_ci: $has_ci
        }')
    fi
    
    echo "$cicd_result"
}

run_documentation_analysis() {
    local codebase="$1"
    
    log INFO "Analyzing documentation quality..."
    
    local docs_result='{}'
    
    if type analyze_documentation &>/dev/null; then
        docs_result=$(analyze_documentation "$codebase")
    else
        # Basic documentation check
        local has_readme=false
        [ -f "$codebase/README.md" ] && has_readme=true
        
        local score=3
        [ "$has_readme" = "true" ] && score=6
        [ -f "$codebase/CONTRIBUTING.md" ] && score=$((score + 1))
        [ -d "$codebase/docs" ] && score=$((score + 1))
        
        docs_result=$(jq -n --argjson score "$score" '{
            readme: {found: true},
            overall_score: $score
        }')
    fi
    
    echo "$docs_result"
}

# =============================================================================
# SCORE CALCULATION
# =============================================================================

calculate_category_scores() {
    local analysis="$1"
    local metrics="$2"
    local security="$3"
    local testing="$4"
    local cicd="$5"
    local docs="$6"
    
    local scores='{}'
    
    # Code Quality Score
    local complexity=$(echo "$metrics" | jq '.complexity.average // 10')
    local duplication=$(echo "$metrics" | jq '.duplication.percentage // 10')
    local maintainability=$(echo "$metrics" | jq '.maintainability.index // 70')
    
    local cq_score=$(math_calc "10 - ($complexity / 5) - ($duplication / 20) + ($maintainability / 20)")
    math_compare "$cq_score" ">" "10" && cq_score=10
    math_compare "$cq_score" "<" "0" && cq_score=0
    scores=$(echo "$scores" | jq --arg s "$cq_score" '.code_quality = {score: ($s | tonumber)}')
    
    # Architecture Score (based on project structure)
    local project_type=$(echo "$analysis" | jq -r '.project_type // "unknown"')
    local arch_score=5
    case "$project_type" in
        monorepo) arch_score=8 ;;
        microservices) arch_score=9 ;;
        fullstack) arch_score=7 ;;
        library) arch_score=7 ;;
        api) arch_score=6 ;;
    esac
    scores=$(echo "$scores" | jq --argjson s "$arch_score" '.architecture = {score: $s}')
    
    # Security Score
    local sec_score=$(echo "$security" | jq '.overall_score // 5')
    scores=$(echo "$scores" | jq --argjson s "$sec_score" '.security = {score: $s}')
    
    # Testing Score
    local test_score=$(echo "$testing" | jq '.overall_score // 5')
    scores=$(echo "$scores" | jq --argjson s "$test_score" '.testing = {score: $s}')
    
    # DevOps Score
    local devops_score=$(echo "$cicd" | jq '.overall_score // 5')
    scores=$(echo "$scores" | jq --argjson s "$devops_score" '.devops = {score: $s}')
    
    # Documentation Score
    local docs_score=$(echo "$docs" | jq '.overall_score // 5')
    scores=$(echo "$scores" | jq --argjson s "$docs_score" '.documentation = {score: $s}')
    
    # Performance Score (estimate based on metrics)
    local perf_score=6
    local debt_hours=$(echo "$metrics" | jq '.technical_debt.hours // 0')
    if math_compare "$debt_hours" "<" "40"; then
        perf_score=8
    elif math_compare "$debt_hours" "<" "100"; then
        perf_score=6
    else
        perf_score=4
    fi
    scores=$(echo "$scores" | jq --argjson s "$perf_score" '.performance = {score: $s}')
    
    # Default scores for other categories
    scores=$(echo "$scores" | jq '
        . + {
            scalability: {score: 6},
            reliability: {score: 6},
            data: {score: 6},
            api: {score: 6},
            observability: {score: 5},
            frontend: {score: 6},
            backend: {score: 6},
            developer_experience: {score: 6},
            maintainability: {score: 6}
        }
    ')
    
    echo "$scores"
}

calculate_overall_score() {
    local scores="$1"
    
    local weighted_sum=0
    local total_weight=0
    
    for category in "${!WEIGHTS[@]}"; do
        local weight="${WEIGHTS[$category]}"
        local score=$(echo "$scores" | jq --arg cat "$category" '.[$cat].score // 5')
        
        weighted_sum=$(math_calc "$weighted_sum + ($score * $weight)")
        total_weight=$((total_weight + weight))
    done
    
    local overall=$(math_calc "$weighted_sum / $total_weight")
    echo "$overall"
}

# =============================================================================
# MAIN EVALUATION FUNCTION
# =============================================================================

run_enhanced_evaluation() {
    local codebase="$1"
    local output_format="${2:-all}"
    
    if [ -z "$codebase" ]; then
        echo "Usage: $0 <codebase_path> [output_format]"
        exit 1
    fi
    
    if [ ! -d "$codebase" ]; then
        log ERROR "Codebase directory not found: $codebase"
        exit 1
    fi
    
    # Resolve absolute path
    codebase=$(cd "$codebase" && pwd)
    
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "  CTO Codebase Evaluation Suite v${VERSION}"
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "Evaluating: $codebase"
    log INFO ""
    
    mkdir -p "$OUTPUT_DIR"
    
    local start_time=$(date +%s)
    local total_steps=7
    local current_step=0
    
    # Step 1: Intelligent Analysis
    current_step=$((current_step + 1))
    show_progress "$current_step" "$total_steps" "Intelligent Analysis"
    local analysis=$(run_intelligent_analysis "$codebase")
    echo ""
    
    # Step 2: Code Metrics
    current_step=$((current_step + 1))
    show_progress "$current_step" "$total_steps" "Code Metrics"
    local metrics=$(run_code_metrics "$codebase")
    echo ""
    
    # Step 3: Security Analysis
    current_step=$((current_step + 1))
    show_progress "$current_step" "$total_steps" "Security Analysis"
    local security=$(run_security_analysis "$codebase")
    echo ""
    
    # Step 4: Testing Analysis
    current_step=$((current_step + 1))
    show_progress "$current_step" "$total_steps" "Testing Analysis"
    local testing=$(run_testing_analysis "$codebase")
    echo ""
    
    # Step 5: CI/CD Analysis
    current_step=$((current_step + 1))
    show_progress "$current_step" "$total_steps" "CI/CD Analysis"
    local cicd=$(run_cicd_analysis "$codebase")
    echo ""
    
    # Step 6: Documentation Analysis
    current_step=$((current_step + 1))
    show_progress "$current_step" "$total_steps" "Documentation Analysis"
    local docs=$(run_documentation_analysis "$codebase")
    echo ""
    
    # Step 7: Calculate Scores
    current_step=$((current_step + 1))
    show_progress "$current_step" "$total_steps" "Calculating Scores"
    
    local scores=$(calculate_category_scores "$analysis" "$metrics" "$security" "$testing" "$cicd" "$docs")
    local overall=$(calculate_overall_score "$scores")
    echo ""
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Compile final results
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local results=$(jq -n \
        --arg version "$VERSION" \
        --arg codebase "$codebase" \
        --arg timestamp "$timestamp" \
        --argjson duration "$duration" \
        --argjson analysis "$analysis" \
        --argjson metrics "$metrics" \
        --argjson security "$security" \
        --argjson testing "$testing" \
        --argjson cicd "$cicd" \
        --argjson docs "$docs" \
        --argjson categories "$scores" \
        --arg overall "$overall" \
        '{
            version: $version,
            codebase_path: $codebase,
            timestamp: $timestamp,
            duration_seconds: $duration,
            analysis: $analysis,
            metrics: $metrics,
            security_scan: $security,
            testing_analysis: $testing,
            cicd_analysis: $cicd,
            documentation_analysis: $docs,
            categories: $categories,
            overall_score: ($overall | tonumber)
        }')
    
    # Save raw results
    local results_file="$OUTPUT_DIR/evaluation_results_$(date '+%Y%m%d_%H%M%S').json"
    echo "$results" > "$results_file"
    log INFO "Raw results saved to: $results_file"
    
    # Generate reports
    if type generate_report &>/dev/null; then
        generate_report "$results_file" "$OUTPUT_DIR" "$output_format"
    fi
    
    # Display summary
    local grade=""
    grade=$(math_grade "$overall")
    
    echo ""
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO "  EVALUATION COMPLETE"
    log INFO "═══════════════════════════════════════════════════════════"
    log INFO ""
    log INFO "  Overall Score: $overall/10 (Grade: $grade)"
    log INFO "  Duration: ${duration}s"
    log INFO ""
    log INFO "  Category Highlights:"
    
    echo "$scores" | jq -r 'to_entries[] | "    \(.key): \(.value.score)"' | while read line; do
        log INFO "$line"
    done
    
    log INFO ""
    log INFO "  Reports generated in: $OUTPUT_DIR"
    log INFO "═══════════════════════════════════════════════════════════"
    
    # Return results for programmatic use
    echo "$results"
}

# =============================================================================
# ENTRY POINT
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_enhanced_evaluation "$@"
fi
