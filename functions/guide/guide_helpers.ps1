# functions/guide/guide_helpers.ps1
# UI-обёртки вкладки Guide: построение панели с описаниями

# Возвращает локализованную строку из словаря @{ en = "..."; ru = "..." }
function Get-GuideLocalizedText {
    param([object]$TextObj)
    
    if ($TextObj -is [hashtable] -and ($TextObj.ContainsKey('en') -or $TextObj.ContainsKey('ru'))) {
        $locale = $script:CurrentLocale
        if ($TextObj.ContainsKey($locale)) {
            return $TextObj[$locale]
        }
        if ($TextObj.ContainsKey('en')) {
            return $TextObj['en']
        }
    }
    
    return [string]$TextObj
}

# Строит панель руководства со сворачиваемыми блоками (Expander)
function Build-GuidePanel {
    param([object]$Window)
    
    if (-not $script:MainWindow) { return }
    $panel = $script:MainWindow.FindName("GuideCategoriesPanel")
    if (-not $panel) { return }
    
    $panel.Children.Clear()
    
    $emojiFont = "Segoe UI Emoji, Segoe UI"
    
    # Сортировка разделов по Order
    $sortedGuide = $script:GuideContent.Values | Sort-Object Order
    
    foreach ($section in $sortedGuide) {
        $sectionKey = ($script:GuideContent.GetEnumerator() | Where-Object { $_.Value -eq $section }).Key
        
        # Сворачиваемый блок раздела
        $expander = New-Object System.Windows.Controls.Expander
        $expander.IsExpanded = $false
        $expander.Margin = "0,0,0,12"
        
        # Заголовок раздела (перевод из translations.json при наличии ключа)
        $headerText = $sectionKey
        if ($section.TranslationKey) {
            $translated = Get-LocalizedString $section.TranslationKey -Fallback $sectionKey
            $headerText = $translated
        }
        
        $header = New-Object System.Windows.Controls.TextBlock
        $header.Text = $headerText
        $header.FontSize = 16
        $header.FontWeight = "Bold"
        $header.FontFamily = $emojiFont
        $header.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "TextFG")
        $expander.Header = $header
        
        # Контейнер содержимого раздела
        $contentStack = New-Object System.Windows.Controls.StackPanel
        $contentStack.Margin = "10,10,10,10"
        
        # Подразделы (заголовок + текст)
        foreach ($subSection in $section.Sections) {
            $headingText = Get-GuideLocalizedText -TextObj $subSection.Heading
            
            $subHeader = New-Object System.Windows.Controls.TextBlock
            $subHeader.Text = $headingText
            $subHeader.FontSize = 14
            $subHeader.FontWeight = "SemiBold"
            $subHeader.FontFamily = $emojiFont
            $subHeader.Margin = "0,10,0,5"
            $subHeader.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "TextFG")
            $contentStack.Children.Add($subHeader) | Out-Null
            
            $bodyText = Get-GuideLocalizedText -TextObj $subSection.Body
            
            $body = New-Object System.Windows.Controls.TextBlock
            $body.Text = $bodyText
            $body.FontSize = 13
            $body.TextWrapping = [System.Windows.TextWrapping]::Wrap
            $body.FontFamily = $emojiFont
            $body.Margin = "0,0,0,10"
            $body.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "TextFG")
            $contentStack.Children.Add($body) | Out-Null
        }
        
        $expander.Content = $contentStack
        $panel.Children.Add($expander) | Out-Null
    }
}