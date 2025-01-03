# PowerShell Script to Setup Startup Services

# Function to write to a log file
function Write-Log {
    param([string]$Message)
    $logPath = "$env:TEMP\setup_startup_services_log.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logPath -Append
}

try {
    # Create the Scripts directory if it doesn't exist
    if (-not (Test-Path -Path "C:\Scripts")) {
        New-Item -ItemType Directory -Path "C:\Scripts" -Force | Out-Null
        Write-Log "Created C:\Scripts directory"
    } else {
        Write-Log "C:\Scripts directory already exists"
    }

    # Get the current script's directory
    $currentDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

    # Copy the StartupServices.ps1 script
    $sourcePath = Join-Path -Path $currentDir -ChildPath "StartupServices.ps1"
    $destinationPath = "C:\Scripts\StartupServices.ps1"
    
    Copy-Item -Path $sourcePath -Destination $destinationPath -Force
    Write-Log "Copied StartupServices.ps1 to C:\Scripts"

    Write-Log "Setup completed successfully"
} catch {
    Write-Log "An error occurred: $_"
}