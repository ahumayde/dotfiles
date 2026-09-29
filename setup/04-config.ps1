<#
.SYNOPSIS
    Installs Nerd Fonts and deploys configuration files (symlinks/copies/shortcuts).
#>

param([switch]$DryRun, [switch]$All)

$SetupDir = $PSScriptRoot
. "$SetupDir\utils.ps1"

# ---------------------------------------------------------------------------
# Nerd Fonts  (the installer lives in $ScriptsDir, NOT config\bin)
# ---------------------------------------------------------------------------
Write-Status "Configuring Nerd Fonts..."

$NerdFontScriptPath = Join-Path $ScriptsDir "Invoke-NerdFontInstaller.ps1"
$NerdFontScriptUrl  = "https://raw.githubusercontent.com/jpawlowski/nerd-fonts-installer-PS/master/Invoke-NerdFontInstaller.ps1"

# Ask first, so we never download something the user declined. A dry run never prompts.
if ($DryRun -or $All -or (Confirm-Step -Title "NerdFonts" -Message "Download (if needed) and run the Nerd Font installer now?")) {
    if (-not (Test-Path $NerdFontScriptPath)) {
        if ($DryRun) {
            Write-DryRunNotice "download Nerd Font installer to $NerdFontScriptPath"
        } else {
            try {
                New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
                Invoke-WebRequest -Uri $NerdFontScriptUrl -OutFile $NerdFontScriptPath -ErrorAction Stop
            } catch {
                Write-ErrorMsg "Failed to download Nerd Font installer: $_"
                if (Test-Path $NerdFontScriptPath) { Remove-Item $NerdFontScriptPath -Force -ErrorAction SilentlyContinue }
            }
        }
    }

    if ($DryRun) {
        Write-DryRunNotice "execute $NerdFontScriptPath -Scope AllUsers"
    } elseif (Test-Path $NerdFontScriptPath) {
        try { & $NerdFontScriptPath -Scope AllUsers }
        catch { Write-ErrorMsg "Nerd Font installer failed: $_" }
    }
} else {
    Write-Host "[Skipped] Nerd Fonts" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Configuration files
# ---------------------------------------------------------------------------
Write-Status "Synchronising Configuration Files..."

# Types: Symlink | Copy (file or folder) | CopyContents (merge folder contents into Target) | Shortcut
$ConfigMappings = @(
    @{ Name = "PowerShell Profile"; Source = "$ConfigDir\terminal\profile.ps1"; Target = $PowerShellProfilePath; Type = "Symlink" },
    @{ Name = "Windows Terminal"; Source = "$ConfigDir\terminal\settings.json"; Target = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"; Type = "Copy" },
    @{ Name = "VSCode Settings"; Source = "$ConfigDir\vscode\settings.json"; Target = "$env:APPDATA\Code\User\settings.json"; Type = "Copy" },
    @{ Name = "AutoHotkey Startup"; Source = "$ConfigDir\autohotkey\startup_ahk.exe"; Target = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\startup_ahk.lnk"; Type = "Shortcut" },
    @{ Name = "Windhawk Mods"; Source = "$ConfigDir\windhawk\mods"; Target = "$env:ProgramData\Windhawk\Engine\Mods"; Type = "CopyContents"; Service = "Windhawk" },
    @{ Name = "Windhawk Settings"; Source = "$ConfigDir\windhawk\userprofile.json"; Target = "$env:ProgramData\Windhawk\Engine\userprofile.json"; Type = "Copy"; Service = "Windhawk" }
    # Neovim is handled within the powershell user profile
    # PowerToys is handled separately below (its settings are many files, shipped as a .ptb backup).
)

function Get-MappingDescription {
    param($Map)
    switch ($Map.Type) {
        "Symlink"      { return "create symlink $($Map.Target) -> $($Map.Source)" }
        "Copy"         { return "copy $($Map.Source) to $($Map.Target)" }
        "CopyContents" { return "copy the contents of $($Map.Source) into $($Map.Target)" }
        "Shortcut"     { return "create shortcut $($Map.Target) pointing to $($Map.Source)" }
        default        { return "deploy $($Map.Source) to $($Map.Target) ($($Map.Type))" }
    }
}

# True when the existing target already matches what we would deploy (makes re-runs quiet).
function Test-DeploymentCurrent {
    param($Map, $Existing)
    switch ($Map.Type) {
        "Symlink" {
            return ($Existing.LinkType -eq "SymbolicLink" -and ([string]@($Existing.Target)[0]) -ieq $Map.Source)
        }
        "Copy" {
            $Src = Get-Item -LiteralPath $Map.Source -Force -ErrorAction SilentlyContinue
            if (-not $Src -or $Src.PSIsContainer -or $Existing.PSIsContainer) { return $false }
            return ((Get-FileHash -LiteralPath $Map.Source).Hash -eq (Get-FileHash -LiteralPath $Map.Target).Hash)
        }
        "Shortcut" {
            $Lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($Map.Target)
            return ($Lnk.TargetPath -ieq $Map.Source)
        }
        default { return $false }
    }
}

foreach ($Map in $ConfigMappings) {
    Write-Host "Deploying [$($Map.Name)] " -ForegroundColor Magenta -NoNewline

    # DryRun: report and move on. Nothing below this block runs in a dry run.
    if ($DryRun) {
        Write-Host ""
        Write-DryRunNotice (Get-MappingDescription $Map)
        if ($Map.Service) { Write-DryRunNotice "stop and restart service: $($Map.Service)" }
        continue
    }

    if (-not (Test-Path -LiteralPath $Map.Source)) {
        Write-Host ""
        Write-ErrorMsg "Source not found, skipping: $($Map.Source)"
        continue
    }

    try {
        $TargetDir = if ($Map.Type -eq "CopyContents") { $Map.Target } else { Split-Path $Map.Target -Parent }
        if (-not (Test-Path -LiteralPath $TargetDir)) { New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null }
    } catch {
        Write-Host ""
        Write-ErrorMsg "Could not create $TargetDir : $_"
        continue
    }

    # CopyContents merges into an existing folder, so it never needs conflict handling.
    if ($Map.Type -ne "CopyContents") {
        # -Force so broken symlinks are still found.
        $Existing = Get-Item -LiteralPath $Map.Target -Force -ErrorAction SilentlyContinue
        if ($Existing) {
            if (Test-DeploymentCurrent -Map $Map -Existing $Existing) {
                Write-Host "[Already up to date]" -ForegroundColor DarkGray
                continue
            }

            # 0 = Skip, 1 = Backup & Replace, 2 = Delete & Replace.  -All never deletes: it backs up.
            $Choice = if ($All) { 1 } else {
                Write-Host ""
                Confirm-Choice -Title "Conflict: $(Format-Highlight $Map.Target -Style BrightBlue)" -Message "Handle existing $($Map.Name) config?" -ChoiceLabels @("&Skip", "&Backup & Replace", "&Delete & Replace")
            }

            # NB: 'continue' must not be used inside a 'switch' here - it would only leave the switch.
            if ($Choice -eq 0) {
                Write-Host "[Skipped]" -ForegroundColor Yellow
                continue
            }

            try {
                if ($Choice -eq 1) {
                    $Backup = "$($Map.Target).bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
                    # Move-Item takes a full path; Rename-Item -NewName does not.
                    Move-Item -LiteralPath $Map.Target -Destination $Backup -Force -ErrorAction Stop
                } else {
                    Remove-DeploymentTarget -Path $Map.Target
                }
            } catch {
                Write-ErrorMsg "Could not clear existing $($Map.Name) target: $_"
                continue
            }
        }
    }

    $Ok = $true
    $ServiceStopped = $false
    try {
        if ($Map.Service) {
            $Svc = Get-Service -Name $Map.Service -ErrorAction SilentlyContinue
            if ($Svc -and $Svc.Status -eq "Running") {
                Stop-Service -Name $Map.Service -ErrorAction Stop
                $ServiceStopped = $true
                Start-Sleep -Seconds 1
            }
        }

        switch ($Map.Type) {
            "Symlink"      { New-Item -ItemType SymbolicLink -Path $Map.Target -Target $Map.Source -Force -ErrorAction Stop | Out-Null }
            "Copy"         { Copy-Item -LiteralPath $Map.Source -Destination $Map.Target -Recurse -Force -ErrorAction Stop }
            "CopyContents" { Copy-Item -Path (Join-Path $Map.Source "*") -Destination $Map.Target -Recurse -Force -ErrorAction Stop }
            "Shortcut" {
                $WshShell = New-Object -ComObject WScript.Shell
                $Shortcut = $WshShell.CreateShortcut($Map.Target)
                $Shortcut.TargetPath = $Map.Source
                $Shortcut.WorkingDirectory = Split-Path $Map.Source -Parent
                $Shortcut.Save()
            }
            default { throw "Unknown mapping type '$($Map.Type)'" }
        }
    } catch {
        $Ok = $false
        Write-Host ""
        Write-ErrorMsg "Failed to configure $($Map.Name): $_"
    } finally {
        # Always bring the service back, even if the copy failed.
        if ($ServiceStopped) {
            try { Start-Service -Name $Map.Service -ErrorAction Stop }
            catch { Write-ErrorMsg "Failed to restart service $($Map.Service): $_" }
        }
    }

    if ($Ok) { Write-Host (Format-Highlight "[Successfully Configured]" -Style BrightGreen) }
}

# ---------------------------------------------------------------------------
# PowerToys settings
# PowerToys spreads its settings over many JSON files (one folder per module), so the repo
# ships a .ptb backup (created via PowerToys > General > Backup & restore > Backup) in
# config\powertoys\. A .ptb is just a zip archive of those JSON files.
# ---------------------------------------------------------------------------
Write-Status "Configuring PowerToys settings..."

function Get-LatestPtb {
    param([string]$Dir)
    if (-not (Test-Path -LiteralPath $Dir)) { return $null }
    return Get-ChildItem -LiteralPath $Dir -Filter "*.ptb" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime, Name -Descending | Select-Object -First 1
}

# Extracts the backup over the PowerToys settings folder. Existing files that differ are
# copied to "<SettingsDir>.dotfiles-backup.<timestamp>" first; identical files are left alone.
function Expand-PowerToysBackup {
    param([string]$Ptb, [string]$SettingsDir)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $Temp       = Join-Path ([IO.Path]::GetTempPath()) "ptb-$([guid]::NewGuid().ToString('N'))"
    $BackupRoot = "$SettingsDir.dotfiles-backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    $Result     = [pscustomobject]@{ Copied = 0; Unchanged = 0; BackedUp = 0; BackupRoot = $BackupRoot }

    try {
        # Expand-Archive refuses a .ptb extension, so use the .NET API directly.
        [IO.Compression.ZipFile]::ExtractToDirectory($Ptb, $Temp)
        $Files = @(Get-ChildItem -LiteralPath $Temp -Recurse -File -Force)
        if (-not ($Files | Where-Object { $_.Extension -ieq ".json" })) {
            throw "The archive contains no .json settings files, so it doesn't look like a PowerToys backup."
        }

        foreach ($File in $Files) {
            $Rel  = $File.FullName.Substring($Temp.Length).TrimStart([char]'\', [char]'/')
            $Dest = Join-Path $SettingsDir $Rel

            if (Test-Path -LiteralPath $Dest) {
                if ((Get-FileHash -LiteralPath $File.FullName).Hash -eq (Get-FileHash -LiteralPath $Dest).Hash) {
                    $Result.Unchanged++
                    continue
                }
                $BackupPath = Join-Path $BackupRoot $Rel
                New-Item -ItemType Directory -Force -Path (Split-Path $BackupPath -Parent) | Out-Null
                Copy-Item -LiteralPath $Dest -Destination $BackupPath -Force
                $Result.BackedUp++
            }

            New-Item -ItemType Directory -Force -Path (Split-Path $Dest -Parent) | Out-Null
            Copy-Item -LiteralPath $File.FullName -Destination $Dest -Force
            $Result.Copied++
        }
    } finally {
        Remove-Item -LiteralPath $Temp -Recurse -Force -ErrorAction SilentlyContinue
    }
    return $Result
}

$PowerToysSourceDir   = Join-Path $ConfigDir "powertoys"
$PowerToysSettingsDir = Join-Path $env:LOCALAPPDATA "Microsoft\PowerToys"
$PowerToysBackupDir   = Join-Path $DocumentsDir "PowerToys\Backup"
$Ptb = Get-LatestPtb $PowerToysSourceDir

if ($DryRun) {
    if ($Ptb) {
        Write-DryRunNotice "ask how to apply $($Ptb.Name): copy it to $PowerToysBackupDir for a manual Restore in PowerToys, or extract it into $PowerToysSettingsDir (stopping PowerToys first)"
    } else {
        Write-DryRunNotice "look for a .ptb backup in $PowerToysSourceDir (none found or repo not cloned yet)"
    }
} elseif (-not $Ptb) {
    Write-Host "No .ptb backup found in $PowerToysSourceDir; skipping PowerToys settings." -ForegroundColor Yellow
} else {
    # 0 = Skip, 1 = Manual restore, 2 = Extract now.  -All is non-interactive, so it extracts.
    $Choice = if ($All) { 2 } else {
        Confirm-Choice -Title "PowerToys settings" -Message "How should '$($Ptb.Name)' be applied?" `
            -ChoiceLabels @("&Skip", "&Manual restore", "&Extract now") `
            -ChoiceDescriptions @(
                "Leave PowerToys settings alone.",
                "Copies the backup to $PowerToysBackupDir; you then click Restore in PowerToys.",
                "Stops PowerToys and extracts the backup into $PowerToysSettingsDir (differing files are backed up first)."
            )
    }

    if ($Choice -eq 0) {
        Write-Host "[Skipped] PowerToys settings" -ForegroundColor Yellow
    } elseif ($Choice -eq 1) {
        try {
            New-Item -ItemType Directory -Force -Path $PowerToysBackupDir | Out-Null
            Copy-Item -LiteralPath $Ptb.FullName -Destination $PowerToysBackupDir -Force -ErrorAction Stop
            Write-Host "Copied $($Ptb.Name) to $PowerToysBackupDir" -ForegroundColor Green
            Write-Host "Now open PowerToys > Settings > General > Backup & restore > Restore." -ForegroundColor Cyan
            Write-Host "(If you've set a custom backup location in PowerToys, restore from that folder instead.)" -ForegroundColor DarkGray
        } catch {
            Write-ErrorMsg "Failed to copy PowerToys backup: $_"
        }
    } else {
        $Running = @(Get-Process -Name "PowerToys*" -ErrorAction SilentlyContinue)
        if ($Running.Count -gt 0) {
            Write-Host "Stopping PowerToys..." -ForegroundColor Yellow
            $Running | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        try {
            $R = Expand-PowerToysBackup -Ptb $Ptb.FullName -SettingsDir $PowerToysSettingsDir
            Write-Host "$(Format-Highlight "[PowerToys settings restored]" -Style BrightGreen) $($R.Copied) written, $($R.Unchanged) already identical."
            if ($R.BackedUp -gt 0) { Write-Host "Replaced files were backed up to $($R.BackupRoot)" -ForegroundColor DarkGray }
            if ($Running.Count -gt 0) { Write-Host "PowerToys was stopped; start it again to load the restored settings." -ForegroundColor Cyan }
        } catch {
            Write-ErrorMsg "Failed to extract PowerToys backup: $_"
            if ($Running.Count -gt 0) { Write-Host "PowerToys was stopped; start it again." -ForegroundColor Cyan }
        }
    }
}

exit 0
