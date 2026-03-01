#!/bin/bash

# =============================================================================
# ENHANCED ARCHITECTURE ANALYZER
# =============================================================================
# Deep architecture analysis for codebases
# Detects: Design patterns, modularity, coupling, cohesion, boundaries
# =============================================================================

# =============================================================================
# MAIN ARCHITECTURE ANALYSIS
# =============================================================================

analyze_architecture() {
    local codebase_path="$1"
    local output_dir="${2:-${TMPDIR:-/tmp}/architecture-analysis}"
    
    mkdir -p "$output_dir"
    
    local total_score=10
    
    # Run all architecture checks
    local pattern_result=$(detect_design_patterns "$codebase_path" 2>/dev/null) || pattern_result='{"patterns_found": 0}'
    local modularity_result=$(analyze_modularity "$codebase_path" 2>/dev/null) || modularity_result='{"score": 5}'
    local coupling_result=$(analyze_coupling "$codebase_path" 2>/dev/null) || coupling_result='{"score": 5}'
    local layering_result=$(analyze_layering "$codebase_path" 2>/dev/null) || layering_result='{"score": 5}'
    local dependency_result=$(analyze_dependencies "$codebase_path" 2>/dev/null) || dependency_result='{"score": 5}'
    
    # Validate JSON
    echo "$pattern_result" | jq '.' >/dev/null 2>&1 || pattern_result='{"patterns_found": 0}'
    echo "$modularity_result" | jq '.' >/dev/null 2>&1 || modularity_result='{"score": 5}'
    echo "$coupling_result" | jq '.' >/dev/null 2>&1 || coupling_result='{"score": 5}'
    echo "$layering_result" | jq '.' >/dev/null 2>&1 || layering_result='{"score": 5}'
    echo "$dependency_result" | jq '.' >/dev/null 2>&1 || dependency_result='{"score": 5}'
    
    # Extract scores
    local pattern_count=$(echo "$pattern_result" | jq -r '.patterns_found // 0') || pattern_count=0
    local modularity_score=$(echo "$modularity_result" | jq -r '.score // 5') || modularity_score=5
    local coupling_score=$(echo "$coupling_result" | jq -r '.score // 5') || coupling_score=5
    local layering_score=$(echo "$layering_result" | jq -r '.score // 5') || layering_score=5
    local dependency_score=$(echo "$dependency_result" | jq -r '.score // 5') || dependency_score=5
    
    # Bonus for using design patterns
    local pattern_bonus=0
    [ "${pattern_count:-0}" -gt 3 ] && pattern_bonus=1
    [ "${pattern_count:-0}" -gt 7 ] && pattern_bonus=2
    
    # Calculate overall score
    total_score=$(( (modularity_score + coupling_score + layering_score + dependency_score + pattern_bonus) / 4 ))
    
    [ "$total_score" -lt 1 ] && total_score=1
    [ "$total_score" -gt 10 ] && total_score=10
    
    cat << EOF
{
    "overall_score": ${total_score:-5},
    "design_patterns": $pattern_result,
    "modularity": $modularity_result,
    "coupling": $coupling_result,
    "layering": $layering_result,
    "dependencies": $dependency_result
}
EOF
}

# =============================================================================
# DESIGN PATTERNS DETECTION
# =============================================================================

