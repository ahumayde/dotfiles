<#
.SYNOPSIS
    Undoes the dotfiles setup and reverts your configs to their ORIGINAL (oldest) backups.

.DESCRIPTION
    Every stage asks for confirmation (there is deliberately no -All), and the destructive ones
    default to "No". Stages:
      1. Config files: remove what was deployed and restore the OLDEST '<name>.bak.<timestamp>'
         for each (i.e. the file as it was before the dotfiles ever touched it).
      2. PowerToys: restore the oldest version of each settings file that extraction replaced.
      3. Offer to delete the newer backups left behind.
      4. Remove the managed entries from your User PATH.
      5. Optionally uninstall the winget packages (one prompt each).
      6. Optionally delete the ~/.dotfiles repository.
    Requires administrator rights and elevates itself, except -DryRun.

.PARAMETER DryRun
    Show what would be removed/restored without changing anything or prompting.
#>

param([switch]$DryRun)

$SetupDir = $PSScriptRoot
# Forward the flags: dot-sourcing a script with a param() block otherwise resets them.
. "$SetupDir\install.ps1" -DryRun:$DryRun

# Backups created by install/deploy-configs ("<target>.bak.<yyyyMMddHHmmss>"), OLDEST FIRST.
# The fixed-width timestamp makes a plain name sort chronological.
function Get-TargetBackups {
    param([string]$Target)
    $Parent = Split-Path $Target -Parent
    $Leaf   = Split-Path $Target -Leaf
    if (-not (Test-Path -LiteralPath $Parent)) { return @() }
    return @(Get-ChildItem -LiteralPath $Parent -Filter "$Leaf.bak.*" -Force -ErrorAction SilentlyContinue | Sort-Object Name)
}

# Returns the newer backups left behind (so the caller can offer to delete them).
function Invoke-ConfigRevert {
    param([switch]$DryRun, [object[]]$Mappings = $ConfigMappings)

    $Leftover = @()
    foreach ($Map in $Mappings) {
        Write-Host "Reverting [$($Map.Name)] " -ForegroundColor Magenta -NoNewline

        if ($Map.Type -eq "CopyContents") {
            Write-Host "[Not reverted: merged folders have no backup]" -ForegroundColor Yellow
            continue
        }

        $Existing = $null
        $Existing = Get-Item -LiteralPath $Map.Target -Force -ErrorAction SilentlyContinue
        $Backups  = @(Get-TargetBackups $Map.Target)
        $Oldest   = if ($Backups.Count -gt 0) { $Backups[0] } else { $null }

        if (-not $Existing -and -not $Oldest) {
            Write-Host "[Nothing to do]" -ForegroundColor DarkGray
            continue
        }

        # Is the current file still exactly what we deployed? (Local edits would be lost.)
        $IsOurs = $false
        if ($Existing) { $IsOurs = Test-DeploymentCurrent -Map $Map -Existing $Existing }

        if ($DryRun) {
            Write-Host ""
            if ($Existing) { Write-DryRunNotice "remove $($Map.Target)" }
            if ($Oldest)   { Write-DryRunNotice "restore the oldest backup $($Oldest.Name) to $($Map.Target)" }
            if ($Backups.Count -gt 1) { $Leftover += @($Backups | Select-Object -Skip 1) }
            continue
        }

        # Build the choices to match what is actually possible here.
        $Labels  = @("&Skip")
        $Descs   = @("Leave this alone.")
        $Actions = @("skip")
        if ($Existing -and $Oldest) {
            $Labels += "&Revert";      $Descs += "Remove the current file and restore the oldest backup ($($Oldest.Name))."; $Actions += "revert"
            $Labels += "Remove &only"; $Descs += "Remove the current file; don't restore any backup.";                        $Actions += "remove"
        } elseif ($Existing) {
            $Labels += "&Remove";      $Descs += "Remove the current file (no backup exists to restore).";                    $Actions += "remove"
        } else {
            $Labels += "&Restore";     $Descs += "Restore the oldest backup ($($Oldest.Name)).";                              $Actions += "restore"
        }

        $Lines = @()
        if ($Existing) {
            $State = if ($IsOurs) { "matches what the dotfiles deployed" } else { "differs from the repo copy - local changes would be lost" }
            $Lines += "  Current: $($Map.Target) ($State)"
        } else {
            $Lines += "  Current: $($Map.Target) (missing)"
        }
        if ($Oldest) { $Lines += "  Oldest backup: $($Oldest.Name)  [$($Backups.Count) backup(s) in total]" }

        Write-Host ""
        $Idx    = Confirm-Choice -Title "Revert: $($Map.Name)" -Message ("Revert this config?`n" + ($Lines -join "`n")) -ChoiceLabels $Labels -ChoiceDescriptions $Descs
        $Action = $Actions[$Idx]
        if ($Action -eq "skip") {
            Write-Host "[Skipped] $($Map.Name)" -ForegroundColor Yellow
            continue
        }

        $Ok = $true
        $AppState = $null
        try {
            $AppState = Stop-MappingApps -Map $Map
            if ($Existing -and ($Action -eq "revert" -or $Action -eq "remove")) {
                Remove-DeploymentTarget -Path $Map.Target
            }
            if ($Action -eq "revert" -or $Action -eq "restore") {
                New-Item -ItemType Directory -Force -Path (Split-Path $Map.Target -Parent) | Out-Null
                Move-Item -LiteralPath $Oldest.FullName -Destination $Map.Target -ErrorAction Stop
                if ($Backups.Count -gt 1) { $Leftover += @($Backups | Select-Object -Skip 1) }
            }
        } catch {
            $Ok = $false
            Write-ErrorMsg "Failed to revert $($Map.Name): $_"
        } finally {
            if ($AppState) { Restore-MappingApps -Map $Map -State $AppState }
        }
        if ($Ok) { Write-Host (Format-Highlight "[Reverted $($Map.Name): $Action]" -Style BrightGreen) }
    }
    return @($Leftover)
}

