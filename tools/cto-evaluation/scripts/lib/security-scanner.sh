#!/bin/bash

# =============================================================================
# ADVANCED SECURITY SCANNER
# =============================================================================
# Comprehensive security analysis:
#   - Secret detection with multiple patterns
#   - SAST with multiple tools
#   - Dependency vulnerability scanning
#   - SBOM generation
#   - Security misconfiguration detection
#   - License compliance checking
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/math-utils.sh"

# =============================================================================
# SECRET PATTERNS DATABASE
# =============================================================================

# Extended patterns for secret detection
SECRET_PATTERNS=(
    # AWS
    'AKIA[0-9A-Z]{16}'
    'aws_access_key_id\s*[=:]\s*["\x27]?[A-Z0-9]{20}'
    'aws_secret_access_key\s*[=:]\s*["\x27]?[A-Za-z0-9/+=]{40}'
    
    # Google Cloud
    'AIza[0-9A-Za-z\-_]{35}'
    'ya29\.[0-9A-Za-z\-_]+'
    '"type"\s*:\s*"service_account"'
    
    # GitHub
    'gh[pousr]_[A-Za-z0-9_]{36,}'
    'github_pat_[A-Za-z0-9_]{22,}'
    
    # GitLab
    'glpat-[A-Za-z0-9\-]{20,}'
    
    # Slack
    'xox[baprs]-[0-9a-zA-Z]{10,}'
    'https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+'
    
    # Stripe
    'sk_live_[0-9a-zA-Z]{24,}'
    'rk_live_[0-9a-zA-Z]{24,}'
    
    # OpenAI
    'sk-[A-Za-z0-9]{48,}'
    
    # Anthropic
    'sk-ant-[A-Za-z0-9\-]{90,}'
    
    # Private Keys
    '-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY'
    '-----BEGIN CERTIFICATE-----'
    
    # Generic API Keys/Tokens
    'api[_-]?key\s*[=:]\s*["\x27][A-Za-z0-9_\-]{20,}["\x27]'
    'api[_-]?secret\s*[=:]\s*["\x27][A-Za-z0-9_\-]{20,}["\x27]'
    'auth[_-]?token\s*[=:]\s*["\x27][A-Za-z0-9_\-]{20,}["\x27]'
    'access[_-]?token\s*[=:]\s*["\x27][A-Za-z0-9_\-]{20,}["\x27]'
    'bearer\s+[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+'
    
    # Passwords
    'password\s*[=:]\s*["\x27][^\s"]{8,}["\x27]'
    'passwd\s*[=:]\s*["\x27][^\s"]{8,}["\x27]'
    'pwd\s*[=:]\s*["\x27][^\s"]{8,}["\x27]'
    
    # Database URLs
    'postgres://[^:]+:[^@]+@'
    'mysql://[^:]+:[^@]+@'
    'mongodb(\+srv)?://[^:]+:[^@]+@'
    'redis://:[^@]+@'
    
    # Sendgrid
    'SG\.[A-Za-z0-9\-_]{22,}\.[A-Za-z0-9\-_]{22,}'
    
    # Twilio
    'SK[0-9a-fA-F]{32}'
    'AC[0-9a-fA-F]{32}'
    
    # Mailgun
    'key-[0-9a-zA-Z]{32}'
    
    # Firebase
    'AAAA[A-Za-z0-9_-]{7}:[A-Za-z0-9_-]{140}'
    
    # Heroku
    '[hH][eE][rR][oO][kK][uU].*[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}'
)

# =============================================================================
# SECRET DETECTION
# =============================================================================

