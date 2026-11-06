# Abre apps/sitios al frente y maximizados. Corre en su propio proceso para no bloquear el servidor local.
param($mode, $arg, $title)
Add-Type -Namespace W -Name U -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r);
[DllImport("user32.dll")] public static extern void keybd_event(byte vk,byte sc,uint f,UIntPtr e);
[DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p,IntPtr l);
[DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll",CharSet=CharSet.Auto)] static extern int GetClassName(IntPtr h,System.Text.StringBuilder b,int n);
[DllImport("user32.dll",CharSet=CharSet.Auto)] static extern int GetWindowText(IntPtr h,System.Text.StringBuilder b,int n);
delegate bool EnumProc(IntPtr h,IntPtr l);
public static IntPtr[] EdgeWins(){ var r=new System.Collections.Generic.List<IntPtr>(); EnumWindows((h,l)=>{ if(IsWindowVisible(h)){ var c=new System.Text.StringBuilder(64); GetClassName(h,c,64); if(c.ToString()=="Chrome_WidgetWin_1"){ var t=new System.Text.StringBuilder(256); GetWindowText(h,t,256); if(t.Length>0) r.Add(h);} } return true; },IntPtr.Zero); return r.ToArray(); }
public static string Title(IntPtr h){ var t=new System.Text.StringBuilder(256); GetWindowText(h,t,256); return t.ToString(); }
[StructLayout(LayoutKind.Sequential)] public struct RECT{public int L,T,R,B;}
'@
Add-Type -AssemblyName System.Windows.Forms
$edgeExe = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
function Front($h) {
  [W.U]::keybd_event(0x12,0,0,[UIntPtr]::Zero); [W.U]::keybd_event(0x12,0,2,[UIntPtr]::Zero)   # Alt: permite pasar la ventana al frente
  [void][W.U]::ShowWindow($h,3); [void][W.U]::SetForegroundWindow($h)
}
function OpenWeb($url) {
  $before = @([W.U]::EdgeWins())
  Start-Process $edgeExe -ArgumentList "--app=$url", '--start-fullscreen'
  $new = $null
  for ($i = 0; $i -lt 20 -and -not $new; $i++) { Start-Sleep -Milliseconds 350; $new = [W.U]::EdgeWins() | ? { $before -notcontains $_ -and ([W.U]::Title($_)) -notlike 'NEON CONSOLE*' } | Select -First 1 }
  if (-not $new) { return }
  Start-Sleep -Milliseconds 700; Front $new; Start-Sleep -Milliseconds 500
  $rc = New-Object 'W.U+RECT'; [void][W.U]::GetWindowRect($new, [ref]$rc)
  $sh = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
  if (($rc.B - $rc.T) -lt ($sh - 2)) { [W.U]::keybd_event(0x7A,0,0,[UIntPtr]::Zero); [W.U]::keybd_event(0x7A,0,2,[UIntPtr]::Zero) }
}
function OpenApp($appid, $t) {
  if ($appid -match '^[A-Za-z]:\\') { Start-Process $appid } else { Start-Process explorer.exe "shell:AppsFolder\$appid" }
  $h = $null
  for ($i = 0; $i -lt 30 -and -not $h; $i++) { Start-Sleep -Milliseconds 400; $h = (Get-Process | ? { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -like "*$t*" -and $_.Name -notin 'claude','msedge' } | Select -First 1).MainWindowHandle }
  if ($h) { Front $h }
}
function LaunchApp($target) {
  Start-Process $target
  $new = $null
  for ($i = 0; $i -lt 30 -and -not $new; $i++) { Start-Sleep -Milliseconds 400; $new = Get-Process | ? { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -and $_.MainWindowTitle -notlike 'NEON CONSOLE*' -and $_.Name -notin 'claude','msedge','explorer' -and (Get-Date) -lt ($_.StartTime.AddSeconds(25)) } | Select -First 1 }
  if ($new) { Front $new.MainWindowHandle }
}
switch ($mode) { 'web' { OpenWeb $arg } 'app' { OpenApp $arg $title } 'launch' { LaunchApp $arg } }
