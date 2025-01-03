@echo off
title Running Fixes (this will take a bit)
cls

:: Configuration Variables
set LOG_FILE=C:\ImagingServices\MaintenanceLog.txt
set STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
set STARTUP_BATCH_FILE=StartXray.bat
set OPAL_CONFIG_FILE=C:\opal\cfg\opalconfiguration.xml
set OPAL_STUD_LIST_CONFIG_FILE=C:\opal\cfg\OpalStudyListConfig.xml

:: Function to Log Messages with Timestamps
:LogMessage
echo %date% %time%: %* >> %LOG_FILE%
goto :eof

:: Function to Check if Running as Administrator
:CheckAdmin
net session >nul 2>&1
if %errorLevel% neq 0 (
    call :LogMessage This script requires administrative privileges. Please run as administrator.
    pause
    exit /b
)
goto :eof

:: Main Script Body
call :CheckAdmin

:: Create the log file if it doesn't exist, or else append to it.
if not exist "C:\ImagingServices" (
    mkdir "C:\ImagingServices"
)

:: Get the current date in YYYYMMDD format
for /f "tokens=2 delims==" %%i in ('"wmic os get localdatetime /value"') do set dt=%%i
set currentdate=%dt:~0,8%

:: Rename the existing log file if it exists
if exist %LOG_FILE% (
    rename %LOG_FILE% MaintenanceLog_%currentdate%.txt
)

:: Logging to file
call :LogMessage Logging to %LOG_FILE%

:: Create Startup Batch File for Opal Services
call :LogMessage Creating startup batch file...
(
    echo net start "SQL Server (MSSQLSERVER)"
    echo net start "OpalRad ImageServer"
    echo net start "OpalRad Dicom Print"
    echo net start "OpalRad DICOM Receive"
    echo net start "OpalRad Listener"
    echo net start "OpalRad Router"
    echo net start "Opal Agent"
    echo net start "Opal Backup"
    echo net start "OpalRad Modality Worklist"
    echo net start "World Wide Web Publishing Service"
    echo net start "Code42 CrashPlan Backup Service"
    echo net start "Datto RMM"
    echo net start "CagService"
) > "%STARTUP_FOLDER%\%STARTUP_BATCH_FILE%"

call :LogMessage Creating %STARTUP_BATCH_FILE% in the startup folder.

:: Close StudyList
call :LogMessage Closing StudyList...
taskkill /F /IM OPALStudyList.exe

:: Backup and Reset Opal Configuration Files
call :LogMessage Backing up and resetting Opal configuration files...
if not exist C:\opal\cfg\Backup mkdir C:\opal\cfg\Backup
copy /y %OPAL_CONFIG_FILE% C:\opal\cfg\Backup
copy /y %OPAL_STUD_LIST_CONFIG_FILE% C:\opal\cfg\Backup

:: Reset the Opal Configuration File to its default state
(
    echo ^<?xml version="1.0" encoding="utf-8"?^> > %OPAL_CONFIG_FILE%
    echo ^<opalconfiguration^> >> %OPAL_CONFIG_FILE%
    echo   ^<database location="localhost@OPALRAD" user="sa" password="1q2w3e4r5t" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<packet_size value="4096" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<persist_security_info value="True" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<ServerConnections^> >> %OPAL_CONFIG_FILE%
    echo     ^<database location="localhost" initialcatalog="OPALRAD" user="sa" password="1q2w3e4r5t" packet_size="4096" name="localhost" /^> >> %OPAL_CONFIG_FILE%
    echo   ^</ServerConnections^> >> %OPAL_CONFIG_FILE%
    echo   ^<study_list_refresh_interval value="2" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<transfer_log_refresh_interval value="90" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<send_queue_refresh_interval value="90" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<IISEnable value="0" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLMyAETitle value="" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLAETitle value="" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLNetworkAddress value="" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLPort value="" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLName value="" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLQueryAETitle value="" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLDateRange value="" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLModality value="" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLStatus value="" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLInstitution value="" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLNewUID value="False" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<MWLIssuerPID value="MWLIssuerPID" /^> >> %OPAL_CONFIG_FILE%
    echo   ^<Skin value="1" /^> >> %OPAL_CONFIG_FILE%
    echo ^</opalconfiguration^> >> %OPAL_CONFIG_FILE%
)

