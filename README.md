<div align="center">

# 🔄 claude-session-sync

**Claude Code 多模型协作的 SESSION_ID 自动管理工具**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)](#)

[English](./README_EN.md) | 简体中文

</div>

<br/>

> [!IMPORTANT]
> **🔑 前置条件（核心依赖）**
> 本工具依赖以下两个 MCP 服务，**安装前请确认已配置至少一个**。推荐同时安装两个以充分发挥多模型协作优势：Codex 负责逻辑/后端，Gemini 负责设计/前端。
>
> | MCP 服务 | 仓库链接 | 说明 |
> |:---:|---|---|
> | **Codex MCP** | [GuDaStudio/codexmcp](https://github.com/GuDaStudio/codexmcp) | 提供强大的后端逻辑分析与代码生成能力 |
> | **Gemini MCP** | [GuDaStudio/geminimcp](https://github.com/GuDaStudio/geminimcp) | 提供出色的前端设计与多模态理解能力 |

---

## 📑 目录

- [🤔 为什么需要这个工具？](#-为什么需要这个工具)
- [✨ 核心特性](#-核心特性)
- [🚀 快速开始](#-快速开始)
- [🧠 工作原理](#-工作原理)
- [⚙️ 高级配置](#-高级配置)
- [🗑️ 卸载](#-卸载)
- [📚 更多文档](#-更多文档)

---

## 🤔 为什么需要这个工具？

使用 Claude Code 进行多模型协作（Codex、Gemini）时，SESSION_ID 经常被遗忘，导致：

- ❌ **丢失对话上下文**
- ❌ **重复解释相同内容**
- ❌ **跨任务会话混乱**

**解决方案：** 通过 **PreToolUse Hook** 在每次 MCP 调用前自动读取并注入会话状态，实现无缝衔接。

---

## ✨ 核心特性

| 特性 | 描述 |
|:---|:---|
| 🔄 **自动注入** | 调用 Codex/Gemini 前自动将历史会话状态注入上下文 |
| 📁 **自动创建** | 首次调用时自动初始化 `.claude/sessions.json` 文件 |
| 🎯 **精准触发** | 仅对指定的 Codex/Gemini MCP 工具调用触发，不影响其他工具 |
| 🖥️ **跨平台** | 完美支持 macOS、Linux 以及 Windows |

---

## 🚀 快速开始

<details open>
<summary><b>🍎 macOS / 🐧 Linux</b></summary>

```bash
git clone https://github.com/Boulea7/claude-session-sync.git
cd claude-session-sync
bash hook/install.sh
```

> [!NOTE]
> **依赖项**: 需要安装 [jq](https://stedolan.github.io/jq/)（`brew install jq` 或 `apt install jq`）

</details>

<details open>
<summary><b>🪟 Windows</b></summary>

```powershell
git clone https://github.com/Boulea7/claude-session-sync.git
cd claude-session-sync
.\hook\install.ps1
```

> [!NOTE]
> **依赖项**: 需要安装 [Git for Windows](https://git-scm.com/downloads/win)（Claude Code 依赖 Git Bash 执行命令）

> [!WARNING]
> **Windows 注意事项**
> 1. **必须安装 Git for Windows**
> 2. **推荐使用 WSL2** — 如遇兼容性问题，WSL2 是更稳定的选择
> 3. **PowerShell 执行策略** — 如遇权限问题，以管理员身份运行：
>    ```powershell
>    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
>    ```

</details>

安装完毕后，只需**重启 Claude Code** 即可生效，**无需任何其他配置**。

---

## 🧠 工作原理

```text
┌─────────────────────────┐
│   Claude Code 客户端    │
└────────────┬────────────┘
             │  1. 准备调用 Codex / Gemini MCP
             ▼
┌─────────────────────────┐
│   PreToolUse Hook       │  自动创建/读取 .claude/sessions.json
│  (claude-session-sync)  │  并将状态注入到本次请求的上下文中
└────────────┬────────────┘
             │  2. 携带历史会话状态发起调用
             ▼
┌─────────────────────────┐
│       MCP 服务端        │
│    (Codex / Gemini)     │
└────────────┬────────────┘
             │  3. 返回执行结果及新的 SESSION_ID
             ▼
┌─────────────────────────┐
│   Claude Code 客户端    │  4. 用户 / Skill 将 SESSION_ID 写回文件
└─────────────────────────┘
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

> [!WARNING]
> Hook 只负责**读取**会话状态并注入上下文，不会自动回写 MCP 返回的 SESSION_ID。你需要手动更新或配合 skill 保存返回值。

> [!CAUTION]
> `sessions.json` 内容会在 MCP 调用前输出到上下文。**绝对不要**在其中存储 token、密码、cookie 等敏感信息。

---

## ⚙️ 高级配置

### 配置文件位置

| 平台 | 路径 |
|:---|:---|
| **macOS / Linux** | `~/.claude/settings.json` |
| **Windows** | `%USERPROFILE%\.claude\settings.json` |

### Hook 配置结构

<details>
<summary>点击查看完整配置示例</summary>

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

> **注：** 以上为简化示例，便于阅读。实际安装的命令还包含符号链接保护和权限加固。完整命令请参见 `hook/settings.snippet.json`。

</details>

### 扩展支持其他 MCP

如需为其他 MCP 工具启用此功能，修改 `matcher` 字段即可：

```json
"matcher": "mcp__codex__codex|mcp__gemini__gemini|mcp__other__tool"
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
|:---|:---|
| [Codex MCP](https://github.com/GuDaStudio/codexmcp) | Claude Code 的 Codex 集成 |
| [Gemini MCP](https://github.com/GuDaStudio/geminimcp) | Claude Code 的 Gemini 集成 |

---

<div align="center">

本项目基于 [MIT](LICENSE) 协议开源 © 2026 Boulea7

</div>
