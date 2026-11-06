# Quita la tarea de arranque y detiene los procesos del panel.
Unregister-ScheduledTask -TaskName 'NeonPanel' -Confirm:$false -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | ? { $_.CommandLine -match '\\pc\\(start|server|collector|phone_server)\.ps1' } | % { Stop-Process -Id $_.ProcessId -Force }
Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" | ? { $_.CommandLine -like '*NeonPanel*edge-profile*' } | % { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Write-Host 'Panel desinstalado (los archivos del repo no se borran).'
