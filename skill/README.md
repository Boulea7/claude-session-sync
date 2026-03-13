# Skill Version / Skill 版本

This directory contains the skill-based implementation of session-sync.

此目录包含 session-sync 的 skill 版本实现。

## Installation / 安装

### Option 1: Copy to Claude plugins directory / 复制到 Claude 插件目录

```bash
mkdir -p ~/.claude/plugins/session-sync/skills
cp session-sync.md ~/.claude/plugins/session-sync/skills/
```

### Option 2: Copy to your project / 复制到项目目录

```bash
mkdir -p .claude/skills
cp /path/to/claude-session-sync/skill/session-sync.md .claude/skills/
```

> **Note:** For simplicity, use `cp` instead of a symlink. The hook's symlink protection applies only to `.claude/` and `.claude/sessions.json`, not to skill files.

## Usage / 使用

Once installed, you can invoke the skill with:

```
/session-sync
```

Or use natural language triggers:
- "save session"
- "session status"
- "list sessions"
- "sync session"

## When to Use / 何时使用

Use the skill version when:
- You prefer manual control over session management
- You want to explicitly save/load sessions
- The hook version conflicts with other hooks

使用 skill 版本的场景：
- 你更喜欢手动控制会话管理
- 你想显式地保存/加载会话
- hook 版本与其他 hooks 冲突

## Comparison with Hook Version / 与 Hook 版本对比

| Feature | Hook Version | Skill Version |
|---------|--------------|---------------|
| Automatic | ✅ Yes | ❌ No |
| Manual control | ❌ Limited | ✅ Full |
| Setup complexity | Simple | Simple |
| Conflict risk | Low | None |

## File Structure / 文件结构

```
skill/
├── session-sync.md    # Skill definition
└── README.md          # This file
```
