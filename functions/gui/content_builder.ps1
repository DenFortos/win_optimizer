# functions\gui\content_builder.ps1

# Построение UI-контента всех разделов (категории + чекбоксы)

# Хранилище чекбоксов оптимизаций для перевода
if (-not $script:OptimizationCheckBoxes) { $script:OptimizationCheckBoxes = @{} }

# Строит универсальную панель с категориями и чекбоксами из каталога
function Build-GenericPanel {
    param(
        [string]$PanelName,
        [hashtable]$Catalog,
        [scriptblock]$UpdateCountFunction,
        [hashtable]$HeadersStorage,
        [hashtable]$SelectAllStorage,
        [string]$TagFormat = "simple"
    )
    
    if (-not $script:MainWindow) { return }
    $panel = $script:MainWindow.FindName($PanelName)
    if (-not $panel) { return }
    
    $panel.Children.Clear()
    
    if ($PanelName -eq "OptimizationCategoriesPanel") {
        $script:OptimizationCheckBoxes = @{}
    }
    
    # Сортировка категорий по Order
    $sortedCatalog = $Catalog.Values | Where-Object { $_.Order -ne $null } | Sort-Object Order
    if (-not $sortedCatalog) { $sortedCatalog = $Catalog.Values }
    
    foreach ($cat in $sortedCatalog) {
        $catKey = ($Catalog.GetEnumerator() | Where-Object { $_.Value -eq $cat }).Key
        
        # Контейнер категории с рамкой
        $border = New-Object System.Windows.Controls.Border
        $border.Background = "Transparent"
        $border.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "TextFG")
        $border.BorderThickness = "2"
        $border.CornerRadius = "6"
        $border.Padding = "10"
        $border.Margin = "0,0,0,12"
        
        $stack = New-Object System.Windows.Controls.StackPanel
        
        # Заголовок категории и чекбокс «Выбрать всё»
        $headerGrid = New-Object System.Windows.Controls.Grid
        $headerGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" })) | Out-Null
        $headerGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" })) | Out-Null
        
        $title = New-Object System.Windows.Controls.TextBlock
        $title.Text = if ($cat.Icon) { "$($cat.Icon) $($cat.DisplayName)" } else { $cat.DisplayName }
        $title.FontSize = 14
        $title.FontWeight = "SemiBold"
        $title.VerticalAlignment = "Center"
        $title.FontFamily = "Segoe UI Emoji, Segoe UI"
        $title.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "TextFG")
        [System.Windows.Controls.Grid]::SetColumn($title, 0)
        $headerGrid.Children.Add($title) | Out-Null
        
        # Чекбоксы элементов категории
        $wrap = New-Object System.Windows.Controls.WrapPanel
        $categoryCheckBoxesList = [System.Collections.ArrayList]@()
        
        foreach ($item in $cat.Items) {
            $cb = New-Object System.Windows.Controls.CheckBox
            
            # Перевод имени элемента (только для Optimization)
            $itemName = $item.Name
            if ($PanelName -eq "OptimizationCategoriesPanel" -and $item.ContainsKey('TranslationKey')) {
                $itemName = Get-LocalizedString $item.TranslationKey -Fallback $item.Name
            }
            $cb.Content = $itemName
            
            # Сохранение чекбокса для перевода (только для Optimization)
            if ($PanelName -eq "OptimizationCategoriesPanel" -and $item.ContainsKey('TranslationKey')) {
                $script:OptimizationCheckBoxes[$item.FunctionName] = @{
                    CheckBox = $cb
                    TranslationKey = $item.TranslationKey
                    Fallback = $item.Name
                }
            }
            
            # Tag в зависимости от формата
            if ($TagFormat -eq "category|name") {
                $cb.Tag = "$catKey|$($item.Name)"
            } elseif ($item.ContainsKey('FunctionName')) {
                $cb.Tag = $item.FunctionName
            } else {
                $cb.Tag = $item.Name
            }
            
            $cb.Margin = "0,0,15,5"
            $cb.Cursor = "Hand"
            if ($item.ContainsKey('Description')) { $cb.ToolTip = $item.Description }
            $cb.SetResourceReference([System.Windows.Controls.CheckBox]::ForegroundProperty, "TextFG")
            
            # Пометка небезопасных элементов
            if ($item.ContainsKey('Safe') -and $item.Safe -eq $false) { 
                $cb.ToolTip = if ($cb.ToolTip) { "$($cb.ToolTip)`n⚠️ Применяйте с осторожностью" } else { "⚠️ Применяйте с осторожностью" }
            }
            
            $cb.Add_Checked($UpdateCountFunction)
            $cb.Add_Unchecked($UpdateCountFunction)
            $wrap.Children.Add($cb) | Out-Null
            [void]$categoryCheckBoxesList.Add($cb)
        }
        
        # Чекбокс «Выбрать всё»
        $selectAllCb = New-Object System.Windows.Controls.CheckBox
        $selectAllCb.Content = (Get-LocalizedString "select_all" -Fallback "Select All")
        $selectAllCb.VerticalAlignment = "Center"
        $selectAllCb.Cursor = "Hand"
        $selectAllCb.Tag = @{
            CheckBoxes = $categoryCheckBoxesList
            UpdateFunc = $UpdateCountFunction
        }
        $selectAllCb.SetResourceReference([System.Windows.Controls.CheckBox]::ForegroundProperty, "TextFG")
        [System.Windows.Controls.Grid]::SetColumn($selectAllCb, 1)
        
        # Синхронизация всех чекбоксов категории
        $selectAllCb.Add_Click({
            param($sender, $eventArgs)
            $isChecked = [bool]$sender.IsChecked
            $tagData = $sender.Tag
            if ($tagData -is [hashtable]) {
                $checkBoxes = $tagData.CheckBoxes
                $updateFunc = $tagData.UpdateFunc
                
                if ($checkBoxes -and $checkBoxes -is [System.Collections.IList]) {
                    foreach ($cb in $checkBoxes) {
                        if ($cb -and $cb.IsChecked -ne $isChecked) { $cb.IsChecked = $isChecked }
                    }
                }
                
                if ($updateFunc) { $updateFunc.Invoke() }
            }
        })
        
        $headerGrid.Children.Add($selectAllCb) | Out-Null
        $headerGrid.Margin = "0,0,0,8"
        $stack.Children.Add($headerGrid) | Out-Null
        $stack.Children.Add($wrap) | Out-Null
        
        # Сохранение заголовка для локализации
        if ($HeadersStorage -and $cat.ContainsKey('TranslationKey')) {
            $HeadersStorage[$cat.TranslationKey] = @{
                Control = $title
                Icon = $cat.Icon
                TranslationKey = $cat.TranslationKey
                DisplayName = $cat.DisplayName
            }
        } elseif ($HeadersStorage -and $catKey) {
            $HeadersStorage[$catKey] = @{
                Control = $title
                Icon = $cat.Icon
                TranslationKey = $cat.TranslationKey
            }
        }
        
        # Сохранение «Выбрать всё» для локализации
        if ($SelectAllStorage) {
            $SelectAllStorage["$PanelName`_$catKey"] = $selectAllCb
        }
        
        $border.Child = $stack
        $panel.Children.Add($border) | Out-Null
    }
}

