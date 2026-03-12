# Troubleshooting / 故障排除

## Common Issues / 常见问题

### 1. Hook Not Triggering / Hook 未触发

**Symptoms / 症状:**
- No session state injected before MCP calls
- `sessions.json` not being read

**Solutions / 解决方案:**

1. **Verify hook installation / 验证 hook 安装:**
   ```bash
   cat ~/.claude/settings.json | jq '.hooks.PreToolUse'
   ```

   Should show the session-sync hook configuration.

2. **Check matcher pattern / 检查匹配模式:**

   The hook should match: `mcp__codexmcp__codex|mcp__gemini__gemini`

   If your MCP tools have different names, update the matcher.

3. **Restart Claude Code / 重启 Claude Code:**

   Settings changes require a restart to take effect.

---

### 2. sessions.json Not Found / 找不到 sessions.json

**Symptoms / 症状:**
- Hook outputs: `No active sessions. Remember to save SESSION_ID...`

**Solutions / 解决方案:**

1. **Create project-level sessions.json / 创建项目级 sessions.json:**
   ```bash
   mkdir -p .claude
   cp ~/.claude/sessions.json .claude/sessions.json
   ```

2. **Verify file path / 验证文件路径:**

   The hook reads from `.claude/sessions.json` relative to your working directory.

---

### 3. jq Not Installed / 未安装 jq

**Symptoms / 症状:**
- Install script fails with "jq is required"

**Solutions / 解决方案:**

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# CentOS/RHEL
sudo yum install jq
```

---

### 4. Hook Conflicts / Hook 冲突

**Symptoms / 症状:**
- Other PreToolUse hooks stop working
- Unexpected behavior

**Solutions / 解决方案:**

1. **Check hook order / 检查 hook 顺序:**
   ```bash
   cat ~/.claude/settings.json | jq '.hooks.PreToolUse'
   ```

2. **Ensure hooks are additive / 确保 hooks 是叠加的:**

   Multiple hooks in the array should all execute. If not, check for conflicting matchers.

---

### 5. SESSION_ID Not Persisted / SESSION_ID 未持久化

**Symptoms / 症状:**
- SESSION_ID lost between calls
- Context not maintained

**Solutions / 解决方案:**

1. **Manually update sessions.json / 手动更新 sessions.json:**

   After each MCP call, update the file:
   ```json
   {
     "tasks": {
       "my-task": {
         "codex_session_id": "<new-session-id>"
       }
     }
   }
   ```

2. **Use the skill version / 使用 skill 版本:**

   The skill provides explicit session management commands.

---

### 6. Permission Denied / 权限被拒绝

**Symptoms / 症状:**
- Install script fails
- Cannot write to settings.json

**Solutions / 解决方案:**

```bash
# Fix permissions
chmod 644 ~/.claude/settings.json
chmod 755 ~/.claude

# Run install with correct permissions
bash hook/install.sh
```

---

## Getting Help / 获取帮助

If you encounter issues not covered here:

1. **Check the GitHub Issues:**
   https://github.com/Boulea7/claude-session-sync/issues

2. **Open a new issue with:**
   - Your OS and Claude Code version
   - Contents of `~/.claude/settings.json`
   - Error messages or unexpected behavior
   - Steps to reproduce

---

## Debugging Tips / 调试技巧

### Enable verbose hook output / 启用详细 hook 输出

Modify the hook command to include more info:

```json
{
  "command": "echo '=== Session State ===' && cat .claude/sessions.json 2>/dev/null || echo '{\"_hint\": \"No sessions\"}'"
}
```

### Test hook manually / 手动测试 hook

```bash
cd /your/project
cat .claude/sessions.json
```

### Check Claude Code logs / 检查 Claude Code 日志

Look for hook execution in Claude Code's output when calling MCP tools.
