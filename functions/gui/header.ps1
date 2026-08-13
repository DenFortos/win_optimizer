# functions/gui/header.ps1
# Обработчики шапки: переключение темы и языка

# Переключает тему между light/dark и обновляет UI
function Switch-Theme {
    if ($script:IsInitializing -or -not $script:MainWindow) { return }
    $script:IsDarkTheme = -not $script:IsDarkTheme
    $themeName = if ($script:IsDarkTheme) { "dark" } else { "light" }
    Set-Theme -ThemeName $themeName -Window $script:MainWindow
    Update-ThemeButton -Window $script:MainWindow
}

# Обновляет иконку кнопки переключения темы
function Update-ThemeButton {
    param([object]$Window)
    $btn = $Window.FindName("ThemeButton")
    if ($btn) { $btn.Content = if ($script:IsDarkTheme) { "☀" } else { "☾" } }
}

# Обрабатывает выбор языка в ComboBox шапки
function Switch-LanguageHandler {
    param($sender, $eventArgs)
    if ($script:IsInitializing -or $script:IsApplyingLocalization -or -not $script:MainWindow) { return }
    $lang = [string]$sender.SelectedItem.Tag
    if (-not $lang -or $script:CurrentLocale -eq $lang) { return }
    Switch-Language -Locale $lang -Window $script:MainWindow
}

# Подключает обработчики кнопки темы и ComboBox языка
function Initialize-HeaderHandlers {
    param([object]$Window)
    $themeBtn = $Window.FindName("ThemeButton")
    $langCb = $Window.FindName("LanguageComboBox")
    if ($themeBtn) { $themeBtn.Add_Click({ Switch-Theme }) }
    if ($langCb) { $langCb.Add_SelectionChanged({ Switch-LanguageHandler -sender $this -eventArgs $args }) }
}