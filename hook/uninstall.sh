#!/bin/bash

# claude-session-sync uninstaller
# Removes PreToolUse hooks for SESSION_ID management

set -euo pipefail
umask 077

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
echo -e "${BLUE}  claude-session-sync uninstaller${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check jq
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    exit 1
fi

# Check settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}No settings.json found. Nothing to uninstall.${NC}"
    exit 0
fi

# Validate JSON
if ! jq empty "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo -e "${RED}Error: $SETTINGS_FILE is not valid JSON. Fix or restore from backup.${NC}"
    exit 1
fi

# Backup before uninstall
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/settings.json.$(date +%Y%m%d_%H%M%S).pre-uninstall.bak"
echo -e "${YELLOW}Backing up settings.json to:${NC}"
echo -e "  $BACKUP_FILE"
cp "$SETTINGS_FILE" "$BACKUP_FILE"
# Keep only the 5 most recent backups
find "$BACKUP_DIR" -name "settings.json.*.bak" | sort -r | tail -n +6 | xargs rm -f

echo -e "${GREEN}Removing hook configuration...${NC}"

# Remove hook safely (handles null PreToolUse)
TMP_FILE="$(mktemp "$CLAUDE_DIR/settings.json.XXXXXX.tmp")"
jq --arg matcher "$MATCHER" '
  .hooks.PreToolUse = ((.hooks.PreToolUse // []) | map(select(.matcher != $matcher)))
  | if .hooks.PreToolUse == [] then del(.hooks.PreToolUse) else . end
  | if .hooks == {} then del(.hooks) else . end
' "$SETTINGS_FILE" > "$TMP_FILE"
mv "$TMP_FILE" "$SETTINGS_FILE"
TMP_FILE=""

echo -e "${GREEN}Hook removed successfully!${NC}"
echo ""

# Ask about sessions.json (only in interactive mode)
if [ -t 0 ]; then
    echo -e "${YELLOW}Do you want to remove ~/.claude/sessions.json? (y/N)${NC}"
    read -r response
else
    response="N"
fi

if [[ "$response" =~ ^[Yy]$ ]]; then
    if [ -f "$CLAUDE_DIR/sessions.json" ]; then
        rm "$CLAUDE_DIR/sessions.json"
        echo -e "${GREEN}Removed ~/.claude/sessions.json${NC}"
    fi
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Uninstallation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Note: Project-level .claude/sessions.json files were not removed."
echo -e "Remove them manually if needed."
echo ""
