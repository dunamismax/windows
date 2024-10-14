# Silent PowerShell Script to Start Services at Startup

# Function to write to a log file
function Write-Log {
    param([string]$Message)
    $logPath = "$env:TEMP\startup_services_log.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logPath -Append
}

$services = @(
    "Datto RMM",
    "CagService",
    "SQL Server (MSSQLSERVER)",
    "OpalRad ImageServer",
    "OpalRad Dicom Print",
    "OpalRad DICOM Receive",
    "OpalRad Listener",
    "OpalRad Router",
    "Opal Agent",
    "Opal Backup",
    "OpalRad Modality Worklist",
    "World Wide Web Publishing Service",
    "Code42 CrashPlan Backup Service"
)

foreach ($service in $services) {
    try {
        $result = Start-Service -Name $service -ErrorAction Stop
        Write-Log "Started service: $service"
    } catch {
        Write-Log "Failed to start service: $service. Error: $_"
    }
}

Write-Log "Service startup script completed."