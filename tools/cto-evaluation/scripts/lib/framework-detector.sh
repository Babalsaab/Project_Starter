#!/bin/bash

# =============================================================================
# Enhanced Framework Detection
# =============================================================================
# Detects frameworks, languages, and project types with high accuracy.
# =============================================================================

detect_project_type() {
    local codebase="$1"
    local detected=()
    
    # --- JavaScript/TypeScript Ecosystem ---
    if [ -f "$codebase/package.json" ]; then
        local pkg_content
        pkg_content=$(cat "$codebase/package.json" 2>/dev/null)
        
        # React ecosystem
        if echo "$pkg_content" | grep -qE '"(react|react-dom)"'; then
            if echo "$pkg_content" | grep -qE '"next"'; then
                detected+=("nextjs")
            elif echo "$pkg_content" | grep -qE '"gatsby"'; then
                detected+=("gatsby")
            elif echo "$pkg_content" | grep -qE '"remix"'; then
                detected+=("remix")
            else
                detected+=("react")
            fi
        fi
        
        # Vue ecosystem
        if echo "$pkg_content" | grep -qE '"vue"'; then
            if echo "$pkg_content" | grep -qE '"nuxt"'; then
                detected+=("nuxt")
            else
                detected+=("vue")
            fi
        fi
        
        # Angular
        if echo "$pkg_content" | grep -qE '"@angular/core"'; then
            detected+=("angular")
        fi
        
        # Svelte
        if echo "$pkg_content" | grep -qE '"svelte"'; then
            if echo "$pkg_content" | grep -qE '"@sveltejs/kit"'; then
                detected+=("sveltekit")
            else
                detected+=("svelte")
            fi
        fi
        
        # Backend frameworks
        if echo "$pkg_content" | grep -qE '"express"'; then
            detected+=("express")
        fi
        if echo "$pkg_content" | grep -qE '"@nestjs/core"'; then
            detected+=("nestjs")
        fi
        if echo "$pkg_content" | grep -qE '"fastify"'; then
            detected+=("fastify")
        fi
        if echo "$pkg_content" | grep -qE '"hapi"'; then
            detected+=("hapi")
        fi
        if echo "$pkg_content" | grep -qE '"koa"'; then
            detected+=("koa")
        fi
        
        # TypeScript
        if [ -f "$codebase/tsconfig.json" ] || echo "$pkg_content" | grep -qE '"typescript"'; then
            detected+=("typescript")
        fi
        
        # Testing frameworks
        if echo "$pkg_content" | grep -qE '"jest"'; then
            detected+=("jest")
        fi
        if echo "$pkg_content" | grep -qE '"vitest"'; then
            detected+=("vitest")
        fi
        if echo "$pkg_content" | grep -qE '"cypress"'; then
            detected+=("cypress")
        fi
        if echo "$pkg_content" | grep -qE '"playwright"'; then
            detected+=("playwright")
        fi
        
        # ORMs
        if echo "$pkg_content" | grep -qE '"prisma"'; then
            detected+=("prisma")
        fi
        if echo "$pkg_content" | grep -qE '"typeorm"'; then
            detected+=("typeorm")
        fi
        if echo "$pkg_content" | grep -qE '"sequelize"'; then
            detected+=("sequelize")
        fi
        if echo "$pkg_content" | grep -qE '"mongoose"'; then
            detected+=("mongoose")
        fi
    fi
    
    # --- Python Ecosystem ---
    local python_deps=""
    if [ -f "$codebase/requirements.txt" ]; then
        python_deps=$(cat "$codebase/requirements.txt" 2>/dev/null)
    fi
    if [ -f "$codebase/pyproject.toml" ]; then
        python_deps="$python_deps $(cat "$codebase/pyproject.toml" 2>/dev/null)"
    fi
    if [ -f "$codebase/Pipfile" ]; then
        python_deps="$python_deps $(cat "$codebase/Pipfile" 2>/dev/null)"
    fi
    if [ -f "$codebase/setup.py" ]; then
        python_deps="$python_deps $(cat "$codebase/setup.py" 2>/dev/null)"
    fi
    
    if [ -n "$python_deps" ]; then
        detected+=("python")
        
        if echo "$python_deps" | grep -qiE "django"; then
            detected+=("django")
        fi
        if echo "$python_deps" | grep -qiE "fastapi"; then
            detected+=("fastapi")
        fi
        if echo "$python_deps" | grep -qiE "flask"; then
            detected+=("flask")
        fi
        if echo "$python_deps" | grep -qiE "starlette"; then
            detected+=("starlette")
        fi
        if echo "$python_deps" | grep -qiE "pytorch|torch"; then
            detected+=("pytorch")
        fi
        if echo "$python_deps" | grep -qiE "tensorflow|keras"; then
            detected+=("tensorflow")
        fi
        if echo "$python_deps" | grep -qiE "sqlalchemy"; then
            detected+=("sqlalchemy")
        fi
        if echo "$python_deps" | grep -qiE "celery"; then
            detected+=("celery")
        fi
        if echo "$python_deps" | grep -qiE "pytest"; then
            detected+=("pytest")
        fi
    fi
    
    # --- Go Ecosystem ---
    if [ -f "$codebase/go.mod" ]; then
        detected+=("go")
        local go_mod
        go_mod=$(cat "$codebase/go.mod" 2>/dev/null)
        
        if echo "$go_mod" | grep -qE "gin-gonic/gin"; then
            detected+=("gin")
        fi
        if echo "$go_mod" | grep -qE "labstack/echo"; then
            detected+=("echo")
        fi
        if echo "$go_mod" | grep -qE "gofiber/fiber"; then
            detected+=("fiber")
        fi
        if echo "$go_mod" | grep -qE "gorilla/mux"; then
            detected+=("gorilla")
        fi
        if echo "$go_mod" | grep -qE "go-chi/chi"; then
            detected+=("chi")
        fi
        if echo "$go_mod" | grep -qE "gorm.io/gorm"; then
            detected+=("gorm")
        fi
    fi
    
    # --- Java Ecosystem ---
    if [ -f "$codebase/pom.xml" ]; then
        detected+=("java" "maven")
        local pom
        pom=$(cat "$codebase/pom.xml" 2>/dev/null)
        
        if echo "$pom" | grep -qE "spring-boot"; then
            detected+=("spring-boot")
        fi
        if echo "$pom" | grep -qE "quarkus"; then
            detected+=("quarkus")
        fi
        if echo "$pom" | grep -qE "micronaut"; then
            detected+=("micronaut")
        fi
    fi
    
    if [ -f "$codebase/build.gradle" ] || [ -f "$codebase/build.gradle.kts" ]; then
        detected+=("java" "gradle")
        local gradle
        gradle=$(cat "$codebase/build.gradle" "$codebase/build.gradle.kts" 2>/dev/null)
        
        if echo "$gradle" | grep -qE "spring-boot|org.springframework.boot"; then
            detected+=("spring-boot")
        fi
        if echo "$gradle" | grep -qE "kotlin"; then
            detected+=("kotlin")
        fi
    fi
    
    # --- Rust Ecosystem ---
    if [ -f "$codebase/Cargo.toml" ]; then
        detected+=("rust")
        local cargo
        cargo=$(cat "$codebase/Cargo.toml" 2>/dev/null)
        
        if echo "$cargo" | grep -qE "actix-web"; then
            detected+=("actix")
        fi
        if echo "$cargo" | grep -qE "rocket"; then
            detected+=("rocket")
        fi
        if echo "$cargo" | grep -qE "axum"; then
            detected+=("axum")
        fi
        if echo "$cargo" | grep -qE "tokio"; then
            detected+=("tokio")
        fi
    fi
    
    # --- Ruby Ecosystem ---
    if [ -f "$codebase/Gemfile" ]; then
        detected+=("ruby")
        local gemfile
        gemfile=$(cat "$codebase/Gemfile" 2>/dev/null)
        
        if echo "$gemfile" | grep -qE "rails"; then
            detected+=("rails")
        fi
        if echo "$gemfile" | grep -qE "sinatra"; then
            detected+=("sinatra")
        fi
    fi
    
    # --- PHP Ecosystem ---
    if [ -f "$codebase/composer.json" ]; then
        detected+=("php")
        local composer
        composer=$(cat "$codebase/composer.json" 2>/dev/null)
        
        if echo "$composer" | grep -qE "laravel/framework"; then
            detected+=("laravel")
        fi
        if echo "$composer" | grep -qE "symfony/framework"; then
            detected+=("symfony")
        fi
    fi
    
    # --- .NET Ecosystem ---
    local csproj_files=$(find "$codebase" -maxdepth 3 -name "*.csproj" 2>/dev/null | head -1)
    if [ -n "$csproj_files" ]; then
        detected+=("dotnet" "csharp")
        
        local csproj
        csproj=$(find "$codebase" -maxdepth 3 -name "*.csproj" -exec cat {} \; 2>/dev/null)
        
        if echo "$csproj" | grep -qE "Microsoft.AspNetCore"; then
            detected+=("aspnet")
        fi
    fi
    
    # --- Elixir Ecosystem ---
    if [ -f "$codebase/mix.exs" ]; then
        detected+=("elixir")
        local mix
        mix=$(cat "$codebase/mix.exs" 2>/dev/null)
        
        if echo "$mix" | grep -qE ":phoenix"; then
            detected+=("phoenix")
        fi
    fi
    
    # Determine primary language
    local primary_lang="unknown"
    for lang in typescript javascript python go java rust ruby php csharp elixir; do
        if [[ " ${detected[*]} " =~ " $lang " ]]; then
            primary_lang="$lang"
            break
        fi
    done
    
    # Return as JSON
    local frameworks_json=$(printf '%s\n' "${detected[@]}" | sort -u | jq -R . | jq -s .)
    
    cat << EOF
{
    "primary_language": "$primary_lang",
    "frameworks": $frameworks_json,
    "detected_count": ${#detected[@]}
}
EOF
}

# Detect project architecture type
detect_architecture() {
    local codebase="$1"
    local arch_type="unknown"
    local confidence=0
    
    # Check for monorepo indicators
    local has_workspaces=false
    local has_lerna=false
    local has_nx=false
    local has_turborepo=false
    
    if [ -f "$codebase/package.json" ]; then
        local pkg
        pkg=$(cat "$codebase/package.json" 2>/dev/null)
        if echo "$pkg" | grep -qE '"workspaces"'; then
            has_workspaces=true
        fi
    fi
    [ -f "$codebase/lerna.json" ] && has_lerna=true
    [ -f "$codebase/nx.json" ] && has_nx=true
    [ -f "$codebase/turbo.json" ] && has_turborepo=true
    
    if $has_workspaces || $has_lerna || $has_nx || $has_turborepo; then
        arch_type="monorepo"
        confidence=90
    fi
    
    # Check for microservices indicators
    local service_dirs
    service_dirs=$(find "$codebase" -maxdepth 2 -type d \( -name "services" -o -name "microservices" -o -name "apps" \) 2>/dev/null | head -1)
    if [ -n "$service_dirs" ]; then
        local service_count
        service_count=$(find "$service_dirs" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        if [ "$service_count" -gt 2 ]; then
            if [ "$arch_type" = "monorepo" ]; then
                arch_type="monorepo-microservices"
            else
                arch_type="microservices"
            fi
            confidence=80
        fi
    fi
    
    # Check for serverless
    if [ -f "$codebase/serverless.yml" ] || [ -f "$codebase/serverless.yaml" ] || \
       [ -f "$codebase/template.yaml" ] || [ -f "$codebase/sam.yaml" ] || \
       [ -d "$codebase/functions" ] || [ -d "$codebase/lambdas" ]; then
        arch_type="serverless"
        confidence=85
    fi
    
    # Check for traditional MVC
    if [ -d "$codebase/controllers" ] || [ -d "$codebase/views" ] || \
       [ -d "$codebase/app/controllers" ] || [ -d "$codebase/app/views" ]; then
        if [ "$arch_type" = "unknown" ]; then
            arch_type="mvc"
            confidence=75
        fi
    fi
    
    # Check for clean/hexagonal architecture
    if [ -d "$codebase/domain" ] || [ -d "$codebase/infrastructure" ] || \
       [ -d "$codebase/application" ] || [ -d "$codebase/core" ]; then
        if [ "$arch_type" = "unknown" ] || [ "$arch_type" = "mvc" ]; then
            arch_type="clean-architecture"
            confidence=70
        fi
    fi
    
    # Fallback: Check if it's a library/package
    if [ "$arch_type" = "unknown" ]; then
        if [ -f "$codebase/index.js" ] || [ -f "$codebase/index.ts" ] || \
           [ -f "$codebase/lib/index.js" ] || [ -f "$codebase/src/index.ts" ]; then
            if [ -f "$codebase/package.json" ]; then
                local pkg
                pkg=$(cat "$codebase/package.json" 2>/dev/null)
                if echo "$pkg" | grep -qE '"main"|"module"|"exports"'; then
                    arch_type="library"
                    confidence=70
                fi
            fi
        fi
    fi
    
    cat << EOF
{
    "type": "$arch_type",
    "confidence": $confidence
}
EOF
}

# Detect database technologies
detect_databases() {
    local codebase="$1"
    local databases=()
    
    # Search for database connection strings and imports
    local db_patterns=(
        "mongodb|mongoose:mongodb"
        "postgres|pg|psycopg:postgresql"
        "mysql|mysql2:mysql"
        "sqlite|sqlite3:sqlite"
        "redis|ioredis:redis"
        "elasticsearch|@elastic:elasticsearch"
        "dynamodb|@aws-sdk/client-dynamodb:dynamodb"
        "cassandra|datastax:cassandra"
        "neo4j:neo4j"
        "firebase|firestore:firebase"
        "supabase:supabase"
        "prisma:prisma"
        "typeorm:typeorm"
        "sequelize:sequelize"
        "gorm:gorm"
        "sqlalchemy:sqlalchemy"
        "hibernate:hibernate"
    )
    
    for pattern_pair in "${db_patterns[@]}"; do
        local pattern="${pattern_pair%%:*}"
        local db_name="${pattern_pair##*:}"
        
        if grep -rqlE "$pattern" "$codebase" \
            --include="*.js" --include="*.ts" --include="*.py" --include="*.go" \
            --include="*.java" --include="*.rb" --include="*.rs" --include="*.php" \
            --include="*.json" --include="*.yaml" --include="*.yml" --include="*.toml" \
            --include="*.env*" --include="docker-compose*" \
            --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
            2>/dev/null; then
            databases+=("$db_name")
        fi
    done
    
    # Check docker-compose for database services
    if [ -f "$codebase/docker-compose.yml" ] || [ -f "$codebase/docker-compose.yaml" ]; then
        local compose
        compose=$(cat "$codebase/docker-compose.yml" "$codebase/docker-compose.yaml" 2>/dev/null)
        
        echo "$compose" | grep -qE "image:.*postgres" && databases+=("postgresql")
        echo "$compose" | grep -qE "image:.*mysql|image:.*mariadb" && databases+=("mysql")
        echo "$compose" | grep -qE "image:.*mongo" && databases+=("mongodb")
        echo "$compose" | grep -qE "image:.*redis" && databases+=("redis")
        echo "$compose" | grep -qE "image:.*elasticsearch" && databases+=("elasticsearch")
    fi
    
    printf '%s\n' "${databases[@]}" | sort -u | tr '\n' ' '
}

# Export functions
export -f detect_project_type 2>/dev/null || true
export -f detect_architecture 2>/dev/null || true
export -f detect_databases 2>/dev/null || true
