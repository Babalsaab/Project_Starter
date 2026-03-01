#!/bin/bash

# =============================================================================
# ENHANCED SECURITY ANALYZER
# =============================================================================
# Advanced security scanning with pattern-based detection
# Supports: JavaScript/TypeScript, Python, Go, Java, Ruby, PHP, Rust, C#
# =============================================================================

# Security patterns defined as functions for compatibility
get_injection_pattern() {
    local lang="$1"
    case "$lang" in
        js) echo 'execute.*\$\{|query.*\+.*req\.|\.query\([^)]*\$|raw\s*\(.*\+|exec\s*\(.*\+' ;;
        python) echo 'execute.*%s|cursor\.execute.*\+|\.format\(.*user|f".*SELECT.*{|raw\s*\(.*\+' ;;
        java) echo 'executeQuery.*\+|PreparedStatement.*\+.*getParameter|createQuery.*\+' ;;
        go) echo 'Exec.*\+|Query.*fmt\.Sprintf|db\.Raw.*\+' ;;
        ruby) echo 'where.*#{|find_by_sql.*#|execute.*#{|\.order\(.*params' ;;
        php) echo '\$_GET|\$_POST|\$_REQUEST.*mysql_query|mysqli_query.*\$_|query.*\.\s*\$' ;;
        *) echo '' ;;
    esac
}

get_xss_pattern() {
    local lang="$1"
    case "$lang" in
        js) echo 'innerHTML\s*=|document\.write\s*\(|\.html\s*\([^)]*\$|dangerouslySetInnerHTML|v-html\s*=' ;;
        python) echo 'mark_safe\s*\(|Markup\s*\(.*request|\|safe|render_template_string.*request' ;;
        java) echo '\.setContentType.*text/html.*getParameter|out\.print.*getParameter|response\.getWriter.*getParameter' ;;
        php) echo 'echo\s*\$_GET|echo\s*\$_POST|print\s*\$_REQUEST' ;;
        ruby) echo 'raw\s*params|\.html_safe.*params' ;;
        *) echo '' ;;
    esac
}

# =============================================================================
# MAIN SECURITY ANALYSIS
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/search-utils.sh" ]; then
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/search-utils.sh"
fi

has_code_match() {
    local pattern="$1"
    local path="$2"
    shift 2
    if type grep_code_quiet >/dev/null 2>&1; then
        grep_code_quiet "$pattern" "$path" "$@"
    else
        grep -R -n -E -q "$@" "$pattern" "$path" 2>/dev/null
    fi
}

count_matches() {
    local pattern="$1"
    local path="$2"
    shift 2
    if type grep_code_count >/dev/null 2>&1; then
        grep_code_count "$pattern" "$path" "$@"
    else
        { grep -R -n -E "$@" "$pattern" "$path" 2>/dev/null || true; } | wc -l | tr -d ' '
    fi
}

count_files() {
    local pattern="$1"
    local path="$2"
    shift 2
    if type grep_code >/dev/null 2>&1; then
        { grep_code "$pattern" "$path" -l "$@" || true; } | wc -l | tr -d ' '
    else
        { grep -R -n -E -l "$@" "$pattern" "$path" 2>/dev/null || true; } | wc -l | tr -d ' '
    fi
}

list_files_with_match() {
    local pattern="$1"
    local path="$2"
    shift 2
    if type grep_code >/dev/null 2>&1; then
        grep_code "$pattern" "$path" -l "$@"
    else
        grep -R -n -E -l "$@" "$pattern" "$path" 2>/dev/null
    fi
}