# PowerToys extraction copies each REPLACED file into "PowerToys.dotfiles-backup.<timestamp>".
# Restore the oldest version of every file found in any of those folders. Files the extraction
# newly created (there was no previous version) cannot be identified and are left in place.
function Invoke-PowerToysRevert {
    param([switch]$DryRun)

    $Parent = Split-Path $PowerToysSettingsDir -Parent
    $Leaf   = Split-Path $PowerToysSettingsDir -Leaf
    $Dirs   = @()
    if (Test-Path -LiteralPath $Parent) {
        $Dirs = @(Get-ChildItem -LiteralPath $Parent -Directory -Filter "$Leaf.dotfiles-backup.*" -ErrorAction SilentlyContinue | Sort-Object Name)
    }
    if ($Dirs.Count -eq 0) {
        Write-Host "[No PowerToys backups found]" -ForegroundColor DarkGray
        return @()
    }

    $Seen = @{}
    $Plan = @()
    foreach ($Dir in $Dirs) {   # oldest first, so the first sighting of a file is its oldest version
        foreach ($File in (Get-ChildItem -LiteralPath $Dir.FullName -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            $Rel = $File.FullName.Substring($Dir.FullName.Length).TrimStart([char]'\', [char]'/')
            if (-not $Seen.ContainsKey($Rel.ToLowerInvariant())) {
                $Seen[$Rel.ToLowerInvariant()] = $true
                $Plan += [pscustomobject]@{ Rel = $Rel; From = $File.FullName }
            }
        }
    }

    if ($DryRun) {
        Write-DryRunNotice "restore $($Plan.Count) PowerToys settings file(s) to their oldest backed-up versions (from $($Dirs.Count) backup folder(s)), stopping PowerToys first"
        return @($Dirs)
    }

    $Go = Confirm-Step -Title "Revert: PowerToys" `
        -Message "Restore $($Plan.Count) PowerToys settings file(s) to their original versions, taken from the oldest of $($Dirs.Count) backup folder(s)?`nPowerToys will be closed first. Files the restore created from scratch are left in place." `
        -YesDescription "Restores the original settings files." -NoDescription "Leaves PowerToys settings alone."
    if (-not $Go) {
        Write-Host "[Skipped] PowerToys" -ForegroundColor Yellow
        return @()
    }

    $Running = @(Get-Process -Name "PowerToys*" -ErrorAction SilentlyContinue)
    if ($Running.Count -gt 0) { $Running | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2 }

    $Done = 0
    try {
        foreach ($Item in $Plan) {
            $Dest = Join-Path $PowerToysSettingsDir $Item.Rel
            New-Item -ItemType Directory -Force -Path (Split-Path $Dest -Parent) | Out-Null
            Copy-Item -LiteralPath $Item.From -Destination $Dest -Force -ErrorAction Stop
            $Done++
        }
        Write-Host (Format-Highlight "[Restored $Done PowerToys file(s)]" -Style BrightGreen)
    } catch {
        Write-ErrorMsg "Failed to restore PowerToys settings: $_"
    }
    if ($Running.Count -gt 0) { Write-Host "PowerToys was closed; start it again." -ForegroundColor Cyan }
    return @($Dirs)
}

#############################################################################
### MAIN  (skipped when this file is itself dot-sourced, e.g. by tests)
#############################################################################
if ($MyInvocation.InvocationName -eq ".") { return }

if (-not (Test-PowerShell7)) { return }
if (Invoke-RequireAdmin -ScriptPath $PSCommandPath -DryRun:$DryRun) { return }

Write-Status "Starting Environment Rollback..."
if ($DryRun) { Write-Status "DryRun mode: no changes will be made and nothing will be asked." }

# ---------------------------------------------------------------------------
Write-Status "Stage 1/6: Reverting config files to their oldest backups..."
$Leftover = @()
$Leftover += @(Invoke-ConfigRevert -DryRun:$DryRun)

Write-Status "Stage 2/6: Reverting PowerToys settings..."
$Leftover += @(Invoke-PowerToysRevert -DryRun:$DryRun)

# ---------------------------------------------------------------------------
Write-Status "Stage 3/6: Newer backups..."
$Leftover = @($Leftover | Where-Object { $_ })
if ($Leftover.Count -eq 0) {
    Write-Host "No newer backups left behind." -ForegroundColor DarkGray
} elseif ($DryRun) {
    Write-DryRunNotice "offer to delete $($Leftover.Count) newer backup file(s)/folder(s)"
} elseif (Confirm-Step -DefaultNo -Title "Delete newer backups" `
        -Message "$($Leftover.Count) newer backup file(s)/folder(s) remain (the oldest ones were restored above). Delete them?" `
        -YesDescription "Permanently deletes the newer backups." -NoDescription "Keeps them.") {
    foreach ($Item in $Leftover) {
        try { Remove-Item -LiteralPath $Item.FullName -Recurse -Force -ErrorAction Stop; Write-Host "Deleted $($Item.Name)" -ForegroundColor Green }
        catch { Write-ErrorMsg "Could not delete $($Item.FullName): $_" }
    }
}

# ---------------------------------------------------------------------------
Write-Status "Stage 4/6: Cleaning User Environment Paths..."
$Kept    = @()
$Removed = @()
foreach ($Entry in (Split-PathList (Get-UserPath))) {
    if (Test-PathEntryPresent -Entries $TargetBinPaths -Path $Entry) { $Removed += $Entry } else { $Kept += $Entry }
}
if ($Removed.Count -eq 0) {
    Write-Host "No managed PATH entries found." -ForegroundColor DarkGray
} elseif ($DryRun) {
    foreach ($Entry in $Removed) { Write-DryRunNotice "remove $Entry from User PATH" }
} elseif (Confirm-Step -Title "Clean PATH" -Message "Remove these entries from your User PATH?`n  $($Removed -join "`n  ")") {
    try {
        Set-UserPath ($Kept -join ";")
        foreach ($Entry in $Removed) { Write-Host "Removed $Entry from Environment Variables" -ForegroundColor Green }
    } catch {
        Write-ErrorMsg "Failed to update User PATH: $_"
    }
} else {
    Write-Host "[Skipped] PATH cleanup" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
Write-Status "Stage 5/6: Winget packages..."
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found; skipping package removal." -ForegroundColor Yellow
} else {
    foreach ($Id in $WingetIds) {
        if (-not (Test-WingetPackageInstalled $Id)) { continue }
        if ($DryRun) { Write-DryRunNotice "offer to uninstall winget package '$Id'"; continue }

        # One prompt per package, default No: some of these may have been installed before this setup.
        if (-not (Confirm-Step -DefaultNo -Title "Uninstall $Id" -Message "Uninstall $Id? (It may have been installed before this setup ran.)" `
                -YesDescription "Uninstalls the software." -NoDescription "Leaves it installed.")) {
            Write-Host "[Kept] $Id" -ForegroundColor Yellow
            continue
        }
        Write-Host "Uninstalling [$Id]..." -ForegroundColor Yellow
        winget uninstall --id $Id -e --silent
        if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "Failed to uninstall $Id (winget exit code $LASTEXITCODE)" }
    }
}

