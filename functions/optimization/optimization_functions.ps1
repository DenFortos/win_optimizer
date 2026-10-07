# functions/optimization/optimization_functions.ps1
# Твики Windows с проверкой текущего состояния (используются в optimization_catalog.ps1)

# Проверяет, равно ли значение в реестре ожидаемому
function Test-RegistryValue {
    param([string]$Path, [string]$Name, $ExpectedValue)
    try {
        if (-not (Test-Path $Path)) { return $false }
        $current = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
        if ($null -eq $current) { return $false }
        
        # Числовое сравнение с нормализацией под DWORD (0xffffffff хранится как -1)
        $curNum = 0L; $expNum = 0L
        if ([long]::TryParse([string]$current, [ref]$curNum) -and 
            [long]::TryParse([string]$ExpectedValue, [ref]$expNum)) {
            return (($curNum -band 0xFFFFFFFF) -eq ($expNum -band 0xFFFFFFFF))
        }
        return ([string]$current -eq [string]$ExpectedValue)
    } catch { return $false }
}

# Проверяет, остановлена ли и отключена ли служба
function Test-ServiceDisabled {
    param([string]$ServiceName)
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if (-not $service) { return $true }
        return ($service.Status -eq 'Stopped' -and $service.StartType -eq 'Disabled')
    } catch { return $true }
}

# Отключает фоновую запись Xbox Game Bar
function Disable-GameDVR {
    if (Test-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0) {
        Write-Host "    ⚪ Уже отключено" -ForegroundColor Gray
        return
    }
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Force
    $gameDvrPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
    if (-not (Test-Path $gameDvrPath)) { New-Item -Path $gameDvrPath -Force | Out-Null }
    Set-ItemProperty -Path $gameDvrPath -Name "AllowGameDVR" -Value 0 -Force
}

# Отключает оптимизацию полноэкранного режима Windows
function Disable-FullscreenOptimizations {
    $path = "HKCU:\System\GameConfigStore"
    if (Test-RegistryValue $path "GameDVR_FSEBehaviorMode" 2) {
        Write-Host "    ⚪ Уже отключено" -ForegroundColor Gray
        return
    }
    Set-ItemProperty -Path $path -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
    Set-ItemProperty -Path $path -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Force
    Set-ItemProperty -Path $path -Name "GameDVR_FSEBehavior" -Value 2 -Force
    Set-ItemProperty -Path $path -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Force
}

# Отключает сетевой троттлинг для снижения пинга
function Disable-NetworkThrottling {
    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    if (Test-RegistryValue $path "NetworkThrottlingIndex" 0xffffffff) {
        Write-Host "    ⚪ Уже отключено" -ForegroundColor Gray
        return
    }
    Set-ItemProperty -Path $path -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
    Set-ItemProperty -Path $path -Name "SystemResponsiveness" -Value 0 -Force
}

# Отключает акселерацию мыши (Raw Input)
function Disable-MouseAcceleration {
    $path = "HKCU:\Control Panel\Mouse"
    if (Test-RegistryValue $path "MouseSpeed" "0") {
        Write-Host "    ⚪ Уже отключено" -ForegroundColor Gray
        return
    }
    Set-ItemProperty -Path $path -Name "MouseSpeed" -Value "0" -Force
    Set-ItemProperty -Path $path -Name "MouseThreshold1" -Value "0" -Force
    Set-ItemProperty -Path $path -Name "MouseThreshold2" -Value "0" -Force
}

# Отключает телеметрию (службы DiagTrack/dmwappushservice и политика AllowTelemetry)
function Disable-Telemetry {
    $allDisabled = $true
    
    $diagService = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
    if ($diagService -and ($diagService.Status -ne 'Stopped' -or $diagService.StartType -ne 'Disabled')) {
        $allDisabled = $false
    }
    
    $dmwService = Get-Service -Name "dmwappushservice" -ErrorAction SilentlyContinue
    if ($dmwService -and ($dmwService.Status -ne 'Stopped' -or $dmwService.StartType -ne 'Disabled')) {
        $allDisabled = $false
    }
    
    $telemetryPolicy = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
    if (-not $telemetryPolicy -or $telemetryPolicy.AllowTelemetry -ne 0) {
        $allDisabled = $false
    }
    
    if ($allDisabled) {
        Write-Host "    ⚪ Уже отключено" -ForegroundColor Gray
        return
    }
    
    Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    
    Stop-Service "dmwappushservice" -Force -ErrorAction SilentlyContinue
    Set-Service "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
    
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
    
    Write-Host "    ✅ Телеметрия отключена (DiagTrack + dmwappushservice)" -ForegroundColor Green
}

