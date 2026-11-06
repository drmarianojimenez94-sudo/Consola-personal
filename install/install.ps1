# Instala el panel para el usuario actual (sin administrador): una tarea programada al iniciar sesion ejecuta pc\start.ps1,
# que levanta el servidor, el recolector y el servidor del telefono, y abre la consola en pantalla completa.
$repo = (Resolve-Path "$PSScriptRoot\..").Path
if(-not (Test-Path "$repo\pc\rates.json")){ Copy-Item "$repo\pc\rates.example.json" "$repo\pc\rates.json" }
$act = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$repo\pc\start.ps1`""
$trg = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 5 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName 'NeonPanel' -Action $act -Trigger $trg -Settings $set -Force | Out-Null
Start-ScheduledTask -TaskName 'NeonPanel'
Write-Host "Instalado. Se inicia solo al abrir sesion. La TV mostrara la direccion del telefono y el PIN arriba a la derecha."
Write-Host "La primera vez Windows pedira permiso de firewall para PowerShell: elegi 'Redes privadas'."
Write-Host "Registro de arranque: pc\data\start.log"
