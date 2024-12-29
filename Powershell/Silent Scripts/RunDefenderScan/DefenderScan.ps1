# Set Windows Defender to take automatic action on detected threats
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -ThreatDefaultAction_1 6  # Clean action for low severity
Set-MpPreference -ThreatDefaultAction_2 6  # Clean action for moderate severity
Set-MpPreference -ThreatDefaultAction_3 6  # Clean action for high severity
Set-MpPreference -ThreatDefaultAction_4 6  # Clean action for severe severity

# Start a full scan
Start-MpScan -ScanType FullScan