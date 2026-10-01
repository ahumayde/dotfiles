<#
.SYNOPSIS
    Installer AND shared library for the Windows/PowerShell dotfiles environment.

.DESCRIPTION
    Run directly (.\install.ps1) or straight from the web, it performs the full installation:

        irm https://raw.githubusercontent.com/ahumayde/dotfiles/refs/heads/windows-11/pc/setup/install.ps1 | iex

    With flags, use the script-block form (a plain pipe into iex cannot take arguments):

        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/ahumayde/dotfiles/refs/heads/windows-11/pc/setup/install.ps1))) -DryRun

    DOT-SOURCED by another script, it only loads the constants and functions and then stops, so
    export-configs.ps1 / deploy-configs.ps1 / uninstall.ps1 share one set of globals and helpers.
    Dot-source it WITH the flags forwarded, otherwise this param() block resets them:

        . "$SetupDir\install.ps1" -DryRun:$DryRun -All:$All

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

#############################################################################
### GLOBALS
#############################################################################

$DotfilesPath   = Join-Path $HOME ".dotfiles"
$DotfilesRepo   = "https://github.com/ahumayde/dotfiles"
$DotfilesBranch = "windows-11/pc"
$DotfilesRaw    = "https://raw.githubusercontent.com/ahumayde/dotfiles"
$SetupDir       = Join-Path $DotfilesPath "setup"
$ConfigDir      = Join-Path $DotfilesPath "configs"
$ScriptsDir     = Join-Path $DotfilesPath "scripts"
# Where THIS file lives in the repo (used to cache itself when run through iex and it must relaunch).
$ScriptUrl      = "$DotfilesRaw/$DotfilesBranch/setup/install.ps1"

$WingetIds = @(
    "Git.Git", "Neovim.Neovim", "Microsoft.PowerToys", "AutoHotkey.AutoHotkey",
    "RamenSoftware.Windhawk", "JanDeDobbeleer.OhMyPosh", "OpenJS.NodeJS",
    "Python.Python.3.14"
)

$TargetBinPaths = @(
    "C:\Program Files\Git\bin",
    "C:\Program Files\Git\usr\bin",
    "C:\Program Files\Neovim\bin",
    $ScriptsDir,
    $SetupDir
)

# Respects a redirected (e.g. OneDrive) Documents folder, unlike "$HOME\Documents".
$DocumentsDir = [Environment]::GetFolderPath("MyDocuments")
if (-not $DocumentsDir) { $DocumentsDir = Join-Path $HOME "Documents" }
$PowerShellProfilePath = Join-Path $DocumentsDir "PowerShell\Microsoft.PowerShell_profile.ps1"

$NerdFontScriptPath = Join-Path $ScriptsDir "Invoke-NerdFontInstaller.ps1"
$NerdFontScriptUrl  = "https://raw.githubusercontent.com/jpawlowski/nerd-fonts-installer-PS/master/Invoke-NerdFontInstaller.ps1"

# PowerToys keeps its settings in many JSON files, so the repo ships a .ptb backup instead.
$PowerToysSourceDir   = Join-Path $ConfigDir "powertoys"
$PowerToysBackupDir   = Join-Path $DocumentsDir "PowerToys\Backup"
$PowerToysSettingsDir = Join-Path $env:LOCALAPPDATA "Microsoft\PowerToys"

