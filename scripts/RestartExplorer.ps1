# RestartExplorer.ps1

param (
    [string]$targetExePath = "C:\Users\ahuma\AppData\Local\Vivaldi\Application\vivaldi.exe",
    [string]$iconFilePath  = "C:\Users\ahuma\AppData\Local\Vivaldi\Application\icon_128.ico"
)

# Start-Process -FilePath ".\IconReplacer\bin\Release\net8.0\IconReplacer.exe" -ArgumentList $targetExePath, $iconFilePath -NoNewWindow -Wait

# Function to restart Windows Explorer
function Restart-Explorer {
    # Stop the explorer process
    Stop-Process -Name explorer -Force

    # Wait to ensure process stopped 
    Start-Sleep -Seconds 2

    # Remove icon cache
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*" -Force

    # Start the explorer process
    Start-Process explorer
}

# Execute the function
Restart-Explorer

Write-Output "Explorer has been restarted successfully."
