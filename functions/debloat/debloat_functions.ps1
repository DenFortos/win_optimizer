# functions/debloat/debloat_functions.ps1
# Удаление выбранных UWP-приложений в фоновом Runspace

# Запускает асинхронное удаление выбранных UWP-приложений
function Apply-Debloat {
    param([string[]]$SelectedTags)
    
    if (-not $SelectedTags -or $SelectedTags.Count -eq 0) { return }
    
    $resultHash = @{ Success = 0; Failed = 0; Errors = @() }
    
    $scriptBlock = {
        param($selectedTags, $debloatCatalog, $hostObj, $result)
        
        try { $hostObj.UI.RawUI.BackgroundColor = 'Black'; $hostObj.UI.RawUI.ForegroundColor = 'Gray' } catch {}
        try {
            [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
            [Console]::InputEncoding = [System.Text.Encoding]::UTF8
        } catch {}
        
        # Подавление прогресс-баров Remove-AppxPackage
        $ProgressPreference = 'SilentlyContinue'
        
        Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  УДАЛЕНИЕ UWP ($($selectedTags.Count) элементов)" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        
        $successCount = 0; $failedCount = 0; $errors = @()
        $currentUser = $env:USERNAME
        
        foreach ($tag in $selectedTags) {
            $parts = $tag -split '\|'
            if ($parts.Count -ne 2) { continue }
            $categoryKey = $parts[0]; $itemName = $parts[1]
            
            $itemInfo = $null
            if ($debloatCatalog.Contains($categoryKey)) {
                $itemInfo = $debloatCatalog[$categoryKey].Items | Where-Object { $_.Name -eq $itemName } | Select-Object -First 1
            }
            if (-not $itemInfo) {
                Write-Host "  ⚠️ Пропущено: $itemName (не найден в каталоге)" -ForegroundColor Yellow
                continue
            }
            
            Write-Host "  → Удаляем: $($itemInfo.Name) ($($itemInfo.PackageName))..." -ForegroundColor Cyan
            
            try {
                if ($itemInfo.Type -eq "UWP") {
                    # Удаление регистрации пакета у текущего пользователя
                    $packages = Get-AppxPackage -Name $itemInfo.PackageName -ErrorAction SilentlyContinue
                    if ($packages) {
                        $packages | Remove-AppxPackage -ErrorAction SilentlyContinue
                        Write-Host "    ✅ Удалено для пользователя $currentUser`: $($itemInfo.Name)" -ForegroundColor Green
                        $successCount++
                    } else {
                        Write-Host "    ⚪ Не найдено у пользователя: $($itemInfo.Name)" -ForegroundColor Gray
                    }
                    
                    # Удаление пакета из образа Windows (не вернётся новым пользователям)
                    try {
                        $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | 
                                       Where-Object { $_.PackageName -like "*$($itemInfo.PackageName)*" }
                        if ($provisioned) {
                            $provisioned | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
                            Write-Host "    ✅ Удалено из образа Windows" -ForegroundColor Green
                        }
                    } catch { }
                } else {
                    Write-Host "    ⚠️ Win32 удаление не поддерживается" -ForegroundColor Yellow
                    $failedCount++; $errors += "$($itemInfo.Name): Win32 тип не реализован"
                }
            } catch {
                Write-Host "    ❌ Ошибка удаления: $_" -ForegroundColor Red
                $failedCount++; $errors += "$($itemInfo.Name): $($_.Exception.Message)"
            }
        }
        
        # Итоговый отчёт
        Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  РЕЗУЛЬТАТ УДАЛЕНИЯ UWP" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  ✅ Успешно удалено: $successCount" -ForegroundColor Green
        if ($failedCount -gt 0) {
            Write-Host "  ❌ Ошибок: $failedCount" -ForegroundColor Red
            foreach ($err in $errors) { Write-Host "    • $err" -ForegroundColor Yellow }
        }
        Write-Host "`n  💡 Удалённые приложения можно вернуть из Microsoft Store" -ForegroundColor Cyan
        Write-Host "  💡 Рекомендуется перезагрузить ПК" -ForegroundColor Cyan
        
        $result.Success = $successCount; $result.Failed = $failedCount
    }
    
    # Запуск в Runspace без блокировки UI
    $runspace = [runspacefactory]::CreateRunspace($Host)
    $runspace.Open()
    $ps = [powershell]::Create().AddScript($scriptBlock).AddArgument($SelectedTags).AddArgument($script:DebloatCatalog).AddArgument($Host).AddArgument($resultHash)
    $ps.Runspace = $runspace
    $script:TweaksJob = @{
        PowerShell = $ps
        AsyncResult = $ps.BeginInvoke()
        Runspace = $runspace
        ResultHash = $resultHash
    }
}