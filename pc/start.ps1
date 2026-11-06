# Lanzador unico del panel. Lo ejecuta una tarea programada al iniciar sesion.
#  - arranca (y relanza si caen) el recolector, el servidor local y el servidor del telefono
#  - abre la consola en pantalla completa cuando el servidor responde
#  - mantiene Windows "minimo": cierra Lively y los lanzadores que se auto-inician en los primeros minutos
$pc = $PSScriptRoot
$mx = New-Object Threading.Mutex($false,'Global\NeonPanelLauncher'); if(-not $mx.WaitOne(0)){ exit }
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$log = "$pc\data\start.log"; New-Item -ItemType Directory -Force "$pc\data" | Out-Null
function Log($m){ try{ Add-Content $log "$(Get-Date -f s) $m" }catch{} }
function Alive($file){ [bool](Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | ? { $_.CommandLine -like "*\pc\$file*" -and $_.CommandLine -notlike '*start.ps1*' }) }
function Ensure($file){ if(-not (Alive $file)){ Log "iniciando $file"; Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"$pc\$file" } }
$t0 = Get-Date; $opened = $false; Log 'start.ps1 iniciado'
while($true){
  Ensure 'collector.ps1'; Ensure 'server.ps1'; Ensure 'phone_server.ps1'
  if(-not $opened){
    try{ Invoke-WebRequest http://127.0.0.1:8777/stats -UseBasicParsing -TimeoutSec 2 | Out-Null
      $kargs = '--kiosk http://127.0.0.1:8777 --edge-kiosk-type=fullscreen --no-first-run --autoplay-policy=no-user-gesture-required --user-data-dir="' + $env:LOCALAPPDATA + '\NeonPanel\edge-profile"'
      Start-Process $edge -ArgumentList $kargs
      $opened = $true; Log 'consola abierta' }catch{}
  }
  # primeros 5 minutos: cerrar lo que se auto-inicia y no hace falta en el escritorio minimo
  if(((Get-Date)-$t0).TotalMinutes -lt 5){
    Get-Process Lively,Lively.UI.WinUI,Lively.Player.WebView2,Lively.Watchdog,Rainmeter -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-CimInstance Win32_Process -Filter "Name='steam.exe'" | ? { $_.CommandLine -match '-silent' } | % { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue; Get-Process steamwebhelper -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }
    Get-Process Battle.net -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  }
  if(((Get-Date)-$t0).TotalMinutes -lt 5){ Start-Sleep 5 } else { Start-Sleep 30 }
}


