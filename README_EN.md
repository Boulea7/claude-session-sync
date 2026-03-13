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

## 🔑 Prerequisites

This tool requires at least one of the following MCP servers to be configured in Claude Code:

| MCP | Repository | Description |
|-----|-----------|-------------|
| **Codex MCP** | [GuDaStudio/codexmcp](https://github.com/GuDaStudio/codexmcp) | Integrates OpenAI Codex into Claude Code — excellent for backend logic, debugging, and code analysis |
| **Gemini MCP** | [GuDaStudio/geminimcp](https://github.com/GuDaStudio/geminimcp) | Integrates Google Gemini into Claude Code — excellent for frontend design and multimodal understanding |

> 💡 **Recommended**: Install both MCPs to unlock full multi-model collaboration — Codex for logic/backend, Gemini for design/frontend.

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

> ⚠️ **Note**: The hook only **reads** session state and injects it into context. It does NOT auto-write returned SESSION_IDs back. You need to update manually or use a skill.

> 🔒 **Privacy**: `sessions.json` content is output to context before MCP calls. **Do not store** tokens, passwords, cookies, or other sensitive data.

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
      "matcher": "mcp__codex__codex|mcp__gemini__gemini",
      "hooks": [{
        "type": "command",
        "command": "[ -f .claude/sessions.json ] || (mkdir -p .claude && echo '{...}' > .claude/sessions.json); cat .claude/sessions.json",
        "timeout": 3000
      }]
    }]
  }
}
```

> **Note:** Simplified for readability. The actual installed command includes symlink protection and permission hardening. See `hook/settings.snippet.json` for the full command.

### Add Other MCP Tools

Modify the `matcher` field:

```json
"matcher": "mcp__codex__codex|mcp__gemini__gemini|mcp__other__tool"
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
