<#
.SYNOPSIS
    Exports the live config/settings files from this system back into the repo (.dotfiles\configs).

.DESCRIPTION
    The reverse of deploy-configs.ps1. For every Copy/CopyContents mapping it compares the system
    copy with the repo copy and, after confirmation, overwrites the REPO copy with the system one.
    Symlinked files (e.g. the PowerShell profile) already live in the repo, and shortcuts are not
    exportable, so those are skipped. PowerToys is exported from its own Backup (.ptb) folder.
    Nothing on the system is modified; review the result with git before committing.

.PARAMETER DryRun
    Show what would be exported without copying anything or prompting.

.PARAMETER All
    Non-interactive: export every changed file without asking.
#>

param(
    [switch]$DryRun,
    [switch]$All
)

$SetupDir = $PSScriptRoot
# Forward the flags: dot-sourcing a script with a param() block otherwise resets them.
. "$SetupDir\install.ps1" -DryRun:$DryRun -All:$All

# Work out what differs. Each entry: From (system), To (repo), plus a label.
function Get-Changes {
    param([string]$From, [string]$To)

    $Changes = @()

    if ($SystemItem.PSIsContainer) {
        foreach ($Rel in (Get-DirChanges -From $From -To $To)) {
            $Changes += [pscustomobject]@{
                From = (Join-Path $From $Rel)
                To   = (Join-Path $To $Rel)
            }
        }
    } else {
        $Differs = $true
        if (Test-Path -LiteralPath $To) {
            if (Get-Command git -ErrorAction SilentlyContinue) {
                # --quiet returns exit code 1 if differences exist, 0 if identical
                git diff --no-index --quiet $To $From 2>$null
                $Differs = ($LASTEXITCODE -ne 0)
            } else {
                try {
                    $SysHash = (Get-FileHash -LiteralPath $From -ErrorAction Stop).Hash
                    $RepoHash = (Get-FileHash -LiteralPath $To -ErrorAction Stop).Hash
                    $Differs = ($SysHash -ne $RepoHash)
                } catch {
                    $Differs = $true
                }
            }
        }

        if ($Differs) {
            $Changes += [pscustomobject]@{
                From = $From
                To   = $To
            }
        }
    }

    return $Changes
}

