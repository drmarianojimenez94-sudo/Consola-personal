# Atajo del joystick: vuelve al panel desde cualquier juego/app.
#  - Boton Guia (Xbox) o Back+Start mantenidos 1 s  ->  trae el panel al frente
#  - Si el panel ya esta al frente, vuelve a la ultima ventana (Alt+Tab)
Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices; using System.Text; using System.Collections.Generic;
public static class Pad {
  [StructLayout(LayoutKind.Sequential)] public struct GP { public ushort B; public byte LT, RT; public short LX, LY, RX, RY; }
  [StructLayout(LayoutKind.Sequential)] public struct ST { public uint P; public GP G; }
  [DllImport("xinput1_4.dll", EntryPoint="#100")] static extern int GetEx(int i, out ST s);
  [DllImport("xinput1_4.dll")] static extern int XInputGetState(int i, out ST s);
  public static short LX, LY, RX, RY; public static byte LT;
  public static int Read(out ushort b){ b=0; for(int i=0;i<4;i++){ ST s; int r; try{ r=GetEx(i,out s);}catch{ r=XInputGetState(i,out s);} if(r==0){ b=s.G.B; LX=s.G.LX; LY=s.G.LY; RX=s.G.RX; RY=s.G.RY; LT=s.G.LT; return i; } } return -1; }
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk,byte sc,uint f,UIntPtr e);
  [DllImport("user32.dll")] static extern bool EnumWindows(EP p,IntPtr l);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll",CharSet=CharSet.Auto)] static extern int GetWindowText(IntPtr h,StringBuilder b,int n);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f,int dx,int dy,int d,UIntPtr e);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
  public static uint Pid(IntPtr h){ uint p; GetWindowThreadProcessId(h,out p); return p; }
  delegate bool EP(IntPtr h,IntPtr l);
  public static IntPtr Kiosk(){ IntPtr f=IntPtr.Zero; EnumWindows((h,l)=>{ if(IsWindowVisible(h)||true){ var t=new StringBuilder(256); GetWindowText(h,t,256); if(t.ToString().StartsWith("NEON CONSOLE")){ f=h; return false; } } return true; },IntPtr.Zero); return f; }
}
'@
$last = [datetime]::MinValue; $holdStart = $null; $guideWas = $false
$dbgT = [datetime]::MinValue; $kc = [IntPtr]::Zero; $kt = [datetime]::MinValue; $prevB = 0; $wc = New-Object Net.WebClient
# --- Modo mouse: palanca izq = cursor, A = clic izq., B = clic der., palanca der. = scroll, LT = cursor lento.
# Solo se activa cuando al frente hay un navegador/reproductor/escritorio (NO en juegos ni en el panel).
# L3+R3 (apretar ambas palancas) lo apaga/enciende a mano.
$mouseApps = 'msedge','chrome','firefox','brave','opera','vivaldi','explorer','vlc','mpc-hc64','mpc-hc','potplayer64','SumatraPDF','WINWORD','EXCEL','POWERPNT','Krita','audacity','obs64','Spotify','ApplicationFrameHost','Netflix','HBOMax','DisneyPlus','Plex','Kodi','Taskmgr'
$mouseOff = $false; $mouseOn = $false; $mpT = [datetime]::MinValue; $aDown = $false; $bDown = $false; $l3Was = $false; $mouseCnt = 0
$map = @{ 1='up'; 2='down'; 4='left'; 8='right'; 16='start'; 32='back'; 256='lb'; 512='rb'; 4096='ok'; 8192='b'; 16384='x'; 32768='y' }
while ($true) {
  $b = [uint16]0
  $idx = [Pad]::Read([ref]$b)
  if ($idx -lt 0) { Start-Sleep 2; continue }          # sin control conectado: revisar poco
  $guide = ($b -band 0x0400) -ne 0
  $combo = (($b -band 0x30) -eq 0x30)
  $fire = $false
  if ($guide -and -not $guideWas) { $fire = $true }
  $guideWas = $guide
  if ($combo) { if (-not $holdStart) { $holdStart = Get-Date } elseif (((Get-Date) - $holdStart).TotalMilliseconds -ge 1000) { $fire = $true; $holdStart = $null; Start-Sleep -Milliseconds 800 } } else { $holdStart = $null }
  # navegacion del panel con el joystick (D-pad, stick izq., A/B/X/Y/Start/Back/LB/RB) cuando el panel esta al frente
  if (((Get-Date) - $kt).TotalSeconds -gt 3) { $kc = [Pad]::Kiosk(); $kt = Get-Date }
  $b2 = [int]$b
  if ([Pad]::LX -lt -16000) { $b2 = $b2 -bor 4 } elseif ([Pad]::LX -gt 16000) { $b2 = $b2 -bor 8 }
  if ([Pad]::LY -gt 16000) { $b2 = $b2 -bor 1 } elseif ([Pad]::LY -lt -16000) { $b2 = $b2 -bor 2 }
  $front = ($kc -ne [IntPtr]::Zero) -and ([Pad]::GetForegroundWindow() -eq $kc)
  if ($front -and -not $combo) {
    $new = $b2 -band (-bnot $prevB)
    foreach ($k in $map.Keys) { if ($new -band $k) { try { [void]$wc.DownloadString('http://127.0.0.1:8777/inbox/push?t=key:' + $map[$k]); Add-Content "$PSScriptRoot\data\padhome.log" ((Get-Date -f HH:mm:ss) + ' push ' + $map[$k]) } catch { Add-Content "$PSScriptRoot\data\padhome.err" ((Get-Date -f HH:mm:ss) + ' ' + $_.Exception.Message) } } }
  }
  # ---- modo mouse ----
  if (((Get-Date) - $mpT).TotalMilliseconds -gt 300) {
    $mpT = Get-Date; $mouseOn = $false
    if (-not $mouseOff -and -not $front) {
      try { $fg = [Pad]::GetForegroundWindow(); $pn = (Get-Process -Id ([Pad]::Pid($fg)) -ErrorAction Stop).ProcessName; $mouseOn = ($mouseApps -contains $pn) } catch {}
    }
    if (-not $mouseOn) { if ($aDown) { [Pad]::mouse_event(4,0,0,0,[UIntPtr]::Zero); $aDown = $false }; if ($bDown) { [Pad]::mouse_event(16,0,0,0,[UIntPtr]::Zero); $bDown = $false } }
  }
  $l3r3 = (($b -band 0xC0) -eq 0xC0)
  if ($l3r3 -and -not $l3Was) { $mouseOff = -not $mouseOff; Add-Content "$PSScriptRoot\data\padhome.log" ((Get-Date -f HH:mm:ss) + ' modo mouse ' + $(if ($mouseOff) {'OFF'} else {'auto'})) }
  $l3Was = $l3r3
  if ($mouseOn) {
    $slow = if ([Pad]::LT -gt 100) { 0.25 } else { 1.0 }
    $dx = 0; $dy = 0
    $lx = [int][Pad]::LX; $ly = [int][Pad]::LY
    if ([Math]::Abs($lx) -gt 7000) { $dx = [Math]::Sign($lx) * [Math]::Pow(([Math]::Abs($lx) - 7000) / 25767.0, 2) * 38 * $slow }
    if ([Math]::Abs($ly) -gt 7000) { $dy = -[Math]::Sign($ly) * [Math]::Pow(([Math]::Abs($ly) - 7000) / 25767.0, 2) * 38 * $slow }
    if ($dx -ne 0 -or $dy -ne 0) { [Pad]::mouse_event(1,[int][Math]::Round($dx),[int][Math]::Round($dy),0,[UIntPtr]::Zero) }
    $ry = [int][Pad]::RY
    $mouseCnt++
    if ([Math]::Abs($ry) -gt 9000 -and ($mouseCnt % 3) -eq 0) { [Pad]::mouse_event(0x800,0,0,[int]([Math]::Sign($ry) * [Math]::Pow(([Math]::Abs($ry) - 9000) / 23767.0, 1.5) * 120),[UIntPtr]::Zero) }
    $aNow = ($b -band 0x1000) -ne 0; $bNow = ($b -band 0x2000) -ne 0
    if ($aNow -and -not $aDown) { [Pad]::mouse_event(2,0,0,0,[UIntPtr]::Zero); $aDown = $true } elseif (-not $aNow -and $aDown) { [Pad]::mouse_event(4,0,0,0,[UIntPtr]::Zero); $aDown = $false }
    if ($bNow -and -not $bDown) { [Pad]::mouse_event(8,0,0,0,[UIntPtr]::Zero); $bDown = $true } elseif (-not $bNow -and $bDown) { [Pad]::mouse_event(16,0,0,0,[UIntPtr]::Zero); $bDown = $false }
  }
  $prevB = $b2
  if (((Get-Date) - $dbgT).TotalSeconds -gt 5) { $dbgT = Get-Date; Add-Content "$PSScriptRoot\data\padhome.log" ((Get-Date -f HH:mm:ss) + ' idx=' + $idx + ' b=' + $b + ' front=' + $front + ' kc=' + $kc) }
  if ($fire -and ((Get-Date) - $last).TotalMilliseconds -gt 1500) {
    $last = Get-Date
    $k = [Pad]::Kiosk()
    if ($k -ne [IntPtr]::Zero) {
      if ([Pad]::GetForegroundWindow() -eq $k) {
        [Pad]::keybd_event(0x12,0,0,[UIntPtr]::Zero); [Pad]::keybd_event(0x09,0,0,[UIntPtr]::Zero); [Pad]::keybd_event(0x09,0,2,[UIntPtr]::Zero); [Pad]::keybd_event(0x12,0,2,[UIntPtr]::Zero)
      } else {
        [Pad]::keybd_event(0x12,0,0,[UIntPtr]::Zero); [Pad]::keybd_event(0x12,0,2,[UIntPtr]::Zero)
        [void][Pad]::ShowWindow($k,9); [void][Pad]::SetForegroundWindow($k)
      }
    }
  }
  if ($mouseOn) { Start-Sleep -Milliseconds 10 } else { Start-Sleep -Milliseconds 80 }
}
