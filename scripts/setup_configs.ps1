<# .SYNOPSIS
    Windows/Powershell Environment Configuration Script
#>

param(
    [switch]$DryRun
)

# -----------------------------------------------------------------------------
# Variable Declarations
# -----------------------------------------------------------------------------

$ConfigDir = "$HOME\.config"
$ScriptsDir = "$ConfigDir\scripts"
$PowershellDir = "$ConfigDir\terminal"
$PowershellProfile = "$PowershellDir\user_profile.ps1"
$WindowsTerminalSettings = "$ConfigDir\terminal\settings.json"
$NerdFontScriptPath = "$ScriptsDir\Invoke-NerdFontInstaller.ps1"

$DotfilesPath = "$HOME\dotfiles"
$DotfilesRepo = "https://github.com/ahumayde/dotfiles"
$DotfilesBranch = "windows-11/surface-pro-9"

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

function Write-DryRunNotice {
    param([string]$Message)
    Write-Host "[DryRun] Would $Message" -ForegroundColor DarkGray
}

function Format-Highlight {
    <#
    .SYNOPSIS
        Wraps text in an ANSI escape sequence so callers don't have to
        hardcode raw escape codes throughout the script. The style table
        below reproduces the exact codes used in the original script
        (not a generic replacement palette), so output looks identical.
        Falls back to plain, uncolored text on PowerShell < 7, since
        Windows PowerShell 5.1's console host doesn't reliably render
        ANSI/VT escape sequences.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [ValidateSet(
            "BrightGray",     # `e[90m - used for "-Scope"
            "BrightGreen",    # `e[92m - used for "[Successfully Installed]" / "]"
            "BrightYellow",   # `e[93m - used for "install-nerdfonts"
            "BrightBlue",     # `e[94m - used for file paths in titles/summaries
            "BrightMagenta",  # `e[95m - used for [$Id] and [NerdFonts] titles
            "Green",          # `e[32m - used for "Backing up old config..."
            "White",          # `e[37m - used for "-> $Target" / "AllUsers"
            "Purple256"       # `e[38;5;99m - used for symlink source paths
        )]
        [string]$Style
    )

    # Powershell versions below 7 do not reliably render ANSI escape sequences
    if ($PSVersionTable.PSVersion.Major -lt 7) { return $Text }

    $Codes = @{
        BrightGray    = "90"
        BrightGreen   = "92"
        BrightYellow  = "93"
        BrightBlue    = "94"
        BrightMagenta = "95"
        Green         = "32"
        White         = "37"
        Purple256     = "38;5;99"
    }
    return "`e[$($Codes[$Style])m$Text`e[0m"
}

function Confirm-Choice {
    <#
    .SYNOPSIS
        Generalized multi-choice prompt. Returns the index of the selected
        choice. Confirm-Step (yes/no) and any multi-option prompt (e.g. the
        dotfiles Skip/Backup/Delete conflict) both build on this.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Title = "Confirm",

        [Parameter(Mandatory)]
        [string[]]$ChoiceLabels,

        [string[]]$ChoiceDescriptions,

        [int]$DefaultIndex = 0
    )

    $ChoiceObjects = for ($i = 0; $i -lt $ChoiceLabels.Count; $i++) {
        $Description = ""
        if ($ChoiceDescriptions -and $i -lt $ChoiceDescriptions.Count) {
            $Description = $ChoiceDescriptions[$i]
        }
        New-Object System.Management.Automation.Host.ChoiceDescription $ChoiceLabels[$i], $Description
    }

    $Options = [System.Management.Automation.Host.ChoiceDescription[]]$ChoiceObjects
    return $host.UI.PromptForChoice($Title, $Message, $Options, $DefaultIndex)
}

function Confirm-Step {
    <#
    .SYNOPSIS
        Thin yes/no wrapper around Confirm-Choice for the common case.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [string]$Title = "Confirm",
        [string]$YesDescription = "Proceeds with this step.",
        [string]$NoDescription  = "Skips this step."
    )

    $Result = Confirm-Choice -Title $Title -Message $Message `
        -ChoiceLabels @("&Yes", "&No") `
        -ChoiceDescriptions @($YesDescription, $NoDescription)

    return ($Result -eq 0)
}

