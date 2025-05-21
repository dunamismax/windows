<#
    Swiss Army Knife Toolkit for Windows
    ======================================
    This PowerShell script provides an interactive, Nord–themed, menu–driven
    toolkit designed for Windows 10/11 sysadmins, pentesters, and security/network professionals.

    Features include:
      • A main menu broken into submenus for:
          - System Tools
          - Networking Tools
          - Security Tools
          - Software Installation Tools
          - Miscellaneous Tools
      • Logging of all events to a log file located in the script directory.
      • Nord–themed color output throughout (using built–in colors approximating the Nord palette).
      • Functions for installing Python, Chocolatey, VSCode; uninstalling software;
        checking system info, Windows Update, network configuration, firewall status,
        antivirus operations, disk cleanup, and system restart.
      • Consistent navigation using 'm' to return to the main menu and 'q' to quit.

    Author: dunamismax
    Date: 2025-02-10

    Note: Before running this script in an elevated PowerShell session, set:
          Set-ExecutionPolicy Unrestricted -Force
#>

#region Global Variables & Logging
# The directory where the script is located.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Path to the log file (in the same directory as the script).
$LogFile = Join-Path $ScriptDir "swiss_army_toolkit.log"

# Writes a log entry with a timestamp to the log file.
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp  $message"
    Add-Content -Path $LogFile -Value $entry
}
#endregion

#region Nord-Themed Output Functions
# These functions provide colored console output and log the messages.
function Write-NordInfo {
    param([string]$message)
    Write-Host $message -ForegroundColor Cyan
    Write-Log "INFO: $message"
}

function Write-NordSuccess {
    param([string]$message)
    Write-Host $message -ForegroundColor Green
    Write-Log "SUCCESS: $message"
}

function Write-NordWarning {
    param([string]$message)
    Write-Host $message -ForegroundColor Yellow
    Write-Log "WARNING: $message"
}

function Write-NordError {
    param([string]$message)
    Write-Host $message -ForegroundColor Red
    Write-Log "ERROR: $message"
}
#endregion

#region Helper: Return to Main Menu or Quit
# Prompts the user to return to the main menu ("m") or quit ("q").
function Prompt-Return {
    Write-NordInfo "Press 'm' to return to the Main Menu or 'q' to quit."
    $choice = Read-Host "Enter your choice"
    if ($choice -eq "m") { Show-MainMenu }
    elseif ($choice -eq "q") { Write-NordInfo "Exiting the toolkit. Goodbye!"; exit }
    else { Show-MainMenu }
}
#endregion

#region System Tools
#===========================================================================
# Function: Show-SystemInformation
# Purpose : Retrieves and displays detailed system information.
#===========================================================================
function Show-SystemInformation {
    Write-NordInfo "Gathering detailed system information..."

    try {
        # Retrieve system, OS, BIOS, and processor data using CIM.
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $operatingSystem  = Get-CimInstance -ClassName Win32_OperatingSystem  -ErrorAction Stop
        $bios             = Get-CimInstance -ClassName Win32_BIOS             -ErrorAction Stop
        $processor        = Get-CimInstance -ClassName Win32_Processor        -ErrorAction Stop | Select-Object -First 1
    }
    catch {
        Write-NordError "Error retrieving system information: $_"
        Prompt-Return
        return
    }

    # Calculate system uptime.
    try {
        $lastBootTime = [Management.ManagementDateTimeConverter]::ToDateTime($operatingSystem.LastBootUpTime)
        $uptimeSpan   = (Get-Date) - $lastBootTime
        $uptimeFormatted = "{0} days, {1} hours, {2} minutes" -f $uptimeSpan.Days, $uptimeSpan.Hours, $uptimeSpan.Minutes
    }
    catch {
        $uptimeFormatted = "Unavailable"
        Write-NordWarning "Unable to calculate uptime: $_"
    }

    # Format total physical memory.
    $totalMemoryGB = "{0:N2} GB" -f ($computerSystem.TotalPhysicalMemory / 1GB)

    # Display system information.
    Write-Host ""
    Write-Host "================= System Information =================" -ForegroundColor Cyan
    Write-Host ("Computer Name:".PadRight(25) + $computerSystem.Name) -ForegroundColor Cyan
    Write-Host ("Manufacturer:".PadRight(25)  + $computerSystem.Manufacturer) -ForegroundColor Cyan
    Write-Host ("Model:".PadRight(25)         + $computerSystem.Model) -ForegroundColor Cyan
    Write-Host ("Total Memory:".PadRight(25)  + $totalMemoryGB) -ForegroundColor Cyan
    Write-Host ("OS Name:".PadRight(25)       + $operatingSystem.Caption) -ForegroundColor Cyan
    Write-Host ("OS Version:".PadRight(25)    + $operatingSystem.Version) -ForegroundColor Cyan
    Write-Host ("OS Build:".PadRight(25)      + $operatingSystem.BuildNumber) -ForegroundColor Cyan
    Write-Host ("BIOS Version:".PadRight(25)  + $bios.SMBIOSBIOSVersion) -ForegroundColor Cyan
    Write-Host ("Processor:".PadRight(25)     + $processor.Name) -ForegroundColor Cyan
    Write-Host ("System Uptime:".PadRight(25) + $uptimeFormatted) -ForegroundColor Cyan
    Write-Host ("Domain:".PadRight(25)        + $computerSystem.Domain) -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ""

    # Log system information summary.
    $logMessage = "System Information: " +
                  "ComputerName='$($computerSystem.Name)', " +
                  "Manufacturer='$($computerSystem.Manufacturer)', " +
                  "Model='$($computerSystem.Model)', " +
                  "TotalMemory='$totalMemoryGB', " +
                  "OS='$($operatingSystem.Caption) $($operatingSystem.Version) (Build $($operatingSystem.BuildNumber))', " +
                  "BIOS='$($bios.SMBIOSBIOSVersion)', " +
                  "Processor='$($processor.Name)', " +
                  "Uptime='$uptimeFormatted', " +
                  "Domain='$($computerSystem.Domain)'"
    Write-Log $logMessage

    Prompt-Return
}

