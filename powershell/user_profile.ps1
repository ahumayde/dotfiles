# Config Term
oh-my-posh init pwsh --config ~/.config/term/theme.omp.json | Invoke-Expression

# Environment Variables
$env:NVIM_INIT_FILE = "$env:USERPROFILE\.config\nvim\init.lua"
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config\"
# $env:NVIM_RUNTIME_DIR = "$env:USERPROFILE\.config\nvim"
# $PROFILE = "$env:USERPROFILE\.config\powershell\user_profile.ps1"

# Functions
function Invoke-OhMyPoshInit { & oh-my-posh init pwsh --config ~/.config/term/theme.omp.json | Invoke-Expression }

# function Get-UnixLikeDirectoryListing {
#     $output = @()
#     $items = Get-ChildItem | Sort-Object @{Expression = { $_.PSIsContainer -notlike $true }}, @{Expression = { $_.Name }}
#     $maxNameLength = ($items | Measure-Object -Property Name -Maximum).Maximum.Length
#
#     $items | ForEach-Object {
#         if ($_.PSIsContainer) { 
#             if ($_.Name -like '.*') {
#             } else {
#             }
#         } else { 
#             if ($_.Name -like '.*') {
                # $output += "`e[38;5;99m       .Dir       $($_.Name)" 
                # $output += "`e[94;0001m        Dir       $($_.Name)" 
                # $output += "`e[90;0001m       .File      $($_.Name)" 
                # $output += "`e[37;0001m        File      $($_.Name)" 
#             } else {
#             }
#         } 
#     }
#     $output# | Format-Table -AutoSize
# }
# function Get-UnixLikeDirectoryListing {
#     $items = Get-ChildItem | Sort-Object @{Expression = { $_.PSIsContainer -notlike $true }}, @{Expression = { $_.Name }}
#     $items | ForEach-Object {
#         if ($_.PSIsContainer) { 
        #     if ($_.Name -like '.*') {
        #         Write-Host                "  `e[38;5;99m.Dir       $($_.Name)   "
        #     } else {
        #         Write-Host -ForegroundColor DarkCyan "   Dir       $($_.Name)   "
        #     }
        # } else { 
        #     if ($_.Name -like '.*') {
        #         Write-Host -ForegroundColor DarkGray "  .File      $($_.Name)   "
        #     } else {
        #         Write-Host -ForegroundColor White    "   File      $($_.Name)   "
        #     }
#         } 
#     }
#     Write-Host
# }
function Set-Colour {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [Alias("InputObject")]
        $Item
    )

    $ItemType = $Item.GetType().Name
    $ItemName = $Item.Name

    switch -Wildcard ($ItemType) {
        'DirectoryInfo' { # Directory
            if ($_.Name -like '.*') {
                return "`e[38;5;99m .Dir       $ItemName" 
            } else {
                return "`e[94;0001m  Dir       $ItemName" 
            }
        }
        'FileInfo' { # Regular file
            if ($_.Name -like '.*') {
                return "`e[90;0001m .File      $ItemName" 
            } else {
                return "`e[37;0001m  File      $ItemName" 
            }
        }
        'SymbolicLinkInfo' { # Symbolic link
                return "`e[35;0001m  SymLink   $ItemName"
        }
        'DirectoryLinkInfo' { # Directory symbolic link
                return "`e[35;0001m  DirLink   $ItemName"
        }
        default { # Unknown or unsupported type
                return "`e[33;0001m  Unknown   $ItemName"
        }
    }
}

function Get-UnixLikeDirectoryListing {
    $items = Get-ChildItem | Sort-Object @{Expression = { $_.PSIsContainer -notlike $true }}, @{Expression = { $_.Name }}
    $itemCount = $items.Count
    $itemsPerColumn = [math]::Ceiling($itemCount / 2)

    $column1 = $items[0..($itemsPerColumn - 1)]
    $column2 = $items[$itemsPerColumn..($itemCount - 1)]

    for ($i = 0; $i -lt $itemsPerColumn; $i++) {
        $item1 = $column1[$i]
        $item2 = $column2[$i]

        $formatString = "{0,-40}{1,-40}"
        Set-LS-Colours -Item $item1
        $output = $formatString -f ($item1 | Set-Colour), ($item2 | Set-Colour)

        # Write-Host $output
    }

    # Write-Host
}

# Alias
Set-Alias vim nvim
Set-Alias omp oh-my-posh
Set-Alias ompi Invoke-OhMyPoshInit
Set-Alias less 'C:\Users\AHumayde\AppData\Local\Programs\Git\usr\bin\less.exe'
# Set-Alias ll ls | ForEach-Object { $_ -replace '\e\[\d+m' } | Format-Wide -Column 4
Set-Alias la dir | Format-Wide -Column 4 
Set-Alias ll dir | Format-Table Name -AutoSize
Set-Alias g git
Set-Alias pip pip3
Set-Alias touch New-Item
Set-Alias grep findstr
Set-Alias ls Get-UnixLikeDirectoryListing
