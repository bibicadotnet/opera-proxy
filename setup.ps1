<#
.SYNOPSIS
Automatically installs Opera Proxy with proper shortcut creation
#>

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
$processes = @(Get-Process -Name "opera-proxy*" -ErrorAction SilentlyContinue) +
             @(Get-Process -Name "wscript*" -ErrorAction SilentlyContinue |
               Where-Object { $_.Path -like "*opera-proxy.vbs" })

if ($processes) {
    $processes | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}


if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force }
if (Test-Path $operaProxyPath) { Remove-Item $operaProxyPath -Recurse -Force }

New-Item -ItemType Directory -Path $operaProxyPath -Force | Out-Null

# Determine architecture
$arch = switch ((Get-WmiObject Win32_Processor).Architecture) {
    0 { "386" }    # x86
    9 { "amd64" }  # x64
    12 { "arm64" } # ARM
    default { if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" } }
}
$downloadName = "opera-proxy.windows-$arch.exe"

# Download using WebClient
try {
    $release = Invoke-RestMethod "https://api.github.com/repos/Snawoot/opera-proxy/releases/latest"
    $downloadUrl = ($release.assets | Where-Object name -eq $downloadName).browser_download_url

    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($downloadUrl, "$operaProxyPath\$downloadName")
    Rename-Item "$operaProxyPath\$downloadName" "opera-proxy.exe" -Force
} catch { 
    Write-Host "Download failed: $_" -ForegroundColor Red
    exit 1
} finally {
    if ($webClient) { $webClient.Dispose() }
}

# Generate random config
$randomPort = Get-Random -Minimum 8000 -Maximum 9999
$fakeDomains = @("voz.vn", "google.com", "microsoft.com", "youtube.com", "facebook.com", "amazon.com", "apple.com", "netflix.com", "twitter.com", "instagram.com", "linkedin.com", "github.com", "stackoverflow.com", "reddit.com", "wikipedia.org", "gmail.com", "outlook.com", "yahoo.com", "bing.com", "cloudflare.com")
$randomDomain = $fakeDomains | Get-Random

# Create VBS launcher
@"
Set ws = CreateObject("WScript.Shell")
ws.CurrentDirectory = "$operaProxyPath"
ws.Run "opera-proxy.exe -country AS -bind-address 127.0.0.1:$randomPort -bootstrap-dns https://dns.google/dns-query -fake-SNI $randomDomain -socks-mode", 0, True
"@ | Out-File "$operaProxyPath\opera-proxy.vbs" -Encoding ASCII

# Create startup shortcut
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "$env:WINDIR\System32\wscript.exe"
$shortcut.Arguments = "`"$operaProxyPath\opera-proxy.vbs`""
$shortcut.WorkingDirectory = $operaProxyPath
$shortcut.Save()

# Start service immediately
Start-Process "wscript.exe" -ArgumentList "`"$operaProxyPath\opera-proxy.vbs`"" -WindowStyle Hidden

# Display info
Write-Host
$info = @"
Opera Socks5 Proxy installed successfully!

IP: 127.0.0.1
Port: $randomPort
Location: Singapore

Config file: $operaProxyPath\opera-proxy.vbs
Shortcut: $shortcutPath
"@

$info | Out-File "$operaProxyPath\info.txt" -Encoding UTF8
$info
Write-Host
