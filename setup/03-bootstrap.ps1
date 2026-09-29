<#
.SYNOPSIS
    Bootstraps the dotfiles repository (clone, or pull if it already exists).
#>

param(
    [switch]$DryRun,
    [switch]$All
)

$SetupDir = $PSScriptRoot
. "$SetupDir\utils.ps1"

Write-Status "Checking repository status..."

if (-not $DryRun -and -not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "git was not found on PATH. Install Git.Git (step 1) and re-run."
    exit 1
}

if (-not (Test-Path $DotfilesPath)) {
    if ($DryRun) {
        Write-DryRunNotice "clone $DotfilesRepo (branch: $DotfilesBranch) to $DotfilesPath"
    } else {
        Write-Host "Cloning repository..." -ForegroundColor Yellow
        git clone -b $DotfilesBranch $DotfilesRepo $DotfilesPath
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "git clone failed (exit code $LASTEXITCODE)"
            exit 1
        }
    }
} elseif (Test-Path (Join-Path $DotfilesPath ".git")) {
    if ($DryRun) {
        Write-DryRunNotice "pull latest changes for $DotfilesPath"
    } else {
        Write-Host "Pulling latest changes from repository..." -ForegroundColor Yellow
        # -C avoids Set-Location, which would change the caller's working directory.
        git -C $DotfilesPath pull --ff-only origin $DotfilesBranch
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "git pull failed (exit code $LASTEXITCODE). Continuing with the existing checkout."
        }
    }
} else {
    Write-ErrorMsg "$DotfilesPath exists but is not a git repository. Move or delete it and re-run."
    exit 1
}

exit 0
