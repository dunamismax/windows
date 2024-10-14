' VBScript Wrapper to Run Complete Setup Silently

' Create objects for shell operations and file system operations
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get the script's directory
strScriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Function to run a PowerShell script silently
Sub RunPowerShellScriptSilently(scriptName)
    strPSScript = objFSO.BuildPath(strScriptDir, scriptName)
    
    If objFSO.FileExists(strPSScript) Then
        strCommand = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & strPSScript & """"
        objShell.Run strCommand, 0, True
    Else
        ' Optionally, log an error if the PowerShell script is not found
        ' WScript.Echo "PowerShell script not found: " & strPSScript
    End If
End Sub

' Run the setup script
RunPowerShellScriptSilently "SetupStartupServices.ps1"

' Run the script to create the startup task
RunPowerShellScriptSilently "CreateStartupTask.ps1"

' Clean up objects
Set objShell = Nothing
Set objFSO = Nothing

' Ensure the script exits silently
WScript.Quit 0