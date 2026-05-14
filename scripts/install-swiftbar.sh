#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
PLUGIN="$ROOT/bin/agent-watch.30s.sh"
TARGET_DIR="${1:-$HOME/SwiftBarPlugins}"
TARGET="$TARGET_DIR/agent-watch.30s.sh"

mkdir -p "$TARGET_DIR"
ln -sf "$PLUGIN" "$TARGET"
chmod +x "$PLUGIN"

print "installed $TARGET"
