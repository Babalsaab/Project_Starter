#!/usr/bin/env bash
# ============================================================================
# Vibecoded Orchestrator — Universal Setup Script
# ============================================================================
# Works on: Linux, macOS, Windows (Git Bash / WSL / MSYS2)
#
# Usage:
#   ./start.sh          # Full setup + start dev server
#   ./start.sh --setup  # Setup only (no dev server)
#   ./start.sh --check  # Verify everything is configured
#   ./start.sh --mcp    # Rebuild MCP server only
#   ./start.sh --clean  # Clean reinstall everything
#
# This script handles both fresh clones and existing projects.
# ============================================================================

set -euo pipefail

# ── Colors (with fallback for dumb terminals) ────────────────────────────────

if [[ -t 1 ]] && command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
  RED=$(tput setaf 1) GREEN=$(tput setaf 2) YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4) MAGENTA=$(tput setaf 5) CYAN=$(tput setaf 6)
  BOLD=$(tput bold) RESET=$(tput sgr0)
else
  RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" BOLD="" RESET=""
fi

# ── Helpers ──────────────────────────────────────────────────────────────────

info()    { echo "${BLUE}[INFO]${RESET}  $*"; }
success() { echo "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo "${RED}[ERROR]${RESET} $*"; }
step()    { echo ""; echo "${BOLD}${CYAN}── $* ──${RESET}"; }
divider() { echo "${CYAN}────────────────────────────────────────────────${RESET}"; }

# ── Detect OS & Platform ────────────────────────────────────────────────────

detect_platform() {
  OS="unknown"
  case "$(uname -s)" in
    Linux*)   OS="linux";;
    Darwin*)  OS="macos";;
    MINGW*|MSYS*|CYGWIN*) OS="windows";;
  esac

  ARCH="$(uname -m)"
  if [[ "$OS" == "windows" ]]; then
    SHELL_ENV="git-bash"
    [[ -n "${WSL_DISTRO_NAME:-}" ]] && SHELL_ENV="wsl"
  else
    SHELL_ENV="native"
  fi

  info "Platform: ${BOLD}$OS${RESET} ($ARCH) via $SHELL_ENV"
}

# ── Resolve project root (works even if called from subdirectory) ───────────

resolve_root() {
  # Find the directory containing this script
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$SCRIPT_DIR"

  # Verify we're in the right project
  if [[ ! -f "$PROJECT_ROOT/package.json" ]]; then
    error "Cannot find package.json in $PROJECT_ROOT"
    error "Run this script from the project root directory."
    exit 1
  fi

  cd "$PROJECT_ROOT"
  info "Project root: ${BOLD}$PROJECT_ROOT${RESET}"
}

# ── Check prerequisites ─────────────────────────────────────────────────────

check_prerequisites() {
  step "Checking prerequisites"
  local missing=0

  # Node.js
  if command -v node &>/dev/null; then
    local node_version
    node_version="$(node -v)"
    local node_major="${node_version#v}"
    node_major="${node_major%%.*}"
    if [[ "$node_major" -ge 18 ]]; then
      success "Node.js $node_version"
    else
      error "Node.js $node_version found, but >= 18 required"
      missing=1
    fi
  else
    error "Node.js not found. Install from https://nodejs.org/"
    missing=1
  fi

  # npm
  if command -v npm &>/dev/null; then
    success "npm $(npm -v)"
  else
    error "npm not found. It should come with Node.js."
    missing=1
  fi

  # Git (optional but recommended)
  if command -v git &>/dev/null; then
    success "git $(git --version | awk '{print $3}')"
  else
    warn "git not found. Some features may not work."
  fi

  if [[ $missing -ne 0 ]]; then
    echo ""
    error "Missing prerequisites. Install them and re-run this script."
    exit 1
  fi
}

# ── Create required directories ──────────────────────────────────────────────

ensure_directories() {
  step "Ensuring directory structure"

  local dirs=(
    "runs/artifacts"
    "runs/prds"
    "runs/logs"
    "runs/workflows"
    "config/project-sessions"
    "config/workflows"
    "memory"
    "memory/daily"
  )

  for dir in "${dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
      mkdir -p "$dir"
      info "Created $dir/"
    fi
  done

  # Ensure .gitkeep files exist for tracked empty dirs
  local gitkeeps=(
    "runs/artifacts/.gitkeep"
    "runs/prds/.gitkeep"
    "runs/logs/.gitkeep"
    "config/project-sessions/.gitkeep"
  )

  for gk in "${gitkeeps[@]}"; do
    [[ ! -f "$gk" ]] && touch "$gk"
  done

  # Initialize memory store if not exists
  if [[ ! -f "memory/memory-store.json" ]]; then
    cat > "memory/memory-store.json" <<'MEMEOF'
{
  "version": "2.0.0",
  "facts": [],
  "sessions": [],
  "search_index": {
    "docs": [],
    "documentFreqs": {},
    "totalDocs": 0
  }
}
MEMEOF
    info "Initialized memory/memory-store.json"
  fi

  # Initialize MEMORY.md if not exists
  if [[ ! -f "memory/MEMORY.md" ]]; then
    cat > "memory/MEMORY.md" <<'MDEOF'
# Project Memory

Persistent context for the Vibecoded Orchestrator project.
Last updated: $(date +%Y-%m-%d)
Total facts: 0 | Sessions: 0
MDEOF
    info "Initialized memory/MEMORY.md"
  fi

  success "All directories ready"
}

