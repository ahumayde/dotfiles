<#
.SYNOPSIS
    Shared constants and helper functions. Dot-source this file from every setup script.
#>

# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------

$DotfilesPath   = Join-Path $HOME ".dotfiles"
$DotfilesRepo   = "https://github.com/ahumayde/dotfiles"
$DotfilesBranch = "windows-11/pc"
$ScriptsDir     = Join-Path $DotfilesPath "scripts"
$ConfigDir      = Join-Path $DotfilesPath "config"

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
