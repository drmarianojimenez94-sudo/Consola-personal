# Recolector de datos: escribe JSON en data\ para que el servidor responda al instante (sin bloquearse con la red ni con CIM).
$root=$PSScriptRoot; $data="$root\data"; New-Item -ItemType Directory -Force $data | Out-Null
$ProgressPreference='SilentlyContinue'
function Save($name,$obj,$depth=5){ try{ $tmp="$data\$name.tmp"; [IO.File]::WriteAllText($tmp,(ConvertTo-Json $obj -Compress -Depth $depth),[Text.Encoding]::UTF8); Move-Item $tmp "$data\$name.json" -Force }catch{} }
function SteamLibs{ $libs=@('C:\Program Files (x86)\Steam'); try{ Get-Content 'C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf' -ErrorAction Stop | Select-String '"path"\s+"([^"]+)"' | % { $libs += ($_.Matches[0].Groups[1].Value -replace '\\\\','\') } }catch{}; $libs|Select -Unique }
function DoStats{
  $cpu=(Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime
  $os=Get-CimInstance Win32_OperatingSystem; $tot=[math]::Round($os.TotalVisibleMemorySize/1MB,1); $free=[math]::Round($os.FreePhysicalMemory/1MB,1)
  $g=(& nvidia-smi --query-gpu=temperature.gpu,power.draw,utilization.gpu --format=csv,noheader,nounits 2>$null) -split ',\s*'
  $d=Get-Volume -DriveLetter C; $up=(Get-Date)-$os.LastBootUpTime
  Save 'stats' @{cpu=[int]$cpu;ramUsed=[math]::Round($tot-$free,1);ramTotal=$tot;gpuTemp=$g[0];gpuPower=$g[1];gpuUtil=$g[2];diskFreeGB=[int]($d.SizeRemaining/1GB);diskTotalGB=[int]($d.Size/1GB);uptime=('{0}d {1:00}h {2:00}m' -f $up.Days,$up.Hours,$up.Minutes)}
}
function DoDownloads{
  $items=@(); foreach($lib in SteamLibs){ Get-ChildItem "$lib\steamapps" -Filter appmanifest_*.acf -ErrorAction SilentlyContinue | % {
    $t=Get-Content $_.FullName -Raw; $n=[regex]::Match($t,'"name"\s+"([^"]+)"').Groups[1].Value; $f=[int][regex]::Match($t,'"StateFlags"\s+"(\d+)"').Groups[1].Value
    $tot=[double][regex]::Match($t,'"BytesToDownload"\s+"(\d+)"').Groups[1].Value; $got=[double][regex]::Match($t,'"BytesDownloaded"\s+"(\d+)"').Groups[1].Value
    if($f -ne 4 -and $tot -gt 0){ $items += @{name=$n;pct=[math]::Round($got/$tot*100,1);gb=[math]::Round($tot/1GB,1)} } } }
  $net=(Get-CimInstance Win32_PerfFormattedData_Tcpip_NetworkInterface | Measure-Object BytesReceivedPersec -Sum).Sum
  Save 'downloads' @{steamRunning=[bool](Get-Process steam -ErrorAction SilentlyContinue);battlenetRunning=[bool](Get-Process Battle.net -ErrorAction SilentlyContinue);steam=@($items);netMBps=[math]::Round($net/1MB,2)} 4
}
function DoGames{
  $out=@(); foreach($lib in SteamLibs){ Get-ChildItem "$lib\steamapps" -Filter appmanifest_*.acf -ErrorAction SilentlyContinue | % {
    $t=Get-Content $_.FullName -Raw; $n=[regex]::Match($t,'"name"\s+"([^"]+)"').Groups[1].Value; $id=[regex]::Match($t,'"appid"\s+"(\d+)"').Groups[1].Value
    $f=[int][regex]::Match($t,'"StateFlags"\s+"(\d+)"').Groups[1].Value; $sz=[double][regex]::Match($t,'"SizeOnDisk"\s+"(\d+)"').Groups[1].Value
    if($f -eq 4 -and $n -and $n -notmatch 'Redistributable|Proton|Steam Linux|Steamworks'){ $out += @{id=$id;name=$n;gb=[math]::Round($sz/1GB,1)} } } }
  Save 'games' @($out) 3
}
function DoFinance{
  $o=[ordered]@{}
  try{ $d=Invoke-RestMethod https://dolarapi.com/v1/dolares -TimeoutSec 6; $o.usdOficial=($d|?{$_.casa -eq 'oficial'}).venta; $o.usdBlue=($d|?{$_.casa -eq 'blue'}).venta }catch{}
  try{ $o.brl=(Invoke-RestMethod https://dolarapi.com/v1/cotizaciones/brl -TimeoutSec 6).venta }catch{}
  try{ $c=Invoke-RestMethod 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd&include_24hr_change=true' -TimeoutSec 6
       $o.btc=$c.bitcoin.usd; $o.btcCh=[math]::Round($c.bitcoin.usd_24h_change,2); $o.eth=$c.ethereum.usd; $o.ethCh=[math]::Round($c.ethereum.usd_24h_change,2) }catch{}
  try{ $r=Invoke-RestMethod https://api.argentinadatos.com/v1/finanzas/rendimientos -TimeoutSec 8; $best=$null
       foreach($e in $r){ $a=$e.rendimientos|?{$_.moneda -eq 'ARS'}|Select -First 1; if($a -and (-not $best -or $a.apy -gt $best.apy)){ $best=@{apy=$a.apy;ent=$e.entidad} } }
       if($best){ $o.arsBest=$best.apy; $o.arsBestEnt=$best.ent } }catch{}
  try{ $cfg=Get-Content "$root\rates.json" -Raw -ErrorAction Stop | ConvertFrom-Json; if($cfg.mercadoPagoTNA){ $o.mpTna=$cfg.mercadoPagoTNA } }catch{}
  if($o.Count -gt 0){ Save 'finance' $o }
}
function DoWeather{
  $lat=-34.61;$lon=-58.38;$city='Buenos Aires'
  try{ $cfg=Get-Content "$root\rates.json" -Raw -ErrorAction Stop | ConvertFrom-Json; if($cfg.lat){$lat=$cfg.lat;$lon=$cfg.lon;$city=$cfg.ciudad} }catch{}
  try{ $pl=Get-Content "$data\phone_location.json" -Raw -ErrorAction Stop | ConvertFrom-Json; if(((Get-Date)-[datetime]$pl.at).TotalHours -lt 6){ $d=[Math]::Sqrt([Math]::Pow(($pl.lat-$lat)*111,2)+[Math]::Pow(($pl.lon-$lon)*111*[Math]::Cos($lat*3.14159/180),2)); if($d -gt 40){ $city='Ubicacion del telefono' }; $lat=$pl.lat; $lon=$pl.lon } }catch{}
  try{ $w=Invoke-RestMethod "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max&timezone=auto&forecast_days=4" -TimeoutSec 8
       Save 'weather' @{city=$city;temp=$w.current.temperature_2m;feels=$w.current.apparent_temperature;code=$w.current.weather_code;wind=$w.current.wind_speed_10m;hum=$w.current.relative_humidity_2m;days=@(0..3|%{ @{max=$w.daily.temperature_2m_max[$_];min=$w.daily.temperature_2m_min[$_];code=$w.daily.weather_code[$_];rain=$w.daily.precipitation_probability_max[$_]} })} }catch{}
}
$tick=0
$script:fired=@{}; $script:ringAt=$null
function DoAlarms{
  $now=Get-Date
  if($script:ringAt -and ($now-$script:ringAt).TotalSeconds -gt 90){ try{ (New-Object Net.WebClient).DownloadString('http://127.0.0.1:8777/alarm/stop')|Out-Null }catch{}; $script:ringAt=$null }
  $sn="$data\snooze.txt"; if(Test-Path $sn){ $q=(Get-Content $sn -Raw).Trim() -split '\|'; if([datetime]::Parse($q[0]) -le $now){ Remove-Item $sn -Force; $script:ringAt=$now; try{ (New-Object Net.WebClient).DownloadString('http://127.0.0.1:8777/alarm/ring?n='+[uri]::EscapeDataString($q[1])+'&h='+$q[2])|Out-Null }catch{} } }
  $f="$env:USERPROFILE\Consultorio\alarmas.json"; if(-not (Test-Path $f)){ return }
  $a=Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json; $key=$now.ToString('yyyyMMddHHmm'); $hm=$now.ToString('HH:mm'); $dow=[int]$now.DayOfWeek
  foreach($x in @($a)){
    if(-not $x.activa -or $x.hora -ne $hm){ continue }
    if(@($x.dias) -notcontains $dow){ continue }
    if($script:fired[$x.id] -eq $key){ continue }
    $script:fired[$x.id]=$key; $script:ringAt=$now
    try{ (New-Object Net.WebClient).DownloadString('http://127.0.0.1:8777/alarm/ring?n='+[uri]::EscapeDataString([string]$x.nombre)+'&h='+$x.hora)|Out-Null }catch{}
  }
}while($true){
  try{ DoAlarms }catch{}
  # si nadie mira el panel (hay un juego al frente), recolectar muy de vez en cuando
  try{ if(((Get-Date)-(Get-Item "$data\seen.txt" -ErrorAction Stop).LastWriteTime).TotalSeconds -gt 25){ Start-Sleep 25 } }catch{}
  try{ DoStats }catch{}
  if($tick % 2 -eq 0){ try{ DoDownloads }catch{} }
  if($tick % 30 -eq 0){ try{ DoGames }catch{} }
  if($tick % 40 -eq 0){ try{ DoFinance }catch{} }
  if($tick % 300 -eq 0){ try{ DoWeather }catch{} }
  $tick++; Start-Sleep 5
}
