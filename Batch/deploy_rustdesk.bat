@echo off
REM ######################################################################
REM #                                                                    #
REM #          RustDesk Silent Installer Batch Script                    #
REM #                                                                    #
REM #   !! IMPORTANT: Right-click this file and "Run as administrator" !! #
REM #                                                                    #
REM ######################################################################
setlocal

REM --- Configuration ---
set "RUSTDESK_PW=2020Techs!@"
REM !!! IMPORTANT: Replace "configstring" with your actual RustDesk configuration string !!!
set "RUSTDESK_CFG=configstring"
REM Example: set "RUSTDESK_CFG=your_server_address,your_key"

set "ServiceName=Rustdesk"
set "TargetVersion=1.3.9"
set "Downloadlink=https://github.com/rustdesk/rustdesk/releases/download/1.3.9/rustdesk-1.3.9-x86_64.exe"
set "TempPath=C:\Temp"
set "InstallerName=rustdesk.exe"
set "InstallerPath=%TempPath%\%InstallerName%"
set "RustDeskInstallPath=%ProgramFiles%\RustDesk"
set "RustDeskExe=%RustDeskInstallPath%\rustdesk.exe"

echo Target RustDesk Version: %TargetVersion%
echo Using Static Download Link: %Downloadlink%
echo.

REM --- Check Currently Installed Version ---
echo Checking installed RustDesk version...
set "CurrentVersion="
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RustDesk" /v Version > nul 2>&1
if %ERRORLEVEL% == 0 (
    for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RustDesk" /v Version ^| findstr /i Version') do set "CurrentVersion=%%b"
)

if defined CurrentVersion (
    echo Found installed version: %CurrentVersion%
    if "%CurrentVersion%"=="%TargetVersion%" (
        echo RustDesk version %CurrentVersion% is already the target version (%TargetVersion%). No action needed.
        goto :EndScriptSuccess
    ) else (
        echo Upgrading to target version %TargetVersion%...
    )
) else (
    echo RustDesk not found installed. Installing target version %TargetVersion%...
)
echo.

REM --- Prepare Download ---
echo Ensuring Temp directory exists at %TempPath%...
if not exist "%TempPath%" mkdir "%TempPath%"
if not exist "%TempPath%" (
    echo ERROR: Could not create Temp directory: %TempPath%
    goto :EndScriptFail
)

REM --- Download Installer ---
echo Downloading %Downloadlink% to %InstallerPath%...
REM Using PowerShell for reliable download and TLS handling
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Tls13; Invoke-WebRequest -Uri '%Downloadlink%' -OutFile '%InstallerPath%' -UseBasicParsing"

if not exist "%InstallerPath%" (
    echo ERROR: Failed to download RustDesk installer. Check network connection and URL.
    goto :EndScriptFail
)
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell download command failed with ErrorLevel %ERRORLEVEL%.
    goto :EndScriptFail
)
echo Download complete.
echo.

REM --- Install RustDesk ---
echo Starting silent installation...
REM Using start /wait ensures the script waits for the installer to finish.
start "" /wait "%InstallerPath%" --silent-install

if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Installer exited with code %ERRORLEVEL%. Installation may have failed.
    REM Decide whether to continue or fail here. Let's try to continue.
) else (
    echo Installer process completed.
)
echo.

REM --- Wait for Install ---
echo Waiting 20 seconds for installation to settle...
timeout /t 20 /nobreak > nul
echo.

REM --- Verify Installation ---
if not exist "%RustDeskExe%" (
     echo ERROR: RustDesk executable not found at '%RustDeskExe%' after installation attempt.
     goto :EndScriptFail
)
echo RustDesk executable found at %RustDeskExe%.
echo.

REM --- Service Installation ---
echo Checking if RustDesk service '%ServiceName%' exists...
sc query "%ServiceName%" > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo RustDesk service not found. Installing service...
    "%RustDeskExe%" --install-service
    if %ERRORLEVEL% NEQ 0 (
        echo WARNING: Service installation command exited with code %ERRORLEVEL%.
    ) else (
        echo Service installation command completed.
    )
    echo Waiting 20 seconds for service to register...
    timeout /t 20 /nobreak > nul

    REM Re-check if service exists after install attempt
    sc query "%ServiceName%" > nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Service '%ServiceName%' still not found after installation attempt.
        goto :EndScriptFail
    )
) else (
    echo RustDesk service already exists.
)
echo.

REM --- Ensure Service is Running ---
echo Ensuring RustDesk service is running...
set "attempts=0"
:CheckServiceLoop
    if %attempts% GEQ 5 (
        echo ERROR: Failed to start the RustDesk service after %attempts% attempts.
        goto :EndScriptFail
    )

    sc query "%ServiceName%" | findstr /i "STATE" | findstr /i "RUNNING" > nul
    if %ERRORLEVEL% == 0 (
        echo RustDesk service is running.
        goto :ServiceRunning
    )

    set /a attempts+=1
    echo Attempt %attempts%: Service not running. Starting service '%ServiceName%'...
    net start "%ServiceName%" > nul 2>&1
    REM Alternative: sc start "%ServiceName%" > nul 2>&1

    echo Waiting 5 seconds...
    timeout /t 5 /nobreak > nul
    goto CheckServiceLoop

:ServiceRunning
echo.

REM --- Get RustDesk ID ---
echo Retrieving RustDesk ID...
set "rustdesk_id=Failed to retrieve"
for /f "delims=" %%i in ('"%RustDeskExe%" --get-id') do set "rustdesk_id=%%i"
REM Basic check if retrieval worked (output should not be empty)
if "%rustdesk_id%"=="Failed to retrieve" (
    echo WARNING: --get-id command might have failed or returned empty.
)
echo.

REM --- Apply Configuration ---
echo Applying configuration: %RUSTDESK_CFG%
"%RustDeskExe%" --config "%RUSTDESK_CFG%"
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: --config command exited with code %ERRORLEVEL%.
)
echo.

REM --- Set Password ---
echo Setting password...
"%RustDeskExe%" --password "%RUSTDESK_PW%"
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: --password command exited with code %ERRORLEVEL%.
)
echo.

REM --- Output Results ---
echo ...............................................
echo RustDesk Deployment Summary:
echo RustDesk ID: %rustdesk_id%
echo Configured Password: %RUSTDESK_PW%
echo ...............................................
goto :EndScriptSuccess

REM --- End Script Sections ---
:EndScriptFail
echo.
echo !!!!! SCRIPT FAILED !!!!!
echo Please review the messages above.
endlocal
pause
exit /b 1

:EndScriptSuccess
echo.
echo Script completed successfully.
endlocal
pause
exit /b 0