#===========================================================================
# Function: Check-WindowsUpdate
# Purpose : Ensures Windows Update service is running and lists available updates.
#===========================================================================
function Check-WindowsUpdate {
    Write-NordInfo "Starting Windows Update check..."

    try {
        # Ensure the Windows Update service (wuauserv) is running.
        $wuService = Get-Service -Name "wuauserv" -ErrorAction Stop
        Write-NordInfo "Windows Update Service status: $($wuService.Status)"
        if ($wuService.Status -ne 'Running') {
            Write-NordWarning "Windows Update Service is not running. Attempting to start it..."
            Start-Service -Name "wuauserv" -ErrorAction Stop
            $wuService = Get-Service -Name "wuauserv"
            Write-NordSuccess "Windows Update Service started successfully. Current status: $($wuService.Status)"
        }
    }
    catch {
        Write-NordError "Failed to check or start the Windows Update Service: $_"
        Prompt-Return
        return
    }

    try {
        # Create COM objects for Windows Update.
        $updateSession  = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        Write-NordInfo "Querying Windows Update for available updates..."

        # Search for software updates that are not installed.
        $criteria     = "IsInstalled=0 and Type='Software'"
        $searchResult = $updateSearcher.Search($criteria)
        $updatesCount = $searchResult.Updates.Count

        Write-NordInfo "Number of available updates: $updatesCount"
        if ($updatesCount -gt 0) {
            Write-Host "`nAvailable Updates:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $updatesCount; $i++) {
                $update = $searchResult.Updates.Item($i)
                Write-Host ("[{0}] {1}" -f ($i + 1), $update.Title) -ForegroundColor Cyan
            }
        }
        else {
            Write-NordSuccess "No available updates. Your system is up-to-date."
        }
    }
    catch {
        Write-NordError "An error occurred while searching for Windows Updates: $_"
    }

    $logMessage = "Windows Update Check: Service Status: $($wuService.Status); Available Updates Count: $updatesCount"
    Write-Log $logMessage

    Prompt-Return
}
#endregion

