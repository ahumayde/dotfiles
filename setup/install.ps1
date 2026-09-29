<#
.SYNOPSIS
    Master orchestrator for the Windows/PowerShell dotfiles environment.

.PARAMETER DryRun
    Print what would be done without downloading, installing or modifying anything.

.PARAMETER All
    Non-interactive: answer "yes" to install prompts and back up conflicting configs.
#>

param(
    [switch]$DryRun,
    [switch]$All
)

$SetupDir = $PSScriptRoot
. "$SetupDir\utils.ps1"

# Check the PowerShell version BEFORE elevating, so we don't raise UAC just to fail.
Assert-PowerShell7

# Automatically elevate to Administrator and preserve flags (skipped for -DryRun)
Invoke-RequireAdmin -ScriptPath $PSCommandPath -DryRun:$DryRun -All:$All

Write-Status "Initialising Modular Environment Configuration..."
if ($DryRun) { Write-Status "DryRun mode: no changes will be made." }

# 1. Install Winget packages (including Git)
& "$SetupDir\01-dependencies.ps1" -DryRun:$DryRun -All:$All
if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "Dependency step failed. Aborting."; exit 1 }

# 2. Add newly installed binaries to PATH
& "$SetupDir\02-paths.ps1" -DryRun:$DryRun -All:$All
if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "PATH step failed. Aborting."; exit 1 }

# Refresh the current session's PATH so the next script can actually use 'git'
Update-SessionPath

# 3. Clone or pull the repository using Git
& "$SetupDir\03-bootstrap.ps1" -DryRun:$DryRun -All:$All
if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "Repository bootstrap failed. Aborting before config deployment."; exit 1 }

# 4. Deploy configurations
& "$SetupDir\04-config.ps1" -DryRun:$DryRun -All:$All

if ($DryRun) { Write-Status "Dry run complete. No changes were made." } 
else { Write-Status "Setup Complete! Please restart your terminal for all environment variables to apply globally." }
