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
$arch = switch ((Get-WmiObject Win32_Processor).Architecture) {
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

# Generate random ports for 3 servers
$portAS = Get-Random -Minimum 10000 -Maximum 10099
$portAM = Get-Random -Minimum 10100 -Maximum 10199
$portEU = Get-Random -Minimum 10200 -Maximum 10299

$fakeDomains = @("voz.vn", "google.com", "microsoft.com", "youtube.com", "facebook.com", "amazon.com", "apple.com", "netflix.com", "twitter.com", "instagram.com", "linkedin.com", "github.com", "stackoverflow.com", "reddit.com", "wikipedia.org", "gmail.com", "outlook.com", "yahoo.com", "bing.com", "cloudflare.com")
$randomDomain = $fakeDomains | Get-Random

# Create VBS launcher for all 3 servers
@"
Set ws = CreateObject("WScript.Shell")
ws.CurrentDirectory = "$operaProxyPath"
ws.Run "opera-proxy.exe -country AS -bind-address 127.0.0.1:$portAS -bootstrap-dns https://dns.google/dns-query -fake-SNI $randomDomain -socks-mode", 0, False
ws.Run "opera-proxy.exe -country AM -bind-address 127.0.0.1:$portAM -bootstrap-dns https://dns.google/dns-query -fake-SNI $randomDomain -socks-mode", 0, False
ws.Run "opera-proxy.exe -country EU -bind-address 127.0.0.1:$portEU -bootstrap-dns https://dns.google/dns-query -fake-SNI $randomDomain -socks-mode", 0, False
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

# Display info
Write-Host
$info = @"
Opera Socks5 Proxy installed successfully!

IP: 127.0.0.1
Port: $portAS
Location: Singapore

IP: 127.0.0.1
Port: $portAM
Location: Americas

IP: 127.0.0.1
Port: $portEU
Location: Europe

Config file: $operaProxyPath\opera-proxy.vbs
Shortcut: $shortcutPath
"@
$info | Out-File "$operaProxyPath\info.txt" -Encoding UTF8
$info
Write-Host
