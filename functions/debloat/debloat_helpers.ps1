# functions/debloat/debloat_helpers.ps1
# UI-обёртки вкладки Debloat: построение панели и получение выбора

# Строит панель категорий UWP-приложений через Build-GenericPanel
function Build-TweaksPanel {
    param([object]$Window)
    
    if (-not $script:TweakItemHeaders) { $script:TweakItemHeaders = @{} }
    if (-not $script:SelectAllHeaders) { $script:SelectAllHeaders = @{} }
    
    Build-GenericPanel -PanelName "TweaksCategoriesPanel" `
                       -Catalog $script:DebloatCatalog `
                       -UpdateCountFunction { Update-TweaksCount } `
                       -HeadersStorage $script:TweakItemHeaders `
                       -SelectAllStorage $script:SelectAllHeaders `
                       -TagFormat "category|name"
    
    $script:TweaksCachedCheckBoxes = $null
}

# Возвращает список выбранных UWP-приложений
function Get-SelectedTweaks {
    param([object]$Window)
    $items = Get-SelectedItems -PanelName "TweaksCategoriesPanel"
    return $items | ForEach-Object { @{ Name = ($_ -split '\|')[1]; Tag = $_ } }
}

# Сбрасывает все чекбоксы вкладки Debloat
function Clear-TweaksSelections {
    param([object]$Window)
    Clear-Selections -PanelName "TweaksCategoriesPanel"
}

# Обновляет счётчик выбранных приложений в кнопке «Сбросить выбор»
function Update-TweaksCount {
    Update-ItemCount -CounterName "BtnClearTweaks" -PanelName "TweaksCategoriesPanel" -TranslationKey "btn_clear_count"
}

# Блокирует/разблокирует весь UI на время удаления UWP
function Set-TweaksUILocked {
    param([bool]$Locked)
    Set-GlobalUILocked -Locked $Locked
}

# Показывает модальное окно с результатом удаления UWP
function Show-TweaksResult {
    param([int]$SuccessCount = 0, [int]$FailedCount = 0)
    if (-not $script:MainWindow) { return }
    
    $title = Get-LocalizedString "app_title" -Fallback "Windows Optimizer"
    $console = Get-LocalizedString "see_console" -Fallback "Details in PowerShell console"
    
    if ($FailedCount -eq 0 -and $SuccessCount -gt 0) {
        $msg = "✅ Успешно удалено: $SuccessCount`n`n$console"
        $icon = "Information"
    } elseif ($SuccessCount -gt 0 -and $FailedCount -gt 0) {
        $msg = "⚠️ Удалено с ошибками:`n✅ Успешно: $SuccessCount`n❌ Ошибок: $FailedCount`n`n$console"
        $icon = "Warning"
    } else {
        $msg = "❌ Не удалось удалить твики`n`n$console"
        $icon = "Error"
    }
    
    try { [System.Windows.MessageBox]::Show($msg, $title, "OK", $icon) | Out-Null }
    catch { Write-Log "Failed to show Tweaks MessageBox: $_" "WARNING" }
}