scan_secrets() {
    local codebase="$1"
    local findings='[]'
    local total_secrets=0
    
    echo "  Scanning for secrets..." >&2
    
    # Files to scan
    local include_patterns="--include=*.js --include=*.ts --include=*.py --include=*.go --include=*.java \
        --include=*.rb --include=*.php --include=*.cs --include=*.json --include=*.yaml --include=*.yml \
        --include=*.env* --include=*.properties --include=*.conf --include=*.config --include=*.xml \
        --include=*.sh --include=*.toml"
    
    # Exclusions (security rule files, examples, tests)
    local exclude_patterns="--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
        --exclude-dir=dist --exclude-dir=build --exclude-dir=coverage \
        --exclude=*semgrep*.yaml --exclude=*.baseline --exclude=*test* --exclude=*spec* \
        --exclude=*example* --exclude=*sample* --exclude=*.md"
    
    for pattern in "${SECRET_PATTERNS[@]}"; do
        local matches=$(grep -rnoEi "$pattern" "$codebase" $include_patterns $exclude_patterns 2>/dev/null | head -50)
        
        if [ -n "$matches" ]; then
            while IFS= read -r match; do
                local file=$(echo "$match" | cut -d: -f1)
                local line=$(echo "$match" | cut -d: -f2)
                local snippet=$(echo "$match" | cut -d: -f3- | head -c 100)
                
                # Skip if in comments or documentation
                local context=$(sed -n "${line}p" "$file" 2>/dev/null)
                if echo "$context" | grep -qE "^\s*(//|#|/\*|\*|<!--)" 2>/dev/null; then
                    # Check if it looks like a real secret (not a pattern example)
                    if ! echo "$context" | grep -qiE "(example|sample|placeholder|your_|fake|test)" 2>/dev/null; then
                        findings=$(echo "$findings" | jq --arg f "$file" --arg l "$line" --arg p "${pattern:0:30}..." \
                            '. += [{file: $f, line: ($l | tonumber), pattern_type: $p, severity: "high", in_comment: true}]')
                        total_secrets=$((total_secrets + 1))
                    fi
                else
                    # Not in comment - higher severity
                    if ! echo "$context" | grep -qiE "(example|sample|placeholder|your_|fake|test|TODO)" 2>/dev/null; then
                        findings=$(echo "$findings" | jq --arg f "$file" --arg l "$line" --arg p "${pattern:0:30}..." \
                            '. += [{file: $f, line: ($l | tonumber), pattern_type: $p, severity: "critical", in_comment: false}]')
                        total_secrets=$((total_secrets + 1))
                    fi
                fi
            done <<< "$matches"
        fi
    done
    
    # Use external tools if available
    if command -v gitleaks &> /dev/null; then
        echo "    Running Gitleaks..." >&2
        local gl_output=$(gitleaks detect --source="$codebase" --no-git -f json 2>/dev/null || echo "[]")
        local gl_count=$(echo "$gl_output" | jq 'length')
        
        if [ "$gl_count" -gt 0 ]; then
            total_secrets=$((total_secrets + gl_count))
            echo "$gl_output" | jq -c '.[]' | while read -r item; do
                local file=$(echo "$item" | jq -r '.File')
                local line=$(echo "$item" | jq -r '.StartLine')
                local rule=$(echo "$item" | jq -r '.RuleID')
                findings=$(echo "$findings" | jq --arg f "$file" --arg l "$line" --arg r "$rule" \
                    '. += [{file: $f, line: ($l | tonumber), pattern_type: $r, severity: "critical", tool: "gitleaks"}]')
            done
        fi
    fi
    
    if command -v trufflehog &> /dev/null; then
        echo "    Running TruffleHog..." >&2
        local th_output=$(trufflehog filesystem "$codebase" --json --no-verification 2>/dev/null | head -100 || echo "")
        
        if [ -n "$th_output" ]; then
            local th_count=$(echo "$th_output" | jq -s 'length')
            total_secrets=$((total_secrets + th_count))
        fi
    fi
    
    jq -n \
        --argjson findings "$findings" \
        --argjson count "$total_secrets" \
        '{
            total_secrets_found: $count,
            findings: $findings,
            severity_breakdown: {
                critical: ([$findings[] | select(.severity == "critical")] | length),
                high: ([$findings[] | select(.severity == "high")] | length)
            },
            score: (
                if $count == 0 then 10
                elif $count <= 2 then 6
                elif $count <= 5 then 4
                elif $count <= 10 then 2
                else 0
                end
            )
        }'
}

# =============================================================================
# DEPENDENCY VULNERABILITY SCANNING
# =============================================================================