analyze_security() {
    local codebase_path="$1"
    local output_dir="${2:-${TMPDIR:-/tmp}/security-analysis}"
    
    mkdir -p "$output_dir"
    
    local total_score=0
    local checks_performed=0
    local critical_issues=0
    local high_issues=0
    local medium_issues=0
    local low_issues=0
    
    # Run all security checks
    local injection_result=$(check_injection_vulnerabilities "$codebase_path")
    local xss_result=$(check_xss_vulnerabilities "$codebase_path")
    local auth_result=$(check_authentication_issues "$codebase_path")
    local crypto_result=$(check_cryptography_issues "$codebase_path")
    local secrets_result=$(check_secrets_exposure "$codebase_path")
    local deps_result=$(check_dependency_vulnerabilities "$codebase_path")
    local config_result=$(check_security_misconfig "$codebase_path")
    local headers_result=$(check_security_headers "$codebase_path")
    
    # Calculate totals
    critical_issues=$(echo "$injection_result $xss_result $auth_result $crypto_result $secrets_result" | \
        jq -s 'map(.critical_count // 0) | add')
    high_issues=$(echo "$injection_result $xss_result $auth_result $crypto_result $secrets_result" | \
        jq -s 'map(.high_count // 0) | add')
    medium_issues=$(echo "$injection_result $xss_result $auth_result $crypto_result $secrets_result $deps_result $config_result" | \
        jq -s 'map(.medium_count // 0) | add')
    low_issues=$(echo "$injection_result $xss_result $auth_result $crypto_result $secrets_result $deps_result $config_result $headers_result" | \
        jq -s 'map(.low_count // 0) | add')
    
    # Calculate overall security score
    local base_score=10
    base_score=$((base_score - critical_issues * 3))
    base_score=$((base_score - high_issues * 2))
    base_score=$((base_score - medium_issues))
    base_score=$((base_score - low_issues / 2))
    
    [ "$base_score" -lt 1 ] && base_score=1
    [ "$base_score" -gt 10 ] && base_score=10
    
    # Output comprehensive results
    cat << EOF
{
    "overall_score": $base_score,
    "critical_issues": $critical_issues,
    "high_issues": $high_issues,
    "medium_issues": $medium_issues,
    "low_issues": $low_issues,
    "injection_analysis": $injection_result,
    "xss_analysis": $xss_result,
    "auth_analysis": $auth_result,
    "crypto_analysis": $crypto_result,
    "secrets_analysis": $secrets_result,
    "dependency_analysis": $deps_result,
    "config_analysis": $config_result,
    "headers_analysis": $headers_result
}
EOF
}

# =============================================================================
# INJECTION VULNERABILITY CHECK
# =============================================================================

check_injection_vulnerabilities() {
    local codebase_path="$1"
    local critical_count=0
    local high_count=0
    local findings='[]'
    
    # Check for SQL injection in different languages
    for lang in js python java go ruby php; do
        local pattern=$(get_injection_pattern "$lang")
        [ -z "$pattern" ] && continue
        
        local extensions=""
        case $lang in
            js) extensions="*.js *.ts *.jsx *.tsx" ;;
            python) extensions="*.py" ;;
            java) extensions="*.java" ;;
            go) extensions="*.go" ;;
            ruby) extensions="*.rb" ;;
            php) extensions="*.php" ;;
        esac
        
        for ext in $extensions; do
            local matches=$(list_files_with_match "$pattern" "$codebase_path" --include="$ext" | head -20)
            
            for file in $matches; do
                critical_count=$((critical_count + 1))
                local relative_path="${file#$codebase_path/}"
                findings=$(echo "$findings" | jq --arg f "$relative_path" --arg t "sql_injection" \
                    '. + [{"file": $f, "type": $t, "severity": "critical"}]')
            done
        done
    done
    
    # Check for command injection
    local cmd_injection_patterns='exec\s*\(|system\s*\(|eval\s*\(|spawn\s*\(|popen\s*\(|subprocess\.call.*shell.*True|os\.system\s*\('
    local cmd_matches=$(list_files_with_match "$cmd_injection_patterns" "$codebase_path" \
        --include=*.js --include=*.py --include=*.rb --include=*.php | head -10)
    
    for file in $cmd_matches; do
        # Check if user input is passed
        if grep -qE '(req\.|request\.|params\.|args\.|argv)' "$file" 2>/dev/null; then
            critical_count=$((critical_count + 1))
        fi
    done
    
    # Check for NoSQL injection
    local nosql_patterns='\$where|\$regex.*\$options|find\s*\(.*\$|\$ne|\$gt|\$lt.*user'
    local nosql_matches=$(count_files "$nosql_patterns" "$codebase_path" --include=*.js)
    
    high_count=$((high_count + nosql_matches))
    
    cat << EOF
{
    "critical_count": $critical_count,
    "high_count": $high_count,
    "findings": $findings
}
EOF
}

