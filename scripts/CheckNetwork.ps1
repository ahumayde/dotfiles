## --- Set the target websites you want to monitor here ---
$targetWebsites = "www.tcgcollector.com", "www.google.com"

# --- Automatically resolve their IP addresses below ---
Write-Host "Resolving IP addresses for target websites..." -ForegroundColor Cyan
Write-Host "Target Websites: {$targetWebsites}" -ForegroundColor Gray

# --- Resolve the hostname and add its IP addresses to our target list ---
foreach ($website in $targetWebsites) {
    try {
        $resolvedIPs = Resolve-DnsName -Name $website -ErrorAction Stop | Select-Object -ExpandProperty IPAddress
        $targetIPs += $resolvedIPs
        Write-Host "  [OK] Resolved '$website' to: $($resolvedIPs -join ', ')" -ForegroundColor Green
    }
    catch {
        Write-Warning "  [FAIL] Could not resolve '$website'."
    }
}

# --- Remove any duplicate IPs if multiple sites use the same address ---
$targetIPs = $targetIPs | Select-Object -Unique

# --- Exit if we couldn't resolve any of the websites --- 
if ($targetIPs.Count -eq 0) {
    Write-Error "Could not resolve any target websites. Exiting script."
    return
}

Write-Host "---------------------------------------------------------"
Write-Host "Silently monitoring for connections to the resolved IPs..." -ForegroundColor Green
Write-Host "Output will only appear when a connection is detected. Press Ctrl+C to stop."
Write-Host "---------------------------------------------------------"

# --- Display network connections to target IPs
while ($true) {
    # Check for connections to any of the target IPs, suppressing errors if none are found
    $connections = Get-NetTCPConnection -RemoteAddress $targetIPs -ErrorAction SilentlyContinue

    # If a connection was found, process and display it
    if ($connections) {
        $timestamp = "$(Get-Date)"
        Write-Host "--- Connection detected at $timestamp ---" -ForegroundColor Yellow
        
        # Format the output with the process name and display it fully
        $connections | Select-Object LocalPort, RemoteAddress, State, @{Name="ProcessName";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} | Format-Table -AutoSize
        
        # Pause briefly to avoid re-logging the same connection instantly
        Start-Sleep -Milliseconds 500
    }
    
    # Check frequently for new connections
    Start-Sleep -Milliseconds 100
}