function Install-WingetPackages {
    param(
        [switch]$All,
        [switch]$DryRun
    )

    Write-Status "Checking and Installing Winget Packages..."

    # 1. Install Packages with User Confirmation
    foreach ($Id in $WingetIds) {
        Write-Host "Processing: [$Id]" -ForegroundColor Magenta -NoNewLine
        $null = winget list -e --id $Id 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host " [Already Installed]" -ForegroundColor Green
            continue
        }

        $Title = "Install $(Format-Highlight "[$Id]" -Style BrightMagenta)"

        $ShouldInstall = $All -or (Confirm-Step -Title $Title `
            -Message "This application is missing. Do you wish to install it?" `
            -YesDescription "Installs $Id." `
            -NoDescription "Skips this application.")

        if (-not $ShouldInstall) {
            Write-Host "Skipping $Id..." -ForegroundColor Yellow
            continue
        }

        if ($DryRun) {
            Write-DryRunNotice "install winget package '$Id'"
            continue
        }

        Write-Host "[Installing...]" -ForegroundColor Yellow
        try {
            winget install --id $Id -e
            if ($LASTEXITCODE -ne 0) {
                throw "winget exited with code $LASTEXITCODE"
            }
            Write-Host "[$Id Installed]" -ForegroundColor Green
        } catch {
            Write-ErrorMsg "Failed to install $Id`: $_"
        }
    }

    # 2. Refresh Environment Variables
    if ($DryRun) {
        Write-DryRunNotice "refresh the Path environment variable"
    } else {
        try {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        } catch {
            Write-ErrorMsg "Failed to refresh Path environment variable: $_"
        }
    }
}

function Setup-Dotfiles {
    param(
        [switch]$All,
        [switch]$DryRun
    )

    Write-Status "Initializing Dotfiles Setup..."

    # 1. Ensure the Source Repo exists
    if (-not (Test-Path $DotfilesPath)) {
        if ($DryRun) {
            Write-DryRunNotice "clone $DotfilesRepo (branch: $DotfilesBranch) to $DotfilesPath"
        } else {
            Write-Status "Cloning your main dotfiles repository..."
            try {
                git clone -b $DotfilesBranch $DotfilesRepo $DotfilesPath
                if ($LASTEXITCODE -ne 0) {
                    throw "git clone exited with code $LASTEXITCODE"
                }
            } catch {
                Write-ErrorMsg "Failed to clone dotfiles repository: $_"
                return
            }
        }
    }

    # 2. Ensure the Target Config Directory exists
    if (-not (Test-Path $ConfigDir)) {
        if ($DryRun) {
            Write-DryRunNotice "create directory $ConfigDir"
        } else {
            New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
        }
    }

    # 3. Get all Items (Files & Directories)
    if (-not (Test-Path $DotfilesPath)) {
        Write-ErrorMsg "Dotfiles path $DotfilesPath not found. Skipping sync."
        return
    }
    $ItemsToSync = Get-ChildItem -Path $DotfilesPath -Force

    foreach ($Item in $ItemsToSync) {
        $TargetName = $Item.Name
        $SourcePath = $Item.FullName
        $TargetPath = "$ConfigDir\$TargetName"

        Write-Host "Processing: [dotfiles\$TargetName]" -ForegroundColor Magenta -NoNewLine

        if (Test-Path $TargetPath) {
            # NOTE: this is a 3-way choice (Skip/Backup/Delete), not a yes/no,
            # so it uses Confirm-Choice directly rather than Confirm-Step.
            # When -All is set, we replace the existing config outright
            # (consistent with -All meaning "run the full install without
            # further prompts").
            if ($All) {
                if ($DryRun) {
                    Write-DryRunNotice "delete and replace existing config at $TargetPath"
                    continue
                }
                Write-Host " [Replacing...]" -ForegroundColor Yellow
                try {
                    Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
                    Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force -ErrorAction Stop
                    Start-Sleep -Milliseconds 100
                    Write-Host "$TargetPath $(Format-Highlight "[Successfully Installed]" -Style BrightGreen)"
                } catch {
                    Write-ErrorMsg "Failed to replace $TargetPath : $_"
                }
                continue
            }

            $Title = "File Conflict: Existing configuration detected at $(Format-Highlight $TargetPath -Style BrightBlue)"
            $Message = "How do you want to handle the existing configuration?"

            $Result = Confirm-Choice -Title $Title -Message $Message `
                -ChoiceLabels @("&Skip", "&Backup & Replace", "&Delete & Replace") `
                -ChoiceDescriptions @(
                    "Preserves the existing file.",
                    "Renames the old file before copying.",
                    "Deletes the old file before copying."
                )

            switch ($Result) {
                1 { # Backup
                    $TimeStamp = Get-Date -Format "yyyyMMddHHmmss"
                    $BackupPath = "$TargetPath.bak.$TimeStamp"

                    if ($DryRun) {
                        Write-DryRunNotice "back up $TargetPath to $BackupPath, then copy $SourcePath to $TargetPath"
                        continue
                    }

                    try {
                        Write-Host "$(Format-Highlight "Backing up old config to $BackupPath..." -Style BrightGreen)"
                        Rename-Item -Path $TargetPath -NewName $BackupPath -ErrorAction Stop
                        Start-Sleep -Milliseconds 100

                        Write-Host "Copying $SourcePath..." -ForegroundColor Yellow
                        Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force -ErrorAction Stop
                        Start-Sleep -Milliseconds 100

                        Write-Host "$TargetPath $(Format-Highlight "[Successfully Installed]" -Style BrightGreen)"
                    } catch {
                        Write-ErrorMsg "Failed to back up and replace $TargetPath : $_"
                    }
                }
                2 { # Delete
                    if ($DryRun) {
                        Write-DryRunNotice "delete $TargetPath, then copy $SourcePath to $TargetPath"
                        continue
                    }

                    try {
                        Write-Host "Deleting old configurations..." -ForegroundColor Red
                        Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
                        Start-Sleep -Milliseconds 100

                        Write-Host "Copying $SourcePath..." -ForegroundColor Yellow
                        Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force -ErrorAction Stop
                        Start-Sleep -Milliseconds 100

                        Write-Host "$TargetPath $(Format-Highlight "[Successfully Installed]" -Style BrightGreen)"
                    } catch {
                        Write-ErrorMsg "Failed to delete and replace $TargetPath : $_"
                    }
                }
                0 { # Skip (Default)
                    Write-Host "Skipping $SourcePath..." -ForegroundColor Yellow
                }
            }
        } else { # No conflict, just copy
            if ($DryRun) {
                Write-DryRunNotice "copy $SourcePath to $TargetPath"
                continue
            }

            Write-Host " [Installing...]" -ForegroundColor Yellow
            try {
                Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force -ErrorAction Stop
                Start-Sleep -Milliseconds 100
                Write-Host "$TargetPath $(Format-Highlight "[Successfully Installed]" -Style BrightGreen)"
            } catch {
                Write-ErrorMsg "Failed to install $TargetPath : $_"
            }
        }
    }
}

