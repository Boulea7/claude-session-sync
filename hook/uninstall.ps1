# claude-session-sync uninstaller for Windows
# Run in PowerShell: .\uninstall.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ClaudeDir = "$env:USERPROFILE\.claude"
$SettingsFile = "$ClaudeDir\settings.json"
$BackupDir = "$ClaudeDir\backups"
$Matcher = "mcp__codexmcp__codex|mcp__gemini__gemini"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  claude-session-sync uninstaller (Windows)" -ForegroundColor Blue
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

# Load settings
try {
    $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
} catch {
    Write-Host "Error: settings.json is not valid JSON." -ForegroundColor Red
    exit 1
}

Write-Host "Removing hook configuration..." -ForegroundColor Green

# Remove hook safely (check if PreToolUse exists)
if ($settings.hooks -and $settings.hooks.PSObject.Properties["PreToolUse"]) {
    $settings.hooks.PreToolUse = @($settings.hooks.PreToolUse | Where-Object {
        $_.matcher -ne $Matcher
    })

    # Clean up empty arrays
    if ($settings.hooks.PreToolUse.Count -eq 0) {
        $settings.hooks.PSObject.Properties.Remove("PreToolUse")
    }
    if ($settings.hooks.PSObject.Properties.Count -eq 0) {
        $settings.PSObject.Properties.Remove("hooks")
    }
}

# Save settings (UTF-8 without BOM)
$jsonContent = $settings | ConvertTo-Json -Depth 10
$encoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($SettingsFile, $jsonContent, $encoding)

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
