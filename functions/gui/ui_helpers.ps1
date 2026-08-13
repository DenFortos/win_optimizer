# functions/gui/ui_helpers.ps1
# Общие вспомогательные функции для UI

# Рекурсивно находит все CheckBox в дереве элементов WPF
function Find-CheckBoxes {
    param([System.Windows.DependencyObject]$Parent)
    $result = @()
    if (-not $Parent) { return $result }
    
    for ($i = 0; $i -lt [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Parent); $i++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Parent, $i)
        if ($child -is [System.Windows.Controls.CheckBox]) { $result += $child }
        $result += Find-CheckBoxes -Parent $child
    }
    return $result
}

# Рекурсивно находит все элементы заданного типа в дереве WPF
function Find-ChildrenOfType {
    param([System.Windows.DependencyObject]$Parent, [string]$TypeName)
    $result = @()
    if (-not $Parent) { return $result }
    
    for ($i = 0; $i -lt [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Parent); $i++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Parent, $i)
        if ($child.GetType().Name -eq $TypeName) { $result += $child }
        $result += Find-ChildrenOfType -Parent $child -TypeName $TypeName
    }
    return $result
}

# Блокирует/разблокирует весь интерфейс на время выполнения операций
function Set-GlobalUILocked {
    param([bool]$Locked)
    
    if (-not $script:MainWindow) { return }
    
    try {
        # Блокировка вкладок (TabControl не трогаем, чтобы работал ScrollBar)
        $tabControl = $script:MainWindow.FindName("MainTabControl")
        if ($tabControl) {
            $tabItems = Find-ChildrenOfType -Parent $tabControl -TypeName "TabItem"
            foreach ($tab in $tabItems) {
                $tab.IsEnabled = -not $Locked
            }
        }
        
        # Блокировка всех кнопок действий
        foreach ($btnName in @("BtnInstall", "BtnOpenAppwiz", "BtnClearSelection", "BtnApplyTweaks", "BtnClearTweaks", "BtnApplyOptimization", "BtnOpenCleanMgr", "BtnClearOptimization")) {
            $btn = $script:MainWindow.FindName($btnName)
            if ($btn) { $btn.IsEnabled = -not $Locked }
        }
        
        # Блокировка всех чекбоксов
        foreach ($panelName in @("CategoriesPanel", "TweaksCategoriesPanel", "OptimizationCategoriesPanel")) {
            $panel = $script:MainWindow.FindName($panelName)
            if ($panel) {
                foreach ($cb in Find-CheckBoxes $panel) {
                    $cb.IsEnabled = -not $Locked
                }
            }
        }
    }
    catch {
        Write-Log "Failed to set global UI lock: $_" "WARNING"
    }
}

# Показывает модальное окно с результатом установки программ
function Show-InstallResult {
    param([bool]$Success, [int]$ExitCode = 0)
    if (-not $script:MainWindow) { return }
    
    $title = Get-LocalizedString "app_title" -Fallback "Windows Optimizer"
    $console = Get-LocalizedString "see_console" -Fallback "Details in PowerShell console"
    
    if ($Success) {
        $msg = (Get-LocalizedString "install_success" -Fallback "Installation successful") + "`n`n$console"
        $icon = "Information"
    } else {
        $msg = (Get-LocalizedString "install_error" -Fallback "Installation failed") + " (exit: $ExitCode)`n`n$console"
        $icon = "Warning"
    }
    
    try { [System.Windows.MessageBox]::Show($msg, $title, "OK", $icon) | Out-Null }
    catch { Write-Log "Failed to show MessageBox: $_" "WARNING" }
}

# Обновляет счётчик выбранных программ в кнопке «Сбросить выбор» (вкладка Install)
function Update-SelectedCount {
    Update-ItemCount -CounterName "BtnClearSelection" -PanelName "CategoriesPanel" -TranslationKey "btn_clear_count"
}