:: Reset the Opal Studylist Configuration File to its default state
(
    echo ^<?xml version="1.0"?^> > %OPAL_STUD_LIST_CONFIG_FILE%
    echo ^<Config^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<acquire active="4" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<series_per_image active="True" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<autoopen active="False" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<teachingstudy active="False" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<tsname active="" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<tsid active="" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<krez active="1" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<kodakSingleMode active="False" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<series_per_image_paper active="True" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<splitEditScreen active="True" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<ignoreViewed active="False" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<maintainLastSearch active="False" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<show_desc_bttn active="True" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<show_bp_bttn active="True" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<show_ref_bttn active="True" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<show_read_bttn active="True" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<show_inst_bttn active="True" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<show_facil_bttn active="True" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo   ^<show_dept_bttn active="True" /^> >> %OPAL_STUD_LIST_CONFIG_FILE%
    echo ^</Config^> >> %OPAL_STUD_LIST_CONFIG_FILE%
)

:: SQL Server Configuration
call :LogMessage Configuring SQL Server...
sqlcmd -Q "ALTER LOGIN [sa] WITH PASSWORD=N'1q2w3e4r5t'"
sqlcmd -d opalrad -Q "DELETE FROM USERS_SESSION_INFO;"
WMIC /NAMESPACE:\\root\Microsoft\SqlServer\ComputerManagement12 PATH ServerNetworkProtocol WHERE ProtocolName='Tcp' CALL SetEnable
WMIC /NAMESPACE:\\root\Microsoft\SqlServer\ComputerManagement12 PATH ServerNetworkProtocol WHERE ProtocolName='Np' CALL SetEnable

:: Firewall Configuration
call :LogMessage Adding firewall rules for Opal...
netsh advfirewall firewall add rule name="Opal" dir=in action=allow protocol=TCP localport=104,1433,33333-33338,80

:: System Cleanup and Optimization
call :LogMessage Cleaning up temporary files and system logs...
del /s /q /f %temp%\*
rmdir /s /q %temp%
md %temp%

for %%D in (
    C:\Windows\Logs\CBS 
    C:\inetpub\wwwroot\OpalWeb\OpalImages
    C:\inetpub\wwwroot\OpalWeb.Services\cache
) do (
    if exist %%D (
        del /s /q /f %%D\*
        rmdir /s /q %%D
    )
)

:: Run System Maintenance Tasks
call :LogMessage Running Disk Cleanup, System File Checker, and Check Disk...
cleanmgr /sagerun:1 
sfc /scannow
chkdsk C: /f /r 
chkdsk D: /f /r

:: Windows Update and Defender
call :LogMessage Updating and running Windows Defender scan...
powershell -Command "Install-Module PSWindowsUpdate -Force -Scope CurrentUser"
powershell -Command "Import-Module PSWindowsUpdate; Get-WindowsUpdate; Install-WindowsUpdate -AcceptAll -AutoReboot"
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2

:: Disk Optimization (Defrag or TRIM)
for /f "tokens=2 delims==" %%i in ('wmic diskdrive get model^, mediatype /format:list ^| find "MediaType"') do (
    if /i "%%i"=="Fixed hard disk media" (
        call :LogMessage Optimizing HDD...
        defrag C: /O
        defrag D: /O
    ) else (
        call :LogMessage Skipping defrag for SSD...
    )
)

:: Network Diagnostics
call :LogMessage Checking network connectivity...
ping -n 4 www.google.com
tracert www.google.com
nslookup www.google.com

:: Additional System Settings
call :LogMessage Disabling Fast Startup, security warnings, and UAC...
powercfg /hibernate OFF
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_DWORD /D 0 /F
REG ADD "HKCU\Environment" /V SEE_MASK_NOZONECHECKS /T REG_SZ /D 1 /F
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V SEE_MASK_NOZONECHECKS /T REG_SZ /D 1 /F
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v LowRiskFileTypes /f /d ".bat"
%windir%\System32\reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f

