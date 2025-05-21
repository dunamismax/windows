' RunPSScript.vbs
Dim objShell
Set objShell = CreateObject("WScript.Shell")

' Path to the PowerShell script
Dim scriptPath
scriptPath = "C:\path\to\your\ShowMessage.ps1"

' Command to run the PowerShell script
Dim command
command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & scriptPath & """"

' Run the PowerShell script
objShell.Run command, 0, True

' Clean up
Set objShell = Nothing