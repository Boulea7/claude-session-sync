---
name: session-sync
description: |
  Manage SESSION_IDs for multi-model collaboration (Codex/Gemini).
  Use this skill to: save session IDs, retrieve session context, or list active sessions.
  Triggers: "save session", "session status", "list sessions", "sync session"
tools:
  - Read
  - Write
  - Edit
  - Glob
---

# Session Sync Skill

You are helping the user manage SESSION_IDs for multi-model collaboration with Codex and Gemini MCPs.

## Session File Location

The session state is stored in `.claude/sessions.json` in the current project directory.

## Actions

### 1. Check Session Status

First, read the current session state:

```
Read .claude/sessions.json
```

If the file doesn't exist, inform the user and offer to create it.

### 2. Save a Session ID

When the user wants to save a session ID, update the sessions.json file:

```json
{
  "_schema_version": "1.0",
  "tasks": {
    "<task_name>": {
      "description": "<brief task description>",
      "codex_session_id": "<SESSION_ID from codex>",
      "gemini_session_id": "<SESSION_ID from gemini>",
      "created_at": "<ISO timestamp>",
      "updated_at": "<ISO timestamp>"
    }
  }
}
```

### 3. Resume a Session

When the user wants to resume a previous session:

1. Read sessions.json
2. Find the relevant task
3. Display the SESSION_IDs
4. Remind the user to pass these IDs to the next MCP call

### 4. Clean Up Old Sessions

When requested, remove completed or stale sessions from the file.

## Important Reminders

After every Codex or Gemini MCP call that returns a SESSION_ID:

1. **Always** save the SESSION_ID to sessions.json
2. **Always** use the saved SESSION_ID for follow-up calls to the same task
3. Different tasks should have different session entries

## Example Workflow

```
User: "Save the codex session for the refactoring task"

1. Read .claude/sessions.json
2. Add/update entry:
   {
     "tasks": {
       "refactoring": {
         "description": "Code refactoring task",
         "codex_session_id": "abc-123-def",
         "updated_at": "2026-03-12T10:30:00Z"
       }
     }
   }
3. Write updated file
4. Confirm to user
```

## Error Handling

- If sessions.json doesn't exist, create it with the template structure
- If a task doesn't exist, create a new entry
- If updating fails, inform the user and suggest manual intervention