#region Networking Tools
#===========================================================================
# Function: Show-NetworkConfiguration
# Purpose : Displays network adapter configuration details.
#===========================================================================
function Show-NetworkConfiguration {
    Write-NordInfo "Gathering network configuration details..."
    try {
        $netConfigs = Get-NetIPConfiguration -ErrorAction Stop
    }
    catch {
        Write-NordError "Error retrieving network configuration: $_"
        Prompt-Return
        return
    }

    if (-not $netConfigs -or $netConfigs.Count -eq 0) {
        Write-NordWarning "No network configuration details were found on this system."
        Prompt-Return
        return
    }

    foreach ($config in $netConfigs) {
        Write-Host "-------------------------------------------------" -ForegroundColor Cyan
        Write-Host ("Interface Alias:".PadRight(25) + $config.InterfaceAlias) -ForegroundColor Cyan
        Write-Host ("Interface Index:".PadRight(25) + $config.InterfaceIndex) -ForegroundColor Cyan
        Write-Host ("Description:".PadRight(25) + $config.InterfaceDescription) -ForegroundColor Cyan

        if ($config.IPv4Address) {
            Write-Host "IPv4 Address(es):" -ForegroundColor Cyan
            foreach ($ip in $config.IPv4Address) {
                Write-Host ("   {0} (Prefix Length: {1})" -f $ip.IPAddress, $ip.PrefixLength) -ForegroundColor Cyan
            }
        }
        else { Write-Host "IPv4 Address(es): None" -ForegroundColor Yellow }

        if ($config.IPv6Address) {
            Write-Host "IPv6 Address(es):" -ForegroundColor Cyan
            foreach ($ip in $config.IPv6Address) {
                Write-Host ("   {0} (Prefix Length: {1})" -f $ip.IPAddress, $ip.PrefixLength) -ForegroundColor Cyan
            }
        }
        else { Write-Host "IPv6 Address(es): None" -ForegroundColor Yellow }

        if ($config.DNSServer.ServerAddresses -and $config.DNSServer.ServerAddresses.Count -gt 0) {
            Write-Host "DNS Server(s):" -ForegroundColor Cyan
            foreach ($dns in $config.DNSServer.ServerAddresses) {
                Write-Host ("   {0}" -f $dns) -ForegroundColor Cyan
            }
        }
        else { Write-Host "DNS Server(s): None" -ForegroundColor Yellow }

        if ($config.IPv4DefaultGateway) {
            Write-Host "IPv4 Default Gateway:" -ForegroundColor Cyan
            Write-Host ("   {0}" -f $config.IPv4DefaultGateway.NextHop) -ForegroundColor Cyan
        }
        else { Write-Host "IPv4 Default Gateway: None" -ForegroundColor Yellow }

        if ($config.IPv6DefaultGateway) {
            Write-Host "IPv6 Default Gateway:" -ForegroundColor Cyan
            Write-Host ("   {0}" -f $config.IPv6DefaultGateway.NextHop) -ForegroundColor Cyan
        }
        else { Write-Host "IPv6 Default Gateway: None" -ForegroundColor Yellow }
    }
    Write-Host "-------------------------------------------------" -ForegroundColor Cyan

    $logMessage = "Network Configuration: Retrieved $($netConfigs.Count) adapter configuration(s)."
    Write-Log $logMessage
    Prompt-Return
}

#===========================================================================
# Function: Test-Ping
# Purpose : Performs a ping test to a user–specified host.
#===========================================================================
function Test-Ping {
    Write-NordInfo "Starting Ping Test..."
    $target = Read-Host "Enter the hostname or IP address to ping"

    if ([string]::IsNullOrWhiteSpace($target)) {
        Write-NordError "No hostname or IP address was provided. Please try again."
        Prompt-Return
        return
    }

    try {
        Write-NordInfo "Executing ping test for '$target'..."
        $pingResults = Test-Connection -ComputerName $target -Count 4 -ErrorAction Stop
        if ($pingResults) {
            Write-NordSuccess "Ping test to '$target' was successful."
            Write-Host "`nPing Results:" -ForegroundColor Cyan
            $pingResults | Format-Table -AutoSize
        }
        else {
            Write-NordWarning "No responses received from '$target'."
        }
        $logMessage = "Ping test executed for '$target'. Responses received: $($pingResults.Count)"
        Write-Log $logMessage
    }
    catch {
        Write-NordError "Ping test failed for '$target'. Error details: $_"
        Write-Log "Ping test error for '$target': $_"
    }

    Prompt-Return
}
#endregion

#region Security Tools
#===========================================================================
# Function: Check-WindowsFirewall
# Purpose : Retrieves and displays the status of Windows Firewall profiles.
#===========================================================================
function Check-WindowsFirewall {
    Write-NordInfo "Checking Windows Firewall status..."
    try {
        $firewallProfiles = Get-NetFirewallProfile -ErrorAction Stop
        if ($firewallProfiles) {
            Write-Host "-------------------------------------------------" -ForegroundColor Cyan
            Write-Host "          Windows Firewall Profiles              " -ForegroundColor Cyan
            Write-Host "-------------------------------------------------" -ForegroundColor Cyan
            $firewallProfiles | Format-Table -Property Name, Enabled, DefaultInboundAction, DefaultOutboundAction -AutoSize
            Write-Host "-------------------------------------------------" -ForegroundColor Cyan
            Write-NordSuccess "Windows Firewall profiles retrieved successfully."
            $logMessage = "Firewall status: " + ($firewallProfiles | ForEach-Object {
                "$($_.Name): Enabled=$($_.Enabled), Inbound=$($_.DefaultInboundAction), Outbound=$($_.DefaultOutboundAction)"
            } | Out-String)
            Write-Log $logMessage
        }
        else {
            Write-NordWarning "No Windows Firewall profiles were found on this system."
        }
    }
    catch {
        Write-NordError "An error occurred while retrieving Windows Firewall status: $_"
        Write-Log "Error retrieving Windows Firewall status: $_"
    }
    Prompt-Return
}

