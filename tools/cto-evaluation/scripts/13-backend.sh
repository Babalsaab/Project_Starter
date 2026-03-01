#!/bin/bash

# =============================================================================
# BACKEND ENGINEERING EVALUATION (Parameters 341-360)
# =============================================================================
# Evaluates:
#   - Service Implementation (283-294)
#   - Real-Time & Communication (295-302)
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
    "category": "backend",
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
# Check Service Layer Architecture (Parameters 308-311)
# =============================================================================
check_service_architecture() {
    progress_step "Service layer architecture"
    local score=5

    # Check for service/controller separation
    local service_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*service*.ts" -o -name "*service*.js" -o -name "*service*.py" -o \
        -name "*Service*.java" -o -name "*_service.py" \
        \) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l)
    
    local controller_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*controller*.ts" -o -name "*controller*.js" -o \
        -name "*Controller*.java" -o -name "*views*.py" \
        \) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l)

    log_metric "service_files" "$service_files"
    log_metric "controller_files" "$controller_files"
    echo "Scanning: Found $service_files service files, $controller_files controller files" >&2

    if [ "$service_files" -gt 10 ] && [ "$controller_files" -gt 5 ]; then
        score=8
    elif [ "$service_files" -gt 5 ]; then
        score=7
    elif [ "$service_files" -eq 0 ]; then
        add_finding "medium" "architecture" "No service layer separation found"
    fi

    # Check for dependency injection
    if grep -rqE "(@Injectable|@Inject|@Autowired|@Service|container\.resolve|inject)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.java" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "dependency_injection" "true"
        score=$((score + 1))
        echo "Scanning: Found dependency injection patterns" >&2
    fi

    # Check for repository pattern
    local repo_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*repository*.ts" -o -name "*Repository*.java" -o -name "*repo*.py" \
        \) ! -path "*/node_modules/*" 2>/dev/null | wc -l)
    
    if [ "$repo_files" -gt 0 ]; then
        log_metric "repository_pattern" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Middleware Pipeline (Parameter 285)
# =============================================================================
check_middleware() {
    progress_step "Middleware pipeline"
    local score=5

    # Count middleware files/usage
    local middleware_count=$(grep -rcE "(app\.use\(|middleware|Middleware|@UseGuards|@UseInterceptors)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=test* 2>/dev/null | \
        awk -F: '{sum += $2} END {print sum+0}')
    
    log_metric "middleware_usage" "$middleware_count"
    echo "Scanning: Found $middleware_count middleware usages" >&2

    if [ "$middleware_count" -gt 20 ]; then
        score=8
    elif [ "$middleware_count" -gt 10 ]; then
        score=7
    elif [ "$middleware_count" -lt 3 ]; then
        add_finding "low" "backend" "Very few middleware patterns found"
    fi

    # Check for guards/interceptors
    if grep -rqE "(@Guard|@Interceptor|CanActivate|NestInterceptor|beforeRequest)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "guards_interceptors" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Background Jobs (Parameters 313-314)
# =============================================================================
check_background_jobs() {
    progress_step "Background jobs and scheduling"
    local score=5

    # Check for job/queue libraries
    if grep -rqE "(bull|agenda|bee-queue|celery|rq|sidekiq|@Cron|@Interval|node-cron)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "job_queue" "true"
        score=8
        echo "Scanning: Found job/queue implementation" >&2
    fi

    # Check for scheduled tasks
    if grep -rqE "(cron|schedule|@Scheduled|setInterval|setTimeout.*recurring)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "scheduled_tasks" "true"
        score=$((score + 1))
    fi

    # Check for worker files
    local worker_files=$(find "$CODEBASE_PATH" -type f \( \
        -name "*worker*.ts" -o -name "*worker*.js" -o -name "*job*.py" -o \
        -name "*processor*.ts" \
        \) ! -path "*/node_modules/*" 2>/dev/null | wc -l)
    
    if [ "$worker_files" -gt 0 ]; then
        log_metric "worker_files" "$worker_files"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check Real-Time Features (Parameters 318-325)
# =============================================================================
check_realtime() {
    progress_step "Real-time features"
    local score=5

    # Check for WebSocket
    if grep -rqE "(WebSocket|socket\.io|ws|@WebSocketGateway|@SubscribeMessage|channels)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "websocket" "true"
        score=$((score + 2))
        echo "Scanning: Found WebSocket implementation" >&2
    fi

    # Check for Server-Sent Events
    if grep -rqE "(SSE|EventSource|text/event-stream|server-sent)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "sse" "true"
        score=$((score + 1))
    fi

    # Check for pub/sub
    if grep -rqE "(publish|subscribe|pubsub|PubSub|emit|broadcast)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" \
        --exclude-dir=node_modules --exclude-dir=test* 2>/dev/null; then
        log_metric "pubsub" "true"
        score=$((score + 1))
    fi

    # Check for message queue integration
    if grep -rqE "(rabbitmq|kafka|sqs|amqp)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "message_queue" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Check File & Email Services (Parameters 315-317)
# =============================================================================
check_services() {
    progress_step "File and notification services"
    local score=5

    # Check for file upload handling
    if grep -rqE "(multer|busboy|formidable|multipart|FileInterceptor|UploadedFile)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        log_metric "file_upload" "true"
        score=$((score + 1))
        echo "Scanning: Found file upload handling" >&2
    fi

    # Check for cloud storage
    if grep -rqE "(s3|S3|minio|cloudinary|azure.*blob|gcs|@google-cloud/storage)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "cloud_storage" "true"
        score=$((score + 1))
    fi

    # Check for email service
    if grep -rqE "(nodemailer|sendgrid|ses|mailgun|postmark|smtp)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "email_service" "true"
        score=$((score + 1))
        echo "Scanning: Found email service" >&2
    fi

    # Check for push notifications
    if grep -rqE "(firebase.*messaging|FCM|push.*notification|expo-notifications|apn|onesignal)" "$CODEBASE_PATH" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.json" \
        --exclude-dir=node_modules 2>/dev/null; then
        log_metric "push_notifications" "true"
        score=$((score + 1))
    fi

    [ "$score" -gt 10 ] && score=10
    echo "$score"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "Starting Backend Evaluation..."
    echo "Codebase: $CODEBASE_PATH"

    local service_score=$(check_service_architecture)
    local middleware_score=$(check_middleware)
    local jobs_score=$(check_background_jobs)
    local realtime_score=$(check_realtime)
    local services_score=$(check_services)

    # Weighted average
    local total_score=$(math_calc "$service_score * 0.25 + $middleware_score * 0.20 + $jobs_score * 0.20 + $realtime_score * 0.20 + $services_score * 0.15")

    RESULTS=$(echo "$RESULTS" | jq --arg score "$total_score" '.score = ($score | tonumber)')
    RESULTS=$(echo "$RESULTS" | jq '.parameters_evaluated = 20')
    RESULTS=$(echo "$RESULTS" | jq \
        --arg ss "$service_score" \
        --arg ms "$middleware_score" \
        --arg js "$jobs_score" \
        --arg rs "$realtime_score" \
        --arg svs "$services_score" \
        '.subscores = {
            service_architecture: ($ss | tonumber),
            middleware: ($ms | tonumber),
            background_jobs: ($js | tonumber),
            realtime: ($rs | tonumber),
            services: ($svs | tonumber)
        }')

    # Merge findings from subshells
    RESULTS=$(merge_findings "$RESULTS")

    echo "$RESULTS" | jq '.' > "$OUTPUT_FILE"
    echo "Backend Score: $total_score/10"
}

main
