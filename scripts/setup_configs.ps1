<# .SYNOPSIS
    Windows/Powershell Environment Configuration Script
#>

# -----------------------------------------------------------------------------
# Variable Declarations
# -----------------------------------------------------------------------------

$ConfigDir = "$HOME\.config"
$ScriptsDir = "$ConfigDir\scripts"
$PowershellDir = "$ConfigDir\powershell"
$PowershellProfile = "$PowershellDir\user_profile.ps1"
$WindowsTerminalSettings = "$ConfigDir\terminal\settings.json"
$NerdFontScriptPath = "$ScriptsDir\Invoke-NerdFontInstaller.ps1"

$DotfilesPath = "$HOME\dotfiles"
$DotfilesRepo = "https://github.com/ahumayde/dotfiles"
$DotfilesBranch = "windows-11/hp-laptop-14"

# Winget Package IDs
$WingetIds = @(
    "Git.Git",                    # Git
    "Neovim.Neovim",              # Neovim
    "Microsoft.PowerToys",        # PowerToys
    "AutoHotkey.AutoHotkey",      # AutoHotkey
    "RamenSoftware.Windhawk",     # Windhawk
    "JanDeDobbeleer.OhMyPosh",    # Oh My Posh
    "OpenJS.NodeJS.LTS",          # Node JS (Required for Neovim/LSP)
    "Python.Python.3.14",         # Python 3.14
    "zig.zig"                     # Zig Compiler (Often needed for Treesitter on Windows)
    # "BurntSushi.ripgrep.MSVC",    # Ripgrep (Required for Telescope)
    # "JesseDuffield.lazygit"       # LazyGit (Optional but recommended for LazyVim)
)

# Binary Paths to add to Environment Path
$TargetBinPaths = @(
    "C:\Program Files\Git\bin",
    "C:\Program Files\Git\Usr\bin",
    "C:\Program Files\Neovim\bin"
)

# Windows Terminal Settings Paths
$WindowsTerminalSettingsPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)

# Nerd Font Installer Script
$NerdFontScriptUrl = "https://raw.githubusercontent.com/jpawlowski/nerd-fonts-installer-PS/master/Invoke-NerdFontInstaller.ps1"
$PreferredFonts = @("JetBrainsMono", "CascadiaCode", "FiraCode")

# -----------------------------------------------------------------------------
# Function Declarations
# -----------------------------------------------------------------------------

