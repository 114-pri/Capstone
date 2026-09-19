<#
.SYNOPSIS
    Real-time GitHub Auto-Sync Watcher for LFSR_BIST_ALU_Vivado
.DESCRIPTION
    Monitors the repository directory for file changes and debounces multiple saves.
    Automatically stages, commits, and pushes changes to GitHub.
#>

param(
    [int]$DebounceSeconds = 7
)

$repoRoot = (Get-Item $PSScriptRoot).Parent.FullName
Set-Location $repoRoot

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  GitHub Auto-Sync Watcher Active" -ForegroundColor Cyan
Write-Host "  Repository: $repoRoot" -ForegroundColor Gray
Write-Host "  Debounce Window: $DebounceSeconds seconds" -ForegroundColor Gray
Write-Host "=======================================================" -ForegroundColor Cyan

# Verify git remote
$remoteUrl = git remote get-url origin 2>$null
if (-not $remoteUrl) {
    Write-Host "[WARNING] No remote 'origin' configured for this git repository!" -ForegroundColor Yellow
    Write-Host "Please configure your GitHub remote before auto-sync can push:" -ForegroundColor Yellow
    Write-Host "  git remote add origin https://github.com/<username>/<repo>.git" -ForegroundColor White
} else {
    Write-Host "[INFO] Remote target: $remoteUrl" -ForegroundColor Green
}

# Verify user.name and user.email
$gitUser = git config user.name
$gitEmail = git config user.email
if (-not $gitUser -or -not $gitEmail) {
    Write-Host "[WARNING] Git user identity is not set. Setting local fallback identity..." -ForegroundColor Yellow
    if (-not $gitUser) { git config user.name "Project Contributor" }
    if (-not $gitEmail) { git config user.email "contributor@local" }
}

$lastChangeTime = [DateTime]::MinValue
$pendingSync = $false

function Invoke-GitSync {
    try {
        $status = git status --porcelain
        if (-not $status) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] No modified tracked files to commit." -ForegroundColor DarkGray
            return
        }

        Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Changes detected. Syncing with GitHub..." -ForegroundColor Yellow
        
        # Add all tracked and new files (respecting .gitignore)
        git add -A
        
        # Commit with timestamp
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $commitMsg = "Auto-update: $timestamp"
        $commitResult = git commit -m "$commitMsg"
        Write-Host $commitResult -ForegroundColor DarkCyan

        # Push to remote
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Pushing to remote..." -ForegroundColor Cyan
        $pushResult = git push origin HEAD 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] SUCCESS: Successfully pushed to GitHub!" -ForegroundColor Green
        } else {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] PUSH FAILED: $pushResult" -ForegroundColor Red
            Write-Host "Tip: If remote has new commits, try: git pull --rebase origin main" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ERROR during sync: $_" -ForegroundColor Red
    }
}

# Setup FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $repoRoot
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite, DirectoryName'

$action = {
    param($source, $event)
    $path = $event.FullPath
    
    # Ignore internal git and vivado temporary files/folders
    if ($path -match '\\\.git\\' -or 
        $path -match '\\\.Xil\\' -or 
        $path -match '\\\.vivado_user_data\\' -or 
        $path -match '\.cache\\' -or 
        $path -match '\.runs\\' -or 
        $path -match '\.hw\\' -or 
        $path -match '\.sim\\' -or 
        $path -match '\.jou$' -or 
        $path -match '\.log$' -or 
        $path -match '\.str$') {
        return
    }

    $global:lastChangeTime = [DateTime]::Now
    $global:pendingSync = $true
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] File modified: $($event.Name)" -ForegroundColor DarkGray
}

$handlers = @(
    Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action,
    Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action,
    Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $action,
    Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $action
)

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Watcher started. Monitoring for file changes... (Press Ctrl+C to stop)" -ForegroundColor Green

try {
    while ($true) {
        Start-Sleep -Milliseconds 1000
        if ($global:pendingSync -and ([DateTime]::Now - $global:lastChangeTime).TotalSeconds -ge $DebounceSeconds) {
            $global:pendingSync = $false
            Invoke-GitSync
        }
    }
} finally {
    Write-Host "`nStopping file watcher..." -ForegroundColor Yellow
    $watcher.EnableRaisingEvents = $false
    foreach ($h in $handlers) {
        Unregister-Event -SourceIdentifier $h.Name -ErrorAction SilentlyContinue
    }
    $watcher.Dispose()
    Write-Host "Auto-Sync stopped." -ForegroundColor Gray
}