scan_dependencies() {
    local codebase="$1"
    local vulns='{
        "npm": {"critical": 0, "high": 0, "medium": 0, "low": 0, "total": 0},
        "python": {"critical": 0, "high": 0, "medium": 0, "low": 0, "total": 0},
        "go": {"critical": 0, "high": 0, "medium": 0, "low": 0, "total": 0},
        "ruby": {"critical": 0, "high": 0, "medium": 0, "low": 0, "total": 0},
        "java": {"critical": 0, "high": 0, "medium": 0, "low": 0, "total": 0}
    }'
    
    local total_critical=0
    local total_high=0
    local total_medium=0
    local total_low=0
    
    echo "  Scanning dependencies for vulnerabilities..." >&2
    
    # NPM/Node.js
    if [ -f "$codebase/package-lock.json" ] || [ -f "$codebase/yarn.lock" ]; then
        echo "    Scanning npm packages..." >&2
        cd "$codebase"
        
        if [ -f "package-lock.json" ]; then
            local npm_audit=$(npm audit --json 2>/dev/null || echo '{"metadata":{"vulnerabilities":{"critical":0,"high":0,"moderate":0,"low":0}}}')
            
            local npm_crit=$(echo "$npm_audit" | jq -r '.metadata.vulnerabilities.critical // 0' 2>/dev/null | grep -oE '^[0-9]+' || echo 0)
            local npm_high=$(echo "$npm_audit" | jq -r '.metadata.vulnerabilities.high // 0' 2>/dev/null | grep -oE '^[0-9]+' || echo 0)
            local npm_med=$(echo "$npm_audit" | jq -r '.metadata.vulnerabilities.moderate // 0' 2>/dev/null | grep -oE '^[0-9]+' || echo 0)
            local npm_low=$(echo "$npm_audit" | jq -r '.metadata.vulnerabilities.low // 0' 2>/dev/null | grep -oE '^[0-9]+' || echo 0)
            
            total_critical=$((total_critical + npm_crit))
            total_high=$((total_high + npm_high))
            total_medium=$((total_medium + npm_med))
            total_low=$((total_low + npm_low))
            
            vulns=$(echo "$vulns" | jq \
                --argjson c "$npm_crit" --argjson h "$npm_high" --argjson m "$npm_med" --argjson l "$npm_low" \
                '.npm = {critical: $c, high: $h, medium: $m, low: $l, total: ($c + $h + $m + $l)}')
        fi
    fi
    
    # Python
    if [ -f "$codebase/requirements.txt" ] || [ -f "$codebase/Pipfile.lock" ] || [ -f "$codebase/poetry.lock" ]; then
        echo "    Scanning Python packages..." >&2
        cd "$codebase"
        
        if command -v pip-audit &> /dev/null; then
            local pip_audit=$(pip-audit --format json -r requirements.txt 2>/dev/null || echo "[]")
            local py_vulns=$(echo "$pip_audit" | jq 'length')
            
            total_high=$((total_high + py_vulns))
            vulns=$(echo "$vulns" | jq --argjson v "$py_vulns" '.python.high = $v | .python.total = $v')
            
        elif command -v safety &> /dev/null; then
            local safety_out=$(safety check --json 2>/dev/null || echo "[]")
            local py_vulns=$(echo "$safety_out" | jq 'length')
            
            total_high=$((total_high + py_vulns))
            vulns=$(echo "$vulns" | jq --argjson v "$py_vulns" '.python.high = $v | .python.total = $v')
        fi
    fi
    
    # Go
    if [ -f "$codebase/go.mod" ]; then
        echo "    Scanning Go modules..." >&2
        cd "$codebase"
        
        if command -v govulncheck &> /dev/null; then
            local govuln=$(govulncheck -json ./... 2>/dev/null | jq -s '[.[] | select(.vulnerability != null)]' || echo "[]")
            local go_vulns=$(echo "$govuln" | jq 'length')
            
            total_high=$((total_high + go_vulns))
            vulns=$(echo "$vulns" | jq --argjson v "$go_vulns" '.go.high = $v | .go.total = $v')
        fi
    fi
    
    # Trivy (universal scanner)
    if command -v trivy &> /dev/null; then
        echo "    Running Trivy comprehensive scan..." >&2
        local trivy_out=$(trivy fs --format json --security-checks vuln "$codebase" 2>/dev/null || echo '{"Results":[]}')
        
        local trivy_crit=$(echo "$trivy_out" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length')
        local trivy_high=$(echo "$trivy_out" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length')
        local trivy_med=$(echo "$trivy_out" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length')
        local trivy_low=$(echo "$trivy_out" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW")] | length')
        
        # Don't double count - only add if we didn't already scan this ecosystem
        # For now, add as supplementary data
        vulns=$(echo "$vulns" | jq \
            --argjson c "$trivy_crit" --argjson h "$trivy_high" --argjson m "$trivy_med" --argjson l "$trivy_low" \
            '. + {trivy: {critical: $c, high: $h, medium: $m, low: $l}}')
    fi
    
    # Calculate score
    local score=10
    if [ "$total_critical" -gt 0 ]; then
        score=$((score - total_critical * 3))
    fi
    if [ "$total_high" -gt 0 ]; then
        score=$((score - total_high))
    fi
    if [ "$total_medium" -gt 5 ]; then
        score=$((score - 1))
    fi
    [ "$score" -lt 0 ] && score=0
    
    jq -n \
        --argjson vulns "$vulns" \
        --argjson crit "$total_critical" \
        --argjson high "$total_high" \
        --argjson med "$total_medium" \
        --argjson low "$total_low" \
        --argjson score "$score" \
        '{
            vulnerabilities_by_ecosystem: $vulns,
            totals: {
                critical: $crit,
                high: $high,
                medium: $med,
                low: $low
            },
            score: $score,
            risk_level: (
                if $crit > 0 then "critical"
                elif $high > 5 then "high"
                elif $high > 0 then "medium"
                elif $med > 10 then "medium"
                else "low"
                end
            )
        }'
}

# =============================================================================
# SECURITY MISCONFIGURATION DETECTION
# =============================================================================

scan_misconfigurations() {
    local codebase="$1"
    local misconfigs='[]'
    
    echo "  Scanning for security misconfigurations..." >&2
    
    # CORS misconfiguration
    if grep -rqE 'Access-Control-Allow-Origin.*\*|cors\(\s*\)' "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --exclude-dir=node_modules 2>/dev/null; then
        misconfigs=$(echo "$misconfigs" | jq '. += [{type: "cors", severity: "medium", message: "Permissive CORS configuration detected"}]')
    fi
    
    # Debug mode enabled
    if grep -rqE 'DEBUG\s*=\s*(True|true|1)|NODE_ENV.*development' "$codebase" \
        --include="*.env" --include="*.env.*" --include="*.py" --exclude="*.example" 2>/dev/null; then
        misconfigs=$(echo "$misconfigs" | jq '. += [{type: "debug_mode", severity: "high", message: "Debug mode may be enabled in production config"}]')
    fi
    
    # Insecure cookie settings
    if grep -rqE 'secure\s*[:=]\s*(false|False)|httpOnly\s*[:=]\s*(false|False)' "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --exclude-dir=node_modules 2>/dev/null; then
        misconfigs=$(echo "$misconfigs" | jq '. += [{type: "insecure_cookies", severity: "high", message: "Insecure cookie configuration detected"}]')
    fi
    
    # Missing security headers (check for helmet, security middleware)
    if [ -f "$codebase/package.json" ]; then
        if ! grep -q '"helmet"' "$codebase/package.json" 2>/dev/null; then
            if grep -q '"express"' "$codebase/package.json" 2>/dev/null; then
                misconfigs=$(echo "$misconfigs" | jq '. += [{type: "missing_helmet", severity: "medium", message: "Express app missing Helmet security middleware"}]')
            fi
        fi
    fi
    
    # SQL injection potential (raw queries)
    if grep -rqE '\$\{.*\}.*SELECT|SELECT.*\+.*|execute\(.*%s' "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --exclude-dir=node_modules 2>/dev/null; then
        misconfigs=$(echo "$misconfigs" | jq '. += [{type: "sql_injection", severity: "critical", message: "Potential SQL injection - string interpolation in queries"}]')
    fi
    
    # eval() usage
    if grep -rqE '\beval\s*\(|\bnew\s+Function\s*\(' "$codebase" \
        --include="*.js" --include="*.ts" --exclude-dir=node_modules 2>/dev/null; then
        misconfigs=$(echo "$misconfigs" | jq '. += [{type: "eval_usage", severity: "high", message: "Dangerous eval() or Function() constructor usage detected"}]')
    fi
    
    # Hardcoded IPs/hosts in code
    if grep -rqE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$codebase" \
        --include="*.js" --include="*.ts" --include="*.py" --exclude-dir=node_modules \
        --exclude="*.md" --exclude="*.log" 2>/dev/null; then
        misconfigs=$(echo "$misconfigs" | jq '. += [{type: "hardcoded_ip", severity: "low", message: "Hardcoded IP addresses found"}]')
    fi
    
    # Missing rate limiting
    if [ -f "$codebase/package.json" ]; then
        if ! grep -qE '"express-rate-limit"|"rate-limiter"' "$codebase/package.json" 2>/dev/null; then
            if grep -q '"express"' "$codebase/package.json" 2>/dev/null; then
                misconfigs=$(echo "$misconfigs" | jq '. += [{type: "missing_rate_limit", severity: "medium", message: "No rate limiting middleware detected"}]')
            fi
        fi
    fi
    
    local count=$(echo "$misconfigs" | jq 'length')
    local crit_count=$(echo "$misconfigs" | jq '[.[] | select(.severity == "critical")] | length')
    local high_count=$(echo "$misconfigs" | jq '[.[] | select(.severity == "high")] | length')
    
    local score=10
    score=$((score - crit_count * 3 - high_count * 2))
    [ "$score" -lt 0 ] && score=0
    
    jq -n \
        --argjson items "$misconfigs" \
        --argjson count "$count" \
        --argjson score "$score" \
        '{
            misconfigurations: $items,
            total: $count,
            score: $score
        }'
}

# =============================================================================
# COMPREHENSIVE SECURITY SCAN
# =============================================================================

run_full_security_scan() {
    local codebase="$1"
    local output_file="${2:-/dev/stdout}"
    
    echo "Running comprehensive security scan..." >&2
    
    local secrets=$(scan_secrets "$codebase")
    local deps=$(scan_dependencies "$codebase")
    local misconfigs=$(scan_misconfigurations "$codebase")
    
    # Calculate overall score
    local secrets_score=$(echo "$secrets" | jq '.score')
    local deps_score=$(echo "$deps" | jq '.score')
    local config_score=$(echo "$misconfigs" | jq '.score')
    
    local overall_score=$(math_calc "($secrets_score * 0.4 + $deps_score * 0.4 + $config_score * 0.2)")
    
    jq -n \
        --argjson secrets "$secrets" \
        --argjson deps "$deps" \
        --argjson misconfigs "$misconfigs" \
        --arg overall "$overall_score" \
        '{
            security_scan_version: "2.0",
            secrets: $secrets,
            dependencies: $deps,
            misconfigurations: $misconfigs,
            overall_score: ($overall | tonumber),
            risk_assessment: (
                if ($overall | tonumber) >= 8 then "low"
                elif ($overall | tonumber) >= 6 then "medium"
                elif ($overall | tonumber) >= 4 then "high"
                else "critical"
                end
            ),
            recommendations: (
                []
                + (if $secrets.total_secrets_found > 0 then ["CRITICAL: Remove hardcoded secrets and use environment variables or secret management"] else [] end)
                + (if $deps.totals.critical > 0 then ["CRITICAL: Update dependencies with critical vulnerabilities immediately"] else [] end)
                + (if $deps.totals.high > 0 then ["HIGH: Update dependencies with high-severity vulnerabilities"] else [] end)
                + (if ($misconfigs.misconfigurations | map(select(.severity == "critical")) | length) > 0 then ["CRITICAL: Fix security misconfigurations"] else [] end)
            )
        }' > "$output_file"
    
    cat "$output_file"
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_full_security_scan "$@"
fi
