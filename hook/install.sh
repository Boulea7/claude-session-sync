#!/bin/bash

# claude-session-sync installer
# Automatically configures PreToolUse hooks for SESSION_ID management

set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
BACKUP_DIR="$CLAUDE_DIR/backups"
MATCHER="mcp__codex__codex|mcp__gemini__gemini"
TMP_FILE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cleanup() {
    if [ -n "${TMP_FILE:-}" ] && [ -f "$TMP_FILE" ]; then
        rm -f "$TMP_FILE"
    fi
}
trap cleanup EXIT

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  claude-session-sync installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check jq
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo -e "Install: ${YELLOW}brew install jq${NC} (macOS) or ${YELLOW}apt install jq${NC} (Linux)"
    exit 1
fi

# Check settings.snippet.json
if [ ! -f "$SCRIPT_DIR/settings.snippet.json" ]; then
    echo -e "${RED}Error: settings.snippet.json not found.${NC}"
    exit 1
fi

if ! jq empty "$SCRIPT_DIR/settings.snippet.json" >/dev/null 2>&1; then
    echo -e "${RED}Error: settings.snippet.json is not valid JSON.${NC}"
    exit 1
fi

# Create directories
if [ ! -d "$CLAUDE_DIR" ]; then
    echo -e "${YELLOW}Creating $CLAUDE_DIR directory...${NC}"
    mkdir -p "$CLAUDE_DIR"
fi

mkdir -p "$BACKUP_DIR"

# Backup existing settings.json
if [ -f "$SETTINGS_FILE" ]; then
    BACKUP_FILE="$BACKUP_DIR/settings.json.$(date +%Y%m%d_%H%M%S).bak"
    echo -e "${YELLOW}Backing up existing settings.json to:${NC}"
    echo -e "  $BACKUP_FILE"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    # Keep only the 5 most recent backups
    find "$BACKUP_DIR" -name "settings.json.*.bak" | sort -r | tail -n +6 | xargs rm -f
else
    echo -e "${YELLOW}No existing settings.json found, creating new one...${NC}"
    echo '{}' > "$SETTINGS_FILE"
fi

# Validate existing settings.json
if ! jq empty "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo -e "${RED}Error: $SETTINGS_FILE is not valid JSON. Fix or restore from backup.${NC}"
    exit 1
fi

# Read hook configuration
HOOK_CONFIG="$(cat "$SCRIPT_DIR/settings.snippet.json")"

echo -e "${GREEN}Merging hook configuration...${NC}"

# Check if hook already installed
if jq -e --arg matcher "$MATCHER" '(.hooks.PreToolUse // []) | any(.matcher == $matcher)' "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo -e "${YELLOW}Hook already installed. Updating...${NC}"
fi

# Merge: remove existing hook with same matcher, then add new one
TMP_FILE="$(mktemp "$CLAUDE_DIR/settings.json.XXXXXX.tmp")"
jq --argjson hook "$HOOK_CONFIG" --arg matcher "$MATCHER" '
  .hooks.PreToolUse = (((.hooks.PreToolUse // []) | map(select(.matcher != $matcher))) + $hook.hooks.PreToolUse)
' "$SETTINGS_FILE" > "$TMP_FILE"
mv "$TMP_FILE" "$SETTINGS_FILE"
TMP_FILE=""

echo -e "${GREEN}Hook configuration merged successfully!${NC}"
echo ""

# Create sessions.json template
echo -e "${GREEN}Creating sessions.json template...${NC}"
if [ ! -f "$CLAUDE_DIR/sessions.json" ]; then
    cat > "$CLAUDE_DIR/sessions.json" << 'EOF'
{
  "_schema_version": "1.0",
  "_hint": "Track SESSION_IDs here. Do not store secrets or tokens.",
  "tasks": {}
}
EOF
    echo -e "  Created: $CLAUDE_DIR/sessions.json"
else
    echo -e "${YELLOW}  sessions.json already exists, skipping...${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Restart Claude Code to apply changes"
echo -e "  2. ${GREEN}That's it!${NC} The hook will auto-create sessions.json when needed"
echo ""
