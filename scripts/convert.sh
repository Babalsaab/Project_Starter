#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# convert.sh — Convert Vibecoded Orchestrator agent YAMLs to multi-tool formats
#
# Supported formats:
#   claude-code, cursor, aider, windsurf, opencode, antigravity, gemini-cli
#
# Usage:
#   ./scripts/convert.sh                        # convert all agents, all formats
#   ./scripts/convert.sh --format cursor        # convert all agents to Cursor only
#   ./scripts/convert.sh --agent backend_engineer  # convert one agent, all formats
#   ./scripts/convert.sh --format aider --agent qa_engineer
# ──────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INTEGRATIONS_DIR="$ROOT_DIR/integrations"
AGENT_DIRS=("$ROOT_DIR/agents/pool/tech" "$ROOT_DIR/agents/pool/marketing")

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Counters ──────────────────────────────────────────────────────────────────
TOTAL_AGENTS=0
TOTAL_FILES=0
ERRORS=0

# ── CLI flags ─────────────────────────────────────────────────────────────────
FORMAT_FILTER=""
AGENT_FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format)
      FORMAT_FILTER="$2"
      shift 2
      ;;
    --agent)
      AGENT_FILTER="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--format <format>] [--agent <agent_id>]"
      echo ""
      echo "Formats: claude-code, cursor, aider, windsurf, opencode, antigravity, gemini-cli"
      echo ""
      echo "Examples:"
      echo "  $0                                  # all agents, all formats"
      echo "  $0 --format cursor                  # all agents, Cursor only"
      echo "  $0 --agent backend_engineer         # one agent, all formats"
      echo "  $0 --format aider --agent qa_engineer"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${RESET}"
      exit 1
      ;;
  esac
done

ALL_FORMATS=("claude-code" "cursor" "aider" "windsurf" "opencode" "antigravity" "gemini-cli")

if [[ -n "$FORMAT_FILTER" ]]; then
  valid=false
  for f in "${ALL_FORMATS[@]}"; do
    [[ "$f" == "$FORMAT_FILTER" ]] && valid=true
  done
  if ! $valid; then
    echo -e "${RED}Error: Unknown format '$FORMAT_FILTER'${RESET}"
    echo "Valid formats: ${ALL_FORMATS[*]}"
    exit 1
  fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# YAML parser — uses yq if available, otherwise pure bash fallback
# ──────────────────────────────────────────────────────────────────────────────
HAS_YQ=false
if command -v yq &>/dev/null; then
  HAS_YQ=true
fi

# Extract a scalar YAML field value (single line). Works for simple key: "value" or key: value
yaml_get() {
  local file="$1"
  local key="$2"
  if $HAS_YQ; then
    yq -r ".$key // \"\"" "$file" 2>/dev/null || echo ""
  else
    # Bash fallback: match top-level key and strip quotes
    local val
    val=$(sed -n "s/^${key}:[[:space:]]*//p" "$file" | head -1)
    # Strip surrounding quotes
    val="${val#\"}"
    val="${val%\"}"
    val="${val#\'}"
    val="${val%\'}"
    echo "$val"
  fi
}

