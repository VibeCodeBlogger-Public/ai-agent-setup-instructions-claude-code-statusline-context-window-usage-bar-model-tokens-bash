#!/usr/bin/env bash
# install.sh — install the Claude Code status line into ~/.claude/
# Copies statusline.sh and adds the statusLine block to settings.json (preserving the rest).
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$CLAUDE_DIR/settings.json"

mkdir -p "$CLAUDE_DIR"
cp "$SRC_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh"
chmod +x "$CLAUDE_DIR/statusline.sh"
echo "✓ Copied statusline.sh → $CLAUDE_DIR/statusline.sh"

STATUSLINE_JSON='{"type":"command","command":"~/.claude/statusline.sh"}'

if command -v jq >/dev/null 2>&1; then
  [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
  cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d_%H%M%S)"
  tmp="$(mktemp)"
  jq --argjson sl "$STATUSLINE_JSON" '.statusLine = $sl' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "✓ Set statusLine in $SETTINGS (backup saved alongside it)."
else
  echo "! jq not found — add this to $SETTINGS manually:"
  echo '    "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }'
fi

echo "→ Restart Claude Code (or start a new session) to see the status line."
