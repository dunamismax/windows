title Setting Permissions
cls
@echo off

echo.
echo *******************************
echo Setting permissions for Opal folder
echo *******************************
icacls "C:\opal\bin" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\bin" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\bin" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\bin" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\bin" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\bin" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\bin /r /d y

icacls "C:\opal\cfg" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\cfg" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\cfg" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\cfg" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\cfg" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\cfg" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\cfg /r /d y

icacls "C:\opal\data" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\data" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\data" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\data" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\data" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\data" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\data /r /d y

icacls "C:\opal\Backup" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\Backup" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\Backup" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\Backup" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\Backup" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\Backup" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\Backup /r /d y

icacls "C:\opal\cache" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\cache" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\cache" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\cache" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\cache" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\cache" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\cache /r /d y

icacls "C:\opal\driver" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\driver" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\driver" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\driver" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\driver" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\driver" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\driver /r /d y

icacls "C:\opal\log" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\log" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\log" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\log" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\log" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\log" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\log /r /d y

icacls "C:\opal\opal" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\opal" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\opal" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\opal" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\opal" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\opal" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\opal /r /d y

icacls "C:\opal\opallite" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\opallite" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\opallite" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\opallite" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\opallite" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\opallite" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\opallite /r /d y

icacls "C:\opal\plugins32" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\plugins32" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\plugins32" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\plugins32" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\plugins32" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\plugins32" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\plugins32 /r /d y

icacls "C:\opal\plugins64" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\plugins64" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\plugins64" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\plugins64" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\plugins64" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\plugins64" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\plugins64 /r /d y

icacls "C:\opal\uaiarchive" /grant "NETWORK SERVICE":(OI)(CI)F /T
icacls "C:\opal\uaiarchive" /grant "LOCAL SERVICE":(OI)(CI)F /T
icacls "C:\opal\uaiarchive" /grant "Everyone":(OI)(CI)F /T
icacls "C:\opal\uaiarchive" /grant "Authenticated Users":(OI)(CI)F /T
icacls "C:\opal\uaiarchive" /grant "Users":(OI)(CI)F /T
icacls "C:\opal\uaiarchive" /grant "Administrators":(OI)(CI)F /T
takeown /f C:\opal\uaiarchive /r /d y

echo done!