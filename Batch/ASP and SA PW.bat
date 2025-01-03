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