# =============================================================================
# XSS VULNERABILITY CHECK
# =============================================================================

check_xss_vulnerabilities() {
    local codebase_path="$1"
    local critical_count=0
    local high_count=0
    local medium_count=0
    local findings='[]'
    
    # Check React dangerouslySetInnerHTML
    local react_dangerous=$(count_files "dangerouslySetInnerHTML" "$codebase_path" --include=*.jsx --include=*.tsx)
    
    # Check if sanitized
    if [ "$react_dangerous" -gt 0 ]; then
        local sanitized=$(count_files "DOMPurify|sanitize-html|xss-filters" "$codebase_path" --include=*.jsx --include=*.tsx)
        
        if [ "$sanitized" -eq 0 ]; then
            high_count=$((high_count + react_dangerous))
        fi
    fi
    
    # Check innerHTML usage
    local innerHTML_count=$(count_matches "innerHTML\\s*=" "$codebase_path" --include=*.js --include=*.ts)
    
    high_count=$((high_count + innerHTML_count / 5))
    
    # Check Vue v-html
    local vue_vhtml=$(count_matches "v-html" "$codebase_path" --include=*.vue)
    
    medium_count=$((medium_count + vue_vhtml))
    
    # Check for template injection
    local template_injection=$(count_files "render_template_string.*request" "$codebase_path" --include=*.py)
    
    critical_count=$((critical_count + template_injection))
    
    # Check Angular bypassSecurityTrust
    local angular_bypass=$(count_matches "bypassSecurityTrust" "$codebase_path" --include=*.ts)
    
    high_count=$((high_count + angular_bypass))
    
    cat << EOF
{
    "critical_count": $critical_count,
    "high_count": $high_count,
    "medium_count": $medium_count,
    "findings": $findings
}
EOF
}

# =============================================================================
# AUTHENTICATION ISSUES CHECK
# =============================================================================