# ---------------------------------------------------------------------------
Write-Status "Stage 6/6: Repository..."
if (-not (Test-Path $DotfilesPath)) {
    Write-Host "No repository at $DotfilesPath." -ForegroundColor DarkGray
} elseif ($DryRun) {
    Write-DryRunNotice "offer to delete the repository at $DotfilesPath"
} elseif (Confirm-Step -DefaultNo -Title "Remove Repository" -Message "Completely delete $DotfilesPath? This destroys any uncommitted changes (export-configs.ps1 saves your live settings into it first)." `
        -YesDescription "Deletes the folder." -NoDescription "Preserves the folder.") {
    # Don't sit inside the folder we're about to delete (this script normally lives in it).
    Set-Location $HOME
    try {
        Remove-Item -Path $DotfilesPath -Recurse -Force -ErrorAction Stop
        Write-Host "Deleted $DotfilesPath" -ForegroundColor Green
    } catch {
        Write-ErrorMsg "Failed to delete $($DotfilesPath): $_"
    }
} else {
    Write-Host "[Kept] $DotfilesPath" -ForegroundColor Yellow
}

if ($DryRun) {
    Write-Status "Dry run complete. No changes were made."
} else {
    Write-Status "Rollback complete. Restart your terminal for PATH changes to finalise."
    Write-Host "Not reverted: Windhawk mods (merged, no backup), fonts from the Nerd Font installer, and PowerToys files that didn't exist before." -ForegroundColor DarkGray
}
