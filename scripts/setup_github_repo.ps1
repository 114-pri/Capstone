<#
.SYNOPSIS
    Interactive GitHub Repository Setup & Initial Push for LFSR_BIST_ALU_Vivado
#>

$repoRoot = (Get-Item $PSScriptRoot).Parent.FullName
Set-Location $repoRoot

$ghPath = "C:\Program Files\GitHub CLI\gh.exe"
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    if (Test-Path $ghPath) {
        $env:Path = "$([System.IO.Path]::GetDirectoryName($ghPath));$env:Path"
    } else {
        Write-Host "[ERROR] GitHub CLI (gh) not found in PATH or at '$ghPath'." -ForegroundColor Red
        Write-Host "Please install it or provide an existing repository URL." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "     WA-LP-BIST RISC-V Project - GitHub Setup Wizard" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""

# Check existing remote
$existingRemote = git remote get-url origin 2>$null
if ($existingRemote) {
    Write-Host "[INFO] A remote repository is already configured: $existingRemote" -ForegroundColor Green
    $ans = Read-Host "Do you want to push to this existing remote now? (Y/n)"
    if ($ans -eq "" -or $ans -match "^[Yy]") {
        Write-Host "Pushing main branch to origin..." -ForegroundColor Cyan
        git push -u origin main
        Write-Host "[SUCCESS] Repository pushed to $existingRemote!" -ForegroundColor Green
        
        Write-Host "`nStarting background auto-sync watcher..." -ForegroundColor Cyan
        & "$PSScriptRoot\auto_sync_github.ps1"
        exit 0
    }
}

# Check GitHub CLI Authentication
Write-Host "Checking GitHub authentication status..." -ForegroundColor Gray
$authCheck = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[STEP 1/3] You are not currently logged into GitHub." -ForegroundColor Yellow
    Write-Host "We will open your web browser to authenticate securely with GitHub." -ForegroundColor Yellow
    Write-Host "Press ENTER to open the browser login..." -ForegroundColor White
    [void][System.Console]::ReadLine()

    gh auth login --web -p https
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Authentication was not completed. Please try again." -ForegroundColor Red
        exit 1
    }
}

# Fetch GitHub User info
try {
    $userInfo = gh api user | ConvertFrom-Json
    $ghLogin = $userInfo.login
    $ghEmail = $userInfo.email
    Write-Host "`n[AUTHENTICATED] Logged in as: $ghLogin" -ForegroundColor Green
    
    if ($ghEmail) {
        git config user.email $ghEmail
    } else {
        git config user.email "$ghLogin@users.noreply.github.com"
    }
    git config user.name $ghLogin
} catch {
    Write-Host "[INFO] Logged in with GitHub CLI." -ForegroundColor Green
}

# Repository Setup Options
Write-Host "`n[STEP 2/3] Repository Creation" -ForegroundColor Cyan
Write-Host "Choose an option:" -ForegroundColor White
Write-Host "  [1] Automatically create a new repository on your GitHub account (Recommended)" -ForegroundColor White
Write-Host "  [2] Link an existing empty GitHub repository URL" -ForegroundColor White
$choice = Read-Host "Enter option [1 or 2] (Default: 1)"

if ($choice -eq "2") {
    $remoteUrl = Read-Host "Enter your GitHub repository URL (e.g. https://github.com/username/repo.git)"
    if (-not $remoteUrl) {
        Write-Host "[ERROR] No URL provided." -ForegroundColor Red
        exit 1
    }
    git remote remove origin 2>$null
    git remote add origin $remoteUrl
    Write-Host "Pushing commits to $remoteUrl..." -ForegroundColor Cyan
    git push -u origin main
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n[SUCCESS] Project pushed successfully to $remoteUrl!" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to push to $remoteUrl. Check permissions or repository state." -ForegroundColor Red
        exit 1
    }
} else {
    $repoName = Read-Host "Enter repository name (Default: LFSR_BIST_ALU_Vivado)"
    if (-not $repoName) { $repoName = "LFSR_BIST_ALU_Vivado" }

    $visChoice = Read-Host "Visibility: [1] Public (Default) or [2] Private"
    $visibility = if ($visChoice -eq "2") { "--private" } else { "--public" }

    Write-Host "`nCreating GitHub repository '$repoName' and pushing initial commit..." -ForegroundColor Cyan
    gh repo create $repoName $visibility --source=. --remote=origin --push

    if ($LASTEXITCODE -eq 0) {
        $repoUrl = git remote get-url origin 2>$null
        Write-Host "`n===================================================================" -ForegroundColor Green
        Write-Host "[SUCCESS] Repository created and uploaded successfully!" -ForegroundColor Green
        Write-Host "Repository URL: $repoUrl" -ForegroundColor Green
        Write-Host "===================================================================" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to create repository via GitHub CLI." -ForegroundColor Red
        exit 1
    }
}

# Step 3: Launch Auto-Sync
Write-Host "`n[STEP 3/3] Real-Time Auto-Sync Watcher" -ForegroundColor Cyan
Write-Host "Would you like to start the real-time auto-sync watcher now?" -ForegroundColor White
Write-Host "It will stay running in the background and automatically push every change you make." -ForegroundColor Gray
$startSync = Read-Host "Start Auto-Sync now? (Y/n, Default: Y)"
if ($startSync -eq "" -or $startSync -match "^[Yy]") {
    Write-Host "`nStarting Auto-Sync Watcher..." -ForegroundColor Green
    & "$PSScriptRoot\auto_sync_github.ps1"
} else {
    Write-Host "`nYou can start the auto-sync watcher at any time by running:" -ForegroundColor Yellow
    Write-Host "  start_auto_sync.bat" -ForegroundColor White
}