# Отключает рекламный идентификатор Windows
function Disable-AdvertisingID {
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    
    $adEnabled = Get-ItemProperty -Path $path -Name "Enabled" -ErrorAction SilentlyContinue
    $adPolicy = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -ErrorAction SilentlyContinue
    
    if ($adEnabled -and $adEnabled.Enabled -eq 0 -and $adPolicy -and $adPolicy.DisabledByGroupPolicy -eq 1) {
        Write-Host "    ⚪ Уже отключено" -ForegroundColor Gray
        return
    }
    
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name "Enabled" -Value 0 -Type DWord -Force
    
    $policyPath = "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
    reg add $policyPath /v DisabledByGroupPolicy /t REG_DWORD /d 1 /f | Out-Null
    
    $check = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -ErrorAction SilentlyContinue
    if ($check -and $check.DisabledByGroupPolicy -eq 1) {
        Write-Host "    ✅ Рекламный ID отключён (Enabled=0 + GroupPolicy=1)" -ForegroundColor Green
    } else {
        $fallbackPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
        if (-not (Test-Path $fallbackPath)) { New-Item -Path $fallbackPath -Force | Out-Null }
        New-ItemProperty -Path $fallbackPath -Name "DisabledByGroupPolicy" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Host "    ✅ Рекламный ID отключён (Enabled=0 + GroupPolicy=1)" -ForegroundColor Green
    }
}

# Отключает веб-поиск в меню Пуск
function Disable-WebSearchStartMenu {
    $allDisabled = $true
    
    $path1 = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    if (-not (Test-RegistryValue $path1 "DisableSearchBoxSuggestions" 1)) {
        $allDisabled = $false
    }
    
    $path2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    $searchPolicy = Get-ItemProperty -Path $path2 -Name "ConnectedSearchUseWeb" -ErrorAction SilentlyContinue
    if (-not $searchPolicy -or $searchPolicy.ConnectedSearchUseWeb -ne 0) {
        $allDisabled = $false
    }
    
    if ($allDisabled) {
        Write-Host "    ⚪ Уже отключено" -ForegroundColor Gray
        return
    }
    
    if (-not (Test-Path $path1)) { New-Item -Path $path1 -Force | Out-Null }
    Set-ItemProperty -Path $path1 -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force
    
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowSearchToUseLocation /t REG_DWORD /d 0 /f | Out-Null
    
    Write-Host "    ✅ Веб-поиск в Пуске отключён" -ForegroundColor Green
}

