# functions/optimization/optimization_helpers.ps1
# UI-обёртки вкладки Optimization: построение панели и получение выбора

# Строит панель категорий оптимизаций через Build-GenericPanel
function Build-OptimizationPanel {
    param([object]$Window)
    
    if (-not $script:OptimizationItemHeaders) { $script:OptimizationItemHeaders = @{} }
    if (-not $script:SelectAllHeaders) { $script:SelectAllHeaders = @{} }
    
    Build-GenericPanel -PanelName "OptimizationCategoriesPanel" `
                       -Catalog $script:OptimizationCatalog `
                       -UpdateCountFunction { Update-OptimizationCount } `
                       -HeadersStorage $script:OptimizationItemHeaders `
                       -SelectAllStorage $script:SelectAllHeaders `
                       -TagFormat "simple"
    
    $script:OptimizationCachedCheckBoxes = $null
}

# Возвращает список выбранных оптимизаций
function Get-SelectedOptimizations {
    param([object]$Window)
    return Get-SelectedItems -PanelName "OptimizationCategoriesPanel"
}

# Сбрасывает все чекбоксы вкладки Optimization
function Clear-OptimizationsSelections {
    param([object]$Window)
    Clear-Selections -PanelName "OptimizationCategoriesPanel"
}

# Обновляет счётчик выбранных оптимизаций в кнопке «Сбросить выбор»
function Update-OptimizationCount {
    Update-ItemCount -CounterName "BtnClearOptimization" -PanelName "OptimizationCategoriesPanel" -TranslationKey "btn_clear_count"
}

# Блокирует/разблокирует весь UI на время применения оптимизаций
function Set-OptimizationUILocked {
    param([bool]$Locked)
    Set-GlobalUILocked -Locked $Locked
}

# Показывает модальное окно с результатом применения оптимизаций
function Show-OptimizationResult {
    param([int]$SuccessCount = 0, [int]$FailedCount = 0)
    if (-not $script:MainWindow) { return }
    
    $title = Get-LocalizedString "app_title" -Fallback "Windows Optimizer"
    $console = Get-LocalizedString "see_console" -Fallback "Details in PowerShell console"
    
    if ($FailedCount -eq 0 -and $SuccessCount -gt 0) {
        $msg = "✅ Успешно применено: $SuccessCount`n`n$console"
        $icon = "Information"
    } elseif ($SuccessCount -gt 0 -and $FailedCount -gt 0) {
        $msg = "⚠️ Применено с ошибками:`n✅ Успешно: $SuccessCount`n❌ Ошибок: $FailedCount`n`n$console"
        $icon = "Warning"
    } else {
        $msg = "❌ Не удалось применить оптимизации`n`n$console"
        $icon = "Error"
    }
    
    try { [System.Windows.MessageBox]::Show($msg, $title, "OK", $icon) | Out-Null }
    catch { Write-Log "Failed to show Optimization MessageBox: $_" "WARNING" }
}