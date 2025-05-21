# Comprehensive Windows Maintenance Script with Parallel Execution
# Import RunspacePool for parallel execution
Add-Type -AssemblyName System.Management.Automation

$VerbosePreference = "Continue"
$DebugPreference = "Continue"
$InformationPreference = "Continue"
$ErrorActionPreference = 'Stop'

# Function to get current date and time without using Get-Date
function Get-CurrentDateTime {
    return [System.DateTime]::Now
}

# Function to write to both log file and output stream
function Write-VerboseOutput {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = [System.DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timestamp - [$Level] $Message"
    $logFile = "C:\Scripts\Logs\full_powershell_log.txt"

    try {
        Write-Verbose $logMessage
        Add-Content -Path $logFile -Value $logMessage -ErrorAction Stop
    } catch {
        Write-Warning "Failed to write to log file: $_"
    }
}

Write-VerboseOutput -Message "Starting weekly maintenance tasks" -Level "INFO"
Write-VerboseOutput -Message "PowerShell Version: $($PSVersionTable.PSVersion)" -Level "INFO"
Write-VerboseOutput -Message "PowerShell Edition: $($PSVersionTable.PSEdition)" -Level "INFO"
Write-VerboseOutput -Message "Operating System: $([System.Environment]::OSVersion.VersionString)" -Level "INFO"
Write-VerboseOutput -Message "Current Execution Policy: $(Get-ExecutionPolicy)" -Level "INFO"
Write-VerboseOutput -Message "Running as user: $env:USERNAME" -Level "INFO"
Write-VerboseOutput -Message "Script path: $PSCommandPath" -Level "INFO"

# Test file system access
$testFile = "C:\Scripts\Logs\test.txt"
try {
    "Test" | Out-File -FilePath $testFile -ErrorAction Stop
    Remove-Item -Path $testFile -ErrorAction Stop
    Write-VerboseOutput -Message "Successfully wrote to and removed test file in log directory" -Level "INFO"
} catch {
    Write-VerboseOutput -Message "Error accessing log directory: $_" -Level "ERROR"
}

# Create a runspace pool
$runspacePool = [runspacefactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS * 2)
$runspacePool.Open()

$jobs = @()

# Function to create and invoke a script block in a new runspace
function Start-RunspaceJob {
    param(
        [ScriptBlock]$ScriptBlock,
        [string]$JobName
    )
    $job = [powershell]::Create().AddScript({
        param($ScriptBlock, $JobName, $WriteVerboseOutputScriptBlock)
        
        # Define Write-VerboseOutput function in this scope
        function Write-VerboseOutput {
            param([string]$Message, [string]$Level = "INFO")
            & $WriteVerboseOutputScriptBlock.Invoke($Message, $Level)
        }

        try {
            Write-VerboseOutput -Message "Starting job: $JobName"
            $result = & $ScriptBlock.Invoke($JobName)
            Write-VerboseOutput -Message "Completed job: $JobName"
            Write-VerboseOutput -Message "Job $JobName completed with result: $result"
            return $result
        } catch {
            $errorMessage = $_.Exception.Message
            $errorLineNumber = $_.InvocationInfo.ScriptLineNumber
            Write-VerboseOutput -Message "Error in job $JobName at line $errorLineNumber`: $errorMessage" -Level "ERROR"
            return "Error: $errorMessage"
        }
    }).AddArgument($ScriptBlock).AddArgument($JobName).AddArgument($function:Write-VerboseOutput)
    
    $job.RunspacePool = $runspacePool
    $global:jobs += [PSCustomObject]@{
        Job = $job
        Result = $job.BeginInvoke()
        Name = $JobName
    }
}

try {
    # 0. Create System Restore Point
    Start-RunspaceJob -JobName "SystemRestorePoint" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Creating System Restore Point" -Level "INFO"
        try {
            Write-VerboseOutput -Message "Checking if running with administrator privileges" -Level "INFO"
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
            if (-not $isAdmin) {
                throw "This script must be run as an Administrator"
            }
            
            Write-VerboseOutput -Message "Creating restore point" -Level "INFO"
            Checkpoint-Computer -Description "Weekly Maintenance Restore Point" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Write-VerboseOutput -Message "System Restore Point created successfully" -Level "INFO"
            $result = "System Restore Point created successfully"
        } catch {
            $errorMessage = $_.Exception.Message
            $errorLineNumber = $_.InvocationInfo.ScriptLineNumber
            Write-VerboseOutput -Message "Error creating System Restore Point at line $errorLineNumber`: $errorMessage" -Level "ERROR"
            Write-VerboseOutput -Message "Error Type: $($_.Exception.GetType().FullName)" -Level "ERROR"
            Write-VerboseOutput -Message "Stack Trace: $($_.ScriptStackTrace)" -Level "ERROR"
            $result = "Error: $errorMessage at line $errorLineNumber"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 1. Check Disk for Errors
    Start-RunspaceJob -JobName "DiskCheck" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Checking disk for errors" -Level "INFO"
        $results = @()
        try {
            Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
                $driveLetter = $_.DeviceID.Substring(0,1)
                Write-VerboseOutput -Message "Checking drive $driveLetter" -Level "INFO"
                $repairResult = Repair-Volume -DriveLetter $driveLetter -Scan
                $results += "Drive $driveLetter: $repairResult"
            }
            Write-VerboseOutput -Message "Disk check completed" -Level "INFO"
            $result = "Completed. " + ($results -join "; ")
        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error during disk check: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 2. Clear Temporary Files
    Start-RunspaceJob -JobName "ClearTempFiles" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Clearing temporary files" -Level "INFO"
        $results = @()
        $locations = @(
            "C:\Windows\Temp\*",
            "C:\Windows\Prefetch\*",
            "C:\Documents and Settings\*\Local Settings\temp\*",
            "C:\Users\*\Appdata\Local\Temp\*"
        )
        
        try {
            foreach ($location in $locations) {
                $filesRemoved = (Get-ChildItem -Path $location -Recurse -Force -ErrorAction SilentlyContinue).Count
                Remove-Item -Path $location -Recurse -Force -ErrorAction SilentlyContinue
                $results += "Cleared $filesRemoved items from $location"
                Write-VerboseOutput -Message "Cleared $filesRemoved items from $location" -Level "INFO"
            }
            
            $totalCleared = ($results | ForEach-Object { [int]($_ -split ' ')[1] } | Measure-Object -Sum).Sum
            $result = "Successfully cleared $totalCleared temporary files"
            Write-VerboseOutput -Message "Temporary files cleared" -Level "INFO"
        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error clearing temporary files: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 3. Update and Run Antivirus Scan
    Start-RunspaceJob -JobName "AntivirusScan" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Updating and running antivirus scan" -Level "INFO"
        $results = @()
        
        try {
            # Update virus definitions
            Write-VerboseOutput -Message "Updating virus definitions" -Level "INFO"
            $updateProcess = Start-Process -FilePath "C:\Program Files\Windows Defender\MpCmdRun.exe" -ArgumentList "-SignatureUpdate" -NoNewWindow -Wait -PassThru
            if ($updateProcess.ExitCode -eq 0) {
                $results += "Signature update completed successfully"
            } else {
                $results += "Signature update failed with exit code: $($updateProcess.ExitCode)"
            }

            # Run quick scan
            Write-VerboseOutput -Message "Running quick scan" -Level "INFO"
            $scanProcess = Start-Process -FilePath "C:\Program Files\Windows Defender\MpCmdRun.exe" -ArgumentList "-Scan -ScanType QuickScan" -NoNewWindow -Wait -PassThru
            if ($scanProcess.ExitCode -eq 0) {
                $results += "Quick scan completed successfully"
            } else {
                $results += "Quick scan failed with exit code: $($scanProcess.ExitCode)"
            }

            $result = "Completed. " + ($results -join "; ")
            Write-VerboseOutput -Message "Antivirus update and scan completed" -Level "INFO"
        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error during antivirus update and scan: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 4. SMART Disk Check (Extended)
Start-RunspaceJob -JobName "SMARTDiskCheck" -ScriptBlock {
    param($JobName)
    Write-VerboseOutput -Message "Performing Extended SMART Disk Check" -Level "INFO"
    $results = @()
    $warnings = @()
    
    try {
        $smartData = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus
        $extendedData = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictData

        foreach ($disk in $smartData) {
            $diskName = ($disk.InstanceName -split "\\")[2]
            if ($disk.Active) {
                if ($disk.PredictFailure) {
                    $warningMessage = "Disk $diskName is predicting failure. Reason: $disk.Reason"
                    Write-VerboseOutput -Message "WARNING: $warningMessage" -Level "WARNING"
                    $warnings += $warningMessage
                } else {
                    Write-VerboseOutput -Message "Disk $diskName passed the basic SMART check." -Level "INFO"
                    $results += "Disk $diskName: Passed basic SMART check"
                }

                # Get extended SMART data
                $extendedInfo = $extendedData | Where-Object { $_.InstanceName -eq $disk.InstanceName }
                if ($extendedInfo) {
                    $vendorData = $extendedInfo.VendorSpecific
                    $attributes = @{}
                    for ($i = 0; $i -lt $vendorData.Length; $i += 12) {
                        $id = $vendorData[$i]
                        # Use a subarray approach
                        $valueBytes = [byte[]]$vendorData[$i+5..($i+8)]
                        $value = [BitConverter]::ToUInt32($valueBytes, 0)
                        $attributes[$id] = $value
                    }

                    $reallocatedSectors = if ($attributes.ContainsKey(5)) { $attributes[5] } else { "N/A" }
                    $spinRetryCount = if ($attributes.ContainsKey(10)) { $attributes[10] } else { "N/A" }
                    $currentPendingSectors = if ($attributes.ContainsKey(197)) { $attributes[197] } else { "N/A" }

                    Write-VerboseOutput -Message "Extended SMART data for $diskName:" -Level "INFO"
                    Write-VerboseOutput -Message "  Reallocated Sectors Count: $reallocatedSectors" -Level "INFO"
                    Write-VerboseOutput -Message "  Spin Retry Count: $spinRetryCount" -Level "INFO"
                    Write-VerboseOutput -Message "  Current Pending Sectors: $currentPendingSectors" -Level "INFO"

                    if (($reallocatedSectors -ne "N/A" -and $reallocatedSectors -gt 0) -or 
                        ($spinRetryCount -ne "N/A" -and $spinRetryCount -gt 0) -or 
                        ($currentPendingSectors -ne "N/A" -and $currentPendingSectors -gt 0)) {
                        $warningMessage = "Disk $diskName shows signs of potential issues. Consider further investigation or replacement."
                        Write-VerboseOutput -Message "WARNING: $warningMessage" -Level "WARNING"
                        $warnings += $warningMessage
                    }
                    
                    $results += "Disk $diskName: Reallocated Sectors=$reallocatedSectors, Spin Retry Count=$spinRetryCount, Current Pending Sectors=$currentPendingSectors"
                } else {
                    Write-VerboseOutput -Message "Unable to retrieve extended SMART data for $diskName" -Level "INFO"
                    $results += "Disk $diskName: Unable to retrieve extended SMART data"
                }
            } else {
                Write-VerboseOutput -Message "NOTE: SMART is not active on disk $diskName" -Level "INFO"
                $results += "Disk $diskName: SMART is not active"
            }
        }
        
        Write-VerboseOutput -Message "Extended SMART Disk Check completed" -Level "INFO"
        
        if ($warnings.Count -gt 0) {
            $result = "Completed with warnings. " + ($warnings -join "; ") + "; " + ($results -join "; ")
        } else {
            $result = "Completed successfully. " + ($results -join "; ")
        }
    } catch {
        $errorMessage = $_.Exception.Message
        Write-VerboseOutput -Message "Error performing Extended SMART Disk Check: $errorMessage" -Level "ERROR"
        $result = "Error: $errorMessage"
    }
    
    Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
    return $result
}



    # 5. Disk Space Analysis
    Start-RunspaceJob -JobName "DiskSpaceAnalysis" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Performing Disk Space Analysis" -Level "INFO"
        $results = @()
        $warnings = @()
        
        try {
            $drives = Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
            foreach ($drive in $drives) {
                $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
                $totalSpaceGB = [math]::Round($drive.Size / 1GB, 2)
                $usedSpaceGB = $totalSpaceGB - $freeSpaceGB
                $freeSpacePercent = [math]::Round(($freeSpaceGB / $totalSpaceGB) * 100, 2)
                
                $driveInfo = "Drive $($drive.DeviceID): Total: $totalSpaceGB GB, Used: $usedSpaceGB GB, Free: $freeSpaceGB GB ($freeSpacePercent% free)"
                Write-VerboseOutput -Message $driveInfo -Level "INFO"
                $results += $driveInfo
                
                if ($freeSpacePercent -lt 10) {
                    $warningMessage = "WARNING: Drive $($drive.DeviceID) has less than 10% free space"
                    Write-VerboseOutput -Message $warningMessage -Level "WARNING"
                    $warnings += $warningMessage
                }
                
                # Get top 5 largest files
                $largestFiles = Get-ChildItem -Path $drive.DeviceID -Recurse -ErrorAction SilentlyContinue | 
                                Sort-Object Length -Descending | 
                                Select-Object -First 5 FullName, @{Name="SizeGB";Expression={[math]::Round($_.Length / 1GB, 2)}}
                
                Write-VerboseOutput -Message "Top 5 largest files on drive $($drive.DeviceID):" -Level "INFO"
                $largestFilesInfo = $largestFiles | ForEach-Object { "  $($_.FullName) - $($_.SizeGB) GB" }
                $largestFilesInfo | ForEach-Object { Write-VerboseOutput -Message $_ -Level "INFO" }
                $results += "Largest files on $($drive.DeviceID): " + ($largestFilesInfo -join "; ")
            }
            
            Write-VerboseOutput -Message "Disk Space Analysis completed" -Level "INFO"
            
            if ($warnings.Count -gt 0) {
                $result = "Completed with warnings. " + ($warnings -join "; ") + "; " + ($results -join "; ")
            } else {
                $result = "Completed successfully. " + ($results -join "; ")
            }
        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error during Disk Space Analysis: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 6. System Uptime Report
    Start-RunspaceJob -JobName "SystemUptimeReport" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Checking System Uptime" -Level "INFO"
        $result = ""
        
        try {
            $bootuptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
            $uptime = [System.DateTime]::Now - $bootUpTime
            $uptimeString = "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
            Write-VerboseOutput -Message "System Uptime: $uptimeString" -Level "INFO"
            
            $result = "System has been up for $uptimeString"
            
            if ($uptime.Days -ge 30) {
                $warningMessage = "WARNING: System has been running for more than 30 days. A reboot is recommended."
                Write-VerboseOutput -Message $warningMessage -Level "WARNING"
                $result = "$warningMessage; $result"
            }
        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error checking System Uptime: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 7. Installed Software Audit
    Start-RunspaceJob -JobName "InstalledSoftwareAudit" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Generating Installed Software Audit" -Level "INFO"
        $result = ""
        
        try {
            $installedSoftware = Get-Package | Select-Object Name, Version
            $auditFile = "C:\Scripts\Logs\installed_software_audit.csv"
            $installedSoftware | Export-Csv -Path $auditFile -NoTypeInformation
            
            $softwareCount = ($installedSoftware | Measure-Object).Count
            Write-VerboseOutput -Message "Installed Software Audit saved to $auditFile" -Level "INFO"
            Write-VerboseOutput -Message "Total number of installed software packages: $softwareCount" -Level "INFO"
            
            if (Test-Path $auditFile) {
                $fileSizeKB = [math]::Round((Get-Item $auditFile).Length / 1KB, 2)
                $result = "Audit completed successfully. $softwareCount software packages found. Audit file ($fileSizeKB KB) saved to $auditFile"
            } else {
                $result = "Audit completed, but the output file was not created. $softwareCount software packages found."
            }
        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error generating Installed Software Audit: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 8. Network Configuration Backup
    Start-RunspaceJob -JobName "NetworkConfigBackup" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Backing up Network Configuration" -Level "INFO"
        $result = ""
        $backupResults = @()
        
        try {
            $backupPath = "C:\Scripts\Logs\NetworkConfigBackup"
            if (-not (Test-Path $backupPath)) {
                New-Item -ItemType Directory -Path $backupPath | Out-Null
                Write-VerboseOutput -Message "Created backup directory: $backupPath" -Level "INFO"
            }

            # Backup IP Configuration
            $ipConfigFile = "$backupPath\ipconfig_backup.txt"
            ipconfig /all | Out-File $ipConfigFile
            if (Test-Path $ipConfigFile) {
                $backupResults += "IP Configuration backup successful"
            } else {
                $backupResults += "Failed to create IP Configuration backup"
            }

            # Backup Wi-Fi Profiles
            $wifiProfileFile = "$backupPath\wifi_profiles_backup.txt"
            netsh wlan show profiles | Out-File $wifiProfileFile
            if (Test-Path $wifiProfileFile) {
                $backupResults += "Wi-Fi Profiles backup successful"
            } else {
                $backupResults += "Failed to create Wi-Fi Profiles backup"
            }

            # Backup Network Adapters Configuration
            $netAdapterFile = "$backupPath\network_adapters_backup.csv"
            Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed | 
                Export-Csv $netAdapterFile -NoTypeInformation
            if (Test-Path $netAdapterFile) {
                $backupResults += "Network Adapters Configuration backup successful"
            } else {
                $backupResults += "Failed to create Network Adapters Configuration backup"
            }

            $totalSizeKB = (Get-ChildItem $backupPath | Measure-Object -Property Length -Sum).Sum / 1KB
            $totalSizeKB = [math]::Round($totalSizeKB, 2)

            Write-VerboseOutput -Message "Network Configuration backed up to $backupPath" -Level "INFO"
            $result = "Backup completed. Total backup size: $totalSizeKB KB. " + ($backupResults -join "; ")
        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error during Network Configuration Backup: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 9. Event Log Analysis
    Start-RunspaceJob -JobName "EventLogAnalysis" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Analyzing Event Logs" -Level "INFO"
        $result = ""
        
        try {
            $startTime = [System.DateTime]::Now.AddDays(-7)  # Look at last 7 days
            $criticalEvents = Get-WinEvent -FilterHashtable @{
                LogName='System','Application'
                Level=1,2  # Critical and Error levels
                StartTime=$startTime
            } -ErrorAction SilentlyContinue

            if ($criticalEvents) {
                $eventSummary = $criticalEvents | Group-Object -Property Id, LogName | 
                    Select-Object Count, @{Name='EventID';Expression={$_.Group[0].Id}}, 
                    @{Name='LogName';Expression={$_.Group[0].LogName}}, 
                    @{Name='Message';Expression={$_.Group[0].Message}}

                $summaryFile = "C:\Scripts\Logs\critical_events_summary.csv"
                $eventSummary | Export-Csv $summaryFile -NoTypeInformation

                if (Test-Path $summaryFile) {
                    $fileSizeKB = [math]::Round((Get-Item $summaryFile).Length / 1KB, 2)
                    Write-VerboseOutput -Message "Found $($criticalEvents.Count) critical events. Summary exported to $summaryFile" -Level "INFO"
                    $result = "Analysis completed. Found $($criticalEvents.Count) critical events. Summary file ($fileSizeKB KB) exported to $summaryFile"
                    
                    $top5Events = $eventSummary | Sort-Object Count -Descending | Select-Object -First 5
                    $result += "`nTop 5 most frequent critical events:"
                    foreach ($event in $top5Events) {
                        $result += "`n- EventID: $($event.EventID), Count: $($event.Count), LogName: $($event.LogName)"
                    }
                } else {
                    $result = "Analysis completed. Found $($criticalEvents.Count) critical events, but failed to create summary file."
                }
            } else {
                Write-VerboseOutput -Message "No critical events found in the last 7 days" -Level "INFO"
                $result = "Analysis completed. No critical events found in the last 7 days."
            }
        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error during Event Log Analysis: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 10. Performance Baseline
    Start-RunspaceJob -JobName "PerformanceBaseline" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Collecting Performance Baseline" -Level "INFO"
        $result = ""
        
        try {
            $cpu = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
            $memory = Get-WmiObject Win32_OperatingSystem | Select-Object @{Name = "MemoryUsage"; Expression = {"{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize)}}
            $disk = Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object DeviceID, @{Name="UsedSpace";Expression={"{0:N2}" -f ((($_.Size - $_.FreeSpace) / $_.Size) * 100)}}

            $performanceData = [PSCustomObject]@{
                Date = [System.DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
                CPUUsage = $cpu
                MemoryUsage = $memory.MemoryUsage
                DiskUsage = ($disk | ForEach-Object { "$($_.DeviceID)=$($_.UsedSpace)%" }) -join ';'
            }

            $baselinePath = "C:\Scripts\Logs\performance_baseline.csv"
            $performanceData | Export-Csv -Path $baselinePath -Append -NoTypeInformation
            Write-VerboseOutput -Message "Performance baseline collected and appended to $baselinePath" -Level "INFO"

            $result = "Current Performance Baseline: CPU Usage=$($cpu)%, Memory Usage=$($memory.MemoryUsage)%, Disk Usage: $($performanceData.DiskUsage)"

            # Compare with previous baseline
            $previousBaselines = Import-Csv -Path $baselinePath
            if ($previousBaselines.Count -gt 1) {
                $previousBaseline = $previousBaselines[-2]  # Get the second-last entry
                $cpuDiff = [math]::Round($cpu - [double]$previousBaseline.CPUUsage, 2)
                $memoryDiff = [math]::Round([double]$performanceData.MemoryUsage - [double]$previousBaseline.MemoryUsage, 2)

                Write-VerboseOutput -Message "Performance comparison with previous baseline:" -Level "INFO"
                Write-VerboseOutput -Message "  CPU Usage change: $cpuDiff%" -Level "INFO"
                Write-VerboseOutput -Message "  Memory Usage change: $memoryDiff%" -Level "INFO"

                $result += "`nComparison with previous baseline: CPU change=$cpuDiff%, Memory change=$memoryDiff%"

                if ($cpuDiff -gt 10 -or $memoryDiff -gt 10) {
                    $warningMessage = "WARNING: Significant increase in resource usage detected."
                    Write-VerboseOutput -Message $warningMessage -Level "WARNING"
                    $result += "`n$warningMessage"
                }
            } else {
                $result += "`nNo previous baseline available for comparison."
            }

            if (Test-Path $baselinePath) {
                $fileSizeKB = [math]::Round((Get-Item $baselinePath).Length / 1KB, 2)
                $result += "`nBaseline data appended to $baselinePath (File size: $fileSizeKB KB)"
            } else {
                $result += "`nFailed to create or update the baseline file."
            }

        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error collecting Performance Baseline: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 11. Scheduled Task Audit
    Start-RunspaceJob -JobName "ScheduledTaskAudit" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Auditing Scheduled Tasks" -Level "INFO"
        $result = ""
        
        try {
            $tasks = Get-ScheduledTask | Where-Object {$_.TaskPath -notlike "\Microsoft*"} | 
                Select-Object TaskName, TaskPath, State, 
                @{Name="LastRunTime";Expression={$_.LastRunTime.ToString("yyyy-MM-dd HH:mm:ss")}}, 
                @{Name="LastTaskResult";Expression={$_.LastTaskResult}}

            $auditFile = "C:\Scripts\Logs\scheduled_tasks_audit.csv"
            $tasks | Export-Csv -Path $auditFile -NoTypeInformation

            $totalTasks = $tasks.Count
            $runningTasks = ($tasks | Where-Object {$_.State -eq "Running"}).Count
            $readyTasks = ($tasks | Where-Object {$_.State -eq "Ready"}).Count
            $disabledTasks = ($tasks | Where-Object {$_.State -eq "Disabled"}).Count

            Write-VerboseOutput -Message "Scheduled Tasks audit completed. Results saved to $auditFile" -Level "INFO"
            Write-VerboseOutput -Message "Total non-Microsoft scheduled tasks: $totalTasks" -Level "INFO"
            
            if (Test-Path $auditFile) {
                $fileSizeKB = [math]::Round((Get-Item $auditFile).Length / 1KB, 2)
                $result = "Audit completed successfully. "
                $result += "Total non-Microsoft scheduled tasks: $totalTasks. "
                $result += "Running: $runningTasks, Ready: $readyTasks, Disabled: $disabledTasks. "
                $result += "Audit file ($fileSizeKB KB) saved to $auditFile. "
                
                $thirtyDaysAgo = [System.DateTime]::Now.AddDays(-30)
                $oldTasks = $tasks | Where-Object { $_.LastRunTime -ne $null -and [DateTime]::Parse($_.LastRunTime) -lt $thirtyDaysAgo }
                if ($oldTasks) {
                    $result += "Tasks not run in last 30 days: $($oldTasks.Count). "
                    $result += "Top 5 oldest tasks: "
                    $result += ($oldTasks | Sort-Object LastRunTime | Select-Object -First 5 | ForEach-Object { "$($_.TaskName) (Last run: $($_.LastRunTime))" }) -join ", "
                } else {
                    $result += "All tasks have run within the last 30 days."
                }
            } else {
                $result = "Audit completed, but the output file was not created. Total non-Microsoft scheduled tasks: $totalTasks"
            }
        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error during Scheduled Task Audit: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 12. System File Verification
    Start-RunspaceJob -JobName "SystemFileVerification" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Performing System File Verification" -Level "INFO"
        $result = ""
        $issues = @()
        
        try {
            $dismLog = "C:\Scripts\Logs\DISM_CheckHealth.log"
            $sfcLog = "C:\Scripts\Logs\SFC_Scan.log"
            $chkdskLog = "C:\Scripts\Logs\CHKDSK_Scan.log"

            # Run CHKDSK
            Write-VerboseOutput -Message "Running CHKDSK..." -Level "INFO"
            $chkdskOutput = & chkdsk C: /scan /forceofflinefix /perf
            $chkdskOutput | Out-File -FilePath $chkdskLog
            if ($LASTEXITCODE -eq 0) {
                Write-VerboseOutput -Message "CHKDSK completed successfully. No issues found." -Level "INFO"
                $result += "CHKDSK: No issues found. "
            } else {
                Write-VerboseOutput -Message "WARNING: CHKDSK found issues. Check $chkdskLog for details." -Level "WARNING"
                $result += "CHKDSK: Issues found. "
                $issues += "CHKDSK found issues"
            }

            # Run DISM
            Write-VerboseOutput -Message "Running DISM check..." -Level "INFO"
            Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Cleanup-Image /CheckHealth /LogPath:$dismLog" -NoNewWindow -Wait

            if (Select-String -Path $dismLog -Pattern "No component store corruption detected." -Quiet) {
                Write-VerboseOutput -Message "DISM check completed. No corruption detected." -Level "INFO"
                $result += "DISM: No corruption detected. "
            } else {
                Write-VerboseOutput -Message "DISM found issues. Attempting repair..." -Level "INFO"
                Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth /LogPath:$dismLog" -NoNewWindow -Wait
                
                if (Select-String -Path $dismLog -Pattern "The restore operation completed successfully." -Quiet) {
                    Write-VerboseOutput -Message "DISM repair completed successfully." -Level "INFO"
                    $result += "DISM: Issues found and repaired. "
                } else {
                    Write-VerboseOutput -Message "WARNING: DISM repair might not have fixed all issues. Check $dismLog for details." -Level "WARNING"
                    $result += "DISM: Issues found, repair incomplete. "
                    $issues += "DISM repair incomplete"
                }
            }

            # Run SFC
            Write-VerboseOutput -Message "Running SFC scan..." -Level "INFO"
            Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow /LogFile:$sfcLog" -NoNewWindow -Wait

            if (Select-String -Path $sfcLog -Pattern "found no integrity violations" -Quiet) {
                Write-VerboseOutput -Message "SFC scan completed. No integrity violations found." -Level "INFO"
                $result += "SFC: No integrity violations found. "
            } else {
                Write-VerboseOutput -Message "SFC found and attempted to repair issues. Check $sfcLog for details." -Level "INFO"
                $result += "SFC: Issues found and repair attempted. "
                $issues += "SFC found integrity violations"
            }

            if ($issues.Count -eq 0) {
                $result = "All checks passed. " + $result
            } else {
                $result = "Issues detected: " + ($issues -join ", ") + ". " + $result
            }

            $logFiles = @($chkdskLog, $dismLog, $sfcLog)
            $logSizes = $logFiles | ForEach-Object {
                if (Test-Path $_) {
                    $size = [math]::Round((Get-Item $_).Length / 1KB, 2)
                    "$((Get-Item $_).Name) ($size KB)"
                } else {
                    "$((Get-Item $_).Name) (not created)"
                }
            }
            $result += "Log files: " + ($logSizes -join ", ") + "."

            Write-VerboseOutput -Message "System File Verification completed. $result" -Level "INFO"
        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error during System File Verification: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # 13. Pending Reboot Check
    Start-RunspaceJob -JobName "PendingRebootCheck" -ScriptBlock {
        param($JobName)
        Write-VerboseOutput -Message "Checking for Pending Reboot" -Level "INFO"
        $result = ""
        $pendingReboot = $false
        $reasons = @()
        $checkResults = @()

        try {
            # Check Component-Based Servicing
            $cbsCheck = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore
            if ($cbsCheck) {
                $pendingReboot = $true
                $reasons += "Component-Based Servicing"
            }
            $checkResults += "Component-Based Servicing: $($cbsCheck -ne $null)"

            # Check Windows Update
            $wuCheck = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore
            if ($wuCheck) {
                $pendingReboot = $true
                $reasons += "Windows Update"
            }
            $checkResults += "Windows Update: $($wuCheck -ne $null)"

            # Check Pending File Rename Operations
            $pfrCheck = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore
            if ($pfrCheck) {
                $pendingReboot = $true
                $reasons += "Pending File Rename"
            }
            $checkResults += "Pending File Rename: $($pfrCheck -ne $null)"

            # Check if a reboot is pending from a system restart
            $systemRestart = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty RebootPending
            if ($systemRestart) {
                $pendingReboot = $true
                $reasons += "System Restart"
            }
            $checkResults += "System Restart: $systemRestart"

            if ($pendingReboot) {
                $warningMessage = "WARNING: System pending reboot. Reasons: $($reasons -join ', ')"
                Write-VerboseOutput -Message $warningMessage -Level "WARNING"
                $result = "Reboot Required. $warningMessage"
            } else {
                Write-VerboseOutput -Message "No pending reboot detected." -Level "INFO"
                $result = "No reboot required."
            }

            $result += " Detailed results: " + ($checkResults -join "; ") + "."

            $bootUpTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
            $uptime = [System.DateTime]::Now - $bootUpTime
            $uptimeString = "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
            $result += " Current system uptime: $uptimeString."

        } catch {
            $errorMessage = $_.Exception.Message
            Write-VerboseOutput -Message "Error checking for Pending Reboot: $errorMessage" -Level "ERROR"
            $result = "Error: $errorMessage"
        }
        
        Write-VerboseOutput -Message "Job $JobName completed with result: $result" -Level "INFO"
        return $result
    }

    # Wait for all jobs to complete
    $timeout = New-TimeSpan -Minutes 30
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($jobs.Result.IsCompleted -contains $false) {
        if ($stopwatch.Elapsed -gt $timeout) {
            Write-VerboseOutput -Message "Timeout reached. Some jobs did not complete." -Level "WARNING"
            break
        }
        Start-Sleep -Seconds 1
    }

    # Process the results
    foreach ($job in $jobs) {
        try {
            $result = $job.Job.EndInvoke($job.Result)
            Write-VerboseOutput -Message "Job $($job.Name) completed. Output: $result" -Level "INFO"
        } catch {
            Write-VerboseOutput -Message "Error occurred while processing job $($job.Name): $_" -Level "ERROR"
        } finally {
            $job.Job.Dispose()
        }
    }

    # Clean up
    $runspacePool.Close()
    $runspacePool.Dispose()

    # Maintenance Summary
    Write-VerboseOutput -Message "Generating Maintenance Summary" -Level "INFO"
    try {
        $logFolder = "C:\Scripts\Logs"
        $logFile = Join-Path -Path $logFolder -ChildPath "weekly_maintenance_log.txt"
        $summaryFile = Join-Path -Path $logFolder -ChildPath "maintenance_summary.txt"
        $criticalFindings = @()

        if (-not (Test-Path -Path $logFile)) {
            throw "Log file not found: $logFile"
        }

        $logContent = Get-Content -Path $logFile -ErrorAction Stop

        foreach ($line in $logContent) {
            if ($line -match "WARNING:|Error|CRITICAL|failed|corruption") {
                $criticalFindings += $line
            }
        }

        $summary = @"
==== Windows Maintenance Summary ====
Date: $((Get-CurrentDateTime).ToString("yyyy-MM-dd HH:mm:ss"))

Total Jobs Executed: $($jobs.Count)
Total Critical Findings: $($criticalFindings.Count)

Critical Findings and Warnings:
$($criticalFindings | ForEach-Object { "- $_" } | Out-String)

Please review the full log at $logFile for more details.
"@

        $summary | Out-File -FilePath $summaryFile -ErrorAction Stop
        Write-VerboseOutput -Message "Maintenance Summary generated and saved to $summaryFile" -Level "INFO"

        if ($criticalFindings.Count -gt 0) {
            Write-VerboseOutput -Message "WARNING: $($criticalFindings.Count) critical findings or warnings were detected during maintenance." -Level "WARNING"
        } else {
            Write-VerboseOutput -Message "No critical findings or warnings were detected during maintenance." -Level "INFO"
        }
    } catch {
        Write-VerboseOutput -Message "Error generating Maintenance Summary: $_" -Level "ERROR"
        Write-VerboseOutput -Message "Log folder: $logFolder" -Level "ERROR"
        Write-VerboseOutput -Message "Log file path: $logFile" -Level "ERROR"
        Write-VerboseOutput -Message "Summary file path: $summaryFile" -Level "ERROR"
    }

    Write-VerboseOutput -Message "Weekly maintenance tasks and summary completed" -Level "INFO"
    Write-VerboseOutput -Message "Script execution completed. Total jobs: $($jobs.Count)" -Level "INFO"

    # Final cleanup
    $Error.Clear()
    [System.GC]::Collect()

    # Output full log content
    $fullLogPath = "C:\Scripts\Logs\full_powershell_log.txt"
    if (Test-Path $fullLogPath) {
        Write-VerboseOutput -Message "Outputting full log content:" -Level "INFO"
        Get-Content $fullLogPath | ForEach-Object { Write-VerboseOutput -Message $_ -Level "INFO" }
    } else {
        Write-VerboseOutput -Message "Full log file not found at $fullLogPath" -Level "WARNING"
    }
} catch {
    $errorMessage = $_.Exception.Message
    $errorLineNumber = $_.InvocationInfo.ScriptLineNumber
    Write-VerboseOutput -Message "Critical error in main script at line $errorLineNumber`: $errorMessage" -Level "ERROR"
    Write-VerboseOutput -Message "Error Type: $($_.Exception.GetType().FullName)" -Level "ERROR"
    Write-VerboseOutput -Message "Stack Trace: $($_.ScriptStackTrace)" -Level "ERROR"
} finally {
    if ($runspacePool) {
        $runspacePool.Close()
        $runspacePool.Dispose()
    }
    
    $fullLogPath = "C:\Scripts\Logs\full_powershell_log.txt"
    if (Test-Path $fullLogPath) {
        Write-VerboseOutput -Message "Outputting full log content:" -Level "INFO"
        Get-Content $fullLogPath | ForEach-Object { Write-VerboseOutput -Message $_ -Level "INFO" }
    } else {
        Write-VerboseOutput -Message "Full log file not found at $fullLogPath" -Level "WARNING"
    }
}
