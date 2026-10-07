# functions/optimization/apply_optimizations.ps1
# Применение выбранных оптимизаций в фоновом Runspace

# Запускает асинхронное применение выбранных твиков
function Apply-Optimizations {
    param([string[]]$SelectedFunctions)
    
    if (-not $SelectedFunctions -or $SelectedFunctions.Count -eq 0) { return }
    
    $resultHash = @{ Success = 0; Failed = 0; Errors = @() }
    
    # Сбор определений функций твиков для передачи в Runspace
    $functionDefs = @()
    foreach ($funcName in @("Test-RegistryValue", "Test-ServiceDisabled",
        "Disable-GameDVR", "Disable-FullscreenOptimizations",
        "Disable-NetworkThrottling", "Disable-MouseAcceleration",
        "Enable-GameMode", "Enable-HAGS", "Enable-HighPerformancePower", "Disable-CoreIsolation",
        "Disable-Telemetry", "Disable-AdvertisingID",
        "Disable-WebSearchStartMenu",
        "Invoke-DismCleanup",
        "Hide-Home", "Hide-Gallery", "Hide-OneDrive", "Hide-Network", "Hide-RemovableDrives",
        "Restart-Explorer")) {
        $cmd = Get-Command -Name $funcName -CommandType Function -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Definition) {
            $functionDefs += "function $funcName { $($cmd.Definition) }"
        }
    }
    $allDefs = $functionDefs -join "`n"
    
    $scriptBlockText = @"
param(`$selectedFunctions, `$optimizationCatalog, `$hostObj, `$result)

$allDefs

try { `$hostObj.UI.RawUI.BackgroundColor = 'Black'; `$hostObj.UI.RawUI.ForegroundColor = 'Gray' } catch {}
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
} catch {}

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ПРИМЕНЕНИЕ ОПТИМИЗАЦИЙ (`$(`$selectedFunctions.Count))" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

`$successCount = 0; `$failedCount = 0; `$errors = @()

`$allItems = @()
foreach (`$catKey in `$optimizationCatalog.Keys) {
    `$allItems += `$optimizationCatalog[`$catKey].Items
}

foreach (`$funcName in `$selectedFunctions) {
    `$itemInfo = `$allItems | Where-Object { `$_.FunctionName -eq `$funcName } | Select-Object -First 1
    if (-not `$itemInfo) {
        Write-Host "  ⚠️ Функция не найдена: `$funcName" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "  → `$(`$itemInfo.Name)" -ForegroundColor Cyan
    
    try {
        & `$funcName
        Write-Host "    ✅ Успешно: `$(`$itemInfo.Name)" -ForegroundColor Green
        `$successCount++
    } catch {
        Write-Host "    ❌ Ошибка: `$(`$_.Exception.Message)" -ForegroundColor Red
        `$failedCount++
        `$errors += "`$(`$itemInfo.Name): `$(`$_.Exception.Message)"
    }
}

# Перезапуск проводника, если применялись твики проводника
`$explorerTweaks = @("Hide-Home", "Hide-Gallery", "Hide-OneDrive", "Hide-Network", "Hide-RemovableDrives")
`$appliedExplorerTweaks = `$selectedFunctions | Where-Object { `$explorerTweaks -contains `$_ }
if (`$appliedExplorerTweaks.Count -gt 0) {
    Restart-Explorer
}

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  РЕЗУЛЬТАТ ОПТИМИЗАЦИИ" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ Успешно применено: `$successCount" -ForegroundColor Green
if (`$failedCount -gt 0) {
    Write-Host "  ❌ Ошибок: `$failedCount" -ForegroundColor Red
    foreach (`$err in `$errors) { Write-Host "    • `$err" -ForegroundColor Yellow }
}
Write-Host "`n  💡 Некоторые твики требуют перезагрузки ПК" -ForegroundColor Cyan

`$result.Success = `$successCount; `$result.Failed = `$failedCount
"@
    
    $scriptBlock = [scriptblock]::Create($scriptBlockText)
    
    $runspace = [runspacefactory]::CreateRunspace($Host)
    $runspace.Open()
    $ps = [powershell]::Create().AddScript($scriptBlock).AddArgument($SelectedFunctions).AddArgument($script:OptimizationCatalog).AddArgument($Host).AddArgument($resultHash)
    $ps.Runspace = $runspace
    $script:OptimizationJob = @{
        PowerShell = $ps
        AsyncResult = $ps.BeginInvoke()
        Runspace = $runspace
        ResultHash = $resultHash
    }
}