#===========================================================================
# Function: Antivirus-Check
# Purpose : Provides a submenu for antivirus operations:
#           - Checking installed antivirus solutions.
#           - Forcing enable Windows Defender.
#           - Uninstalling third–party antivirus.
#           - Running a full system scan using Windows Defender.
#===========================================================================
function Antivirus-Check {
    Write-NordInfo "Entering Antivirus Tools Menu..."

    # Internal: Check installed antivirus products.
    function Check-InstalledAV {
        Write-NordInfo "Scanning for installed antivirus solutions..."
        try {
            $avProducts = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction Stop
            if ($avProducts -and $avProducts.Count -gt 0) {
                Write-Host "Installed Antivirus Solutions:" -ForegroundColor Cyan
                foreach ($av in $avProducts) {
                    Write-Host " - $($av.displayName)" -ForegroundColor Cyan
                }
                Write-Log "Antivirus check: Found $($avProducts.Count) antivirus solution(s)."
            }
            else {
                Write-NordWarning "No antivirus solutions found."
            }
        }
        catch {
            Write-NordError "Error retrieving antivirus solutions: $_"
            Write-Log "Error retrieving antivirus solutions: $_"
        }
    }

    # Internal: Force enable Windows Defender real–time protection.
    function Enable-WindowsDefender {
        Write-NordInfo "Forcing enable of Windows Defender real–time protection..."
        try {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
            Write-NordSuccess "Windows Defender real–time protection enabled successfully."
            Write-Log "Windows Defender real–time protection enabled."
        }
        catch {
            Write-NordError "Error enabling Windows Defender: $_"
            Write-Log "Error enabling Windows Defender: $_"
        }
    }

    # Internal: Uninstall third–party antivirus (non–Defender).
    function Uninstall-ThirdPartyAV {
        Write-NordInfo "Scanning for third–party antivirus solutions..."
        try {
            $avProducts = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction Stop
            $thirdPartyAV = $avProducts | Where-Object { $_.displayName -notmatch "(?i)Defender" }
            if (-not $thirdPartyAV -or $thirdPartyAV.Count -eq 0) {
                Write-NordSuccess "No third–party antivirus solutions detected."
                return
            }
            foreach ($av in $thirdPartyAV) {
                Write-NordInfo "Attempting to uninstall: $($av.displayName)"
                $uninstallString = $null
                $regPaths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                              "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
                foreach ($regPath in $regPaths) {
                    $keys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
                    foreach ($key in $keys) {
                        try {
                            $props = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
                            if ($props.DisplayName -and $props.DisplayName -match [regex]::Escape($av.displayName)) {
                                $uninstallString = $props.UninstallString
                                if ($uninstallString) { break }
                            }
                        }
                        catch { }
                    }
                    if ($uninstallString) { break }
                }
                if ($uninstallString) {
                    Write-NordInfo "Found uninstall command: $uninstallString"
                    try {
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "$uninstallString /quiet" -Wait -NoNewWindow
                        Write-NordSuccess "$($av.displayName) uninstalled successfully."
                        Write-Log "Uninstalled $($av.displayName)."
                    }
                    catch {
                        Write-NordError "Failed to uninstall $($av.displayName): $_"
                        Write-Log "Failed to uninstall $($av.displayName): $_"
                    }
                }
                else {
                    Write-NordWarning "Uninstall command not found for $($av.displayName). Manual removal may be required."
                    Write-Log "Uninstall command not found for $($av.displayName)."
                }
            }
        }
        catch {
            Write-NordError "Error while scanning for third–party antivirus: $_"
            Write-Log "Error in Uninstall-ThirdPartyAV: $_"
        }
    }

    # Internal: Run a full system scan with Windows Defender.
    function Run-FullScan {
        Write-NordInfo "Initiating a full system scan with Windows Defender..."
        try {
            Start-MpScan -ScanType FullScan -ErrorAction Stop
            Write-NordSuccess "Full system scan initiated successfully."
            Write-Log "Windows Defender full scan started."
        }
        catch {
            Write-NordError "Failed to start full system scan: $_"
            Write-Log "Error starting full system scan: $_"
        }
    }

    # Antivirus Tools Submenu Loop
    do {
        Write-Host "-------------------------------------------------" -ForegroundColor Cyan
        Write-Host "               Antivirus Tools Menu              " -ForegroundColor Cyan
        Write-Host "-------------------------------------------------" -ForegroundColor Cyan
        Write-Host "1. Check Installed Antivirus Solutions" -ForegroundColor Cyan
        Write-Host "2. Force Enable Windows Defender" -ForegroundColor Cyan
        Write-Host "3. Uninstall Third–Party Antivirus Solutions" -ForegroundColor Cyan
        Write-Host "4. Run a Full System Scan (Windows Defender)" -ForegroundColor Cyan
        Write-Host "m. Main Menu" -ForegroundColor Cyan
        Write-Host "q. Quit" -ForegroundColor Cyan
        Write-Host "-------------------------------------------------" -ForegroundColor Cyan

        $choice = Read-Host "Enter your choice"
        switch ($choice) {
            "1" { Check-InstalledAV }
            "2" { Enable-WindowsDefender }
            "3" { Uninstall-ThirdPartyAV }
            "4" { Run-FullScan }
            "m" { return }
            "q" { Write-NordInfo "Exiting the toolkit."; exit }
            default { Write-NordWarning "Invalid selection. Please try again." }
        }
    } while ($true)

    Prompt-Return
}
#endregion

