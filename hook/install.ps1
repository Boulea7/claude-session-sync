# claude-session-sync installer for Windows
# Run in PowerShell: .\install.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ClaudeDir = "$env:USERPROFILE\.claude"
$SettingsFile = "$ClaudeDir\settings.json"
$BackupDir = "$ClaudeDir\backups"
$Matcher = "mcp__codex__codex|mcp__gemini__gemini"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  claude-session-sync installer (Windows)" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

# Check Git Bash
$gitBash = $env:CLAUDE_CODE_GIT_BASH_PATH
if (-not $gitBash) {
    $gitBash = @(
        "$env:ProgramFiles\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe"
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}

if (-not $gitBash) {
    Write-Host "Error: Git Bash not found." -ForegroundColor Red
    Write-Host "Install Git for Windows or set CLAUDE_CODE_GIT_BASH_PATH." -ForegroundColor Red
    exit 1
}
Write-Host "Git Bash found: $gitBash" -ForegroundColor Green

# Create directories
if (-not (Test-Path $ClaudeDir)) {
    Write-Host "Creating $ClaudeDir directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

# Backup and load existing settings.json
if (Test-Path $SettingsFile) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "$BackupDir\settings.json.$timestamp.bak"
    Write-Host "Backing up existing settings.json to:" -ForegroundColor Yellow
    Write-Host "  $backupFile"
    Copy-Item $SettingsFile $backupFile
    # Keep only the 5 most recent backups
    Get-ChildItem "$BackupDir\settings.json.*.bak" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 5 | Remove-Item -Force
    try {
        $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
    } catch {
        Write-Host "Error: settings.json is not valid JSON. Restore from backup first." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "No existing settings.json found, creating new one..." -ForegroundColor Yellow
    $settings = [pscustomobject]@{}
}

# Read hook configuration from settings.snippet.json
$snippetPath = Join-Path $PSScriptRoot "settings.snippet.json"
if (-not (Test-Path $snippetPath)) {
    Write-Host "Error: settings.snippet.json not found." -ForegroundColor Red
    exit 1
}
try {
    $snippetConfig = Get-Content $snippetPath -Raw | ConvertFrom-Json
} catch {
    Write-Host "Error: settings.snippet.json is not valid JSON." -ForegroundColor Red
    exit 1
}
$newHooks = $snippetConfig.hooks.PreToolUse

Write-Host "Merging hook configuration..." -ForegroundColor Green

# Initialize hooks structure if needed (using pscustomobject for proper JSON serialization)
if (-not $settings.PSObject.Properties["hooks"]) {
    $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([pscustomobject]@{}) -Force
}
if (-not $settings.hooks.PSObject.Properties["PreToolUse"]) {
    $settings.hooks | Add-Member -NotePropertyName "PreToolUse" -NotePropertyValue @() -Force
}

# Remove existing session-sync hook if present (by matcher)
$settings.hooks.PreToolUse = @($settings.hooks.PreToolUse | Where-Object {
    $_.matcher -ne $Matcher
})

# Add new hooks from snippet
foreach ($hook in $newHooks) {
    $settings.hooks.PreToolUse += $hook
}

# Save settings (UTF-8 without BOM)
$jsonContent = $settings | ConvertTo-Json -Depth 10
$encoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($SettingsFile, $jsonContent, $encoding)

Write-Host "Hook configuration merged successfully!" -ForegroundColor Green
Write-Host ""

# Create sessions.json template
$sessionsFile = "$ClaudeDir\sessions.json"
Write-Host "Creating sessions.json template..." -ForegroundColor Green

if (-not (Test-Path $sessionsFile)) {
    $sessionsTemplate = [pscustomobject]@{
        _schema_version = "1.0"
        _hint = "Track SESSION_IDs here. Do not store secrets or tokens."
        tasks = [pscustomobject]@{}
    }
    $sessionsJson = $sessionsTemplate | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($sessionsFile, $sessionsJson, $encoding)
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
