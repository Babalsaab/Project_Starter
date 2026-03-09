#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# sync-upstream.sh — Sync skills and agents from upstream registries
# ============================================================================
# Clones/pulls latest from 4 upstream repos, compares with our manifest,
# copies new compatible skills to skills/external/, and updates the manifest.
#
# Usage:
#   bash scripts/sync-upstream.sh
#   bash scripts/sync-upstream.sh --dry-run
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$PROJECT_ROOT/config/registries/upstream-manifest.json"
EXTERNAL_SKILLS_DIR="$PROJECT_ROOT/skills/external"
TEMP_DIR=$(mktemp -d)
DRY_RUN=false
SYNC_SUMMARY=""
NEW_COUNT=0
UPDATED_COUNT=0
SKIPPED_COUNT=0

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

# Cleanup on exit
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Ensure required directories exist
mkdir -p "$EXTERNAL_SKILLS_DIR"

# ---- Helpers ----------------------------------------------------------------

log_info() {
  echo "[sync] $1"
}

log_success() {
  echo "[sync] OK: $1"
}

log_warn() {
  echo "[sync] WARN: $1"
}

log_error() {
  echo "[sync] ERROR: $1" >&2
}

# Read a JSON field using node (available in CI and dev environments)
json_get() {
  local file="$1"
  local query="$2"
  node -e "
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync('$file', 'utf8'));
    const result = $query;
    console.log(result === null || result === undefined ? '' : (typeof result === 'object' ? JSON.stringify(result) : result));
  " 2>/dev/null || echo ""
}

# Update a JSON field using node
json_set() {
  local file="$1"
  local query="$2"
  node -e "
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync('$file', 'utf8'));
    $query;
    fs.writeFileSync('$file', JSON.stringify(data, null, 2) + '\n');
  " 2>/dev/null
}

# Clone or update a repo in the temp directory
clone_upstream() {
  local repo="$1"
  local branch="$2"
  local target="$TEMP_DIR/$(echo "$repo" | tr '/' '-')"

  if [ -d "$target" ]; then
    log_info "Updating $repo..."
    (cd "$target" && git pull --quiet 2>/dev/null) || true
  else
    log_info "Cloning $repo (branch: $branch)..."
    git clone --quiet --depth 1 --branch "$branch" "https://github.com/$repo.git" "$target" 2>/dev/null || {
      log_warn "Failed to clone $repo — skipping"
      return 1
    }
  fi

  echo "$target"
}

# Get the latest commit hash from a cloned repo
get_latest_commit() {
  local repo_dir="$1"
  (cd "$repo_dir" && git rev-parse HEAD 2>/dev/null) || echo ""
}

# Check if a skill file is compatible (YAML or Markdown with skill structure)
is_compatible_skill() {
  local file="$1"
  local ext="${file##*.}"

  case "$ext" in
    yaml|yml|md|json) return 0 ;;
    *) return 1 ;;
  esac
}

# Copy a skill to the external skills directory with attribution
copy_skill() {
  local source="$1"
  local upstream_id="$2"
  local upstream_repo="$3"
  local skill_name
  skill_name="$(basename "$source")"
  local dest_dir="$EXTERNAL_SKILLS_DIR/$upstream_id"
  local dest="$dest_dir/$skill_name"

  mkdir -p "$dest_dir"

  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would copy: $skill_name -> $dest"
    return 0
  fi

  cp "$source" "$dest"

  # Add attribution header if it is a text file and does not already have one
  if [[ "$skill_name" == *.md || "$skill_name" == *.yaml || "$skill_name" == *.yml ]]; then
    if ! grep -q "upstream-source" "$dest" 2>/dev/null; then
      local attr_comment
      if [[ "$skill_name" == *.md ]]; then
        attr_comment="<!-- upstream-source: $upstream_repo | synced: $(date -u +%Y-%m-%dT%H:%M:%SZ) -->"
      else
        attr_comment="# upstream-source: $upstream_repo | synced: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      fi
      # Prepend attribution
      local tmp
      tmp=$(mktemp)
      echo "$attr_comment" > "$tmp"
      cat "$dest" >> "$tmp"
      mv "$tmp" "$dest"
    fi
  fi
}

# ---- Sync Logic --------------------------------------------------------------

