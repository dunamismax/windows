# Set error preference to avoid showing PowerShell error messages to the user
$ErrorActionPreference= 'silentlycontinue'

# --- Configuration ---
# Define the desired password hash and salt (as they would appear in the TOML)
# IMPORTANT: Replace these with the actual HASH and SALT corresponding to your desired password '2020Techs!@'
#            These values below are placeholders from your previous example and MUST be correct for your password.
$TargetPasswordHash = '00Y6GcezQQohdBno5iVe5jB1pcJQ5WLqIG2NFQ'
$TargetSalt = 'bephp9'

# Define the service name
$ServiceName = 'Rustdesk'

# Define the target configuration file path for the service
$ConfigDirPath = 'C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config'
$ConfigFilePath = Join-Path $ConfigDirPath 'RustDesk.toml'

# --- Static Download Information ---
$TargetVersion = "1.3.9" # Manually specify the version corresponding to the link
$Downloadlink = "https://github.com/rustdesk/rustdesk/releases/download/1.3.9/rustdesk-1.3.9-x86_64.exe"
Write-Output "Target RustDesk Version: $TargetVersion"
Write-Output "Using Static Download Link: $Downloadlink"

# --- Main Script Logic ---

# Use TLS 1.2 or higher for web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Tls13

# Check currently installed version (handle case where RustDesk is not installed)
$rdver = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RustDesk" -ErrorAction SilentlyContinue).Version

$needsInstallOrUpgrade = $false
if ($rdver -eq $TargetVersion) {
    Write-Output "RustDesk version $rdver is already the target version ($TargetVersion)."
    # Continue to ensure config and service state
} elseif ($rdver) {
    Write-Output "Found installed version $rdver. Upgrading to target version $TargetVersion..."
    $needsInstallOrUpgrade = $true
} else {
    Write-Output "RustDesk not found. Installing target version $TargetVersion..."
    $needsInstallOrUpgrade = $true
}

# Ensure Temp directory exists
$TempPath = "C:\Temp"
if (!(Test-Path $TempPath)) {
    New-Item -ItemType Directory -Force -Path $TempPath | Out-Null
}
$InstallerPath = Join-Path $TempPath "rustdesk.exe"

# Download and Install/Upgrade if needed
if ($needsInstallOrUpgrade) {
    Write-Output "Downloading $Downloadlink to $InstallerPath..."
    try {
        Invoke-WebRequest $Downloadlink -Outfile $InstallerPath -UseBasicParsing -ErrorAction Stop
        Write-Output "Download complete."
    } catch {
        Write-Output "ERROR: Failed to download RustDesk installer. $($_.Exception.Message)"
        Exit 1
    }

    Write-Output "Starting silent installation/upgrade..."
    $installProcess = Start-Process -FilePath $InstallerPath -ArgumentList '--silent-install' -WindowStyle Hidden -PassThru -Wait
    if ($installProcess.ExitCode -ne 0) {
        Write-Output "ERROR: Installer exited with code $($installProcess.ExitCode). Installation/upgrade may have failed."
        # Exit 1 # Decide if critical
    } else {
        Write-Output "Installer process completed."
    }
    Write-Output "Waiting 20 seconds for installation/upgrade to settle..."
    Start-Sleep -seconds 20
} else {
     Write-Output "Skipping download and install as correct version is present."
}

# Define expected installation path
$RustDeskPath = Join-Path $env:ProgramFiles "RustDesk"
$RustDeskExe = Join-Path $RustDeskPath "rustdesk.exe"

if (!(Test-Path $RustDeskExe)) {
     Write-Output "ERROR: RustDesk executable not found at '$RustDeskExe'. Cannot proceed."
     Exit 1
}

# --- Configuration File Modification ---

# Ensure the service is started initially (to generate the config file if it's a fresh install)
Write-Output "Ensuring RustDesk service is running initially..."
$arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($arrService -and $arrService.Status -ne 'Running') {
    Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
    Write-Output "Waiting 15 seconds for service to start and potentially generate config..."
    Start-Sleep -seconds 15
} elseif ($arrService -eq $null) {
     Write-Output "Service not found, installation likely needed (handled below if applicable)."
     # Service install logic comes later if needed
}

# Stop the service before modifying config
Write-Output "Attempting to stop RustDesk service before config modification..."
Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
Start-Sleep -seconds 10 # Give service time to fully stop

# Check if Config file exists
if (!(Test-Path $ConfigFilePath)) {
    Write-Output "ERROR: Configuration file '$ConfigFilePath' not found after starting/stopping service. Cannot set password."
    # Optional: Try starting the service again briefly? Or Exit?
    Write-Output "Attempting to start service again to generate config..."
    Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 10
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 10
    if (!(Test-Path $ConfigFilePath)) {
         Write-Output "ERROR: Config file still not found. Exiting."
         Exit 1
    } else {
         Write-Output "Config file found on second attempt."
    }
}