# ── Install dependencies ─────────────────────────────────────────────────────

install_deps() {
  step "Installing dependencies"

  # Root project
  if [[ ! -d "node_modules" ]] || [[ "$FORCE_INSTALL" == "true" ]]; then
    info "Installing root dependencies..."
    npm install
    success "Root dependencies installed"
  else
    success "Root dependencies already installed (use --clean to force)"
  fi

  # MCP server
  if [[ -d "mcp-server" ]]; then
    if [[ ! -d "mcp-server/node_modules" ]] || [[ "$FORCE_INSTALL" == "true" ]]; then
      info "Installing MCP server dependencies..."
      (cd mcp-server && npm install)
      success "MCP server dependencies installed"
    else
      success "MCP server dependencies already installed"
    fi
  fi
}

# ── Build MCP server ─────────────────────────────────────────────────────────

build_mcp() {
  step "Building MCP server"

  if [[ ! -d "mcp-server/src" ]]; then
    warn "MCP server source not found at mcp-server/src — skipping build"
    return 0
  fi

  (cd mcp-server && npm run build)

  # Verify build output
  if [[ -f "mcp-server/build/index.js" ]]; then
    # Count tools by sending initialize + tools/list and counting inputSchema occurrences
    # (each tool has exactly one inputSchema, making it a reliable counter)
    local tool_count
    tool_count=$(printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"setup","version":"1.0"}}}\n{"jsonrpc":"2.0","method":"notifications/initialized"}\n{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}\n' \
      | node mcp-server/build/index.js 2>/dev/null \
      | grep -o '"inputSchema"' | wc -l || echo "0")
    tool_count=$(echo "$tool_count" | tr -d '[:space:]')

    if [[ "$tool_count" -gt 0 ]]; then
      success "MCP server built — ${BOLD}$tool_count tools${RESET} registered"
    else
      warn "MCP server built but tool count could not be verified"
      success "Build output exists at mcp-server/build/index.js"
    fi
  else
    error "MCP server build failed — mcp-server/build/index.js not found"
    return 1
  fi
}

# ── Database setup ───────────────────────────────────────────────────────────

setup_database() {
  step "Database setup"

  if [[ -f "prisma/schema.prisma" ]]; then
    # Check if DATABASE_URL is set or if SQLite is the default
    if [[ -f ".env.local" ]] || [[ -f ".env" ]] || grep -q "sqlite" prisma/schema.prisma 2>/dev/null; then
      info "Pushing Prisma schema to database..."
      npx prisma generate 2>/dev/null || true
      npx prisma db push --skip-generate 2>/dev/null && success "Database schema synced" || warn "Database push skipped (set DATABASE_URL in .env.local for PostgreSQL)"
    else
      info "No database config found. Using SQLite by default."
      npx prisma generate 2>/dev/null || true
      npx prisma db push --skip-generate 2>/dev/null && success "SQLite database created" || warn "Database setup deferred"
    fi
  else
    warn "No Prisma schema found — skipping database setup"
  fi
}

# ── Validate agents ──────────────────────────────────────────────────────────

