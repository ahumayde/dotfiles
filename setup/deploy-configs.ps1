<#
.SYNOPSIS
    Deploys the config/settings files from the repo (.dotfiles\configs) onto this system.

.DESCRIPTION
    Re-applies everything install.ps1 deploys (symlinks, copies, Windhawk, Command Palette, the
    AutoHotkey startup shortcut and PowerToys) without touching packages, PATH or the repo.
    Existing files that differ are handled per item: Skip / Backup & Replace / Delete & Replace.
    Requires administrator rights (Windhawk lives in ProgramData) and elevates itself, except -DryRun.

.PARAMETER DryRun
    Show what would be deployed without changing anything or prompting.

.PARAMETER All
    Non-interactive: back up (never delete) conflicting files and extract the PowerToys backup.
#>

param(
    [switch]$DryRun,
    [switch]$All
)

$SetupDir = $PSScriptRoot
# Forward the flags: dot-sourcing a script with a param() block otherwise resets them.
. "$SetupDir\install.ps1" -DryRun:$DryRun -All:$All

if (-not (Test-PowerShell7)) { return }

if (-not (Test-Path $ConfigDir)) {
    Write-ErrorMsg "Config folder not found: $ConfigDir. Run install.ps1 first (or pull the repo)."
    return
}

if (Invoke-RequireAdmin -ScriptPath $PSCommandPath -DryRun:$DryRun -All:$All) { return }

Write-Status "Deploying configuration from $ConfigDir ..."
if ($DryRun) { Write-Status "DryRun mode: no changes will be made." }

Invoke-ConfigDeployment -DryRun:$DryRun -All:$All

Write-Status "Configuring PowerToys settings..."
Invoke-PowerToysDeployment -DryRun:$DryRun -All:$All

if ($DryRun) { Write-Status "Dry run complete. No changes were made." }
else { Write-Status "Configuration deployed. Some apps may need a restart to pick up the new settings." }
