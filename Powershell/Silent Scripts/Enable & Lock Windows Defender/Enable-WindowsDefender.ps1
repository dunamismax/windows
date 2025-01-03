# Enable Windows Defender Antivirus

# Ensure that the Windows Defender service (WinDefend) is enabled and started
Set-Service -Name WinDefend -StartupType Automatic
Start-Service -Name WinDefend

# Enable Windows Defender real-time protection
Set-MpPreference -DisableRealtimeMonitoring $false

# Configure Windows Defender as the primary antivirus
Set-MpPreference -DisableAntiSpyware $false

# Prevent users from disabling Windows Defender through Group Policy
# These registry keys enforce Windows Defender settings and prevent changes
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableRealtimeMonitoring" -Value 0 -Force

# Ensure Tamper Protection is enabled (available in Windows 10 Pro and Enterprise)
# This protects Windows Defender settings from being changed
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features"
$registryName = "TamperProtection"
$registryValue = 5  # 5 = Enabled, 0 = Disabled
Set-ItemProperty -Path $registryPath -Name $registryName -Value $registryValue -Force

# Hide all output (run silently without user interaction)
$null = Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
$null = Set-MpPreference -DisableScriptScanning $false

# No logging or output
$null = Out-Null