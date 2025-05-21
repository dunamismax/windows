' VBScript to silently run the PowerShell script in the same directory

Option Explicit
Dim shell, scriptPath, psCommand

' Create a shell object
Set shell = CreateObject("WScript.Shell")

' Get the directory of the VBScript and locate the PowerShell script
scriptPath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\Enable-WindowsDefender.ps1"

' Build PowerShell command to run the script silently
psCommand = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """"

' Execute the PowerShell script silently
shell.Run psCommand, 0, True  ' 0 = Hidden window, True = Wait for completion

' Clean up
Set shell = Nothing