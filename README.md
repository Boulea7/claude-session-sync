<div align="center">

# 🔄 claude-session-sync

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai/code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**Automatic SESSION_ID management for Claude Code multi-model collaboration**

**Claude Code 多模型协作的 SESSION_ID 自动管理工具**

[Features](#-features--特性) •
[Installation](#-installation--安装) •
[Usage](#-usage--使用) •
[Related](#-related-projects--相关项目)

</div>

---

## 🤔 Problem / 问题

When using Claude Code with multiple AI models (Codex, Gemini), SESSION_IDs are often forgotten between calls, causing:

使用 Claude Code 进行多模型协作（Codex、Gemini）时，SESSION_ID 经常在调用间被遗忘，导致：

- ❌ Lost conversation context / 丢失对话上下文
- ❌ Repeated explanations / 重复解释
- ❌ Inefficient collaboration / 协作效率低下
- ❌ Session confusion across tasks / 跨任务会话混乱

## 💡 Solution / 解决方案

**claude-session-sync** automatically injects session state before each MCP call using PreToolUse hooks.

**claude-session-sync** 使用 PreToolUse hooks 在每次 MCP 调用前自动注入会话状态。

---

## ✨ Features / 特性

| Feature | Description |
|---------|-------------|
| 🔄 **Auto Injection** | Automatically inject session state before Codex/Gemini calls |
| 📁 **Project-level State** | Each project maintains its own session state |
| 🛠️ **Easy Setup** | One-command installation |
| 🎯 **Selective Trigger** | Only triggers for Codex and Gemini MCP tools |
| 📝 **Skill Alternative** | Manual skill version for explicit control |

| 特性 | 描述 |
|------|------|
| 🔄 **自动注入** | 在 Codex/Gemini 调用前自动注入会话状态 |
| 📁 **项目级状态** | 每个项目维护独立的会话状态 |
| 🛠️ **简单设置** | 一键安装 |
| 🎯 **选择性触发** | 仅对 Codex 和 Gemini MCP 工具触发 |
| 📝 **Skill 备选** | 手动 skill 版本提供显式控制 |

---

## 📦 Installation / 安装

### Prerequisites / 前置要求

- [Claude Code](https://claude.ai/code) installed
- [jq](https://stedolan.github.io/jq/) for JSON processing

```bash
# Install jq (if not installed)
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

### Quick Install / 快速安装

```bash
# Clone the repository
git clone https://github.com/Boulea7/claude-session-sync.git
cd claude-session-sync

# Run the installer
bash hook/install.sh
```

### What the installer does / 安装器做了什么

1. ✅ Backs up your existing `~/.claude/settings.json`
2. ✅ Merges the PreToolUse hook configuration
3. ✅ Creates `~/.claude/sessions.json` template

---

## 🚀 Usage / 使用

### Zero Configuration / 零配置

**No manual setup required!** The hook automatically creates `.claude/sessions.json` when needed.

**无需手动设置！** Hook 在需要时自动创建 `.claude/sessions.json`。

### Fully Automatic Workflow / 全自动工作流

The hook automatically handles everything:

1. **Before MCP call** → Auto-creates `.claude/sessions.json` if missing
2. **Injects context** → Claude sees active session IDs
3. **After MCP call** → Claude updates the SESSION_ID

Hook 全自动处理一切：

1. **MCP 调用前** → 如果不存在，自动创建 `.claude/sessions.json`
2. **注入上下文** → Claude 看到活跃的 SESSION_ID
3. **MCP 调用后** → Claude 更新 SESSION_ID

### 3. Session File Format / 会话文件格式

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

## ⚙️ Configuration / 配置

### Hook Configuration / Hook 配置

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
> 如果会话文件不存在，hook 会自动创建。

### Customization / 自定义

#### Add more MCP tools / 添加更多 MCP 工具

Update the matcher pattern:

```json
"matcher": "mcp__codexmcp__codex|mcp__gemini__gemini|mcp__your_tool__tool"
```

#### Change session file location / 更改会话文件位置

Modify the command path in the hook.

---

## 🔀 Hook vs Skill / Hook 与 Skill 对比

| Aspect | Hook Version | Skill Version |
|--------|--------------|---------------|
| **Automation** | ✅ Fully automatic | ❌ Manual invocation |
| **Control** | Passive | Active |
| **Best for** | Daily workflow | Explicit management |
| **Setup** | Run installer | Copy skill file |

| 方面 | Hook 版本 | Skill 版本 |
|------|----------|-----------|
| **自动化** | ✅ 全自动 | ❌ 手动调用 |
| **控制** | 被动 | 主动 |
| **适用于** | 日常工作流 | 显式管理 |
| **设置** | 运行安装器 | 复制 skill 文件 |

### Using Skill Version / 使用 Skill 版本

```bash
# Copy to Claude plugins
mkdir -p ~/.claude/plugins/session-sync/skills
cp skill/session-sync.md ~/.claude/plugins/session-sync/skills/

# Then use in Claude Code
/session-sync
```

---

## 🗑️ Uninstall / 卸载

```bash
bash hook/uninstall.sh
```

This will:
- Remove the hook from settings.json
- Optionally delete sessions.json

---

## 📚 Documentation / 文档

- [Usage Guide / 使用指南](docs/USAGE.md)
- [Troubleshooting / 故障排除](docs/TROUBLESHOOTING.md)
- [Skill Version / Skill 版本](skill/README.md)

---

## 🔗 Related Projects / 相关项目

This project is designed to work with:

| Project | Description |
|---------|-------------|
| [Codex MCP](https://github.com/GuDaStudio/codexmcp) | OpenAI Codex integration for Claude Code |
| [Gemini MCP](https://github.com/GuDaStudio/geminimcp) | Google Gemini integration for Claude Code |

本项目设计用于配合：

| 项目 | 描述 |
|------|------|
| [Codex MCP](https://github.com/GuDaStudio/codexmcp) | Claude Code 的 OpenAI Codex 集成 |
| [Gemini MCP](https://github.com/GuDaStudio/geminimcp) | Claude Code 的 Google Gemini 集成 |

---

## 🤝 Contributing / 贡献

Contributions are welcome! Please feel free to submit a Pull Request.

欢迎贡献！请随时提交 Pull Request。

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

**为 Claude Code 社区用心制作**

</div>