detect_design_patterns() {
    local codebase_path="$1"
    local patterns_found=0
    local patterns='[]'
    
    # Singleton pattern
    local singleton=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -l "getInstance\|_instance\|__instance\|singleton" {} \; 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${singleton:-0}" -gt 0 ] && {
        patterns_found=$((patterns_found + 1))
        patterns=$(echo "$patterns" | jq '. + ["singleton"]')
    }
    
    # Factory pattern
    local factory=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -l "Factory\|createInstance\|create_instance\|factory_method" {} \; 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${factory:-0}" -gt 0 ] && {
        patterns_found=$((patterns_found + 1))
        patterns=$(echo "$patterns" | jq '. + ["factory"]')
    }
    
    # Repository pattern
    local repository=$(find "$codebase_path" -type f \( -name "*Repository*" -o -name "*repository*" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${repository:-0}" -gt 0 ] && {
        patterns_found=$((patterns_found + 1))
        patterns=$(echo "$patterns" | jq '. + ["repository"]')
    }
    
    # Service pattern
    local service=$(find "$codebase_path" -type f \( -name "*Service*" -o -name "*service*" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${service:-0}" -gt 2 ] && {
        patterns_found=$((patterns_found + 1))
        patterns=$(echo "$patterns" | jq '. + ["service_layer"]')
    }
    
    # Controller pattern
    local controller=$(find "$codebase_path" -type f \( -name "*Controller*" -o -name "*controller*" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${controller:-0}" -gt 0 ] && {
        patterns_found=$((patterns_found + 1))
        patterns=$(echo "$patterns" | jq '. + ["mvc/controller"]')
    }
    
    # Observer/Event pattern
    local observer=$(find "$codebase_path" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -l "EventEmitter\|Observer\|subscribe\|addEventListener\|on_event\|@Subscribe" {} \; 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${observer:-0}" -gt 0 ] && {
        patterns_found=$((patterns_found + 1))
        patterns=$(echo "$patterns" | jq '. + ["observer/event"]')
    }
    
    # Dependency Injection
    local di=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.java" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -l "@Inject\|@Injectable\|@Autowired\|@inject\|Depends\(" {} \; 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${di:-0}" -gt 0 ] && {
        patterns_found=$((patterns_found + 1))
        patterns=$(echo "$patterns" | jq '. + ["dependency_injection"]')
    }
    
    # Strategy pattern
    local strategy=$(find "$codebase_path" -type f \( -name "*Strategy*" -o -name "*strategy*" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${strategy:-0}" -gt 0 ] && {
        patterns_found=$((patterns_found + 1))
        patterns=$(echo "$patterns" | jq '. + ["strategy"]')
    }
    
    # Middleware pattern
    local middleware=$(find "$codebase_path" -type f \( -name "*middleware*" -o -name "*Middleware*" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${middleware:-0}" -gt 0 ] && {
        patterns_found=$((patterns_found + 1))
        patterns=$(echo "$patterns" | jq '. + ["middleware"]')
    }
    
    # Decorator pattern
    local decorator=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -l "@decorator\|def decorator\|Decorator\|@\w\+(" {} \; 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${decorator:-0}" -gt 2 ] && {
        patterns_found=$((patterns_found + 1))
        patterns=$(echo "$patterns" | jq '. + ["decorator"]')
    }
    
    cat << EOF
{
    "patterns_found": ${patterns_found:-0},
    "patterns": $patterns
}
EOF
}

# =============================================================================
# MODULARITY ANALYSIS
# =============================================================================

analyze_modularity() {
    local codebase_path="$1"
    local score=5
    
    # Check for clear module structure
    local has_src_dir=$([ -d "$codebase_path/src" ] && echo 1 || echo 0)
    local has_lib_dir=$([ -d "$codebase_path/lib" ] && echo 1 || echo 0)
    local has_packages=$([ -d "$codebase_path/packages" ] && echo 1 || echo 0)
    local has_modules=$([ -d "$codebase_path/modules" ] && echo 1 || echo 0)
    
    # Count distinct modules/packages
    local module_count=0
    
    # Check for monorepo structure
    if [ -f "$codebase_path/lerna.json" ] || [ -f "$codebase_path/pnpm-workspace.yaml" ] || [ -d "$codebase_path/packages" ]; then
        module_count=$(find "$codebase_path/packages" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        score=$((score + 2))
    fi
    
    # Check for Python packages
    local python_packages=$(find "$codebase_path" -maxdepth 3 -name "__init__.py" \
        ! -path "*/venv/*" ! -path "*/.venv/*" 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${python_packages:-0}" -gt 3 ] && score=$((score + 1))
    
    # Check for clean folder structure
    local folder_depth=$(find "$codebase_path" -type d \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/venv/*" \
        2>/dev/null | awk -F'/' '{print NF}' | sort -n | tail -1)
    
    # Too deep is bad (> 8 levels)
    [ "${folder_depth:-0}" -gt 8 ] && score=$((score - 1))
    
    # Check for barrel files (index.ts/index.js)
    local barrel_files=$(find "$codebase_path" -type f \( -name "index.ts" -o -name "index.js" \) \
        ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${barrel_files:-0}" -gt 5 ] && score=$((score + 1))
    
    # Check for clear separation (api, ui, db, etc.)
    local separation_count=0
    [ -d "$codebase_path/src/api" ] || [ -d "$codebase_path/api" ] && separation_count=$((separation_count + 1))
    [ -d "$codebase_path/src/ui" ] || [ -d "$codebase_path/frontend" ] || [ -d "$codebase_path/client" ] && separation_count=$((separation_count + 1))
    [ -d "$codebase_path/src/db" ] || [ -d "$codebase_path/database" ] || [ -d "$codebase_path/models" ] && separation_count=$((separation_count + 1))
    [ -d "$codebase_path/src/services" ] || [ -d "$codebase_path/services" ] && separation_count=$((separation_count + 1))
    
    [ "$separation_count" -ge 3 ] && score=$((score + 2))
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-5},
    "has_src_dir": $has_src_dir,
    "has_packages": $has_packages,
    "module_count": ${module_count:-0},
    "python_packages": ${python_packages:-0},
    "barrel_files": ${barrel_files:-0},
    "folder_depth": ${folder_depth:-0},
    "separation_count": ${separation_count:-0}
}
EOF
}

# =============================================================================
# COUPLING ANALYSIS
# =============================================================================

analyze_coupling() {
    local codebase_path="$1"
    local score=7
    local high_coupling_files=0
    
    # Check for circular dependencies (simplified check)
    local import_cycles=0
    
    # Count relative imports (often indicates tight coupling)
    local relative_imports=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -c "from '\.\.\/" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    # Many relative imports = potential coupling issues
    [ "${relative_imports:-0}" -gt 50 ] && score=$((score - 1))
    [ "${relative_imports:-0}" -gt 100 ] && score=$((score - 2))
    
    # Check for god files (files with many imports)
    local files_many_imports=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec sh -c 'imports=$(grep -c "^import\|^from" "$1" 2>/dev/null); [ "$imports" -gt 20 ] && echo 1' _ {} \; 2>/dev/null | wc -l | tr -d ' ')
    
    high_coupling_files=${files_many_imports:-0}
    
    [ "$high_coupling_files" -gt 5 ] && score=$((score - 1))
    [ "$high_coupling_files" -gt 10 ] && score=$((score - 2))
    
    # Check for interface usage (good for loose coupling)
    local interface_count=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.java" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -l "interface \|implements \|@protocol" {} \; 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${interface_count:-0}" -gt 5 ] && score=$((score + 1))
    
    # Check for abstract classes
    local abstract_count=$(find "$codebase_path" -type f \( -name "*.ts" -o -name "*.java" -o -name "*.py" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" \
        -exec grep -l "abstract class\|ABC\|abstractmethod" {} \; 2>/dev/null | wc -l | tr -d ' ')
    
    [ "${abstract_count:-0}" -gt 2 ] && score=$((score + 1))
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-5},
    "relative_imports": ${relative_imports:-0},
    "high_coupling_files": ${high_coupling_files:-0},
    "interface_count": ${interface_count:-0},
    "abstract_count": ${abstract_count:-0}
}
EOF
}

# =============================================================================
# LAYERING ANALYSIS  
# =============================================================================

analyze_layering() {
    local codebase_path="$1"
    local score=5
    local layers_detected=0
    
    # Check for standard layered architecture folders
    # Presentation/UI layer
    if [ -d "$codebase_path/src/components" ] || [ -d "$codebase_path/src/views" ] || [ -d "$codebase_path/src/pages" ] || [ -d "$codebase_path/frontend" ]; then
        layers_detected=$((layers_detected + 1))
    fi
    
    # Business/Application layer
    if [ -d "$codebase_path/src/services" ] || [ -d "$codebase_path/src/usecases" ] || [ -d "$codebase_path/src/application" ]; then
        layers_detected=$((layers_detected + 1))
    fi
    
    # Domain layer
    if [ -d "$codebase_path/src/domain" ] || [ -d "$codebase_path/src/models" ] || [ -d "$codebase_path/src/entities" ]; then
        layers_detected=$((layers_detected + 1))
    fi
    
    # Data/Infrastructure layer
    if [ -d "$codebase_path/src/repositories" ] || [ -d "$codebase_path/src/infrastructure" ] || [ -d "$codebase_path/src/data" ]; then
        layers_detected=$((layers_detected + 1))
    fi
    
    # Clean Architecture patterns
    local clean_arch=false
    if [ -d "$codebase_path/src/domain" ] && [ -d "$codebase_path/src/application" ] && [ -d "$codebase_path/src/infrastructure" ]; then
        clean_arch=true
        score=$((score + 3))
    fi
    
    # Hexagonal Architecture
    local hexagonal=false
    if [ -d "$codebase_path/src/adapters" ] || [ -d "$codebase_path/src/ports" ]; then
        hexagonal=true
        score=$((score + 2))
    fi
    
    # Add points for layer detection
    score=$((score + layers_detected))
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-5},
    "layers_detected": ${layers_detected:-0},
    "clean_architecture": $clean_arch,
    "hexagonal_architecture": $hexagonal
}
EOF
}

# =============================================================================
# DEPENDENCY ANALYSIS
# =============================================================================

analyze_dependencies() {
    local codebase_path="$1"
    local score=6
    local total_deps=0
    local dev_deps=0
    local outdated_risk=0
    
    # Check package.json
    if [ -f "$codebase_path/package.json" ]; then
        total_deps=$(jq '.dependencies | length // 0' "$codebase_path/package.json" 2>/dev/null) || total_deps=0
        dev_deps=$(jq '.devDependencies | length // 0' "$codebase_path/package.json" 2>/dev/null) || dev_deps=0
        
        # Too many dependencies is a risk
        [ "${total_deps:-0}" -gt 50 ] && score=$((score - 1))
        [ "${total_deps:-0}" -gt 100 ] && score=$((score - 2))
        
        # Check for locked versions
        if [ -f "$codebase_path/package-lock.json" ] || [ -f "$codebase_path/yarn.lock" ] || [ -f "$codebase_path/pnpm-lock.yaml" ]; then
            score=$((score + 1))
        fi
    fi
    
    # Check requirements.txt
    if [ -f "$codebase_path/requirements.txt" ]; then
        local py_deps=$(wc -l < "$codebase_path/requirements.txt" | tr -d ' ')
        total_deps=$((total_deps + py_deps))
        
        # Check for pinned versions
        local pinned=$(grep -c "==" "$codebase_path/requirements.txt" 2>/dev/null) || pinned=0
        [ "${pinned:-0}" -gt "$((py_deps / 2))" ] && score=$((score + 1))
    fi
    
    # Check for dependency management tools
    if [ -f "$codebase_path/Pipfile" ] || [ -f "$codebase_path/pyproject.toml" ] || [ -f "$codebase_path/poetry.lock" ]; then
        score=$((score + 1))
    fi
    
    # Check go.mod
    if [ -f "$codebase_path/go.mod" ]; then
        local go_deps=$(grep -c "require\|indirect" "$codebase_path/go.mod" 2>/dev/null) || go_deps=0
        total_deps=$((total_deps + go_deps))
        
        # Go modules are good
        score=$((score + 1))
    fi
    
    [ "$score" -lt 1 ] && score=1
    [ "$score" -gt 10 ] && score=10
    
    cat << EOF
{
    "score": ${score:-5},
    "total_dependencies": ${total_deps:-0},
    "dev_dependencies": ${dev_deps:-0},
    "outdated_risk": ${outdated_risk:-0}
}
EOF
}

# Export functions
export -f analyze_architecture detect_design_patterns analyze_modularity analyze_coupling analyze_layering analyze_dependencies