#region Software Installation Tools
#===========================================================================
# Function: Install-Chocolatey
# Purpose : Installs Chocolatey if not already installed.
#===========================================================================
function Install-Chocolatey {
    Write-NordInfo "Checking for Chocolatey installation..."
    try {
        $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoCmd) {
            Write-NordSuccess "Chocolatey is already installed."
            Write-Log "Chocolatey installation check: Already installed."
            Prompt-Return
            return
        }
    }
    catch {
        Write-NordWarning "Error checking Chocolatey installation: $_"
    }

    Write-NordInfo "Chocolatey not found. Initiating installation..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $installScript = "Set-ExecutionPolicy Bypass -Scope Process -Force; " +
                         "[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " +
                         "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        Invoke-Expression $installScript
        Start-Sleep -Seconds 10
        $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoCmd) {
            Write-NordSuccess "Chocolatey installed successfully."
            Write-Log "Chocolatey installation: Success."
        }
        else {
            Write-NordError "Chocolatey installation failed. 'choco' command not found after installation."
            Write-Log "Chocolatey installation: Failed."
        }
    }
    catch {
        Write-NordError "Error during Chocolatey installation: $_"
        Write-Log "Chocolatey installation error: $_"
    }
    Prompt-Return
}

#===========================================================================
# Function: Install-VSCode
# Purpose : Downloads and installs Visual Studio Code silently if not already installed.
#===========================================================================
function Install-VSCode {
    Write-NordInfo "Checking for Visual Studio Code installation..."
    try {
        $vscodeCmd = Get-Command code -ErrorAction SilentlyContinue
        if ($vscodeCmd) {
            Write-NordSuccess "Visual Studio Code is already installed."
            Write-Log "VSCode installation check: Already installed."
            Prompt-Return
            return
        }
    }
    catch {
        Write-NordWarning "Error checking VSCode installation: $_"
    }

    Write-NordInfo "Visual Studio Code not found. Downloading installer..."
    $tempInstaller = Join-Path $env:TEMP "VSCodeSetup.exe"
    $vscodeUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
    try {
        Invoke-WebRequest -Uri $vscodeUrl -OutFile $tempInstaller -ErrorAction Stop
        Write-NordInfo "VSCode installer downloaded to $tempInstaller"
    }
    catch {
        Write-NordError "Error downloading VSCode installer: $_"
        Write-Log "VSCode installer download error: $_"
        Prompt-Return
        return
    }

    Write-NordInfo "Starting VSCode silent installation..."
    try {
        $arguments = "/VERYSILENT /NORESTART"
        $process = Start-Process -FilePath $tempInstaller -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop
        if ($process.ExitCode -eq 0) {
            Write-NordSuccess "Visual Studio Code installed successfully."
            Write-Log "VSCode installation: Success."
        }
        else {
            Write-NordError "Visual Studio Code installer returned exit code $($process.ExitCode)."
            Write-Log "VSCode installation: Failed with exit code $($process.ExitCode)."
        }
    }
    catch {
        Write-NordError "Error during VSCode installation: $_"
        Write-Log "VSCode installation error: $_"
    }
    finally {
        if (Test-Path $tempInstaller) {
            Remove-Item $tempInstaller -Force -ErrorAction SilentlyContinue
        }
    }
    Prompt-Return
}

