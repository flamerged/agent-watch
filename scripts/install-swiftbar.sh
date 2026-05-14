#!/bin/zsh
set -euo pipefail

TARGET_DIR="${1:-$HOME/SwiftBarPlugins}"
TARGET="$TARGET_DIR/agent-watch.30s.sh"
RELEASE_ASSET_URL="${AGENTWATCH_RELEASE_ASSET_URL:-https://github.com/flamerged/agent-watch/releases/latest/download/agent-watch.30s.sh}"

mkdir -p "$TARGET_DIR"
tmp="$TARGET_DIR/.agent-watch.30s.sh.$$"
rm -f "$tmp"
trap 'rm -f "$tmp"' EXIT

curl -fsSL \
  --connect-timeout 5 \
  --max-time 30 \
  --retry 2 \
  --retry-delay 1 \
  "$RELEASE_ASSET_URL" -o "$tmp"

IFS= read -r first_line < "$tmp" || first_line=""
content="$(< "$tmp")"
if [[ "$first_line" != "#!/bin/zsh" || "$content" != *"<xbar.title>Agent Watch</xbar.title>"* || "$content" != *"PLUGIN_VERSION=\""* ]]; then
  print -u2 "Downloaded file did not look like an Agent Watch plugin."
  exit 1
fi

chmod +x "$tmp"
rm -f "$TARGET"
mv "$tmp" "$TARGET"
trap - EXIT

print "installed $TARGET"
