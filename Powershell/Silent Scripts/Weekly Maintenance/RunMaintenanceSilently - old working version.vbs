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

    ' Create the log folder if it doesn't exist with error handling
    If Not objFSO.FolderExists(logFolder) Then
        On Error Resume Next
        objFSO.CreateFolder(logFolder)
        If Err.Number <> 0 Then
            WScript.Echo "Failed to create log folder: " & Err.Description
            Err.Clear
            Exit Sub
        End If
        On Error GoTo 0
    End If
    
    ' Open or create the log file with error handling
    On Error Resume Next
    Set file = objFSO.OpenTextFile(logFile, 8, True)
    If Err.Number <> 0 Then
        WScript.Echo "Failed to open log file: " & Err.Description
        Err.Clear
        Exit Sub
    End If
    file.WriteLine formattedTime & " - " & message
    file.Close
    On Error GoTo 0
End Sub

' Function to write full PowerShell output to a file
Sub WriteFullLog(content)
    Dim fullLogFile, file
    fullLogFile = "C:\Scripts\Logs\full_log.txt"
    
    On Error Resume Next
    Set file = objFSO.OpenTextFile(fullLogFile, 8, True)
    If Err.Number <> 0 Then
        LogMessage "Failed to open full log file: " & Err.Description
        Err.Clear
        Exit Sub
    End If
    file.Write content
    file.Close
    On Error GoTo 0
End Sub

' Main execution
Sub Main()
    ' Log start of the script
    LogMessage "VBScript started"

    ' Get the script's directory
    Dim strScriptDir, strPSScript, strCommand
    strScriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)

    ' Construct the path to the PowerShell script
    strPSScript = objFSO.BuildPath(strScriptDir, "WeeklyMaintenance.ps1")

    LogMessage "Attempting to run PowerShell script: " & strPSScript

    ' Check if the PowerShell script exists
    If objFSO.FileExists(strPSScript) Then
        ' Construct the command to run PowerShell
        strCommand = "powershell.exe -ExecutionPolicy Bypass -NoProfile -File """ & strPSScript & """ -Verbose *>&1"
        
        LogMessage "Executing command: " & strCommand
        
        ' Check if we're already running as admin
        If Not IsAdmin() Then
            LogMessage "Elevating privileges to run as Administrator"
            On Error Resume Next
            objShell.ShellExecute "powershell.exe", "-ExecutionPolicy Bypass -NoProfile -File """ & strPSScript & """ -Verbose *>&1", "", "runas", 1
            If Err.Number <> 0 Then
                LogMessage "Error elevating privileges: " & Err.Description
                Err.Clear
            Else
                LogMessage "Elevated process started. VBScript will exit now."
            End If
            On Error GoTo 0
        Else
            ' Already running as admin, execute normally
            Dim objExec, fullOutput
            Set objExec = objWShell.Exec(strCommand)
            
            ' Capture full output
            fullOutput = objExec.StdOut.ReadAll()
            
            ' Write full output to log file
            WriteFullLog fullOutput
            
            LogMessage "PowerShell Exit Code: " & objExec.ExitCode
            LogMessage "Full output written to C:\Scripts\Logs\full_log.txt"

            ' Enhanced error handling based on exit code
            If objExec.ExitCode <> 0 Then
                LogMessage "Error: PowerShell script ended with an error. Exit Code: " & objExec.ExitCode
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