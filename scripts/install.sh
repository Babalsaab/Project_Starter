#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# install.sh — Interactive installer for Vibecoded Orchestrator cross-tool support
#
# Auto-detects installed AI coding tools and copies agent/skill integrations
# to the correct directories for each tool.
#
# Usage:
#   ./scripts/install.sh              # interactive mode
#   ./scripts/install.sh --all        # install for all detected tools
#   ./scripts/install.sh --list       # list detected tools only
# ──────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONVERT_SCRIPT="$SCRIPT_DIR/convert.sh"
INTEGRATIONS_DIR="$ROOT_DIR/integrations"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── CLI flags ─────────────────────────────────────────────────────────────────
INSTALL_ALL=false
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      INSTALL_ALL=true
      shift
      ;;
    --list)
      LIST_ONLY=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--all] [--list]"
      echo ""
      echo "  --all   Install for all detected tools without prompting"
      echo "  --list  List detected tools and exit"
      echo ""
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${RESET}"
      exit 1
      ;;
  esac
done

# ──────────────────────────────────────────────────────────────────────────────
# Tool definitions — parallel indexed arrays (bash 3.x compatible)
# ──────────────────────────────────────────────────────────────────────────────

TOOL_NAMES=("claude-code" "cursor" "aider" "windsurf" "opencode" "antigravity" "gemini-cli")
TOOL_LABELS=("Claude Code" "Cursor" "Aider" "Windsurf" "OpenCode" "AntiGravity" "Gemini CLI")
TOOL_DETECTED=()
TOOL_INSTALL_DIRS=()

# ──────────────────────────────────────────────────────────────────────────────
# Tool detection
# ──────────────────────────────────────────────────────────────────────────────

detect_tools() {
  # Claude Code (index 0)
  if [[ -d "$HOME/.claude" ]] || command -v claude &>/dev/null; then
    TOOL_DETECTED[0]=true
  else
    TOOL_DETECTED[0]=false
  fi
  TOOL_INSTALL_DIRS[0]="$ROOT_DIR"

  # Cursor (index 1)
  if [[ -d "$HOME/.cursor" ]] || [[ -d "$HOME/Library/Application Support/Cursor" ]] || command -v cursor &>/dev/null; then
    TOOL_DETECTED[1]=true
  else
    TOOL_DETECTED[1]=false
  fi
  TOOL_INSTALL_DIRS[1]="$ROOT_DIR/.cursor/rules"

  # Aider (index 2)
  if command -v aider &>/dev/null || [[ -f "$ROOT_DIR/.aider.conf.yml" ]]; then
    TOOL_DETECTED[2]=true
  else
    TOOL_DETECTED[2]=false
  fi
  TOOL_INSTALL_DIRS[2]="$ROOT_DIR"

  # Windsurf (index 3)
  if [[ -d "$HOME/.codeium" ]] || [[ -d "$HOME/.windsurf" ]] || [[ -d "$HOME/Library/Application Support/Windsurf" ]]; then
    TOOL_DETECTED[3]=true
  else
    TOOL_DETECTED[3]=false
  fi
  TOOL_INSTALL_DIRS[3]="$ROOT_DIR"

  # OpenCode (index 4)
  if [[ -d "$HOME/.config/opencode" ]] || command -v opencode &>/dev/null; then
    TOOL_DETECTED[4]=true
  else
    TOOL_DETECTED[4]=false
  fi
  TOOL_INSTALL_DIRS[4]="$ROOT_DIR/.opencode/agents"

  # AntiGravity (index 5)
  if [[ -d "$HOME/.antigravity" ]] || command -v antigravity &>/dev/null; then
    TOOL_DETECTED[5]=true
  else
    TOOL_DETECTED[5]=false
  fi
  TOOL_INSTALL_DIRS[5]="$ROOT_DIR/.antigravity/skills"

  # Gemini CLI (index 6)
  if command -v gemini &>/dev/null || [[ -d "$HOME/.gemini" ]]; then
    TOOL_DETECTED[6]=true
  else
    TOOL_DETECTED[6]=false
  fi
  TOOL_INSTALL_DIRS[6]="$ROOT_DIR/.gemini/extensions"
}

# ──────────────────────────────────────────────────────────────────────────────
# Display
# ──────────────────────────────────────────────────────────────────────────────

