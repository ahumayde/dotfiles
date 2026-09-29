<#
.SYNOPSIS
    Appends required binary directories to the User PATH environment variable.
#>

param(
    [switch]$DryRun,
    [switch]$All
)

$SetupDir = $PSScriptRoot
. "$SetupDir\utils.ps1"

Write-Status "Verifying Environment Paths..."

$Entries = @(Split-PathList (Get-UserPath))
$Added   = @()

foreach ($Path in $TargetBinPaths) {
    # Exact, case-insensitive entry match (not a wildcard substring match).
    if (Test-PathEntryPresent -Entries $Entries -Path $Path) {
        Write-Host "Path verified: $Path" -ForegroundColor DarkGray
        continue
    }

    if ($DryRun) {
        Write-DryRunNotice "add $Path to User PATH"
        continue
    }

    $Entries += $Path
    $Added   += $Path
}

if ($Added.Count -gt 0) {
    try {
        Set-UserPath ($Entries -join ";")
        foreach ($Path in $Added) { Write-Host "Added $Path to Environment Variables." -ForegroundColor Green }
    } catch {
        Write-ErrorMsg "Failed to update User PATH: $_"
        exit 1
    }
}

exit 0
