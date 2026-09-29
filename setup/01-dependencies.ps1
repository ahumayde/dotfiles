<#
.SYNOPSIS
    Installs the required winget packages and the Python provider for Neovim.
#>

param([switch]$DryRun, [switch]$All)

$SetupDir = $PSScriptRoot
. "$SetupDir\utils.ps1"

Write-Status "Checking Winget Packages..."

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "winget was not found. Install 'App Installer' from the Microsoft Store and re-run."
    exit 1
}

$Failed = @()

foreach ($Id in $WingetIds) {
    Write-Host "Processing: [$Id]" -ForegroundColor Magenta -NoNewline

    if (Test-WingetPackageInstalled $Id) {
        Write-Host " [Already Installed]" -ForegroundColor Green
        continue
    }
    Write-Host " [Not Installed]" -ForegroundColor Yellow

    # Check DryRun BEFORE prompting so a dry run never asks questions.
    if ($DryRun) {
        Write-DryRunNotice "install winget package '$Id'"
        continue
    }

    if (-not $All -and -not (Confirm-Step -Title "Install $Id" -Message "Install this package?")) {
        Write-Host "[Skipped] $Id" -ForegroundColor Yellow
        continue
    }

    Write-Host "Installing $Id..." -ForegroundColor Yellow
    winget install --id $Id -e --accept-package-agreements --accept-source-agreements --silent
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[$Id Installed]" -ForegroundColor Green
    } else {
        Write-ErrorMsg "Failed to install $Id (winget exit code $LASTEXITCODE)"
        $Failed += $Id
    }
}

if ($Failed.Count -gt 0) {
    Write-ErrorMsg "These packages failed to install: $($Failed -join ', ')"
}

# Freshly installed tools (e.g. Python) aren't on this session's PATH yet.
Update-SessionPath

if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Status "Setting up Python Provider for Neovim..."
    if ($DryRun) {
        Write-DryRunNotice "upgrade pip and install pynvim"
    } else {
        python -m pip install --upgrade pip --quiet
        if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "pip upgrade failed (exit code $LASTEXITCODE)" }
        python -m pip install pynvim --quiet
        if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "pynvim install failed (exit code $LASTEXITCODE)" }
    }
} elseif ($DryRun) {
    Write-DryRunNotice "upgrade pip and install pynvim (once Python is installed)"
} else {
    Write-Host "Python not found on PATH; skipping pynvim setup." -ForegroundColor Yellow
}

exit 0
