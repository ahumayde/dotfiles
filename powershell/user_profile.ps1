oh-my-posh init pwsh --config ~/.config/term/theme.omp.json | Invoke-Expression

# Alias
Set-Alias vim nvim
Set-Alias less 'C:\Program Files\Git\usr\bin\less.exe'
Set-Alias la ls | Format-Wide -Column 4 
Set-Alias ll ls | Format-Wide -Column 4
Set-Alias g git
Set-Alias grep findstr
Set-Alias ls dir | Select-Object @{Name='Mode';Expression={if($_.PSIsContainer) {'Dir       '} else {'File'}}}, Name 
