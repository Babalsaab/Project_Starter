#!/bin/bash

# =============================================================================
# ADVANCED CODEBASE ANALYZER
# =============================================================================
# Provides deep analysis capabilities for more accurate evaluations:
#   - Intelligent language/framework detection
#   - Project structure analysis
#   - Build system detection
#   - Dependency graph analysis
#   - Code metrics extraction
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# LANGUAGE & FRAMEWORK DETECTION
# =============================================================================

detect_languages_advanced() {
    local codebase="$1"
    local output_file="${2:-/dev/stdout}"
    
    local result='{}'
    
    # Count files by extension with proper exclusions
    local exclusions="-not -path */node_modules/* -not -path */.git/* -not -path */vendor/* -not -path */dist/* -not -path */build/* -not -path */__pycache__/* -not -path */.venv/* -not -path */venv/*"
    
    # JavaScript/TypeScript
    local js_count=$(find "$codebase" -type f \( -name "*.js" -o -name "*.jsx" \) $exclusions 2>/dev/null | wc -l | tr -d ' ')
    local ts_count=$(find "$codebase" -type f \( -name "*.ts" -o -name "*.tsx" \) $exclusions 2>/dev/null | wc -l | tr -d ' ')
    
    # Python
    local py_count=$(find "$codebase" -type f -name "*.py" $exclusions 2>/dev/null | wc -l | tr -d ' ')
    
    # Go
    local go_count=$(find "$codebase" -type f -name "*.go" $exclusions 2>/dev/null | wc -l | tr -d ' ')
    
    # Java/Kotlin
    local java_count=$(find "$codebase" -type f -name "*.java" $exclusions 2>/dev/null | wc -l | tr -d ' ')
    local kotlin_count=$(find "$codebase" -type f -name "*.kt" $exclusions 2>/dev/null | wc -l | tr -d ' ')
    
    # Ruby
    local ruby_count=$(find "$codebase" -type f -name "*.rb" $exclusions 2>/dev/null | wc -l | tr -d ' ')
    
    # Rust
    local rust_count=$(find "$codebase" -type f -name "*.rs" $exclusions 2>/dev/null | wc -l | tr -d ' ')
    
    # C/C++
    local c_count=$(find "$codebase" -type f \( -name "*.c" -o -name "*.h" \) $exclusions 2>/dev/null | wc -l | tr -d ' ')
    local cpp_count=$(find "$codebase" -type f \( -name "*.cpp" -o -name "*.cc" -o -name "*.hpp" \) $exclusions 2>/dev/null | wc -l | tr -d ' ')
    
    # C#
    local csharp_count=$(find "$codebase" -type f -name "*.cs" $exclusions 2>/dev/null | wc -l | tr -d ' ')
    
    # PHP
    local php_count=$(find "$codebase" -type f -name "*.php" $exclusions 2>/dev/null | wc -l | tr -d ' ')
    
    # Swift
    local swift_count=$(find "$codebase" -type f -name "*.swift" $exclusions 2>/dev/null | wc -l | tr -d ' ')
    
    # Shell
    local shell_count=$(find "$codebase" -type f \( -name "*.sh" -o -name "*.bash" \) $exclusions 2>/dev/null | wc -l | tr -d ' ')
    
    # Build result
    result=$(jq -n \
        --argjson js "$js_count" \
        --argjson ts "$ts_count" \
        --argjson py "$py_count" \
        --argjson go "$go_count" \
        --argjson java "$java_count" \
        --argjson kotlin "$kotlin_count" \
        --argjson ruby "$ruby_count" \
        --argjson rust "$rust_count" \
        --argjson c "$c_count" \
        --argjson cpp "$cpp_count" \
        --argjson csharp "$csharp_count" \
        --argjson php "$php_count" \
        --argjson swift "$swift_count" \
        --argjson shell "$shell_count" \
        '{
            languages: {
                javascript: {files: $js, detected: ($js > 0)},
                typescript: {files: $ts, detected: ($ts > 0)},
                python: {files: $py, detected: ($py > 0)},
                go: {files: $go, detected: ($go > 0)},
                java: {files: $java, detected: ($java > 0)},
                kotlin: {files: $kotlin, detected: ($kotlin > 0)},
                ruby: {files: $ruby, detected: ($ruby > 0)},
                rust: {files: $rust, detected: ($rust > 0)},
                c: {files: $c, detected: ($c > 0)},
                cpp: {files: $cpp, detected: ($cpp > 0)},
                csharp: {files: $csharp, detected: ($csharp > 0)},
                php: {files: $php, detected: ($php > 0)},
                swift: {files: $swift, detected: ($swift > 0)},
                shell: {files: $shell, detected: ($shell > 0)}
            },
            primary_language: (
                if $ts > 0 and ($ts + $js) >= ($py + $go + $java + $ruby + $rust) then "typescript"
                elif $js > 0 and $js >= ($py + $go + $java + $ruby + $rust) then "javascript"
                elif $py >= ($js + $ts + $go + $java + $ruby + $rust) then "python"
                elif $go >= ($js + $ts + $py + $java + $ruby + $rust) then "go"
                elif $java >= ($js + $ts + $py + $go + $ruby + $rust) then "java"
                elif $ruby >= ($js + $ts + $py + $go + $java + $rust) then "ruby"
                elif $rust >= ($js + $ts + $py + $go + $java + $ruby) then "rust"
                elif $csharp > 0 then "csharp"
                elif $php > 0 then "php"
                elif $swift > 0 then "swift"
                elif $cpp > 0 then "cpp"
                elif $c > 0 then "c"
                else "unknown"
                end
            ),
            total_source_files: ($js + $ts + $py + $go + $java + $kotlin + $ruby + $rust + $c + $cpp + $csharp + $php + $swift)
        }')
    
    echo "$result"
}

