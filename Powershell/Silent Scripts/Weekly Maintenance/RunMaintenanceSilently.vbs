' VBScript Wrapper to Run Maintenance Script Silently with Admin Rights

Option Explicit

' Create objects for shell operations and file system operations
Dim objShell, objFSO, objWShell
Set objShell = CreateObject("Shell.Application")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objWShell = CreateObject("WScript.Shell")

' Function to check if script is running with admin rights
Function IsAdmin()
    On Error Resume Next
    objWShell.RegRead("HKEY_USERS\S-1-5-19\Environment\TEMP")
    IsAdmin = (Err.Number = 0)
    On Error GoTo 0
End Function

' Function to log messages with improved timestamp formatting
Sub LogMessage(message)
    Dim logFolder, logFile, file, formattedTime
    logFolder = "C:\Scripts\Logs"
    logFile = objFSO.BuildPath(logFolder, "MaintenanceScriptLog.txt")
    formattedTime = FormatDateTime(Now, vbGeneralDate)

    ' Ensure silent operation; no screen output
    If Not objFSO.FolderExists(logFolder) Then
        On Error Resume Next
        objFSO.CreateFolder(logFolder)
        On Error GoTo 0
    End If
    
    On Error Resume Next
    Set file = objFSO.OpenTextFile(logFile, 8, True)
    If Err.Number = 0 Then
        file.WriteLine formattedTime & " - " & message
        file.Close
    End If
    On Error GoTo 0
End Sub

' Function to write full PowerShell output to a file
Sub WriteFullLog(content)
    Dim fullLogFile, file
    fullLogFile = "C:\Scripts\Logs\full_log.txt"
    
    On Error Resume Next
    Set file = objFSO.OpenTextFile(fullLogFile, 2, True)
    If Err.Number = 0 Then
        file.Write content
        file.Close
    Else
        LogMessage "Failed to open full log file: " & Err.Description
    End If
    On Error GoTo 0
End Sub

' Main execution
Sub Main()
    LogMessage "VBScript started"
    Dim strScriptDir, strPSScript, strCommand
    strScriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
    strPSScript = objFSO.BuildPath(strScriptDir, "WeeklyMaintenance.ps1")
    LogMessage "Attempting to run PowerShell script: " & strPSScript
    If objFSO.FileExists(strPSScript) Then
        strCommand = "powershell.exe -ExecutionPolicy Bypass -NoProfile -File """ & strPSScript & """ -Verbose *>&1"
        LogMessage "Executing command: " & strCommand
        
        If Not IsAdmin() Then
            LogMessage "Elevating privileges to run as Administrator"
            On Error Resume Next
            objShell.ShellExecute "powershell.exe", strCommand, "", "runas", 0
            If Err.Number <> 0 Then
                LogMessage "Failed to elevate privileges: " & Err.Description
            Else
                LogMessage "Elevated process started. VBScript will exit now."
            End If
            On Error GoTo 0
        Else
            Dim objExec, fullOutput, errorOutput
            Set objExec = objWShell.Exec(strCommand)
            
            ' Wait for the script to finish
            Do While objExec.Status = 0
                WScript.Sleep 100
            Loop
            
            fullOutput = objExec.StdOut.ReadAll()
            errorOutput = objExec.StdErr.ReadAll()
            WriteFullLog fullOutput & vbCrLf & errorOutput
            
            LogMessage "PowerShell Exit Code: " & objExec.ExitCode
            If objExec.ExitCode <> 0 Then
                LogMessage "Error: PowerShell script ended with an error. Exit Code: " & objExec.ExitCode
                LogMessage "Error Output: " & errorOutput
            Else
                LogMessage "PowerShell script completed successfully"
            End If
        End If
    Else
        LogMessage "PowerShell script not found: " & strPSScript
    End If
    LogMessage "VBScript execution completed"
End Sub

' Run the main execution
Main

' Clean up objects
Set objShell = Nothing
Set objFSO = Nothing
Set objWShell = Nothing

' Ensure the script exits silently
WScript.Quit 0
