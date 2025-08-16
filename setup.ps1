# Check admin rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
   Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://go.bibica.net/opera-proxy | iex`"" -Verb RunAs
   exit
}
clear

# Configuration
$operaProxyPath = "C:\opera-proxy"
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = Join-Path $startupPath "opera-proxy.lnk"

# Cleanup previous installation
Get-Process -Name "opera-proxy" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-WmiObject Win32_Process | Where-Object {$_.Name -eq "wscript.exe" -and $_.CommandLine -like "*opera-proxy.vbs*"} | ForEach-Object {$_.Terminate()}
Start-Sleep -Milliseconds 500
if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force }
if (Test-Path $operaProxyPath) { Remove-Item $operaProxyPath -Recurse -Force }
New-Item -ItemType Directory -Path $operaProxyPath -Force | Out-Null

# Determine architecture
$arch = switch ((Get-WmiObject Win32_Processor | Select-Object -First 1).Architecture) {
   0 { "386" }
   9 { "amd64" }
   12 { "arm64" }
   default { if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" } }
}
$downloadName = "opera-proxy.windows-$arch.exe"

# Download
$release = Invoke-RestMethod "https://api.github.com/repos/Snawoot/opera-proxy/releases/latest"
$downloadUrl = ($release.assets | Where-Object name -eq $downloadName).browser_download_url
(New-Object System.Net.WebClient).DownloadFile($downloadUrl, "$operaProxyPath\$downloadName")
Rename-Item "$operaProxyPath\$downloadName" "opera-proxy.exe" -Force

# Create VBS launcher for all 3 servers
@"
Set ws = CreateObject("WScript.Shell")
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")

On Error Resume Next

' Kill existing opera-proxy processes
Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'opera-proxy.exe'")
For Each objProcess in colProcesses
    objProcess.Terminate()
Next

On Error GoTo 0

WScript.Sleep 1000

ws.CurrentDirectory = "$operaProxyPath"
ws.Run "opera-proxy.exe -country AS -bind-address 127.0.0.1:10001 -bootstrap-dns https://dns.google/dns-query -fake-SNI www.cloudflare.com -socks-mode", 0, False
ws.Run "opera-proxy.exe -country AM -bind-address 127.0.0.1:10002 -bootstrap-dns https://dns.google/dns-query -fake-SNI www.cloudflare.com -socks-mode", 0, False
ws.Run "opera-proxy.exe -country EU -bind-address 127.0.0.1:10003 -bootstrap-dns https://dns.google/dns-query -fake-SNI www.cloudflare.com -socks-mode", 0, False
"@ | Out-File "$operaProxyPath\opera-proxy.vbs" -Encoding ASCII

# Create startup shortcut
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "$env:WINDIR\System32\wscript.exe"
$shortcut.Arguments = "`"$operaProxyPath\opera-proxy.vbs`""
$shortcut.WorkingDirectory = $operaProxyPath
$shortcut.Save()

# Start service immediately
Start-Process $shortcutPath

# Create VBS launcher Singapore 1
@"
Set ws = CreateObject("WScript.Shell")
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")

On Error Resume Next

' Kill existing opera-proxy processes
Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'opera-proxy.exe'")
For Each objProcess in colProcesses
    objProcess.Terminate()
Next

On Error GoTo 0

WScript.Sleep 1000

ws.CurrentDirectory = "$operaProxyPath"
ws.Run "opera-proxy.exe -country AS -bind-address 127.0.0.1:10001 -bootstrap-dns https://dns.google/dns-query -fake-SNI www.cloudflare.com -socks-mode -override-proxy-address 77.111.245.11", 0, False
ws.Run "opera-proxy.exe -country AM -bind-address 127.0.0.1:10002 -bootstrap-dns https://dns.google/dns-query -fake-SNI www.cloudflare.com -socks-mode", 0, False
ws.Run "opera-proxy.exe -country EU -bind-address 127.0.0.1:10003 -bootstrap-dns https://dns.google/dns-query -fake-SNI www.cloudflare.com -socks-mode", 0, False
"@ | Out-File "$operaProxyPath\opera-proxy-singapore-1.vbs" -Encoding ASCII

# Create VBS launcher Singapore 2
@"
Set ws = CreateObject("WScript.Shell")
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")

On Error Resume Next

' Kill existing opera-proxy processes
Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'opera-proxy.exe'")
For Each objProcess in colProcesses
    objProcess.Terminate()
Next

On Error GoTo 0

WScript.Sleep 1000

ws.CurrentDirectory = "$operaProxyPath"
ws.Run "opera-proxy.exe -country AS -bind-address 127.0.0.1:10001 -bootstrap-dns https://dns.google/dns-query -fake-SNI www.cloudflare.com -socks-mode -override-proxy-address 77.111.245.12", 0, False
ws.Run "opera-proxy.exe -country AM -bind-address 127.0.0.1:10002 -bootstrap-dns https://dns.google/dns-query -fake-SNI www.cloudflare.com -socks-mode", 0, False
ws.Run "opera-proxy.exe -country EU -bind-address 127.0.0.1:10003 -bootstrap-dns https://dns.google/dns-query -fake-SNI www.cloudflare.com -socks-mode", 0, False
"@ | Out-File "$operaProxyPath\opera-proxy-singapore-2.vbs" -Encoding ASCII

# Display info
Write-Host
$info = @"
Opera Socks5 Proxy installed successfully!

IP: 127.0.0.1
Port: 10001
Location: Singapore

IP: 127.0.0.1
Port: 10002
Location: Americas

IP: 127.0.0.1
Port: 10003
Location: Europe

Config file: $operaProxyPath\opera-proxy.vbs
Shortcut: $shortcutPath
"@
$info | Out-File "$operaProxyPath\info.txt" -Encoding UTF8
$info
Write-Host
