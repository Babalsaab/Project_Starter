#!/bin/bash

# =============================================================================
# ENHANCED DEVOPS ANALYZER
# =============================================================================
# Deep analysis of CI/CD, infrastructure, deployment practices
# Supports: GitHub Actions, GitLab CI, Jenkins, CircleCI, Docker, K8s, Terraform
# =============================================================================

# =============================================================================
# MAIN DEVOPS ANALYSIS
# =============================================================================

analyze_devops() {
    local codebase_path="$1"
    local output_dir="${2:-${TMPDIR:-/tmp}/devops-analysis}"
    
    mkdir -p "$output_dir"
    
    # Run all DevOps checks
    local cicd_result=$(check_cicd_pipeline "$codebase_path")
    local docker_result=$(check_containerization "$codebase_path")
    local k8s_result=$(check_kubernetes "$codebase_path")
    local iac_result=$(check_infrastructure_as_code "$codebase_path")
    local deploy_result=$(check_deployment_practices "$codebase_path")
    local env_result=$(check_environment_management "$codebase_path")
    local gitops_result=$(check_gitops "$codebase_path")
    
    # Calculate scores
    local cicd_score=$(echo "$cicd_result" | jq -r '.score // 5')
    local docker_score=$(echo "$docker_result" | jq -r '.score // 5')
    local k8s_score=$(echo "$k8s_result" | jq -r '.score // 5')
    local iac_score=$(echo "$iac_result" | jq -r '.score // 5')
    local deploy_score=$(echo "$deploy_result" | jq -r '.score // 5')
    
    local overall_score=$(( (cicd_score + docker_score + iac_score + deploy_score) / 4 ))
    
    cat << EOF
{
    "overall_score": $overall_score,
    "cicd_analysis": $cicd_result,
    "docker_analysis": $docker_result,
    "kubernetes_analysis": $k8s_result,
    "iac_analysis": $iac_result,
    "deployment_analysis": $deploy_result,
    "environment_analysis": $env_result,
    "gitops_analysis": $gitops_result
}
EOF
}

# =============================================================================
# CI/CD PIPELINE CHECK
# =============================================================================

