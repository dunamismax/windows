# PowerShell Script to Create Startup Task

# Function to write to a log file
function Write-Log {
    param([string]$Message)
    $logPath = "$env:TEMP\create_startup_task_log.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logPath -Append
}

try {
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Scripts\StartupServices.ps1"
    
    $trigger = New-ScheduledTaskTrigger -AtStartup
    
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings
    
    Register-ScheduledTask -TaskName "Start Services at Startup" -InputObject $task -Force
    
    Write-Log "Scheduled task created successfully."
} catch {
    Write-Log "An error occurred while creating the scheduled task: $_"
}