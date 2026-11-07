# Servidor local de la consola (solo 127.0.0.1). Responde desde archivos cacheados por collector.ps1: nunca se bloquea.
$root = $PSScriptRoot; $data="$root\data"; New-Item -ItemType Directory -Force $data | Out-Null
$ProgressPreference='SilentlyContinue'
$edgeExe='C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$apps = @{
  'edge'=$edgeExe; 'terminal'='wt.exe'; 'explorer'='explorer.exe'
  'steam'='C:\Program Files (x86)\Steam\steam.exe'; 'battlenet'='C:\Program Files (x86)\Battle.net\Battle.net Launcher.exe'
  'claude'='shell:AppsFolder\Claude_pzs8sxrjxfjjc!Claude'; 'taskmgr'='taskmgr.exe'; 'bigpicture'='steam://open/bigpicture'
  'settings'='ms-settings:'; 'pacientes'="$env:USERPROFILE\Pacientes"; 'hospital'="$env:USERPROFILE\Hospital"; 'hospital-protocolos'="$env:USERPROFILE\Hospital\Protocolos"; 'hospital-guardia'="$env:USERPROFILE\Hospital\Guardias"; 'hospital-plantillas'="$env:USERPROFILE\Hospital\Plantillas"; 'hospital-remoto'="$env:USERPROFILE\Hospital\LEEME_acceso_remoto.txt"; 'pcdiag'='C:\ProgramData\PCDiag'; 'hwinfo'='C:\Program Files\HWiNFO64\HWiNFO64.exe'
}
$sites = @{
 'netflix'='https://www.netflix.com'; 'disney'='https://www.disneyplus.com'; 'prime'='https://www.primevideo.com'
 'max'='https://www.max.com'; 'youtube'='https://www.youtube.com/tv'; 'ytmusic'='https://music.youtube.com'
 'spotify'='https://open.spotify.com'; 'twitch'='https://www.twitch.tv'; 'paramount'='https://www.paramountplus.com'
 'appletv'='https://tv.apple.com'; 'crunchyroll'='https://www.crunchyroll.com'
 'gmail'='https://mail.google.com'; 'contacts'='https://contacts.google.com'; 'calendar'='https://calendar.google.com'
 'whatsapp'='https://web.whatsapp.com'; 'chatgpt'='https://chatgpt.com'; 'gemini'='https://gemini.google.com'
 'drive'='https://drive.google.com'; 'onedrive'='https://onedrive.live.com'; 'photos'='https://photos.google.com'
 'meet'='https://meet.google.com'; 'claudeweb'='https://claude.ai'; 'dolarhoy'='https://dolarhoy.com'; 'coingecko'='https://www.coingecko.com'
 'cuentas'='http://127.0.0.1:8777/finanzas.html'; 'gh-lahorda'='https://github.com/Fondal-Studios/La-Horda'; 'gh-vortex'='https://github.com/Fondal-Studios/Vortex'; 'gh-bosta'='https://github.com/Fondal-Studios/Bosta-Cosmica'; 'gh-freebird'='https://github.com/Fondal-Studios/FreeBird'; 'gh-padel'='https://github.com/Fondal-Studios/Virtual-Padel'; 'gh-org'='https://github.com/Fondal-Studios'; 'mercadopago'='https://www.mercadopago.com.ar'; 'lahorda'='https://fondal-studios.github.io/La-Horda/'; 'play-La-Horda'='http://127.0.0.1:8777/play/La-Horda/'; 'play-Bosta-Cosmica'='http://127.0.0.1:8777/play/Bosta-Cosmica/'; 'play-Vortex'='http://127.0.0.1:8777/play/Vortex/'; 'play-FreeBird'='http://127.0.0.1:8777/play/FreeBird/'; 'xcloud'='https://www.xbox.com/play'; 'canva'='https://www.canva.com'; 'runway'='https://app.runwayml.com'; 'metricool'='https://app.metricool.com'; 'figma'='https://www.figma.com'; 'instagram'='https://www.instagram.com'; 'metabiz'='https://business.facebook.com/latest'; 'sketchup'='https://app.sketchup.com'; 'autocadweb'='https://web.autocad.com'; 'pubmed'='https://pubmed.ncbi.nlm.nih.gov'; 'uptodate'='https://www.uptodate.com'; 'lol'='https://www.leagueoflegends.com/es-ar/download/'; 'geforcenow'='https://play.geforcenow.com'; 'vortex'='https://fondal-studios.github.io/Vortex/'; 'mercadolibre'='https://www.mercadolibre.com.ar'
}
# busquedas por voz: plataforma -> plantilla de URL (el texto se codifica; solo estos destinos)
$search = @{
 'youtube'='https://www.youtube.com/results?search_query={0}'; 'ytmusic'='https://music.youtube.com/search?q={0}'
 'netflix'='https://www.netflix.com/search?q={0}'; 'disney'='https://www.disneyplus.com/search/{0}'
 'prime'='https://www.primevideo.com/search/?phrase={0}'; 'max'='https://play.max.com/search?q={0}'
 'spotify'='https://open.spotify.com/search/{0}'; 'twitch'='https://www.twitch.tv/search?term={0}'
 'paramount'='https://www.paramountplus.com/search/?q={0}'; 'crunchyroll'='https://www.crunchyroll.com/search?q={0}'
 'google'='https://www.google.com/search?q={0}'
}
Add-Type -Namespace W -Name U -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c); [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h); [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow(); [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r); [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid); [DllImport("user32.dll")] public static extern void keybd_event(byte vk,byte sc,uint f,UIntPtr e); [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p,IntPtr l); [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h); [DllImport("user32.dll",CharSet=CharSet.Auto)] static extern int GetClassName(IntPtr h,System.Text.StringBuilder b,int n); [DllImport("user32.dll",CharSet=CharSet.Auto)] static extern int GetWindowText(IntPtr h,System.Text.StringBuilder b,int n); delegate bool EnumProc(IntPtr h,IntPtr l); public static IntPtr[] EdgeWins(){ var r=new System.Collections.Generic.List<IntPtr>(); EnumWindows((h,l)=>{ if(IsWindowVisible(h)){ var c=new System.Text.StringBuilder(64); GetClassName(h,c,64); if(c.ToString()=="Chrome_WidgetWin_1"){ var t=new System.Text.StringBuilder(256); GetWindowText(h,t,256); if(t.Length>0) r.Add(h);} } return true; },IntPtr.Zero); return r.ToArray(); } public static string Title(IntPtr h){ var t=new System.Text.StringBuilder(256); GetWindowText(h,t,256); return t.ToString(); } [StructLayout(LayoutKind.Sequential)] public struct RECT{public int L,T,R,B;}'
Add-Type -AssemblyName System.Windows.Forms
function FullscreenFront{ Start-Sleep -Milliseconds 2800; try{ $h=[W.U]::GetForegroundWindow(); $pid2=[uint32]0; [void][W.U]::GetWindowThreadProcessId($h,[ref]$pid2); $p=Get-Process -Id $pid2 -ErrorAction Stop
  if($p.Name -eq 'msedge' -and $p.MainWindowTitle -notlike 'NEON CONSOLE*'){ [void][W.U]::ShowWindow($h,3); Start-Sleep -Milliseconds 500; $rc=New-Object 'W.U+RECT'; [void][W.U]::GetWindowRect($h,[ref]$rc); $sh=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
   if(($rc.B-$rc.T) -lt ($sh-2)){ [W.U]::keybd_event(0x7A,0,0,[UIntPtr]::Zero); [W.U]::keybd_event(0x7A,0,2,[UIntPtr]::Zero) } } }catch{} }
function NewHC{ $pd="$env:USERPROFILE\Pacientes"; $n="$pd\HC_"+(Get-Date -f 'yyyyMMdd_HHmm')+'.md'; Copy-Item "$pd\_plantilla\historia_clinica.md" $n -Force; Start-Process notepad.exe -ArgumentList "`"$n`"" }
function OpenFront($eargs){
  $before=@([W.U]::EdgeWins()); Start-Process $edgeExe -ArgumentList $eargs
  $new=$null; for($i=0;$i -lt 20 -and -not $new;$i++){ Start-Sleep -Milliseconds 350; $new=[W.U]::EdgeWins() | ? { $before -notcontains $_ -and ([W.U]::Title($_)) -notlike 'NEON CONSOLE*' } | Select -First 1 }
  if(-not $new){ return }
  Start-Sleep -Milliseconds 700
  [W.U]::keybd_event(0x12,0,0,[UIntPtr]::Zero); [W.U]::keybd_event(0x12,0,2,[UIntPtr]::Zero)   # Alt: desbloquea el cambio de ventana al frente
  [void][W.U]::ShowWindow($new,3); [void][W.U]::SetForegroundWindow($new); Start-Sleep -Milliseconds 500
  $rc=New-Object 'W.U+RECT'; [void][W.U]::GetWindowRect($new,[ref]$rc); $sh=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
  if(($rc.B-$rc.T) -lt ($sh-2)){ [W.U]::keybd_event(0x7A,0,0,[UIntPtr]::Zero); [W.U]::keybd_event(0x7A,0,2,[UIntPtr]::Zero) }
}
function MinimizeOthers{ foreach($h in [W.U]::EdgeWins()){ if(([W.U]::Title($h)) -notlike 'NEON CONSOLE*'){ [void][W.U]::ShowWindow($h,6) } } }
function LaunchFront($target){
  $before=@([W.U]::EdgeWins() | % { $_.ToInt64() }) 
  Start-Process $target
  $new=$null; for($i=0;$i -lt 30 -and -not $new;$i++){ Start-Sleep -Milliseconds 400; $new=Get-Process | ? { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -and $_.MainWindowTitle -notlike 'NEON CONSOLE*' -and $_.Name -notin 'claude','msedge','explorer' -and (Get-Date) -lt ($_.StartTime.AddSeconds(25)) } | Select -First 1 }
  if($new){ [W.U]::keybd_event(0x12,0,0,[UIntPtr]::Zero); [W.U]::keybd_event(0x12,0,2,[UIntPtr]::Zero); [void][W.U]::ShowWindow($new.MainWindowHandle,3); [void][W.U]::SetForegroundWindow($new.MainWindowHandle) }
}
# apps de la Tienda instaladas: si existen se abren como apps (pantalla completa/maximizadas); si no, se abre la web
$storeApps=@{ 'netflix'='Netflix'; 'disney'='Disney'; 'prime'='Prime Video'; 'appletv'='Apple TV'; 'whatsapp'='WhatsApp'; 'spotify'='Spotify' }
$script:sa=$null; $script:saAt=[datetime]::MinValue
function FindStoreApp($key){
  if(-not $storeApps.ContainsKey($key)){ return $null }
  if(-not $script:sa -or ((Get-Date)-$script:saAt).TotalMinutes -gt 5){ try{ $script:sa=@(Get-StartApps); $script:saAt=Get-Date }catch{} }
  $n=$storeApps[$key]; $script:sa | ? { $_.Name -like "*$n*" } | Select -First 1
}
function OpenApp($app,$title){
  if($app.AppID -match '^[A-Za-z]:\\'){ Start-Process $app.AppID } else { Start-Process explorer.exe "shell:AppsFolder\$($app.AppID)" }
  $h=$null; for($i=0;$i -lt 30 -and -not $h;$i++){ Start-Sleep -Milliseconds 400; $h=(Get-Process | ? { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -like "*$title*" -and $_.Name -notin 'claude','msedge' } | Select -First 1).MainWindowHandle }
  if($h){ [W.U]::keybd_event(0x12,0,0,[UIntPtr]::Zero); [W.U]::keybd_event(0x12,0,2,[UIntPtr]::Zero); [void][W.U]::ShowWindow($h,3); [void][W.U]::SetForegroundWindow($h) }
}
function Spawn($mode,$arg,$title=''){ Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$root\front.ps1`"",$mode,"`"$arg`"","`"$title`"" }
function KioskGpuArg { try{ $c=Get-Content "$data\settings.json" -Raw -ErrorAction Stop | ConvertFrom-Json; if($c.kioskGpu -eq $true){ return '' } }catch{}; return ' --disable-gpu' }
$script:dict=$null
function KioskWin { Get-Process msedge -ErrorAction SilentlyContinue | ? { $_.MainWindowTitle -like 'NEON CONSOLE*' } | Select -First 1 }
function KioskStart { Start-Process $edgeExe -ArgumentList "--kiosk http://127.0.0.1:8777 --edge-kiosk-type=fullscreen --no-first-run --autoplay-policy=no-user-gesture-required$(KioskGpuArg) --user-data-dir=`"$env:LOCALAPPDATA\NeonPanel\edge-profile`"" }
function ToConsole($bigpicture){ MinimizeOthers; $k=KioskWin; if($k){ [W.U]::ShowWindow($k.MainWindowHandle,9)|Out-Null; [W.U]::SetForegroundWindow($k.MainWindowHandle)|Out-Null } else { KioskStart }; if($bigpicture){ Start-Process 'steam://open/bigpicture' } }
function ToDesktop { $k=KioskWin; if($k){ [W.U]::ShowWindow($k.MainWindowHandle,6)|Out-Null } }
$script:ipv=$null; $script:ipAt=[datetime]::MinValue
function GetIp { if($script:ipv -and ((Get-Date)-$script:ipAt).TotalSeconds -lt 60){ return $script:ipv }
  try{ $s=New-Object Net.Sockets.Socket('InterNetwork','Dgram','Udp'); $s.Connect('8.8.8.8',80); $script:ipv=$s.LocalEndPoint.Address.ToString(); $s.Close(); $script:ipAt=Get-Date }catch{}; $script:ipv }
# PIN de vinculacion del telefono (se crea una vez)
$pinFile="$data\pin.txt"; if(-not (Test-Path $pinFile)){ (Get-Random -Minimum 100000 -Maximum 999999).ToString() | Set-Content $pinFile }
$inbox = New-Object System.Collections.ArrayList
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add('http://127.0.0.1:8777/'); $l.Start()
# datos del consultorio: JSON en %USERPROFILE%\Consultorio (fuera del repositorio), con copia de seguridad rotativa
$ConsDir="$env:USERPROFILE\Consultorio"; $ConsNames='pacientes','finanzas','tareas','alarmas','avisos'
function ConsRead($n){ $f="$ConsDir\$n.json"; if(Test-Path $f){ [IO.File]::ReadAllText($f,[Text.Encoding]::UTF8) } elseif($n -eq 'finanzas'){ '{"saldos":[],"movimientos":[]}' } else { '[]' } }
function ConsWrite($n,$json){ New-Item -ItemType Directory -Force "$ConsDir\backup" | Out-Null; $f="$ConsDir\$n.json"; if(Test-Path $f){ Copy-Item $f "$ConsDir\backup\$n.json" -Force }; [IO.File]::WriteAllText($f,$json,[Text.UTF8Encoding]::new($false)) }
function Send($ctx,$body,$type='application/json'){ $b=[Text.Encoding]::UTF8.GetBytes($body); $ctx.Response.ContentType=$type; $ctx.Response.ContentLength64=$b.Length; $ctx.Response.OutputStream.Write($b,0,$b.Length); $ctx.Response.Close() }
function SendFile($ctx,$name,$empty='null'){ $f="$data\$name.json"; if(Test-Path $f){ Send $ctx ([IO.File]::ReadAllText($f)) } else { Send $ctx $empty } }
while($l.IsListening){
  try{ $ctx = $l.GetContext() }catch{ Start-Sleep -Milliseconds 200; continue }
  $p = $ctx.Request.Url.AbsolutePath
  try {
    # defensa contra paginas web externas (CSRF / DNS rebinding): solo mismo origen y Host local
    $sfs=$ctx.Request.Headers['Sec-Fetch-Site']; $hh=$ctx.Request.Headers['Host']
    if(($sfs -and $sfs -notin 'same-origin','none') -or ($hh -ne '127.0.0.1:8777')){ $ctx.Response.StatusCode=403; Send $ctx 'forbidden' 'text/plain'; continue }
    if($p -eq '/stats'){ try{ [IO.File]::WriteAllText("$data\seen.txt",'1') }catch{}; SendFile $ctx 'stats'
    } elseif($p -eq '/finance'){ SendFile $ctx 'finance'
    } elseif($p -eq '/weather'){ SendFile $ctx 'weather'
    } elseif($p -eq '/downloads'){ SendFile $ctx 'downloads'
    } elseif($p -eq '/games'){ SendFile $ctx 'games' '[]'
    } elseif($p -eq '/info'){ Send $ctx (@{ip=(GetIp);port=8443;pin=(Get-Content $pinFile -Raw).Trim()}|ConvertTo-Json -Compress)
    } elseif($p -eq '/inbox/push'){ $t=$ctx.Request.QueryString['t']; if($t -and $t.Length -lt 300 -and $inbox.Count -lt 20){ [void]$inbox.Add($t) }; Send $ctx '{"ok":true}'
    } elseif($p -eq '/inbox/pop'){ $o=@($inbox); $inbox.Clear(); Send $ctx (ConvertTo-Json @($o) -Compress)
    } elseif($p -like '/data/*'){
      $n=$p.Substring(6)
      if($n -notin $ConsNames){ $ctx.Response.StatusCode=404; Send $ctx '{"ok":false}' }
      elseif($ctx.Request.HttpMethod -eq 'POST'){
        if($ctx.Request.ContentLength64 -gt 2MB){ $ctx.Response.StatusCode=413; Send $ctx '{"ok":false}' }
        else { $sr=New-Object IO.StreamReader($ctx.Request.InputStream,[Text.Encoding]::UTF8); $j=$sr.ReadToEnd(); try{ [void](ConvertFrom-Json $j) }catch{ $ctx.Response.StatusCode=400; Send $ctx '{"ok":false}'; continue }; ConsWrite $n $j; Send $ctx '{"ok":true}' }
      } else { Send $ctx (ConsRead $n) }
    } elseif($p -eq '/hc/save' -and $ctx.Request.HttpMethod -eq 'POST'){
      if($ctx.Request.ContentLength64 -gt 100KB){ $ctx.Response.StatusCode=413; Send $ctx '{"ok":false}' }
      else { $sr=New-Object IO.StreamReader($ctx.Request.InputStream,[Text.Encoding]::UTF8); $d=$sr.ReadToEnd() | ConvertFrom-Json
        $dir="$env:USERPROFILE\Pacientes\Historias"; New-Item -ItemType Directory -Force $dir | Out-Null
        $ini=(([string]$d.nombre).Split(' ',[StringSplitOptions]::RemoveEmptyEntries) | % { $_.Substring(0,1).ToUpper() }) -join ''; if(-not $ini){ $ini='SN' }
        $fn="$dir\"+(Get-Date -f 'yyyyMMdd_HHmm')+"_$($ini -replace '[^A-Z0-9]','').md"
        $md="# Historia clinica`r`n`r`nFecha: "+(Get-Date -f 'yyyy-MM-dd HH:mm')+"`r`nPaciente: $($d.nombre)   Edad: $($d.edad)   Sexo: $($d.sexo)`r`n`r`n## Motivo de consulta`r`n$($d.motivo)`r`n`r`n## Enfermedad actual`r`n$($d.actual)`r`n`r`n## Antecedentes`r`n$($d.antecedentes)`r`n`r`n## Medicacion`r`n$($d.medicacion)`r`n`r`n## Examen fisico`r`n$($d.examen)`r`n`r`n## Diagnostico presuntivo`r`n$($d.diagnostico)`r`n`r`n## Plan`r`n$($d.plan)`r`n"
        [IO.File]::WriteAllText($fn,$md,[Text.UTF8Encoding]::new($true))
        Send $ctx ('{"ok":true,"archivo":"'+(Split-Path $fn -Leaf)+'"}') }
    } elseif($p -in '/hc.html','/pacientes.html','/finanzas.html'){ Send $ctx ([IO.File]::ReadAllText("$root$p",[Text.Encoding]::UTF8)) 'text/html; charset=utf-8'
    } elseif($p -eq '/dictado/new'){ $d="$env:USERPROFILE\Pacientes\Dictados"; New-Item -ItemType Directory -Force $d | Out-Null; $script:dict="$d\dictado_"+(Get-Date -f 'yyyyMMdd_HHmm')+'.txt'; Send $ctx '{"ok":true}'
    } elseif($p -eq '/dictado/append'){ $t=$ctx.Request.QueryString['t']; if($script:dict -and $t -and $t.Length -lt 800 -and ((Get-Item $script:dict -ErrorAction SilentlyContinue).Length -lt 200KB)){ Add-Content $script:dict $t -Encoding UTF8 }; Send $ctx '{"ok":true}'
    } elseif($p -like '/open/*'){
      $k=$p.Substring(6)
      if($k -eq 'steamdl'){ Start-Process 'steam://nav/downloads'; Send $ctx '{"ok":true}' }
      elseif($k -eq 'steamlib'){ Start-Process 'steam://open/games'; Send $ctx '{"ok":true}' }
      elseif((FindStoreApp $k)){ $ap=FindStoreApp $k; Send $ctx '{"ok":true}'; Spawn 'app' $ap.AppID $storeApps[$k] }
      elseif($sites.ContainsKey($k)){ Send $ctx '{"ok":true}'; Spawn 'web' $sites[$k] }
      else { $ctx.Response.StatusCode=404; Send $ctx '{"ok":false}' }
    } elseif($p -like '/search/*'){
      $k=$p.Substring(8); $q=$ctx.Request.QueryString['q']
      if($search.ContainsKey($k) -and $q -and $q.Length -lt 200){ $u=[string]::Format($search[$k],[uri]::EscapeDataString($q)); Send $ctx '{"ok":true}'; Spawn 'web' $u }
      else { $ctx.Response.StatusCode=404; Send $ctx '{"ok":false}' }
    } elseif($p -like '/steamrun/*'){
      $id=$p.Substring(10); if($id -match '^\d+$'){ Start-Process "steam://rungameid/$id"; Send $ctx '{"ok":true}' } else { $ctx.Response.StatusCode=400; Send $ctx '{"ok":false}' }
    } elseif($p -eq '/alarm/ring'){
      $global:alarm=@{name=[string]$ctx.Request.QueryString['n'];hora=[string]$ctx.Request.QueryString['h']}
      try{ if(-not $global:snd){ $global:snd=New-Object System.Media.SoundPlayer 'C:\Windows\Media\Alarm01.wav' }; $global:snd.PlayLooping() }catch{}
      if($inbox.Count -lt 20){ [void]$inbox.Add('alarm:'+$global:alarm.name+'|'+$global:alarm.hora) }
      $k=KioskWin; if($k){ [void][W.U]::ShowWindow($k.MainWindowHandle,9); [void][W.U]::SetForegroundWindow($k.MainWindowHandle) } else { KioskStart }
      Send $ctx '{"ok":true}'
    } elseif($p -eq '/alarm/snooze'){ try{ if($global:snd){ $global:snd.Stop() } }catch{}; if($global:alarm){ ((Get-Date).AddMinutes(10).ToString('o')+'|'+$global:alarm.name+'|'+$global:alarm.hora) | Set-Content "$data\snooze.txt" -Encoding ASCII }; $global:alarm=$null; Send $ctx '{"ok":true}'
    } elseif($p -eq '/alarm/stop'){ try{ if($global:snd){ $global:snd.Stop() } }catch{}; $global:alarm=$null; Send $ctx '{"ok":true}'
    } elseif($p -eq '/alarm/state'){ if($global:alarm){ Send $ctx (ConvertTo-Json @{ringing=$true;name=$global:alarm.name;hora=$global:alarm.hora} -Compress) } else { Send $ctx '{"ringing":false}' }
    } elseif($p -like '/app/*'){
      $nm=[uri]::UnescapeDataString($p.Substring(5))
      if($nm -notmatch '^[\w .+()-]{2,60}$'){ $ctx.Response.StatusCode=400; Send $ctx '{"ok":false}' }
      else {
        $lnk=$null; foreach($r in @("$env:USERPROFILE\Desktop","$env:ProgramData\Microsoft\Windows\Start Menu\Programs","$env:APPDATA\Microsoft\Windows\Start Menu\Programs")){ $c=Get-ChildItem $r -Recurse -Filter "$nm.lnk" -ErrorAction SilentlyContinue | Select -First 1; if($c){ $lnk=$c.FullName; break } }
        if($lnk){ Start-Process $lnk; Send $ctx '{"ok":true}' } else { $ctx.Response.StatusCode=404; Send $ctx '{"ok":false}' }
      }
    } elseif($p -like '/dir/*'){
      $dirs=@{fondal="$env:USERPROFILE\Juegos\Fondal";historias="$env:USERPROFILE\Pacientes\Historias";descargas="$env:USERPROFILE\Downloads"}
      $dk=$p.Substring(5); if($dirs.ContainsKey($dk) -and (Test-Path $dirs[$dk])){ Start-Process explorer.exe $dirs[$dk]; Send $ctx '{"ok":true}' } else { $ctx.Response.StatusCode=404; Send $ctx '{"ok":false}' }
    } elseif($p -like '/play/*'){
      $parts=$p.Substring(6) -split '/',2; $rn=$parts[0]; $rel=''; if($parts.Count -gt 1){ $rel=[uri]::UnescapeDataString($parts[1]) }
      $base=Join-Path $env:USERPROFILE "Juegos\Fondal\$rn"; if(Test-Path (Join-Path $base "dist\index.html")){ $base=Join-Path $base "dist" }
      if($rn -notmatch '^[A-Za-z0-9._-]+$' -or -not (Test-Path $base -PathType Container)){ $ctx.Response.StatusCode=404; Send $ctx '{}' }
      elseif($parts.Count -eq 1){ $ctx.Response.Redirect("/play/$rn/"); $ctx.Response.Close() }
      else {
        if($rel -eq '' -or $rel.EndsWith('/')){ $rel+='index.html' }
        $fp=[IO.Path]::GetFullPath((Join-Path $base ($rel -replace '/','\')))
        if(-not $fp.StartsWith($base+'\') -or -not (Test-Path $fp -PathType Leaf)){ $ctx.Response.StatusCode=404; Send $ctx '{}' }
        else {
          $mt=@{'.html'='text/html; charset=utf-8';'.js'='text/javascript; charset=utf-8';'.mjs'='text/javascript; charset=utf-8';'.css'='text/css; charset=utf-8';'.json'='application/json';'.png'='image/png';'.jpg'='image/jpeg';'.jpeg'='image/jpeg';'.webp'='image/webp';'.gif'='image/gif';'.svg'='image/svg+xml';'.mp3'='audio/mpeg';'.ogg'='audio/ogg';'.wav'='audio/wav';'.wasm'='application/wasm';'.woff2'='font/woff2';'.woff'='font/woff';'.ttf'='font/ttf';'.glb'='model/gltf-binary';'.gltf'='model/gltf+json';'.webmanifest'='application/manifest+json';'.txt'='text/plain; charset=utf-8'}
          $ext=[IO.Path]::GetExtension($fp).ToLower(); $ct=$mt[$ext]; if(-not $ct){ $ct='application/octet-stream' }
          $b=[IO.File]::ReadAllBytes($fp); $ctx.Response.ContentType=$ct; $ctx.Response.ContentLength64=$b.Length; $ctx.Response.OutputStream.Write($b,0,$b.Length); $ctx.Response.Close()
        }
      }
    } elseif($p -like '/art/*'){
      $ap=Join-Path "$root\art" ($p.Substring(5) -replace '/','\')
      if($ap -like "$root\art\*" -and $ap -notmatch '\.\.' -and (Test-Path $ap -PathType Leaf)){ $b=[IO.File]::ReadAllBytes($ap); $ctx.Response.ContentType=$(if($ap -match '\.png$'){'image/png'}else{'image/jpeg'}); $ctx.Response.ContentLength64=$b.Length; $ctx.Response.OutputStream.Write($b,0,$b.Length); $ctx.Response.Close() } else { $ctx.Response.StatusCode=404; Send $ctx '{}' }
    } elseif($p -like '/fonts/*'){
      $fp=Join-Path "$root\fonts" ([IO.Path]::GetFileName($p))
      if(Test-Path $fp){ $b=[IO.File]::ReadAllBytes($fp); $ctx.Response.ContentType='font/woff2'; $ctx.Response.ContentLength64=$b.Length; $ctx.Response.OutputStream.Write($b,0,$b.Length); $ctx.Response.Close() } else { $ctx.Response.StatusCode=404; Send $ctx 'no' 'text/plain' }
    } elseif($p -eq '/mode/console'){ ToConsole $false; Send $ctx '{"ok":true}'
    } elseif($p -eq '/mode/games'){ ToConsole $true; Send $ctx '{"ok":true}'
    } elseif($p -eq '/mode/desktop'){ ToDesktop; Send $ctx '{"ok":true}'
    } elseif($p -like '/launch/*'){
      $k=$p.Substring(8)
      if($k -eq 'nuevahc'){ NewHC; Send $ctx '{"ok":true}' }
      elseif($apps.ContainsKey($k)){ Send $ctx '{"ok":true}'; if($k -in 'explorer','terminal','taskmgr','settings','hwinfo','steam','battlenet','pacientes'){ Spawn 'launch' $apps[$k] } else { Start-Process $apps[$k] } } else { $ctx.Response.StatusCode=404; Send $ctx '{"ok":false}' }
    } elseif($p -eq '/' -or $p -eq '/index.html'){ Send $ctx ([IO.File]::ReadAllText("$root\index.html",[Text.Encoding]::UTF8)) 'text/html; charset=utf-8'
    } else { $ctx.Response.StatusCode=404; Send $ctx 'no' 'text/plain' }
  } catch { try{ $ctx.Response.Abort() }catch{} }
}