# Extract the multiline system_prompt block
yaml_get_system_prompt() {
  local file="$1"
  if $HAS_YQ; then
    yq -r '.system_prompt // ""' "$file" 2>/dev/null || echo ""
  else
    # Bash fallback: extract everything between system_prompt: | and the end of the file
    # (system_prompt is always the last field in agent YAMLs)
    local in_block=false
    local result=""
    while IFS= read -r line; do
      if [[ "$line" =~ ^system_prompt:\ *\| ]]; then
        in_block=true
        continue
      fi
      if $in_block; then
        # If we hit a top-level key (no indent), stop — but system_prompt is last, so read to EOF
        if [[ "$line" =~ ^[a-z_]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
          break
        fi
        # Strip the leading 2-space indent
        local stripped="${line#  }"
        result+="${stripped}"$'\n'
      fi
    done < "$file"
    echo "$result"
  fi
}

# Extract responsibilities as a newline-separated list
yaml_get_list() {
  local file="$1"
  local key="$2"
  if $HAS_YQ; then
    yq -r ".${key}[]? // empty" "$file" 2>/dev/null || echo ""
  else
    local in_list=false
    while IFS= read -r line; do
      if [[ "$line" =~ ^${key}: ]]; then
        # Handle inline array format: key: ["a", "b", "c"]
        if [[ "$line" =~ \[(.+)\] ]]; then
          local inner="${BASH_REMATCH[1]}"
          # Split by comma, strip quotes and whitespace
          while IFS=',' read -ra items; do
            for item in "${items[@]}"; do
              item=$(echo "$item" | sed 's/^[[:space:]]*"//; s/"[[:space:]]*$//')
              [[ -n "$item" ]] && echo "$item"
            done
          done <<< "$inner"
          return
        fi
        in_list=true
        continue
      fi
      if $in_list; then
        if [[ "$line" =~ ^[[:space:]]+- ]]; then
          local item="${line#*- }"
          item="${item#\"}"
          item="${item%\"}"
          echo "$item"
        else
          break
        fi
      fi
    done < "$file"
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Format generators
# ──────────────────────────────────────────────────────────────────────────────

generate_claude_code() {
  local file="$1"
  local id title domain prompt
  id=$(yaml_get "$file" "id")
  title=$(yaml_get "$file" "title")
  domain=$(yaml_get "$file" "domain")
  prompt=$(yaml_get_system_prompt "$file")

  local outdir="$INTEGRATIONS_DIR/claude-code"
  mkdir -p "$outdir"
  local outfile="$outdir/${id}.md"

  cat > "$outfile" <<MDEOF
# ${title}

**Agent ID:** ${id}
**Domain:** ${domain}

---

${prompt}
MDEOF

  ((TOTAL_FILES++)) || true
}

generate_cursor() {
  local file="$1"
  local id title domain prompt
  id=$(yaml_get "$file" "id")
  title=$(yaml_get "$file" "title")
  domain=$(yaml_get "$file" "domain")
  prompt=$(yaml_get_system_prompt "$file")

  # Map domain to glob patterns
  local globs=""
  case "$domain" in
    tech/frontend)   globs="src/**/*.{ts,tsx,js,jsx,css}" ;;
    tech/backend)    globs="src/**/*.ts,api/**/*.ts,server/**/*.ts" ;;
    tech/mobile*)    globs="**/*.{swift,kt,dart}" ;;
    tech/devops)     globs="**/{Dockerfile,*.yml,*.yaml,.github/**}" ;;
    tech/security*)  globs="**/*.{ts,js,py,go}" ;;
    tech/qa)         globs="**/*.{test,spec}.{ts,tsx,js,jsx}" ;;
    tech/design*)    globs="src/components/**/*.{tsx,css}" ;;
    tech/data)       globs="**/*.{sql,prisma,ts}" ;;
    marketing/*)     globs="**/*.{md,mdx,txt,html}" ;;
    *)               globs="**/*" ;;
  esac

  local outdir="$INTEGRATIONS_DIR/cursor"
  mkdir -p "$outdir"
  local outfile="$outdir/${id}.mdc"

  cat > "$outfile" <<MDCEOF
---
description: "${title} — ${domain} specialist agent from the Vibecoded Orchestrator"
globs: "${globs}"
alwaysApply: false
---

# ${title}

${prompt}
MDCEOF

  ((TOTAL_FILES++)) || true
}

# Aider: single CONVENTIONS.md file
AIDER_CONTENT=""

generate_aider() {
  local file="$1"
  local id title domain prompt
  id=$(yaml_get "$file" "id")
  title=$(yaml_get "$file" "title")
  domain=$(yaml_get "$file" "domain")
  prompt=$(yaml_get_system_prompt "$file")

  AIDER_CONTENT+="
## ${title} (\`${id}\`) — ${domain}

${prompt}
---

"
}

