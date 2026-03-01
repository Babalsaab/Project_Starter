#!/bin/bash

# =============================================================================
# CI/CD CONFIGURATION ANALYZER
# =============================================================================
# Analyzes CI/CD configurations for best practices:
#   - GitHub Actions
#   - GitLab CI
#   - Jenkins
#   - CircleCI
#   - Azure Pipelines
#   - Bitbucket Pipelines
#   - Travis CI
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/math-utils.sh"

# =============================================================================
# CI/CD PLATFORM DETECTION
# =============================================================================

detect_cicd_platform() {
    local codebase="$1"
    local platforms='[]'
    
    # GitHub Actions
    if [ -d "$codebase/.github/workflows" ]; then
        local workflow_count=$(find "$codebase/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
        platforms=$(echo "$platforms" | jq --argjson count "$workflow_count" '. += [{name: "github_actions", files: $count}]')
    fi
    
    # GitLab CI
    if [ -f "$codebase/.gitlab-ci.yml" ]; then
        platforms=$(echo "$platforms" | jq '. += [{name: "gitlab_ci", files: 1}]')
    fi
    
    # Jenkins
    if [ -f "$codebase/Jenkinsfile" ]; then
        platforms=$(echo "$platforms" | jq '. += [{name: "jenkins", files: 1}]')
    fi
    local jenkins_count=$(find "$codebase" -name "Jenkinsfile*" 2>/dev/null | wc -l)
    if [ "$jenkins_count" -gt 1 ]; then
        platforms=$(echo "$platforms" | jq --argjson count "$jenkins_count" '. += [{name: "jenkins", files: $count}]')
    fi
    
    # CircleCI
    if [ -f "$codebase/.circleci/config.yml" ]; then
        platforms=$(echo "$platforms" | jq '. += [{name: "circleci", files: 1}]')
    fi
    
    # Azure Pipelines
    if [ -f "$codebase/azure-pipelines.yml" ]; then
        platforms=$(echo "$platforms" | jq '. += [{name: "azure_pipelines", files: 1}]')
    fi
    
    # Bitbucket Pipelines
    if [ -f "$codebase/bitbucket-pipelines.yml" ]; then
        platforms=$(echo "$platforms" | jq '. += [{name: "bitbucket_pipelines", files: 1}]')
    fi
    
    # Travis CI
    if [ -f "$codebase/.travis.yml" ]; then
        platforms=$(echo "$platforms" | jq '. += [{name: "travis_ci", files: 1}]')
    fi
    
    # Drone CI
    if [ -f "$codebase/.drone.yml" ]; then
        platforms=$(echo "$platforms" | jq '. += [{name: "drone", files: 1}]')
    fi
    
    echo "$platforms"
}

# =============================================================================
# GITHUB ACTIONS ANALYZER
# =============================================================================

analyze_github_actions() {
    local codebase="$1"
    local analysis='{
        "workflows": [],
        "best_practices": {
            "has_ci": false,
            "has_cd": false,
            "has_security_scanning": false,
            "has_dependency_updates": false,
            "has_caching": false,
            "has_matrix_builds": false,
            "has_concurrency": false,
            "has_timeout": false,
            "has_permissions": false,
            "has_reusable_workflows": false
        },
        "issues": [],
        "score": 0
    }'
    
    local workflow_dir="$codebase/.github/workflows"
    
    if [ ! -d "$workflow_dir" ]; then
        echo "$analysis"
        return
    fi
    
    echo "    Analyzing GitHub Actions workflows..." >&2
    
    for workflow_file in "$workflow_dir"/*.yml "$workflow_dir"/*.yaml; do
        [ -f "$workflow_file" ] || continue
        
        local filename=$(basename "$workflow_file")
        local content=$(cat "$workflow_file")
        
        # Detect workflow type
        local workflow_type="unknown"
        if echo "$content" | grep -qE 'push:|pull_request:'; then
            workflow_type="ci"
            analysis=$(echo "$analysis" | jq '.best_practices.has_ci = true')
        fi
        if echo "$content" | grep -qiE 'deploy|release|publish'; then
            workflow_type="cd"
            analysis=$(echo "$analysis" | jq '.best_practices.has_cd = true')
        fi
        
        # Check for security scanning
        if echo "$content" | grep -qiE 'codeql|snyk|semgrep|trivy|dependabot|security'; then
            analysis=$(echo "$analysis" | jq '.best_practices.has_security_scanning = true')
        fi
        
        # Check for caching
        if echo "$content" | grep -qE 'actions/cache@|cache:'; then
            analysis=$(echo "$analysis" | jq '.best_practices.has_caching = true')
        fi
        
        # Check for matrix builds
        if echo "$content" | grep -qE 'matrix:'; then
            analysis=$(echo "$analysis" | jq '.best_practices.has_matrix_builds = true')
        fi
        
        # Check for concurrency control
        if echo "$content" | grep -qE 'concurrency:'; then
            analysis=$(echo "$analysis" | jq '.best_practices.has_concurrency = true')
        fi
        
        # Check for timeout
        if echo "$content" | grep -qE 'timeout-minutes:'; then
            analysis=$(echo "$analysis" | jq '.best_practices.has_timeout = true')
        fi
        
        # Check for permissions
        if echo "$content" | grep -qE '^permissions:'; then
            analysis=$(echo "$analysis" | jq '.best_practices.has_permissions = true')
        fi
        
        # Check for reusable workflows
        if echo "$content" | grep -qE 'workflow_call:|uses:.*\.github/workflows/'; then
            analysis=$(echo "$analysis" | jq '.best_practices.has_reusable_workflows = true')
        fi
        
        # Add workflow to list
        local triggers=$(echo "$content" | grep -E '^on:' -A 10 | grep -E '^\s{2}\w' | awk '{print $1}' | tr -d ':' | tr '\n' ',' | sed 's/,$//')
        analysis=$(echo "$analysis" | jq --arg name "$filename" --arg type "$workflow_type" --arg triggers "$triggers" \
            '.workflows += [{name: $name, type: $type, triggers: $triggers}]')
        
        # Check for issues
        if echo "$content" | grep -qE 'checkout@v[12]' ; then
            analysis=$(echo "$analysis" | jq --arg file "$filename" \
                '.issues += [{file: $file, severity: "medium", message: "Using outdated checkout action version"}]')
        fi
        
        if ! echo "$content" | grep -qE 'timeout-minutes:'; then
            analysis=$(echo "$analysis" | jq --arg file "$filename" \
                '.issues += [{file: $file, severity: "low", message: "No timeout defined - could run indefinitely"}]')
        fi
        
        if echo "$content" | grep -qE '\$\{\{.*secrets\.' && ! echo "$content" | grep -qE '^permissions:'; then
            analysis=$(echo "$analysis" | jq --arg file "$filename" \
                '.issues += [{file: $file, severity: "medium", message: "Uses secrets but no explicit permissions defined"}]')
        fi
    done
    
    # Check for Dependabot
    if [ -f "$codebase/.github/dependabot.yml" ] || [ -f "$codebase/.github/dependabot.yaml" ]; then
        analysis=$(echo "$analysis" | jq '.best_practices.has_dependency_updates = true')
    fi
    
    # Calculate score
    local score=0
    local bp=$(echo "$analysis" | jq '.best_practices')
    
    [ "$(echo "$bp" | jq '.has_ci')" == "true" ] && score=$((score + 2))
    [ "$(echo "$bp" | jq '.has_cd')" == "true" ] && score=$((score + 1))
    [ "$(echo "$bp" | jq '.has_security_scanning')" == "true" ] && score=$((score + 2))
    [ "$(echo "$bp" | jq '.has_dependency_updates')" == "true" ] && score=$((score + 1))
    [ "$(echo "$bp" | jq '.has_caching')" == "true" ] && score=$((score + 1))
    [ "$(echo "$bp" | jq '.has_matrix_builds')" == "true" ] && score=$((score + 1))
    [ "$(echo "$bp" | jq '.has_concurrency')" == "true" ] && score=$((score + 0.5))
    [ "$(echo "$bp" | jq '.has_timeout')" == "true" ] && score=$((score + 0.5))
    [ "$(echo "$bp" | jq '.has_permissions')" == "true" ] && score=$((score + 1))
    
    # Cap at 10
    [ "$score" -gt 10 ] && score=10
    
    analysis=$(echo "$analysis" | jq --argjson score "$score" '.score = $score')
    
    echo "$analysis"
}

# =============================================================================
# GITLAB CI ANALYZER
# =============================================================================

analyze_gitlab_ci() {
    local codebase="$1"
    local analysis='{
        "stages": [],
        "jobs": [],
        "best_practices": {
            "has_stages": false,
            "has_caching": false,
            "has_artifacts": false,
            "has_rules": false,
            "has_includes": false,
            "has_parallel": false
        },
        "score": 0
    }'
    
    local gitlab_file="$codebase/.gitlab-ci.yml"
    
    if [ ! -f "$gitlab_file" ]; then
        echo "$analysis"
        return
    fi
    
    echo "    Analyzing GitLab CI configuration..." >&2
    
    local content=$(cat "$gitlab_file")
    
    # Check for stages
    if echo "$content" | grep -qE '^stages:'; then
        analysis=$(echo "$analysis" | jq '.best_practices.has_stages = true')
        local stages=$(echo "$content" | grep -A 20 '^stages:' | grep -E '^\s+-\s+' | sed 's/.*-\s*//' | tr '\n' ',' | sed 's/,$//')
        analysis=$(echo "$analysis" | jq --arg stages "$stages" '.stages = ($stages | split(","))')
    fi
    
    # Check for caching
    if echo "$content" | grep -qE '^cache:|^\s+cache:'; then
        analysis=$(echo "$analysis" | jq '.best_practices.has_caching = true')
    fi
    
    # Check for artifacts
    if echo "$content" | grep -qE '^\s+artifacts:'; then
        analysis=$(echo "$analysis" | jq '.best_practices.has_artifacts = true')
    fi
    
    # Check for rules (modern approach vs only/except)
    if echo "$content" | grep -qE '^\s+rules:'; then
        analysis=$(echo "$analysis" | jq '.best_practices.has_rules = true')
    fi
    
    # Check for includes
    if echo "$content" | grep -qE '^include:'; then
        analysis=$(echo "$analysis" | jq '.best_practices.has_includes = true')
    fi
    
    # Check for parallel
    if echo "$content" | grep -qE '^\s+parallel:'; then
        analysis=$(echo "$analysis" | jq '.best_practices.has_parallel = true')
    fi
    
    # Calculate score
    local score=5  # Base score for having GitLab CI
    local bp=$(echo "$analysis" | jq '.best_practices')
    
    [ "$(echo "$bp" | jq '.has_stages')" == "true" ] && score=$((score + 1))
    [ "$(echo "$bp" | jq '.has_caching')" == "true" ] && score=$((score + 1))
    [ "$(echo "$bp" | jq '.has_artifacts')" == "true" ] && score=$((score + 1))
    [ "$(echo "$bp" | jq '.has_rules')" == "true" ] && score=$((score + 1))
    [ "$(echo "$bp" | jq '.has_includes')" == "true" ] && score=$((score + 1))
    
    [ "$score" -gt 10 ] && score=10
    
    analysis=$(echo "$analysis" | jq --argjson score "$score" '.score = $score')
    
    echo "$analysis"
}

