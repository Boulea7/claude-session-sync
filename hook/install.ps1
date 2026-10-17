# claude-session-sync installer for Windows
# Run in PowerShell: .\install.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-HookGroups {
    param($Groups)
    if ($Groups -isnot [array]) {
        throw "PreToolUse must be an array."
    }
    foreach ($group in $Groups) {
        if ($group -isnot [pscustomobject] -or
            -not $group.PSObject.Properties["hooks"] -or
            $group.hooks -isnot [array]) {
            throw "PreToolUse groups must be objects with a hooks array."
        }
        foreach ($handler in $group.hooks) {
            if ($handler -isnot [pscustomobject]) {
                throw "Hook handlers must be objects."
            }
        }
    }
}

function Test-SessionSyncHandler {
    param($Handler, $Expected)
    $properties = @($Handler.PSObject.Properties)
    $expectedProperties = @($Expected.PSObject.Properties)
    if ($properties.Count -ne $expectedProperties.Count) { return $false }
    foreach ($property in $expectedProperties) {
        $actual = $properties | Where-Object { $_.Name -ceq $property.Name } | Select-Object -First 1
        if ($null -eq $actual) { return $false }
        $value = $property.Value
        if ($null -eq $value) {
            if ($null -ne $actual.Value) { return $false }
        } elseif ($value -is [string] -or $value -is [bool] -or
                  $value -is [int] -or $value -is [long] -or
                  $value -is [double] -or $value -is [decimal]) {
            if ($null -eq $actual.Value -or $actual.Value.GetType() -ne $value.GetType() -or
                $actual.Value -cne $value) { return $false }
        } else {
            # The shipped handlers use scalar fields; preserve unsupported values.
            return $false
        }
    }
    return $true
}

$ClaudeDir = "$env:USERPROFILE\.claude"
$SettingsFile = "$ClaudeDir\settings.json"
$BackupDir = "$ClaudeDir\backups"
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

# Refuse symlinked paths
foreach ($path in @($ClaudeDir, $SettingsFile, $BackupDir)) {
    if ((Test-Path -LiteralPath $path) -and (Get-Item -LiteralPath $path).LinkType) {
        Write-Host "Error: refusing symlinked path: $path" -ForegroundColor Red
        exit 1
    }
}

# Create directories
if (-not (Test-Path $ClaudeDir)) {
    Write-Host "Creating $ClaudeDir directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

# Preserve timestamp strings when the parser supports DateKind.
$jsonReadOptions = @{}
if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey("DateKind")) {
    $jsonReadOptions["DateKind"] = "String"
}

# Backup and load existing settings.json
if (Test-Path $SettingsFile) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "$BackupDir\settings.json.$timestamp.bak"
    Write-Host "Backing up existing settings.json to:" -ForegroundColor Yellow
    Write-Host "  $backupFile"
    Copy-Item $SettingsFile $backupFile
    # Keep only the 5 most recent backups
    Get-ChildItem "$BackupDir\settings.json.*.bak" | Where-Object { $_.Name -notlike '*.pre-uninstall.bak' } | Sort-Object LastWriteTime -Descending | Select-Object -Skip 5 | Remove-Item -Force
    try {
        $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json @jsonReadOptions
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
    $snippetConfig = Get-Content $snippetPath -Raw | ConvertFrom-Json @jsonReadOptions
} catch {
    Write-Host "Error: settings.snippet.json is not valid JSON." -ForegroundColor Red
    exit 1
}
if ($snippetConfig -isnot [pscustomobject] -or
    -not $snippetConfig.PSObject.Properties["hooks"] -or
    $snippetConfig.hooks -isnot [pscustomobject] -or
    -not $snippetConfig.hooks.PSObject.Properties["PreToolUse"]) {
    throw "Snippet must contain PreToolUse hook groups."
}
$newHooks = $snippetConfig.hooks.PreToolUse
Assert-HookGroups $newHooks
if ($newHooks.Count -eq 0 -or @($newHooks | Where-Object { $_.hooks.Count -eq 0 }).Count -gt 0) {
    throw "Snippet must contain hook handlers."
}

Write-Host "Merging hook configuration..." -ForegroundColor Green

# Initialize hooks structure if needed (using pscustomobject for proper JSON serialization)
if ($settings -isnot [pscustomobject]) {
    throw "Settings must be an object."
}
if (-not $settings.PSObject.Properties["hooks"] -or $null -eq $settings.hooks) {
    $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([pscustomobject]@{}) -Force
} elseif ($settings.hooks -isnot [pscustomobject]) {
    throw "Settings hooks must be an object."
}
if (-not $settings.hooks.PSObject.Properties["PreToolUse"] -or $null -eq $settings.hooks.PreToolUse) {
    $settings.hooks | Add-Member -NotePropertyName "PreToolUse" -NotePropertyValue @() -Force
}
Assert-HookGroups $settings.hooks.PreToolUse

# Remove complete matching handlers across all matchers, keeping nonempty groups.
$projectHandlers = @($newHooks | ForEach-Object { $_.hooks })
$remainingGroups = @(
    foreach ($group in $settings.hooks.PreToolUse) {
        $group.hooks = @(
            foreach ($handler in $group.hooks) {
                $matched = $false
                foreach ($expected in $projectHandlers) {
                    if (Test-SessionSyncHandler $handler $expected) {
                        $matched = $true
                        break
                    }
                }
                if (-not $matched) { $handler }
            }
        )
        if ($group.hooks.Count -gt 0) { $group }
    }
)
$settings.hooks.PreToolUse = $remainingGroups + @($newHooks)

# Save settings atomically (UTF-8 without BOM)
$encoding = New-Object System.Text.UTF8Encoding($false)
$jsonContent = $settings | ConvertTo-Json -Depth 100 -WarningAction Stop
$tempFile = Join-Path $ClaudeDir ("settings.json.{0}.tmp" -f [guid]::NewGuid().ToString("N"))
try {
    [System.IO.File]::WriteAllText($tempFile, $jsonContent, $encoding)
    Move-Item -LiteralPath $tempFile -Destination $SettingsFile -Force
} finally {
    if (Test-Path -LiteralPath $tempFile) { Remove-Item -LiteralPath $tempFile -Force }
}

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
    $sessionsTemp = Join-Path $ClaudeDir (".sessions.{0}.tmp" -f [guid]::NewGuid().ToString("N"))
    try {
        [System.IO.File]::WriteAllText($sessionsTemp, $sessionsJson, $encoding)
        Move-Item -LiteralPath $sessionsTemp -Destination $sessionsFile -Force
    } finally {
        if (Test-Path -LiteralPath $sessionsTemp) { Remove-Item -LiteralPath $sessionsTemp -Force }
    }
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