flush_aider() {
  local outdir="$INTEGRATIONS_DIR/aider"
  mkdir -p "$outdir"
  local outfile="$outdir/CONVENTIONS.md"

  cat > "$outfile" <<AEOF
# Vibecoded Orchestrator — Agent Conventions for Aider

This file contains all specialist agent rules from the Vibecoded Orchestrator.
Aider will use these conventions when working on code in this project.

---

${AIDER_CONTENT}
AEOF

  ((TOTAL_FILES++)) || true
}

# Windsurf: single .windsurfrules file
WINDSURF_CONTENT=""

generate_windsurf() {
  local file="$1"
  local id title domain prompt
  id=$(yaml_get "$file" "id")
  title=$(yaml_get "$file" "title")
  domain=$(yaml_get "$file" "domain")
  prompt=$(yaml_get_system_prompt "$file")

  WINDSURF_CONTENT+="
### ${title} (\`${id}\`) — ${domain}

${prompt}
---

"
}

flush_windsurf() {
  local outdir="$INTEGRATIONS_DIR/windsurf"
  mkdir -p "$outdir"
  local outfile="$outdir/.windsurfrules"

  cat > "$outfile" <<WEOF
# Vibecoded Orchestrator — Agent Rules for Windsurf

These rules define the specialist agent behaviors from the Vibecoded Orchestrator.
Windsurf will apply the relevant agent's rules based on the task context.

---

${WINDSURF_CONTENT}
WEOF

  ((TOTAL_FILES++)) || true
}

generate_opencode() {
  local file="$1"
  local id title domain prompt
  id=$(yaml_get "$file" "id")
  title=$(yaml_get "$file" "title")
  domain=$(yaml_get "$file" "domain")
  prompt=$(yaml_get_system_prompt "$file")

  local responsibilities
  responsibilities=$(yaml_get_list "$file" "responsibilities")

  local outdir="$INTEGRATIONS_DIR/opencode"
  mkdir -p "$outdir"
  local outfile="$outdir/${id}.md"

  local resp_md=""
  while IFS= read -r line; do
    [[ -n "$line" ]] && resp_md+="- ${line}"$'\n'
  done <<< "$responsibilities"

  cat > "$outfile" <<OCEOF
# ${title}

**ID:** ${id}
**Domain:** ${domain}

## Responsibilities

${resp_md}

## System Prompt

${prompt}
OCEOF

  ((TOTAL_FILES++)) || true
}

generate_antigravity() {
  local file="$1"
  local id title domain prompt
  id=$(yaml_get "$file" "id")
  title=$(yaml_get "$file" "title")
  domain=$(yaml_get "$file" "domain")
  prompt=$(yaml_get_system_prompt "$file")

  # Convert id to kebab-case for agentskills.io spec
  local skill_name="${id//_/-}"

  # Truncate description to < 1024 chars for spec compliance
  local short_desc
  short_desc=$(echo "$prompt" | head -1 | cut -c1-200)

  local outdir="$INTEGRATIONS_DIR/antigravity/${skill_name}"
  mkdir -p "$outdir"
  local outfile="$outdir/SKILL.md"

  cat > "$outfile" <<AGEOF
---
name: ${skill_name}
description: "${short_desc}"
version: "2.0.0"
domain: "${domain}"
source: "vibecoded-orchestrator"
---

# ${title}

${prompt}
AGEOF

  ((TOTAL_FILES++)) || true
}