#===========================================================================
# Function: Uninstall-Software
# Purpose : Searches for installed software matching a user–provided name and uninstalls it.
#===========================================================================
function Uninstall-Software {
    Write-NordInfo "Software Uninstallation Tool"
    $softwareName = Read-Host "Enter the name (or part of the name) of the software to uninstall"
    if ([string]::IsNullOrWhiteSpace($softwareName)) {
        Write-NordError "No software name provided. Aborting uninstallation."
        Prompt-Return
        return
    }

    Write-NordInfo "Searching for installed software matching '$softwareName'..."
    $uninstallEntries = @()
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    foreach ($path in $registryPaths) {
        try {
            $keys = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
            foreach ($key in $keys) {
                try {
                    $app = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
                    if ($app.DisplayName -and $app.DisplayName -like "*$softwareName*") {
                        $uninstallEntries += [PSCustomObject]@{
                            DisplayName     = $app.DisplayName
                            UninstallString = $app.UninstallString
                            InstallLocation = $app.InstallLocation
                            RegistryPath    = $key.PSPath
                        }
                    }
                }
                catch { }
            }
        }
        catch {
            Write-NordWarning "Error accessing registry path ${path}: $_"
        }
    }

    if ($uninstallEntries.Count -eq 0) {
        Write-NordWarning "No installed software matching '$softwareName' was found."
        Prompt-Return
        return
    }

    Write-Host "`nFound the following entries:" -ForegroundColor Cyan
    $index = 1
    foreach ($entry in $uninstallEntries) {
        Write-Host ("[{0}] {1}" -f $index, $entry.DisplayName) -ForegroundColor Cyan
        $index++
    }

    $choice = Read-Host "Enter the number of the software you wish to uninstall (or 'a' to uninstall all listed)"
    if ($choice -eq "a") {
        $selectedEntries = $uninstallEntries
    }
    else {
        if (-not [int]::TryParse($choice, [ref]$null) -or $choice -lt 1 -or $choice -gt $uninstallEntries.Count) {
            Write-NordError "Invalid selection. Aborting uninstallation."
            Prompt-Return
            return
        }
        $selectedEntries = @($uninstallEntries[$choice - 1])
    }

    foreach ($entry in $selectedEntries) {
        Write-NordInfo "Attempting to uninstall '$($entry.DisplayName)'..."
        if ([string]::IsNullOrWhiteSpace($entry.UninstallString)) {
            Write-NordWarning "No uninstall command found for '$($entry.DisplayName)'. Manual removal may be required."
            Write-Log "Uninstallation failed for '$($entry.DisplayName)': UninstallString not found."
            continue
        }
        try {
            $uninstallCmd = $entry.UninstallString.Trim('"')
            if ($uninstallCmd -match "msiexec") {
                if ($uninstallCmd -notmatch "/x") { $uninstallCmd += " /x" }
                $uninstallCmd += " /quiet /norestart"
                Write-NordInfo "MSI uninstall command: $uninstallCmd"
                $arguments = $uninstallCmd.Substring($uninstallCmd.IndexOf(" "))
                Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -ErrorAction Stop
            }
            else {
                if ($uninstallCmd -notmatch "/S" -and $uninstallCmd -notmatch "/silent") {
                    $uninstallCmd += " /S"
                }
                Write-NordInfo "Uninstall command: $uninstallCmd"
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $uninstallCmd -Wait -NoNewWindow -ErrorAction Stop
            }
            Write-NordSuccess "'$($entry.DisplayName)' uninstalled successfully."
            Write-Log "Uninstalled '$($entry.DisplayName)'."
        }
        catch {
            Write-NordError "Failed to uninstall '$($entry.DisplayName)': $_"
            Write-Log "Uninstallation error for '$($entry.DisplayName)': $_"
        }
    }
    Prompt-Return
}
#endregion

#region Miscellaneous Tools
#===========================================================================
# Function: Disk-Cleanup
# Purpose : Initiates the Disk Cleanup utility for a specified drive.
#===========================================================================
function Disk-Cleanup {
    Write-NordInfo "Initiating Disk Cleanup..."
    $drive = Read-Host "Enter the drive letter to clean up (default is C)"
    if ([string]::IsNullOrWhiteSpace($drive)) { $drive = "C" }
    $drive = $drive.Trim() -replace "[:]", "" + ":"
    try {
        Write-NordInfo "Starting Disk Cleanup for drive $drive..."
        $cleanmgrPath = "$env:SystemRoot\System32\cleanmgr.exe"
        if (-not (Test-Path $cleanmgrPath)) {
            Write-NordError "Disk Cleanup tool not found at $cleanmgrPath."
            Write-Log "Disk Cleanup: cleanmgr.exe not found."
            Prompt-Return
            return
        }
        Start-Process -FilePath $cleanmgrPath -ArgumentList "/d", "$drive" -Wait -NoNewWindow
        Write-NordSuccess "Disk Cleanup completed (if any cleanup was performed) for drive $drive."
        Write-Log "Disk Cleanup initiated for drive $drive."
    }
    catch {
        Write-NordError "An error occurred during Disk Cleanup: $_"
        Write-Log "Disk Cleanup error: $_"
    }
    Prompt-Return
}

