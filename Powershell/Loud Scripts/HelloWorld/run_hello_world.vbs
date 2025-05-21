' VBScript to execute PowerShell 7 script

' Create shell and file system objects
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Define paths
strPwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
strScriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
strPSScript = objFSO.BuildPath(strScriptDir, "hello_world.ps1")

' Check if pwsh.exe exists
If Not objFSO.FileExists(strPwshPath) Then
    WScript.Echo "PowerShell 7 (pwsh.exe) not found at " & strPwshPath
    WScript.Quit 1
End If

' Check if the PowerShell script exists
If Not objFSO.FileExists(strPSScript) Then
    WScript.Echo "PowerShell script not found: " & strPSScript
    WScript.Quit 1
End If

' Construct the command
strCommand = """" & strPwshPath & """ -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File """ & strPSScript & """"

' Execute the PowerShell script
objShell.Run strCommand, 0, True

' Clean up
Set objShell = Nothing
Set objFSO = Nothing

' Exit successfully
WScript.Quit 0