# Глубокая очистка хранилища компонентов Windows (WinSxS) через DISM
function Invoke-DismCleanup {
    Write-Host "    ⏳ Очистка WinSxS, может занять 5-15 минут..." -ForegroundColor Yellow
    
    try {
        $output = Dism /Online /Cleanup-Image /StartComponentCleanup /Quiet 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    ✅ Очистка WinSxS завершена" -ForegroundColor Green
        } else {
            Write-Host "    ⚪ DISM: код $LASTEXITCODE (возможно, уже очищено)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "    ❌ Ошибка DISM: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Скрывает «Главная» из боковой панели проводника
function Hide-Home {
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum"
    $clsid = "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
    
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    
    $currentValue = Get-ItemProperty -Path $path -Name $clsid -ErrorAction SilentlyContinue
    if ($currentValue -and $currentValue.$clsid -eq 1) {
        Write-Host "    ⚪ Уже скрыто" -ForegroundColor Gray
        return
    }
    
    Set-ItemProperty -Path $path -Name $clsid -Value 1 -Type DWord -Force
}

# Скрывает «Галерея» из боковой панели проводника
function Hide-Gallery {
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum"
    $clsid = "{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    
    $currentValue = Get-ItemProperty -Path $path -Name $clsid -ErrorAction SilentlyContinue
    if ($currentValue -and $currentValue.$clsid -eq 1) {
        Write-Host "    ⚪ Уже скрыто" -ForegroundColor Gray
        return
    }
    
    Set-ItemProperty -Path $path -Name $clsid -Value 1 -Type DWord -Force
}

# Скрывает OneDrive из боковой панели проводника
function Hide-OneDrive {
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum"
    $clsid = "{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    
    $currentValue = Get-ItemProperty -Path $path -Name $clsid -ErrorAction SilentlyContinue
    if ($currentValue -and $currentValue.$clsid -eq 1) {
        Write-Host "    ⚪ Уже скрыто" -ForegroundColor Gray
        return
    }
    
    Set-ItemProperty -Path $path -Name $clsid -Value 1 -Type DWord -Force
}

# Скрывает «Сеть» из боковой панели проводника
function Hide-Network {
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum"
    $clsid = "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}"
    
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    
    $currentValue = Get-ItemProperty -Path $path -Name $clsid -ErrorAction SilentlyContinue
    if ($currentValue -and $currentValue.$clsid -eq 1) {
        Write-Host "    ⚪ Уже скрыто" -ForegroundColor Gray
        return
    }
    
    Set-ItemProperty -Path $path -Name $clsid -Value 1 -Type DWord -Force
}

# Скрывает съёмные диски из боковой панели проводника
function Hide-RemovableDrives {
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum"
    $clsid = "{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}"
    
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    
    $currentValue = Get-ItemProperty -Path $path -Name $clsid -ErrorAction SilentlyContinue
    if ($currentValue -and $currentValue.$clsid -eq 1) {
        Write-Host "    ⚪ Уже скрыто" -ForegroundColor Gray
        return
    }
    
    Set-ItemProperty -Path $path -Name $clsid -Value 1 -Type DWord -Force
}

# Перезапускает проводник для применения изменений реестра
function Restart-Explorer {
    Write-Host "  🔄 Перезапуск проводника..." -ForegroundColor Cyan
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
        Start-Process explorer.exe
    }
}

# Включает игровой режим Windows
function Enable-GameMode {
    $path = "HKCU:\SOFTWARE\Microsoft\GameBar"
    
    $allowAuto = Get-ItemProperty -Path $path -Name "AllowAutoGameMode" -ErrorAction SilentlyContinue
    $autoEnabled = Get-ItemProperty -Path $path -Name "AutoGameModeEnabled" -ErrorAction SilentlyContinue
    
    if ($allowAuto -and $allowAuto.AllowAutoGameMode -eq 1 -and 
        $autoEnabled -and $autoEnabled.AutoGameModeEnabled -eq 1) {
        Write-Host "    ⚪ Уже включено" -ForegroundColor Gray
        return
    }
    
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force
    
    Write-Host "    ✅ Игровой режим включён (+5-10% FPS)" -ForegroundColor Green
}

# Включает аппаратное планирование GPU (HAGS)
function Enable-HAGS {
    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    
    if (Test-RegistryValue $path "HwSchMode" 2) {
        Write-Host "    ⚪ Уже включено" -ForegroundColor Gray
        return
    }
    
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f | Out-Null
    
    Write-Host "    ✅ HAGS включён (+5-15% FPS, требуется перезагрузка)" -ForegroundColor Green
}

# Активирует схему питания «Высокая производительность»
function Enable-HighPerformancePower {
    try {
        $highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        
        $activePlan = powercfg /getactivescheme
        if ($activePlan -match $highPerfGuid) {
            Write-Host "    ⚪ Уже активировано" -ForegroundColor Gray
            return
        }
        
        powercfg /setactive $highPerfGuid | Out-Null
        
        if ((powercfg /getactivescheme) -match $highPerfGuid) {
            Write-Host "    ✅ Схема 'Высокая производительность' активирована" -ForegroundColor Green
        } else {
            Write-Host "    ⚠️ Схема недоступна на этой системе (Modern Standby / ноутбук)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    ❌ Не удалось активировать схему: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Отключает изоляцию ядра (Memory Integrity / HVCI)
function Disable-CoreIsolation {
    Write-Host "    ⚠️ ВНИМАНИЕ: снижает защиту от атак на уровне ядра" -ForegroundColor Yellow
    
    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
    
    if (Test-RegistryValue $path "Enabled" 0) {
        Write-Host "    ⚪ Уже отключено" -ForegroundColor Gray
        return
    }
    
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name "Enabled" -Value 0 -Type DWord -Force
    
    Write-Host "    ✅ Core Isolation отключён (+10-20% FPS, требуется перезагрузка)" -ForegroundColor Green
}