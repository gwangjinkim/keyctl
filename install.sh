#!/bin/bash
# Unix install snippet for keyctl
set -e

BIN="keyctl"
INSTALL_DIR="${1:-$HOME/bin}"
mkdir -p "$INSTALL_DIR"
cp "$BIN" "$INSTALL_DIR/$BIN"
chmod +x "$INSTALL_DIR/$BIN"

echo "Installed to $INSTALL_DIR/$BIN"
echo "Add $INSTALL_DIR to your PATH to use globally."
# Optional: launchd/systemd notes
# macOS: cp com.keyctl.plist ~/Library/LaunchAgents/
# Linux: cp keyctl.service /etc/systemd/system/
