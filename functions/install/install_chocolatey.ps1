# functions/install/install_chocolatey.ps1
# Установка выбранных программ через Chocolatey в фоновом Runspace

# Запускает асинхронную установку выбранных программ через Chocolatey
function Install-ChocoPrograms {
    param([string[]]$AppNames)
    
    if (-not $AppNames -or $AppNames.Count -eq 0) { return }
    if (-not (Ensure-Chocolatey)) { return }
    
    # Список пакетов Chocolatey и portable-программ для ярлыков
    $pkgList = @()
    $shortcutApps = @()
    
    foreach ($app in $AppNames) {
        $info = Get-AppInfo -AppName $app
        if ($info -and $info.choco) {
            $pkgList += $info.choco
            if ($info.desktop -and $info.exePath) {
                $shortcutApps += @{
                    Name = $app
                    ExePath = $ExecutionContext.InvokeCommand.ExpandString($info.exePath)
                }
            }
        }
    }
    if ($pkgList.Count -eq 0) { return }
    
    $resultHash = @{ ExitCode = 1 }
    $scriptBlock = {
        param($pkgList, $shortcutApps, $hostObj, $result)
        
        try { $hostObj.UI.RawUI.BackgroundColor = 'Black'; $hostObj.UI.RawUI.ForegroundColor = 'Gray' } catch {}
        
        Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  УСТАНОВКА ПРОГРАММ ($($pkgList.Count)) через Chocolatey" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        
        $chocoExe = "C:\ProgramData\chocolatey\bin\choco.exe"
        if (-not (Test-Path $chocoExe)) {
            Write-Host "  ❌ Chocolatey не найден: $chocoExe" -ForegroundColor Red
            $result.ExitCode = 1
            return
        }
        
        $successful = @{}
        $failed = @{}
        $successPattern = 'success|installed|successful|Deployed'
        $errorPattern = @(
            'ERROR:', 'Exception calling', 'fail', 'not found', 'not installed',
            'timeout', 'timed out', 'connection', 'SSL', 'TLS', 'certificate',
            'unauthorized', 'forbidden', '403', '404', '500', '503',
            'checksum', 'mismatch', 'hash', 'exit code', 'returned exit code',
            '1603', '1601', '1605', '1618', '1641', 'dependency', 'Unable to resolve'
        ) -join '|'
        
        foreach ($pkg in $pkgList) {
            Write-Host "`n  → $pkg" -ForegroundColor Cyan
            $installArgs = @("upgrade", $pkg, "-y", "--no-progress")
            $pkgOutput = @()
            
            & $chocoExe @installArgs 2>&1 | ForEach-Object {
                $line = "$_"
                $pkgOutput += $line
                $color = if ($line -match $successPattern) { 'Green' }
                         elseif ($line -match $errorPattern) { 'Red' }
                         elseif ($line -match 'warning|already installed') { 'Yellow' }
                         elseif ($line -match 'downloading|installing|Downloading') { 'Cyan' }
                         else { 'Gray' }
                Write-Host "    $line" -ForegroundColor $color
            }
            
            $outputJoined = $pkgOutput -join " "
            
            if ($outputJoined -match 'The (install|upgrade) of [^\s]+ was successful') {
                $successful[$pkg] = $true
                Write-Host "    ✅ Установлено: $pkg" -ForegroundColor Green
            }
            elseif ($outputJoined -match 'is the latest version|Nothing to change|up-to-date|already installed') {
                $successful[$pkg] = $true
                Write-Host "    ✅ Уже актуальна: $pkg" -ForegroundColor Green
            }
            else {
                $errorLines = $pkgOutput | Where-Object { $_ -match $errorPattern }
                $failed[$pkg] = if ($errorLines -and $errorLines.Count -gt 0) {
                    $max = [Math]::Min(3, $errorLines.Count)
                    ($errorLines | Select-Object -First $max | ForEach-Object { $_.Trim() }) -join " | "
                } else { "Неизвестная ошибка (см. вывод выше)" }
                Write-Host "    ❌ Не удалось: $pkg" -ForegroundColor Red
            }
        }
        
        # Итоговый отчёт
        Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  РЕЗУЛЬТАТ УСТАНОВКИ" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        if ($successful.Count -gt 0) {
            Write-Host "  ✅ Установлено: $($successful.Count)" -ForegroundColor Green
        }
        if ($failed.Count -gt 0) {
            Write-Host "  ❌ Ошибок: $($failed.Count)" -ForegroundColor Red
            foreach ($p in $failed.Keys) {
                Write-Host "    • $p" -ForegroundColor Red
                Write-Host "      $($failed[$p])" -ForegroundColor Yellow
            }
        }
        
        # Ярлыки для portable-программ
        if ($shortcutApps -and $shortcutApps.Count -gt 0) {
            Write-Host ""
            $desktop = [Environment]::GetFolderPath("Desktop")
            foreach ($sApp in $shortcutApps) {
                if (-not (Test-Path $sApp.ExePath)) {
                    Write-Host "  ⚠ $($sApp.Name): exe не найден ($($sApp.ExePath))" -ForegroundColor Yellow
                    continue
                }
                try {
                    $lnk = Join-Path $desktop "$($sApp.Name).lnk"
                    $shell = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
                    $shell.TargetPath = $sApp.ExePath
                    $shell.WorkingDirectory = Split-Path $sApp.ExePath
                    $shell.Save()
                    Write-Host "  📌 $($sApp.Name): ярлык создан" -ForegroundColor Green
                } catch {
                    Write-Host "  ⚠ $($sApp.Name): не удалось создать ярлык" -ForegroundColor Yellow
                }
            }
        }
        
        $result.ExitCode = if ($failed.Count -eq 0 -and $successful.Count -gt 0) { 0 } else { 1 }
    }
    
    # Запуск в Runspace без блокировки UI
    $runspace = [runspacefactory]::CreateRunspace($Host)
    $runspace.Open()
    $ps = [powershell]::Create().AddScript($scriptBlock).AddArgument($pkgList).AddArgument($shortcutApps).AddArgument($Host).AddArgument($resultHash)
    $ps.Runspace = $runspace
    $script:InstallJob = @{
        PowerShell = $ps
        AsyncResult = $ps.BeginInvoke()
        Runspace = $runspace
        ResultHash = $resultHash
    }
    
    # Добавление путей dev-инструментов в системный PATH
    foreach ($app in $AppNames) {
        $info = Get-AppInfo -AppName $app
        if ($info.path) {
            foreach ($p in ($info.path -split ";")) {
                if ((Test-Path $p) -and ([Environment]::GetEnvironmentVariable("Path","Machine") -split ";" -notcontains $p)) {
                    [Environment]::SetEnvironmentVariable("Path", "$([Environment]::GetEnvironmentVariable('Path','Machine'));$p", "Machine")
                    $env:PATH += ";$p"
                }
            }
        }
    }
}