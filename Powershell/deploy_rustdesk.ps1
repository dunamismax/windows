# Set error preference to avoid showing PowerShell error messages to the user
$ErrorActionPreference= 'silentlycontinue'

# --- Configuration ---
# Assign a password to the password variable
$rustdesk_pw = '2020Techs!@'

# !!! IMPORTANT: Replace "configstring" with your actual RustDesk configuration string !!!
$rustdesk_cfg="configstring"
# Example: $rustdesk_cfg="your_server_address,your_key"

# Define the service name
$ServiceName = 'Rustdesk'

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

if ($rdver -eq $TargetVersion) {
    Write-Output "RustDesk version $rdver is already the target version ($TargetVersion). No action needed."
    Exit 0 # Exit successfully
} elseif ($rdver) {
    Write-Output "Found installed version $rdver. Upgrading to target version $TargetVersion..."
} else {
    Write-Output "RustDesk not found. Installing target version $TargetVersion..."
}

# Ensure Temp directory exists
$TempPath = "C:\Temp"
if (!(Test-Path $TempPath)) {
    New-Item -ItemType Directory -Force -Path $TempPath | Out-Null
}
$InstallerPath = Join-Path $TempPath "rustdesk.exe"

# Download the installer
Write-Output "Downloading $Downloadlink to $InstallerPath..."
try {
    Invoke-WebRequest $Downloadlink -Outfile $InstallerPath -UseBasicParsing -ErrorAction Stop
    Write-Output "Download complete."
} catch {
    Write-Output "ERROR: Failed to download RustDesk installer. $($_.Exception.Message)"
    Exit 1 # Exit with a non-zero code to indicate failure
}

# Install RustDesk silently without showing a window
Write-Output "Starting silent installation..."
$installProcess = Start-Process -FilePath $InstallerPath -ArgumentList '--silent-install' -WindowStyle Hidden -PassThru -Wait
if ($installProcess.ExitCode -ne 0) {
    Write-Output "ERROR: Installer exited with code $($installProcess.ExitCode). Installation may have failed."
    # Consider exiting here depending on how critical a zero exit code is
    # Exit 1
} else {
    Write-Output "Installer process completed."
}

# Allow time for installation/upgrade processes to finish before service interaction
Write-Output "Waiting 20 seconds for installation to settle..."
Start-Sleep -seconds 20

# Define expected installation path
$RustDeskPath = Join-Path $env:ProgramFiles "RustDesk"
$RustDeskExe = Join-Path $RustDeskPath "rustdesk.exe"

if (!(Test-Path $RustDeskExe)) {
     Write-Output "ERROR: RustDesk executable not found at '$RustDeskExe' after installation attempt."
     Exit 1
}

# Check if service exists and install if needed
$arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($arrService -eq $null) {
    Write-Output "RustDesk service not found. Installing service..."
    $serviceInstallProcess = Start-Process -FilePath $RustDeskExe -ArgumentList '--install-service' -WindowStyle Hidden -PassThru -Wait
    if ($serviceInstallProcess.ExitCode -ne 0) {
         Write-Output "WARNING: Service installation command exited with code $($serviceInstallProcess.ExitCode)."
         # Don't necessarily exit, the service might still get created shortly after
    } else {
        Write-Output "Service installation command completed."
    }
    # Wait for service to potentially appear
    Write-Output "Waiting 20 seconds for service to register..."
    Start-Sleep -seconds 20
    $arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($arrService -eq $null) {
        Write-Output "ERROR: Service '$ServiceName' still not found after installation attempt."
        Exit 1
    }
} else {
    Write-Output "RustDesk service already exists."
}

# Ensure the service is running
Write-Output "Ensuring RustDesk service is running..."
$attempts = 0
while ($arrService.Status -ne 'Running' -and $attempts -lt 5) {
    $attempts++
    Write-Output "Attempt ${attempts}: Starting service '$ServiceName'..."
    Start-Service $ServiceName -ErrorAction SilentlyContinue
    Start-Sleep -seconds 5
    $arrService.Refresh()
    Write-Output "Current service status: $($arrService.Status)"
}

if ($arrService.Status -ne 'Running') {
    Write-Output "ERROR: Failed to start the RustDesk service after $attempts attempts."
    Exit 1
} else {
    Write-Output "RustDesk service is running."
}

# Get RustDesk ID (capture to variable only first)
Write-Output "Retrieving RustDesk ID..."
$rustdesk_id_output = ""
try {
    # Execute and capture standard output.
    $rustdesk_id_output = (& "$RustDeskExe" --get-id)
    if ($LASTEXITCODE -ne 0) {
         Write-Output "WARNING: --get-id command exited with code $LASTEXITCODE."
    }
} catch {
    Write-Output "ERROR: Failed to execute RustDesk to get ID. $($_.Exception.Message)"
    # Decide if you want to exit or continue without ID
    # Exit 1
}
# Process the output if necessary (sometimes includes extra lines)
$rustdesk_id = ($rustdesk_id_output | Select-Object -First 1).Trim()

# Apply configuration
Write-Output "Applying configuration..."
try {
    & "$RustDeskExe" --config $rustdesk_cfg
    if ($LASTEXITCODE -ne 0) {
         Write-Output "WARNING: --config command exited with code $LASTEXITCODE."
    }
} catch {
     Write-Output "ERROR: Failed to apply configuration. $($_.Exception.Message)"
     # Exit 1
}


# Set password
Write-Output "Setting password..."
try {
    & "$RustDeskExe" --password $rustdesk_pw
     if ($LASTEXITCODE -ne 0) {
         Write-Output "WARNING: --password command exited with code $LASTEXITCODE."
    }
} catch {
     Write-Output "ERROR: Failed to set password. $($_.Exception.Message)"
     # Exit 1
}

# --- Output Results for RMM ---
Write-Output "..............................................."
Write-Output "RustDesk Deployment Summary:"
# Show the value of the ID Variable (check if it was retrieved)
if ($rustdesk_id) {
    Write-Output "RustDesk ID: $rustdesk_id"
} else {
    Write-Output "RustDesk ID: Failed to retrieve."
}
# Show the value of the Password Variable
Write-Output "Configured Password: $rustdesk_pw" # Use the specific password value
Write-Output "..............................................."
Write-Output "Script completed."
Exit 0 # Explicitly exit with success code