validate_project() {
  step "Validating project"

  # Count agents
  local tech_agents marketing_agents chiefs personas mentors skills
  tech_agents=$(find agents/pool/tech -name "*.yaml" 2>/dev/null | wc -l | tr -d '[:space:]')
  marketing_agents=$(find agents/pool/marketing -name "*.yaml" 2>/dev/null | wc -l | tr -d '[:space:]')
  chiefs=$(find agents/chiefs -name "*.yaml" 2>/dev/null | wc -l | tr -d '[:space:]')
  personas=$(find agents/personas -name "*.md" 2>/dev/null | wc -l | tr -d '[:space:]')
  mentors=$(grep -c "^  [a-z_]*:$" config/mentors.yaml 2>/dev/null || echo "0")
  skills=$(find skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d '[:space:]')

  local claude_skills=0
  if [[ -d ".claude/skills" ]]; then
    claude_skills=$(find .claude/skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d '[:space:]')
  fi

  local workflows=0
  if [[ -d "config/workflows" ]]; then
    workflows=$(find config/workflows -name "*.yaml" -o -name "*.yml" 2>/dev/null | wc -l | tr -d '[:space:]')
  fi

  success "Agents: ${BOLD}$tech_agents tech + $marketing_agents marketing + $chiefs chiefs${RESET}"
  success "Personas: ${BOLD}$personas${RESET}"
  success "Mentors: ${BOLD}$mentors${RESET}"
  success "Skills: ${BOLD}$skills orchestrator + $claude_skills Claude Code native${RESET}"
  success "Workflows: ${BOLD}$workflows${RESET}"

  # Run agent validation if available
  if npm run validate --silent 2>/dev/null; then
    success "Agent YAML validation passed"
  fi
}

# ── Configure IDE integrations ───────────────────────────────────────────────

check_ide_config() {
  step "IDE integration status"

  # Claude Code
  if [[ -f ".claude/settings.local.json" ]]; then
    success "Claude Code — .claude/settings.local.json"
  else
    warn "Claude Code config missing. Creating .claude/settings.local.json..."
    mkdir -p .claude
    cat > .claude/settings.local.json <<'CCEOF'
{
  "mcpServers": {
    "orchestrator": {
      "command": "node",
      "args": ["mcp-server/build/index.js"]
    }
  }
}
CCEOF
    success "Claude Code config created"
  fi

  # Cursor
  if [[ -f ".cursor/mcp.json" ]]; then
    success "Cursor — .cursor/mcp.json"
  else
    warn "Cursor config missing. Creating .cursor/mcp.json..."
    mkdir -p .cursor
    cat > .cursor/mcp.json <<'CREOF'
{
  "mcpServers": {
    "orchestrator": {
      "command": "node",
      "args": ["mcp-server/build/index.js"]
    }
  }
}
CREOF
    success "Cursor config created"
  fi

  # VS Code / Copilot
  if [[ -f ".vscode/mcp.json" ]]; then
    success "VS Code / Copilot — .vscode/mcp.json"
  else
    warn "VS Code MCP config missing. Creating .vscode/mcp.json..."
    mkdir -p .vscode
    cat > .vscode/mcp.json <<'VSEOF'
{
  "servers": {
    "orchestrator": {
      "type": "stdio",
      "command": "node",
      "args": ["mcp-server/build/index.js"]
    }
  }
}
VSEOF
    success "VS Code MCP config created"
  fi

  # Windsurf
  if [[ -f ".windsurfrules" ]]; then
    success "Windsurf — .windsurfrules"
  else
    warn "Windsurf rules not found (optional)"
  fi

  # AntiGravity
  if [[ -f ".antigravityrules" ]]; then
    success "AntiGravity — .antigravityrules"
  else
    warn "AntiGravity rules not found (optional)"
  fi

  if [[ -d ".agent/skills" ]]; then
    local ag_skills
    ag_skills=$(find .agent/skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d '[:space:]')
    success "AntiGravity skills — .agent/skills/ ($ag_skills skills)"
  fi

  # AntiGravity MCP config (user-level)
  local ag_config=""
  if [[ "$OS" == "windows" ]]; then
    ag_config="$USERPROFILE/.gemini/settings.json"
    # Also check APPDATA location
    [[ -z "$ag_config" || ! -f "$ag_config" ]] && ag_config="$APPDATA/AntiGravity/mcp_config.json"
  elif [[ "$OS" == "macos" ]]; then
    ag_config="$HOME/.gemini/settings.json"
  else
    ag_config="$HOME/.gemini/settings.json"
  fi

  if [[ -n "$ag_config" && -f "$ag_config" ]]; then
    success "AntiGravity MCP — $ag_config"
  else
    info "AntiGravity MCP config: Add the orchestrator server in AntiGravity Settings > MCP"
    info "  Server name: orchestrator"
    info "  Command: node"
    info "  Args: $(pwd)/mcp-server/build/index.js"
  fi

  # Instruction files
  [[ -f "CLAUDE.md" ]]    && success "CLAUDE.md present"     || warn "CLAUDE.md missing"
  [[ -f "AGENTS.md" ]]    && success "AGENTS.md present"     || warn "AGENTS.md missing"
  [[ -f ".cursorrules" ]] && success ".cursorrules present"   || warn ".cursorrules missing"
}

# ── Environment file check ───────────────────────────────────────────────────

