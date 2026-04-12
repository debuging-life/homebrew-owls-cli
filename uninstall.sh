#!/bin/bash
set -euo pipefail

echo ""
echo "  Uninstalling owls-cli..."

rm -rf "$HOME/.owls"

# Remove PATH entry from shell config
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [ -f "$rc" ]; then
        sed -i '' '/# OwlsCLI/d' "$rc"
        sed -i '' '/\.owls\/bin/d' "$rc"
    fi
done

echo "  ✅ OwlsCLI uninstalled."
echo ""