# Возвращает список выбранных элементов панели (служебные чекбоксы исключаются)
function Get-SelectedItems {
    param([string]$PanelName)
    
    if (-not $script:MainWindow) { return @() }
    $panel = $script:MainWindow.FindName($PanelName)
    if (-not $panel) { return @() }
    
    $selected = @()
    foreach ($cb in Find-CheckBoxes $panel) {
        if ($cb.Tag -is [System.Collections.IList]) { continue }
        if ($cb.Tag -is [hashtable]) { continue }
        if ($cb.IsChecked) { $selected += $cb.Tag }
    }
    return $selected
}

# Сбрасывает все чекбоксы в указанной панели
function Clear-Selections {
    param([string]$PanelName)
    
    if (-not $script:MainWindow) { return }
    $panel = $script:MainWindow.FindName($PanelName)
    if (-not $panel) { return }
    
    foreach ($cb in Find-CheckBoxes $panel) {
        $cb.IsChecked = $false
    }
}

# Обновляет счётчик выбранных элементов в кнопке или TextBlock
function Update-ItemCount {
    param([string]$CounterName, [string]$PanelName, [string]$TranslationKey = "selected_count")
    
    if (-not $script:MainWindow) { return }
    try {
        $counter = $script:MainWindow.FindName($CounterName)
        if (-not $counter) { return }
        
        $count = 0
        foreach ($cb in Find-CheckBoxes ($script:MainWindow.FindName($PanelName))) {
            if ($cb.Tag -isnot [System.Collections.IList] -and $cb.Tag -isnot [hashtable] -and $cb.IsChecked) { $count++ }
        }
        
        $text = (Get-LocalizedString $TranslationKey -Fallback "Selected: {count}") -replace '\{count\}', $count
        Set-ElementText -Element $counter -Text $text
    }
    catch { Write-Log "Failed to update $CounterName`: $_" "WARNING" }
}

# Блокирует/разблокирует кнопки и чекбоксы указанной панели
function Set-UILockedGeneric {
    param([string]$PanelName, [string[]]$ButtonNames, [bool]$Locked)
    
    if (-not $script:MainWindow) { return }
    try {
        foreach ($btnName in $ButtonNames) {
            $btn = $script:MainWindow.FindName($btnName)
            if ($btn) { $btn.IsEnabled = -not $Locked }
        }
        
        $panel = $script:MainWindow.FindName($PanelName)
        if ($panel) {
            foreach ($cb in Find-CheckBoxes $panel) { $cb.IsEnabled = -not $Locked }
        }
    }
    catch { Write-Log "Failed to set UI lock: $_" "WARNING" }
}