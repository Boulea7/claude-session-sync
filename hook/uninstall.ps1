# claude-session-sync uninstaller for Windows
# Run in PowerShell: .\uninstall.ps1

$ErrorActionPreference = "Stop"

$ClaudeDir = "$env:USERPROFILE\.claude"
$SettingsFile = "$ClaudeDir\settings.json"
$BackupDir = "$ClaudeDir\backups"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  🔄 claude-session-sync uninstaller (Windows)" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

if (-not (Test-Path $SettingsFile)) {
    Write-Host "No settings.json found. Nothing to uninstall." -ForegroundColor Yellow
    exit 0
}

# Backup before uninstall
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "$BackupDir\settings.json.$timestamp.pre-uninstall.bak"
Write-Host "Backing up settings.json to:" -ForegroundColor Yellow
Write-Host "  $backupFile"
Copy-Item $SettingsFile $backupFile

# Load and modify settings
$settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json

Write-Host "Removing hook configuration..." -ForegroundColor Green

if ($settings.hooks -and $settings.hooks.PreToolUse) {
    $settings.hooks.PreToolUse = @($settings.hooks.PreToolUse | Where-Object {
        $_.matcher -ne "mcp__codexmcp__codex|mcp__gemini__gemini"
    })

    # Clean up empty arrays
    if ($settings.hooks.PreToolUse.Count -eq 0) {
        $settings.hooks.PSObject.Properties.Remove("PreToolUse")
    }
    if ($settings.hooks.PSObject.Properties.Count -eq 0) {
        $settings.PSObject.Properties.Remove("hooks")
    }
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8

Write-Host "Hook removed successfully!" -ForegroundColor Green
Write-Host ""

# Ask about sessions.json
$sessionsFile = "$ClaudeDir\sessions.json"
if (Test-Path $sessionsFile) {
    $response = Read-Host "Do you want to remove $sessionsFile? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        Remove-Item $sessionsFile
        Write-Host "Removed $sessionsFile" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  Uninstallation complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Project-level .claude\sessions.json files were not removed."
Write-Host "Remove them manually if needed."
Write-Host ""
