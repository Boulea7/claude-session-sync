<div align="center">

# 🔄 claude-session-sync

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Automatic SESSION_ID management for Claude Code multi-model collaboration**

[简体中文](./README.md) | English

</div>

---

## 🤔 The Problem

When collaborating with multiple AI models (Codex, Gemini) in Claude Code, SESSION_IDs are often forgotten:

- ❌ Lost conversation context
- ❌ Repeated explanations
- ❌ Session confusion across tasks

## 💡 The Solution

Use **PreToolUse Hook** to automatically inject session state before each MCP call.

---

## 📦 Installation

### macOS / Linux

```bash
git clone https://github.com/Boulea7/claude-session-sync.git
cd claude-session-sync
bash hook/install.sh
```

> **Dependency**: Requires [jq](https://stedolan.github.io/jq/) (`brew install jq` or `apt install jq`)

### Windows

```powershell
git clone https://github.com/Boulea7/claude-session-sync.git
cd claude-session-sync
.\hook\install.ps1
```

> **Dependency**: Requires [Git for Windows](https://git-scm.com/downloads/win) (Claude Code uses Git Bash internally)

### After Installation

Restart Claude Code to apply changes. **No additional configuration needed.**

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔄 **Auto Injection** | Inject session state before Codex/Gemini calls |
| 📁 **Auto Creation** | Auto-creates `.claude/sessions.json` on first call |
| 🖥️ **Cross-platform** | Supports macOS, Linux, Windows |
| 🎯 **Precise Trigger** | Only triggers for Codex/Gemini MCP |

---

## 🚀 Usage

### Workflow

```
Call Codex/Gemini
       ↓
Hook auto-creates/reads .claude/sessions.json
       ↓
Session state injected into context
       ↓
Claude calls MCP and updates SESSION_ID
```

### Session File Example

```json
{
  "_schema_version": "1.0",
  "tasks": {
    "feature-auth": {
      "codex_session_id": "abc-123-def-456",
      "gemini_session_id": "xyz-789-uvw"
    }
  }
}
```

---

## ⚙️ Configuration

### Config File Location

| Platform | Path |
|----------|------|
| macOS/Linux | `~/.claude/settings.json` |
| Windows | `%USERPROFILE%\.claude\settings.json` |

### Hook Configuration

The installer automatically adds:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "mcp__codexmcp__codex|mcp__gemini__gemini",
      "hooks": [{
        "type": "command",
        "command": "[ -f .claude/sessions.json ] || (mkdir -p .claude && echo '{...}' > .claude/sessions.json); cat .claude/sessions.json",
        "timeout": 3000
      }]
    }]
  }
}
```

### Add Other MCP Tools

Modify the `matcher` field:

```json
"matcher": "mcp__codexmcp__codex|mcp__gemini__gemini|mcp__other__tool"
```

---

## ⚠️ Windows Notes

1. **Git for Windows required** - Claude Code uses Git Bash internally to execute all shell commands
2. **WSL2 recommended** - For better compatibility, consider using WSL2
3. **PowerShell execution policy** - If you encounter permission issues, run as Administrator:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

---

## 🗑️ Uninstall

**macOS / Linux:**
```bash
bash hook/uninstall.sh
```

**Windows:**
```powershell
.\hook\uninstall.ps1
```

---

## 📚 Documentation

- [Usage Guide](docs/USAGE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Skill Version](skill/README.md)

---

## 🔗 Related Projects

| Project | Description |
|---------|-------------|
| [Codex MCP](https://github.com/GuDaStudio/codexmcp) | Codex integration for Claude Code |
| [Gemini MCP](https://github.com/GuDaStudio/geminimcp) | Gemini integration for Claude Code |

---

## 📄 License

[MIT](LICENSE) © 2026 Boulea7
