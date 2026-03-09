#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# validate-skills.sh — Validate skills follow the agentskills.io specification
#
# Checks:
#   - Each skill directory has SKILL.md
#   - YAML frontmatter has required fields (name, description)
#   - name matches directory name
#   - description is under 1024 characters
#   - name is lowercase-hyphenated, max 64 characters
#   - Warns on missing optional fields (version, domain)
#
# Usage:
#   ./scripts/validate-skills.sh                    # validate all skills
#   ./scripts/validate-skills.sh path/to/skills/    # validate specific directory
# ──────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Counters ──────────────────────────────────────────────────────────────────
TOTAL=0
PASSED=0
ERRORS=0
WARNINGS=0

# ── Target directory ──────────────────────────────────────────────────────────
SKILLS_DIR="${1:-$ROOT_DIR/skills}"

# Also check integrations if they exist
EXTRA_DIRS=()
if [[ -d "$ROOT_DIR/integrations/antigravity" ]]; then
  EXTRA_DIRS+=("$ROOT_DIR/integrations/antigravity")
fi
if [[ -d "$ROOT_DIR/integrations/gemini-cli" ]]; then
  EXTRA_DIRS+=("$ROOT_DIR/integrations/gemini-cli")
fi

echo ""
echo -e "${BOLD}${CYAN}Vibecoded Orchestrator — Skill Validator (agentskills.io spec)${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# Frontmatter extraction helpers
# ──────────────────────────────────────────────────────────────────────────────

# Extract a field from YAML frontmatter (between --- delimiters)
extract_frontmatter_field() {
  local file="$1"
  local field="$2"
  # Read between the first pair of --- lines
  local in_frontmatter=false
  local found_first=false
  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if ! $found_first; then
        found_first=true
        in_frontmatter=true
        continue
      else
        break
      fi
    fi
    if $in_frontmatter; then
      if [[ "$line" =~ ^${field}:[[:space:]]*(.*) ]]; then
        local val="${BASH_REMATCH[1]}"
        # Strip surrounding quotes
        val="${val#\"}"
        val="${val%\"}"
        val="${val#\'}"
        val="${val%\'}"
        echo "$val"
        return
      fi
    fi
  done < "$file"
}

# Check if file has YAML frontmatter
has_frontmatter() {
  local file="$1"
  local first_line
  first_line=$(head -1 "$file" 2>/dev/null)
  [[ "$first_line" == "---" ]]
}

# ──────────────────────────────────────────────────────────────────────────────
# Validate a single skill directory
# ──────────────────────────────────────────────────────────────────────────────

