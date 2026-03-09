#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# lint-agents.sh — Validate agent YAML files for the Vibecoded Orchestrator
#
# Checks:
#   - Required fields: id, title, domain, reports_to, responsibilities,
#     expected_inputs, expected_outputs, system_prompt
#   - token_cap or token_cap_per_turn exists
#   - system_prompt is non-empty and > 50 words
#   - domain format (e.g., "tech/frontend", "marketing/email")
#   - id matches filename
#   - reports_to is a valid chief (CEO, CTO, CMO, COO)
#
# Usage:
#   ./scripts/lint-agents.sh                              # lint all agents
#   ./scripts/lint-agents.sh agents/pool/tech/            # lint tech agents only
#   ./scripts/lint-agents.sh agents/pool/tech/qa_engineer.yaml  # lint single file
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
ERROR_FILES=()

# ── Target ────────────────────────────────────────────────────────────────────
TARGET="${1:-}"

# ── yq detection ──────────────────────────────────────────────────────────────
HAS_YQ=false
if command -v yq &>/dev/null; then
  HAS_YQ=true
fi

echo ""
echo -e "${BOLD}${CYAN}Vibecoded Orchestrator — Agent YAML Linter${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

if $HAS_YQ; then
  echo -e "${GREEN}[ok]${RESET} yq detected — using yq for YAML parsing"
else
  echo -e "${YELLOW}[info]${RESET} yq not found — using bash fallback parser"
fi
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# YAML helpers (same approach as convert.sh)
# ──────────────────────────────────────────────────────────────────────────────

yaml_get() {
  local file="$1"
  local key="$2"
  if $HAS_YQ; then
    yq -r ".$key // \"\"" "$file" 2>/dev/null || echo ""
  else
    local val
    val=$(sed -n "s/^${key}:[[:space:]]*//p" "$file" | head -1)
    val="${val#\"}"
    val="${val%\"}"
    val="${val#\'}"
    val="${val%\'}"
    echo "$val"
  fi
}

yaml_has_key() {
  local file="$1"
  local key="$2"
  if $HAS_YQ; then
    local val
    val=$(yq -r ".$key // \"__MISSING__\"" "$file" 2>/dev/null || echo "__MISSING__")
    [[ "$val" != "__MISSING__" && "$val" != "null" ]]
  else
    grep -q "^${key}:" "$file" 2>/dev/null
  fi
}

yaml_has_list() {
  local file="$1"
  local key="$2"
  if $HAS_YQ; then
    local count
    count=$(yq -r ".$key | length // 0" "$file" 2>/dev/null || echo "0")
    [[ "$count" -gt 0 ]]
  else
    local found=false
    local in_key=false
    while IFS= read -r line; do
      if [[ "$line" =~ ^${key}: ]]; then
        # Check for inline array format: key: ["a", "b"]
        if [[ "$line" =~ \[.*\] ]]; then
          found=true
          break
        fi
        in_key=true
        continue
      fi
      if $in_key; then
        if [[ "$line" =~ ^[[:space:]]+- ]]; then
          found=true
          break
        else
          break
        fi
      fi
    done < "$file"
    $found
  fi
}