check_cicd_pipeline() {
    local codebase_path="$1"
    local score=5
    local features=0
    local pipeline_type="none"
    
    # Detect CI/CD platform
    if [ -d "$codebase_path/.github/workflows" ]; then
        pipeline_type="github_actions"
        features=$((features + 2))
    fi
    
    if [ -f "$codebase_path/.gitlab-ci.yml" ]; then
        pipeline_type="gitlab_ci"
        features=$((features + 2))
    fi
    
    if [ -f "$codebase_path/Jenkinsfile" ]; then
        pipeline_type="jenkins"
        features=$((features + 2))
    fi
    
    if [ -f "$codebase_path/.circleci/config.yml" ]; then
        pipeline_type="circleci"
        features=$((features + 2))
    fi
    
    if [ -f "$codebase_path/azure-pipelines.yml" ]; then
        pipeline_type="azure_devops"
        features=$((features + 2))
    fi
    
    if [ -f "$codebase_path/bitbucket-pipelines.yml" ]; then
        pipeline_type="bitbucket"
        features=$((features + 2))
    fi
    
    # Analyze pipeline quality
    local pipeline_files=""
    case $pipeline_type in
        github_actions) pipeline_files="$codebase_path/.github/workflows/*.yml $codebase_path/.github/workflows/*.yaml" ;;
        gitlab_ci) pipeline_files="$codebase_path/.gitlab-ci.yml" ;;
        jenkins) pipeline_files="$codebase_path/Jenkinsfile" ;;
        circleci) pipeline_files="$codebase_path/.circleci/config.yml" ;;
        azure_devops) pipeline_files="$codebase_path/azure-pipelines.yml" ;;
    esac
    
    if [ -n "$pipeline_files" ]; then
        # Check for tests in CI
        local has_tests=$(cat $pipeline_files 2>/dev/null | grep -c "test\|Test\|TEST\|npm run test\|pytest\|go test\|cargo test")
        [ "$has_tests" -gt 0 ] && features=$((features + 1))
        
        # Check for linting in CI
        local has_lint=$(cat $pipeline_files 2>/dev/null | grep -c "lint\|eslint\|pylint\|golint\|clippy")
        [ "$has_lint" -gt 0 ] && features=$((features + 1))
        
        # Check for security scanning
        local has_security=$(cat $pipeline_files 2>/dev/null | grep -c "security\|snyk\|trivy\|codeql\|sonar\|semgrep\|bandit")
        [ "$has_security" -gt 0 ] && features=$((features + 1))
        
        # Check for build step
        local has_build=$(cat $pipeline_files 2>/dev/null | grep -c "build\|compile\|docker build")
        [ "$has_build" -gt 0 ] && features=$((features + 1))
        
        # Check for deployment step
        local has_deploy=$(cat $pipeline_files 2>/dev/null | grep -c "deploy\|release\|publish")
        [ "$has_deploy" -gt 0 ] && features=$((features + 1))
        
        # Check for caching
        local has_cache=$(cat $pipeline_files 2>/dev/null | grep -c "cache\|Cache\|actions/cache")
        [ "$has_cache" -gt 0 ] && features=$((features + 1))
        
        # Check for matrix builds
        local has_matrix=$(cat $pipeline_files 2>/dev/null | grep -c "matrix\|strategy:")
        [ "$has_matrix" -gt 0 ] && features=$((features + 1))
        
        # Check for environment protection
        local has_protection=$(cat $pipeline_files 2>/dev/null | grep -c "environment:\|approval\|protected")
        [ "$has_protection" -gt 0 ] && features=$((features + 1))
        
        # Check for artifact management
        local has_artifacts=$(cat $pipeline_files 2>/dev/null | grep -c "artifact\|upload\|download")
        [ "$has_artifacts" -gt 0 ] && features=$((features + 1))
    fi
    
    score=$((3 + features))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "pipeline_type": "$pipeline_type",
    "features": $features,
    "has_tests": $([ "$has_tests" -gt 0 ] && echo "true" || echo "false"),
    "has_lint": $([ "$has_lint" -gt 0 ] && echo "true" || echo "false"),
    "has_security": $([ "$has_security" -gt 0 ] && echo "true" || echo "false"),
    "has_deploy": $([ "$has_deploy" -gt 0 ] && echo "true" || echo "false"),
    "has_cache": $([ "$has_cache" -gt 0 ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# CONTAINERIZATION CHECK
# =============================================================================

check_containerization() {
    local codebase_path="$1"
    local score=5
    local best_practices=0
    local issues=0
    
    # Check for Dockerfile
    local dockerfiles=$(find "$codebase_path" -name "Dockerfile*" -type f 2>/dev/null)
    
    if [ -n "$dockerfiles" ]; then
        best_practices=$((best_practices + 2))
        
        for dockerfile in $dockerfiles; do
            # Check for multi-stage builds
            local stages=$(grep -c "^FROM" "$dockerfile" 2>/dev/null)
            [ "$stages" -gt 1 ] && best_practices=$((best_practices + 1))
            
            # Check for non-root user
            if grep -q "USER\|user" "$dockerfile" 2>/dev/null; then
                best_practices=$((best_practices + 1))
            else
                issues=$((issues + 1))
            fi
            
            # Check for HEALTHCHECK
            if grep -q "HEALTHCHECK" "$dockerfile" 2>/dev/null; then
                best_practices=$((best_practices + 1))
            fi
            
            # Check for specific versions (not latest)
            if grep "FROM.*:latest" "$dockerfile" 2>/dev/null; then
                issues=$((issues + 1))
            else
                best_practices=$((best_practices + 1))
            fi
            
            # Check for .dockerignore
            if [ -f "${dockerfile%/*}/.dockerignore" ] || [ -f "$codebase_path/.dockerignore" ]; then
                best_practices=$((best_practices + 1))
            else
                issues=$((issues + 1))
            fi
            
            # Check for security best practices
            # No secrets in Dockerfile
            if grep -qE "ARG.*password|ARG.*secret|ARG.*key" "$dockerfile" 2>/dev/null; then
                issues=$((issues + 1))
            fi
            
            # Check for minimal base image
            if grep -qE "FROM.*(alpine|slim|distroless)" "$dockerfile" 2>/dev/null; then
                best_practices=$((best_practices + 1))
            fi
            
            # Check for proper layer optimization
            if grep -q "RUN.*&&.*&&" "$dockerfile" 2>/dev/null; then
                best_practices=$((best_practices + 1))
            fi
        done
    fi
    
    # Check for docker-compose
    if [ -f "$codebase_path/docker-compose.yml" ] || [ -f "$codebase_path/docker-compose.yaml" ] || [ -f "$codebase_path/compose.yaml" ]; then
        best_practices=$((best_practices + 1))
        
        local compose_file=$(find "$codebase_path" -maxdepth 1 \( -name "docker-compose.yml" -o -name "docker-compose.yaml" -o -name "compose.yaml" \) | head -1)
        
        # Check for health checks in compose
        if grep -q "healthcheck:" "$compose_file" 2>/dev/null; then
            best_practices=$((best_practices + 1))
        fi
        
        # Check for resource limits
        if grep -qE "mem_limit:|cpus:|resources:" "$compose_file" 2>/dev/null; then
            best_practices=$((best_practices + 1))
        fi
        
        # Check for named volumes
        if grep -q "volumes:" "$compose_file" 2>/dev/null; then
            best_practices=$((best_practices + 1))
        fi
    fi
    
    score=$((3 + best_practices - issues))
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "has_dockerfile": $([ -n "$dockerfiles" ] && echo "true" || echo "false"),
    "best_practices": $best_practices,
    "issues": $issues,
    "has_compose": $([ -f "$codebase_path/docker-compose.yml" ] || [ -f "$codebase_path/docker-compose.yaml" ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# KUBERNETES CHECK
# =============================================================================

check_kubernetes() {
    local codebase_path="$1"
    local score=5
    local best_practices=0
    local has_k8s=false
    
    # Check for Kubernetes manifests
    local k8s_files=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
        -exec grep -l "apiVersion:\|kind:\s*Deployment\|kind:\s*Service" {} \; 2>/dev/null | wc -l)
    
    if [ "$k8s_files" -gt 0 ]; then
        has_k8s=true
        best_practices=$((best_practices + 2))
        
        # Check for resource limits
        local resource_limits=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
            -exec grep -c "resources:\|limits:\|requests:" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        [ "$resource_limits" -gt 0 ] && best_practices=$((best_practices + 1))
        
        # Check for probes
        local probes=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
            -exec grep -c "livenessProbe:\|readinessProbe:\|startupProbe:" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        [ "$probes" -gt 0 ] && best_practices=$((best_practices + 1))
        
        # Check for security contexts
        local security_context=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
            -exec grep -c "securityContext:\|runAsNonRoot:\|readOnlyRootFilesystem:" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        [ "$security_context" -gt 0 ] && best_practices=$((best_practices + 1))
        
        # Check for network policies
        local network_policies=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
            -exec grep -c "kind:\s*NetworkPolicy" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        [ "$network_policies" -gt 0 ] && best_practices=$((best_practices + 1))
        
        # Check for HPA
        local hpa=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
            -exec grep -c "kind:\s*HorizontalPodAutoscaler" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        [ "$hpa" -gt 0 ] && best_practices=$((best_practices + 1))
        
        # Check for PodDisruptionBudget
        local pdb=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
            -exec grep -c "kind:\s*PodDisruptionBudget" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        [ "$pdb" -gt 0 ] && best_practices=$((best_practices + 1))
    fi
    
    # Check for Helm charts
    if [ -d "$codebase_path/charts" ] || [ -f "$codebase_path/Chart.yaml" ]; then
        best_practices=$((best_practices + 2))
    fi
    
    # Check for Kustomize
    if find "$codebase_path" -name "kustomization.yaml" -o -name "kustomization.yml" 2>/dev/null | grep -q .; then
        best_practices=$((best_practices + 1))
    fi
    
    score=$((3 + best_practices))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "has_kubernetes": $has_k8s,
    "best_practices": $best_practices,
    "k8s_files": $k8s_files,
    "has_helm": $([ -d "$codebase_path/charts" ] && echo "true" || echo "false"),
    "has_kustomize": $(find "$codebase_path" -name "kustomization.yaml" 2>/dev/null | grep -q . && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# INFRASTRUCTURE AS CODE CHECK
# =============================================================================

check_infrastructure_as_code() {
    local codebase_path="$1"
    local score=5
    local implementations=0
    local iac_type="none"
    
    # Check for Terraform
    local tf_files=$(find "$codebase_path" -name "*.tf" -type f 2>/dev/null | wc -l)
    if [ "$tf_files" -gt 0 ]; then
        iac_type="terraform"
        implementations=$((implementations + 3))
        
        # Check for modules
        local tf_modules=$(find "$codebase_path" -type d -name "modules" 2>/dev/null | wc -l)
        [ "$tf_modules" -gt 0 ] && implementations=$((implementations + 1))
        
        # Check for state management
        if find "$codebase_path" -name "*.tf" -exec grep -l "backend\s*\"" {} \; 2>/dev/null | grep -q .; then
            implementations=$((implementations + 1))
        fi
        
        # Check for variable files
        local tf_vars=$(find "$codebase_path" -name "*.tfvars" -type f 2>/dev/null | wc -l)
        [ "$tf_vars" -gt 0 ] && implementations=$((implementations + 1))
    fi
    
    # Check for Pulumi
    if [ -f "$codebase_path/Pulumi.yaml" ]; then
        iac_type="pulumi"
        implementations=$((implementations + 3))
    fi
    
    # Check for CloudFormation
    local cf_files=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) \
        -exec grep -l "AWSTemplateFormatVersion\|AWS::CloudFormation" {} \; 2>/dev/null | wc -l)
    if [ "$cf_files" -gt 0 ]; then
        iac_type="cloudformation"
        implementations=$((implementations + 2))
    fi
    
    # Check for CDK
    if [ -f "$codebase_path/cdk.json" ]; then
        iac_type="cdk"
        implementations=$((implementations + 3))
    fi
    
    # Check for Ansible
    local ansible_files=$(find "$codebase_path" -type f \( -name "*.yml" -o -name "*.yaml" \) \
        -exec grep -l "hosts:\|tasks:\|ansible" {} \; 2>/dev/null | wc -l)
    if [ "$ansible_files" -gt 2 ]; then
        if [ "$iac_type" = "none" ]; then
            iac_type="ansible"
        fi
        implementations=$((implementations + 2))
    fi
    
    score=$((3 + implementations))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "iac_type": "$iac_type",
    "implementations": $implementations,
    "terraform_files": $tf_files,
    "cloudformation_files": ${cf_files:-0},
    "ansible_files": ${ansible_files:-0}
}
EOF
}

# =============================================================================
# DEPLOYMENT PRACTICES CHECK
# =============================================================================

check_deployment_practices() {
    local codebase_path="$1"
    local score=5
    local practices=0
    
    # Check for blue-green deployment
    local blue_green=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.tf" \) \
        -exec grep -c "blue.*green\|green.*blue\|BlueGreen" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$blue_green" -gt 0 ] && practices=$((practices + 1))
    
    # Check for canary deployment
    local canary=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
        -exec grep -c "canary\|Canary" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$canary" -gt 0 ] && practices=$((practices + 1))
    
    # Check for rolling deployment
    local rolling=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
        -exec grep -c "rollingUpdate\|RollingUpdate" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$rolling" -gt 0 ] && practices=$((practices + 1))
    
    # Check for feature flags
    local feature_flags=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        -exec grep -c "featureFlag\|feature_flag\|launchdarkly\|unleash\|flagsmith" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$feature_flags" -gt 0 ] && practices=$((practices + 2))
    
    # Check for database migrations
    local migrations=$(find "$codebase_path" -type d -name "migrations" 2>/dev/null | wc -l)
    local migration_files=$(find "$codebase_path" -type f -name "*migration*" 2>/dev/null | wc -l)
    [ "$migrations" -gt 0 ] || [ "$migration_files" -gt 0 ] && practices=$((practices + 1))
    
    # Check for rollback capability
    local rollback=$(find "$codebase_path" -type f \
        -exec grep -c "rollback\|Rollback\|revert\|downgrade" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$rollback" -gt 0 ] && practices=$((practices + 1))
    
    # Check for semantic versioning
    local semver=$(find "$codebase_path" -maxdepth 2 -type f \( -name "package.json" -o -name "setup.py" -o -name "Cargo.toml" \) \
        -exec grep -c '"version":\|version\s*=' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$semver" -gt 0 ] && practices=$((practices + 1))
    
    # Check for changelog
    if [ -f "$codebase_path/CHANGELOG.md" ] || [ -f "$codebase_path/CHANGELOG" ] || [ -f "$codebase_path/HISTORY.md" ]; then
        practices=$((practices + 1))
    fi
    
    score=$((4 + practices))
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": $score,
    "practices": $practices,
    "blue_green": $([ "$blue_green" -gt 0 ] && echo "true" || echo "false"),
    "canary": $([ "$canary" -gt 0 ] && echo "true" || echo "false"),
    "rolling": $([ "$rolling" -gt 0 ] && echo "true" || echo "false"),
    "feature_flags": $([ "$feature_flags" -gt 0 ] && echo "true" || echo "false"),
    "has_migrations": $([ "$migrations" -gt 0 ] && echo "true" || echo "false"),
    "has_changelog": $([ -f "$codebase_path/CHANGELOG.md" ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# ENVIRONMENT MANAGEMENT CHECK
# =============================================================================

check_environment_management() {
    local codebase_path="$1"
    local practices=0
    
    # Check for environment-specific configs
    local env_configs=0
    
    # Check for .env files
    local env_files=$(find "$codebase_path" -maxdepth 2 -name ".env*" -type f 2>/dev/null | wc -l)
    [ "$env_files" -gt 1 ] && practices=$((practices + 1))
    
    # Check for .env.example
    if [ -f "$codebase_path/.env.example" ] || [ -f "$codebase_path/.env.sample" ]; then
        practices=$((practices + 1))
    fi
    
    # Check for config per environment
    local env_specific=$(find "$codebase_path" -type f \( \
        -name "*production*" -o -name "*staging*" -o -name "*development*" -o \
        -name "*.prod.*" -o -name "*.dev.*" -o -name "*.stage.*" \) 2>/dev/null | wc -l)
    [ "$env_specific" -gt 2 ] && practices=$((practices + 1))
    
    # Check for secrets management
    local secrets_mgmt=$(find "$codebase_path" -type f \
        -exec grep -c "vault\|VAULT\|aws.*secrets\|parameter.*store\|doppler\|1password" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$secrets_mgmt" -gt 0 ] && practices=$((practices + 2))
    
    # Check for config validation
    local config_validation=$(find "$codebase_path" -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" \
        -exec grep -c "env.*require\|config.*validate\|required.*env\|convict\|dotenv-safe" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$config_validation" -gt 0 ] && practices=$((practices + 1))
    
    cat << EOF
{
    "practices": $practices,
    "env_files": $env_files,
    "has_example_env": $([ -f "$codebase_path/.env.example" ] && echo "true" || echo "false"),
    "secrets_management": $([ "$secrets_mgmt" -gt 0 ] && echo "true" || echo "false"),
    "config_validation": $([ "$config_validation" -gt 0 ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# GITOPS CHECK
# =============================================================================

check_gitops() {
    local codebase_path="$1"
    local implementations=0
    
    # Check for ArgoCD
    local argocd=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
        -exec grep -c "argocd\|ArgoCD\|argoproj.io" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$argocd" -gt 0 ] && implementations=$((implementations + 2))
    
    # Check for Flux
    local flux=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
        -exec grep -c "fluxcd\|flux-system\|toolkit.fluxcd.io" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$flux" -gt 0 ] && implementations=$((implementations + 2))
    
    # Check for declarative configuration
    local declarative=$(find "$codebase_path" -type d \( -name "manifests" -o -name "k8s" -o -name "kubernetes" -o -name "deploy" \) 2>/dev/null | wc -l)
    [ "$declarative" -gt 0 ] && implementations=$((implementations + 1))
    
    # Check for environment overlays
    local overlays=$(find "$codebase_path" -type d -name "overlays" 2>/dev/null | wc -l)
    [ "$overlays" -gt 0 ] && implementations=$((implementations + 1))
    
    # Check for sealed secrets
    local sealed_secrets=$(find "$codebase_path" -type f \( -name "*.yaml" -o -name "*.yml" \) \
        -exec grep -c "SealedSecret\|bitnami.com/sealed-secrets" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$sealed_secrets" -gt 0 ] && implementations=$((implementations + 1))
    
    cat << EOF
{
    "implementations": $implementations,
    "argocd": $([ "$argocd" -gt 0 ] && echo "true" || echo "false"),
    "flux": $([ "$flux" -gt 0 ] && echo "true" || echo "false"),
    "declarative_config": $([ "$declarative" -gt 0 ] && echo "true" || echo "false"),
    "environment_overlays": $([ "$overlays" -gt 0 ] && echo "true" || echo "false")
}
EOF
}

# =============================================================================
# BUILD OPTIMIZATION CHECK
# =============================================================================

check_build_optimization() {
    local codebase_path="$1"
    local optimizations=0
    
    # Check for build caching
    if [ -f "$codebase_path/package.json" ]; then
        # Check for turbo/nx
        if grep -qE '"turbo"|"nx"|"lerna"' "$codebase_path/package.json" 2>/dev/null; then
            optimizations=$((optimizations + 2))
        fi
    fi
    
    # Check for CI caching
    if [ -d "$codebase_path/.github/workflows" ]; then
        local ci_cache=$(grep -r "actions/cache\|cache:" "$codebase_path/.github/workflows" 2>/dev/null | wc -l)
        [ "$ci_cache" -gt 0 ] && optimizations=$((optimizations + 1))
    fi
    
    # Check for Docker layer caching
    local docker_cache=$(find "$codebase_path" -name "Dockerfile*" \
        -exec grep -c "COPY.*package.*json\|--mount=type=cache" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$docker_cache" -gt 0 ] && optimizations=$((optimizations + 1))
    
    # Check for incremental builds
    local incremental=$(find "$codebase_path" -type f \
        -exec grep -c "incremental\|--incremental\|tsBuildInfoFile" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    [ "$incremental" -gt 0 ] && optimizations=$((optimizations + 1))
    
    cat << EOF
{
    "optimizations": $optimizations,
    "monorepo_tools": $(grep -qE '"turbo"|"nx"' "$codebase_path/package.json" 2>/dev/null && echo "true" || echo "false"),
    "ci_caching": $([ "${ci_cache:-0}" -gt 0 ] && echo "true" || echo "false"),
    "docker_layer_cache": $([ "$docker_cache" -gt 0 ] && echo "true" || echo "false")
}
EOF
}
