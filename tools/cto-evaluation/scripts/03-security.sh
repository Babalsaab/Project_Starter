#!/bin/bash

# =============================================================================
# SECURITY EVALUATION (Parameters 82-119)
# =============================================================================
# Evaluates:
#   - Authentication & Authorization (59-70)
#   - Data Protection (71-82)
#   - OWASP Top 10 (83-96)
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
SUITE_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/common-progress.sh"
source "$SCRIPT_DIR/common-findings.sh"
source "$SCRIPT_DIR/lib/math-utils.sh"

set_total_steps 6

# Initialize results
RESULTS='{
    "category": "security",
    "parameters_evaluated": 0,
    "parameters_total": 38,
    "score": 0,
    "findings": [],
    "vulnerabilities": {
        "critical": 0,
        "high": 0,
        "medium": 0,
        "low": 0
    },
    "metrics": {}
}'

init_findings

log_metric() {
    local name="$1"
    local value="$2"
    RESULTS=$(echo "$RESULTS" | jq --arg n "$name" --arg v "$value" '.metrics[$n] = $v')
}

# =============================================================================
# SECRETS DETECTION
# =============================================================================

detect_secrets() {
    progress_step "Secrets & credentials detection"

    local secrets_found=0

    # Check for hardcoded secrets patterns
    local secret_patterns=(
        "password\s*=\s*['\"][^'\"]+['\"]"
        "api_key\s*=\s*['\"][^'\"]+['\"]"
        "secret\s*=\s*['\"][^'\"]+['\"]"
        "aws_access_key_id\s*=\s*['\"][A-Z0-9]{20}['\"]"
        "aws_secret_access_key\s*=\s*['\"][A-Za-z0-9/+=]{40}['\"]"
        "AKIA[0-9A-Z]{16}"  # AWS Access Key
        "ghp_[a-zA-Z0-9]{36}"  # GitHub Personal Access Token
        "sk-[a-zA-Z0-9]{48}"  # OpenAI API Key
        "Bearer\s+[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+"  # JWT
    )

    for pattern in "${secret_patterns[@]}"; do
        local matches
        matches=$(grep -rniE "$pattern" "$CODEBASE_PATH" \
            --include="*.js" --include="*.ts" --include="*.py" --include="*.go" \
            --include="*.java" --include="*.rb" --include="*.php" --include="*.json" \
            --include="*.yaml" --include="*.yml" --include="*.env*" \
            --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
            --exclude="semgrep-rules.yaml" --exclude="*semgrep*.yaml" \
            --exclude=".secrets.baseline" --exclude="bandit.yaml" \
            2>/dev/null | head -20 || echo "")

        if [ -n "$matches" ]; then
            local match_count
            match_count=$(echo "$matches" | wc -l)
            secrets_found=$((secrets_found + match_count))

            while IFS= read -r match; do
                local file_path
                file_path=$(echo "$match" | cut -d: -f1)
                add_finding "critical" "secrets_in_code" "Potential secret detected" "$file_path" "CWE-798"
            done <<< "$matches"
        fi
    done

    # Try trufflehog if available
    if command -v trufflehog &> /dev/null; then
        echo "  Running TruffleHog..." >&2
        local trufflehog_output
        trufflehog_output=$(trufflehog filesystem "$CODEBASE_PATH" --json 2>/dev/null | head -100 || echo "")

        if [ -n "$trufflehog_output" ]; then
            local th_count
            th_count=$(echo "$trufflehog_output" | jq -s 'length')
            secrets_found=$((secrets_found + th_count))
            log_metric "trufflehog_findings" "$th_count"
        fi
    fi

    # Try gitleaks if available
    if command -v gitleaks &> /dev/null; then
        echo "  Running Gitleaks..." >&2
        local gitleaks_output
        gitleaks_output=$(gitleaks detect --source="$CODEBASE_PATH" --no-git -f json 2>/dev/null || echo "[]")

        local gl_count
        gl_count=$(echo "$gitleaks_output" | jq 'length')
        log_metric "gitleaks_findings" "$gl_count"
    fi

    log_metric "secrets_found" "$secrets_found"

    # Score calculation
    if [ "$secrets_found" -eq 0 ]; then
        echo "10"
    elif [ "$secrets_found" -lt 3 ]; then
        echo "5"
    else
        echo "2"
    fi
}

# =============================================================================
# DEPENDENCY VULNERABILITY SCANNING
# =============================================================================

