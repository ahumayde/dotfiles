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

    # Start the explorer process
    Start-Process explorer
}

# Execute the function
Restart-Explorer

Write-Output "Explorer has been restarted successfully."
