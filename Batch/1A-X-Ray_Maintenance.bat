@echo off
title Running Fixes (this will take a bit)
cls

:: Ensure the directory exists
if not exist "C:\ImagingServices" (
    mkdir "C:\ImagingServices"
)

:: Get the current date in YYYYMMDD format
for /f "tokens=2 delims==" %%i in ('"wmic os get localdatetime /value"') do set dt=%%i
set currentdate=%dt:~0,8%

:: Log file path
set logfile=C:\ImagingServices\MaintenanceLog.txt

:: Rename the existing log file if it exists
if exist %logfile% (
    rename %logfile% MaintenanceLog_%currentdate%.txt
)

:: Proceed with the rest of the script
echo Logging to %logfile%


:: Function to check if running as administrator
:checkAdmin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo "This script requires administrative privileges. Please run as administrator." >> %logfile%
    pause
    exit /b
)

:: Logging function
:log
echo %date% %time%: %* >> %logfile%
goto :eof


:: Creating batch file in Startup folder that runs when the computer boots and starts all services including Datto RMM
:log "*******************************"
:log "Creating Startup Batch"
:: Define variables
set STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
set BATCH_FILE_NAME=StartXray.bat
set BATCH_FILE_PATH=%STARTUP_FOLDER%\%BATCH_FILE_NAME%

:: Check if the batch file already exists
if exist "%BATCH_FILE_PATH%" (
    echo %BATCH_FILE_NAME% already exists in the startup folder.
    goto :eof  :: Exit the script
)

:: Create the batch file
echo Creating %BATCH_FILE_NAME% in the startup folder...

(
    echo "net start "SQL Server (MSSQLSERVER)""
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
) > "%BATCH_FILE_PATH%"

:log echo %BATCH_FILE_NAME% created successfully.
:log "done!"

:: Close the StudyList
:log "*******************************"
:log "Closing the StudyList"
taskkill /F /IM OPALStudyList.exe >> %logfile% 2>&1
:log "done!"

:: Start SQL and WWW
:log "*******************************"
:log "Starting SQL and WWW"
net start "SQL Server (MSSQLSERVER)" >> %logfile% 2>&1
net start "World Wide Web Publishing Service" >> %logfile% 2>&1
:log "done!"

:: Stop all Opal Services
:log "*******************************"
:log "Stopping all Opal Services"
net stop "Opal Agent" >> %logfile% 2>&1
net stop "Opal Backup" >> %logfile% 2>&1
net stop "OpalRad Dicom Print" >> %logfile% 2>&1
net stop "OpalRad DICOM Receive" >> %logfile% 2>&1
net stop "OpalRad Listener" >> %logfile% 2>&1
net stop "OpalRad Router" >> %logfile% 2>&1
net stop "OpalRad ImageServer" >> %logfile% 2>&1
:log "done!"

:: Backup Config Files
:log "*******************************"
:log "Backing up Config Files"
cd C:\opal\cfg
mkdir Backup
Xcopy /y opalconfiguration.xml C:\opal\cfg\Backup >> %logfile% 2>&1
Xcopy /y OpalStudyListConfig.xml C:\opal\cfg\Backup >> %logfile% 2>&1
:log "done!"

:: Reset the Opal Configuration File
:log "*******************************"
:log "Resetting the Opal Configuration File"
cd C:\opal\cfg
del opalconfiguration.xml >> %logfile% 2>&1
echo ^<?xml version="1.0" encoding="utf-8"?^> > opalconfiguration.xml
echo ^<opalconfiguration^> >> opalconfiguration.xml
echo   ^<database location="localhost@OPALRAD" user="sa" password="1q2w3e4r5t" /^> >> opalconfiguration.xml
echo   ^<packet_size value="4096" /^> >> opalconfiguration.xml
echo   ^<persist_security_info value="True" /^> >> opalconfiguration.xml
echo   ^<ServerConnections^> >> opalconfiguration.xml
echo     ^<database location="localhost" initialcatalog="OPALRAD" user="sa" password="1q2w3e4r5t" packet_size="4096" name="localhost" /^> >> opalconfiguration.xml
echo   ^</ServerConnections^> >> opalconfiguration.xml
echo   ^<study_list_refresh_interval value="2" /^> >> opalconfiguration.xml
echo   ^<transfer_log_refresh_interval value="90" /^> >> opalconfiguration.xml
echo   ^<send_queue_refresh_interval value="90" /^> >> opalconfiguration.xml
echo   ^<IISEnable value="0" /^> >> opalconfiguration.xml
echo   ^<MWLMyAETitle value="" /^> >> opalconfiguration.xml
echo   ^<MWLAETitle value="" /^> >> opalconfiguration.xml
echo   ^<MWLNetworkAddress value="" /^> >> opalconfiguration.xml
echo   ^<MWLPort value="" /^> >> opalconfiguration.xml
echo   ^<MWLName value="" /^> >> opalconfiguration.xml
echo   ^<MWLQueryAETitle value="" /^> >> opalconfiguration.xml
echo   ^<MWLDateRange value="" /^> >> opalconfiguration.xml
echo   ^<MWLModality value="" /^> >> opalconfiguration.xml
echo   ^<MWLStatus value="" /^> >> opalconfiguration.xml
echo   ^<MWLInstitution value="" /^> >> opalconfiguration.xml
echo   ^<MWLNewUID value="False" /^> >> opalconfiguration.xml
echo   ^<MWLIssuerPID value="MWLIssuerPID" /^> >> opalconfiguration.xml
echo   ^<Skin value="1" /^> >> opalconfiguration.xml
echo ^</opalconfiguration^> >> opalconfiguration.xml
:log "done!"

