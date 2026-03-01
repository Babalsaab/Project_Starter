#!/bin/bash

# =============================================================================
# COMPLIANCE & GOVERNANCE EVALUATION (Parameters 411-422)
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
source "$SCRIPT_DIR/common-findings.sh"
source "$SCRIPT_DIR/lib/math-utils.sh"
init_findings

# Progress tracking
TOTAL_STEPS=5
CURRENT_STEP=0

progress_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "Evaluating: [$CURRENT_STEP/$TOTAL_STEPS] $1" >&2
}

RESULTS='{
    "category": "compliance",
    "parameters_evaluated": 0,
    "parameters_total": 12,
    "score": 0,
    "findings": [],
    "metrics": {}
}'

log_metric() {
    RESULTS=$(echo "$RESULTS" | jq --arg n "$1" --arg v "$2" '.metrics[$n] = $v')
}

# add_finding is now provided by common-findings.sh with location support
# add_finding "severity" "parameter" "message" "location"

# =============================================================================
# Check Privacy Compliance (Parameters 376-377)
# =============================================================================
check_privacy() {
    progress_step "Privacy compliance (GDPR/CCPA)"
    local score=5

    # Check for privacy-related patterns
    if grep -rqE "(gdpr|GDPR|ccpa|CCPA|privacy.*policy|data.*protection)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.md" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "privacy_mentions" "true"
        score=$((score + 1))
        echo "Scanning: Found privacy compliance references" >&2
    fi

    # Check for consent management
    if grep -rqE "(consent|Consent|cookie.*consent|CookieConsent|gdpr.*consent)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.tsx" --include="*.js" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "consent_management" "true"
        score=$((score + 2))
        echo "Scanning: Found consent management" >&2
    fi

    # Check for data deletion capability (Right to Erasure)
    if grep -rqE "(delete.*user|deleteAccount|purge.*data|erasure|anonymize)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=test* 2>/dev/null; then
        log_metric "data_deletion" "true"
        score=$((score + 1))
    fi

    # Check for data export capability
    if grep -rqE "(export.*data|download.*data|data.*portability|getUserData)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "data_export" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Security Compliance (Parameters 357, 362)
# =============================================================================
check_security_compliance() {
    progress_step "Security compliance (SOC2, Privacy by Design)"
    local score=5

    # Check for security headers
    if grep -rqE "(helmet|security.*header|X-Frame-Options|Content-Security-Policy|HSTS)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "security_headers" "true"
        score=$((score + 1))
    fi

    # Check for audit logging
    if grep -rqE "(audit.*log|AuditLog|@Audit|audit_trail)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "audit_logging" "true"
        score=$((score + 2))
        echo "Scanning: Found audit logging" >&2
    fi

    # Check for data classification
    if grep -rqE "(sensitive|Sensitive|pii|PII|confidential|Confidential|@sensitive)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "data_classification" "true"
        score=$((score + 1))
    fi

    # Check for security documentation
    if [ -f "$CODEBASE_PATH/SECURITY.md" ] || [ -f "$CODEBASE_PATH/.github/SECURITY.md" ]; then
        log_metric "security_policy" "true"
        score=$((score + 1))
        echo "Scanning: Found SECURITY.md" >&2
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check License Compliance (Parameter 363)
# =============================================================================
check_license() {
    progress_step "License compliance"
    local score=5

    # Check for LICENSE file
    if [ -f "$CODEBASE_PATH/LICENSE" ] || [ -f "$CODEBASE_PATH/LICENSE.md" ] || [ -f "$CODEBASE_PATH/LICENSE.txt" ]; then
        log_metric "license_file" "true"
        score=$((score + 2))
        echo "Scanning: Found LICENSE file" >&2
    else
        add_finding "medium" "license" "No LICENSE file found"
        score=$((score - 1))
    fi

    # Check for license in package.json
    if [ -f "$CODEBASE_PATH/package.json" ]; then
        if jq -e '.license' "$CODEBASE_PATH/package.json" >/dev/null 2>&1; then
            log_metric "package_license" "true"
            score=$((score + 1))
        fi
    fi

    # Check for license scanning tools
    if grep -rqE "(license-checker|licensee|fossa|snyk.*license)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.yaml" --include="*.yml" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "license_scanning" "true"
        score=$((score + 1))
    fi

    # Check for NOTICE file (Apache compliance)
    if [ -f "$CODEBASE_PATH/NOTICE" ]; then
        log_metric "notice_file" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Data Handling Compliance (Parameters 358, 360)
# =============================================================================
check_data_handling() {
    progress_step "Data handling compliance"
    local score=5

    # Check for data residency configurations
    if grep -rqE "(region|Region|REGION|zone|availability.*zone|datacenter)" "$CODEBASE_PATH" \
        --include="*.yaml" --include="*.yml" --include="*.json" --include="*.env*" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "data_residency" "true"
        score=$((score + 1))
    fi

    # Check for encryption
    if grep -rqE "(encrypt|Encrypt|crypto|bcrypt|argon2|scrypt|aes|AES)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "encryption_used" "true"
        score=$((score + 1))
    fi

    # Check for data retention policies
    if grep -rqE "(retention|expire|ttl|TTL|maxAge|purge.*old)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.yaml" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "data_retention" "true"
        score=$((score + 1))
    fi

    # Check for PII handling
    if grep -rqE "(pii|PII|personal.*data|PersonalData|sensitiveField)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "pii_handling" "true"
        score=$((score + 1))
        echo "Scanning: Found PII handling patterns" >&2
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Industry-Specific Compliance (Parameters 378-379)
# =============================================================================
check_industry() {
    progress_step "Industry-specific compliance"
    local score=5

    # Check for HIPAA patterns
    if grep -rqE "(hipaa|HIPAA|phi|PHI|health.*data|medical)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.md" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "hipaa_relevant" "true"
        score=$((score + 1))
        echo "Scanning: Found HIPAA-related patterns" >&2
    fi

    # Check for PCI-DSS patterns
    if grep -rqE "(pci|PCI|credit.*card|card.*number|payment|stripe|braintree)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "pci_relevant" "true"
        
        # Check for tokenization
        if grep -rqE "(token|Token|tokenize)" "$CODEBASE_PATH" \
            --include="*.ts" --include="*.js" --include="*.py" \
            --exclude-dir=node_modules 2>/dev/null; then
            log_metric "payment_tokenization" "true"
            score=$((score + 2))
        fi
    fi

    # Check for accessibility compliance
    if grep -rqE "(wcag|WCAG|a11y|aria|accessibility)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.tsx" --include="*.js" --include="*.md" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "accessibility_compliance" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Compliance Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local privacy_score=$(check_privacy)
    local security_score=$(check_security_compliance)
    local license_score=$(check_license)
    local data_score=$(check_data_handling)
    local industry_score=$(check_industry)

    # Weighted average
    local total_score=$(math_calc "$privacy_score * 0.25 + $security_score * 0.25 + $license_score * 0.15 + $data_score * 0.20 + $industry_score * 0.15")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 12')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg ps "$privacy_score" \
        --arg ss "$security_score" \
        --arg ls "$license_score" \
        --arg ds "$data_score" \
        --arg is "$industry_score" \
        '.subscores = {
            privacy: ($ps | tonumber),
            security_compliance: ($ss | tonumber),
            license: ($ls | tonumber),
            data_handling: ($ds | tonumber),
            industry_specific: ($is | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Compliance Score: $total_score/10"
}

main
