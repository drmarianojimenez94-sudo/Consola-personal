# Servidor HTTPS para el telefono (red local privada). Sirve la app (../phone), exige PIN y ejecuta:
#  - mouse / clics / scroll / teclas / texto en la PC (SendInput)
#  - el resto (voz, teclas del joystick) se reenvia a la consola por /inbox/push
$root=$PSScriptRoot; $data="$root\data"; $web=(Resolve-Path "$root\..\phone").Path; New-Item -ItemType Directory -Force $data | Out-Null
$subject='CN=NeonPanelPhone'
$cert=Get-ChildItem Cert:\CurrentUser\My | ? { $_.Subject -eq $subject -and $_.NotAfter -gt (Get-Date).AddDays(30) } | Select -First 1
if(-not $cert){ $cert=New-SelfSignedCertificate -Subject $subject -CertStoreLocation Cert:\CurrentUser\My -KeyExportPolicy Exportable -KeySpec KeyExchange -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider' -NotAfter (Get-Date).AddYears(5) -DnsName 'neonpanel','localhost' }
$listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Any,8443); $listener.Start()
$fails=[hashtable]::Synchronized(@{})
$pool=[runspacefactory]::CreateRunspacePool(1,8); $pool.Open()
$work={
 param($client,$cert,$web,$data,$fails)
 Add-Type -AssemblyName System.Web
 if(-not ('NI' -as [type])){ try{ Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class NI {
 [DllImport("user32.dll")] public static extern void mouse_event(uint f,int dx,int dy,int d,UIntPtr e);
 [DllImport("user32.dll")] public static extern void keybd_event(byte vk,byte sc,uint f,UIntPtr e);
 [DllImport("user32.dll")] public static extern uint SendInput(uint n, INPUT[] i, int sz);
 [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT{public int dx,dy;public uint mouseData,dwFlags,time;public IntPtr dwExtraInfo;}
 [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT{public ushort wVk,wScan;public uint dwFlags,time;public IntPtr dwExtraInfo;}
 [StructLayout(LayoutKind.Explicit)] public struct U{[FieldOffset(0)] public MOUSEINPUT mi;[FieldOffset(0)] public KEYBDINPUT ki;}
 [StructLayout(LayoutKind.Sequential)] public struct INPUT{public uint type;public U u;}
 public static void Uni(string s){ foreach(char ch in s){ var d=new INPUT{type=1}; d.u.ki=new KEYBDINPUT{wVk=0,wScan=ch,dwFlags=4}; var u=new INPUT{type=1}; u.u.ki=new KEYBDINPUT{wVk=0,wScan=ch,dwFlags=6}; SendInput(2,new INPUT[]{d,u},Marshal.SizeOf(typeof(INPUT))); } }
 public static void Key(byte vk){ keybd_event(vk,0,0,UIntPtr.Zero); keybd_event(vk,0,2,UIntPtr.Zero); }
}
'@ }catch{} }
 $VK=@{enter=0x0D;esc=0x1B;tab=0x09;backspace=0x08;up=0x26;down=0x28;left=0x25;right=0x27;space=0x20;delete=0x2E;home=0x24;end=0x23;pgup=0x21;pgdn=0x22;f11=0x7A;playpause=0xB3;next=0xB0;prev=0xB1;volup=0xAF;voldown=0xAE;mute=0xAD}
 function IsPrivate($ip){ $ip -match '^(10\.|192\.168\.|127\.|172\.(1[6-9]|2[0-9]|3[01])\.|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.)' }
 try{
  $client.ReceiveTimeout=8000; $client.SendTimeout=8000
  $ip=$client.Client.RemoteEndPoint.Address.ToString(); if(-not (IsPrivate $ip)){ return }
  $ssl=New-Object Net.Security.SslStream($client.GetStream(),$false)
  $ssl.AuthenticateAsServer($cert,$false,[Security.Authentication.SslProtocols]::Tls12,$false)
  $buf=New-Object byte[] 8192; $n=$ssl.Read($buf,0,8192); if($n -le 0){ return }
  $req=[Text.Encoding]::UTF8.GetString($buf,0,$n); $line=($req -split "`r?`n")[0]
  if($line -notmatch '^GET (\S+) HTTP'){ return }
  $uri=$Matches[1]; $path=$uri.Split('?')[0]; $q=[System.Web.HttpUtility]::ParseQueryString(($uri -split '\?',2)[1])
  function Reply($code,$body,$type){ $b=[Text.Encoding]::UTF8.GetBytes($body); $h="HTTP/1.1 $code`r`nContent-Type: $type`r`nContent-Length: $($b.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"; $hb=[Text.Encoding]::ASCII.GetBytes($h); $ssl.Write($hb,0,$hb.Length); $ssl.Write($b,0,$b.Length); $ssl.Flush() }
  $static=@{'/'='index.html|text/html; charset=utf-8';'/manifest.webmanifest'='manifest.webmanifest|application/manifest+json';'/icon.svg'='icon.svg|image/svg+xml';'/sw.js'='sw.js|text/javascript'}
  if($static.ContainsKey($path)){ $f,$ty=$static[$path].Split('|'); Reply '200 OK' ([IO.File]::ReadAllText("$web\$f",[Text.Encoding]::UTF8)) $ty; return }
  if($path -eq '/cmd' -or $path -eq '/check'){
   $f=$fails[$ip]; if($f -and $f.until -gt (Get-Date)){ Reply '429 Too Many Requests' '{"ok":false,"err":"bloqueado 60s"}' 'application/json'; return }
   $pin=(Get-Content "$data\pin.txt" -Raw).Trim()
   if($q['pin'] -ne $pin){ $c=1; if($f){$c=$f.n+1}; $fails[$ip]=@{n=$c;until=$(if($c -ge 5){(Get-Date).AddSeconds(60)}else{[datetime]::MinValue})}; Reply '403 Forbidden' '{"ok":false,"err":"PIN incorrecto"}' 'application/json'; return }
   $fails.Remove($ip)
   if($path -eq '/cmd'){
    $t=$q['t']; if($t -and $t.Length -lt 300){
     if($t -eq 'key:ping'){ }
     elseif($t -match '^loc:(-?\d{1,3}\.\d{1,6}),(-?\d{1,3}\.\d{1,6}),(\d{1,6})$'){ $lat=[double]::Parse($Matches[1],[Globalization.CultureInfo]::InvariantCulture); $lon=[double]::Parse($Matches[2],[Globalization.CultureInfo]::InvariantCulture); if([Math]::Abs($lat) -le 90 -and [Math]::Abs($lon) -le 180){ ('{0}' -f (ConvertTo-Json @{lat=$lat;lon=$lon;acc=[int]$Matches[3];at=(Get-Date -f s)} -Compress)) | Set-Content "$data\phone_location.json" -Encoding UTF8 } }
     elseif($t -match '^mouse:(-?\d{1,4}),(-?\d{1,4})$'){ $dx=[Math]::Max(-300,[Math]::Min(300,[int]$Matches[1])); $dy=[Math]::Max(-300,[Math]::Min(300,[int]$Matches[2])); [NI]::mouse_event(1,$dx,$dy,0,[UIntPtr]::Zero) }
     elseif($t -match '^click:(left|right|double)$'){ switch($Matches[1]){ 'left'{[NI]::mouse_event(2,0,0,0,[UIntPtr]::Zero);[NI]::mouse_event(4,0,0,0,[UIntPtr]::Zero)} 'right'{[NI]::mouse_event(8,0,0,0,[UIntPtr]::Zero);[NI]::mouse_event(16,0,0,0,[UIntPtr]::Zero)} 'double'{1..2|%{[NI]::mouse_event(2,0,0,0,[UIntPtr]::Zero);[NI]::mouse_event(4,0,0,0,[UIntPtr]::Zero);Start-Sleep -Milliseconds 40}} } }
     elseif($t -match '^scroll:(-?\d{1,2})$'){ [NI]::mouse_event(0x800,0,0,([int]$Matches[1]*120),[UIntPtr]::Zero) }
     elseif($t -match '^pckey:(\w+)$' -and $VK.ContainsKey($Matches[1])){ [NI]::Key([byte]$VK[$Matches[1]]) }
     elseif($t.StartsWith('type:')){ $s=$t.Substring(5); if($s.Length -le 200){ [NI]::Uni($s) } }
     else { Invoke-WebRequest ('http://127.0.0.1:8777/inbox/push?t='+[uri]::EscapeDataString($t)) -UseBasicParsing -TimeoutSec 5 | Out-Null }
    } }
   Reply '200 OK' '{"ok":true}' 'application/json'; return }
  Reply '404 Not Found' 'no' 'text/plain'
 }catch{ try{ Add-Content "$data\phone_err.log" ("$(Get-Date -f s) "+$_.Exception.Message+' | '+$_.Exception.InnerException.Message) }catch{} } finally{ try{$client.Close()}catch{} }
}
while($true){
 $c=$listener.AcceptTcpClient()
 $ps=[powershell]::Create(); $ps.RunspacePool=$pool; [void]$ps.AddScript($work).AddArgument($c).AddArgument($cert).AddArgument($web).AddArgument($data).AddArgument($fails); [void]$ps.BeginInvoke()
}
