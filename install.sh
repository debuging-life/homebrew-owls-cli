#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# OwlsCLI Installer (Binary Only — No Source Access)
#
# Install: Copy this script to your team, or host on internal server.
# Users get the binary only — source code stays private.
# ─────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

INSTALL_DIR="$HOME/.owls/bin"
REPO="debuging-life/owls-cli"

echo ""
echo -e "  ${BOLD}OwlsCLI Installer${NC}"
echo -e "  ${DIM}MicroUI module management tool${NC}"
echo ""

# ─── Step 1: Check gh CLI ────────────────────────────────────

echo -e "  ${CYAN}[1/4]${NC} Checking GitHub CLI..."

if ! command -v gh &> /dev/null; then
    echo -e "  ${RED}✗${NC} GitHub CLI (gh) is not installed."
    echo -e "  ${DIM}Install it: brew install gh${NC}"
    exit 1
fi

# ─── Step 2: Check GitHub auth ───────────────────────────────

echo -e "  ${CYAN}[2/4]${NC} Verifying GitHub authentication..."

if ! gh auth status &> /dev/null; then
    echo -e "  ${RED}✗${NC} Not authenticated with GitHub."
    echo -e "  ${DIM}Run: gh auth login${NC}"
    exit 1
fi

# ─── Step 3: Download binary from Releases ───────────────────

echo -e "  ${CYAN}[3/4]${NC} Downloading latest binary..."

ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ASSET_NAME="owls-microui-${OS}-${ARCH}"

mkdir -p "$INSTALL_DIR"

# Download ONLY the binary from GitHub Releases (not the source)
if ! gh release download --repo "$REPO" --pattern "${ASSET_NAME}" --dir "$INSTALL_DIR" --clobber 2>/dev/null; then
    # Try without arch suffix (universal binary)
    if ! gh release download --repo "$REPO" --pattern "owls-microui" --dir "$INSTALL_DIR" --clobber 2>/dev/null; then
        echo -e "  ${RED}✗${NC} No binary found in releases."
        echo -e "  ${DIM}Either you don't have access, or no release exists yet.${NC}"
        echo -e "  ${DIM}Contact your admin.${NC}"
        exit 1
    fi
    mv "$INSTALL_DIR/owls-microui" "$INSTALL_DIR/owls-microui" 2>/dev/null || true
else
    mv "$INSTALL_DIR/${ASSET_NAME}" "$INSTALL_DIR/owls-microui"
fi

chmod +x "$INSTALL_DIR/owls-microui"

# ─── Step 4: Add to PATH ─────────────────────────────────────

echo -e "  ${CYAN}[4/4]${NC} Configuring PATH..."

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
echo -e "  ${GREEN}✅ owls-microui installed successfully!${NC}"
echo ""
echo -e "  ${DIM}Installed to:${NC} ${INSTALL_DIR}/owls-microui"
echo ""
echo -e "  ${BOLD}Restart your terminal, then run:${NC}"
echo ""
echo -e "    owls-microui --help"
echo -e "    owls-microui create Transfers"
echo -e "    owls-microui remove Transfers"
echo ""