# Count words in system_prompt
count_system_prompt_words() {
  local file="$1"
  local prompt
  if $HAS_YQ; then
    prompt=$(yq -r '.system_prompt // ""' "$file" 2>/dev/null || echo "")
  else
    local in_block=false
    prompt=""
    while IFS= read -r line; do
      if [[ "$line" =~ ^system_prompt:\ *\| ]]; then
        in_block=true
        continue
      fi
      if $in_block; then
        if [[ "$line" =~ ^[a-z_]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
          break
        fi
        prompt+="${line} "
      fi
    done < "$file"
  fi
  echo "$prompt" | wc -w | tr -d ' '
}

# ──────────────────────────────────────────────────────────────────────────────
# Lint a single agent YAML file
# ──────────────────────────────────────────────────────────────────────────────

lint_agent() {
  local file="$1"
  local filename
  filename=$(basename "$file" .yaml)
  local file_errors=0
  local file_warnings=0

  ((TOTAL++)) || true

  local id title domain reports_to
  id=$(yaml_get "$file" "id")
  title=$(yaml_get "$file" "title")
  domain=$(yaml_get "$file" "domain")
  reports_to=$(yaml_get "$file" "reports_to")

  echo -e "${BLUE}[lint]${RESET} ${BOLD}${filename}.yaml${RESET}"

  # ── Required scalar fields ──────────────────────────────────────────────────

  # id
  if [[ -z "$id" ]]; then
    echo -e "  ${RED}[error]${RESET} Missing required field: id"
    ((file_errors++)) || true
  elif [[ "$id" != "$filename" ]]; then
    echo -e "  ${RED}[error]${RESET} id '${id}' does not match filename '${filename}.yaml'"
    ((file_errors++)) || true
  fi

  # title
  if [[ -z "$title" ]]; then
    echo -e "  ${RED}[error]${RESET} Missing required field: title"
    ((file_errors++)) || true
  fi

  # domain
  if [[ -z "$domain" ]]; then
    echo -e "  ${RED}[error]${RESET} Missing required field: domain"
    ((file_errors++)) || true
  else
    # Validate domain format: category/subcategory
    if [[ ! "$domain" =~ ^(tech|marketing)/[a-z_-]+$ ]]; then
      echo -e "  ${RED}[error]${RESET} Invalid domain format '${domain}' — expected 'tech/<sub>' or 'marketing/<sub>'"
      ((file_errors++)) || true
    fi
  fi

  # reports_to
  if [[ -z "$reports_to" ]]; then
    echo -e "  ${RED}[error]${RESET} Missing required field: reports_to"
    ((file_errors++)) || true
  else
    case "$reports_to" in
      CEO|CTO|CMO|COO) ;;
      *)
        echo -e "  ${YELLOW}[warn]${RESET}  reports_to '${reports_to}' is not a standard chief (CEO, CTO, CMO, COO)"
        ((file_warnings++)) || true
        ;;
    esac
  fi

  # ── Required list fields ────────────────────────────────────────────────────

  if ! yaml_has_list "$file" "responsibilities"; then
    echo -e "  ${RED}[error]${RESET} Missing or empty required field: responsibilities"
    ((file_errors++)) || true
  fi

  if ! yaml_has_list "$file" "expected_inputs"; then
    echo -e "  ${RED}[error]${RESET} Missing or empty required field: expected_inputs"
    ((file_errors++)) || true
  fi

  if ! yaml_has_list "$file" "expected_outputs"; then
    echo -e "  ${RED}[error]${RESET} Missing or empty required field: expected_outputs"
    ((file_errors++)) || true
  fi

  # ── token_cap ───────────────────────────────────────────────────────────────

  if ! yaml_has_key "$file" "token_cap" && ! yaml_has_key "$file" "token_cap_per_turn"; then
    echo -e "  ${RED}[error]${RESET} Missing required field: token_cap or token_cap_per_turn"
    ((file_errors++)) || true
  fi

  # ── system_prompt ───────────────────────────────────────────────────────────

  if ! yaml_has_key "$file" "system_prompt"; then
    echo -e "  ${RED}[error]${RESET} Missing required field: system_prompt"
    ((file_errors++)) || true
  else
    local word_count
    word_count=$(count_system_prompt_words "$file")
    if [[ "$word_count" -eq 0 ]]; then
      echo -e "  ${RED}[error]${RESET} system_prompt is empty"
      ((file_errors++)) || true
    elif [[ "$word_count" -lt 50 ]]; then
      echo -e "  ${RED}[error]${RESET} system_prompt is too short (${word_count} words, minimum 50)"
      ((file_errors++)) || true
    fi
  fi

  # ── Optional checks (warnings) ─────────────────────────────────────────────

  if ! yaml_has_key "$file" "mentors"; then
    echo -e "  ${YELLOW}[warn]${RESET}  Missing optional field: mentors"
    ((file_warnings++)) || true
  fi

  if ! yaml_has_key "$file" "mentor_lens"; then
    echo -e "  ${YELLOW}[warn]${RESET}  Missing optional field: mentor_lens"
    ((file_warnings++)) || true
  fi

  # ── Result ──────────────────────────────────────────────────────────────────

  ERRORS=$((ERRORS + file_errors))
  WARNINGS=$((WARNINGS + file_warnings))

  if [[ $file_errors -eq 0 && $file_warnings -eq 0 ]]; then
    echo -e "  ${GREEN}[pass]${RESET}  All checks passed"
    ((PASSED++)) || true
  elif [[ $file_errors -eq 0 ]]; then
    echo -e "  ${GREEN}[pass]${RESET}  Passed with ${file_warnings} warning(s)"
    ((PASSED++)) || true
  else
    echo -e "  ${RED}[fail]${RESET}  ${file_errors} error(s), ${file_warnings} warning(s)"
    ERROR_FILES+=("$filename")
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Collect files to lint
# ──────────────────────────────────────────────────────────────────────────────

AGENT_FILES=()

if [[ -n "$TARGET" ]]; then
  if [[ -f "$TARGET" ]]; then
    # Single file
    AGENT_FILES+=("$TARGET")
  elif [[ -d "$TARGET" ]]; then
    # Directory
    while IFS= read -r -d '' f; do
      AGENT_FILES+=("$f")
    done < <(find "$TARGET" -name "*.yaml" -print0 | sort -z)
  else
    # Try relative to ROOT_DIR
    if [[ -f "$ROOT_DIR/$TARGET" ]]; then
      AGENT_FILES+=("$ROOT_DIR/$TARGET")
    elif [[ -d "$ROOT_DIR/$TARGET" ]]; then
      while IFS= read -r -d '' f; do
        AGENT_FILES+=("$f")
      done < <(find "$ROOT_DIR/$TARGET" -name "*.yaml" -print0 | sort -z)
    else
      echo -e "${RED}Error: Target not found: ${TARGET}${RESET}"
      exit 1
    fi
  fi
else
  # Default: all agent directories
  for dir in "$ROOT_DIR/agents/pool/tech" "$ROOT_DIR/agents/pool/marketing"; do
    if [[ -d "$dir" ]]; then
      while IFS= read -r -d '' f; do
        AGENT_FILES+=("$f")
      done < <(find "$dir" -name "*.yaml" -print0 | sort -z)
    fi
  done
fi

if [[ ${#AGENT_FILES[@]} -eq 0 ]]; then
  echo -e "${YELLOW}No agent YAML files found.${RESET}"
  exit 0
fi

echo -e "${BLUE}Found ${#AGENT_FILES[@]} agent file(s) to lint${RESET}"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# Run linting
# ──────────────────────────────────────────────────────────────────────────────

for agent_file in "${AGENT_FILES[@]}"; do
  lint_agent "$agent_file"
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}Lint Summary${RESET}"
echo ""
echo -e "  Total agents:   ${BOLD}${TOTAL}${RESET}"
echo -e "  ${GREEN}Passed:${RESET}         ${BOLD}${PASSED}${RESET}"
echo -e "  ${RED}Errors:${RESET}         ${BOLD}${ERRORS}${RESET}"
echo -e "  ${YELLOW}Warnings:${RESET}       ${BOLD}${WARNINGS}${RESET}"
echo ""

if [[ ${#ERROR_FILES[@]} -gt 0 ]]; then
  echo -e "${RED}${BOLD}Files with errors:${RESET}"
  for ef in "${ERROR_FILES[@]}"; do
    echo -e "  ${RED}-${RESET} ${ef}.yaml"
  done
  echo ""
fi

if [[ $ERRORS -gt 0 ]]; then
  echo -e "${RED}${BOLD}Linting failed with ${ERRORS} error(s).${RESET}"
  exit 1
else
  echo -e "${GREEN}${BOLD}All agents passed linting.${RESET}"
  exit 0
fi
