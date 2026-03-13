<div align="center">

# 🔄 claude-session-sync

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Claude Code 多模型协作的 SESSION_ID 自动管理工具**

[English](./README_EN.md) | 简体中文

</div>

---

## 🤔 问题

使用 Claude Code 进行多模型协作（Codex、Gemini）时，SESSION_ID 经常被遗忘：

- ❌ 丢失对话上下文
- ❌ 重复解释相同内容
- ❌ 跨任务会话混乱

## 💡 方案

通过 **PreToolUse Hook** 在每次 MCP 调用前自动注入会话状态。

---

## 🔑 前置条件

本工具依赖以下两个 MCP 服务，**安装前请确认已配置至少一个**：

| MCP | 仓库 | 说明 |
|-----|------|------|
| **Codex MCP** | [GuDaStudio/codexmcp](https://github.com/GuDaStudio/codexmcp) | 将 OpenAI Codex 集成到 Claude Code，提供强大的后端逻辑分析与代码生成能力 |
| **Gemini MCP** | [GuDaStudio/geminimcp](https://github.com/GuDaStudio/geminimcp) | 将 Google Gemini 集成到 Claude Code，提供出色的前端设计与多模态理解能力 |

> 💡 **推荐**：同时安装两个 MCP，充分发挥多模型协作优势——Codex 负责逻辑/后端，Gemini 负责设计/前端。

---

## 📦 安装

### macOS / Linux

```bash
git clone https://github.com/Boulea7/claude-session-sync.git
cd claude-session-sync
bash hook/install.sh
```

> **依赖**: 需要安装 [jq](https://stedolan.github.io/jq/)（`brew install jq` 或 `apt install jq`）

### Windows

```powershell
git clone https://github.com/Boulea7/claude-session-sync.git
cd claude-session-sync
.\hook\install.ps1
```

> **依赖**: 需要安装 [Git for Windows](https://git-scm.com/downloads/win)（Claude Code 依赖 Git Bash 执行命令）

### 安装完成后

重启 Claude Code 即可生效，**无需其他配置**。

---

## ✨ 特性

| 特性 | 描述 |
|------|------|
| 🔄 **自动注入** | 调用 Codex/Gemini 前自动注入会话状态 |
| 📁 **自动创建** | 首次调用时自动创建 `.claude/sessions.json` |
| 🖥️ **跨平台** | 支持 macOS、Linux、Windows |
| 🎯 **精准触发** | 仅对 Codex/Gemini MCP 触发 |

---

## 🚀 使用

### 工作流程

```
调用 Codex/Gemini
       ↓
Hook 自动创建/读取 .claude/sessions.json
       ↓
会话状态注入到上下文
       ↓
Claude 调用 MCP 并更新 SESSION_ID
```

### 会话文件示例

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

> ⚠️ **注意**：Hook 只负责**读取**会话状态并注入上下文，不会自动回写 MCP 返回的 SESSION_ID。你需要手动更新或配合 skill 保存返回值。

> 🔒 **隐私提醒**：`sessions.json` 内容会在 MCP 调用前输出到上下文。**不要存储** token、密码、cookie 等敏感信息。

---

## ⚙️ 配置说明

### 配置文件位置

| 平台 | 路径 |
|------|------|
| macOS/Linux | `~/.claude/settings.json` |
| Windows | `%USERPROFILE%\.claude\settings.json` |

### Hook 配置

安装脚本自动添加以下配置：

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

> **注意：** 以上为简化示例，便于阅读。实际安装的命令还包含符号链接保护和权限加固。完整命令请参见 `hook/settings.snippet.json`。

### 添加其他 MCP 工具

修改 `matcher` 字段：

```json
"matcher": "mcp__codex__codex|mcp__gemini__gemini|mcp__other__tool"
```

---

## ⚠️ Windows 注意事项

1. **必须安装 Git for Windows** - Claude Code 内部使用 Git Bash 执行所有 shell 命令
2. **推荐使用 WSL2** - 如遇兼容性问题，WSL2 是更稳定的选择
3. **PowerShell 执行策略** - 如遇权限问题，以管理员身份运行：
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

---

## 🗑️ 卸载

**macOS / Linux:**
```bash
bash hook/uninstall.sh
```

**Windows:**
```powershell
.\hook\uninstall.ps1
```

---

## 📚 更多文档

- [使用指南](docs/USAGE.md)
- [故障排除](docs/TROUBLESHOOTING.md)
- [Skill 版本](skill/README.md)

---

## 🔗 相关项目

| 项目 | 描述 |
|------|------|
| [Codex MCP](https://github.com/GuDaStudio/codexmcp) | Claude Code 的 Codex 集成 |
| [Gemini MCP](https://github.com/GuDaStudio/geminimcp) | Claude Code 的 Gemini 集成 |

---

## 📄 License

[MIT](LICENSE) © 2026 Boulea7