validate_skill() {
  local skill_dir="$1"
  local dir_name
  dir_name=$(basename "$skill_dir")
  local skill_file="$skill_dir/SKILL.md"
  local has_error=false
  local has_warning=false

  ((TOTAL++)) || true

  echo -e "${BLUE}[check]${RESET} ${BOLD}${dir_name}${RESET}"

  # Check SKILL.md exists
  if [[ ! -f "$skill_file" ]]; then
    echo -e "  ${RED}[error]${RESET} Missing SKILL.md"
    ((ERRORS++)) || true
    return
  fi

  # Check frontmatter exists
  if ! has_frontmatter "$skill_file"; then
    echo -e "  ${RED}[error]${RESET} Missing YAML frontmatter (must start with ---)"
    ((ERRORS++)) || true
    return
  fi

  # Extract fields
  local name description version domain

  name=$(extract_frontmatter_field "$skill_file" "name")
  description=$(extract_frontmatter_field "$skill_file" "description")
  version=$(extract_frontmatter_field "$skill_file" "version")
  domain=$(extract_frontmatter_field "$skill_file" "domain")

  # Required: name
  if [[ -z "$name" ]]; then
    echo -e "  ${RED}[error]${RESET} Missing required field: name"
    has_error=true
    ((ERRORS++)) || true
  else
    # Validate name format: lowercase-hyphenated
    if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
      echo -e "  ${RED}[error]${RESET} name '${name}' must be lowercase-hyphenated (a-z, 0-9, hyphens only)"
      has_error=true
      ((ERRORS++)) || true
    fi

    # Validate name length: max 64 chars
    if [[ ${#name} -gt 64 ]]; then
      echo -e "  ${RED}[error]${RESET} name '${name}' exceeds 64 character limit (${#name} chars)"
      has_error=true
      ((ERRORS++)) || true
    fi

    # Validate name matches directory name
    if [[ "$name" != "$dir_name" ]]; then
      echo -e "  ${RED}[error]${RESET} name '${name}' does not match directory name '${dir_name}'"
      has_error=true
      ((ERRORS++)) || true
    fi
  fi

  # Required: description
  if [[ -z "$description" ]]; then
    echo -e "  ${RED}[error]${RESET} Missing required field: description"
    has_error=true
    ((ERRORS++)) || true
  else
    # Validate description length: under 1024 chars
    if [[ ${#description} -gt 1024 ]]; then
      echo -e "  ${RED}[error]${RESET} description exceeds 1024 character limit (${#description} chars)"
      has_error=true
      ((ERRORS++)) || true
    fi
  fi

  # Optional: version
  if [[ -z "$version" ]]; then
    echo -e "  ${YELLOW}[warn]${RESET}  Missing optional field: version"
    has_warning=true
    ((WARNINGS++)) || true
  fi

  # Optional: domain
  if [[ -z "$domain" ]]; then
    echo -e "  ${YELLOW}[warn]${RESET}  Missing optional field: domain"
    has_warning=true
    ((WARNINGS++)) || true
  fi

  # Check SKILL.md has content beyond frontmatter
  local content_lines
  content_lines=$(sed -n '/^---$/,/^---$/d; p' "$skill_file" | grep -c '[^ ]' 2>/dev/null || echo "0")
  if [[ "$content_lines" -lt 3 ]]; then
    echo -e "  ${YELLOW}[warn]${RESET}  SKILL.md has very little content beyond frontmatter (${content_lines} non-empty lines)"
    has_warning=true
    ((WARNINGS++)) || true
  fi

  if ! $has_error && ! $has_warning; then
    echo -e "  ${GREEN}[pass]${RESET}  All checks passed"
    ((PASSED++)) || true
  elif ! $has_error; then
    ((PASSED++)) || true
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Main — scan skill directories
# ──────────────────────────────────────────────────────────────────────────────

ALL_SKILL_DIRS=()

# Collect from primary skills directory
if [[ -d "$SKILLS_DIR" ]]; then
  echo -e "${BLUE}Scanning:${RESET} ${SKILLS_DIR}"
  while IFS= read -r -d '' d; do
    # Only include directories that are actual skill dirs (contain files or are expected to have SKILL.md)
    if [[ -d "$d" && "$(basename "$d")" != "external" ]]; then
      ALL_SKILL_DIRS+=("$d")
    fi
  done < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
fi

# Collect from extra directories
if [[ ${#EXTRA_DIRS[@]} -gt 0 ]]; then
  for extra_dir in "${EXTRA_DIRS[@]}"; do
    echo -e "${BLUE}Scanning:${RESET} ${extra_dir}"
    while IFS= read -r -d '' d; do
      if [[ -d "$d" ]]; then
        ALL_SKILL_DIRS+=("$d")
      fi
    done < <(find "$extra_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  done
fi

echo ""

if [[ ${#ALL_SKILL_DIRS[@]} -eq 0 ]]; then
  echo -e "${YELLOW}No skill directories found.${RESET}"
  exit 0
fi

for skill_dir in "${ALL_SKILL_DIRS[@]}"; do
  validate_skill "$skill_dir"
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}Validation Summary${RESET}"
echo ""
echo -e "  Total skills:   ${BOLD}${TOTAL}${RESET}"
echo -e "  ${GREEN}Passed:${RESET}         ${BOLD}${PASSED}${RESET}"
echo -e "  ${RED}Errors:${RESET}         ${BOLD}${ERRORS}${RESET}"
echo -e "  ${YELLOW}Warnings:${RESET}       ${BOLD}${WARNINGS}${RESET}"
echo ""

if [[ $ERRORS -gt 0 ]]; then
  echo -e "${RED}${BOLD}Validation failed with ${ERRORS} error(s).${RESET}"
  exit 1
else
  echo -e "${GREEN}${BOLD}All skills valid.${RESET}"
  exit 0
fi