check_env() {
  step "Environment check"

  if [[ -f ".env.local" ]]; then
    success ".env.local found"
    if grep -q "ANTHROPIC_API_KEY" .env.local 2>/dev/null; then
      success "ANTHROPIC_API_KEY is configured"
    else
      warn "ANTHROPIC_API_KEY not set in .env.local — orchestrator will use fallback mode"
      info "Add it with: echo 'ANTHROPIC_API_KEY=sk-ant-...' >> .env.local"
    fi
  elif [[ -f ".env" ]]; then
    success ".env found"
  else
    warn "No .env.local found — creating from .env.example..."
    if [[ -f ".env.example" ]]; then
      cp .env.example .env.local
      success "Created .env.local from .env.example"
      warn "Edit .env.local to add your API keys"
    else
      info "No .env.example found. Create .env.local manually if needed."
    fi
  fi
}

# ── Print summary ────────────────────────────────────────────────────────────

print_summary() {
  echo ""
  divider
  echo "${BOLD}${GREEN}  Vibecoded Orchestrator — Ready!${RESET}"
  divider
  echo ""
  echo "  ${BOLD}Quick Commands:${RESET}"
  echo "    npm run dev                  Start TaskFlow web app (port 1000)"
  echo "    npm run orchestrator         Run agent orchestration pipeline"
  echo "    npm run orchestrator:list    List project sessions"
  echo "    npm run mcp:build            Rebuild MCP server"
  echo ""
  echo "  ${BOLD}MCP Server (44 tools):${RESET}"
  echo "    Agents (4)    Personas (2)    Mentors (2)     Skills (4)"
  echo "    PRD (3)       Sessions (4)    Memory (9)      Workflows (8)"
  echo "    Skill Discovery (4)"
  echo ""
  echo "  ${BOLD}Claude Code Skills:${RESET}"
  echo "    /skill-builder               Create new skills interactively"
  echo "    /image-gen                   AI image generation via Kie.ai"
  echo "    /antigravity-skill-creator   Cross-platform skill creation"
  echo ""
  echo "  ${BOLD}AI Coder Integration:${RESET}"
  echo "    Claude Code    .claude/settings.local.json"
  echo "    Cursor         .cursor/mcp.json"
  echo "    VS Code        .vscode/mcp.json"
  echo "    Windsurf       .windsurfrules + MCP settings UI"
  echo "    AntiGravity    .antigravityrules + .agent/skills/ + MCP settings UI"
  echo ""
  echo "  ${BOLD}Documentation:${RESET}"
  echo "    docs/MCP-SETUP-GUIDE.md      Full MCP setup & extension guide"
  echo "    CLAUDE.md                    Claude Code project instructions"
  echo "    AGENTS.md                    Agent system documentation"
  echo ""
  divider
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  local MODE="${1:-full}"
  FORCE_INSTALL="false"

  case "$MODE" in
    --check|-c)
      detect_platform
      resolve_root
      check_prerequisites
      validate_project
      check_ide_config
      check_env
      echo ""
      success "Health check complete."
      exit 0
      ;;
    --mcp|-m)
      detect_platform
      resolve_root
      build_mcp
      echo ""
      success "MCP server rebuilt."
      exit 0
      ;;
    --clean)
      FORCE_INSTALL="true"
      info "Clean install mode — reinstalling everything"
      detect_platform
      resolve_root
      check_prerequisites
      info "Removing node_modules..."
      rm -rf node_modules mcp-server/node_modules mcp-server/build
      install_deps
      build_mcp
      ensure_directories
      setup_database
      validate_project
      check_ide_config
      check_env
      print_summary
      exit 0
      ;;
    --setup|-s)
      detect_platform
      resolve_root
      check_prerequisites
      ensure_directories
      install_deps
      build_mcp
      setup_database
      validate_project
      check_ide_config
      check_env
      print_summary
      exit 0
      ;;
    --help|-h)
      echo "Vibecoded Orchestrator Setup"
      echo ""
      echo "Usage: ./start.sh [option]"
      echo ""
      echo "Options:"
      echo "  (none)       Full setup + start dev server"
      echo "  --setup, -s  Setup only (no dev server)"
      echo "  --check, -c  Verify configuration"
      echo "  --mcp, -m    Rebuild MCP server only"
      echo "  --clean      Clean reinstall everything"
      echo "  --help, -h   Show this help"
      exit 0
      ;;
    *)
      # Full setup + start dev server
      detect_platform
      resolve_root
      check_prerequisites
      ensure_directories
      install_deps
      build_mcp
      setup_database
      validate_project
      check_ide_config
      check_env
      print_summary

      step "Starting TaskFlow dev server"
      info "Web app at: ${BOLD}http://localhost:1000${RESET}"
      info "Press Ctrl+C to stop"
      echo ""
      npm run dev
      ;;
  esac
}

main "$@"