function Write-Status {
    param([string]$Message)
    Write-Host "-> $Message" -ForegroundColor Cyan
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

function Install-WingetPackages {
    Write-Status "Checking and Installing Winget Packages..."

    # 1. Install Packages with User Confirmation
    foreach ($Id in $WingetIds) {
        Write-Host "Processing: [$Id]" -ForegroundColor Magenta -NoNewLine
        $null = winget list -e --id $Id 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host " [Already Installed]" -ForegroundColor Green
            continue
        }

	if ($PSVersionTable.PSVersion.Major -ge 7) { $Title = "Install `e[95m[$Id]" }
	else { $Title = "Install [$Id]" }

        $Message = "This application is missing. Do you wish to install it?"
        $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Installs $Id."
        $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Skips this application."
        $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

        $Result = $host.UI.PromptForChoice($Title, $Message, $Options, 0)
        if ($Result -eq 1) {
            Write-Host "Skipping $Id..." -ForegroundColor Yellow
            continue 
        }

        Write-Host "[Installing...]" -ForegroundColor Yellow
        winget install --id $Id -e

        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Failed to install $Id"
        } else {
            Write-Host "[$Id Installed]" -ForegroundColor Green
        }
    }

    # 2. Refresh Environment Variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Setup-Dotfiles {
    Write-Status "Initializing Dotfiles Setup..."

    # 1. Ensure the Source Repo exists
    if (-not (Test-Path $DotfilesPath)) {
        Write-Status "Cloning your main dotfiles repository..."
        git clone -b $DotFilesBranch $DotfilesRepo $DotFilesPath
    }

    # 2. Ensure the Target Config Directory exists
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
    }

    # 3. Get all Items (Files & Directories)
    $ItemsToSync = Get-ChildItem -Path $DotFilesPath -Force

    foreach ($Item in $ItemsToSync) {
        $TargetName = $Item.Name
        $SourcePath = $Item.FullName
        $TargetPath = "$ConfigDir\$TargetName"

        Write-Host "Processing: [dotfiles\$TargetName]" -ForegroundColor Magenta -NoNewLine

        if (Test-Path $TargetPath) {
            $Title = "File Conflict: Existing configuration detected at `e[94m$TargetPath"
            $Message = "How do you want to handle the existing configuration?"
            $Skip   = New-Object System.Management.Automation.Host.ChoiceDescription "&Skip", "Preserves the existing file."
            $Backup = New-Object System.Management.Automation.Host.ChoiceDescription "&Backup & Replace", "Renames the old file before copying."
            $Delete = New-Object System.Management.Automation.Host.ChoiceDescription "&Delete & Replace", "Deletes the old file before copying."
            $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Skip, $Backup, $Delete)

            $Result = $host.UI.PromptForChoice($Title, $Message, $Options, 0)
            switch -Regex ($Result) {
                1 { # Backup
                    $TimeStamp = Get-Date -Format "yyyyMMddHHmmss"
                    $BackupPath = "$TargetPath.bak.$TimeStamp"

                    Write-Host "`e[32mBacking up old config to $BackupPath..."
                    Rename-Item -Path $TargetPath -NewName $BackupPath
                    Start-Sleep -Milliseconds 100

                    Write-Host "Copying $SourcePath..." -ForegroundColor Yellow
                    Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force
                    Start-Sleep -Milliseconds 100

                    Write-Host "$TargetPath `e[92m[Successfully Installed]"
                }
                2 { # Delete
                    Write-Host "Deleting old configurations..." -ForegroundColor Red
                    Remove-Item -Path $TargetPath -Recurse -Force
                    Start-Sleep -Milliseconds 100

                    Write-Host "Copying $SourcePath..." -ForegroundColor Yellow
                    Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force
                    Start-Sleep -Milliseconds 100

                    Write-Host "$TargetPath `e[92m[Successfully Installed]"
                }
                0 { # Skip (Default)
                    Write-Host "Skipping $SourcePath..." -ForegroundColor Yellow
                }
            }
        } else { # No conflict, just copy
            Write-Host " [Installing...]" -Foreground Yellow
            Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force
            Start-Sleep -Milliseconds 100
            Write-Host "$TargetPath `e[92m[Successfully Installed]"
        }
    }
}