# Modify the TOML file
Write-Output "Modifying configuration file: $ConfigFilePath"
try {
    # Read the existing content
    $CurrentContent = Get-Content -Path $ConfigFilePath -Raw -Encoding UTF8 -ErrorAction Stop

    # Prepare the lines to be inserted/updated
    $PasswordLine = "password = '$TargetPasswordHash'"
    $SaltLine = "salt = '$TargetSalt'"

    # Define Regex patterns to find existing lines (case-insensitive, whitespace tolerant)
    $PasswordPattern = "(?im)^\s*password\s*=\s*.*$"
    $SaltPattern = "(?im)^\s*salt\s*=\s*.*$"

    # Update or Append Password line
    if ($CurrentContent -match $PasswordPattern) {
        Write-Output "Updating existing password line..."
        $NewContent = $CurrentContent -replace $PasswordPattern, $PasswordLine
    } else {
        Write-Output "Appending password line..."
        $NewContent = $CurrentContent.TrimEnd() + "`r`n" + $PasswordLine # Ensure newline before appending
    }

    # Update or Append Salt line (operating on the potentially modified content)
    if ($NewContent -match $SaltPattern) {
         Write-Output "Updating existing salt line..."
        $NewContent = $NewContent -replace $SaltPattern, $SaltLine
    } else {
        Write-Output "Appending salt line..."
        $NewContent = $NewContent.TrimEnd() + "`r`n" + $SaltLine # Ensure newline before appending
    }

    # Write the modified content back
    Set-Content -Path $ConfigFilePath -Value $NewContent -Force -Encoding UTF8 -ErrorAction Stop
    Write-Output "Configuration file modified successfully."

} catch {
    Write-Output "ERROR: Failed to read or modify configuration file '$ConfigFilePath'. $($_.Exception.Message)"
    # Attempt to start service anyway? Or exit?
    # Exit 1
}

# --- Service Management (Post Config) ---

# Check if service needs to be installed (might have been removed)
$arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($arrService -eq $null) {
    Write-Output "RustDesk service not found after config attempt. Installing service..."
    $serviceInstallProcess = Start-Process -FilePath $RustDeskExe -ArgumentList '--install-service' -WindowStyle Hidden -PassThru -Wait
    # ... (rest of service install check as before) ...
    Start-Sleep -seconds 15
    $arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($arrService -eq $null) {
        Write-Output "ERROR: Service '$ServiceName' still not found after installation attempt."
        # Exit 1
    }
}

# Ensure the service is running (Start or Restart)
Write-Output "Ensuring RustDesk service is running with updated configuration..."
$attempts = 0
# Refresh service object
$arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($arrService) {
    while ($arrService.Status -ne 'Running' -and $attempts -lt 5) {
        $attempts++
        Write-Output "Attempt ${attempts}: Starting service '$ServiceName'..."
        Start-Service $ServiceName -ErrorAction SilentlyContinue
        Start-Sleep -seconds 7
        $arrService.Refresh()
        Write-Output "Current service status: $($arrService.Status)"
    }
     if ($arrService.Status -ne 'Running') {
        Write-Output "ERROR: Failed to start the RustDesk service after $attempts attempts."
        # Exit 1
    } else {
        Write-Output "RustDesk service is running."
    }
} else {
     Write-Output "ERROR: Could not find RustDesk service object to start it."
     # Exit 1
}

# --- Final Steps ---

# Get RustDesk ID
Write-Output "Waiting 5 seconds for service to stabilize..."
Start-Sleep -seconds 5
Write-Output "Retrieving RustDesk ID..."
$rustdesk_id_output = ""
try {
    $rustdesk_id_output = (& "$RustDeskExe" --get-id)
    if ($LASTEXITCODE -ne 0) {
         Write-Output "WARNING: --get-id command exited with code $LASTEXITCODE."
    }
} catch {
    Write-Output "ERROR: Failed to execute RustDesk to get ID. $($_.Exception.Message)"
}
$rustdesk_id = ($rustdesk_id_output | Select-Object -First 1).Trim()

# --- Output Results for RMM ---
Write-Output "..............................................."
Write-Output "RustDesk Deployment Summary:"
if ($rustdesk_id) {
    Write-Output "RustDesk ID: $rustdesk_id"
} else {
    Write-Output "RustDesk ID: Failed to retrieve."
}
Write-Output "Password configuration applied via: $ConfigFilePath" # Changed message
Write-Output "..............................................."
Write-Output "Script completed."
Exit 0