:: Set Power Plans and Adjust Settings
call :LogMessage Setting power plans and adjusting settings...
powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -change -disk-timeout-ac 0
powercfg -change -disk-timeout-ac 240
for /f "tokens=2 delims=:" %%G in ('powercfg -getactivescheme') do set guid=%%G
powercfg -setacvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000
powercfg -setdcvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000
powercfg -setacvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000
powercfg -setdcvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000

:: ASP.NET and IIS
call :LogMessage Adding ASPState Database and registering ASP.NET...
cd C:\Windows\Microsoft.NET\Framework\v2.0.50727\
aspnet_regSQL -E -S localhost -ssadd
aspnet_regiis.exe -i
cd %SYSTEMROOT%\Microsoft.NET\Framework\v4.0.30319\
aspnet_regiis.exe -i

:: Set permissions for Opal folder
call :LogMessage Setting permissions for Opal folder...
for %%F in (
    "C:\opal\bin"
    "C:\opal\cfg"
    "C:\opal\data"
    "C:\opal\Backup"
    "C:\opal\cache"
    "C:\opal\driver"
    "C:\opal\log"
    "C:\opal\opal"
    "C:\opal\opallite"
    "C:\opal\plugins32"
    "C:\opal\plugins64"
    "C:\opal\uaiarchive"
    "D:\opal\"
) do (
    icacls "%%F" /grant "NETWORK SERVICE":(OI)(CI)F /T
    icacls "%%F" /grant "LOCAL SERVICE":(OI)(CI)F /T
    icacls "%%F" /grant "Everyone":(OI)(CI)F /T
    icacls "%%F" /grant "Authenticated Users":(OI)(CI)F /T
    icacls "%%F" /grant "Users":(OI)(CI)F /T
    icacls "%%F" /grant "Administrators":(OI)(CI)F /T
    takeown /f "%%F" /r /d y
)

:: Restarting all Opal Services
call :LogMessage Restarting all Opal Services...
net stop "Opal Agent"
net stop "Opal Backup"
net stop "OpalRad Dicom Print"
net stop "OpalRad DICOM Receive"
net stop "OpalRad Listener"
net stop "OpalRad Router"
net stop "OpalRad ImageServer"
net stop "SQL Server (MSSQLSERVER)"
iisreset
net start "SQL Server (MSSQLSERVER)"
net start "OpalRad ImageServer"
net start "OpalRad Dicom Print"
net start "OpalRad DICOM Receive"
net start "OpalRad Listener"
net start "OpalRad Router"
net start "Opal Agent"
net start "Opal Backup"
net start "OpalRad Modality Worklist"
net start "World Wide Web Publishing Service"

:: Fixing Opal Web
call :LogMessage Fixing Opal Web...
net stop "W3SVC"
cd C:\inetpub\wwwroot\OpalWeb
powershell -command "(Get-Content .\web.config) | Where-Object {$_ -notmatch 'UnhandledExceptionModule'} | Set-Content web.config"
net start "W3SVC"

:: Finishing Up
call :LogMessage Opal maintenance complete. System will reboot in 1 minute.
shutdown /r /t 60

cd C:\Windows\Microsoft.NET\Framework\v2.0.50727\
aspnet_regSQL -E -S localhost -ssadd
call :LogMessage ASP.NET SQL Registration complete.

sqlcmd -Q "ALTER LOGIN [sa] WITH PASSWORD=N'1q2w3e4r5t'"
echo done!
call :LogMessage SQL Server SA password altered.

net stop "W3SVC"
cd C:\inetpub\wwwroot\OpalWeb
powershell -command "(Get-Content .\web.config) | Where-Object {$_ -notmatch 'UnhandledExceptionModule'} | Set-Content web.config"
net start "W3SVC"
call :LogMessage Opal Web fixed.
