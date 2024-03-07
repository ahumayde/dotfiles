# Config Term
C:/Users/ahuma/AppData/Local/Programs/oh-my-posh/bin/oh-my-posh.exe init pwsh --config ~/.config/term/theme.omp.json | Invoke-Expression

# Env Variables
$env:NVIM_INIT_FILE = "$env:USERPROFILE\.config\nvim\init.lua"
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config\"

function Invoke-OhMyPoshInit { & "C:/Users/ahuma/AppData/Local/Programs/oh-my-posh/bin/oh-my-posh.exe" init pwsh --config ~/.config/term/theme.omp.json | Invoke-Expression }

# Alias
Set-Alias vim nvim
Set-Alias omp Invoke-OhMyPoshInit
Set-Alias less 'C:\Program Files\Git\usr\bin\less.exe'
Set-Alias la ls | Format-Wide -Column 4 
Set-Alias ll ls | Format-Wide -Column 4
Set-Alias g git
Set-Alias grep findstr
Set-Alias ls dir | Select-Object @{Name='Mode';Expression={if($_.PSIsContainer) {'Dir       '} else {'File'}}}, Name 