#===========================================================================
# Function: System-Restart
# Purpose : Restarts the system after user confirmation.
#===========================================================================
function System-Restart {
    Write-NordWarning "System Restart Initiated."
    $confirmation = Read-Host "Are you sure you want to restart the system? (y/n)"
    if ($confirmation -eq "y") {
        try {
            Write-NordInfo "Restarting system now..."
            Write-Log "System Restart initiated by user."
            Restart-Computer -Force -ErrorAction Stop
        }
        catch {
            Write-NordError "Failed to restart the system: $_"
            Write-Log "System Restart error: $_"
        }
    }
    else {
        Write-NordInfo "System Restart cancelled by user."
    }
    Prompt-Return
}
#endregion

#region Install-Python Function
#===========================================================================
# Function: Install-Python
# Purpose : Downloads a pre-built Python archive, extracts it to C:\python,
#           adds Python to the user's PATH, and verifies the installation.
#===========================================================================
function Install-Python {
    Write-NordInfo "Starting Python installation..."
    $pythonUrl = "https://github.com/astral-sh/python-build-standalone/releases/download/20250205/cpython-3.13.2+20250205-x86_64-pc-windows-msvc-pgo-full.tar.zst"
    $tempDownloadPath = Join-Path $env:TEMP "python_build.tar.zst"
    $destinationPath = "C:\python"

    try {
        Write-NordInfo "Downloading Python from: $pythonUrl"
        Invoke-WebRequest -Uri $pythonUrl -OutFile $tempDownloadPath -UseBasicParsing
        Write-NordSuccess "Download completed successfully."
    }
    catch {
        Write-NordError "Error during download: $_"
        Prompt-Return
        return
    }

    if (-Not (Test-Path $destinationPath)) {
        try {
            New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
            Write-NordInfo "Created destination directory: $destinationPath"
        }
        catch {
            Write-NordError "Failed to create destination directory: $_"
            Prompt-Return
            return
        }
    }
    else {
        Write-NordWarning "Destination directory $destinationPath already exists. Existing files may be overwritten."
    }

    try {
        Write-NordInfo "Extracting archive to $destinationPath..."
        tar --use-compress-program=unzstd -xf $tempDownloadPath --strip-components=1 -C $destinationPath
        Write-NordSuccess "Extraction completed."
    }
    catch {
        Write-NordError "Extraction failed: $_"
        Prompt-Return
        return
    }

    $pythonExePath = Join-Path $destinationPath "install\python.exe"
    if (-Not (Test-Path $pythonExePath)) {
        Write-NordError "Python executable not found at expected location: $pythonExePath"
        Prompt-Return
        return
    }

    $pythonDir = Split-Path $pythonExePath -Parent
    $currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentUserPath -notlike "*$pythonDir*") {
        try {
            $newPath = "$currentUserPath;$pythonDir"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-NordInfo "Added '$pythonDir' to the User PATH."
        }
        catch {
            Write-NordError "Failed to update PATH: $_"
            Prompt-Return
            return
        }
    }
    else {
        Write-NordInfo "'$pythonDir' is already in the PATH."
    }

    try {
        $pythonVersion = & python --version 2>&1
        if ($pythonVersion -match "Python") {
            Write-NordSuccess "Python successfully installed: $pythonVersion"
        }
        else {
            Write-NordError "Python test failed. Output: $pythonVersion"
            Prompt-Return
            return
        }
    }
    catch {
        Write-NordError "Error executing Python: $_"
        Prompt-Return
        return
    }

    try {
        Remove-Item $tempDownloadPath -Force
        Write-NordInfo "Cleaned up temporary download file."
    }
    catch {
        Write-NordWarning "Could not remove temporary file: $tempDownloadPath"
    }
    Prompt-Return
}
#endregion

#region Menu Functions
#===========================================================================
# The following functions build the hierarchical menu system.
# To add new functions, simply update the relevant submenu below.
#===========================================================================

# ----- Main Menu -----
function Show-MainMenu {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor DarkCyan
    Write-Host "      Windows Swiss Army Knife Toolkit    " -ForegroundColor DarkCyan
    Write-Host "==========================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "Main Menu:" -ForegroundColor DarkCyan
    Write-Host " 1. System Tools"
    Write-Host " 2. Networking Tools"
    Write-Host " 3. Security Tools"
    Write-Host " 4. Software Installation Tools"
    Write-Host " 5. Miscellaneous Tools"
    Write-Host " q. Quit"
    Write-Host ""

    $choice = Read-Host "Enter your choice (number or 'q' to quit)"
    switch ($choice) {
        "1" { Show-SystemToolsMenu }
        "2" { Show-NetworkingToolsMenu }
        "3" { Show-SecurityToolsMenu }
        "4" { Show-SoftwareInstallationMenu }
        "5" { Show-MiscToolsMenu }
        "q" { Write-NordInfo "Exiting the toolkit. Goodbye!"; exit }
        default {
            Write-NordWarning "Invalid selection. Please try again."
            Start-Sleep -Seconds 1
            Show-MainMenu
        }
    }
}

