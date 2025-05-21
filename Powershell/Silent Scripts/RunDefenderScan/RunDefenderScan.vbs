Dim objShell
Set objShell = WScript.CreateObject("WScript.Shell")
objShell.Run "powershell -NoProfile -ExecutionPolicy Bypass -File ""C:\path\to\your\DefenderScan.ps1""", 0, True
Set objShell = Nothing