print_header() {
  echo ""
  echo -e "${BOLD}${CYAN}Vibecoded Orchestrator — Cross-Tool Installer${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${DIM}74 specialist agents | 15 mentors | 78 personas${RESET}"
  echo ""
}

print_detection_results() {
  echo -e "${BOLD}Detected AI Coding Tools:${RESET}"
  echo ""

  local detected_count=0
  for i in "${!TOOL_NAMES[@]}"; do
    local label="${TOOL_LABELS[$i]}"
    if [[ "${TOOL_DETECTED[$i]}" == "true" ]]; then
      echo -e "  ${GREEN}[detected]${RESET}  ${BOLD}${label}${RESET}"
      ((detected_count++)) || true
    else
      echo -e "  ${DIM}[not found]${RESET} ${DIM}${label}${RESET}"
    fi
  done

  echo ""
  echo -e "  ${BLUE}${detected_count} tool(s) detected${RESET}"
  echo ""
}

# ──────────────────────────────────────────────────────────────────────────────
# Installation
# ──────────────────────────────────────────────────────────────────────────────

install_for_tool() {
  local tool="$1"
  local format="$tool"
  local install_dir=""
  local source_dir="$INTEGRATIONS_DIR/$format"

  # Look up install dir by tool name
  for i in "${!TOOL_NAMES[@]}"; do
    if [[ "${TOOL_NAMES[$i]}" == "$tool" ]]; then
      install_dir="${TOOL_INSTALL_DIRS[$i]}"
      break
    fi
  done

  echo -e "${BLUE}[install]${RESET} Converting agents for ${BOLD}${tool}${RESET}..."

  # Run conversion for this format
  bash "$CONVERT_SCRIPT" --format "$format"

  if [[ ! -d "$source_dir" ]]; then
    echo -e "${RED}[error]${RESET} Conversion output not found at $source_dir"
    return 1
  fi

  echo -e "${BLUE}[install]${RESET} Copying to ${BOLD}${install_dir}${RESET}..."

  case "$tool" in
    claude-code)
      echo -e "${GREEN}[done]${RESET}  Claude Code integration files at: ${source_dir}"
      echo -e "${DIM}         Claude Code uses the MCP server directly. Files available for reference.${RESET}"
      ;;
    cursor)
      mkdir -p "$install_dir"
      cp -r "$source_dir"/*.mdc "$install_dir/" 2>/dev/null || true
      echo -e "${GREEN}[done]${RESET}  Cursor rules installed to: ${install_dir}"
      echo -e "${DIM}         Restart Cursor to pick up new rules.${RESET}"
      ;;
    aider)
      if [[ -f "$source_dir/CONVENTIONS.md" ]]; then
        cp "$source_dir/CONVENTIONS.md" "$install_dir/CONVENTIONS.md"
        echo -e "${GREEN}[done]${RESET}  Aider conventions at: ${install_dir}/CONVENTIONS.md"
        echo -e "${DIM}         Aider will auto-read CONVENTIONS.md from the project root.${RESET}"
      fi
      ;;
    windsurf)
      if [[ -f "$source_dir/.windsurfrules" ]]; then
        cp "$source_dir/.windsurfrules" "$install_dir/.windsurfrules"
        echo -e "${GREEN}[done]${RESET}  Windsurf rules at: ${install_dir}/.windsurfrules"
        echo -e "${DIM}         Windsurf will auto-read .windsurfrules from the project root.${RESET}"
      fi
      ;;
    opencode)
      mkdir -p "$install_dir"
      cp -r "$source_dir"/*.md "$install_dir/" 2>/dev/null || true
      echo -e "${GREEN}[done]${RESET}  OpenCode agents at: ${install_dir}"
      ;;
    antigravity)
      mkdir -p "$install_dir"
      cp -r "$source_dir"/* "$install_dir/" 2>/dev/null || true
      echo -e "${GREEN}[done]${RESET}  AntiGravity skills at: ${install_dir}"
      echo -e "${DIM}         Skills follow agentskills.io spec with SKILL.md per agent.${RESET}"
      ;;
    gemini-cli)
      mkdir -p "$install_dir"
      cp -r "$source_dir"/* "$install_dir/" 2>/dev/null || true
      echo -e "${GREEN}[done]${RESET}  Gemini CLI extensions at: ${install_dir}"
      ;;
  esac

  echo ""
}

# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

get_label_for_tool() {
  local tool="$1"
  for i in "${!TOOL_NAMES[@]}"; do
    if [[ "${TOOL_NAMES[$i]}" == "$tool" ]]; then
      echo "${TOOL_LABELS[$i]}"
      return
    fi
  done
  echo "$tool"
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

print_header
detect_tools
print_detection_results

if $LIST_ONLY; then
  exit 0
fi

# Collect detected tools
DETECTED_TOOLS=()

for i in "${!TOOL_NAMES[@]}"; do
  if [[ "${TOOL_DETECTED[$i]}" == "true" ]]; then
    DETECTED_TOOLS+=("${TOOL_NAMES[$i]}")
  fi
done

if [[ ${#DETECTED_TOOLS[@]} -eq 0 ]]; then
  echo -e "${YELLOW}No supported AI coding tools detected.${RESET}"
  echo ""
  echo "You can still generate integration files manually:"
  echo "  ./scripts/convert.sh --format cursor"
  echo ""
  echo "Supported tools: claude-code, cursor, aider, windsurf, opencode, antigravity, gemini-cli"
  exit 0
fi

# Determine which tools to install for
INSTALL_TOOLS=()

if $INSTALL_ALL; then
  INSTALL_TOOLS=("${DETECTED_TOOLS[@]}")
else
  echo -e "${BOLD}Select tools to install for:${RESET}"
  echo ""

  for i in "${!DETECTED_TOOLS[@]}"; do
    local_tool="${DETECTED_TOOLS[$i]}"
    local_label=$(get_label_for_tool "$local_tool")
    echo -e "  ${BOLD}$((i+1))${RESET}) ${local_label}"
  done
  echo -e "  ${BOLD}a${RESET}) All detected tools"
  echo -e "  ${BOLD}q${RESET}) Quit"
  echo ""

  read -rp "Enter choices (e.g., 1,3 or a): " choices

  if [[ "$choices" == "q" || "$choices" == "Q" ]]; then
    echo "Cancelled."
    exit 0
  fi

  if [[ "$choices" == "a" || "$choices" == "A" ]]; then
    INSTALL_TOOLS=("${DETECTED_TOOLS[@]}")
  else
    IFS=',' read -ra selections <<< "$choices"
    for sel in "${selections[@]}"; do
      sel=$(echo "$sel" | tr -d ' ')
      if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#DETECTED_TOOLS[@]} )); then
        INSTALL_TOOLS+=("${DETECTED_TOOLS[$((sel-1))]}")
      else
        echo -e "${YELLOW}Skipping invalid selection: ${sel}${RESET}"
      fi
    done
  fi
fi

if [[ ${#INSTALL_TOOLS[@]} -eq 0 ]]; then
  echo -e "${YELLOW}No tools selected. Exiting.${RESET}"
  exit 0
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}Installing for ${#INSTALL_TOOLS[@]} tool(s)...${RESET}"
echo ""

INSTALL_COUNT=0

for tool in "${INSTALL_TOOLS[@]}"; do
  install_for_tool "$tool"
  ((INSTALL_COUNT++)) || true
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}Installation complete!${RESET}"
echo ""
echo -e "  Tools configured:  ${BOLD}${INSTALL_COUNT}${RESET}"
echo -e "  Integration files: ${BOLD}${INTEGRATIONS_DIR}${RESET}"
echo ""
echo -e "${BOLD}Next steps:${RESET}"

for tool in "${INSTALL_TOOLS[@]}"; do
  case "$tool" in
    claude-code)
      echo -e "  ${GREEN}Claude Code${RESET}: Already active — use the MCP orchestrator tools"
      ;;
    cursor)
      echo -e "  ${GREEN}Cursor${RESET}: Restart Cursor. Rules appear in Settings > Rules"
      ;;
    aider)
      echo -e "  ${GREEN}Aider${RESET}: Run \`aider\` in the project root — CONVENTIONS.md is auto-loaded"
      ;;
    windsurf)
      echo -e "  ${GREEN}Windsurf${RESET}: Open the project in Windsurf — .windsurfrules is auto-loaded"
      ;;
    opencode)
      echo -e "  ${GREEN}OpenCode${RESET}: Agent files are in .opencode/agents/"
      ;;
    antigravity)
      echo -e "  ${GREEN}AntiGravity${RESET}: Skills installed to .antigravity/skills/"
      ;;
    gemini-cli)
      echo -e "  ${GREEN}Gemini CLI${RESET}: Extensions installed to .gemini/extensions/"
      ;;
  esac
done
echo ""
