#!/bin/bash

# =============================================================================
# CTO Codebase Evaluation Suite - Installation Script (macOS/Linux)
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║         CTO Codebase Evaluation Suite - Installer                     ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux*)     OS_NAME="Linux";;
    Darwin*)    OS_NAME="macOS";;
    CYGWIN*|MINGW*|MSYS*) OS_NAME="Windows";;
    *)          OS_NAME="Unknown";;
esac

echo -e "${BLUE}Detected OS:${NC} $OS_NAME"
echo ""

# =============================================================================
# Check and Install Dependencies
# =============================================================================

check_command() {
    command -v "$1" &> /dev/null
}

install_with_brew() {
    if check_command brew; then
        echo -e "${BLUE}Installing $1 with Homebrew...${NC}"
        brew install "$1"
    else
        return 1
    fi
}

install_with_apt() {
    if check_command apt-get; then
        echo -e "${BLUE}Installing $1 with apt...${NC}"
        sudo apt-get update && sudo apt-get install -y "$1"
    else
        return 1
    fi
}

install_with_yum() {
    if check_command yum; then
        echo -e "${BLUE}Installing $1 with yum...${NC}"
        sudo yum install -y "$1"
    else
        return 1
    fi
}

install_with_dnf() {
    if check_command dnf; then
        echo -e "${BLUE}Installing $1 with dnf...${NC}"
        sudo dnf install -y "$1"
    else
        return 1
    fi
}

install_package() {
    local package="$1"
    local apt_name="${2:-$1}"
    local brew_name="${3:-$1}"
    
    if [ "$OS_NAME" = "macOS" ]; then
        install_with_brew "$brew_name" || return 1
    elif [ "$OS_NAME" = "Linux" ]; then
        install_with_apt "$apt_name" || install_with_yum "$apt_name" || install_with_dnf "$apt_name" || return 1
    fi
}

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Checking Dependencies${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

MISSING_REQUIRED=()
MISSING_OPTIONAL=()

# Required: Node.js
if check_command node; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js $NODE_VERSION"
else
    echo -e "${RED}✗${NC} Node.js (required)"
    MISSING_REQUIRED+=("nodejs")
fi

# Required: npm
if check_command npm; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓${NC} npm $NPM_VERSION"
else
    echo -e "${RED}✗${NC} npm (required)"
    MISSING_REQUIRED+=("npm")
fi

# Required: jq
if check_command jq; then
    JQ_VERSION=$(jq --version)
    echo -e "${GREEN}✓${NC} jq $JQ_VERSION"
else
    echo -e "${RED}✗${NC} jq (required)"
    MISSING_REQUIRED+=("jq")
fi

# Required: git
if check_command git; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    echo -e "${GREEN}✓${NC} Git $GIT_VERSION"
else
    echo -e "${RED}✗${NC} Git (required)"
    MISSING_REQUIRED+=("git")
fi

# Optional: Docker
if check_command docker; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
    echo -e "${GREEN}✓${NC} Docker $DOCKER_VERSION"
else
    echo -e "${YELLOW}○${NC} Docker (optional - for container analysis)"
    MISSING_OPTIONAL+=("docker")
fi

# Optional: Python
if check_command python3; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo -e "${GREEN}✓${NC} Python $PYTHON_VERSION"
else
    echo -e "${YELLOW}○${NC} Python 3 (optional - for Python project analysis)"
    MISSING_OPTIONAL+=("python3")
fi

# Optional: cloc (Count Lines of Code)
if check_command cloc; then
    CLOC_VERSION=$(cloc --version | head -1)
    echo -e "${GREEN}✓${NC} cloc $CLOC_VERSION"
else
    echo -e "${YELLOW}○${NC} cloc (optional - for accurate LOC counting)"
    MISSING_OPTIONAL+=("cloc")
fi

echo ""

# =============================================================================
# Install Missing Required Dependencies
# =============================================================================

if [ ${#MISSING_REQUIRED[@]} -ne 0 ]; then
    echo -e "${YELLOW}Missing required dependencies: ${MISSING_REQUIRED[*]}${NC}"
    echo ""
    read -p "Would you like to install them automatically? (y/n): " install_deps
    
    if [ "$install_deps" = "y" ] || [ "$install_deps" = "Y" ]; then
        for dep in "${MISSING_REQUIRED[@]}"; do
            case "$dep" in
                nodejs|npm)
                    if [ "$OS_NAME" = "macOS" ]; then
                        install_with_brew node
                    elif [ "$OS_NAME" = "Linux" ]; then
                        # Use NodeSource for latest Node.js
                        if check_command curl; then
                            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>/dev/null || true
                            install_with_apt nodejs || install_with_dnf nodejs
                        else
                            install_package nodejs
                        fi
                    fi
                    ;;
                jq)
                    install_package jq
                    ;;
                git)
                    install_package git
                    ;;
            esac
        done
    else
        echo -e "${RED}Please install the required dependencies manually and run this script again.${NC}"
        echo ""
        echo "Installation commands:"
        echo ""
        if [ "$OS_NAME" = "macOS" ]; then
            echo "  brew install node jq git"
        else
            echo "  # Ubuntu/Debian:"
            echo "  sudo apt-get install nodejs npm jq git"
            echo ""
            echo "  # Fedora/RHEL:"
            echo "  sudo dnf install nodejs npm jq git"
        fi
        exit 1
    fi
