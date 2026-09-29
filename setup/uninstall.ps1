<#
.SYNOPSIS
    Safely uninstalls and rolls back the dotfiles environment.

.PARAMETER DryRun
    Print what would be removed without changing anything (no prompts, no elevation).
#>

param([switch]$DryRun)

$SetupDir = $PSScriptRoot
. "$SetupDir\utils.ps1"

Assert-PowerShell7

# Automatically elevate to Administrator and preserve flags (skipped for -DryRun)
Invoke-RequireAdmin -ScriptPath $PSCommandPath -DryRun:$DryRun

Write-Status "Starting Environment Rollback..."
if ($DryRun) { Write-Status "DryRun mode: no changes will be made." }

# ---------------------------------------------------------------------------
# 1. Remove configs (and restore the newest backup made by 04-config.ps1, if any)
# ---------------------------------------------------------------------------
Write-Status "Removing Configuration Links and Files..."

# Mirrors the mappings in 04-config.ps1 (Neovim is commented out there, so it is not touched here).
$ConfigTargets = @(
    $PowerShellProfilePath,
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:APPDATA\Code\User\settings.json",
    "$env:LOCALAPPDATA\Microsoft\PowerToys\settings.json",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\startup_ahk.lnk"
)

if ($DryRun -or (Confirm-Step -Title "Remove Configs" -Message "Remove the deployed config files/links (your terminal, VS Code and PowerToys settings)? The most recent backup of each will be restored if one exists.")) {
    foreach ($Target in $ConfigTargets) {
        $Existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
        $Parent   = Split-Path $Target -Parent
        $Leaf     = Split-Path $Target -Leaf
        $Backups  = @()
        if (Test-Path -LiteralPath $Parent) {
            $Backups = @(Get-ChildItem -LiteralPath $Parent -Filter "$Leaf.bak.*" -Force -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
        }

        if ($Existing) {
            if ($DryRun) {
                Write-DryRunNotice "remove $Target"
            } else {
                try {
                    Remove-DeploymentTarget -Path $Target
                    Write-Host "Removed $Target" -ForegroundColor Green
                } catch {
                    Write-ErrorMsg "Failed to remove $($Target): $_"
                    continue
                }
            }
        }

        if ($Backups.Count -gt 0) {
            if ($DryRun) {
                Write-DryRunNotice "restore $($Backups[0].FullName) to $Target"
            } else {
                try {
                    Move-Item -LiteralPath $Backups[0].FullName -Destination $Target -ErrorAction Stop
                    Write-Host "Restored backup to $Target" -ForegroundColor Green
                } catch {
                    Write-ErrorMsg "Failed to restore backup for $($Target): $_"
                }
            }
        }
    }
} else {
    Write-Host "[Skipped] Config removal" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 2. Clean environment paths
# ---------------------------------------------------------------------------
Write-Status "Cleaning User Environment Paths..."

$Kept    = @()
$Removed = @()
foreach ($Entry in (Split-PathList (Get-UserPath))) {
    if (Test-PathEntryPresent -Entries $TargetBinPaths -Path $Entry) { $Removed += $Entry } else { $Kept += $Entry }
}

if ($Removed.Count -eq 0) {
    Write-Host "No managed PATH entries found." -ForegroundColor DarkGray
} elseif ($DryRun) {
    foreach ($Entry in $Removed) { Write-DryRunNotice "remove $Entry from User PATH" }
} else {
    try {
        Set-UserPath ($Kept -join ";")
        foreach ($Entry in $Removed) { Write-Host "Removed $Entry from Environment Variables" -ForegroundColor Green }
    } catch {
        Write-ErrorMsg "Failed to update User PATH: $_"
    }
}

# ---------------------------------------------------------------------------
# 3. Uninstall winget packages
# ---------------------------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found; skipping package removal." -ForegroundColor Yellow
} elseif ($DryRun -or (Confirm-Step -Title "Uninstall Packages" -Message "Uninstall all winget packages installed by this setup? (Git, Neovim, PowerToys, etc.)" -YesDescription "Uninstalls software." -NoDescription "Leaves software intact.")) {
    foreach ($Id in $WingetIds) {
        if (-not (Test-WingetPackageInstalled $Id)) { continue }
        if ($DryRun) { Write-DryRunNotice "uninstall winget package '$Id'"; continue }

        Write-Host "Uninstalling [$Id]..." -ForegroundColor Yellow
        winget uninstall --id $Id -e --silent
        if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "Failed to uninstall $Id (winget exit code $LASTEXITCODE)" }
    }
}

# ---------------------------------------------------------------------------
# 4. Remove repository
# ---------------------------------------------------------------------------
if (Test-Path $DotfilesPath) {
    if ($DryRun) {
        Write-DryRunNotice "delete repository at $DotfilesPath"
    } elseif (Confirm-Step -Title "Remove Repository" -Message "Completely delete the $DotfilesPath directory? This destroys uncommitted changes." -YesDescription "Deletes the folder." -NoDescription "Preserves the folder.") {
        # Don't sit inside the folder we're about to delete.
        Set-Location $HOME
        try {
            Remove-Item -Path $DotfilesPath -Recurse -Force -ErrorAction Stop
            Write-Host "Deleted $DotfilesPath" -ForegroundColor Green
        } catch {
            Write-ErrorMsg "Failed to delete $($DotfilesPath): $_"
        }
    }
}

if ($DryRun) {
    Write-Status "Dry run complete. No changes were made."
} else {
    Write-Status "Rollback Complete. Restart your terminal for PATH changes to finalise."
}