:: Reset the Opal Studylist Configuration File (Acquire Active 4)
:log "*******************************"
:log "Resetting the Opal Studylist Configuration File (Acquire Active 4)"
cd C:\opal\cfg
del OpalStudyListConfig.xml >> %logfile% 2>&1
echo ^<?xml version="1.0"?^> > OpalStudyListConfig.xml
echo ^<Config^> >> OpalStudyListConfig.xml
echo   ^<acquire active="4" /^> >> OpalStudyListConfig.xml
echo   ^<series_per_image active="True" /^> >> OpalStudyListConfig.xml
echo   ^<autoopen active="False" /^> >> OpalStudyListConfig.xml
echo   ^<teachingstudy active="False" /^> >> OpalStudyListConfig.xml
echo   ^<tsname active="" /^> >> OpalStudyListConfig.xml
echo   ^<tsid active="" /^> >> OpalStudyListConfig.xml
echo   ^<krez active="1" /^> >> OpalStudyListConfig.xml
echo   ^<kodakSingleMode active="False" /^> >> OpalStudyListConfig.xml
echo   ^<series_per_image_paper active="True" /^> >> OpalStudyListConfig.xml
echo   ^<splitEditScreen active="True" /^> >> OpalStudyListConfig.xml
echo   ^<ignoreViewed active="False" /^> >> OpalStudyListConfig.xml
echo   ^<maintainLastSearch active="False" /^> >> OpalStudyListConfig.xml
echo   ^<show_desc_bttn active="True" /^> >> OpalStudyListConfig.xml
echo   ^<show_bp_bttn active="True" /^> >> OpalStudyListConfig.xml
echo   ^<show_ref_bttn active="True" /^> >> OpalStudyListConfig.xml
echo   ^<show_read_bttn active="True" /^> >> OpalStudyListConfig.xml
echo   ^<show_inst_bttn active="True" /^> >> OpalStudyListConfig.xml
echo   ^<show_facil_bttn active="True" /^> >> OpalStudyListConfig.xml
echo   ^<show_dept_bttn active="True" /^> >> OpalStudyListConfig.xml
echo ^</Config^> >> OpalStudyListConfig.xml
:log "done!"

:: Changing the SA password for SQL
:log "*******************************"
:log "Changing the SA password for SQL"
sqlcmd -Q "ALTER LOGIN [sa] WITH PASSWORD=N'1q2w3e4r5t'" >> %logfile% 2>&1
:log "done!"

:: Terminating Sessions
:log "*******************************"
:log "Terminating Sessions"
sqlcmd -d opalrad -Q "DELETE FROM USERS_SESSION_INFO;" >> %logfile% 2>&1
:log "done!"

:: Enabling TCP/IP and Named Pipes in SQL
:log "*******************************"
:log "Enabling TCP/IP and Named Pipes in SQL"
WMIC /NAMESPACE:\\root\Microsoft\SqlServer\ComputerManagement12 PATH ServerNetworkProtocol WHERE ProtocolName='Tcp' CALL SetEnable >> %logfile% 2>&1
WMIC /NAMESPACE:\\root\Microsoft\SqlServer\ComputerManagement12 PATH ServerNetworkProtocol WHERE ProtocolName='Np' CALL SetEnable >> %logfile% 2>&1
:log "done!"