function Symlink-PowerShellProfiles {
    Write-Status "Symbolically Linking All Powershell Profiles..."

    # 1. Ensure ~/.config/powershell exists
    if (-not (Test-Path $PowershellDir)) {
        New-Item -ItemType Directory -Force -Path $PowershellDir | Out-Null
    }

    # 2. Ensure the unified profile file exists
    if (-not (Test-Path $PowershellProfile)) {
        New-Item -ItemType File -Force -Path $PowershellProfile | Out-Null
    }

    # 3. Collect all profile paths for both Windows PowerShell & PowerShell 7
    $ProfilePaths = @()

    # PowerShell 5 profiles
    try {
        $ProfilePaths += powershell -NoProfile -Command '$PROFILE.AllUsersAllHosts'
        $ProfilePaths += powershell -NoProfile -Command '$PROFILE.AllUsersCurrentHost'
        $ProfilePaths += powershell -NoProfile -Command '$PROFILE.CurrentUserAllHosts'
        $ProfilePaths += powershell -NoProfile -Command '$PROFILE.CurrentUserCurrentHost'
    } catch {
        Write-ErrorMsg "Failed to add Powershell 5 profiles to symbolic link list"
    }

    # PowerShell 7 profiles
    try {
        $ProfilePaths += pwsh -NoProfile -Command '$PROFILE.AllUsersAllHosts'
        $ProfilePaths += pwsh -NoProfile -Command '$PROFILE.AllUsersCurrentHost'
        $ProfilePaths += pwsh -NoProfile -Command '$PROFILE.CurrentUserAllHosts'
        $ProfilePaths += pwsh -NoProfile -Command '$PROFILE.CurrentUserCurrentHost'
    } catch {
        Write-ErrorMsg "Failed to add Powershell 7 profiles to symbolic link list"
    }

    # Remove duplicates and empty entries
    $ProfilePaths = $ProfilePaths | Where-Object { $_ -and $_.Trim() -ne "" } | Select-Object -Unique

    # 4. Replace each profile with a symbolic link
    foreach ($Profile in $ProfilePaths) {
        $ProfileDir = Split-Path $Profile

        # Ensure directory exists
        if (-not (Test-Path $ProfileDir)) {
            New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
        }

        # Remove existing profile file or link
        if (Test-Path $Profile) { Remove-Item $Profile -Force }

        # Create symbolic link
        Write-Host "Creating SymLink: `e[38;5;99m$Profile `e[37m-> $PowershellProfile..."
        New-Item -ItemType SymbolicLink -Path $Profile -Target $PowershellProfile | Out-Null
        Start-Sleep -Milliseconds 100

    }

    Write-Host "[PowerShell profiles configured at `e[94m$PowershellProfile`e[92m]" -ForegroundColor Green
}

function Setup-Tools {
    Write-Status "Setting up Development Tools..."

    # 1. Setup Python Pip & PyNvim
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Host "Upgrading Pip and installing Pynvim..."
        python -m pip install --upgrade pip
        python -m pip install pynvim
    } else {
        Write-ErrorMsg "Python not found. Skipping Pip setup."
    }

    # 2. Add Binaries to Path (Persistently)
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")

    foreach ($Path in $TargetBinPaths) {
        if ($CurrentPath -notlike "*$Path*") {
            [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$Path", "User")
            Write-Host "Added $Path to User Environment Path"
        }
    }
}

