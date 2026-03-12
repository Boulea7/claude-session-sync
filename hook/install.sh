#!/bin/bash

# claude-session-sync installer
# Automatically configures PreToolUse hooks for SESSION_ID management

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
echo -e "${BLUE}  🔄 claude-session-sync installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo -e "Install it with: ${YELLOW}brew install jq${NC} (macOS) or ${YELLOW}apt install jq${NC} (Linux)"
    exit 1
fi

# Create .claude directory if it doesn't exist
if [ ! -d "$CLAUDE_DIR" ]; then
    echo -e "${YELLOW}Creating $CLAUDE_DIR directory...${NC}"
    mkdir -p "$CLAUDE_DIR"
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup existing settings.json
if [ -f "$SETTINGS_FILE" ]; then
    BACKUP_FILE="$BACKUP_DIR/settings.json.$(date +%Y%m%d_%H%M%S).bak"
    echo -e "${YELLOW}Backing up existing settings.json to:${NC}"
    echo -e "  $BACKUP_FILE"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
else
    echo -e "${YELLOW}No existing settings.json found, creating new one...${NC}"
    echo '{}' > "$SETTINGS_FILE"
fi

# Read the hook configuration
HOOK_CONFIG=$(cat "$SCRIPT_DIR/settings.snippet.json")

# Merge hooks into settings.json
echo -e "${GREEN}Merging hook configuration...${NC}"

# Check if hooks already exist
EXISTING_HOOKS=$(jq '.hooks.PreToolUse // []' "$SETTINGS_FILE")

# Check if our hook is already installed
if echo "$EXISTING_HOOKS" | grep -q "mcp__codexmcp__codex|mcp__gemini__gemini"; then
    echo -e "${YELLOW}Hook already installed. Updating...${NC}"
    # Remove existing hook and add new one
    jq 'del(.hooks.PreToolUse[] | select(.matcher == "mcp__codexmcp__codex|mcp__gemini__gemini"))' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
fi

# Merge the new hook configuration
jq --argjson hook "$HOOK_CONFIG" '
  .hooks.PreToolUse = ((.hooks.PreToolUse // []) + $hook.hooks.PreToolUse)
' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

echo -e "${GREEN}Hook configuration merged successfully!${NC}"
echo ""

# Copy sessions.json template to .claude directory
echo -e "${GREEN}Creating sessions.json template...${NC}"
if [ ! -f "$CLAUDE_DIR/sessions.json" ]; then
    cp "$SCRIPT_DIR/sessions.json" "$CLAUDE_DIR/sessions.json"
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
echo -e "The hook automatically:"
echo -e "  • Creates ${YELLOW}.claude/sessions.json${NC} in each project on first MCP call"
echo -e "  • Injects session state before Codex/Gemini calls"
echo -e "  • No manual setup required per project"
echo ""