:: Add Firewall Ports for Opal
:log "*******************************"
:log "Add Firewall Ports for Opal"
netsh advfirewall firewall add rule name="Opal" dir=in action=allow protocol=TCP localport=104,1433,33333-33338,80 >> %logfile% 2>&1
:log "done!"

:: Freeing up storage space
:log "*******************************"
:log "Freeing up storage space"
cd \
cd windows\system32
iisreset /stop >> %logfile% 2>&1

cd C:\Windows\Temp
del * /S /Q >> %logfile% 2>&1
rmdir /S /Q "C:\Windows\Temp" >> %logfile% 2>&1

cd C:\Windows\Logs\CBS
del * /S /Q >> %logfile% 2>&1
rmdir /S /Q "C:\Windows\Logs\CBS" >> %logfile% 2>&1

cd C:\inetpub\wwwroot\OpalWeb\OpalImages
del * /S /Q >> %logfile% 2>&1
rmdir /S /Q "C:\inetpub\wwwroot\OpalWeb\OpalImages" >> %logfile% 2>&1

cd C:\inetpub\wwwroot\OpalWeb.Services\cache
del * /S /Q >> %logfile% 2>&1
rmdir /S /Q "C:\inetpub\wwwroot\OpalWeb.Services\cache" >> %logfile% 2>&1

cacls c:\inetpub\wwwroot /t /e /g Administrators:f >> %logfile% 2>&1
cacls c:\inetpub\wwwroot /t /e /g "2020tech":f >> %logfile% 2>&1
cacls c:\inetpub\wwwroot /t /e /g "opal":f >> %logfile% 2>&1
cacls c:\inetpub\wwwroot /t /e /g Users:f >> %logfile% 2>&1
cacls c:\inetpub\wwwroot /t /e /g Everyone:f >> %logfile% 2>&1
cacls c:\inetpub\wwwroot /t /e /g "Network Service":f >> %logfile% 2>&1
cacls c:\inetpub\wwwroot /t /e /g "Local Service":f >> %logfile% 2>&1

cd \
cd windows\system32
iisreset /start >> %logfile% 2>&1
:log "done!"

:: Disable Fast Startup
:log "*******************************"
:log "Disable Fast Startup"
powercfg /hibernate OFF >> %logfile% 2>&1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_dWORD /D 0 /F >> %logfile% 2>&1
:log "done!"

:: Disable Security Warnings
:log "*******************************"
:log "Disable Security Warnings"
REG ADD "HKCU\Environment" /V SEE_MASK_NOZONECHECKS /T REG_SZ /D 1 /F >> %logfile% 2>&1
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V SEE_MASK_NOZONECHECKS /T REG_SZ /D 1 /F >> %logfile% 2>&1
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v LowRiskFileTypes /f /d ".bat" >> %logfile% 2>&1
:log "done!"

:: Disabling UAC
:log "*******************************"
:log "Disabling UAC"
%windir%\System32\reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f >> %logfile% 2>&1
:log "done!"

:: Set High Performance Power Plan
:log "*******************************"
:log "Set High Performance Power Plan"
:log "Set HDD Always on"
powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >> %logfile% 2>&1
powercfg -change -disk-timeout-ac 0 >> %logfile% 2>&1
:log "done!"

:: Set High Performance Power Plan
:log "*******************************"
:log "Disable USB Selective Suspend Setting and Adaptive Display Setting"
:log "Set HDD sleep to 2hrs"
powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >> %logfile% 2>&1
for /f "tokens=2 delims=:" %%G in ('powercfg -getactivescheme') do set guid=%%G
for /f %%G in ("%guid%") do set guid=%%G
powercfg -setacvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000 >> %logfile% 2>&1
powercfg -setdcvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000 >> %logfile% 2>&1
powercfg -setacvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000 >> %logfile% 2>&1
powercfg -setdcvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000 >> %logfile% 2>&1
powercfg -change -disk-timeout-ac 240 >> %logfile% 2>&1
:log "done!"

:: Adding ASPState Database in SQL
:log "*******************************"
:log "Adding ASPState Database in SQL"
cd C:\Windows\Microsoft.NET\Framework\v2.0.50727\
aspnet_regSQL -E -S localhost -ssadd >> %logfile% 2>&1
:log "done!"

:: Register ASP.NET
:log "*******************************"
:log "Register ASP.NET"
cd %SYSTEMROOT%\Microsoft.NET\Framework\v2.0.50727\
aspnet_regiis.exe -i >> %logfile% 2>&1
cd %SYSTEMROOT%\Microsoft.NET\Framework\v4.0.30319\
aspnet_regiis.exe -i >> %logfile% 2>&1
:log "done!"

