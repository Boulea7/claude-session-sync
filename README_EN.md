<div align="center">

# 🔄 claude-session-sync

**Automatic SESSION_ID management for Claude Code multi-model collaboration**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)](#-quick-start)

[简体中文](./README.md) | English

</div>

<br/>

> [!IMPORTANT]
> **🔑 Prerequisites (Critical Dependencies)**
> This tool requires at least one of the following MCP servers configured in Claude Code. **Please install at least one before proceeding.** Installing both is recommended to unlock full multi-model collaboration — Codex for backend/logic, Gemini for frontend/design.
>
> | MCP Server | Repository | Description |
> |:---:|---|---|
> | **Codex MCP** | [GuDaStudio/codexmcp](https://github.com/GuDaStudio/codexmcp) | Integrates OpenAI Codex — excellent for backend logic, debugging, and code analysis |
> | **Gemini MCP** | [GuDaStudio/geminimcp](https://github.com/GuDaStudio/geminimcp) | Integrates Google Gemini — excellent for frontend design and multimodal understanding |

---

## 📑 Table of Contents

- [🤔 The Problem & Solution](#-the-problem--solution)
- [✨ Core Features](#-core-features)
- [🚀 Quick Start](#-quick-start)
- [🧠 How It Works](#-how-it-works)
- [⚙️ Advanced Configuration](#-advanced-configuration)
- [🗑️ Uninstall](#-uninstall)
- [📚 Documentation](#-documentation)

---

## 🤔 The Problem & Solution

When collaborating with multiple AI models (Codex, Gemini) in Claude Code, SESSION_IDs are frequently forgotten, leading to:

- ❌ **Lost conversation context**
- ❌ **Repeated explanations**
- ❌ **Session confusion across tasks**

**The Solution:** A **PreToolUse Hook** that automatically reads and injects session state before each MCP call, ensuring seamless continuity across models.

---

## ✨ Core Features

| Feature | Description |
|:---|:---|
| 🔄 **Auto Injection** | Injects prior session state automatically before each Codex/Gemini call |
| 📁 **Auto Creation** | Auto-creates `.claude/sessions.json` on the very first call |
| 🎯 **Precise Trigger** | Only triggers for specified Codex/Gemini MCP tools, leaving others untouched |
| 🖥️ **Cross-platform** | Fully supports macOS, Linux, and Windows |

---

## 🚀 Quick Start

<details open>
<summary><b>🍎 macOS / 🐧 Linux</b></summary>

```bash
git clone https://github.com/Boulea7/claude-session-sync.git
cd claude-session-sync
bash hook/install.sh
```

> [!NOTE]
> **Dependency**: Requires [jq](https://stedolan.github.io/jq/) (`brew install jq` or `apt install jq`)

</details>

<details open>
<summary><b>🪟 Windows</b></summary>

```powershell
git clone https://github.com/Boulea7/claude-session-sync.git
cd claude-session-sync
.\hook\install.ps1
```

> [!NOTE]
> **Dependency**: Requires [Git for Windows](https://git-scm.com/downloads/win) (Claude Code uses Git Bash internally to execute all shell commands)

> [!WARNING]
> **Windows Notes**
> 1. **Git for Windows is required**
> 2. **WSL2 recommended** — For better compatibility, WSL2 is the more stable option
> 3. **PowerShell execution policy** — If you encounter permission issues, run as Administrator:
>    ```powershell
>    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
>    ```

</details>

After installation, simply **restart Claude Code** to apply the changes. **No additional configuration needed.**

---

## 🧠 How It Works

```text
┌─────────────────────────┐
│   Claude Code Client    │
└────────────┬────────────┘
             │  1. Triggers Tool Call (Codex / Gemini)
             ▼
┌─────────────────────────┐
│   PreToolUse Hook       │  Auto-creates/reads .claude/sessions.json
│  (claude-session-sync)  │  and injects state into context
└────────────┬────────────┘
             │  2. Initiates call with prior session state
             ▼
┌─────────────────────────┐
│       MCP Server        │
│    (Codex / Gemini)     │
└────────────┬────────────┘
             │  3. Returns results & new SESSION_ID
             ▼
┌─────────────────────────┐
│   Claude Code Client    │  4. User / Skill writes SESSION_ID back to file
└─────────────────────────┘
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

> [!WARNING]
> The hook only **reads** session state and injects it into context. It does **not** auto-write returned SESSION_IDs back. You need to update them manually or use a skill.

> [!CAUTION]
> The content of `sessions.json` is output to context before every MCP call. **Never store** tokens, passwords, cookies, or any other sensitive data in this file.

---

## ⚙️ Advanced Configuration

### Config File Location

| Platform | Path |
|:---|:---|
| **macOS / Linux** | `~/.claude/settings.json` |
| **Windows** | `%USERPROFILE%\.claude\settings.json` |

### Hook Configuration Structure

<details>
<summary>Click to view configuration details</summary>

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

</details>

### Add Other MCP Tools

To enable the hook for additional tools, modify the `matcher` field:

```json
"matcher": "mcp__codex__codex|mcp__gemini__gemini|mcp__other__tool"
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
|:---|:---|
| [Codex MCP](https://github.com/GuDaStudio/codexmcp) | Codex integration for Claude Code |
| [Gemini MCP](https://github.com/GuDaStudio/geminimcp) | Gemini integration for Claude Code |

---

<div align="center">

Licensed under [MIT](LICENSE) © 2026 Boulea7

</div>
