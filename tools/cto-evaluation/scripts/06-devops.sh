#!/bin/bash

# =============================================================================
# DEVOPS EVALUATION (Parameters 211-234)
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
source "$SCRIPT_DIR/common-progress.sh"
source "$SCRIPT_DIR/common-findings.sh"
source "$SCRIPT_DIR/lib/math-utils.sh"
init_findings

set_total_steps 5

RESULTS='{
    "category": "devops",
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

# Check CI/CD configuration
check_cicd() {
    progress_step "CI/CD configuration"
    local score=3

    # GitHub Actions
    if [ -d "$CODEBASE_PATH/.github/workflows" ]; then
        local workflow_count=$( (ls -1 "$CODEBASE_PATH/.github/workflows/"*.yml 2>/dev/null || true) | wc -l)
        log_metric "github_actions_workflows" "$workflow_count"

        if [ "$workflow_count" -gt 0 ]; then
            score=7

            # Check for test job
            if grep -rq "test\|jest\|pytest\|npm test" "$CODEBASE_PATH/.github/workflows/" 2>/dev/null; then
                log_metric "ci_tests" "true"
                score=$((score + 1))
            fi

            # Check for build job
            if grep -rq "build\|compile" "$CODEBASE_PATH/.github/workflows/" 2>/dev/null; then
                log_metric "ci_build" "true"
                score=$((score + 1))
            fi

            # Check for deploy job
            if grep -rq "deploy\|release" "$CODEBASE_PATH/.github/workflows/" 2>/dev/null; then
                log_metric "ci_deploy" "true"
                score=$((score + 1))
            fi
        fi
    # GitLab CI
    elif [ -f "$CODEBASE_PATH/.gitlab-ci.yml" ]; then
        log_metric "gitlab_ci" "true"
        score=8
    # CircleCI
    elif [ -f "$CODEBASE_PATH/.circleci/config.yml" ]; then
        log_metric "circleci" "true"
        score=8
    # Jenkins
    elif [ -f "$CODEBASE_PATH/Jenkinsfile" ]; then
        log_metric "jenkinsfile" "true"
        score=7
    else
        add_finding "high" "ci_cd" "No CI/CD configuration found" "$CODEBASE_PATH/.github/workflows"
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# Check containerization
check_containers() {
    echo "  Checking containerization..." >&2
    local score=3

    # Dockerfile
    if [ -f "$CODEBASE_PATH/Dockerfile" ]; then
        log_metric "dockerfile" "true"
        score=7

        # Check Dockerfile best practices
        if grep -q "FROM.*:.*" "$CODEBASE_PATH/Dockerfile" && \
           ! grep -q "FROM.*:latest" "$CODEBASE_PATH/Dockerfile"; then
            log_metric "pinned_base_image" "true"
            score=$((score + 1))
        else
            add_finding "medium" "docker" "Docker base image not pinned to specific version" "$CODEBASE_PATH/Dockerfile"
        fi

        # Multi-stage build
        if grep -c "^FROM" "$CODEBASE_PATH/Dockerfile" | grep -q "^[2-9]"; then
            log_metric "multi_stage_build" "true"
            score=$((score + 1))
        fi

        # Non-root user
        if grep -q "USER" "$CODEBASE_PATH/Dockerfile"; then
            log_metric "non_root_user" "true"
            score=$((score + 1))
        else
            add_finding "medium" "docker" "Docker container may run as root" "$CODEBASE_PATH/Dockerfile"
        fi
    else
        add_finding "low" "containerization" "No Dockerfile found" "$CODEBASE_PATH"
    fi

    # Docker Compose
    if [ -f "$CODEBASE_PATH/docker-compose.yml" ] || [ -f "$CODEBASE_PATH/docker-compose.yaml" ]; then
        log_metric "docker_compose" "true"
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# Check Infrastructure as Code
check_iac() {
    echo "  Checking Infrastructure as Code..." >&2
    local score=3

    # Terraform
    if ls "$CODEBASE_PATH"/*.tf "$CODEBASE_PATH"/**/*.tf 2>/dev/null | head -1 > /dev/null; then
        log_metric "terraform" "true"
        score=8

        # Check for remote state
        if grep -rq "backend\s*\"" "$CODEBASE_PATH" --include="*.tf" 2>/dev/null; then
            log_metric "terraform_remote_state" "true"
            score=$((score + 1))
        fi
    fi

    # Kubernetes
    if ls "$CODEBASE_PATH"/*.yaml "$CODEBASE_PATH"/**/*.yaml 2>/dev/null | \
       xargs grep -l "kind:\s*\(Deployment\|Service\|Pod\)" 2>/dev/null | head -1 > /dev/null; then
        log_metric "kubernetes" "true"
        score=$((score + 1))
    fi

    # Helm
    if [ -d "$CODEBASE_PATH/charts" ] || [ -f "$CODEBASE_PATH/Chart.yaml" ]; then
        log_metric "helm" "true"
        score=$((score + 1))
    fi

    # CloudFormation
    if grep -rq "AWSTemplateFormatVersion" "$CODEBASE_PATH" --include="*.yaml" --include="*.json" 2>/dev/null; then
        log_metric "cloudformation" "true"
        score=8
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# Check environment configuration
check_environments() {
    echo "  Checking environment configuration..." >&2
    local score=5

    # .env files
    if [ -f "$CODEBASE_PATH/.env.example" ] || [ -f "$CODEBASE_PATH/.env.sample" ]; then
        log_metric "env_example" "true"
        score=7
    else
        add_finding "low" "environment" "No .env.example file found"
    fi

    # Environment-specific configs
    local env_configs=$(find "$CODEBASE_PATH" -name "*.production.*" -o -name "*.staging.*" -o -name "*.development.*" 2>/dev/null | wc -l)
    if [ "$env_configs" -gt 0 ]; then
        log_metric "environment_configs" "$env_configs"
        score=$((score + 2))
    fi

    # Check for secrets in config
    if grep -rqE "(password|secret|api_key).*=.*['\"][^'\"]{8,}" "$CODEBASE_PATH" \
        --include="*.env" --include="*.json" --exclude-dir=node_modules 2>/dev/null; then
        add_finding "high" "secrets" "Potential secrets found in configuration files"
        score=$((score - 2))
    fi

    [ "$score" -gt 10 ] && score=10
    [ "$score" -lt 1 ] && score=1
    echo "$score"
}

main() {
    echo "Starting DevOps Evaluation..."

    local cicd_score=$(check_cicd)
    local container_score=$(check_containers)
    local iac_score=$(check_iac)
    local env_score=$(check_environments)

    local total_score=$(math_calc "$cicd_score * 0.35 + $container_score * 0.25 + $iac_score * 0.25 + $env_score * 0.15")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 24')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg cs "$cicd_score" --arg cos "$container_score" --arg is "$iac_score" --arg es "$env_score" \
        '.subscores = {cicd: ($cs | tonumber), containers: ($cos | tonumber), iac: ($is | tonumber), environments: ($es | tonumber)}')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "DevOps Score: $total_score/10"
}

main
