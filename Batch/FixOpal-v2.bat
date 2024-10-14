@echo off
REM Stop OPALStudyList.exe process
taskkill /F /IM OPALStudyList.exe

REM Stop Opal services
set SERVICES=(
    "Opal Agent"
    "Opal Backup"
    "OpalRad Dicom Print"
    "OpalRad DICOM Receive"
    "OpalRad Listener"
    "OpalRad Router"
    "OpalRad ImageServer"
    "OpalRad Modality Worklist"
    "World Wide Web Publishing Service"
)

for %%S in %SERVICES% do (
    net stop %%~S
)

REM Backup configuration files
set CFG_DIR=C:\opal\cfg
set BACKUP_DIR=%CFG_DIR%\Backup

if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%"
)

xcopy /y "%CFG_DIR%\opalconfiguration.xml" "%BACKUP_DIR%"
xcopy /y "%CFG_DIR%\OpalStudyListConfig.xml" "%BACKUP_DIR%"

REM Enable SQL Server network protocols
for %%P in (Tcp Np) do (
    wmic /namespace:\\root\Microsoft\SqlServer\ComputerManagement12 path ServerNetworkProtocol where "ProtocolName='%%P'" call SetEnable
)

REM Start SQL Server service
net start "SQL Server (MSSQLSERVER)"

REM Change 'sa' password
sqlcmd -Q "ALTER LOGIN [sa] WITH PASSWORD=N'1q2w3e4r5t'"

REM Delete from USERS_SESSION_INFO table
sqlcmd -d opalrad -Q "DELETE FROM USERS_SESSION_INFO;"

REM Add firewall rules
netsh advfirewall firewall add rule name="Opal" dir=in action=allow protocol=TCP localport=104,1433,33333-33338,80

REM Stop IIS
iisreset /stop

REM Clean temporary directories
for %%D in ("%TEMP%", "C:\Windows\Temp", "C:\Windows\Logs\CBS") do (
    if exist "%%~D" (
        echo Deleting contents of %%~D
        del /F /S /Q "%%~D\*"
        FOR /D %%p IN ("%%~D\*") DO rmdir /S /Q "%%p"
    )
)

REM Clean OpalWeb cache directories
set OPALWEB_DIR=C:\inetpub\wwwroot\OpalWeb
set OPALWEB_SERVICES_DIR=C:\inetpub\wwwroot\OpalWeb.Services

for %%D in ("%OPALWEB_DIR%\OpalImages", "%OPALWEB_SERVICES_DIR%\cache") do (
    if exist "%%~D" (
        echo Deleting contents of %%~D
        del /F /S /Q "%%~D\*"
        FOR /D %%p IN ("%%~D\*") DO rmdir /S /Q "%%p"
    )
)

REM Set permissions using icacls
set WWWROOT_DIR=C:\inetpub\wwwroot
for %%A in (
    "Administrators:(F)"
    "Users:(F)"
    "Everyone:(F)"
    "NETWORK SERVICE:(F)"
    "LOCAL SERVICE:(F)"
) do (
    icacls "%WWWROOT_DIR%" /grant:r %%~A /T
)

REM Start IIS
iisreset /start

REM Disable hibernation
powercfg /hibernate OFF
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /V HiberbootEnabled /T REG_DWORD /D 0 /F

REM Set power scheme to High Performance
powercfg /setactive SCHEME_MIN

REM Set disk timeout to 0 (never)
powercfg -change -disk-timeout-ac 0

REM Re-register ASP.NET with IIS
for %%V in (v2.0.50727 v4.0.30319) do (
    "%SYSTEMROOT%\Microsoft.NET\Framework\%%V\aspnet_regiis.exe" -i
)

REM Update registry settings for application compatibility
REG ADD "HKLM\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /V "C:\opal\bin\OPALStudyList.exe" /D "RUNASADMIN" /F

REM Add ASP.NET SQL Server session state
"%SYSTEMROOT%\Microsoft.NET\Framework\v2.0.50727\aspnet_regsql.exe" -E -S localhost -ssadd

REM Change 'sa' password again
sqlcmd -Q "ALTER LOGIN [sa] WITH PASSWORD=N'1q2w3e4r5t'"

REM Modify web.config to remove 'UnhandledExceptionModule' entries
net stop "W3SVC"
cd "%OPALWEB_DIR%"
powershell -Command "
    (Get-Content .\web.config) |
    Where-Object { $_ -notmatch 'UnhandledExceptionModule' } |
    Set-Content .\web.config
"
net start "W3SVC"

REM Restart services
for %%S in %SERVICES% do (
    net start %%~S
)

echo Script execution completed successfully.
pause