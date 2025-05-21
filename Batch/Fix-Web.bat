net stop "W3SVC"
cd C:\inetpub\wwwroot\OpalWeb
powershell -command "(Get-Content .\web.config) | Where-Object {$_ -notmatch 'UnhandledExceptionModule'} | Set-Content web.config"
net start "W3SVC"