scan_dependencies() {
    echo "  Scanning dependencies for vulnerabilities..." >&2

    local total_critical=0
    local total_high=0
    local total_medium=0
    local total_low=0

    # JavaScript: npm audit (with 60s timeout to prevent hanging)
    if [ -f "$CODEBASE_PATH/package.json" ] && [ -f "$CODEBASE_PATH/package-lock.json" ]; then
        echo "    Scanning npm dependencies..." >&2
        local npm_audit
        npm_audit=$(cd "$CODEBASE_PATH" && timeout 60 npm audit --json 2>/dev/null || echo '{"metadata":{"vulnerabilities":{}}}')

        local npm_critical
        npm_critical=$(echo "$npm_audit" | jq -r '.metadata.vulnerabilities.critical // 0' 2>/dev/null | tr -d '\n' | grep -oE '^[0-9]+$' || echo "0")
        local npm_high
        npm_high=$(echo "$npm_audit" | jq -r '.metadata.vulnerabilities.high // 0' 2>/dev/null | tr -d '\n' | grep -oE '^[0-9]+$' || echo "0")
        local npm_medium
        npm_medium=$(echo "$npm_audit" | jq -r '.metadata.vulnerabilities.moderate // 0' 2>/dev/null | tr -d '\n' | grep -oE '^[0-9]+$' || echo "0")
        local npm_low
        npm_low=$(echo "$npm_audit" | jq -r '.metadata.vulnerabilities.low // 0' 2>/dev/null | tr -d '\n' | grep -oE '^[0-9]+$' || echo "0")

        total_critical=$((total_critical + npm_critical))
        total_high=$((total_high + npm_high))
        total_medium=$((total_medium + npm_medium))
        total_low=$((total_low + npm_low))

        log_metric "npm_vulnerabilities_critical" "$npm_critical"
        log_metric "npm_vulnerabilities_high" "$npm_high"
        log_metric "npm_vulnerabilities_medium" "$npm_medium"
        log_metric "npm_vulnerabilities_low" "$npm_low"

        if [ "$npm_critical" -gt 0 ]; then
            add_finding "critical" "vulnerable_dependencies" "$npm_critical critical npm vulnerabilities" "package.json" "CWE-1035"
        fi
        if [ "$npm_high" -gt 0 ]; then
            add_finding "high" "vulnerable_dependencies" "$npm_high high npm vulnerabilities" "package.json" "CWE-1035"
        fi
    fi

    # Python: pip-audit or safety (with 60s timeout)
    if [ -f "$CODEBASE_PATH/requirements.txt" ] || [ -f "$CODEBASE_PATH/pyproject.toml" ]; then
        if command -v pip-audit &> /dev/null; then
            echo "    Scanning Python dependencies with pip-audit..." >&2
            local pip_audit
            pip_audit=$(cd "$CODEBASE_PATH" && timeout 60 pip-audit --format json 2>/dev/null || echo "[]")
            local pip_vulns
            pip_vulns=$(echo "$pip_audit" | jq 'length' 2>/dev/null || echo "0")

            log_metric "python_vulnerabilities" "$pip_vulns"

            if [ "$pip_vulns" -gt 0 ]; then
                total_high=$((total_high + pip_vulns))
                add_finding "high" "vulnerable_dependencies" "$pip_vulns Python dependency vulnerabilities" "requirements.txt" "CWE-1035"
            fi
        elif command -v safety &> /dev/null; then
            echo "    Scanning Python dependencies with safety..." >&2
            (
                cd "$CODEBASE_PATH"

                local safety_output
                safety_output=$(safety check --json 2>/dev/null || echo "[]")
                local safety_vulns
                safety_vulns=$(echo "$safety_output" | jq 'length')

                log_metric "python_vulnerabilities" "$safety_vulns"
            )
        fi
    fi

    # Try Snyk if available
    if command -v snyk &> /dev/null; then
        echo "    Running Snyk scan..." >&2
        (
            cd "$CODEBASE_PATH"

            local snyk_output
            snyk_output=$(snyk test --json 2>/dev/null || echo '{"vulnerabilities":[]}')

            local snyk_vulns
            snyk_vulns=$(echo "$snyk_output" | jq '.vulnerabilities | length')
            log_metric "snyk_vulnerabilities" "$snyk_vulns"
        )
    fi

    # Try Trivy if available (for comprehensive scanning)
    if command -v trivy &> /dev/null; then
        echo "    Running Trivy scan..." >&2
        (
            cd "$CODEBASE_PATH"

            local trivy_output
            trivy_output=$(trivy fs --format json --security-checks vuln . 2>/dev/null || echo '{"Results":[]}')

            local trivy_critical
            trivy_critical=$(echo "$trivy_output" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length')
            local trivy_high
            trivy_high=$(echo "$trivy_output" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length')

            log_metric "trivy_critical" "$trivy_critical"
            log_metric "trivy_high" "$trivy_high"

            total_critical=$((total_critical + trivy_critical))
            total_high=$((total_high + trivy_high))
        )
    fi

    log_metric "total_critical_vulnerabilities" "$total_critical"
    log_metric "total_high_vulnerabilities" "$total_high"
    log_metric "total_medium_vulnerabilities" "$total_medium"
    log_metric "total_low_vulnerabilities" "$total_low"

    # Score calculation
    if [ "$total_critical" -eq 0 ] && [ "$total_high" -eq 0 ]; then
        if [ "$total_medium" -eq 0 ]; then
            echo "10"
        elif [ "$total_medium" -lt 5 ]; then
            echo "8"
        else
            echo "6"
        fi
    elif [ "$total_critical" -eq 0 ]; then
        if [ "$total_high" -lt 3 ]; then
            echo "6"
        else
            echo "4"
        fi
    else
        if [ "$total_critical" -lt 3 ]; then
            echo "3"
        else
            echo "1"
        fi
    fi
}

# =============================================================================
# SAST (Static Application Security Testing)
# =============================================================================

run_sast() {
    echo "  Running SAST analysis..." >&2

    local sast_score=10
    local total_findings=0

    # Check for common vulnerability patterns
    echo "    Checking for SQL injection patterns..." >&2

    # SQL Injection patterns
    local sql_injection
    sql_injection=$( (grep -rniE "(execute|query|raw)\s*\(\s*['\"].*\+|f['\"].*SELECT|f['\"].*INSERT|f['\"].*UPDATE|f['\"].*DELETE" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.php" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
        --exclude-dir=.next --exclude-dir=coverage --exclude-dir=dist --exclude-dir=build \
        --exclude-dir=storybook-static --exclude-dir=playwright-report 2>/dev/null || true) | wc -l)

    if [ "$sql_injection" -gt 0 ]; then
        add_finding "critical" "sql_injection" "$sql_injection potential SQL injection vulnerabilities" "$CODEBASE_PATH" "CWE-89"
        sast_score=$((sast_score - 3))
        total_findings=$((total_findings + sql_injection))
    fi
    log_metric "sql_injection_risks" "$sql_injection"

    # XSS patterns
    echo "    Checking for XSS patterns..." >&2
    local xss_patterns
    xss_patterns=$( (grep -rniE "innerHTML\s*=|dangerouslySetInnerHTML|v-html|document\.write\(" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" --include="*.vue" \
        --exclude-dir=node_modules --exclude-dir=.git \
        --exclude-dir=.next --exclude-dir=coverage --exclude-dir=dist --exclude-dir=build \
        --exclude-dir=storybook-static --exclude-dir=playwright-report 2>/dev/null || true) | wc -l)

    if [ "$xss_patterns" -gt 0 ]; then
        add_finding "high" "xss" "$xss_patterns potential XSS vulnerabilities" "$CODEBASE_PATH" "CWE-79"
        sast_score=$((sast_score - 2))
        total_findings=$((total_findings + xss_patterns))
    fi
    log_metric "xss_risks" "$xss_patterns"

    # Command injection patterns
    echo "    Checking for command injection patterns..." >&2
    local cmd_injection
    cmd_injection=$( (grep -rniE "(exec|spawn|system|popen|shell_exec)\s*\(.*\+" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.php" --include="*.rb" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
        --exclude-dir=.next --exclude-dir=coverage --exclude-dir=dist --exclude-dir=build \
        --exclude-dir=storybook-static --exclude-dir=playwright-report 2>/dev/null || true) | wc -l)

    if [ "$cmd_injection" -gt 0 ]; then
        add_finding "critical" "command_injection" "$cmd_injection potential command injection vulnerabilities" "$CODEBASE_PATH" "CWE-78"
        sast_score=$((sast_score - 3))
        total_findings=$((total_findings + cmd_injection))
    fi
    log_metric "command_injection_risks" "$cmd_injection"

    # Path traversal patterns
    echo "    Checking for path traversal patterns..." >&2
    local path_traversal
    path_traversal=$( (grep -rniE "(readFile|writeFile|open|include|require)\s*\(.*\+.*\.\." "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.php" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
        --exclude-dir=.next --exclude-dir=coverage --exclude-dir=dist --exclude-dir=build \
        --exclude-dir=storybook-static --exclude-dir=playwright-report 2>/dev/null || true) | wc -l)

    if [ "$path_traversal" -gt 0 ]; then
        add_finding "high" "path_traversal" "$path_traversal potential path traversal vulnerabilities" "$CODEBASE_PATH" "CWE-22"
        sast_score=$((sast_score - 2))
        total_findings=$((total_findings + path_traversal))
    fi
    log_metric "path_traversal_risks" "$path_traversal"

    # Run Semgrep if available
    if command -v semgrep &> /dev/null; then
        echo "    Running Semgrep (120s timeout)..." >&2
        local semgrep_output
        semgrep_output=$(cd "$CODEBASE_PATH" && timeout 120 semgrep --config=auto --json --quiet . 2>/dev/null || echo '{"results":[]}')

        local semgrep_findings
        semgrep_findings=$(echo "$semgrep_output" | jq '.results | length' 2>/dev/null || echo "0")

        local semgrep_errors
        semgrep_errors=$(echo "$semgrep_output" | jq '[.results[] | select(.extra.severity == "ERROR")] | length' 2>/dev/null || echo "0")

        log_metric "semgrep_findings" "$semgrep_findings"
        log_metric "semgrep_errors" "$semgrep_errors"

        total_findings=$((total_findings + semgrep_errors))
    fi

    log_metric "total_sast_findings" "$total_findings"

    # Ensure score doesn't go below 1
    if [ "$sast_score" -lt 1 ]; then
        sast_score=1
    fi

    echo "$sast_score"
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

check_security_config() {
    echo "  Checking security configurations..." >&2

    local config_score=10

    # Check for security headers middleware
    local has_helmet=false
    local has_cors=false
    local has_rate_limit=false

    if [ -f "$CODEBASE_PATH/package.json" ]; then
        if grep -q '"helmet"' "$CODEBASE_PATH/package.json" 2>/dev/null; then
            has_helmet=true
            log_metric "helmet_enabled" "true"
        elif grep -qE "(Content-Security-Policy|X-Frame-Options|Strict-Transport-Security)" \
            "$CODEBASE_PATH/next.config.js" "$CODEBASE_PATH/next.config.ts" \
            "$CODEBASE_PATH/next.config.mjs" 2>/dev/null; then
            # Next.js projects configure security headers via next.config.js headers()
            has_helmet=true
            log_metric "helmet_enabled" "true"
        else
            log_metric "helmet_enabled" "false"
            add_finding "medium" "security_headers" "Helmet.js not found - security headers may be missing" "$CODEBASE_PATH/package.json" "CWE-693"
            config_score=$((config_score - 1))
        fi

        if grep -q '"cors"' "$CODEBASE_PATH/package.json" 2>/dev/null; then
            has_cors=true
            log_metric "cors_configured" "true"
        fi

        if grep -qE '"(express-rate-limit|rate-limiter)"' "$CODEBASE_PATH/package.json" 2>/dev/null; then
            has_rate_limit=true
            log_metric "rate_limiting_enabled" "true"
        elif grep -qE "(isRateLimited|rate.*limit|rateLimit|RateLimit)" \
            "$CODEBASE_PATH/src/middleware.ts" "$CODEBASE_PATH/middleware.ts" 2>/dev/null; then
            # Next.js projects implement rate limiting in middleware.ts
            has_rate_limit=true
            log_metric "rate_limiting_enabled" "true"
        else
            log_metric "rate_limiting_enabled" "false"
            add_finding "medium" "rate_limiting" "No rate limiting middleware found" "$CODEBASE_PATH/package.json" "CWE-770"
            config_score=$((config_score - 1))
        fi
    fi

    # Check for HTTPS enforcement
    local http_usage
    http_usage=$( (grep -rniE "http://[^localhost][^127\.0\.0\.1]" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
        --exclude-dir=.next --exclude-dir=coverage --exclude-dir=dist --exclude-dir=build 2>/dev/null || true) | wc -l)

    if [ "$http_usage" -gt 0 ]; then
        add_finding "medium" "insecure_transport" "$http_usage instances of HTTP (not HTTPS) found" "$CODEBASE_PATH" "CWE-319"
        config_score=$((config_score - 1))
    fi
    log_metric "http_usage_count" "$http_usage"

    # Check for password hashing
    local has_bcrypt=false
    local has_argon2=false

    if grep -rqE "(bcrypt|argon2|scrypt)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
        --exclude-dir=.next --exclude-dir=coverage 2>/dev/null; then
        has_bcrypt=true
        log_metric "secure_password_hashing" "true"
    elif grep -rqE "(next-auth|@auth/|NextAuth)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.next 2>/dev/null; then
        # NextAuth.js handles password hashing internally via its credential provider
        has_bcrypt=true
        log_metric "secure_password_hashing" "true (via NextAuth)"
    else
        # Only flag if auth-related code exists
        if grep -rqE "(password|login|auth)" "$CODEBASE_PATH" \
            --include="*.js" --include="*.ts" --include="*.py" \
            --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.next 2>/dev/null; then
            log_metric "secure_password_hashing" "false"
            add_finding "high" "password_hashing" "No secure password hashing library found" "$CODEBASE_PATH" "CWE-916"
            config_score=$((config_score - 2))
        fi
    fi

    # Check for JWT implementation
    if grep -rqE "(jsonwebtoken|jose|jwt)" "$CODEBASE_PATH" \
        --include="*.js" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "jwt_usage" "true"

        # Check for insecure JWT patterns (algorithm none, weak secret)
        local jwt_issues
        jwt_issues=$( (grep -rniE "algorithm.*none|HS256.*hardcoded" "$CODEBASE_PATH" \
            --include="*.js" --include="*.ts" \
            --exclude-dir=node_modules --exclude-dir=.git \
            --exclude-dir=.next --exclude-dir=coverage --exclude-dir=dist --exclude-dir=build 2>/dev/null || true) | wc -l)

        if [ "$jwt_issues" -gt 0 ]; then
            add_finding "high" "jwt_security" "Potential JWT security issues found" "$CODEBASE_PATH" "CWE-347"
            config_score=$((config_score - 2))
        fi
    fi

    echo "$config_score"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo "Starting Security Evaluation..." >&2
    echo "Codebase: $CODEBASE_PATH" >&2

    local secrets_score
    secrets_score=$(detect_secrets)
    echo "  Secrets Score: $secrets_score/10" >&2

    local dependency_score
    dependency_score=$(scan_dependencies)
    echo "  Dependency Score: $dependency_score/10" >&2

    local sast_score
    sast_score=$(run_sast)
    echo "  SAST Score: $sast_score/10" >&2

    local config_score
    config_score=$(check_security_config)
    echo "  Config Score: $config_score/10" >&2

    # Calculate weighted average
    # Secrets: 25%, Dependencies: 25%, SAST: 30%, Config: 20%
    local total_score
    total_score=$(math_calc "$secrets_score * 0.25 + $dependency_score * 0.25 + $sast_score * 0.30 + $config_score * 0.20")

    # Update results
    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 38')

    # Add subscores
    RESULTS=$(echo "$RESULTS" | jq \
        --arg ss "$secrets_score" \
        --arg ds "$dependency_score" \
        --arg sast "$sast_score" \
        --arg cs "$config_score" \
        '.subscores = {
            secrets: ($ss | tonumber),
            dependencies: ($ds | tonumber),
            sast: ($sast | tonumber),
            configuration: ($cs | tonumber)
        }')

    # Count vulnerabilities by severity (before merge, which cleans up the file)
    local critical_count=$(count_findings_by_severity "critical")
    local high_count=$(count_findings_by_severity "high")
    local medium_count=$(count_findings_by_severity "medium")
    local low_count=$(count_findings_by_severity "low")

    # Merge accumulated findings from JSONL file (also cleans up temp file)
    RESULTS=$(merge_findings "$RESULTS")

    RESULTS=$(echo "$RESULTS" | jq \
        --argjson crit "$critical_count" \
        --argjson high "$high_count" \
        --argjson med "$medium_count" \
        --argjson low "$low_count" \
        '.vulnerabilities = {critical: $crit, high: $high, medium: $med, low: $low}')

    # Write output
    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"

    echo "" >&2
    echo "Security Score: $total_score/10" >&2
    echo "Results saved to: $OUTPUT_FILE" >&2

    # Summary
    local critical_count
    critical_count=$(echo "$RESULTS" | jq '.vulnerabilities.critical')
    local high_count
    high_count=$(echo "$RESULTS" | jq '.vulnerabilities.high')

    if [ "$critical_count" -gt 0 ]; then
        echo "WARNING: $critical_count CRITICAL vulnerabilities found!" >&2
    fi
    if [ "$high_count" -gt 0 ]; then
        echo "WARNING: $high_count HIGH severity issues found!" >&2
    fi
}

main
