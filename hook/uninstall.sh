#!/bin/bash

# claude-session-sync uninstaller
# Removes PreToolUse hooks for SESSION_ID management

set -e

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
BACKUP_DIR="$CLAUDE_DIR/backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🔄 claude-session-sync uninstaller${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    exit 1
fi

# Check if settings.json exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}No settings.json found. Nothing to uninstall.${NC}"
    exit 0
fi

# Backup before uninstall
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/settings.json.$(date +%Y%m%d_%H%M%S).pre-uninstall.bak"
echo -e "${YELLOW}Backing up settings.json to:${NC}"
echo -e "  $BACKUP_FILE"
cp "$SETTINGS_FILE" "$BACKUP_FILE"

# Remove the session-sync hook
echo -e "${GREEN}Removing hook configuration...${NC}"

jq 'del(.hooks.PreToolUse[] | select(.matcher == "mcp__codexmcp__codex|mcp__gemini__gemini"))' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

# Clean up empty arrays
jq 'if .hooks.PreToolUse == [] then del(.hooks.PreToolUse) else . end |
    if .hooks == {} then del(.hooks) else . end' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

echo -e "${GREEN}Hook removed successfully!${NC}"
echo ""

# Ask about sessions.json
echo -e "${YELLOW}Do you want to remove ~/.claude/sessions.json? (y/N)${NC}"
read -r response
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
