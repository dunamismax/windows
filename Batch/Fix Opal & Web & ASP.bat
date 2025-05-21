title Running Fixes (this might take a while)
cls
@echo off

echo.
echo *******************************
echo Closing the StudyList
echo *******************************
taskkill /F /IM OPALStudyList.exe
echo done!

echo.
echo *******************************
echo Starting SQL and WWW
echo *******************************
net start "SQL Server (MSSQLSERVER)" 
net start "World Wide Web Publishing Service"
echo done!

echo.
echo *******************************
echo Stopping all Opal Services
echo *******************************
net stop "Opal Agent"
net stop "Opal Backup"
net stop "OpalRad Dicom Print"
net stop "OpalRad DICOM Receive"
net stop "OpalRad Listener"
net stop "OpalRad Router"
net stop "OpalRad ImageServer"
echo done!

echo.
echo *******************************
echo Backing up Config Files
echo *******************************
cd C:\opal\cfg
mkdir Backup
Xcopy /y opalconfiguration.xml C:\opal\cfg\Backup
Xcopy /y OpalStudyListConfig.xml C:\opal\cfg\Backup

echo.
echo *******************************
echo Resetting the Opal Configuration File
echo *******************************
cd C:\opal\cfg
del opalconfiguration.xml
echo ^<?xml version="1.0" encoding="utf-8"?^> >> opalconfiguration.xml
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
echo done!

echo.
echo *******************************
echo Resetting the Opal Studylist Configuration File (Acquire Active 4)
echo *******************************
cd C:\opal\cfg
del OpalStudyListConfig.xml
echo ^<?xml version="1.0"?^> >> OpalStudyListConfig.xml
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
echo done!

echo.
echo *******************************
echo Changing the SA password for SQL
echo *******************************
sqlcmd -Q "ALTER LOGIN [sa] WITH PASSWORD=N'1q2w3e4r5t'"
echo done!

echo.
echo *******************************
echo Terminating Sessions
echo *******************************
sqlcmd -d opalrad -Q "DELETE FROM USERS_SESSION_INFO;"
echo done!

echo.
echo *******************************
echo Enabling TCP/IP and Named Pipes in SQL
echo *******************************
WMIC /NAMESPACE:\\root\Microsoft\SqlServer\ComputerManagement12 PATH ServerNetworkProtocol WHERE ProtocolName='Tcp' CALL SetEnable
WMIC /NAMESPACE:\\root\Microsoft\SqlServer\ComputerManagement12 PATH ServerNetworkProtocol WHERE ProtocolName='Np' CALL SetEnable
echo done!

echo.
echo *******************************
echo Add Firewall Ports for Opal
echo *******************************
netsh advfirewall firewall add rule name="Opal" dir=in action=allow protocol=TCP localport=104,1433,33333-33338,80
echo done!

echo.
echo *******************************
echo Freeing up storage space
echo *******************************
cd \
cd windows\system32
iisreset /stop

cd C:\Windows\Temp
del * /S /Q
rmdir /S /Q "C:\Windows\Temp"

cd C:\Windows\Logs\CBS
del * /S /Q
rmdir /S /Q "C:\Windows\Logs\CBS"

cd C:\inetpub\wwwroot\OpalWeb\OpalImages
del * /S /Q
rmdir /S /Q "C:\inetpub\wwwroot\OpalWeb\OpalImages"

cd C:\inetpub\wwwroot\OpalWeb.Services\cache
del * /S /Q
rmdir /S /Q "C:\inetpub\wwwroot\OpalWeb.Services\cache"

cacls c:\inetpub\wwwroot /t /e /g Administrators:f
cacls c:\inetpub\wwwroot /t /e /g "2020tech":f
cacls c:\inetpub\wwwroot /t /e /g "opal":f
cacls c:\inetpub\wwwroot /t /e /g Users:f
cacls c:\inetpub\wwwroot /t /e /g Everyone:f
cacls c:\inetpub\wwwroot /t /e /g "Network Service":f
cacls c:\inetpub\wwwroot /t /e /g "Local Service":f

cd \
cd windows\system32
iisreset /start
echo done!

echo.
echo *******************************
echo Disable Fast Startup
echo *******************************
powercfg /hibernate OFF
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_dWORD /D 0 /F
echo done!

echo.
echo *******************************
echo Disable Security Warnings
echo *******************************
REG ADD "HKCU\Environment" /V SEE_MASK_NOZONECHECKS /T REG_SZ /D 1 /F
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V SEE_MASK_NOZONECHECKS /T REG_SZ /D 1 /F
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v LowRiskFileTypes /f /d ".bat"
echo done!

echo.
echo *******************************
echo Disabling UAC
echo *******************************
%windir%\System32\reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
echo done!

echo.
echo *******************************
echo Set High Performance Power Plan
echo Set HDD Always on
echo *******************************
powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -change -disk-timeout-ac 0
echo done!

echo.
echo *******************************
echo Set High Performance Power Plan
echo Disable USB Selective Suspend Setting and Adaptive Display Setting
echo Set HDD sleep to 2hrs
echo *******************************
powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
for /f "tokens=2 delims=:" %%G in ('powercfg -getactivescheme') do set guid=%%G
for /f %%G in ("%guid%") do set guid=%%G
powercfg -setacvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000
powercfg -setdcvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000
powercfg -setacvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000
powercfg -setdcvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000
powercfg -change -disk-timeout-ac 240
echo done!

echo.
echo *******************************
echo Adding ASPState Database in SQL
echo *******************************
cd C:\Windows\Microsoft.NET\Framework\v2.0.50727\
aspnet_regSQL -E -S localhost -ssadd
echo done!

echo.
echo *******************************
echo Register ASP.NET
echo *******************************
cd %SYSTEMROOT%\Microsoft.NET\Framework\v2.0.50727\
aspnet_regiis.exe -i
cd %SYSTEMROOT%\Microsoft.NET\Framework\v4.0.30319\
aspnet_regiis.exe -i
echo done!

echo.
echo *******************************
echo Disable USB Selective Suspend Setting and Adaptive Display Setting
echo *******************************
powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
for /f "tokens=2 delims=:" %%G in ('powercfg -getactivescheme') do set guid=%%G
for /f %%G in ("%guid%") do set guid=%%G
powercfg -setacvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000
powercfg -setdcvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000
powercfg -setacvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000
powercfg -setdcvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000
echo done!

echo.
echo *******************************
echo Setting StudyList to run as admin
echo *******************************
reg.exe Add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "C:\opal\bin\OPALStudyList.exe" /d "RUNASADMIN" /f
echo done!

echo.
echo *******************************
echo Restarting all Opal Services
echo *******************************
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
echo done!

echo.
echo *******************************
echo Fixes Complete!
echo *******************************
echo.

net stop "W3SVC"
cd C:\inetpub\wwwroot\OpalWeb
powershell -command "(Get-Content .\web.config) | Where-Object {$_ -notmatch 'UnhandledExceptionModule'} | Set-Content web.config"
net start "W3SVC"

cls
@echo off

echo.
echo *******************************
echo Adding ASPState Database in SQL
echo *******************************
cd C:\Windows\Microsoft.NET\Framework\v2.0.50727\
aspnet_regSQL -E -S localhost -ssadd
echo done!

echo.
echo *******************************
echo Changing the SA password for SQL
echo *******************************
sqlcmd -Q "ALTER LOGIN [sa] WITH PASSWORD=N'1q2w3e4r5t'"
echo done!