# =============================================================================
# FRAMEWORK DETECTION
# =============================================================================

detect_frameworks() {
    local codebase="$1"
    local frameworks='{"frontend": [], "backend": [], "mobile": [], "testing": [], "build": []}'
    
    # ===== FRONTEND FRAMEWORKS =====
    
    # React
    if [ -f "$codebase/package.json" ]; then
        if grep -qE '"(react|react-dom)"' "$codebase/package.json" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.frontend += ["react"]')
            
            # Check for Next.js
            if grep -q '"next"' "$codebase/package.json" 2>/dev/null; then
                frameworks=$(echo "$frameworks" | jq '.frontend += ["nextjs"]')
            fi
            # Check for Gatsby
            if grep -q '"gatsby"' "$codebase/package.json" 2>/dev/null; then
                frameworks=$(echo "$frameworks" | jq '.frontend += ["gatsby"]')
            fi
            # Check for Remix
            if grep -q '"@remix-run"' "$codebase/package.json" 2>/dev/null; then
                frameworks=$(echo "$frameworks" | jq '.frontend += ["remix"]')
            fi
        fi
        
        # Vue
        if grep -q '"vue"' "$codebase/package.json" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.frontend += ["vue"]')
            if grep -q '"nuxt"' "$codebase/package.json" 2>/dev/null; then
                frameworks=$(echo "$frameworks" | jq '.frontend += ["nuxt"]')
            fi
        fi
        
        # Angular
        if grep -q '"@angular/core"' "$codebase/package.json" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.frontend += ["angular"]')
        fi
        
        # Svelte
        if grep -q '"svelte"' "$codebase/package.json" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.frontend += ["svelte"]')
            if grep -q '"@sveltejs/kit"' "$codebase/package.json" 2>/dev/null; then
                frameworks=$(echo "$frameworks" | jq '.frontend += ["sveltekit"]')
            fi
        fi
        
        # Solid
        if grep -q '"solid-js"' "$codebase/package.json" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.frontend += ["solid"]')
        fi
    fi
    
    # ===== BACKEND FRAMEWORKS =====
    
    # Node.js frameworks
    if [ -f "$codebase/package.json" ]; then
        # Express
        if grep -q '"express"' "$codebase/package.json" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["express"]')
        fi
        # Fastify
        if grep -q '"fastify"' "$codebase/package.json" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["fastify"]')
        fi
        # NestJS
        if grep -q '"@nestjs/core"' "$codebase/package.json" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["nestjs"]')
        fi
        # Hono
        if grep -q '"hono"' "$codebase/package.json" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["hono"]')
        fi
        # Koa
        if grep -q '"koa"' "$codebase/package.json" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["koa"]')
        fi
    fi
    
    # Python frameworks
    if [ -f "$codebase/requirements.txt" ] || [ -f "$codebase/pyproject.toml" ] || [ -f "$codebase/Pipfile" ]; then
        local py_deps=""
        [ -f "$codebase/requirements.txt" ] && py_deps=$(cat "$codebase/requirements.txt" 2>/dev/null)
        [ -f "$codebase/pyproject.toml" ] && py_deps="$py_deps $(cat "$codebase/pyproject.toml" 2>/dev/null)"
        [ -f "$codebase/Pipfile" ] && py_deps="$py_deps $(cat "$codebase/Pipfile" 2>/dev/null)"
        
        # Django
        if echo "$py_deps" | grep -qi "django" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["django"]')
            if echo "$py_deps" | grep -qi "djangorestframework\|django-rest-framework" 2>/dev/null; then
                frameworks=$(echo "$frameworks" | jq '.backend += ["django-rest-framework"]')
            fi
        fi
        # FastAPI
        if echo "$py_deps" | grep -qi "fastapi" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["fastapi"]')
        fi
        # Flask
        if echo "$py_deps" | grep -qi "flask" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["flask"]')
        fi
        # Starlette
        if echo "$py_deps" | grep -qi "starlette" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["starlette"]')
        fi
    fi
    
    # Go frameworks
    if [ -f "$codebase/go.mod" ]; then
        local go_deps=$(cat "$codebase/go.mod" 2>/dev/null)
        # Gin
        if echo "$go_deps" | grep -q "gin-gonic" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["gin"]')
        fi
        # Fiber
        if echo "$go_deps" | grep -q "gofiber" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["fiber"]')
        fi
        # Echo
        if echo "$go_deps" | grep -q "labstack/echo" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["echo"]')
        fi
    fi
    
    # Ruby frameworks
    if [ -f "$codebase/Gemfile" ]; then
        local rb_deps=$(cat "$codebase/Gemfile" 2>/dev/null)
        # Rails
        if echo "$rb_deps" | grep -q "rails" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["rails"]')
        fi
        # Sinatra
        if echo "$rb_deps" | grep -q "sinatra" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["sinatra"]')
        fi
    fi
    
    # Java frameworks
    if [ -f "$codebase/pom.xml" ] || [ -f "$codebase/build.gradle" ] || [ -f "$codebase/build.gradle.kts" ]; then
        local java_deps=""
        [ -f "$codebase/pom.xml" ] && java_deps=$(cat "$codebase/pom.xml" 2>/dev/null)
        [ -f "$codebase/build.gradle" ] && java_deps="$java_deps $(cat "$codebase/build.gradle" 2>/dev/null)"
        [ -f "$codebase/build.gradle.kts" ] && java_deps="$java_deps $(cat "$codebase/build.gradle.kts" 2>/dev/null)"
        
        # Spring Boot
        if echo "$java_deps" | grep -qi "spring-boot" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["spring-boot"]')
        fi
        # Micronaut
        if echo "$java_deps" | grep -qi "micronaut" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["micronaut"]')
        fi
        # Quarkus
        if echo "$java_deps" | grep -qi "quarkus" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["quarkus"]')
        fi
    fi
    
    # Rust frameworks
    if [ -f "$codebase/Cargo.toml" ]; then
        local rust_deps=$(cat "$codebase/Cargo.toml" 2>/dev/null)
        # Actix
        if echo "$rust_deps" | grep -q "actix-web" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["actix"]')
        fi
        # Axum
        if echo "$rust_deps" | grep -q "axum" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["axum"]')
        fi
        # Rocket
        if echo "$rust_deps" | grep -q "rocket" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.backend += ["rocket"]')
        fi
    fi
    
    # ===== MOBILE FRAMEWORKS =====
    
    # React Native
    if [ -f "$codebase/package.json" ] && grep -q '"react-native"' "$codebase/package.json" 2>/dev/null; then
        frameworks=$(echo "$frameworks" | jq '.mobile += ["react-native"]')
        if grep -q '"expo"' "$codebase/package.json" 2>/dev/null; then
            frameworks=$(echo "$frameworks" | jq '.mobile += ["expo"]')
        fi
    fi
    
    # Flutter
    if [ -f "$codebase/pubspec.yaml" ]; then
        frameworks=$(echo "$frameworks" | jq '.mobile += ["flutter"]')
    fi
    
    # iOS Native
    if [ -f "$codebase/Package.swift" ] || ls "$codebase"/*.xcodeproj 2>/dev/null | head -1 > /dev/null; then
        frameworks=$(echo "$frameworks" | jq '.mobile += ["ios-native"]')
    fi
    
    # Android Native
    if [ -f "$codebase/app/build.gradle" ] || [ -f "$codebase/app/build.gradle.kts" ]; then
        frameworks=$(echo "$frameworks" | jq '.mobile += ["android-native"]')
    fi
    
    # ===== TESTING FRAMEWORKS =====
    
    if [ -f "$codebase/package.json" ]; then
        local pkg=$(cat "$codebase/package.json" 2>/dev/null)
        
        [ "$(echo "$pkg" | jq -r '.devDependencies.jest // .dependencies.jest // empty')" != "" ] && \
            frameworks=$(echo "$frameworks" | jq '.testing += ["jest"]')
        [ "$(echo "$pkg" | jq -r '.devDependencies.vitest // .dependencies.vitest // empty')" != "" ] && \
            frameworks=$(echo "$frameworks" | jq '.testing += ["vitest"]')
        [ "$(echo "$pkg" | jq -r '.devDependencies.mocha // .dependencies.mocha // empty')" != "" ] && \
            frameworks=$(echo "$frameworks" | jq '.testing += ["mocha"]')
        [ "$(echo "$pkg" | jq -r '.devDependencies.cypress // .dependencies.cypress // empty')" != "" ] && \
            frameworks=$(echo "$frameworks" | jq '.testing += ["cypress"]')
        [ "$(echo "$pkg" | jq -r '.devDependencies.playwright // .dependencies.playwright // .devDependencies["@playwright/test"] // empty')" != "" ] && \
            frameworks=$(echo "$frameworks" | jq '.testing += ["playwright"]')
    fi
    
    # Python testing
    if [ -f "$codebase/requirements.txt" ] || [ -f "$codebase/pyproject.toml" ]; then
        local py_deps=""
        [ -f "$codebase/requirements.txt" ] && py_deps=$(cat "$codebase/requirements.txt" 2>/dev/null)
        [ -f "$codebase/pyproject.toml" ] && py_deps="$py_deps $(cat "$codebase/pyproject.toml" 2>/dev/null)"
        
        echo "$py_deps" | grep -qi "pytest" && frameworks=$(echo "$frameworks" | jq '.testing += ["pytest"]')
        echo "$py_deps" | grep -qi "unittest" && frameworks=$(echo "$frameworks" | jq '.testing += ["unittest"]')
    fi
    
    # ===== BUILD TOOLS =====
    
    # Webpack
    [ -f "$codebase/webpack.config.js" ] || [ -f "$codebase/webpack.config.ts" ] && \
        frameworks=$(echo "$frameworks" | jq '.build += ["webpack"]')
    
    # Vite
    [ -f "$codebase/vite.config.js" ] || [ -f "$codebase/vite.config.ts" ] && \
        frameworks=$(echo "$frameworks" | jq '.build += ["vite"]')
    
    # Rollup
    [ -f "$codebase/rollup.config.js" ] && frameworks=$(echo "$frameworks" | jq '.build += ["rollup"]')
    
    # esbuild
    [ -f "$codebase/package.json" ] && grep -q '"esbuild"' "$codebase/package.json" && \
        frameworks=$(echo "$frameworks" | jq '.build += ["esbuild"]')
    
    # Turbo
    [ -f "$codebase/turbo.json" ] && frameworks=$(echo "$frameworks" | jq '.build += ["turborepo"]')
    
    # Nx
    [ -f "$codebase/nx.json" ] && frameworks=$(echo "$frameworks" | jq '.build += ["nx"]')
    
    # Lerna
    [ -f "$codebase/lerna.json" ] && frameworks=$(echo "$frameworks" | jq '.build += ["lerna"]')
    
    echo "$frameworks"
}

# =============================================================================
# PROJECT TYPE DETECTION
# =============================================================================

detect_project_type() {
    local codebase="$1"
    local project_type="unknown"
    local characteristics='[]'
    
    # Monorepo detection
    if [ -f "$codebase/lerna.json" ] || [ -f "$codebase/turbo.json" ] || [ -f "$codebase/nx.json" ] || \
       [ -f "$codebase/pnpm-workspace.yaml" ] || [ -d "$codebase/packages" ]; then
        project_type="monorepo"
        characteristics=$(echo "$characteristics" | jq '. += ["monorepo"]')
    fi
    
    # Microservices detection
    if [ -d "$codebase/services" ] || [ -d "$codebase/apps" ]; then
        local service_count=$(ls -d "$codebase/services/"*/ "$codebase/apps/"*/ 2>/dev/null | wc -l | tr -d ' ')
        if [ "$service_count" -gt 2 ]; then
            characteristics=$(echo "$characteristics" | jq '. += ["microservices"]')
        fi
    fi
    
    # Library/Package detection
    if [ -f "$codebase/package.json" ]; then
        local pkg=$(cat "$codebase/package.json" 2>/dev/null)
        local has_main=$(echo "$pkg" | jq -r '.main // empty')
        local has_module=$(echo "$pkg" | jq -r '.module // empty')
        local has_types=$(echo "$pkg" | jq -r '.types // .typings // empty')
        
        if [ -n "$has_main" ] || [ -n "$has_module" ] || [ -n "$has_types" ]; then
            if ! echo "$pkg" | jq -e '.dependencies.react // .dependencies.vue // .dependencies.angular' > /dev/null 2>&1; then
                characteristics=$(echo "$characteristics" | jq '. += ["library"]')
            fi
        fi
    fi
    
    # API-only backend
    if ! find "$codebase" -maxdepth 3 -type f \( -name "*.html" -o -name "*.jsx" -o -name "*.tsx" -o -name "*.vue" -o -name "*.svelte" \) 2>/dev/null | grep -q .; then
        if [ -f "$codebase/package.json" ] || [ -f "$codebase/requirements.txt" ] || [ -f "$codebase/go.mod" ]; then
            characteristics=$(echo "$characteristics" | jq '. += ["api-backend"]')
        fi
    fi
    
    # Full-stack detection
    local has_frontend=false
    local has_backend=false
    
    if find "$codebase" -maxdepth 3 -type f \( -name "*.jsx" -o -name "*.tsx" -o -name "*.vue" -o -name "*.svelte" \) 2>/dev/null | grep -q .; then
        has_frontend=true
    fi
    
    if [ -f "$codebase/package.json" ] && grep -qE '"(express|fastify|nestjs|koa)"' "$codebase/package.json" 2>/dev/null; then
        has_backend=true
    fi
    
    if [ "$has_frontend" = true ] && [ "$has_backend" = true ]; then
        characteristics=$(echo "$characteristics" | jq '. += ["fullstack"]')
    elif [ "$has_frontend" = true ]; then
        characteristics=$(echo "$characteristics" | jq '. += ["frontend-only"]')
    fi
    
    # CLI tool detection
    if [ -f "$codebase/package.json" ]; then
        local has_bin=$(cat "$codebase/package.json" | jq -r '.bin // empty')
        if [ -n "$has_bin" ]; then
            characteristics=$(echo "$characteristics" | jq '. += ["cli-tool"]')
        fi
    fi
    
    # Determine primary type
    if echo "$characteristics" | jq -e 'contains(["monorepo"])' > /dev/null; then
        project_type="monorepo"
    elif echo "$characteristics" | jq -e 'contains(["microservices"])' > /dev/null; then
        project_type="microservices"
    elif echo "$characteristics" | jq -e 'contains(["library"])' > /dev/null; then
        project_type="library"
    elif echo "$characteristics" | jq -e 'contains(["fullstack"])' > /dev/null; then
        project_type="fullstack"
    elif echo "$characteristics" | jq -e 'contains(["api-backend"])' > /dev/null; then
        project_type="api"
    elif echo "$characteristics" | jq -e 'contains(["frontend-only"])' > /dev/null; then
        project_type="frontend"
    elif echo "$characteristics" | jq -e 'contains(["cli-tool"])' > /dev/null; then
        project_type="cli"
    fi
    
    jq -n --arg type "$project_type" --argjson chars "$characteristics" \
        '{project_type: $type, characteristics: $chars}'
}