fi

# =============================================================================
# Install Optional Dependencies
# =============================================================================

if [ ${#MISSING_OPTIONAL[@]} -ne 0 ]; then
    echo ""
    echo -e "${YELLOW}Optional dependencies not installed: ${MISSING_OPTIONAL[*]}${NC}"
    read -p "Would you like to install them? (y/n): " install_optional
    
    if [ "$install_optional" = "y" ] || [ "$install_optional" = "Y" ]; then
        for dep in "${MISSING_OPTIONAL[@]}"; do
            case "$dep" in
                docker)
                    echo -e "${BLUE}Docker installation is OS-specific. Please visit: https://docs.docker.com/get-docker/${NC}"
                    ;;
                python3)
                    install_package python3
                    ;;
                cloc)
                    install_package cloc
                    ;;
            esac
        done
    fi
fi

# =============================================================================
# Install Node.js Global Packages
# =============================================================================

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Installing Node.js Analysis Tools${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

NPM_PACKAGES=(
    "eslint"
    "jscpd"
    "madge"
    "typescript"
)

for pkg in "${NPM_PACKAGES[@]}"; do
    if npm list -g "$pkg" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $pkg already installed"
    else
        echo -e "${BLUE}Installing $pkg...${NC}"
        npm install -g "$pkg" 2>/dev/null || sudo npm install -g "$pkg"
    fi
done

# =============================================================================
# Make Scripts Executable
# =============================================================================

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Setting Up Scripts${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

chmod +x "$SCRIPT_DIR/evaluate"
chmod +x "$SCRIPT_DIR/scripts/"*.sh 2>/dev/null || true

echo -e "${GREEN}✓${NC} Made scripts executable"

# =============================================================================
# Create Symbolic Link (Optional)
# =============================================================================

echo ""
read -p "Would you like to add 'cto-eval' command to your PATH? (y/n): " add_to_path

if [ "$add_to_path" = "y" ] || [ "$add_to_path" = "Y" ]; then
    LINK_PATH="/usr/local/bin/cto-eval"
    
    if [ -L "$LINK_PATH" ] || [ -f "$LINK_PATH" ]; then
        sudo rm -f "$LINK_PATH"
    fi
    
    sudo ln -s "$SCRIPT_DIR/evaluate" "$LINK_PATH" 2>/dev/null || {
        echo -e "${YELLOW}Could not create symlink. You can add this to your shell config:${NC}"
        echo "  alias cto-eval='$SCRIPT_DIR/evaluate'"
    }
    
    if [ -L "$LINK_PATH" ]; then
        echo -e "${GREEN}✓${NC} Created 'cto-eval' command"
        echo "  You can now run: cto-eval /path/to/codebase"
    fi
fi

# =============================================================================
# Done!
# =============================================================================

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BLUE}To evaluate a codebase:${NC}"
echo ""
echo "    cd $SCRIPT_DIR"
echo "    ./evaluate /path/to/your/codebase"
echo ""
echo "  ${BLUE}Or use interactive mode:${NC}"
echo ""
echo "    ./evaluate"
echo ""
if [ -L "/usr/local/bin/cto-eval" ]; then
echo "  ${BLUE}Or from anywhere:${NC}"
echo ""
echo "    cto-eval /path/to/your/codebase"
echo ""
fi
echo -e "  ${BLUE}For help:${NC}"
echo ""
echo "    ./evaluate --help"
echo ""
