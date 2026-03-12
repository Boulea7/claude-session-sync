# Usage Guide / 使用指南

## Overview / 概述

claude-session-sync helps maintain SESSION_ID continuity across multi-model collaboration sessions with Codex and Gemini MCPs.

claude-session-sync 帮助在 Codex 和 Gemini MCP 的多模型协作会话中保持 SESSION_ID 的连续性。

---

## Hook Version Workflow / Hook 版本工作流程

### How It Works / 工作原理

1. **Before each MCP call** / 每次 MCP 调用前
   - The PreToolUse hook triggers
   - It reads `.claude/sessions.json` from your project
   - Session state is injected into the context

2. **After MCP returns** / MCP 返回后
   - You (or Claude) should update sessions.json with the new SESSION_ID
   - This ensures the next call has the correct context

### Project Setup / 项目设置

For each project where you want session tracking:

```bash
# Create .claude directory in your project
mkdir -p .claude

# Copy the sessions template
cp ~/.claude/sessions.json .claude/sessions.json
```

### Session File Structure / 会话文件结构

```json
{
  "_schema_version": "1.0",
  "tasks": {
    "feature-auth": {
      "description": "Implementing authentication system",
      "codex_session_id": "abc-123-def-456",
      "gemini_session_id": "xyz-789-uvw-012",
      "created_at": "2026-03-12T10:00:00Z",
      "updated_at": "2026-03-12T14:30:00Z"
    },
    "bugfix-login": {
      "description": "Fixing login redirect bug",
      "codex_session_id": "bug-fix-session-001",
      "updated_at": "2026-03-12T15:00:00Z"
    }
  }
}
```

---

## Best Practices / 最佳实践

### 1. One Task, One Session Entry / 一个任务一个会话条目

Keep related work in the same session entry:

```json
{
  "tasks": {
    "refactor-api": {
      "codex_session_id": "session-for-api-refactor"
    }
  }
}
```

### 2. Clean Up Completed Tasks / 清理已完成的任务

Remove old entries when tasks are done:

```bash
# Edit .claude/sessions.json
# Remove completed task entries
```

### 3. Don't Commit sessions.json / 不要提交 sessions.json

Add to your `.gitignore`:

```
.claude/sessions.json
```

Session IDs are ephemeral and project-specific.

---

## Troubleshooting / 故障排除

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues.

---

## Examples / 示例

### Starting a New Task / 开始新任务

1. Create a task entry in sessions.json:
   ```json
   {
     "tasks": {
       "my-new-feature": {
         "description": "Building new feature X"
       }
     }
   }
   ```

2. Call Codex/Gemini - session state will be injected

3. After the call, update with the returned SESSION_ID

### Resuming Work / 恢复工作

1. Check sessions.json for your task's SESSION_ID
2. Pass it to your next MCP call
3. The hook will remind you of active sessions automatically

---

## Integration with CLAUDE.md / 与 CLAUDE.md 集成

Add these instructions to your project's CLAUDE.md:

```markdown
## Session Management

- Always check .claude/sessions.json before MCP calls
- Save SESSION_ID after each Codex/Gemini call
- Use the same SESSION_ID for related follow-up calls
```
