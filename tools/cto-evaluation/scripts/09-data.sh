#!/bin/bash

# =============================================================================
# DATA ARCHITECTURE & MANAGEMENT EVALUATION (Parameters 275-294)
# =============================================================================
# Evaluates:
#   - Data Modeling (217-226)
#   - Data Operations (227-236)
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
    "category": "data_architecture",
    "parameters_evaluated": 0,
    "parameters_total": 20,
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
# Check Schema Design (Parameters 240-243)
# =============================================================================
check_schema_design() {
    progress_step "Schema design patterns"
    local score=5

    # Check for ORM/schema definitions
    local schema_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*.prisma" -o \
        -name "*schema*.ts" -o \
        -name "*model*.py" -o \
        -name "*entity*.java" -o \
        -name "*migration*" \
        \) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l)
    
    log_metric "schema_files" "$schema_files"
    echo "Scanning: Found $schema_files schema/model files" >&2

    if [ "$schema_files" -gt 10 ]; then
        score=8
    elif [ "$schema_files" -gt 5 ]; then
        score=6
    elif [ "$schema_files" -eq 0 ]; then
        add_finding "medium" "schema" "No schema definition files found"
        score=4
    fi

    # Check for TypeORM/Prisma/Sequelize
    if grep -rqE "(prisma|typeorm|sequelize|mongoose|sqlalchemy|django\.db)" "$CODEBASE_PATH" \
        --include="*.json" --include="*.ts" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "orm_used" "true"
        score=$((score + 1))
        echo "Scanning: ORM detected" >&2
    fi

    # Check for constraints
    if grep -rqE "(@Unique|@Index|@Check|unique:|index:|foreign.*key|ForeignKey|constraint)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.py" --include="*.prisma" --include="*.sql" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "constraints_defined" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Audit Fields (Parameter 222)
# =============================================================================
check_audit_fields() {
    progress_step "Audit fields and timestamps"
    local score=5

    # Check for created/updated timestamps
    if grep -rqE "(createdAt|created_at|updatedAt|updated_at|@CreateDateColumn|@UpdateDateColumn|auto_now)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.py" --include="*.prisma" --include="*.java" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "timestamp_fields" "true"
        score=$((score + 2))
        echo "Scanning: Found timestamp audit fields" >&2
    else
        add_finding "medium" "data" "No created/updated timestamp fields found"
    fi

    # Check for soft delete
    if grep -rqE "(deletedAt|deleted_at|isDeleted|is_deleted|softDelete|paranoid)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.py" --include="*.prisma" --include="*.java" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "soft_delete" "true"
        score=$((score + 1))
        echo "Scanning: Found soft delete pattern" >&2
    fi

    # Check for created_by/updated_by
    if grep -rqE "(createdBy|created_by|updatedBy|updated_by|author|modified_by)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.py" --include="*.prisma" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "actor_tracking" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Migration Strategy (Parameters 250-251)
# =============================================================================
check_migrations() {
    progress_step "Migration strategy"
    local score=5

    # Count migration files
    local migration_count=$(find "$CODEBASE_PATH" -type f \( \
        -name "*migration*" -o \
        -path "*/migrations/*" -o \
        -path "*/db/migrate/*" \
        \) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l)
    
    log_metric "migration_files" "$migration_count"
    echo "Scanning: Found $migration_count migration files" >&2

    if [ "$migration_count" -gt 20 ]; then
        score=8
    elif [ "$migration_count" -gt 5 ]; then
        score=7
    elif [ "$migration_count" -eq 0 ]; then
        add_finding "high" "data" "No database migration files found"
        score=3
    fi

    # Check for reversible migrations
    if grep -rqE "(down|rollback|revert|undo)" "$CODEBASE_PATH" \
        --include="*migration*" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "reversible_migrations" "true"
        score=$((score + 1))
    else
        add_finding "medium" "migrations" "Migrations may not be reversible"
    fi

    # Check for seed data
    if find "$CODEBASE_PATH" -type f \( -name "*seed*" -o -name "*fixture*" \) \
        ! -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
        log_metric "seed_data" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Data Validation (Parameter 229)
# =============================================================================
check_validation() {
    progress_step "Data validation"
    local score=5

    # Check for validation libraries/decorators
    if grep -rqE "(class-validator|joi|yup|zod|@IsString|@IsEmail|@IsNotEmpty|validator|pydantic)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "validation_library" "true"
        score=8
        echo "Scanning: Found validation library" >&2
    else
        add_finding "medium" "validation" "No validation library found"
    fi

    # Check for schema validation
    if grep -rqE "(schema\.validate|validate\(|validateSync|parseAsync|safeParse)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "schema_validation" "true"
        score=$((score + 1))
    fi

    # Check for input sanitization
    if grep -rqE "(sanitize|escape|xss|DOMPurify|bleach|html\.escape)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "input_sanitization" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Data Sync & Caching (Parameters 257-258)
# =============================================================================
check_data_sync() {
    progress_step "Data synchronization and caching"
    local score=5

    # Check for cache invalidation patterns
    if grep -rqE "(invalidate|cache\.del|cache\.clear|evict|flush.*cache)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "cache_invalidation" "true"
        score=$((score + 2))
        echo "Scanning: Found cache invalidation patterns" >&2
    fi

    # Check for ETL patterns
    if grep -rqE "(etl|ETL|transform|extract|pipeline|batch.*job|@Scheduled)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.yaml" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "etl_patterns" "true"
        score=$((score + 1))
    fi

    # Check for event sourcing
    if grep -rqE "(event.*store|EventStore|EventSourcing|aggregate.*root|DomainEvent)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "event_sourcing" "true"
        score=$((score + 2))
        echo "Scanning: Found event sourcing patterns" >&2
    fi

    # Check for data archival
    if grep -rqE "(archive|Archive|retention|purge|cleanup.*old)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "data_archival" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Data Architecture Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local schema_score=$(check_schema_design)
    local audit_score=$(check_audit_fields)
    local migration_score=$(check_migrations)
    local validation_score=$(check_validation)
    local sync_score=$(check_data_sync)

    # Weighted average
    local total_score=$(math_calc "$schema_score * 0.25 + $audit_score * 0.15 + $migration_score * 0.25 + $validation_score * 0.20 + $sync_score * 0.15")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 20')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg ss "$schema_score" \
        --arg as "$audit_score" \
        --arg ms "$migration_score" \
        --arg vs "$validation_score" \
        --arg syncs "$sync_score" \
        '.subscores = {
            schema_design: ($ss | tonumber),
            audit_fields: ($as | tonumber),
            migrations: ($ms | tonumber),
            validation: ($vs | tonumber),
            data_sync: ($syncs | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Data Architecture Score: $total_score/10"
}

main