:: Disable USB Selective Suspend Setting and Adaptive Display Setting
:log "*******************************"
:log "Disable USB Selective Suspend Setting and Adaptive Display Setting"
powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >> %logfile% 2>&1
for /f "tokens=2 delims=:" %%G in ('powercfg -getactivescheme') do set guid=%%G
for /f %%G in ("%guid%") do set guid=%%G
powercfg -setacvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000 >> %logfile% 2>&1
powercfg -setdcvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000 >> %logfile% 2>&1
powercfg -setacvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000 >> %logfile% 2>&1
powercfg -setdcvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000 >> %logfile% 2>&1
:log "done!"

:: Setting StudyList to run as admin
:log "*******************************"
:log "Setting StudyList to run as admin"
reg.exe Add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "C:\opal\bin\OPALStudyList.exe" /d "RUNASADMIN" /f >> %logfile% 2>&1
:log "done!"

:: Restarting all Opal Services
:log "*******************************"
:log "Restarting all Opal Services"
net stop "Opal Agent" >> %logfile% 2>&1
net stop "Opal Backup" >> %logfile% 2>&1
net stop "OpalRad Dicom Print" >> %logfile% 2>&1
net stop "OpalRad DICOM Receive" >> %logfile% 2>&1
net stop "OpalRad Listener" >> %logfile% 2>&1
net stop "OpalRad Router" >> %logfile% 2>&1
net stop "OpalRad ImageServer" >> %logfile% 2>&1
net stop "SQL Server (MSSQLSERVER)" >> %logfile% 2>&1
iisreset >> %logfile% 2>&1
net start "SQL Server (MSSQLSERVER)" >> %logfile% 2>&1
net start "OpalRad ImageServer" >> %logfile% 2>&1
net start "OpalRad Dicom Print" >> %logfile% 2>&1
net start "OpalRad DICOM Receive" >> %logfile% 2>&1
net start "OpalRad Listener" >> %logfile% 2>&1
net start "OpalRad Router" >> %logfile% 2>&1
net start "Opal Agent" >> %logfile% 2>&1
net start "Opal Backup" >> %logfile% 2>&1
net start "OpalRad Modality Worklist" >> %logfile% 2>&1
net start "World Wide Web Publishing Service" >> %logfile% 2>&1
:log "done!"

:: Fixing Opal Web
:log "*******************************"
:log "Fixing Opal Web"
net stop "W3SVC" >> %logfile% 2>&1
cd C:\inetpub\wwwroot\OpalWeb
powershell -command "(Get-Content .\web.config) | Where-Object {$_ -notmatch 'UnhandledExceptionModule'} | Set-Content web.config" >> %logfile% 2>&1
net start "W3SVC" >> %logfile% 2>&1
:log "done!"

:: Adding ASPState Database in SQL
:log "*******************************"
:log "Adding ASPState Database in SQL"
cd C:\Windows\Microsoft.NET\Framework\v2.0.50727\
aspnet_regSQL -E -S localhost -ssadd >> %logfile% 2>&1
:log "done!"

:: Changing the SA password for SQL
:log "*******************************"
:log "Changing the SA password for SQL"
sqlcmd -Q "ALTER LOGIN [sa] WITH PASSWORD=N'1q2w3e4r5t'" >> %logfile% 2>&1
:log "done!"

:: Set permissions for Opal folder
:log "*******************************"
:log "Setting permissions for Opal folder"
icacls "C:\opal\bin" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\bin" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\bin" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\bin" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\bin" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\bin" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\bin /r /d y >> %logfile% 2>&1

icacls "C:\opal\cfg" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\cfg" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\cfg" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\cfg" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\cfg" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\cfg" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\cfg /r /d y >> %logfile% 2>&1

icacls "C:\opal\data" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\data" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\data" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\data" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\data" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\data" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\data /r /d y >> %logfile% 2>&1

icacls "C:\opal\Backup" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\Backup" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\Backup" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\Backup" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\Backup" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\Backup" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\Backup /r /d y >> %logfile% 2>&1

icacls "C:\opal\cache" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\cache" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\cache" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\cache" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\cache" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\cache" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\cache /r /d y >> %logfile% 2>&1

icacls "C:\opal\driver" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\driver" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\driver" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\driver" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\driver" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\driver" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\driver /r /d y >> %logfile% 2>&1

