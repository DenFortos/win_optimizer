# functions/install/install_helpers.ps1
# UI-обёртки вкладки Install: построение панели, получение выбора и рендер ссылок на ручную загрузку.

# Строит панель категорий программ через Build-GenericPanel
function Build-CategoriesPanel {
    param([object]$Window)
    
    if (-not $script:CategoryHeaders) { $script:CategoryHeaders = @{} }
    if (-not $script:SelectAllHeaders) { $script:SelectAllHeaders = @{} }
    
    # Группировка программ по категориям
    $categories = @{}
    foreach ($app in $script:AppCatalog.Keys) {
        $cat = $script:AppCatalog[$app].category
        if (-not $categories.Contains($cat)) { $categories[$cat] = @() }
        $categories[$cat] += $app
    }
    
    # Каталог в формате Build-GenericPanel
    $catalog = @{}
    foreach ($cat in $script:CategoryOrder) {
        if (-not $categories.Contains($cat)) { continue }
        $catalog[$cat] = @{
            DisplayName = $cat
            Icon = $script:CategoryIcons[$cat]
            Order = [array]::IndexOf($script:CategoryOrder, $cat)
            TranslationKey = $script:CategoryNames[$cat]
            Items = $categories[$cat] | ForEach-Object { @{ Name = $_; Tag = $_ } }
        }
    }
    
    Build-GenericPanel -PanelName "CategoriesPanel" `
                       -Catalog $catalog `
                       -UpdateCountFunction { Update-SelectedCount } `
                       -HeadersStorage $script:CategoryHeaders `
                       -SelectAllStorage $script:SelectAllHeaders `
                       -TagFormat "simple"
    
    # Добавляем секцию ручных загрузок в самый низ панели
    Build-ManualDownloadsSection -PanelName "CategoriesPanel"
    
    $script:CachedCheckBoxes = $null
}

# Строит и добавляет секцию с кликабельными ссылками для ручной загрузки программ.
# Что делает функция: Создаёт визуально отделённый блок с поясняющим текстом и гиперссылками, 
# сохраняет ссылки на текстовые элементы в глобальный словарь для корректной работы переключения языка.
function Build-ManualDownloadsSection {
    param([string]$PanelName)
    
    if (-not $script:MainWindow) { return }
    $panel = $script:MainWindow.FindName($PanelName)
    if (-not $panel) { return }
    
    # Внешняя рамка для визуального отделения
    $border = New-Object System.Windows.Controls.Border
    $border.Background = "Transparent"
    $border.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "TextFG")
    $border.BorderThickness = "2"
    $border.CornerRadius = "6"
    $border.Padding = "15"
    $border.Margin = "0,10,0,10"
    
    $stack = New-Object System.Windows.Controls.StackPanel
    
    # Заголовок секции
    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = Get-LocalizedString "manual_downloads_title" -Fallback "🔗 Manual Downloads"
    $title.FontSize = 15
    $title.FontWeight = "Bold"
    $title.FontFamily = "Segoe UI Emoji, Segoe UI"
    $title.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "TextFG")
    $title.Margin = "0,0,0,8"
    $stack.Children.Add($title) | Out-Null
    
    # Поясняющий текст
    $desc = New-Object System.Windows.Controls.TextBlock
    $desc.Text = Get-LocalizedString "manual_downloads_desc" -Fallback "These programs are not available in package managers. Click the links below to download them from official sources."
    $desc.FontSize = 12
    $desc.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $desc.FontFamily = "Segoe UI"
    $desc.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "TextFG")
    $desc.Opacity = 0.8
    $desc.Margin = "0,0,0,12"
    $stack.Children.Add($desc) | Out-Null
    
    # Сохраняем ссылки на элементы для последующего обновления при смене языка
    # Что делает этот блок: Инициализирует глобальный словарь и сохраняет в него объекты WPF, чтобы функция Apply-Localization могла менять их текст.
    if (-not $script:ManualDownloadsTexts) { $script:ManualDownloadsTexts = @{} }
    $script:ManualDownloadsTexts["Title"] = $title
    $script:ManualDownloadsTexts["Desc"] = $desc
    
    # Контейнер для ссылок
    $wrapPanel = New-Object System.Windows.Controls.WrapPanel
    $wrapPanel.Margin = "0,0,0,0"
    
    # Генерация гиперссылок из каталога ManualDownloads
    foreach ($key in $script:ManualDownloads.Keys) {
        $item = $script:ManualDownloads[$key]
        
        $linkBlock = New-Object System.Windows.Controls.TextBlock
        $linkBlock.Margin = "0,0,20,8"
        $linkBlock.FontSize = 13
        $linkBlock.FontFamily = "Segoe UI"
        
        $hyperlink = New-Object System.Windows.Documents.Hyperlink
        # Используем только переведенное имя без скобок
        $hyperlink.Inlines.Add((Get-LocalizedString $item.TranslationKey -Fallback $item.Name))
        $hyperlink.NavigateUri = [uri]$item.Url
        $hyperlink.TextDecorations = [System.Windows.TextDecorations]::None
        
        # Обработчик клика по ссылке
        $hyperlink.Add_RequestNavigate({
            param($sender, $e)
            try {
                Start-Process $e.Uri.AbsoluteUri
            } catch {
                Write-Log "Failed to open URL $($e.Uri.AbsoluteUri): $_" "ERROR"
            }
            $e.Handled = $true
        })
        
        # Стилизация гиперссылки при наведении
        $hyperlink.Add_MouseEnter({
            param($sender, $e)
            $sender.TextDecorations = [System.Windows.TextDecorations]::Underline
            $sender.Foreground = [System.Windows.Media.Brushes]::DodgerBlue
        })
        $hyperlink.Add_MouseLeave({
            param($sender, $e)
            $sender.TextDecorations = [System.Windows.TextDecorations]::None
            $sender.SetResourceReference([System.Windows.Documents.Hyperlink]::ForegroundProperty, "TextFG")
        })
        
        $hyperlink.SetResourceReference([System.Windows.Documents.Hyperlink]::ForegroundProperty, "TextFG")
        
        $linkBlock.Inlines.Add($hyperlink)
        $wrapPanel.Children.Add($linkBlock) | Out-Null
    }
    
    $stack.Children.Add($wrapPanel) | Out-Null
    $border.Child = $stack
    $panel.Children.Add($border) | Out-Null
}

# Возвращает список выбранных программ
function Get-SelectedApps {
    param([object]$Window)
    return Get-SelectedItems -PanelName "CategoriesPanel"
}

# Сбрасывает все чекбоксы вкладки Install
function Clear-AllSelections {
    param([object]$Window)
    Clear-Selections -PanelName "CategoriesPanel"
}

# Обновляет счётчик выбранных программ в кнопке «Сбросить выбор»
function Update-SelectedCount {
    Update-ItemCount -CounterName "BtnClearSelection" -PanelName "CategoriesPanel" -TranslationKey "btn_clear_count"
}

# Блокирует/разблокирует весь UI на время установки
function Set-InstallUILocked {
    param([bool]$Locked)
    Set-GlobalUILocked -Locked $Locked
}