generate_gemini_cli() {
  local file="$1"
  local id title domain prompt
  id=$(yaml_get "$file" "id")
  title=$(yaml_get "$file" "title")
  domain=$(yaml_get "$file" "domain")
  prompt=$(yaml_get_system_prompt "$file")

  local skill_name="${id//_/-}"

  local short_desc
  short_desc=$(echo "$prompt" | head -1 | cut -c1-200)

  local outdir="$INTEGRATIONS_DIR/gemini-cli/${skill_name}"
  mkdir -p "$outdir"
  local outfile="$outdir/SKILL.md"

  cat > "$outfile" <<GCEOF
---
name: ${skill_name}
description: "${short_desc}"
version: "2.0.0"
domain: "${domain}"
tool: "gemini-cli"
---

# ${title}

${prompt}
GCEOF

  ((TOTAL_FILES++)) || true
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${CYAN}Vibecoded Orchestrator — Agent Format Converter${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

if $HAS_YQ; then
  echo -e "${GREEN}[ok]${RESET} yq detected — using yq for YAML parsing"
else
  echo -e "${YELLOW}[warn]${RESET} yq not found — using bash fallback parser"
  echo -e "       Install yq for better parsing: brew install yq"
fi

if [[ -n "$FORMAT_FILTER" ]]; then
  echo -e "${BLUE}[filter]${RESET} Format: ${BOLD}${FORMAT_FILTER}${RESET}"
fi
if [[ -n "$AGENT_FILTER" ]]; then
  echo -e "${BLUE}[filter]${RESET} Agent: ${BOLD}${AGENT_FILTER}${RESET}"
fi

echo ""

# Collect agent YAML files
AGENT_FILES=()
for dir in "${AGENT_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    while IFS= read -r -d '' f; do
      AGENT_FILES+=("$f")
    done < <(find "$dir" -name "*.yaml" -print0 | sort -z)
  fi
done

if [[ ${#AGENT_FILES[@]} -eq 0 ]]; then
  echo -e "${RED}Error: No agent YAML files found.${RESET}"
  exit 1
fi

# Determine which formats to generate
if [[ -n "$FORMAT_FILTER" ]]; then
  FORMATS=("$FORMAT_FILTER")
else
  FORMATS=("${ALL_FORMATS[@]}")
fi

# Process each agent
for agent_file in "${AGENT_FILES[@]}"; do
  agent_id=$(yaml_get "$agent_file" "id")

  # Apply agent filter
  if [[ -n "$AGENT_FILTER" && "$agent_id" != "$AGENT_FILTER" ]]; then
    continue
  fi

  agent_title=$(yaml_get "$agent_file" "title")
  echo -e "${BLUE}[agent]${RESET} ${BOLD}${agent_title}${RESET} (${agent_id})"

  ((TOTAL_AGENTS++)) || true

  for fmt in "${FORMATS[@]}"; do
    case "$fmt" in
      claude-code)   generate_claude_code "$agent_file" ;;
      cursor)        generate_cursor "$agent_file" ;;
      aider)         generate_aider "$agent_file" ;;
      windsurf)      generate_windsurf "$agent_file" ;;
      opencode)      generate_opencode "$agent_file" ;;
      antigravity)   generate_antigravity "$agent_file" ;;
      gemini-cli)    generate_gemini_cli "$agent_file" ;;
    esac
  done
done

# Flush aggregated formats
for fmt in "${FORMATS[@]}"; do
  case "$fmt" in
    aider)    flush_aider ;;
    windsurf) flush_windsurf ;;
  esac
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}Conversion complete!${RESET}"
echo ""
echo -e "  Agents processed:  ${BOLD}${TOTAL_AGENTS}${RESET}"
echo -e "  Files generated:   ${BOLD}${TOTAL_FILES}${RESET}"
echo -e "  Formats:           ${BOLD}${FORMATS[*]}${RESET}"
echo -e "  Output directory:  ${BOLD}${INTEGRATIONS_DIR}${RESET}"
echo ""

if [[ $ERRORS -gt 0 ]]; then
  echo -e "${RED}Errors encountered: ${ERRORS}${RESET}"
  exit 1
fi

# List output structure
echo -e "${BLUE}Output structure:${RESET}"
for fmt in "${FORMATS[@]}"; do
  local_dir="$INTEGRATIONS_DIR/$fmt"
  if [[ -d "$local_dir" ]]; then
    count=$(find "$local_dir" -type f | wc -l | tr -d ' ')
    echo -e "  ${GREEN}${fmt}/${RESET} — ${count} file(s)"
  fi
done
echo ""