function Setup-NerdFonts {
    Write-Status "Configuring Nerd Fonts..." -NoNewLine

    # 1. Prepare Directory
    if (-not (Test-Path $ScriptsDir)) {
        New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
    }

    # 2. Download Script
    if (-not (Test-Path $PROFILE)) {
        Write-Host "Downloading font installation script..." -ForegroundColor Yellow
        try {

            Invoke-WebRequest -Uri $NerdFontScriptUrl -OutFile $NerdFontScriptPath
            Write-Host "Font installation script saved to: $NerdFontScriptPath"
        }
        catch { Write-ErrorMsg "Download failed."; return }
    }

    # 3. Add Alias function to Profile
    if (-not (Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -Type File -Force | Out-Null
    }

    $ProfileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    $AliasCode = "function install-nerdfonts { & '$NerdFontScriptPath' @args }"

    Write-Host "Adding 'install-nerdfonts' command to PowerShell Profile..." -ForegroundColor Yellow
    if ($ProfileContent -notmatch "function install-nerdfonts") {
        Add-Content -Path $PROFILE -Value '`n# Setup Script: NerdFonts Shortcut'
        Add-Content -Path $PROFILE -Value $AliasCode
        Start-Sleep -Milliseconds 100
        Write-Host "[install-nerdfonts Successfully Added]" -ForegroundColor Green
    } else {
        Write-Host "Shortcut 'install-nerdfonts' already exists in Profile." -NoNewLine
    }
    
    $Title = "Install `e[95m[NerdFonts]"
    $Message = "You can now use '`e[93minstall-nerdfonts `e[90m-Scope `e[37mAllUsers' to install NerdFonts. Would you like to run this now?"
    $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Runs the command immediately."
    $No  = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Skips this step."
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

    $Result = $host.UI.PromptForChoice($Title, $Message, $Options, 0)
    switch -Regex ($Result) {
        0 { # Yes (Default)
            Write-Host "Starting NerdFonts installation..." -ForegroundColor Yellow
            & 'C:\Users\ahuma\.config\scripts\Invoke-NerdFontInstaller.ps1' -Scope AllUsers
        }
        1 { # No
            Write-Host "Skipped NerdFonts installation." -ForegroundColor Gray
        }
    }
}

function Symlink-WindowsTerminalSettings {
    Write-Status "Symbolically Linking Windows Terminal Settings"

    # 1. Ensure unified file exists
    if (-not (Test-Path $WindowsTerminalSettings)) {
        New-Item -ItemType File -Force -Path $WindowsTerminalSettings | Out-Null
    }

    # 2. Create Symbolic Link to configuration file
    $CreatedPaths = foreach ($Path in $WindowsTerminalSettingsPaths) {
        if (Test-Path (Split-Path $Path)) {
            if (Test-Path $Path) {
                Remove-Item $Path -Force
            }
            Write-Host "Creating SymLink: `e[38;5;99m$Path `e[37m-> $WindowsTerminalSettings..."
            New-Item -ItemType SymbolicLink -Path $Path -Target $WindowsTerminalSettings | Out-Null
            Start-Sleep -Milliseconds 100
            $Path
        }
    }

    if ($CreatedPaths) {
        Write-Host "[Windows Terminal 'settings.json' configured at `e[94m$WindowsTerminalSettings`e[92m]" -ForegroundColor Green
    }
}

function Run-ConfigSetup {
    $Title = "Configuration Installation & Setup" 
    $Message = "Would you like to run the installation and setup process?"

    $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Runs the installation and setup process."
    $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Ends the script."
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

    $Result = $host.UI.PromptForChoice($Title, $Message, $Options, 0)
    if ($Result -eq 0) {
        # 1. Admin Check
        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Status "This script requires Administrator privileges to install packages and modify PATH."
            Write-Status "Close this window and reopen PowerShell using 'Run as Administrator'."
            Read-Host "Press Enter to confirm and exit"
            return
        }

        # 2. PowerShell Version Check
        if ($PSVersionTable.PSVersion.Major -lt 7) {
            Write-Status "Detected Windows PowerShell 5.x - PowerShell 7 is required."
            $null = winget list -e --id "Microsoft.PowerShell" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Status "Start PowerShell 7 by running 'pwsh' here or opening a new PowerShell 7 window."
            } else {
                Write-Status "Attempting to install PowerShell 7 (pwsh) via winget..."
                Write-Status "NOTE: After installation, start PowerShell 7 by running 'pwsh' here or opening a new PowerShell 7 window."
                $OriginalWingetIds = $WingetIds
                $WingetIds = @( "Microsoft.PowerShell" )
                Install-WingetPackages
                $WingetIds = $OriginalWingetIds
            }

            Write-Status "Restart this script from PowerShell 7 to continue."
            return
        }

        Install-WingetPackages
        Setup-Tools
        Setup-Dotfiles
        Symlink-PowerShellProfiles
        Setup-NerdFonts
        Symlink-WindowsTerminalSettings

        Write-Status "Setup Complete!"
        Write-Status "Please restart your terminal (or log out and back in) to ensure all PATH changes take effect."

        Write-Host "Reloading powershell profile..." -ForegroundColor Yellow
        Write-Host "PowerShell $($PSVersionTable.PSVersion)"
        $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew(); . $PROFILE; $Stopwatch.Stop()
        Write-Host "Loading personal and system profiles took $($Stopwatch.ElapsedMilliseconds)ms."
        Write-Host "[Powershell Profile Reloaded]" -ForegroundColor Green -NoNewLine
    }
}

# -----------------------------------------------------------------------------
# Execution Flow
# -----------------------------------------------------------------------------

# Run Configuration Steps
Run-ConfigSetup
