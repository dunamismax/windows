# ShowMessage.ps1
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show("Hello, this is your message!", "Message Title", 'OK', 'Information')