check_authentication_issues() {
    local codebase_path="$1"
    local critical_count=0
    local high_count=0
    local medium_count=0
    local findings='[]'
    
    # Check for hardcoded credentials
    local hardcoded=$(list_files_with_match 'password\s*[:=]\s*["'\''][^"'\'']{4,}["'\'']' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py --include=*.java --include=*.go \
        --exclude=*test* --exclude=*spec* --exclude=*mock* | head -10)
    
    for file in $hardcoded; do
        # Exclude test/example files
        if ! echo "$file" | grep -qiE '(test|spec|example|sample|mock|fixture)'; then
            critical_count=$((critical_count + 1))
            local relative_path="${file#$codebase_path/}"
            findings=$(echo "$findings" | jq --arg f "$relative_path" \
                '. + [{"file": $f, "type": "hardcoded_credentials", "severity": "critical"}]')
        fi
    done
    
    # Check JWT configuration
    local jwt_issues=0
    
    # JWT with no algorithm verification
    if has_code_match 'algorithms.*\[.*none|verify.*false' "$codebase_path" --include=*.js --include=*.ts; then
        critical_count=$((critical_count + 1))
        jwt_issues=$((jwt_issues + 1))
    fi
    
    # Check for weak session configuration
    local session_issues=$(count_matches 'httpOnly:\s*false|secure:\s*false' "$codebase_path" --include=*.js --include=*.ts)
    
    high_count=$((high_count + session_issues))
    
    # Check for missing CSRF protection
    local has_csrf=$(count_files 'csrf|csurf|csrftoken|xsrf' "$codebase_path" --include=*.js --include=*.ts --include=*.py)
    
    # Check if it's a web app that needs CSRF
    local is_web_app=$(count_files 'express|django|flask|rails|laravel' "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.rb --include=*.php)
    
    if [ "$is_web_app" -gt 0 ] && [ "$has_csrf" -eq 0 ]; then
        medium_count=$((medium_count + 1))
    fi
    
    # Check for insecure password hashing
    local weak_hashing=$(count_files 'md5.*password|sha1.*password|createHash.*md5.*password' "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.java)
    
    critical_count=$((critical_count + weak_hashing))
    
    cat << EOF
{
    "critical_count": $critical_count,
    "high_count": $high_count,
    "medium_count": $medium_count,
    "jwt_issues": $jwt_issues,
    "findings": $findings
}
EOF
}

# =============================================================================
# CRYPTOGRAPHY ISSUES CHECK
# =============================================================================

check_cryptography_issues() {
    local codebase_path="$1"
    local critical_count=0
    local high_count=0
    local medium_count=0
    
    # Check for weak algorithms
    local weak_algos=$(count_matches 'DES[^3]|RC4|MD5|SHA1[^0-9]' "$codebase_path" --include=*.js --include=*.ts --include=*.py --include=*.java --include=*.go)
    
    high_count=$((high_count + weak_algos / 3))
    
    # Check for insecure random
    local insecure_random=$(count_matches "Math\\.random" "$codebase_path" --include=*.js --include=*.ts)
    
    # Check if used for security purposes
    local security_random_context=$(count_files 'Math\\.random.*(token|key|secret|id|uuid|password)' "$codebase_path" --include=*.js --include=*.ts)
    
    critical_count=$((critical_count + security_random_context))
    
    # Check Python insecure random
    local python_random=$(count_matches "random\\." "$codebase_path" --include=*.py)
    
    # Check if secrets module is used instead
    local python_secrets=$(count_matches "secrets\\." "$codebase_path" --include=*.py)
    
    if [ "$python_random" -gt 0 ] && [ "$python_secrets" -eq 0 ]; then
        medium_count=$((medium_count + 1))
    fi
    
    # Check for hardcoded encryption keys
    local hardcoded_keys=$(count_files '(encryption|aes|secret).*key\s*[:=]\s*["'\''][A-Za-z0-9+/=]{16,}["'\'']' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py --include=*.java --exclude=*test*)
    
    critical_count=$((critical_count + hardcoded_keys))
    
    cat << EOF
{
    "critical_count": $critical_count,
    "high_count": $high_count,
    "medium_count": $medium_count
}
EOF
}

# =============================================================================
# SECRETS EXPOSURE CHECK
# =============================================================================

check_secrets_exposure() {
    local codebase_path="$1"
    local critical_count=0
    local high_count=0
    local findings='[]'
    
    # Common secret patterns
    local secret_patterns=(
        'AKIA[0-9A-Z]{16}'  # AWS Access Key
        'sk_live_[0-9a-zA-Z]{24}'  # Stripe Live Key
        'sk_test_[0-9a-zA-Z]{24}'  # Stripe Test Key
        'ghp_[0-9a-zA-Z]{36}'  # GitHub Personal Access Token
        'gho_[0-9a-zA-Z]{36}'  # GitHub OAuth Token
        'github_pat_[0-9a-zA-Z_]{40,}'  # GitHub Fine-grained PAT
        'xox[baprs]-[0-9a-zA-Z-]+'  # Slack Token
        'eyJ[A-Za-z0-9-_]*\.eyJ[A-Za-z0-9-_]*\.[A-Za-z0-9-_]*'  # JWT Token
        'AIza[0-9A-Za-z\\-_]{35}'  # Google API Key
        'ya29\\.[0-9A-Za-z\\-_]+'  # Google OAuth Token
        'pk_live_[0-9a-zA-Z]{24}'  # Stripe Publishable Key
        'rk_live_[0-9a-zA-Z]{24}'  # Stripe Restricted Key
    )
    
    for pattern in "${secret_patterns[@]}"; do
        local matches=$(list_files_with_match "$pattern" "$codebase_path" \
            --include=*.js --include=*.ts --include=*.py --include=*.java --include=*.go \
            --include=*.rb --include=*.php --include=*.env* --include=*.json --include=*.yaml --include=*.yml \
            --exclude=*.example --exclude=*.sample | head -5)
        
        for file in $matches; do
            critical_count=$((critical_count + 1))
            local relative_path="${file#$codebase_path/}"
            findings=$(echo "$findings" | jq --arg f "$relative_path" \
                '. + [{"file": $f, "type": "exposed_secret", "severity": "critical"}]')
        done
    done
    
    # Check for .env files in source control
    local env_files=$(find "$codebase_path" -name ".env" -o -name ".env.local" -o -name ".env.production" 2>/dev/null \
        | grep -vE '/(node_modules|vendor|dist|build|\.git|\.venv|venv|coverage|output|\.cto-evaluation)/' | head -10)
    for env_file in $env_files; do
        # Check if it's tracked by git
        if [ -d "$codebase_path/.git" ]; then
            if git -C "$codebase_path" ls-files --error-unmatch "$env_file" 2>/dev/null; then
                critical_count=$((critical_count + 1))
                local relative_path="${env_file#$codebase_path/}"
                findings=$(echo "$findings" | jq --arg f "$relative_path" \
                    '. + [{"file": $f, "type": "env_in_git", "severity": "critical"}]')
            fi
        fi
    done
    
    # Check .gitignore for env files
    if [ -f "$codebase_path/.gitignore" ]; then
        if ! grep -qE '\.env|\.env\*' "$codebase_path/.gitignore" 2>/dev/null; then
            high_count=$((high_count + 1))
        fi
    fi
    
    # Check for secrets in logs
    local logged_secrets=$(count_matches 'console\.log.*password|print.*password|logger\.(info|debug|error).*password' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py)
    
    high_count=$((high_count + logged_secrets))
    
    cat << EOF
{
    "critical_count": $critical_count,
    "high_count": $high_count,
    "findings": $findings
}
EOF
}

# =============================================================================
# DEPENDENCY VULNERABILITY CHECK
# =============================================================================

check_dependency_vulnerabilities() {
    local codebase_path="$1"
    local medium_count=0
    local low_count=0
    local outdated_count=0
    
    # Check if lockfiles exist (indicates dependency management)
    local has_lockfile=false
    [ -f "$codebase_path/package-lock.json" ] && has_lockfile=true
    [ -f "$codebase_path/yarn.lock" ] && has_lockfile=true
    [ -f "$codebase_path/pnpm-lock.yaml" ] && has_lockfile=true
    [ -f "$codebase_path/Pipfile.lock" ] && has_lockfile=true
    [ -f "$codebase_path/poetry.lock" ] && has_lockfile=true
    [ -f "$codebase_path/Gemfile.lock" ] && has_lockfile=true
    [ -f "$codebase_path/go.sum" ] && has_lockfile=true
    
    if ! $has_lockfile; then
        medium_count=$((medium_count + 1))
    fi
    
    # Check for npm audit configuration
    if [ -f "$codebase_path/package.json" ]; then
        # Check for audit in CI
        local has_audit_ci=false
        if [ -d "$codebase_path/.github/workflows" ]; then
            if has_code_match "npm audit\|yarn audit\|pnpm audit" "$codebase_path/.github/workflows"; then
                has_audit_ci=true
            fi
        fi
        
        if ! $has_audit_ci; then
            low_count=$((low_count + 1))
        fi
        
        # Check for security scanning tools
        local has_security_scanning=false
        if grep -qE '"snyk"|"npm-audit"|"audit-ci"|"better-npm-audit"' "$codebase_path/package.json" 2>/dev/null; then
            has_security_scanning=true
        fi
    fi
    
    # Check Python requirements
    if [ -f "$codebase_path/requirements.txt" ]; then
        # Check for pinned versions
        local unpinned=$(grep -cvE '==|>=' "$codebase_path/requirements.txt" 2>/dev/null || echo 0)
        if [ "$unpinned" -gt 5 ]; then
            low_count=$((low_count + 1))
        fi
        
        # Check for safety configuration
        if [ -d "$codebase_path/.github/workflows" ]; then
            if ! has_code_match "safety check\|pip-audit\|snyk" "$codebase_path/.github/workflows"; then
                low_count=$((low_count + 1))
            fi
        fi
    fi
    
    # Check for Dependabot/Renovate
    local has_dep_updates=false
    [ -f "$codebase_path/.github/dependabot.yml" ] && has_dep_updates=true
    [ -f "$codebase_path/.github/dependabot.yaml" ] && has_dep_updates=true
    [ -f "$codebase_path/renovate.json" ] && has_dep_updates=true
    [ -f "$codebase_path/.renovaterc" ] && has_dep_updates=true
    
    if ! $has_dep_updates; then
        low_count=$((low_count + 1))
    fi
    
    cat << EOF
{
    "medium_count": $medium_count,
    "low_count": $low_count,
    "has_lockfile": $has_lockfile,
    "has_dep_updates": $has_dep_updates
}
EOF
}

# =============================================================================
# SECURITY MISCONFIGURATION CHECK
# =============================================================================

check_security_misconfig() {
    local codebase_path="$1"
    local medium_count=0
    local low_count=0
    
    # Check for debug mode in production configs
    local debug_enabled=$(count_matches 'DEBUG\s*[:=]\s*(true|True|1)|debug:\s*true' "$codebase_path" \
        --include=*.py --include=*.js --include=*.ts --include=*.json --include=*.yaml --include=*.yml \
        --exclude=*test* --exclude=*dev* --exclude=*development*)
    
    medium_count=$((medium_count + debug_enabled / 2))
    
    # Check for CORS misconfiguration
    local cors_wildcard=$(count_matches 'Access-Control-Allow-Origin.*\*|cors\(\)|origin:\s*true|allow_origins.*\*' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py)
    
    medium_count=$((medium_count + cors_wildcard))
    
    # Check for exposed error details
    local exposed_errors=$(count_matches 'stack.*response|error\\.stack.*res\\.' "$codebase_path" --include=*.js --include=*.ts)
    
    medium_count=$((medium_count + exposed_errors))
    
    # Check for missing rate limiting
    local has_rate_limit=false
    if has_code_match 'rate-limit|ratelimit|throttle|express-rate-limit|slowapi' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py; then
        has_rate_limit=true
    fi
    
    if ! $has_rate_limit; then
        low_count=$((low_count + 1))
    fi
    
    # Check for missing input validation
    local has_validation=false
    if has_code_match 'joi|yup|zod|class-validator|express-validator|ajv' "$codebase_path" \
        --include=*.js --include=*.ts; then
        has_validation=true
    fi
    
    if [ -f "$codebase_path/package.json" ] && ! $has_validation; then
        low_count=$((low_count + 1))
    fi
    
    cat << EOF
{
    "medium_count": $medium_count,
    "low_count": $low_count,
    "has_rate_limit": $has_rate_limit,
    "has_validation": $has_validation
}
EOF
}

# =============================================================================
# SECURITY HEADERS CHECK
# =============================================================================

check_security_headers() {
    local codebase_path="$1"
    local low_count=0
    local headers_found=0
    
    # Check for helmet (Node.js)
    if [ -f "$codebase_path/package.json" ]; then
        if grep -q '"helmet"' "$codebase_path/package.json" 2>/dev/null; then
            headers_found=$((headers_found + 1))
        else
            low_count=$((low_count + 1))
        fi
    fi
    
    # Check for security headers middleware
    local has_csp=$(count_files 'Content-Security-Policy|contentSecurityPolicy' "$codebase_path" --include=*.js --include=*.ts)
    
    local has_hsts=$(count_files 'Strict-Transport-Security|hsts' "$codebase_path" --include=*.js --include=*.ts)
    
    local has_xframe=$(count_files 'X-Frame-Options|frameguard' "$codebase_path" --include=*.js --include=*.ts)
    
    [ "$has_csp" -gt 0 ] && headers_found=$((headers_found + 1))
    [ "$has_hsts" -gt 0 ] && headers_found=$((headers_found + 1))
    [ "$has_xframe" -gt 0 ] && headers_found=$((headers_found + 1))
    
    # Python Django security middleware
    if [ -f "$codebase_path/settings.py" ] || find "$codebase_path" -name "settings.py" 2>/dev/null | grep -q .; then
        if ! has_code_match "SecurityMiddleware" "$codebase_path" --include=settings.py; then
            low_count=$((low_count + 1))
        else
            headers_found=$((headers_found + 1))
        fi
    fi
    
    cat << EOF
{
    "low_count": $low_count,
    "headers_found": $headers_found
}
EOF
}

# =============================================================================
# OWASP TOP 10 COMPLIANCE CHECK
# =============================================================================

check_owasp_compliance() {
    local codebase_path="$1"
    
    local compliance_score=0
    local total_checks=10
    
    # A01: Broken Access Control
    local has_auth_middleware=$(count_files 'isAuthenticated|requireAuth|@login_required|@jwt_required|auth.*middleware' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py)
    [ "$has_auth_middleware" -gt 0 ] && compliance_score=$((compliance_score + 1))
    
    # A02: Cryptographic Failures - checked in crypto analysis
    local has_modern_crypto=$(count_files 'AES-256|SHA-256|SHA-384|SHA-512|bcrypt|argon2|scrypt' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py --include=*.go --include=*.java)
    [ "$has_modern_crypto" -gt 0 ] && compliance_score=$((compliance_score + 1))
    
    # A03: Injection - checked in injection analysis
    local has_parameterized=$(count_files 'PreparedStatement|\$[0-9]+|:\w+|%s.*execute' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py)
    [ "$has_parameterized" -gt 0 ] && compliance_score=$((compliance_score + 1))
    
    # A04: Insecure Design
    local has_threat_model=$(count_files "threat|security|risk" "$codebase_path" -i --include=*.md)
    [ "$has_threat_model" -gt 0 ] && compliance_score=$((compliance_score + 1))
    
    # A05: Security Misconfiguration - checked in misconfig analysis
    local has_env_separation=$(find "$codebase_path" -type f -name "*.env.*" 2>/dev/null \
        | grep -vE '/(node_modules|vendor|dist|build|\.git|\.venv|venv|coverage|output|\.cto-evaluation)/' | wc -l)
    [ "$has_env_separation" -gt 2 ] && compliance_score=$((compliance_score + 1))
    
    # A06: Vulnerable Components - checked in dependency analysis
    local has_audit_tools=$(count_files 'npm audit|safety check|snyk|dependabot' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py --include=*.yaml --include=*.yml --include=*.json)
    [ "$has_audit_tools" -gt 0 ] && compliance_score=$((compliance_score + 1))
    
    # A07: Auth Failures - checked in auth analysis
    local has_mfa=$(count_files '2fa|totp|mfa|two-factor|authenticator' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py --include=*.go)
    [ "$has_mfa" -gt 0 ] && compliance_score=$((compliance_score + 1))
    
    # A08: Software Integrity
    local has_integrity_check=$(count_files 'checksum|integrity|sri|subresource' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.json --include=*.yaml --include=*.yml)
    [ "$has_integrity_check" -gt 0 ] && compliance_score=$((compliance_score + 1))
    
    # A09: Security Logging
    local has_security_logging=$(count_files 'audit.*log|security.*log|login.*attempt|failed.*auth' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py)
    [ "$has_security_logging" -gt 0 ] && compliance_score=$((compliance_score + 1))
    
    # A10: SSRF
    local has_url_validation=$(count_files 'url.*validate|whitelist.*url|allowlist.*domain' "$codebase_path" \
        --include=*.js --include=*.ts --include=*.py)
    [ "$has_url_validation" -gt 0 ] && compliance_score=$((compliance_score + 1))
    
    local owasp_percentage=$((compliance_score * 100 / total_checks))
    
    cat << EOF
{
    "compliance_score": $compliance_score,
    "total_checks": $total_checks,
    "percentage": $owasp_percentage
}
EOF
}