function Symlink-PowerShellProfiles {
    param(
        [switch]$All,
        [switch]$DryRun
    )

    Write-Status "Symbolically Linking All Powershell Profiles..."

    # 1. Ensure ~/.config/terminal exists
    if (-not (Test-Path $PowershellDir)) {
        if ($DryRun) {
            Write-DryRunNotice "create directory $PowershellDir"
        } else {
            New-Item -ItemType Directory -Force -Path $PowershellDir | Out-Null
        }
    }

    # 2. Ensure the unified profile file exists
    if (-not (Test-Path $PowershellProfile)) {
        if ($DryRun) {
            Write-DryRunNotice "create file $PowershellProfile"
        } else {
            New-Item -ItemType File -Force -Path $PowershellProfile | Out-Null
        }
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
        Write-ErrorMsg "Failed to add Powershell 5 profiles to symbolic link list: $_"
    }

    # PowerShell 7 profiles
    try {
        $ProfilePaths += pwsh -NoProfile -Command '$PROFILE.AllUsersAllHosts'
        $ProfilePaths += pwsh -NoProfile -Command '$PROFILE.AllUsersCurrentHost'
        $ProfilePaths += pwsh -NoProfile -Command '$PROFILE.CurrentUserAllHosts'
        $ProfilePaths += pwsh -NoProfile -Command '$PROFILE.CurrentUserCurrentHost'
    } catch {
        Write-ErrorMsg "Failed to add Powershell 7 profiles to symbolic link list: $_"
    }

    # Remove duplicates and empty entries
    $ProfilePaths = $ProfilePaths | Where-Object { $_ -and $_.Trim() -ne "" } | Select-Object -Unique

    # 4. Replace each profile with a symbolic link
    foreach ($Profile in $ProfilePaths) {
        $ProfileDir = Split-Path $Profile

        if ($DryRun) {
            Write-DryRunNotice "link $Profile -> $PowershellProfile"
            continue
        }

        try {
            # Ensure directory exists
            if (-not (Test-Path $ProfileDir)) {
                New-Item -ItemType Directory -Force -Path $ProfileDir -ErrorAction Stop | Out-Null
            }

            # Remove existing profile file or link
            if (Test-Path $Profile) { Remove-Item $Profile -Force -ErrorAction Stop }

            # Create symbolic link
            Write-Host "Creating SymLink: $(Format-Highlight $Profile -Style Purple256) -> $PowershellProfile..."
            New-Item -ItemType SymbolicLink -Path $Profile -Target $PowershellProfile -ErrorAction Stop | Out-Null
            Start-Sleep -Milliseconds 100
        } catch {
            Write-ErrorMsg "Failed to link $Profile : $_"
        }
    }

    Write-Host "[PowerShell profiles configured at $(Format-Highlight $PowershellProfile -Style BrightBlue)]" -ForegroundColor Green
}