# Types: Symlink | Copy (file or folder) | CopyContents (merge folder contents into Target) | Shortcut
# Optional keys: Service = a Windows service to stop/restart around the copy,
#                Process = a process name (prefix) to close before the copy (not restarted).
$ConfigMappings = @(
    @{ Name = "PowerShell Profile"; Source = "$ConfigDir\terminal\profile.ps1"; Target = $PowerShellProfilePath; Type = "Symlink" },
    @{ Name = "Windows Terminal"; Source = "$ConfigDir\terminal\settings.json"; Target = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"; Type = "Copy" },
    @{ Name = "VSCode Settings"; Source = "$ConfigDir\vscode\settings.jsonc"; Target = "$env:APPDATA\Code\User\settings.json"; Type = "Copy" },
    @{ Name = "VSCode Keybinds"; Source = "$ConfigDir\vscode\keybindings.jsonc"; Target = "$env:APPDATA\Code\User\keybindings.json"; Type = "Copy" },
    @{ Name = "AutoHotkey Startup"; Source = "$ConfigDir\autohotkey\startup_ahk.exe"; Target = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\startup_ahk.lnk"; Type = "Shortcut" },
    @{ Name = "Windhawk Mods"; Source = "$ConfigDir\windhawk\mods"; Target = "$env:ProgramData\Windhawk\Engine\Mods"; Type = "CopyContents"; Service = "Windhawk" },
    @{ Name = "Windhawk Settings"; Source = "$ConfigDir\windhawk\userprofile.json"; Target = "$env:ProgramData\Windhawk\userprofile.json"; Type = "Copy"; Service = "Windhawk" },
    @{ Name = "Command Palette Json"; Source = "$ConfigDir\powertoys\cmdpal_settings.json"; Target = "$env:LOCALAPPDATA\Packages\Microsoft.CommandPalette_8wekyb3d8bbwe\LocalState\settings.json"; Type = "Copy"; Process = "CommandPalette" }
    @{ Name = "Command Palette Data"; Source = "$ConfigDir\powertoys\cmdpal_settings.dat"; Target = "$env:LOCALAPPDATA\Packages\Microsoft.CommandPalette_8wekyb3d8bbwe\Settings\settings.dat"; Type = "Copy"; Process = "CommandPalette" }
    # Neovim is handled within the powershell user profile
    # PowerToys is handled separately (see Invoke-PowerToysDeployment)
)

#############################################################################
### UTILS
#############################################################################

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
function Write-Status {
    param([string]$Message)
    Write-Host "-> $Message" -ForegroundColor Cyan
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

function Write-DryRunNotice {
    param([string]$Message)
    Write-Host "[DryRun] Would $Message" -ForegroundColor DarkGray
}

function Format-Highlight {
    param([string]$Text, [string]$Style)
    if ($PSVersionTable.PSVersion.Major -lt 7) { return $Text }
    $Codes = @{ BrightGray = "90"; BrightGreen = "92"; BrightYellow = "93"; BrightBlue = "94"; BrightMagenta = "95"; Green = "32"; White = "37"; Purple256 = "38;5;99" }
    if (-not $Codes.ContainsKey($Style)) { return $Text }
    return "`e[$($Codes[$Style])m$Text`e[0m"
}

# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------
function Confirm-Choice {
    param(
        [string]$Message,
        [string]$Title = "Confirm",
        [string[]]$ChoiceLabels,
        [string[]]$ChoiceDescriptions,
        [int]$DefaultIndex = 0
    )
    $Options = for ($i = 0; $i -lt $ChoiceLabels.Count; $i++) {
        $Desc = if ($ChoiceDescriptions -and $i -lt $ChoiceDescriptions.Count) { $ChoiceDescriptions[$i] } else { "" }
        New-Object System.Management.Automation.Host.ChoiceDescription $ChoiceLabels[$i], $Desc
    }
    return $Host.UI.PromptForChoice($Title, $Message, [System.Management.Automation.Host.ChoiceDescription[]]$Options, $DefaultIndex)
}

function Confirm-Step {
    param(
        [string]$Message,
        [string]$Title = "Confirm",
        [string]$YesDescription = "Proceeds with this step.",
        [string]$NoDescription = "Skips this step.",
        [switch]$DefaultNo   # use for destructive steps so a stray Enter doesn't confirm them
    )
    $Default = if ($DefaultNo) { 1 } else { 0 }
    $Result = Confirm-Choice -Title $Title -Message $Message -ChoiceLabels @("&Yes", "&No") -ChoiceDescriptions @($YesDescription, $NoDescription) -DefaultIndex $Default
    return ($Result -eq 0)
}

# ---------------------------------------------------------------------------
# Environment / elevation
# ---------------------------------------------------------------------------
function Test-PowerShell7 {
    if ($PSVersionTable.PSVersion.Major -ge 7) { return $true }
    Write-ErrorMsg "Detected Windows PowerShell $($PSVersionTable.PSVersion). PowerShell 7 is required: run this script with pwsh."
    return $false
}

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Returns $true when the CALLER MUST STOP (an elevated copy was launched, or elevation failed) and
# $false when it may carry on. It never calls 'exit', which would close the terminal under iex.
function Invoke-RequireAdmin {
    param(
        [string]$ScriptPath,   # only needed when we really have to relaunch; empty under iex + DryRun
        [switch]$DryRun,
        [switch]$All
    )

    if (Test-IsAdmin) { return $false }

    # A dry run modifies nothing, so there is no reason to raise a UAC prompt.
    if ($DryRun) {
        Write-Status "DryRun: continuing without elevation (nothing will be modified)."
        return $false
    }

    if (-not $ScriptPath) {
        Write-ErrorMsg "Cannot elevate: no script path to relaunch."
        return $true
    }

    Write-Status "Elevating privileges... Please accept the UAC prompt."
    $PwshExe  = (Get-Process -Id $PID).Path
    $PwshArgs = @("-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$ScriptPath`"")
    if ($All) { $PwshArgs += "-All" }

    try {
        if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
            Start-Process wt.exe -ArgumentList (@("`"$PwshExe`"") + $PwshArgs) -Verb RunAs -ErrorAction Stop
        } else {
            Start-Process $PwshExe -ArgumentList $PwshArgs -Verb RunAs -ErrorAction Stop
        }
    } catch {
        Write-ErrorMsg "Could not elevate (UAC declined?): $_"
    }
    return $true
}

# Under iex there is no script file to re-launch, so cache a copy of this script in %TEMP%.
function Save-RemoteScript {
    $Path = Join-Path $env:TEMP "dotfiles_setup.ps1"
    Write-Status "In-memory execution detected. Caching script locally to relaunch it..."
    $OldProgress = $ProgressPreference
    try {
        $ProgressPreference = "SilentlyContinue"   # the progress bar makes downloads very slow on 5.1
        Invoke-WebRequest -Uri $ScriptUrl -OutFile $Path -UseBasicParsing -ErrorAction Stop
        return $Path
    } catch {
        Write-ErrorMsg "Could not download $ScriptUrl : $_"
        return $null
    } finally {
        $ProgressPreference = $OldProgress
    }
}

function Find-Pwsh {
    $Cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($Cmd) { return $Cmd.Source }
    if ($env:ProgramFiles) {
        $Default = Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe"
        if (Test-Path $Default) { return $Default }
    }
    return $null
}

# From Windows PowerShell 5.x: make sure PowerShell 7 exists, then run this script under it.
function Start-UnderPowerShell7 {
    param([Parameter(Mandatory)][string]$ScriptPath, [switch]$DryRun, [switch]$All)

    $Pwsh = Find-Pwsh
    if (-not $Pwsh) {
        if ($DryRun) {
            Write-DryRunNotice "install PowerShell 7 (Microsoft.PowerShell) via winget, then continue under pwsh"
            return
        }
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-ErrorMsg "PowerShell 7 is required and winget was not found. Install 'App Installer' from the Microsoft Store, or install PowerShell 7 manually."
            return
        }
        Write-Status "Installing PowerShell 7..."
        winget install --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "PowerShell 7 installation failed (winget exit code $LASTEXITCODE)."; return }
        Update-SessionPath
        $Pwsh = Find-Pwsh
        if (-not $Pwsh) { Write-ErrorMsg "PowerShell 7 was installed but pwsh wasn't found. Open a new terminal and run the command again."; return }
    }

    $RunArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath)
    if ($DryRun) { $RunArgs += "-DryRun" }
    if ($All)    { $RunArgs += "-All" }
    & $Pwsh @RunArgs
}

function Update-SessionPath {
    # Rebuild $env:Path from the registry, keeping any session-only entries.
    $Fresh = @(Split-PathList ([Environment]::GetEnvironmentVariable("Path", "Machine"))) +
             @(Split-PathList ([Environment]::GetEnvironmentVariable("Path", "User")))
    $Extra = foreach ($Entry in (Split-PathList $env:Path)) {
        if (-not (Test-PathEntryPresent -Entries $Fresh -Path $Entry)) { $Entry }
    }
    $env:Path = (@($Fresh) + @($Extra)) -join ";"
}

# ---------------------------------------------------------------------------
# PATH list helpers
# ---------------------------------------------------------------------------
function Split-PathList {
    param([string]$List)
    if (-not $List) { return @() }
    return @($List -split ";" | Where-Object { $_.Trim() })
}

function ConvertTo-NormalizedPath {
    param([string]$Path)
    return [Environment]::ExpandEnvironmentVariables($Path).Trim().TrimEnd("\", "/")
}

function Test-PathEntryPresent {
    param([string[]]$Entries, [string]$Path)
    $Wanted = ConvertTo-NormalizedPath $Path
    foreach ($Entry in $Entries) {
        if ((ConvertTo-NormalizedPath $Entry) -ieq $Wanted) { return $true }
    }
    return $false
}

# Read/write the User PATH without flattening %VARIABLES% into literal values
# ([Environment]::Get/SetEnvironmentVariable expands them and writes REG_SZ).
function Get-UserPath {
    $Key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment")
    try { return [string]$Key.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) }
    finally { $Key.Dispose() }
}

function Set-UserPath {
    param([string]$Value)
    $Key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment", $true)
    try { $Key.SetValue("Path", $Value, [Microsoft.Win32.RegistryValueKind]::ExpandString) }
    finally { $Key.Dispose() }
    # Set + clear a throwaway variable so Windows broadcasts the environment change.
    [Environment]::SetEnvironmentVariable("DOTFILES_ENV_REFRESH", "1", "User")
    [Environment]::SetEnvironmentVariable("DOTFILES_ENV_REFRESH", $null, "User")
}

# ---------------------------------------------------------------------------
# Package / filesystem helpers
# ---------------------------------------------------------------------------
function Test-WingetPackageInstalled {
    param([string]$Id)
    # 'winget list' prints text even when nothing matches, so test the exit code, not the output.
    $null = winget list -e --id $Id --accept-source-agreements 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Remove-DeploymentTarget {
    param([Parameter(Mandatory)][string]$Path)
    $Item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($Item.LinkType) {
        # Delete only the link itself, never recurse through it into the repo.
        $Item.Delete()
    } else {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
    }
}

# Stops the service / processes a mapping needs out of the way. Returns state for Restore-MappingApps.
function Stop-MappingApps {
    param($Map)
    $State = [pscustomobject]@{ ServiceStopped = $false; ProcessClosed = $false }

    if ($Map.Service) {
        $Svc = Get-Service -Name $Map.Service -ErrorAction SilentlyContinue
        if ($Svc -and $Svc.Status -eq "Running") {
            Stop-Service -Name $Map.Service -ErrorAction Stop
            $State.ServiceStopped = $true
            Start-Sleep -Seconds 1
        }
        # Kill any lingering UI/Engine processes holding file locks (e.g., windhawk.exe)
        $Procs = @(Get-Process -Name "$($Map.Service)*" -ErrorAction SilentlyContinue)
        if ($Procs.Count -gt 0) { $Procs | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2 }
    }

    if ($Map.Process) {
        $Procs = @(Get-Process -Name "$($Map.Process)*" -ErrorAction SilentlyContinue)
        if ($Procs.Count -gt 0) {
            $Procs | Stop-Process -Force -ErrorAction SilentlyContinue
            $State.ProcessClosed = $true
            Start-Sleep -Seconds 1
        }
    }
    return $State
}

function Restore-MappingApps {
    param($Map, $State)
    if ($State.ServiceStopped) {
        try { Start-Service -Name $Map.Service -ErrorAction Stop }
        catch { Write-ErrorMsg "Failed to restart service $($Map.Service): $_" }
    }
    if ($State.ProcessClosed) {
        Write-Host "  $($Map.Process) was closed; reopen it to load the settings." -ForegroundColor Cyan
    }
}

#############################################################################
### CONFIG DEPLOYMENT (shared by install.ps1 and deploy-configs.ps1)
#############################################################################

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
            # If the existing item is a symlink, it is incorrect and must be replaced
            if ($Existing.LinkType) { return $false }

            $Src = Get-Item -LiteralPath $Map.Source -Force -ErrorAction SilentlyContinue
            if (-not $Src -or $Src.PSIsContainer -or $Existing.PSIsContainer) { return $false }

            # Safely hash the files, returning false silently if the path is broken
            try {
                $SrcHash = (Get-FileHash -LiteralPath $Map.Source -ErrorAction Stop).Hash
                $TgtHash = (Get-FileHash -LiteralPath $Map.Target -ErrorAction Stop).Hash
                return ($SrcHash -eq $TgtHash)
            } catch {
                return $false
            }
        }
        "Shortcut" {
            try {
                $Lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($Map.Target)
                return ($Lnk.TargetPath -ieq $Map.Source)
            } catch { return $false }
        }
        default { return $false }
    }
}

# Deploys repo -> system. Conflicts: Skip / Backup & Replace (<target>.bak.<timestamp>) / Delete & Replace.
function Invoke-ConfigDeployment {
    param([switch]$DryRun, [switch]$All, [object[]]$Mappings = $ConfigMappings)

    foreach ($Map in $Mappings) {
        Write-Host "Deploying [$($Map.Name)] " -ForegroundColor Magenta -NoNewline

        # DryRun: report and move on. Nothing below this block runs in a dry run.
        if ($DryRun) {
            Write-Host ""
            Write-DryRunNotice (Get-MappingDescription $Map)
            if ($Map.Service) { Write-DryRunNotice "stop and restart service: $($Map.Service)" }
            if ($Map.Process) { Write-DryRunNotice "close process: $($Map.Process)" }
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
            $Existing = $null   # don't let a previous iteration's value bleed through
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
        $AppState = $null
        try {
            $AppState = Stop-MappingApps -Map $Map

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
            if ($AppState) { Restore-MappingApps -Map $Map -State $AppState }
        }

        if ($Ok) { Write-Host (Format-Highlight "[Successfully Configured]" -Style BrightGreen) }
    }
}

# ---------------------------------------------------------------------------
# PowerToys settings
# PowerToys spreads its settings over many JSON files (one folder per module), so the repo
# ships a .ptb backup (created via PowerToys > General > Backup & restore > Backup) in
# configs\powertoys\. A .ptb is just a zip archive of those JSON files.
# ---------------------------------------------------------------------------
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

function Invoke-PowerToysDeployment {
    param([switch]$DryRun, [switch]$All)

    $Ptb = Get-LatestPtb $PowerToysSourceDir

    if ($DryRun) {
        if ($Ptb) {
            Write-DryRunNotice "ask how to apply $($Ptb.Name): copy it to $PowerToysBackupDir for a manual Restore in PowerToys, or extract it into $PowerToysSettingsDir (stopping PowerToys first)"
        } else {
            Write-DryRunNotice "look for a .ptb backup in $PowerToysSourceDir (none found or repo not cloned yet)"
        }
        return
    }
    if (-not $Ptb) {
        Write-Host "No .ptb backup found in $PowerToysSourceDir; skipping PowerToys settings." -ForegroundColor Yellow
        return
    }

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

#############################################################################
### LIBRARY MODE: when dot-sourced by another script, stop here.
### Everything above is now defined in the caller's scope; nothing below runs.
#############################################################################

if ($MyInvocation.InvocationName -eq ".") { return }

#############################################################################
### MAIN INSTALLER  (runs via ./install.ps1, & install.ps1, or irm | iex)
#############################################################################

$ActiveScriptPath = $PSCommandPath
$NeedPwsh  = $PSVersionTable.PSVersion.Major -lt 7
$NeedAdmin = (-not $DryRun) -and (-not (Test-IsAdmin))

# Only fetch a cached copy of this script when we actually have to relaunch it.
if (-not $ActiveScriptPath -and ($NeedPwsh -or $NeedAdmin)) {
    $ActiveScriptPath = Save-RemoteScript
    if (-not $ActiveScriptPath) { return }
}

# Started in Windows PowerShell 5.x: get PowerShell 7 and continue there (this check comes
# BEFORE elevating, so we don't raise UAC just to fail).
if ($NeedPwsh) {
    Start-UnderPowerShell7 -ScriptPath $ActiveScriptPath -DryRun:$DryRun -All:$All
    return
}

# Automatically elevate to Administrator and preserve flags (skipped for -DryRun)
if (Invoke-RequireAdmin -ScriptPath $ActiveScriptPath -DryRun:$DryRun -All:$All) { return }

Write-Status "Initialising Modular Environment Configuration..."
if ($DryRun) { Write-Status "DryRun mode: no changes will be made." }

#############################################################################
### Dependencies
#############################################################################

Write-Status "Checking Winget Packages..."

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "winget was not found. Install 'App Installer' from the Microsoft Store and re-run."
    return
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

#############################################################################
### PATH
#############################################################################

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
        return
    }
}

Update-SessionPath

#############################################################################
### Bootstrap
#############################################################################

Write-Status "Checking repository status..."

if (-not $DryRun -and -not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "git was not found on PATH. Install Git.Git (step 1) and re-run."
    return
}

if (-not (Test-Path $DotfilesPath)) {
    if ($DryRun) {
        Write-DryRunNotice "clone $DotfilesRepo (branch: $DotfilesBranch) to $DotfilesPath"
    } else {
        Write-Host "Cloning repository..." -ForegroundColor Yellow
        git clone -b $DotfilesBranch $DotfilesRepo $DotfilesPath
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "git clone failed (exit code $LASTEXITCODE)"
            return
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
    return
}

#############################################################################
### Config
#############################################################################

Write-Status "Configuring Nerd Fonts..."

# Ask first, so we never download something the user declined. A dry run never prompts.
if ($DryRun -or $All -or (Confirm-Step -Title "NerdFonts" -Message "Download (if needed) and run the Nerd Font installer now?")) {
    if (-not (Test-Path $NerdFontScriptPath)) {
        if ($DryRun) {
            Write-DryRunNotice "download Nerd Font installer to $NerdFontScriptPath"
        } else {
            try {
                New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
                Invoke-WebRequest -Uri $NerdFontScriptUrl -OutFile $NerdFontScriptPath -UseBasicParsing -ErrorAction Stop
            } catch {
                Write-ErrorMsg "Failed to download Nerd Font installer: $_"
                if (Test-Path $NerdFontScriptPath) { Remove-Item $NerdFontScriptPath -Force -ErrorAction SilentlyContinue }
            }
        }
    }

    if ($DryRun) {
        Write-DryRunNotice "execute $NerdFontScriptPath -Scope AllUsers"
    } elseif (Test-Path $NerdFontScriptPath) {
        try {
            Write-Host "Launching Nerd Fonts installer in a new window to preserve logs..." -ForegroundColor Yellow
            $PwshExe = (Get-Process -Id $PID).Path
            Start-Process $PwshExe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$NerdFontScriptPath`" -Scope AllUsers" -Wait
        }
        catch { Write-ErrorMsg "Nerd Font installer failed: $_" }
    }
} else {
    Write-Host "[Skipped] Nerd Fonts" -ForegroundColor Yellow
}

Write-Status "Synchronising Configuration Files..."
Invoke-ConfigDeployment -DryRun:$DryRun -All:$All

Write-Status "Configuring PowerToys settings..."
Invoke-PowerToysDeployment -DryRun:$DryRun -All:$All

if ($DryRun) { Write-Status "Dry run complete. No changes were made." }
else { Write-Status "Setup Complete! Please restart your terminal for all environment variables to apply globally." }
