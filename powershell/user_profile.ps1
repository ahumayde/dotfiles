<# .SYNOPSIS
   Powershell Profile
#>

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

# Globals
$CONFIG = "$PROFILE"

# ANSI File Colours 
$PSStyle.FileInfo.Directory    = "`e[94m"
$PSStyle.FileInfo.Executable   = "`e[93m"
$PSStyle.FileInfo.SymbolicLink = "`e[38;5;99m"

# Neovim Configs
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config\"
$env:NVIM_INIT_FILE = "$env:USERPROFILE\.config\nvim\init.lua"
$NVIM_CONFIG = "$env:USERPROFILE\.config\nvim\init.lua"


# -----------------------------------------------------------------------------
# Function Declarations
# -----------------------------------------------------------------------------

function install-nerdfonts {
    & 'C:\Users\ahuma\.config\scripts\Invoke-NerdFontInstaller.ps1' @args
}

function Invoke-OhMyPoshInit { 
    & oh-my-posh init pwsh --config ~/.config/term/theme.omp.json | Invoke-Expression 
}

function nvim-kickstart { 
    $env:NVIM_APPNAME="nvim-kickstart"
    nvim $args
}

function nvim-personal {
    $env:NVIM_APPNAME="nvim-personal"
    nvim $args
}

function ls-less { 
    $mode = "`t`tMode`t`t"
    $file = "`t`tFile`t`t"
    $dir  = "`t`tDir `t`t"
    Get-ChildItem `
    | Select-Object @{ Name=$mode; Expression={ if ($_.PSIsContainer) {$dir} else {$file} } }, Name `
    | &  "less.exe"
}

function ls-simple {
    $items = Get-ChildItem | Sort-Object @{Expression = { $_.PSIsContainer -notlike $true }}, @{Expression = { $_.Name }}
    $items | ForEach-Object {
        if ($_.PSIsContainer) { 
            if ($_.Name -like '.*') {
                Write-Host                "  `e[38;5;99m.Dir       $($_.Name)   "
            } else {
                Write-Host -ForegroundColor DarkBlue "   Dir       $($_.Name)   "
            }
        } else { 
            if ($_.Name -like '.*') {
                Write-Host -ForegroundColor DarkGray "  .File      $($_.Name)   "
            } else {
                Write-Host -ForegroundColor White    "   File      $($_.Name)   "
            }
        } 
    }
    Write-Host
}


# -----------------------------------------------------------------------------
# Execution Flow
# -----------------------------------------------------------------------------

# Oh My Posh Init
Invoke-OhMyPoshInit


# -----------------------------------------------------------------------------
# Aliasses
# -----------------------------------------------------------------------------

# Misstypes
Set-Alias celar clear
Set-Alias g git

# Oh My Posh
Set-Alias omp oh-my-posh
Set-Alias ompi Invoke-OhMyPoshInit

# Unix Commands
Set-Alias ll ls-less
Set-Alias lw dir | Format-Wide -Column 4 
# Set-Alias ll dir | Format-Table Name -AutoSize
