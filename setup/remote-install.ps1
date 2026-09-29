<#
.SYNOPSIS
    Remote installer for the Windows/PowerShell dotfiles environment.

.PARAMETER DryRun
    Print what would be done without downloading, installing or modifying anything.

.PARAMETER All
    Non-interactive: answer "yes" to install prompts and back up conflicting configs.
#>

param(
    [switch]$DryRun,
    [switch]$All
)

#############################################################################
### UTILS
#############################################################################


# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------

$DotfilesPath   = Join-Path $HOME ".dotfiles"
$DotfilesRepo   = "https://github.com/ahumayde/dotfiles"
$DotfilesBranch = "windows-11/pc"
$DotfilesRaw    = "https://raw.githubusercontent.com/ahumayde/dotfiles"
$ConfigDir      = Join-Path $DotfilesPath "configs"
$ScriptsDir     = Join-Path $DotfilesPath "scripts"
$ScriptUrl      = "$DotfilesRaw/$DotfilesBranch/setup/remote-install.ps1"

$WingetIds = @(
    "Git.Git", "Neovim.Neovim", "Microsoft.PowerToys", "AutoHotkey.AutoHotkey",
    "RamenSoftware.Windhawk", "JanDeDobbeleer.OhMyPosh", "OpenJS.NodeJS.LTS",
    "Python.Python.3.14"
)

$TargetBinPaths = @(
    "C:\Program Files\Git\bin",
    "C:\Program Files\Git\usr\bin",
    "C:\Program Files\Neovim\bin",
    $ScriptsDir
)

# Respects a redirected (e.g. OneDrive) Documents folder, unlike "$HOME\Documents".
$DocumentsDir = [Environment]::GetFolderPath("MyDocuments")
if (-not $DocumentsDir) { $DocumentsDir = Join-Path $HOME "Documents" }
$PowerShellProfilePath = Join-Path $DocumentsDir "PowerShell\Microsoft.PowerShell_profile.ps1"
# $PowerShellProfilePath = $PROFILE.CurrentUserCurrentHost

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
        [string]$NoDescription = "Skips this step."
    )
    $Result = Confirm-Choice -Title $Title -Message $Message -ChoiceLabels @("&Yes", "&No") -ChoiceDescriptions @($YesDescription, $NoDescription)
    return ($Result -eq 0)
}

# ---------------------------------------------------------------------------
# Environment / elevation
# ---------------------------------------------------------------------------
function Assert-PowerShell7 {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-ErrorMsg "Detected Windows PowerShell $($PSVersionTable.PSVersion). PowerShell 7 is required. Please install/open pwsh."
        exit 1
    }
}

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-RequireAdmin {
    param(
        [Parameter(Mandatory)][string]$ScriptPath,
        [switch]$DryRun,
        [switch]$All
    )

    if (Test-IsAdmin) { return }

    if ($DryRun) {
        Write-Status "DryRun: continuing without elevation (nothing will be modified)."
        return
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
        exit 1
    }
    exit
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


#############################################################################
### SCRIPT REQUIREMENTS
#############################################################################

# Check the PowerShell version BEFORE elevating, so we don't raise UAC just to fail.
Assert-PowerShell7

# Resolve the script path. If running via 'iex', $PSCommandPath is empty.
$ActiveScriptPath = $PSCommandPath

if (-not $ActiveScriptPath) {
    Write-Status "In-memory execution detected. Caching script locally for elevation..."
    $ActiveScriptPath = Join-Path $env:TEMP "dotfiles_setup.ps1"

    # Replace this URL with the exact raw link to your unified script
    Invoke-WebRequest -Uri $ScriptUrl -OutFile $ActiveScriptPath
}

# Automatically elevate to Administrator and preserve flags (skipped for -DryRun)
Invoke-RequireAdmin -ScriptPath $ActiveScriptPath -DryRun:$DryRun -All:$All

Write-Status "Initialising Modular Environment Configuration..."
if ($DryRun) { Write-Status "DryRun mode: no changes will be made." }


#############################################################################
### Dependencies
#############################################################################


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
        exit 1
    }
}

Update-SessionPath


#############################################################################
### Bootstrap
#############################################################################


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


#############################################################################
### Config
#############################################################################


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
    @{ Name = "VSCode Settings"; Source = "$ConfigDir\vscode\settings.jsonc"; Target = "$env:APPDATA\Code\User\settings.jsonc"; Type = "Copy" },
    @{ Name = "VSCode Keybinds"; Source = "$ConfigDir\vscode\keybindings.jsonc"; Target = "$env:APPDATA\Code\User\keybindings.jsonc"; Type = "Copy" },
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
            if (-not (Test-Path -LiteralPath $Map.Target)) { return $false }
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
        # Clear variable to prevent bleeding from previous loop iterations
        $Existing = $null 
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
            # Stop the core background service
            $Svc = Get-Service -Name $Map.Service -ErrorAction SilentlyContinue
            if ($Svc -and $Svc.Status -eq "Running") {
                Stop-Service -Name $Map.Service -ErrorAction Stop
                $ServiceStopped = $true
                Start-Sleep -Seconds 1
            }
            # Kill any lingering UI/Engine processes holding file locks (e.g., windhawk.exe)
            $Processes = Get-Process -Name "$($Map.Service)*" -ErrorAction SilentlyContinue
            if ($Processes) {
                $Processes | Stop-Process -Force -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 2
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

if ($DryRun) { Write-Status "Dry run complete. No changes were made." } 
else { Write-Status "Setup Complete! Please restart your terminal for all environment variables to apply globally." }
