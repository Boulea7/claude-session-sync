<div align="center">

# 🔄 claude-session-sync

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Claude Code 多模型协作的 SESSION_ID 自动管理工具**

[English](./README_EN.md) | 简体中文

[特性](#-特性) •
[安装](#-安装) •
[使用](#-使用) •
[相关项目](#-相关项目)

</div>

---

## 🤔 问题背景

在使用 Claude Code 进行多模型协作（Codex、Gemini）时，SESSION_ID 经常在调用间被遗忘，导致：

- ❌ 丢失对话上下文
- ❌ 重复解释相同内容
- ❌ 协作效率低下
- ❌ 跨任务会话混乱

## 💡 解决方案

**claude-session-sync** 使用 PreToolUse hooks 在每次 MCP 调用前自动注入会话状态，并在需要时自动创建会话文件。

---

## ✨ 特性

| 特性 | 描述 |
|------|------|
| 🔄 **自动注入** | 在 Codex/Gemini 调用前自动注入会话状态 |
| 📁 **自动创建** | 首次调用时自动创建 `.claude/sessions.json` |
| 🛠️ **一键安装** | 运行安装脚本即可完成配置 |
| 🎯 **选择性触发** | 仅对 Codex 和 Gemini MCP 工具触发 |
| 📝 **Skill 备选** | 提供手动 Skill 版本供显式控制 |

---

## 📦 安装

### 前置要求

- 已安装 [Claude Code](https://claude.ai/code)
- 已安装 [jq](https://stedolan.github.io/jq/)（用于 JSON 处理）

```bash
# 安装 jq（如果未安装）
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

### 快速安装

```bash
# 克隆仓库
git clone https://github.com/Boulea7/claude-session-sync.git
cd claude-session-sync

# 运行安装脚本
bash hook/install.sh
```

### 安装器做了什么

1. ✅ 备份现有的 `~/.claude/settings.json`
2. ✅ 合并 PreToolUse hook 配置
3. ✅ 创建 `~/.claude/sessions.json` 模板

---

## 🚀 使用

### 零配置

**无需手动设置！** Hook 在需要时自动创建 `.claude/sessions.json`。

### 全自动工作流

Hook 全自动处理一切：

1. **MCP 调用前** → 如果不存在，自动创建 `.claude/sessions.json`
2. **注入上下文** → Claude 看到活跃的 SESSION_ID
3. **MCP 调用后** → Claude 更新 SESSION_ID

### 会话文件格式

```json
{
  "_schema_version": "1.0",
  "tasks": {
    "feature-auth": {
      "description": "实现认证系统",
      "codex_session_id": "abc-123-def-456",
      "gemini_session_id": "xyz-789-uvw",
      "updated_at": "2026-03-12T10:00:00Z"
    }
  }
}
```

---

## ⚙️ 配置

### Hook 配置

Hook 被添加到 `~/.claude/settings.json`：

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

> 如果会话文件不存在，hook 会自动创建。

### 自定义

#### 添加更多 MCP 工具

更新 matcher 模式：

```json
"matcher": "mcp__codexmcp__codex|mcp__gemini__gemini|mcp__your_tool__tool"
```

#### 更改会话文件位置

修改 hook 中的命令路径。

---

## 🔀 Hook 与 Skill 对比

| 方面 | Hook 版本 | Skill 版本 |
|------|----------|-----------|
| **自动化** | ✅ 全自动 | ❌ 手动调用 |
| **控制** | 被动 | 主动 |
| **适用于** | 日常工作流 | 显式管理 |
| **设置** | 运行安装器 | 复制 skill 文件 |

### 使用 Skill 版本

```bash
# 复制到 Claude 插件目录
mkdir -p ~/.claude/plugins/session-sync/skills
cp skill/session-sync.md ~/.claude/plugins/session-sync/skills/

# 然后在 Claude Code 中使用
/session-sync
```

---

## 🗑️ 卸载

```bash
bash hook/uninstall.sh
```

这将：
- 从 settings.json 中移除 hook
- 可选删除 sessions.json

---

## 📚 文档

- [使用指南](docs/USAGE.md)
- [故障排除](docs/TROUBLESHOOTING.md)
- [Skill 版本说明](skill/README.md)

---

## 🔗 相关项目

本项目设计用于配合以下工具：

| 项目 | 描述 |
|------|------|
| [Codex MCP](https://github.com/GuDaStudio/codexmcp) | Claude Code 的 OpenAI Codex 集成 |
| [Gemini MCP](https://github.com/GuDaStudio/geminimcp) | Claude Code 的 Google Gemini 集成 |

---

## 🤝 贡献

欢迎贡献！请随时提交 Pull Request。

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启 Pull Request

---

## 📄 License

[MIT](LICENSE) © 2026 Boulea7

---

<div align="center">

**为 Claude Code 社区用心制作 ❤️**

</div>