# =============================================================================
# COMPREHENSIVE CI/CD ANALYSIS
# =============================================================================

analyze_cicd() {
    local codebase="$1"
    local output_file="${2:-/dev/stdout}"
    
    echo "Analyzing CI/CD configuration..." >&2
    
    local platforms=$(detect_cicd_platform "$codebase")
    local platform_count=$(echo "$platforms" | jq 'length')
    
    local result='{
        "cicd_analysis_version": "2.0",
        "platforms_detected": [],
        "github_actions": null,
        "gitlab_ci": null,
        "deployment_configs": {
            "has_docker": false,
            "has_kubernetes": false,
            "has_terraform": false,
            "has_helm": false
        },
        "overall_score": 0,
        "recommendations": []
    }'
    
    result=$(echo "$result" | jq --argjson platforms "$platforms" '.platforms_detected = $platforms')
    
    # Analyze each platform
    if echo "$platforms" | jq -e '.[] | select(.name == "github_actions")' &>/dev/null; then
        local gh_analysis=$(analyze_github_actions "$codebase")
        result=$(echo "$result" | jq --argjson gh "$gh_analysis" '.github_actions = $gh')
    fi
    
    if echo "$platforms" | jq -e '.[] | select(.name == "gitlab_ci")' &>/dev/null; then
        local gl_analysis=$(analyze_gitlab_ci "$codebase")
        result=$(echo "$result" | jq --argjson gl "$gl_analysis" '.gitlab_ci = $gl')
    fi
    
    # Check for deployment configs
    if [ -f "$codebase/Dockerfile" ] || find "$codebase" -name "Dockerfile*" -type f 2>/dev/null | head -1 | grep -q .; then
        result=$(echo "$result" | jq '.deployment_configs.has_docker = true')
    fi
    
    if [ -d "$codebase/k8s" ] || [ -d "$codebase/kubernetes" ] || find "$codebase" -name "*.yaml" -exec grep -l "apiVersion.*kind" {} \; 2>/dev/null | head -1 | grep -q .; then
        result=$(echo "$result" | jq '.deployment_configs.has_kubernetes = true')
    fi
    
    if find "$codebase" -name "*.tf" 2>/dev/null | head -1 | grep -q .; then
        result=$(echo "$result" | jq '.deployment_configs.has_terraform = true')
    fi
    
    if [ -d "$codebase/helm" ] || [ -f "$codebase/Chart.yaml" ]; then
        result=$(echo "$result" | jq '.deployment_configs.has_helm = true')
    fi
    
    # Calculate overall score
    local score=0
    
    if [ "$platform_count" -gt 0 ]; then
        score=5  # Base score for having CI/CD
        
        local gh_score=$(echo "$result" | jq '.github_actions.score // 0')
        local gl_score=$(echo "$result" | jq '.gitlab_ci.score // 0')
        
        if [ "$gh_score" -gt "$score" ]; then
            score=$gh_score
        fi
        if [ "$gl_score" -gt "$score" ]; then
            score=$gl_score
        fi
    fi
    
    # Add deployment config bonus
    local deploy=$(echo "$result" | jq '.deployment_configs')
    [ "$(echo "$deploy" | jq '.has_docker')" == "true" ] && score=$(math_calc "$score + 0.5")
    [ "$(echo "$deploy" | jq '.has_kubernetes')" == "true" ] && score=$(math_calc "$score + 0.5")
    [ "$(echo "$deploy" | jq '.has_terraform')" == "true" ] && score=$(math_calc "$score + 0.5")

    # Cap at 10
    if math_compare "$score" ">" "10"; then score=10; fi
    
    result=$(echo "$result" | jq --argjson score "$score" '.overall_score = $score')
    
    # Generate recommendations
    local recs='[]'
    
    if [ "$platform_count" -eq 0 ]; then
        recs=$(echo "$recs" | jq '. += ["Set up CI/CD - consider GitHub Actions or GitLab CI"]')
    fi
    
    if [ "$(echo "$result" | jq '.github_actions.best_practices.has_security_scanning // false')" == "false" ] && \
       [ "$(echo "$result" | jq '.github_actions // null')" != "null" ]; then
        recs=$(echo "$recs" | jq '. += ["Add security scanning to CI pipeline (CodeQL, Snyk, or Trivy)"]')
    fi
    
    if [ "$(echo "$result" | jq '.github_actions.best_practices.has_caching // false')" == "false" ] && \
       [ "$(echo "$result" | jq '.github_actions // null')" != "null" ]; then
        recs=$(echo "$recs" | jq '. += ["Add caching to speed up CI builds"]')
    fi
    
    if [ "$(echo "$deploy" | jq '.has_docker')" == "false" ]; then
        recs=$(echo "$recs" | jq '. += ["Consider containerizing with Docker for consistent deployments"]')
    fi
    
    result=$(echo "$result" | jq --argjson recs "$recs" '.recommendations = $recs')
    
    echo "$result" > "$output_file"
    cat "$output_file"
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    analyze_cicd "$@"
fi
