# Requiere administrador. Apaga el indexador de busqueda y el servicio de Windhawk (reversible).
$out = 'C:\Users\MARIANO\neon-panel\pc\data\admin_liviano.log'
$r = @()
foreach ($s in 'WSearch','windhawk') {
  try {
    $svc = Get-Service $s -ErrorAction Stop
    $r += "$s antes: inicio=$((Get-CimInstance Win32_Service -Filter "Name='$s'").StartMode) estado=$($svc.Status)"
    Set-Service $s -StartupType Disabled -ErrorAction Stop
    Stop-Service $s -Force -ErrorAction SilentlyContinue
    $r += "$s -> deshabilitado, estado=$((Get-Service $s).Status)"
  } catch { $r += "$s error: $($_.Exception.Message)" }
}
Get-ScheduledTask | ? { $_.TaskName -match 'windhawk' } | % { try { Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction Stop | Out-Null; $r += "tarea $($_.TaskName) deshabilitada" } catch { $r += "tarea $($_.TaskName): $($_.Exception.Message)" } }
$r += "Para deshacer: Set-Service WSearch -StartupType Automatic; Set-Service windhawk -StartupType Automatic"
$r | Set-Content $out -Encoding utf8
