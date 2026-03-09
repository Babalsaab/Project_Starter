#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# update.sh — User-facing update script for the Vibecoded Orchestrator
# ============================================================================
# Checks for updates, pulls latest changes, syncs upstream skills/agents,
# and rebuilds the MCP server.
#
# Usage:
#   ./scripts/update.sh             # Interactive update
#   ./scripts/update.sh --check     # Check for updates without applying
#   ./scripts/update.sh --force     # Update without prompting
#   ./scripts/update.sh --sync-only # Only sync upstream skills/agents
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_JSON="$PROJECT_ROOT/package.json"

MODE="interactive"
for arg in "$@"; do
  case "$arg" in
    --check) MODE="check" ;;
    --force) MODE="force" ;;
    --sync-only) MODE="sync-only" ;;
    --help|-h)
      echo "Usage: ./scripts/update.sh [--check | --force | --sync-only]"
      echo ""
      echo "Options:"
      echo "  --check       Check for updates without applying them"
      echo "  --force       Apply updates without prompting for confirmation"
      echo "  --sync-only   Only sync upstream skills and agents"
      echo "  --help, -h    Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Run ./scripts/update.sh --help for usage"
      exit 1
      ;;
  esac
done

# ---- Helpers ----------------------------------------------------------------

log_info() {
  echo "[update] $1"
}

log_success() {
  echo "[update] OK: $1"
}

log_warn() {
  echo "[update] WARN: $1"
}

log_error() {
  echo "[update] ERROR: $1" >&2
}

get_current_version() {
  node -e "console.log(require('$PACKAGE_JSON').version)" 2>/dev/null || echo "unknown"
}

get_latest_release() {
  # Try gh CLI first, fall back to git tags
  if command -v gh &>/dev/null; then
    gh release view --json tagName --jq '.tagName' 2>/dev/null || echo ""
  else
    git ls-remote --tags origin 2>/dev/null \
      | grep -oP 'refs/tags/v\K[0-9]+\.[0-9]+\.[0-9]+' \
      | sort -V \
      | tail -1 \
      || echo ""
  fi
}

get_changelog_summary() {
  local current_tag="$1"
  if command -v gh &>/dev/null; then
    gh release view "$current_tag" --json body --jq '.body' 2>/dev/null | head -30 || echo "No changelog available."
  else
    echo "Install the gh CLI for changelog summaries."
  fi
}

