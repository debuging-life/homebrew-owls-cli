#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# OwlsCLI Installer
#
# Usage: curl -fsSL https://raw.githubusercontent.com/debuging-life/owls-cli/main/install.sh | bash
# ─────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

INSTALL_DIR="$HOME/.owls/bin"
REPO="debuging-life/owls-cli"  # ← Change this to your GitHub org/repo

echo ""
echo -e "  ${BOLD}OwlsCLI Installer${NC}"
echo -e "  ${DIM}MicroUI module management tool${NC}"
echo ""

# ─── Step 1: Check gh CLI ────────────────────────────────────

echo -e "  ${CYAN}[1/5]${NC} Checking GitHub CLI..."

if ! command -v gh &> /dev/null; then
    echo -e "  ${RED}✗${NC} GitHub CLI (gh) is not installed."
    echo -e "  ${DIM}Install it: brew install gh${NC}"
    exit 1
fi

# ─── Step 2: Check GitHub auth ───────────────────────────────

echo -e "  ${CYAN}[2/5]${NC} Verifying GitHub authentication..."

if ! gh auth status &> /dev/null; then
    echo -e "  ${RED}✗${NC} Not authenticated with GitHub."
    echo -e "  ${DIM}Run: gh auth login${NC}"
    exit 1
fi

# ─── Step 3: Check repo access ───────────────────────────────

echo -e "  ${CYAN}[3/5]${NC} Verifying repo access..."

if ! gh api "repos/${REPO}" --silent &> /dev/null; then
    echo -e "  ${RED}✗${NC} You don't have access to ${REPO}."
    echo -e "  ${DIM}Contact your admin for access.${NC}"
    exit 1
fi

echo -e "  ${GREEN}✓${NC} Authorized"

# ─── Step 4: Download latest binary ──────────────────────────

echo -e "  ${CYAN}[4/5]${NC} Downloading latest release..."

ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

ASSET_NAME="owls-microui-${OS}-${ARCH}"

mkdir -p "$INSTALL_DIR"

# Download from GitHub Releases
gh release download --repo "$REPO" --pattern "${ASSET_NAME}" --dir "$INSTALL_DIR" --clobber 2>/dev/null || {
    # Fallback: build from source
    echo -e "  ${YELLOW}No pre-built binary found. Building from source...${NC}"

    TEMP_DIR=$(mktemp -d)
    gh repo clone "$REPO" "$TEMP_DIR" -- --depth 1 --quiet
    cd "$TEMP_DIR"
    swift build -c release --quiet
    cp ".build/release/owls-microui" "$INSTALL_DIR/owls-microui"
    rm -rf "$TEMP_DIR"
}

chmod +x "$INSTALL_DIR/owls-microui"

# ─── Step 5: Add to PATH ─────────────────────────────────────

echo -e "  ${CYAN}[5/5]${NC} Configuring PATH..."

SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_RC="$HOME/.bash_profile"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q '.owls/bin' "$SHELL_RC" 2>/dev/null; then
        echo '' >> "$SHELL_RC"
        echo '# OwlsCLI' >> "$SHELL_RC"
        echo 'export PATH="$HOME/.owls/bin:$PATH"' >> "$SHELL_RC"
        echo -e "  ${GREEN}✓${NC} Added to PATH in ${SHELL_RC}"
    else
        echo -e "  ${GREEN}✓${NC} PATH already configured"
    fi
fi

# ─── Done ─────────────────────────────────────────────────────

echo ""
echo -e "  ${GREEN}✅ OwlsCLI installed successfully!${NC}"
echo ""
echo -e "  ${DIM}Installed to:${NC} ${INSTALL_DIR}/owls-microui"
echo ""
echo -e "  ${BOLD}Restart your terminal, then run:${NC}"
echo ""
echo -e "    owls-microui --help"
echo -e "    owls-microui create Transfers"
echo -e "    owls-microui remove Transfers"
echo ""
