# claude-session-sync installer for Windows
# Run in PowerShell: .\install.ps1

$ErrorActionPreference = "Stop"

$ClaudeDir = "$env:USERPROFILE\.claude"
$SettingsFile = "$ClaudeDir\settings.json"
$BackupDir = "$ClaudeDir\backups"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  🔄 claude-session-sync installer (Windows)" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

# Create directories
if (-not (Test-Path $ClaudeDir)) {
    Write-Host "Creating $ClaudeDir directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

# Backup existing settings.json
if (Test-Path $SettingsFile) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "$BackupDir\settings.json.$timestamp.bak"
    Write-Host "Backing up existing settings.json to:" -ForegroundColor Yellow
    Write-Host "  $backupFile"
    Copy-Item $SettingsFile $backupFile
    $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
} else {
    Write-Host "No existing settings.json found, creating new one..." -ForegroundColor Yellow
    $settings = @{}
}

# Define the hook configuration
$hookCommand = '[ -f .claude/sessions.json ] || (mkdir -p .claude && echo ''{"_schema_version":"1.0","_hint":"Track SESSION_IDs here. Update after each MCP call.","tasks":{}}'' > .claude/sessions.json); cat .claude/sessions.json'

$newHook = @{
    matcher = "mcp__codexmcp__codex|mcp__gemini__gemini"
    hooks = @(
        @{
            type = "command"
            command = $hookCommand
            timeout = 3000
        }
    )
}

Write-Host "Merging hook configuration..." -ForegroundColor Green

# Initialize hooks structure if needed
if (-not $settings.hooks) {
    $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue @{} -Force
}
if (-not $settings.hooks.PreToolUse) {
    $settings.hooks | Add-Member -NotePropertyName "PreToolUse" -NotePropertyValue @() -Force
}

# Remove existing session-sync hook if present
$settings.hooks.PreToolUse = @($settings.hooks.PreToolUse | Where-Object {
    $_.matcher -ne "mcp__codexmcp__codex|mcp__gemini__gemini"
})

# Add new hook
$settings.hooks.PreToolUse += $newHook

# Save settings
$settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8

Write-Host "Hook configuration merged successfully!" -ForegroundColor Green
Write-Host ""

# Create sessions.json template
$sessionsFile = "$ClaudeDir\sessions.json"
Write-Host "Creating sessions.json template..." -ForegroundColor Green

if (-not (Test-Path $sessionsFile)) {
    $sessionsTemplate = @{
        _schema_version = "1.0"
        _hint = "This file tracks SESSION_IDs for multi-model collaboration. Update this file after each MCP call."
        _usage = @{
            codex = "Store codex SESSION_ID under tasks.<task_name>.codex_session_id"
            gemini = "Store gemini SESSION_ID under tasks.<task_name>.gemini_session_id"
        }
        tasks = @{}
    }
    $sessionsTemplate | ConvertTo-Json -Depth 5 | Set-Content $sessionsFile -Encoding UTF8
    Write-Host "  Created: $sessionsFile"
} else {
    Write-Host "  sessions.json already exists, skipping..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart Claude Code to apply changes"
Write-Host "  2. That's it! The hook will auto-create sessions.json when needed" -ForegroundColor Green
Write-Host ""
