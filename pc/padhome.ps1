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
  public static int Read(out ushort b){ b=0; for(int i=0;i<4;i++){ ST s; int r; try{ r=GetEx(i,out s);}catch{ r=XInputGetState(i,out s);} if(r==0){ b=s.G.B; return i; } } return -1; }
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk,byte sc,uint f,UIntPtr e);
  [DllImport("user32.dll")] static extern bool EnumWindows(EP p,IntPtr l);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll",CharSet=CharSet.Auto)] static extern int GetWindowText(IntPtr h,StringBuilder b,int n);
  delegate bool EP(IntPtr h,IntPtr l);
  public static IntPtr Kiosk(){ IntPtr f=IntPtr.Zero; EnumWindows((h,l)=>{ if(IsWindowVisible(h)||true){ var t=new StringBuilder(256); GetWindowText(h,t,256); if(t.ToString().StartsWith("NEON CONSOLE")){ f=h; return false; } } return true; },IntPtr.Zero); return f; }
}
'@
$last = [datetime]::MinValue; $holdStart = $null; $guideWas = $false
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
  Start-Sleep -Milliseconds 80
}
