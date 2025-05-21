taskkill /F /IM OPALStudyList.exe

net stop "Opal Agent"
net stop "Opal Backup"
net stop "OpalRad Dicom Print"
net stop "OpalRad DICOM Receive"
net stop "OpalRad Listener"
net stop "OpalRad Router"
net stop "OpalRad ImageServer"

cd C:\opal\cfg
mkdir Backup
Xcopy /y opalconfiguration.xml C:\opal\cfg\Backup
Xcopy /y OpalStudyListConfig.xml C:\opal\cfg\Backup

sqlcmd -Q "ALTER LOGIN [sa] WITH PASSWORD=N'1q2w3e4r5t'"

sqlcmd -d opalrad -Q "DELETE FROM USERS_SESSION_INFO;"

WMIC /NAMESPACE:\root\Microsoft\SqlServer\ComputerManagement12 PATH ServerNetworkProtocol WHERE ProtocolName='Tcp' CALL SetEnable
WMIC /NAMESPACE:\root\Microsoft\SqlServer\ComputerManagement12 PATH ServerNetworkProtocol WHERE ProtocolName='Np' CALL SetEnable

netsh advfirewall firewall add rule name="Opal" dir=in action=allow protocol=TCP localport=104,1433,33333-33338,80

cd
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

cd
cd windows\system32
iisreset /start

powercfg /hibernate OFF
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_dWORD /D 0 /F

REG ADD "HKCU\Environment" /V SEE_MASK_NOZONECHECKS /T REG_SZ /D 1 /F
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V SEE_MASK_NOZONECHECKS /T REG_SZ /D 1 /F
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v LowRiskFileTypes /f /d ".bat"

%windir%\System32\reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f

powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -change -disk-timeout-ac 0

powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
for /f "tokens=2 delims=:" %%G in ('powercfg -getactivescheme') do set guid=%%G
for /f %%G in ("%guid%") do set guid=%%G
powercfg -setacvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000
powercfg -setdcvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000
powercfg -setacvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000
powercfg -setdcvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000
powercfg -change -disk-timeout-ac 240

cd %SYSTEMROOT%\Microsoft.NET\Framework\v2.0.50727
aspnet_regiis.exe -i
cd %SYSTEMROOT%\Microsoft.NET\Framework\v4.0.30319
aspnet_regiis.exe -i

powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
for /f "tokens=2 delims=:" %%G in ('powercfg -getactivescheme') do set guid=%%G
for /f %%G in ("%guid%") do set guid=%%G
powercfg -setacvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000
powercfg -setdcvalueindex %guid% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 000
powercfg -setacvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000
powercfg -setdcvalueindex %guid% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 000

reg.exe Add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "C:\opal\bin\OPALStudyList.exe" /d "RUNASADMIN" /f

cd C:\Windows\Microsoft.NET\Framework\v2.0.50727
aspnet_regSQL -E -S localhost -ssadd

sqlcmd -Q "ALTER LOGIN [sa] WITH PASSWORD=N'1q2w3e4r5t'"

net stop "W3SVC"
cd C:\inetpub\wwwroot\OpalWeb
powershell -command "(Get-Content .\web.config) | Where-Object {$_ -notmatch 'UnhandledExceptionModule'} | Set-Content web.config"
net start "W3SVC"

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