# ----- System Tools Menu -----
function Show-SystemToolsMenu {
    Clear-Host
    Write-Host "------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "             System Tools Menu            " -ForegroundColor DarkCyan
    Write-Host "------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " 1. View System Information"
    Write-Host " 2. Check Windows Update Status"
    Write-Host " m. Main Menu"
    Write-Host " q. Quit"
    Write-Host ""

    $choice = Read-Host "Enter your choice"
    switch ($choice) {
        "1" { Show-SystemInformation }
        "2" { Check-WindowsUpdate }
        "m" { Show-MainMenu }
        "q" { Write-NordInfo "Exiting the toolkit. Goodbye!"; exit }
        default {
            Write-NordWarning "Invalid selection. Returning to Main Menu."
            Start-Sleep -Seconds 1
            Show-MainMenu
        }
    }
}

# ----- Networking Tools Menu -----
function Show-NetworkingToolsMenu {
    Clear-Host
    Write-Host "------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "           Networking Tools Menu          " -ForegroundColor DarkCyan
    Write-Host "------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " 1. View Network Configuration"
    Write-Host " 2. Ping Test"
    Write-Host " m. Main Menu"
    Write-Host " q. Quit"
    Write-Host ""

    $choice = Read-Host "Enter your choice"
    switch ($choice) {
        "1" { Show-NetworkConfiguration }
        "2" { Test-Ping }
        "m" { Show-MainMenu }
        "q" { Write-NordInfo "Exiting the toolkit. Goodbye!"; exit }
        default {
            Write-NordWarning "Invalid selection. Returning to Main Menu."
            Start-Sleep -Seconds 1
            Show-MainMenu
        }
    }
}

# ----- Security Tools Menu -----
function Show-SecurityToolsMenu {
    Clear-Host
    Write-Host "------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "            Security Tools Menu           " -ForegroundColor DarkCyan
    Write-Host "------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " 1. Check Windows Firewall Status"
    Write-Host " 2. Antivirus Check"
    Write-Host " m. Main Menu"
    Write-Host " q. Quit"
    Write-Host ""

    $choice = Read-Host "Enter your choice"
    switch ($choice) {
        "1" { Check-WindowsFirewall }
        "2" { Antivirus-Check }
        "m" { Show-MainMenu }
        "q" { Write-NordInfo "Exiting the toolkit. Goodbye!"; exit }
        default {
            Write-NordWarning "Invalid selection. Returning to Main Menu."
            Start-Sleep -Seconds 1
            Show-MainMenu
        }
    }
}

# ----- Software Installation Tools Menu -----
function Show-SoftwareInstallationMenu {
    Clear-Host
    Write-Host "------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "    Software Installation Tools Menu      " -ForegroundColor DarkCyan
    Write-Host "------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " 1. Install Python"
    Write-Host " 2. Install Chocolatey"
    Write-Host " 3. Install Visual Studio Code"
    Write-Host " 4. Uninstall Software"
    Write-Host " m. Main Menu"
    Write-Host " q. Quit"
    Write-Host ""

    $choice = Read-Host "Enter your choice"
    switch ($choice) {
        "1" { Install-Python }
        "2" { Install-Chocolatey }
        "3" { Install-VSCode }
        "4" { Uninstall-Software }
        "m" { Show-MainMenu }
        "q" { Write-NordInfo "Exiting the toolkit. Goodbye!"; exit }
        default {
            Write-NordWarning "Invalid selection. Returning to Main Menu."
            Start-Sleep -Seconds 1
            Show-MainMenu
        }
    }
}

# ----- Miscellaneous Tools Menu -----
function Show-MiscToolsMenu {
    Clear-Host
    Write-Host "------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "         Miscellaneous Tools Menu         " -ForegroundColor DarkCyan
    Write-Host "------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " 1. Disk Cleanup"
    Write-Host " 2. System Restart"
    Write-Host " m. Main Menu"
    Write-Host " q. Quit"
    Write-Host ""

    $choice = Read-Host "Enter your choice"
    switch ($choice) {
        "1" { Disk-Cleanup }
        "2" { System-Restart }
        "m" { Show-MainMenu }
        "q" { Write-NordInfo "Exiting the toolkit. Goodbye!"; exit }
        default {
            Write-NordWarning "Invalid selection. Returning to Main Menu."
            Start-Sleep -Seconds 1
            Show-MainMenu
        }
    }
}
#endregion

#region Start the Toolkit
# Kick off the toolkit by displaying the Main Menu.
Show-MainMenu
#endregion