prompt_confirm() {
  local message="$1"
  if [ "$MODE" = "force" ]; then
    return 0
  fi
  echo -n "$message [y/N] "
  read -r response
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

# ---- Check for updates ------------------------------------------------------

check_updates() {
  local current_version
  current_version=$(get_current_version)
  log_info "Current version: v$current_version"

  local latest_release
  latest_release=$(get_latest_release)

  if [ -z "$latest_release" ]; then
    log_info "No releases found on remote. You may be on the latest development version."
    return 1
  fi

  # Strip 'v' prefix for comparison
  local latest_version="${latest_release#v}"

  log_info "Latest release: v$latest_version"

  if [ "$current_version" = "$latest_version" ]; then
    log_success "You are on the latest release."
    return 1
  fi

  # Compare versions
  if [ "$(printf '%s\n' "$current_version" "$latest_version" | sort -V | tail -1)" = "$latest_version" ]; then
    log_info "Update available: v$current_version -> v$latest_version"
    return 0
  else
    log_info "You are ahead of the latest release (dev branch)."
    return 1
  fi
}

# ---- Update via git ----------------------------------------------------------

update_git() {
  log_info "Checking for uncommitted changes..."

  if [ -n "$(git -C "$PROJECT_ROOT" status --porcelain 2>/dev/null)" ]; then
    log_warn "You have uncommitted changes."
    if ! prompt_confirm "Stash changes and proceed?"; then
      log_info "Aborting update."
      exit 0
    fi
    git -C "$PROJECT_ROOT" stash push -m "auto-stash before update $(date +%Y%m%d-%H%M%S)"
    log_success "Changes stashed."
  fi

  log_info "Pulling latest changes from remote..."
  git -C "$PROJECT_ROOT" pull --rebase origin main || {
    log_error "Git pull failed. Resolve conflicts and try again."
    exit 1
  }
  log_success "Repository updated."
}

# ---- Install dependencies ----------------------------------------------------

install_deps() {
  log_info "Installing dependencies..."
  (cd "$PROJECT_ROOT" && npm ci --legacy-peer-deps 2>/dev/null || npm install --legacy-peer-deps)
  log_success "Dependencies installed."
}

# ---- Rebuild MCP server ------------------------------------------------------

rebuild_mcp() {
  local mcp_dir="$PROJECT_ROOT/mcp-server"
  if [ -d "$mcp_dir" ] && [ -f "$mcp_dir/package.json" ]; then
    log_info "Rebuilding MCP server..."
    (cd "$mcp_dir" && npm install 2>/dev/null && npm run build 2>/dev/null) || {
      log_warn "MCP server rebuild failed. You may need to rebuild manually: npm run mcp:build"
    }
    log_success "MCP server rebuilt."
  else
    log_info "MCP server directory not found, skipping rebuild."
  fi
}

# ---- Sync upstream -----------------------------------------------------------

sync_upstream() {
  local sync_script="$SCRIPT_DIR/sync-upstream.sh"
  if [ -f "$sync_script" ]; then
    log_info "Running upstream skills/agents sync..."
    bash "$sync_script"
  else
    log_warn "sync-upstream.sh not found, skipping upstream sync."
  fi
}

# ---- Generate Prisma client --------------------------------------------------

regenerate_prisma() {
  if [ -f "$PROJECT_ROOT/prisma/schema.prisma" ]; then
    log_info "Regenerating Prisma client..."
    (cd "$PROJECT_ROOT" && npx prisma generate 2>/dev/null) || {
      log_warn "Prisma generate failed. Run manually: npx prisma generate"
    }
    log_success "Prisma client regenerated."
  fi
}

# ---- Main --------------------------------------------------------------------

main() {
  echo ""
  echo "============================================================"
  echo "  Vibecoded Orchestrator — Update Manager"
  echo "  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "============================================================"
  echo ""

  cd "$PROJECT_ROOT"

  # Handle sync-only mode
  if [ "$MODE" = "sync-only" ]; then
    sync_upstream
    echo ""
    log_success "Upstream sync complete."
    exit 0
  fi

  # Check for updates
  local has_updates=false
  if check_updates; then
    has_updates=true
  fi

  # Check-only mode
  if [ "$MODE" = "check" ]; then
    if [ "$has_updates" = true ]; then
      local latest_release
      latest_release=$(get_latest_release)
      echo ""
      echo "Changelog preview:"
      echo "---"
      get_changelog_summary "$latest_release"
      echo "---"
      echo ""
      echo "Run './scripts/update.sh' to apply the update."
    fi
    exit 0
  fi

  # Interactive/force update
  if [ "$has_updates" = true ]; then
    if [ "$MODE" = "interactive" ]; then
      if ! prompt_confirm "Do you want to update now?"; then
        log_info "Update cancelled."
        exit 0
      fi
    fi

    update_git
    install_deps
    regenerate_prisma
    rebuild_mcp
    sync_upstream

    echo ""
    echo "============================================================"
    echo "  Update Complete"
    echo "============================================================"
    local new_version
    new_version=$(get_current_version)
    log_success "Updated to v$new_version"

    # Print changelog
    local latest_release
    latest_release=$(get_latest_release)
    if [ -n "$latest_release" ]; then
      echo ""
      echo "Changelog:"
      echo "---"
      get_changelog_summary "$latest_release"
      echo "---"
    fi
  else
    # No version update, but still offer to sync
    if [ "$MODE" = "interactive" ]; then
      if prompt_confirm "No version update available. Sync upstream skills/agents?"; then
        sync_upstream
      fi
    elif [ "$MODE" = "force" ]; then
      sync_upstream
    fi
  fi

  echo ""
  log_success "All done."
}

main "$@"