function Setup-Tools {
    param(
        [switch]$All,
        [switch]$DryRun
    )

    Write-Status "Setting up Development Tools..."

    # 1. Setup Python Pip & PyNvim
    if (Get-Command python -ErrorAction SilentlyContinue) {
        if ($DryRun) {
            Write-DryRunNotice "upgrade pip and install pynvim"
        } else {
            try {
                Write-Host "Upgrading Pip and installing Pynvim..."
                python -m pip install --upgrade pip
                if ($LASTEXITCODE -ne 0) { throw "pip upgrade exited with code $LASTEXITCODE" }
                python -m pip install pynvim
                if ($LASTEXITCODE -ne 0) { throw "pynvim install exited with code $LASTEXITCODE" }
            } catch {
                Write-ErrorMsg "Failed to set up Python tooling: $_"
            }
        }
    } else {
        Write-ErrorMsg "Python not found. Skipping Pip setup."
    }

    # 2. Add Binaries to Path (Persistently)
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")

    foreach ($Path in $TargetBinPaths) {
        if ($CurrentPath -notlike "*$Path*") {
            if ($DryRun) {
                Write-DryRunNotice "add $Path to User environment Path"
                continue
            }
            try {
                [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$Path", "User")
                Write-Host "Added $Path to User Environment Path"
            } catch {
                Write-ErrorMsg "Failed to add $Path to User Path: $_"
            }
        }
    }
}

function Setup-NerdFonts {
    param(
        [switch]$All,
        [switch]$DryRun
    )

    Write-Status "Configuring Nerd Fonts..." -NoNewLine

    # 1. Prepare Directory
    if (-not (Test-Path $ScriptsDir)) {
        if ($DryRun) {
            Write-DryRunNotice "create directory $ScriptsDir"
        } else {
            New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
        }
    }

    # 2. Download Script
    if (-not (Test-Path $NerdFontScriptPath)) {
        if ($DryRun) {
            Write-DryRunNotice "download $NerdFontScriptUrl to $NerdFontScriptPath"
        } else {
            Write-Host "Downloading font installation script..." -ForegroundColor Yellow
            try {
                Invoke-WebRequest -Uri $NerdFontScriptUrl -OutFile $NerdFontScriptPath -ErrorAction Stop
                Write-Host "Font installation script saved to: $NerdFontScriptPath"
            } catch {
                Write-ErrorMsg "Download failed: $_"
                return
            }
        }
    }

    # 3. Add Alias function to Profile
    if (-not (Test-Path $PROFILE)) {
        if ($DryRun) {
            Write-DryRunNotice "create profile file $PROFILE"
        } else {
            New-Item -Path $PROFILE -Type File -Force | Out-Null
        }
    }

    $ProfileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    $AliasCode = "function install-nerdfonts { & '$NerdFontScriptPath' @args }"

    if ($ProfileContent -notmatch "function install-nerdfonts") {
        if ($DryRun) {
            Write-DryRunNotice "add 'install-nerdfonts' function to $PROFILE"
        } else {
            Write-Host "Adding 'install-nerdfonts' command to PowerShell Profile..." -ForegroundColor Yellow
            try {
                Add-Content -Path $PROFILE -Value "`n# Setup Script: NerdFonts Shortcut" -ErrorAction Stop
                Add-Content -Path $PROFILE -Value $AliasCode -ErrorAction Stop
                Start-Sleep -Milliseconds 100
                Write-Host "[install-nerdfonts Successfully Added]" -ForegroundColor Green
            } catch {
                Write-ErrorMsg "Failed to update profile with nerd fonts shortcut: $_"
            }
        }
    } else {
        Write-Host "Shortcut 'install-nerdfonts' already exists in Profile." -NoNewLine
    }

    $ShouldRun = $All -or (Confirm-Step -Title "Install $(Format-Highlight "[NerdFonts]" -Style BrightMagenta)" `
        -Message "You can now use '$(Format-Highlight "install-nerdfonts -Scope AllUsers" -Style BrightYellow)' to install NerdFonts. Would you like to run this now?" `
        -YesDescription "Runs the command immediately." `
        -NoDescription "Skips this step.")

    if (-not $ShouldRun) {
        Write-Host "Skipped NerdFonts installation." -ForegroundColor Gray
        return
    }

    if ($DryRun) {
        Write-DryRunNotice "run $NerdFontScriptPath -Scope AllUsers"
        return
    }

    try {
        Write-Host "Starting NerdFonts installation..." -ForegroundColor Yellow
        & $NerdFontScriptPath -Scope AllUsers
        if ($LASTEXITCODE -ne 0) {
            throw "NerdFonts installer exited with code $LASTEXITCODE"
        }
    } catch {
        Write-ErrorMsg "NerdFonts installation failed: $_"
    }
}

function Symlink-WindowsTerminalSettings {
    param(
        [switch]$All,
        [switch]$DryRun
    )

    Write-Status "Symbolically Linking Windows Terminal Settings"

    # 1. Ensure unified file exists
    if (-not (Test-Path $WindowsTerminalSettings)) {
        if ($DryRun) {
            Write-DryRunNotice "create file $WindowsTerminalSettings"
        } else {
            New-Item -ItemType File -Force -Path $WindowsTerminalSettings | Out-Null
        }
    }

    # 2. Create Symbolic Link to configuration file
    $CreatedPaths = foreach ($Path in $WindowsTerminalSettingsPaths) {
        if (Test-Path (Split-Path $Path)) {
            if ($DryRun) {
                Write-DryRunNotice "link $Path -> $WindowsTerminalSettings"
                continue
            }

            try {
                if (Test-Path $Path) {
                    Remove-Item $Path -Force -ErrorAction Stop
                }
                Write-Host "Creating SymLink: $(Format-Highlight $Path -Style BrightMagenta) -> $WindowsTerminalSettings..."
                New-Item -ItemType SymbolicLink -Path $Path -Target $WindowsTerminalSettings -ErrorAction Stop | Out-Null
                Start-Sleep -Milliseconds 100
                $Path
            } catch {
                Write-ErrorMsg "Failed to link $Path : $_"
            }
        }
    }

    if ($CreatedPaths) {
        Write-Host "[Windows Terminal 'settings.json' configured at $(Format-Highlight $WindowsTerminalSettings -Style BrightBlue)]" -ForegroundColor Green
    }
}

function Run-ConfigSetup {
    param(
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Status "Running in DRY-RUN mode - no changes will be made."
    }

    $Result = Confirm-Choice -Title "Configuration Installation & Setup" `
        -Message "Would you like to run the installation and setup process?" `
        -ChoiceLabels @("&Yes", "&No", "&All") `
        -ChoiceDescriptions @(
            "Runs the installation and setup process, prompting for each step.",
            "Ends the script.",
            "Runs the full installation and setup process without further prompts."
        )

    if ($Result -eq 1) { return }

    $RunAll = ($Result -eq 2)

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
            Install-WingetPackages -All:$RunAll -DryRun:$DryRun
            $WingetIds = $OriginalWingetIds
        }
        Write-Status "Restart this script from PowerShell 7 to continue."
        return
    }

    Install-WingetPackages -All:$RunAll -DryRun:$DryRun
    Setup-Tools -All:$RunAll -DryRun:$DryRun
    Setup-Dotfiles -All:$RunAll -DryRun:$DryRun
    Symlink-PowerShellProfiles -All:$RunAll -DryRun:$DryRun
    Setup-NerdFonts -All:$RunAll -DryRun:$DryRun
    Symlink-WindowsTerminalSettings -All:$RunAll -DryRun:$DryRun

    Write-Status "Setup Complete!"
    Write-Status "Please restart your terminal (or log out and back in) to ensure all PATH changes take effect."

    if ($DryRun) {
        Write-DryRunNotice "reload the PowerShell profile"
        return
    }

    Write-Host "Reloading powershell profile..." -ForegroundColor Yellow
    Write-Host "PowerShell $($PSVersionTable.PSVersion)"
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew(); . $PROFILE; $Stopwatch.Stop()
    Write-Host "Loading personal and system profiles took $($Stopwatch.ElapsedMilliseconds)ms."
    Write-Host "[Powershell Profile Reloaded]" -ForegroundColor Green -NoNewLine
}

# -----------------------------------------------------------------------------
# Execution Flow
# -----------------------------------------------------------------------------

# Run Configuration Steps
Run-ConfigSetup -DryRun:$DryRun
