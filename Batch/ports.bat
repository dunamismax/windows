echo.
echo *******************************
echo Add Firewall Ports for Opal
echo *******************************
netsh advfirewall firewall add rule name="Opal" dir=in action=allow protocol=TCP localport=104,1433,33333-33338,80
echo done!