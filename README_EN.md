<div align="center">

# 🔄 claude-session-sync

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Automatic SESSION_ID management for Claude Code multi-model collaboration**

[简体中文](./README.md) | English

[Features](#-features) •
[Installation](#-installation) •
[Usage](#-usage) •
[Related Projects](#-related-projects)

</div>

---

## 🤔 The Problem

When using Claude Code with multiple AI models (Codex, Gemini), SESSION_IDs are often forgotten between calls, causing:

- ❌ Lost conversation context
- ❌ Repeated explanations
- ❌ Inefficient collaboration
- ❌ Session confusion across tasks

## 💡 The Solution

**claude-session-sync** automatically injects session state before each MCP call using PreToolUse hooks, and auto-creates session files when needed.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔄 **Auto Injection** | Automatically inject session state before Codex/Gemini calls |
| 📁 **Auto Creation** | Auto-creates `.claude/sessions.json` on first call |
| 🛠️ **One-Click Setup** | Run the installer and you're done |
| 🎯 **Selective Trigger** | Only triggers for Codex and Gemini MCP tools |
| 📝 **Skill Alternative** | Manual skill version for explicit control |

---

## 📦 Installation

### Prerequisites

- [Claude Code](https://claude.ai/code) installed
- [jq](https://stedolan.github.io/jq/) for JSON processing

```bash
# Install jq (if not installed)
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

### Quick Install

```bash
# Clone the repository
git clone https://github.com/Boulea7/claude-session-sync.git
cd claude-session-sync

# Run the installer
bash hook/install.sh
```

### What the Installer Does

1. ✅ Backs up your existing `~/.claude/settings.json`
2. ✅ Merges the PreToolUse hook configuration
3. ✅ Creates `~/.claude/sessions.json` template

---

## 🚀 Usage

### Zero Configuration

**No manual setup required!** The hook automatically creates `.claude/sessions.json` when needed.

### Fully Automatic Workflow

The hook automatically handles everything:

1. **Before MCP call** → Auto-creates `.claude/sessions.json` if missing
2. **Injects context** → Claude sees active session IDs
3. **After MCP call** → Claude updates the SESSION_ID

### Session File Format

```json
{
  "_schema_version": "1.0",
  "tasks": {
    "feature-auth": {
      "description": "Implementing authentication",
      "codex_session_id": "abc-123-def-456",
      "gemini_session_id": "xyz-789-uvw",
      "updated_at": "2026-03-12T10:00:00Z"
    }
  }
}
```

---

## ⚙️ Configuration

### Hook Configuration

The hook is added to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__codexmcp__codex|mcp__gemini__gemini",
        "hooks": [
          {
            "type": "command",
            "command": "[ -f .claude/sessions.json ] || (mkdir -p .claude && echo '{...}' > .claude/sessions.json); cat .claude/sessions.json",
            "timeout": 3000
          }
        ]
      }
    ]
  }
}
```

> The hook auto-creates the sessions file if it doesn't exist.

### Customization

#### Add More MCP Tools

Update the matcher pattern:

```json
"matcher": "mcp__codexmcp__codex|mcp__gemini__gemini|mcp__your_tool__tool"
```

#### Change Session File Location

Modify the command path in the hook.

---

## 🔀 Hook vs Skill

| Aspect | Hook Version | Skill Version |
|--------|--------------|---------------|
| **Automation** | ✅ Fully automatic | ❌ Manual invocation |
| **Control** | Passive | Active |
| **Best for** | Daily workflow | Explicit management |
| **Setup** | Run installer | Copy skill file |

### Using the Skill Version

```bash
# Copy to Claude plugins
mkdir -p ~/.claude/plugins/session-sync/skills
cp skill/session-sync.md ~/.claude/plugins/session-sync/skills/

# Then use in Claude Code
/session-sync
```

---

## 🗑️ Uninstall

```bash
bash hook/uninstall.sh
```

This will:
- Remove the hook from settings.json
- Optionally delete sessions.json

---

## 📚 Documentation

- [Usage Guide](docs/USAGE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Skill Version](skill/README.md)

---

## 🔗 Related Projects

This project is designed to work with:

| Project | Description |
|---------|-------------|
| [Codex MCP](https://github.com/GuDaStudio/codexmcp) | OpenAI Codex integration for Claude Code |
| [Gemini MCP](https://github.com/GuDaStudio/geminimcp) | Google Gemini integration for Claude Code |

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

[MIT](LICENSE) © 2026 Boulea7

---

<div align="center">

**Made with ❤️ for the Claude Code community**

</div>
