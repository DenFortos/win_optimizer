# functions/gui/search.ps1
# Поиск и подсветка совпадений во вкладках

# Создаёт TextBlock с подсветкой совпадений оранжевым цветом
function New-HighlightedTextBlock {
    param([string]$Text, [string]$Search)
    
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.FontSize = 13
    $tb.Foreground = $script:MainWindow.FindResource("TextFG")
    
    if ([string]::IsNullOrEmpty($Search)) {
        $tb.Inlines.Add((New-Object System.Windows.Documents.Run($Text))) | Out-Null
        return $tb
    }
    
    $regex = New-Object System.Text.RegularExpressions.Regex([regex]::Escape($Search), 'IgnoreCase')
    $lastIndex = 0
    
    foreach ($match in $regex.Matches($Text)) {
        if ($match.Index -gt $lastIndex) {
            $tb.Inlines.Add((New-Object System.Windows.Documents.Run($Text.Substring($lastIndex, $match.Index - $lastIndex)))) | Out-Null
        }
        $run = New-Object System.Windows.Documents.Run($match.Value)
        $run.Foreground = [System.Windows.Media.Brushes]::OrangeRed
        $run.FontWeight = [System.Windows.FontWeights]::Bold
        $tb.Inlines.Add($run) | Out-Null
        $lastIndex = $match.Index + $match.Length
    }
    
    if ($lastIndex -lt $Text.Length) {
        $tb.Inlines.Add((New-Object System.Windows.Documents.Run($Text.Substring($lastIndex)))) | Out-Null
    }
    return $tb
}

# Извлекает имя элемента из Tag (форматы "simple" и "category|name")
function Get-ItemNameFromTag {
    param([object]$Tag, [object]$Content)
    $name = [string]$Tag
    if ($name -like "*|*") { $name = ($name -split '\|')[1] }
    if ([string]::IsNullOrEmpty($name)) { $name = $Content -as [string] }
    return $name
}

# Возвращает оригинальное (переведённое) имя чекбокса
function Get-OriginalItemName {
    param([object]$CheckBox)
    
    # Для оптимизаций перевод восстанавливается через TranslationKey
    if ($script:OptimizationCheckBoxes -and $CheckBox.Tag) {
        $info = $script:OptimizationCheckBoxes[$CheckBox.Tag]
        if ($info -and $info.TranslationKey) {
            return Get-LocalizedString $info.TranslationKey -Fallback $info.Fallback
        }
    }
    
    return Get-ItemNameFromTag -Tag $CheckBox.Tag -Content $CheckBox.Content
}

# Подсвечивает совпадения поиска, не скрывая остальные элементы
function Update-SearchFilter {
    param([string]$SearchText)
    
    if (-not $script:MainWindow) { return }
    
    $tabControl = $script:MainWindow.FindName("MainTabControl")
    if (-not $tabControl) { return }
    
    $panelName = switch ($tabControl.SelectedItem.Name) {
        "InstallTab"       { "CategoriesPanel" }
        "TweaksTab"        { "TweaksCategoriesPanel" }
        "OptimizationTab"  { "OptimizationCategoriesPanel" }
        default { return }
    }
    
    $panel = $script:MainWindow.FindName($panelName)
    if (-not $panel) { return }
    
    foreach ($wrapPanel in (Find-ChildrenOfType $panel "WrapPanel")) {
        foreach ($cb in $wrapPanel.Children) {
            if ($cb -isnot [System.Windows.Controls.CheckBox]) { continue }
            if ($cb.Tag -is [System.Collections.IList]) { continue }
            
            $name = Get-OriginalItemName -CheckBox $cb
            
            if ([string]::IsNullOrEmpty($SearchText)) {
                $cb.Content = $name
            }
            elseif ($name -like "*$SearchText*") {
                $cb.Content = New-HighlightedTextBlock -Text $name -Search $SearchText
            }
            else {
                $cb.Content = $name
            }
            
            $cb.Visibility = "Visible"
        }
        
        # Контейнер категории всегда видим
        $parent = $wrapPanel.Parent
        while ($parent -and $parent -isnot [System.Windows.Controls.Border] -and $parent -ne $panel) {
            $parent = $parent.Parent
        }
        if ($parent -and $parent -ne $panel) {
            $parent.Visibility = "Visible"
        }
    }
}

# Сбрасывает подсветку поиска для всех вкладок
function Reset-AllFilters {
    if (-not $script:MainWindow) { return }
    
    foreach ($panelName in @("CategoriesPanel", "TweaksCategoriesPanel", "OptimizationCategoriesPanel")) {
        $panel = $script:MainWindow.FindName($panelName)
        if (-not $panel) { continue }
        
        foreach ($wrapPanel in (Find-ChildrenOfType $panel "WrapPanel")) {
            foreach ($cb in $wrapPanel.Children) {
                if ($cb -isnot [System.Windows.Controls.CheckBox]) { continue }
                if ($cb.Tag -is [System.Collections.IList]) { continue }
                
                $name = Get-OriginalItemName -CheckBox $cb
                if (-not [string]::IsNullOrEmpty($name)) { $cb.Content = $name }
                
                $cb.Visibility = "Visible"
            }
            
            $parent = $wrapPanel.Parent
            while ($parent -and $parent -isnot [System.Windows.Controls.Border] -and $parent -ne $panel) {
                $parent = $parent.Parent
            }
            if ($parent -and $parent -ne $panel) {
                $parent.Visibility = "Visible"
            }
        }
    }
}

# Обрабатывает переключение вкладок: сбрасывает поиск и лениво строит пустые панели
function Handle-TabSelectionChanged {
    param($sender, $eventArgs)
    if ($script:IsInitializing) { return }
    
    # Очистка поля поиска и сброс подсветки
    $sb = $script:MainWindow.FindName("SearchBox")
    if ($sb -and $sb.Text -ne "") { $sb.Text = "" }
    Reset-AllFilters
    
    # Ленивое построение панели по конвенции Build-{TabName}Panel
    $selectedTab = $sender.SelectedItem
    $panel = $script:MainWindow.FindName("$($selectedTab.Name -replace 'Tab$','')CategoriesPanel")
    if (-not $panel) {
        if ($selectedTab.Name -eq "InstallTab") {
            $panel = $script:MainWindow.FindName("CategoriesPanel")
        }
    }
    
    if ($panel -and $panel.Children.Count -eq 0) {
        $tabBaseName = $selectedTab.Name -replace 'Tab$', ''
        $buildFunc = "Build-${tabBaseName}Panel"
        if (Get-Command -Name $buildFunc -ErrorAction SilentlyContinue) {
            & $buildFunc -Window $script:MainWindow
        }
    }
}

# Подключает обработчики поиска и переключения вкладок
function Initialize-SearchHandlers {
    param([object]$Window)
    
    $searchBox = $Window.FindName("SearchBox")
    $tabControl = $Window.FindName("MainTabControl")
    
    if ($tabControl) {
        $tabControl.Add_SelectionChanged({ Handle-TabSelectionChanged -sender $this -eventArgs $args })
    }
    
    if ($searchBox) {
        $panel = $Window.FindName("CategoriesPanel")
        if ($panel) {
            foreach ($cb in Find-CheckBoxes $panel) {
                if ([string]::IsNullOrEmpty($cb.Tag)) { $cb.Tag = $cb.Content }
            }
        }
        $searchBox.Add_TextChanged({ Update-SearchFilter -SearchText $this.Text.Trim() })
    }
}