# =============================================================================
# DATABASE DETECTION
# =============================================================================

detect_databases() {
    local codebase="$1"
    local databases='[]'
    
    # PostgreSQL
    if grep -rqE "(postgres|pg|psycopg|asyncpg)" "$codebase" \
        --include="*.json" --include="*.yaml" --include="*.yml" --include="*.py" --include="*.js" --include="*.ts" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        databases=$(echo "$databases" | jq '. += ["postgresql"]')
    fi
    
    # MySQL/MariaDB
    if grep -rqE "(mysql|mariadb)" "$codebase" \
        --include="*.json" --include="*.yaml" --include="*.yml" --include="*.py" --include="*.js" --include="*.ts" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        databases=$(echo "$databases" | jq '. += ["mysql"]')
    fi
    
    # MongoDB
    if grep -rqE "(mongodb|mongoose|pymongo)" "$codebase" \
        --include="*.json" --include="*.yaml" --include="*.yml" --include="*.py" --include="*.js" --include="*.ts" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        databases=$(echo "$databases" | jq '. += ["mongodb"]')
    fi
    
    # Redis
    if grep -rqE "(redis|ioredis)" "$codebase" \
        --include="*.json" --include="*.yaml" --include="*.yml" --include="*.py" --include="*.js" --include="*.ts" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        databases=$(echo "$databases" | jq '. += ["redis"]')
    fi
    
    # SQLite
    if grep -rqE "(sqlite|better-sqlite)" "$codebase" \
        --include="*.json" --include="*.yaml" --include="*.yml" --include="*.py" --include="*.js" --include="*.ts" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        databases=$(echo "$databases" | jq '. += ["sqlite"]')
    fi
    
    # Elasticsearch
    if grep -rqE "(elasticsearch|@elastic)" "$codebase" \
        --include="*.json" --include="*.yaml" --include="*.yml" --include="*.py" --include="*.js" --include="*.ts" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        databases=$(echo "$databases" | jq '. += ["elasticsearch"]')
    fi
    
    # DynamoDB
    if grep -rqE "(dynamodb|@aws-sdk/client-dynamodb)" "$codebase" \
        --include="*.json" --include="*.yaml" --include="*.yml" --include="*.py" --include="*.js" --include="*.ts" \
        --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        databases=$(echo "$databases" | jq '. += ["dynamodb"]')
    fi
    
    echo "$databases"
}

# =============================================================================
# COMPREHENSIVE ANALYSIS
# =============================================================================

run_full_analysis() {
    local codebase="$1"
    local output_file="${2:-/dev/stdout}"
    
    echo "Running comprehensive codebase analysis..." >&2
    
    local languages=$(detect_languages_advanced "$codebase")
    local frameworks=$(detect_frameworks "$codebase")
    local project=$(detect_project_type "$codebase")
    local databases=$(detect_databases "$codebase")
    
    jq -n \
        --argjson languages "$languages" \
        --argjson frameworks "$frameworks" \
        --argjson project "$project" \
        --argjson databases "$databases" \
        '{
            analysis_version: "2.0",
            languages: $languages,
            frameworks: $frameworks,
            project: $project,
            databases: $databases
        }' > "$output_file"
    
    cat "$output_file"
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_full_analysis "$@"
fi
