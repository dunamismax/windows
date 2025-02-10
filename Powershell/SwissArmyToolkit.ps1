<#
    Swiss Army Knife Toolkit for Windows
    ======================================
    This PowerShell script provides an interactive, Nord–themed, menu–driven
    toolkit designed for Windows 10/11 sysadmins, pentesters, and security/network professionals.

    Features include:
      • A main menu broken into submenus for System Tools, Networking Tools,
        Security Tools, Software Installation Tools, and Miscellaneous Tools.
      • Logging of all events to a log file (located in the script directory).
      • Nord–themed color output throughout (using built–in colors approximating the Nord palette).
      • A complete “Install Python” function that downloads a pre–built Python archive,
        extracts it to C:\python, adds it to the user PATH, and validates the installation.
      • “q” to quit and “m” to return to the main menu available on every page.

    Author: Your Name
    Date: 2025-02-10
#>

#region Global Variables & Logging

# The directory in which the script is running.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Log file path – created in the same folder as the script.
$LogFile = Join-Path $ScriptDir "swiss_army_toolkit.log"

# Write a message (with a timestamp) to the log file.
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp  $message"
    Add-Content -Path $LogFile -Value $entry
}
#endregion

#region Nord-Themed Output Functions
# These functions use built–in colors that approximate the Nord palette.

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
# Every submenu will prompt for "m" (main menu) or "q" (quit) after completing.
function Prompt-Return {
    Write-NordInfo "Press 'm' to return to the Main Menu or 'q' to quit."
    $choice = Read-Host "Enter your choice"
    if ($choice -eq "m") { Show-MainMenu }
    elseif ($choice -eq "q") { Write-NordInfo "Exiting the toolkit. Goodbye!"; exit }
    else { Show-MainMenu }
}
#endregion

#region Placeholder Functions for Various Tools

# -------------------------
# System Tools
# -------------------------
function Show-SystemInformation {
    Write-NordInfo "System Information (Placeholder): This function will display detailed system information."
    # (e.g., Get-ComputerInfo, wmic, etc. can be integrated here)
    Prompt-Return
}

function Check-WindowsUpdate {
    Write-NordInfo "Windows Update Check (Placeholder): This function will query the Windows Update status."
    # (e.g., using the Windows Update API or the Get-WindowsUpdateLog cmdlet)
    Prompt-Return
}

# -------------------------
# Networking Tools
# -------------------------
function Show-NetworkConfiguration {
    Write-NordInfo "Network Configuration (Placeholder): This function will display current network settings."
    # (e.g., ipconfig /all or Get-NetIPConfiguration)
    Prompt-Return
}

function Test-Ping {
    Write-NordInfo "Ping Test (Placeholder): This function will perform a ping test to a specified host."
    # (e.g., Read a host name and execute Test-Connection)
    Prompt-Return
}

# -------------------------
# Security Tools
# -------------------------
function Check-WindowsFirewall {
    Write-NordInfo "Windows Firewall Status (Placeholder): This function will check the status of Windows Firewall."
    # (e.g., using Get-NetFirewallProfile)
    Prompt-Return
}

function Antivirus-Check {
    Write-NordInfo "Antivirus Check (Placeholder): This function will check for installed antivirus solutions."
    # (e.g., via WMI or querying specific registry keys)
    Prompt-Return
}

# -------------------------
# Software Installation Tools
# -------------------------
# The Install-Python function is fully implemented (see below).
function Install-NodeJS {
    Write-NordInfo "Install Node.js (Placeholder): This function will install Node.js."
    # (Future implementation can include downloading and installing Node.js)
    Prompt-Return
}

# -------------------------
# Miscellaneous Tools
# -------------------------
function Disk-Cleanup {
    Write-NordInfo "Disk Cleanup (Placeholder): This function will initiate a disk cleanup process."
    # (e.g., invoking cleanmgr.exe or custom cleanup scripts)
    Prompt-Return
}

function System-Restart {
    Write-NordWarning "System Restart (Placeholder): This function will restart the system."
    $confirmation = Read-Host "Are you sure you want to restart? (y/n)"
    if ($confirmation -eq "y") {
        Write-NordInfo "Restarting system..."
        # Uncomment the line below to enable a real restart:
        # Restart-Computer -Force
    }
    Prompt-Return
}
#endregion

#region Install-Python Function
function Install-Python {
    Write-NordInfo "Starting Python installation..."

    # Define the URL to download the Python build.
    $pythonUrl = "https://github.com/astral-sh/python-build-standalone/releases/download/20250205/cpython-3.13.2+20250205-x86_64-pc-windows-msvc-pgo-full.tar.zst"

    # Download to a temporary file.
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

    # Create the destination directory if it does not exist.
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

    # Extract the archive.
    try {
        Write-NordInfo "Extracting archive to $destinationPath..."
        # The archive likely contains a top–level folder; use --strip-components=1 to remove it.
        # Note: This uses tar’s --use-compress-program option with unzstd.
        tar --use-compress-program=unzstd -xf $tempDownloadPath --strip-components=1 -C $destinationPath
        Write-NordSuccess "Extraction completed."
    }
    catch {
        Write-NordError "Extraction failed: $_"
        Prompt-Return
        return
    }

    # Verify that python.exe exists.
    # (Based on your reference, python.exe should now be at C:\python\install\python.exe)
    $pythonExePath = Join-Path $destinationPath "install\python.exe"
    if (-Not (Test-Path $pythonExePath)) {
        Write-NordError "Python executable not found at expected location: $pythonExePath"
        Prompt-Return
        return
    }

    # Add the folder (C:\python\install) to the user's PATH.
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

    # Test that Python is executable.
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

    # Clean up the temporary download.
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
    Write-Host "      Software Installation Tools Menu    " -ForegroundColor DarkCyan
    Write-Host "------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " 1. Install Python"
    Write-Host " 2. Install Node.js (Placeholder)"
    Write-Host " m. Main Menu"
    Write-Host " q. Quit"
    Write-Host ""

    $choice = Read-Host "Enter your choice"
    switch ($choice) {
        "1" { Install-Python }
        "2" { Install-NodeJS }
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
    Write-Host " 1. Disk Cleanup (Placeholder)"
    Write-Host " 2. System Restart (Placeholder)"
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
# Start the main menu loop.
Show-MainMenu
#endregion