# Files in $From that are new or different compared with $To (relative paths).
function Get-DirChanges {
    param([string]$From, [string]$To)

    $Changes = @()
    $HasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)

    foreach ($File in (Get-ChildItem -LiteralPath $From -Recurse -File -Force -ErrorAction SilentlyContinue)) {
        $Rel = $File.FullName.Substring($From.TrimEnd([char]'\', [char]'/').Length).TrimStart([char]'\', [char]'/')
        $Peer = Join-Path $To $Rel

        if (-not (Test-Path -LiteralPath $Peer)) {
            $Changes += $Rel
            continue
        }

        $Differs = $false
        if ($HasGit) {
            git diff --no-index --quiet $Peer $File.FullName 2>$null
            $Differs = ($LASTEXITCODE -ne 0)
        } else {
            $SysHash = (Get-FileHash -LiteralPath $File.FullName).Hash
            $PeerHash = (Get-FileHash -LiteralPath $Peer).Hash
            $Differs = ($SysHash -ne $PeerHash)
        }

        if ($Differs) {
            $Changes += $Rel
        }
    }

    return $Changes
}

function Invoke-ConfigExport {
    param(
        [switch]$DryRun,
        [switch]$All,
        [object[]]$Mappings = $ConfigMappings
    )

    foreach ($Map in $Mappings) {
        Write-Host "Exporting [$($Map.Name)] " -ForegroundColor Magenta -NoNewline
        $SystemItem = Get-Item -LiteralPath $Map.Target -Force -ErrorAction SilentlyContinue

        # Checks for Symbolic Link Targets
        if ($Map.Type -eq "Symlink") {
            if ($null -ne $SystemItem -and $SystemItem.LinkType -eq 'SymbolicLink') {
                # Safe array coercion handles both PS5.1 and PS7 gracefully
                $RawTarget = [string]@($SystemItem.Target)[0]
                $ResolvedSysTarget = [System.IO.Path]::GetFullPath($RawTarget)
                $ResolvedRepoTarget = [System.IO.Path]::GetFullPath($Map.Source)

                if ($ResolvedSysTarget -ieq $ResolvedRepoTarget) {
                    Write-Host "[Skipped: Symlink intact] " -ForegroundColor DarkGray
                } else {
                    Write-Host "[Warning: Symlink points elsewhere ($RawTarget)]" -ForegroundColor Yellow
                }
            } else {
                Write-Host "[Warning: Not a Symlink or does not exist] ($($Map.Target))" -ForegroundColor Yellow
            }
            continue
        }

        # Checks For Shortcut Targets
        if ($Map.Type -eq "Shortcut") {
            Write-Host "[Skipped: Nothing to export] " -ForegroundColor DarkGray
            continue
        }

        # Checks if Target exists
        if (-not (Test-Path -LiteralPath $Map.Target)) {
            Write-Host "[Warning: Not found on this system] ($(Map.Target))" -ForegroundColor Yellow
            continue
        }

        # Checks if Target is a link
        if ($SystemItem.LinkType) {
            Write-Host "[Skipped: system path is a link ($(Map.Target))] " -ForegroundColor DarkGray
            continue
        }

        $Changes = Get-Changes -From $Map.Target -To $Map.Source
        if ($Changes.Count -eq 0) {
            Write-Host "[Already up to date]" -ForegroundColor Green
            continue
        }

        if ($DryRun) {
            Write-DryRunNotice "export $($Changes.Count) changed file(s) from $($Map.Target) to $($Map.Source)"
            continue
        }

        # Show the user what they're about to overwrite, then ask (default: Skip).
        if ($Changes.Count -eq 1) {
            $SysTime  = (Get-Item -LiteralPath $Changes[0].From).LastWriteTime
            $RepoItem = Get-Item -LiteralPath $Changes[0].To -ErrorAction SilentlyContinue
            $RepoInfo = if ($RepoItem) { "modified $($RepoItem.LastWriteTime)" } else { "does not exist yet" }

            $DiffText = ""
            if ($RepoItem -and (Get-Command git -ErrorAction SilentlyContinue)) {
                $Stat = git diff --no-index --shortstat $Changes[0].To $Changes[0].From 2>$null
                if ($Stat) { $DiffText = "`n  Diff:   $($Stat.Trim())" }
            } elseif (-not $RepoItem) {
                $DiffText = "`n  Diff:   New file (all lines added)"
            }
            $Detail = "  System: $($Changes[0].From) (modified $SysTime)`n  Repo:   $($Changes[0].To) ($RepoInfo)$DiffText"
        } else {
            $Detail = "  $($Changes.Count) new/changed files in $($Map.Target)"
        }

        $Choice = $null
        if ($All) { $Choice = 1 }
        else {
            do {
                $Choice = Confirm-Choice `
                    -Title "Export: $($Map.Name)" `
                    -Message "The system copy differs from the repo copy:`n$Detail`nOverwrite the repo copy with the system version?" `
                    -ChoiceLabels @("&Skip", "&Export", "&View diff") `
                    -ChoiceDescriptions @("Leave the repo copy untouched.", "Copy the system version into the repo.", "Show the line-by-line differences using git.")

                if ($Choice -eq 2) {
                    Write-Host "`n--- DIFF START: $($Map.Name) ---" -ForegroundColor Cyan
                    foreach ($Change in $Changes) {
                        if (Test-Path -LiteralPath $Change.To) {
                            # Force colour output for better readability in the terminal
                            git diff --no-index --color=always $Change.To $Change.From
                        } else {
                            Write-Host "+ New File: $($Change.From) (Does not exist in repo yet)" -ForegroundColor Green
                        }
                    }
                    Write-Host "--- DIFF END ---`n" -ForegroundColor Cyan
                }
            } while ($Choice -eq 2) # Loop back to the prompt if they chose to view the diff
        }

        if ($Choice -eq 0) {
            Write-Host "[Skipped: $($Map.Name)]" -ForegroundColor Yellow
            continue
        }

        try {
            foreach ($Change in $Changes) {
                New-Item -ItemType Directory -Force -Path (Split-Path $Change.To -Parent) | Out-Null
                Copy-Item -LiteralPath $Change.From -Destination $Change.To -Force -ErrorAction Stop
            }
            Write-Host (Format-Highlight "[Exported $($Changes.Count) file(s)]" -Style BrightGreen)
        } catch {
            Write-ErrorMsg "Failed to export $($Map.Name) ($($Map.Target)):$_"
        }
    }
}

# PowerToys can only reliably produce a backup itself (Settings > General > Backup & restore >
# Backup). This picks up its newest .ptb and stores it in the repo in place of the old one.
function Invoke-PowerToysExport {
    param(
        [switch]$DryRun,
        [switch]$All
    )

    $Latest = Get-LatestPtb $PowerToysBackupDir
    if (-not $Latest) {
        Write-Host "No .ptb backup found in $PowerToysBackupDir." -ForegroundColor Yellow
        Write-Host "In PowerToys open Settings > General > Backup & restore > Backup, then run this again." -ForegroundColor Cyan
        return
    }

    $InRepo = Get-LatestPtb $PowerToysSourceDir
    if ($InRepo) {
        $SysHash = (Get-FileHash -LiteralPath $InRepo.FullName).Hash
        $RepoHash = (Get-FileHash -LiteralPath $Latest.FullName).Hash
        if ($SysHash -eq $RepoHash) {
            Write-Host "[Already up to date]" -ForegroundColor Green
            return
        }
    }

    if ($DryRun) {
        Write-DryRunNotice "copy $($Latest.FullName) into $PowerToysSourceDir, replacing any existing .ptb there"
        return
    }

    $RepoInfo = if ($InRepo) { "$($InRepo.Name) ($($InRepo.LastWriteTime))" } else { "none" }

    $Proceed = $All -or (Confirm-Step `
        -Title "Export: PowerToys" `
        -Message "Newest PowerToys backup: $($Latest.Name) ($($Latest.LastWriteTime)).`nRepo currently has: $RepoInfo.`nThis backup is only as fresh as your last click on 'Backup' in PowerToys. Replace the repo's backup with it?" `
        -YesDescription "Replaces the .ptb in the repo." `
        -NoDescription "Leaves the repo's .ptb untouched.")

    if (-not $Proceed) {
        Write-Host "[Skipped] PowerToys" -ForegroundColor Yellow
        return
    }

    try {
        New-Item -ItemType Directory -Force -Path $PowerToysSourceDir | Out-Null
        Get-ChildItem -LiteralPath $PowerToysSourceDir -Filter "*.ptb" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction Stop
        Copy-Item -LiteralPath $Latest.FullName -Destination $PowerToysSourceDir -Force -ErrorAction Stop
        Write-Host (Format-Highlight "[Exported $($Latest.Name)]" -Style BrightGreen)
    } catch {
        Write-ErrorMsg "Failed to export the PowerToys backup: $_"
    }
}

#############################################################################
### MAIN  (skipped when this file is itself dot-sourced, e.g. by tests)
#############################################################################
if ($MyInvocation.InvocationName -eq ".") { return }

if (-not (Test-PowerShell7)) { return }

if (-not (Test-Path (Join-Path $DotfilesPath ".git"))) {
    Write-ErrorMsg "No dotfiles repository found at $DotfilesPath. Run install.ps1 first."
    return
}

Write-Status "Exporting system configuration into $ConfigDir ..."
if ($DryRun) {
    Write-Status "DryRun mode: nothing will be copied."
}

Invoke-ConfigExport -DryRun:$DryRun -All:$All

Write-Host "Exporting [PowerToys Settings] " -ForegroundColor Magenta -NoNewline
Invoke-PowerToysExport -DryRun:$DryRun -All:$All

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Status "Repository changes (review, then commit):"
    git -C $DotfilesPath status --short
}

if ($DryRun) {
    Write-Status "Dry run complete. No changes were made."
}
