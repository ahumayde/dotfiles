<# .SYNOPSIS
    Windows Environment Setup Script
    Equivalent to the provided Bash dotfiles setup, adapted for Windows/PowerShell.
#>

# -----------------------------------------------------------------------------
# Variable Declarations
# -----------------------------------------------------------------------------

$HomeDir = $HOME
$ConfigDir = "$HomeDir\.config"
$NvimDir = "$ConfigDir\nvim"
$ScriptsDir = "$ConfigDir\scripts"  # <--- This will be added to PATH
$DotfilesRepo = "https://github.com/ahumayde/dotfiles"
$DotfilesSource = "$HOME\dotfiles"  # Where we download the source

# Winget Package IDs
$WingetIds = @(
    "Microsoft.PowerShell",       # PowerShell 7 (pwsh)
    "Git.Git",                    # Git
    "Neovim.Neovim",              # Neovim
    "Microsoft.PowerToys",        # PowerToys
    "AutoHotkey.AutoHotkey",      # AutoHotkey
    "RamenSoftware.Windhawk",     # Windhawk
    "JanDeDobbeleer.OhMyPosh",    # Oh My Posh
    "OpenJS.NodeJS.LTS",          # Node JS (Required for Neovim/LSP)
    "Python.Python.3.10",         # Python 3.10
    "BurntSushi.ripgrep.MSVC",    # Ripgrep (Required for Telescope)
    "Zig.Zig"                     # Zig Compiler (Often needed for Treesitter on Windows)
#   "JesseDuffield.lazygit",      # LazyGit (Optional but recommended for LazyVim)
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

    # 1. Install Packages
    foreach ($Id in $WingetIds) {
        Write-Host "Processing: $Id" -NoNewline
        $isInstalled = winget list -e --id $Id
        if ($LASTEXITCODE -eq 0) {
            Write-Host " [Already Installed]" -ForegroundColor Green
        } else {
            Write-Host " [Installing...]" -ForegroundColor Yellow
            winget install --id $Id -e
            if ($LASTEXITCODE -ne 0) {
                Write-ErrorMsg "Failed to install $Id"
            }
        }
    }
    # 2. Refresh Environment Variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
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
    $TargetPaths = @("C:\Program Files\Git\bin", "C:\Program Files\Neovim\bin")
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")

    foreach ($Path in $TargetPaths) {
        if ($CurrentPath -notlike "*$Path*") {
            Write-Status "Adding $Path to User Environment Path"
            [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$Path", "User")
        }
    }
}

function Setup-Dotfiles {
    Write-Status "Initializing Dotfiles Setup..."

    # 1. Ensure the Source Repo exists
    if (-not (Test-Path $DotfilesSource)) {
        Write-Status "Cloning your main dotfiles repository..."
        git clone $DotfilesRepo $DotfilesSource
    }

    # 2. Ensure the Target Config Directory exists
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
    }

    # 3. Get all Items (Files & Directories)
    $ItemsToSync = Get-ChildItem -Path $DotfilesSource -Force

    foreach ($Item in $ItemsToSync) {
        $TargetName = $Item.Name
        $SourcePath = $Item.FullName
        $TargetPath = "$ConfigDir\$TargetName"

        Write-Host "`nProcessing: [$TargetName]" -ForegroundColor Magenta

        if (Test-Path $TargetPath) {
            Write-Status "Existing configuration detected at $TargetPath"
            $Choice = Read-Host "[S]kip, [B]ackup & Replace, [D]elete & Replace? [S/B/D]"

            switch -Regex ($Choice) {
                "[Bb]" { # Backup
                    $TimeStamp = Get-Date -Format "yyyyMMddHHmmss"
                    $BackupPath = "$TargetPath.bak.$TimeStamp"

                    Write-Status "Backing up old config to $BackupPath"
                    Rename-Item -Path $TargetPath -NewName $BackupPath

                    Write-Status "Copying $TargetName..."
                    Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force
                }
                "[Dd]" { # Delete
                    Write-Status "Deleting old config..."
                    Remove-Item -Path $TargetPath -Recurse -Force

                    Write-Status "Copying $TargetName..."
                    Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force
                }
                Default { # Skip
                    Write-Status "Skipping $TargetName."
                }
            }
        } else { # No conflict, just copy
            Write-Status "No previous config found for $TargetName. Installing..."
            Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force
        }
    }
}

function Setup-SymLinks {}

function Install-NerdFonts {
    Write-Status "Configuring Nerd Font Installer..."
    
    # 1. Prepare Directory
    if (-not (Test-Path $ScriptsDir)) {
        New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
    }

    # 2. Download Script
    $LocalScriptPath = "$ScriptsDir\Invoke-NerdFontInstaller.ps1"
    try {
        Invoke-WebRequest -Uri $NerdFontScriptUrl -OutFile $LocalScriptPath
        Write-Status "Script saved to: $LocalScriptPath"
    }
    catch {
        Write-ErrorMsg "Download failed."
        return
    }

    # 3. Add Alias function to Profile
    if (-not (Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -Type File -Force | Out-Null
    }

    $ProfileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    $AliasCode = "function install-nerdfonts { & '$LocalScriptPath' @args }"

    if ($ProfileContent -notmatch "function install-nerdfonts") {
        Write-Status "Adding 'install-nerdfonts' command to PowerShell Profile..."
        Add-Content -Path $PROFILE -Value "# Setup Script: NerdFonts Shortcut"
        Add-Content -Path $PROFILE -Value $AliasCode
        . $PROFILE
    } else {
        Write-Status "Shortcut 'install-nerdfonts' already exists in Profile."
    }

    Write-Host "You can now type 'install-nerdfonts' from anywhere!" -ForegroundColor Green
}


# -----------------------------------------------------------------------------
# Execution Flow
# -----------------------------------------------------------------------------

# 1. Admin Check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges to install packages and modify PATH."
    Write-Warning "Please right-click and 'Run as Administrator'."
    exit
}

# 2. PowerShell Version Check
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Status "You are running Windows PowerShell 5."
    Write-Status "This script will install PowerShell 7 (pwsh)."
    Write-Status "NOTE: After installation, please restart your terminal using 'pwsh'."
}

# 3. Run Steps
Install-WingetPackages
Setup-Tools
Setup-Dotfiles
Setup-SymLinks
Install-NerdFonts

Write-Status "Setup Complete!"
Write-Status "Please restart your terminal (or log out and back in) to ensure all PATH changes take effect."
if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    Write-Status "Type 'pwsh' to switch to PowerShell 7."
}