sync_upstream() {
  local index="$1"
  local upstream_id
  local upstream_repo
  local upstream_branch
  local upstream_skill_path
  local upstream_last_commit

  upstream_id=$(json_get "$MANIFEST" "data.upstreams[$index].id")
  upstream_repo=$(json_get "$MANIFEST" "data.upstreams[$index].repo")
  upstream_branch=$(json_get "$MANIFEST" "data.upstreams[$index].branch")
  upstream_skill_path=$(json_get "$MANIFEST" "data.upstreams[$index].skill_path")
  upstream_last_commit=$(json_get "$MANIFEST" "data.upstreams[$index].last_commit")

  if [ -z "$upstream_id" ] || [ -z "$upstream_repo" ]; then
    return 0
  fi

  echo ""
  echo "============================================================"
  log_info "Syncing upstream: $upstream_id ($upstream_repo)"
  echo "============================================================"

  # Clone the repo
  local repo_dir
  repo_dir=$(clone_upstream "$upstream_repo" "$upstream_branch") || {
    SYNC_SUMMARY="${SYNC_SUMMARY}\n  - $upstream_id: SKIPPED (clone failed)"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    return 0
  }

  # Get latest commit
  local latest_commit
  latest_commit=$(get_latest_commit "$repo_dir")

  # Check if we already have this commit
  if [ -n "$upstream_last_commit" ] && [ "$upstream_last_commit" = "$latest_commit" ]; then
    log_info "No changes since last sync (commit: ${latest_commit:0:8})"
    SYNC_SUMMARY="${SYNC_SUMMARY}\n  - $upstream_id: up to date"
    return 0
  fi

  # Determine the search path for skills/agents
  local search_path="$repo_dir"
  if [ -n "$upstream_skill_path" ]; then
    search_path="$repo_dir/$upstream_skill_path"
  fi

  if [ ! -d "$search_path" ]; then
    log_warn "Skill path not found: $upstream_skill_path in $upstream_repo"
    SYNC_SUMMARY="${SYNC_SUMMARY}\n  - $upstream_id: SKIPPED (path not found)"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    return 0
  fi

  # Find compatible skill files
  local found_count=0
  local synced_count=0

  while IFS= read -r -d '' skill_file; do
    if is_compatible_skill "$skill_file"; then
      found_count=$((found_count + 1))
      local relative_path="${skill_file#$search_path/}"
      local skill_basename
      skill_basename="$(basename "$skill_file")"
      local dest_file="$EXTERNAL_SKILLS_DIR/$upstream_id/$skill_basename"

      # Check if this is new or updated
      if [ -f "$dest_file" ]; then
        # Compare contents (ignoring attribution header)
        if diff -q <(tail -n +2 "$dest_file" 2>/dev/null || cat "$dest_file") \
                    "$skill_file" >/dev/null 2>&1; then
          continue  # No changes
        fi
        log_info "Updated: $relative_path"
        UPDATED_COUNT=$((UPDATED_COUNT + 1))
      else
        log_info "New: $relative_path"
        NEW_COUNT=$((NEW_COUNT + 1))
      fi

      copy_skill "$skill_file" "$upstream_id" "$upstream_repo"
      synced_count=$((synced_count + 1))
    fi
  done < <(find "$search_path" -maxdepth 3 -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.md" -o -name "*.json" \) -print0 2>/dev/null)

  log_success "Found $found_count compatible files, synced $synced_count"

  # Update the manifest
  if [ "$DRY_RUN" = false ]; then
    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    json_set "$MANIFEST" "
      data.upstreams[$index].last_sync = '$now';
      data.upstreams[$index].last_commit = '$latest_commit';
    "
  fi

  SYNC_SUMMARY="${SYNC_SUMMARY}\n  - $upstream_id: $synced_count synced ($found_count found)"
}

# ---- Main --------------------------------------------------------------------

main() {
  echo ""
  echo "============================================================"
  echo "  Vibecoded Orchestrator — Upstream Sync"
  echo "  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [ "$DRY_RUN" = true ]; then
    echo "  MODE: DRY RUN (no changes will be written)"
  fi
  echo "============================================================"

  # Read number of upstreams from manifest
  local upstream_count
  upstream_count=$(node -e "
    const data = JSON.parse(require('fs').readFileSync('$MANIFEST', 'utf8'));
    console.log(data.upstreams.length);
  " 2>/dev/null || echo "0")

  if [ "$upstream_count" -eq 0 ]; then
    log_error "No upstreams found in manifest: $MANIFEST"
    exit 1
  fi

  log_info "Found $upstream_count upstream registries to sync"

  # Sync each upstream
  for i in $(seq 0 $((upstream_count - 1))); do
    sync_upstream "$i"
  done

  # Update global sync timestamp
  if [ "$DRY_RUN" = false ]; then
    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    json_set "$MANIFEST" "data.last_global_sync = '$now'"
  fi

  # Print summary
  echo ""
  echo "============================================================"
  echo "  Sync Summary"
  echo "============================================================"
  echo -e "$SYNC_SUMMARY"
  echo ""
  echo "  New items:     $NEW_COUNT"
  echo "  Updated items: $UPDATED_COUNT"
  echo "  Skipped repos: $SKIPPED_COUNT"
  echo "============================================================"
  echo ""
}

main "$@"