icacls "C:\opal\log" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\log" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\log" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\log" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\log" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\log" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\log /r /d y >> %logfile% 2>&1

icacls "C:\opal\opal" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\opal" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\opal" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\opal" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\opal" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\opal" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\opal /r /d y >> %logfile% 2>&1

icacls "C:\opal\opallite" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\opallite" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\opallite" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\opallite" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\opallite" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\opallite" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\opallite /r /d y >> %logfile% 2>&1

icacls "C:\opal\plugins32" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\plugins32" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\plugins32" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\plugins32" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\plugins32" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\plugins32" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\plugins32 /r /d y >> %logfile% 2>&1

icacls "C:\opal\plugins64" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\plugins64" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\plugins64" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\plugins64" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\plugins64" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\plugins64" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\plugins64 /r /d y >> %logfile% 2>&1

icacls "C:\opal\uaiarchive" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\uaiarchive" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\uaiarchive" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\uaiarchive" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\uaiarchive" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "C:\opal\uaiarchive" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f C:\opal\uaiarchive /r /d y >> %logfile% 2>&1

icacls "D:\opal\" /grant "NETWORK SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "D:\opal\" /grant "LOCAL SERVICE":(OI)(CI)F /T >> %logfile% 2>&1
icacls "D:\opal\" /grant "Everyone":(OI)(CI)F /T >> %logfile% 2>&1
icacls "D:\opal\" /grant "Authenticated Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "D:\opal\" /grant "Users":(OI)(CI)F /T >> %logfile% 2>&1
icacls "D:\opal\" /grant "Administrators":(OI)(CI)F /T >> %logfile% 2>&1
takeown /f D:\opal\ /r /d y >> %logfile% 2>&1
:log "done!"

:: Batch script for Windows 10 / 11 maintenance
:: Run as administrator

:checkAdmin
net session >nul 2>&1
if %errorLevel% neq 0 (
    :log "This script requires administrative privileges. Please run as administrator."
    pause
    exit /b
)

:: Disk Cleanup
:log "Running Disk Cleanup..."
cleanmgr /sagerun:1 >> %logfile% 2>&1

:: Delete Temporary Files
:log "Deleting temporary files..."
del /s /q /f %temp%\* >> %logfile% 2>&1
rd /s /q %temp% >> %logfile% 2>&1
md %temp% >> %logfile% 2>&1

:: System File Checker
:log "Running System File Checker..."
sfc /scannow >> %logfile% 2>&1

:: Check Disk for Errors
:log "Checking disk for errors..."
chkdsk C: /f /r >> %logfile% 2>&1
chkdsk D: /f /r >> %logfile% 2>&1

:: Windows Update
:log "Running Windows Update..."
powershell -Command "Install-Module PSWindowsUpdate -Force -Scope CurrentUser" >> %logfile% 2>&1
powershell -Command "Import-Module PSWindowsUpdate; Get-WindowsUpdate; Install-WindowsUpdate -AcceptAll -AutoReboot" >> %logfile% 2>&1

:: Windows Defender Update and Scan
:log "Updating and running Windows Defender scan..."
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate >> %logfile% 2>&1
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2 >> %logfile% 2>&1

:: Check Drive Type and Optimize
for /f "tokens=2 delims==" %%i in ('wmic diskdrive get model^, mediatype /format:list ^| find "MediaType"') do (
    if /i "%%i"=="Fixed hard disk media" (
        :log "Optimizing HDD..."
        defrag C: /O >> %logfile% 2>&1
        defrag D: /O >> %logfile% 2>&1
    ) else (
        :log "Skipping defrag for SSD..."
    )
)

:: Clear DNS Cache
:log "Clearing DNS cache..."
ipconfig /flushdns >> %logfile% 2>&1

:: Run Network Diagnostics without Resetting IPs
:log "Testing network connectivity with ping..."
start cmd /c "ping www.google.com >> %logfile% 2>&1"
timeout /t 60 /nobreak
taskkill /f /im ping.exe >nul 2>&1

:log "Tracing route to www.google.com..."
start cmd /c "tracert www.google.com >> %logfile% 2>&1"
timeout /t 60 /nobreak
taskkill /f /im tracert.exe >nul 2>&1

:log "Checking DNS resolution..."
start cmd /c "nslookup www.google.com >> %logfile% 2>&1"
timeout /t 60 /nobreak
taskkill /f /im nslookup.exe >nul 2>&1

:: Reboot System
:log "Maintenance complete. The system will now reboot."
shutdown /r /t 60

:: End of script
