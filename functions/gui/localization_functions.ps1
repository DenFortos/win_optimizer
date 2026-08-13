# functions/gui/localization_functions.ps1
# Управление локализацией интерфейса (EN/RU)

$script:CurrentLocale = "en"             # Текущий язык интерфейса
$script:Translations = $null             # Загруженные переводы
$script:IsApplyingLocalization = $false  # Флаг защиты от рекурсии
$script:UserSelectedLocale = $null       # Язык, выбранный пользователем

# Загружает переводы из внешнего JSON или встроенного ресурса
function Initialize-Localization {
    param([string]$Locale = "en")
    
    if ($script:CurrentLocale -eq $Locale -and $script:Translations) { return }
    $script:CurrentLocale = $Locale
    
    $translationsJson = $null
    if ($ProjectRoot) {
        $path = Join-Path $ProjectRoot "configuration/translations.json"
        if (Test-Path $path) {
            try { $translationsJson = Get-Content $path -Raw -Encoding UTF8 } catch {}
        }
    }
    if (-not $translationsJson -and $script:EmbeddedTranslationsJson) {
        $translationsJson = $script:EmbeddedTranslationsJson
    }
    
    if ($translationsJson) {
        try {
            $script:Translations = $translationsJson | ConvertFrom-Json
        }
        catch {
            Write-Log "Failed to parse translations JSON: $_" "ERROR"
            $script:Translations = $null
        }
    }
}

# Возвращает переведённую строку по ключу с fallback на английский
function Get-LocalizedString {
    param([string]$Key, [string]$Fallback = "")
    foreach ($lang in @($script:CurrentLocale, "en")) {
        if ($script:Translations.$lang.$Key) {
            return $script:Translations.$lang.$Key
        }
    }
    return $Fallback
}

# Проверяет, содержит ли строка эмодзи
function Test-HasEmoji {
    param([string]$Text)
    if (-not $Text) { return $false }
    
    if ($Text.Contains([char]0xFE0F)) { return $true }
    
    foreach ($char in $Text.ToCharArray()) {
        $code = [int]$char
        if ($code -ge 0x2600 -and $code -le 0x2BFF) { return $true }
    }
    
    for ($i = 0; $i -lt $Text.Length - 1; $i++) {
        $high = [int]$Text[$i]
        $low = [int]$Text[$i + 1]
        if ($high -ge 0xD800 -and $high -le 0xDBFF -and $low -ge 0xDC00 -and $low -le 0xDFFF) {
            return $true
        }
    }
    return $false
}

# Устанавливает текст WPF-элемента с учётом типа и шрифта для эмодзи
function Set-ElementText {
    param([object]$Element, [string]$Text)
    
    if (-not $Element -or -not $Text) { return }
    
    $hasEmoji = Test-HasEmoji -Text $Text
    $emojiFont = "Segoe UI Emoji, Segoe UI"
    
    if ($Element -is [System.Windows.Controls.TextBox]) {
        $Element.Tag = $Text
        if ($hasEmoji) { $Element.FontFamily = $emojiFont }
    } elseif ($Element -is [System.Windows.Controls.TextBlock]) {
        $Element.Text = $Text
        if ($hasEmoji) { $Element.FontFamily = $emojiFont }
    } else {
        try { 
            $Element.Content = $Text
            if ($hasEmoji) { $Element.FontFamily = $emojiFont }
        }
        catch { 
            $Element.Text = $Text
            if ($hasEmoji) { $Element.FontFamily = $emojiFont }
        }
    }
}

# Применяет все переводы к элементам UI с защитой от рекурсии
function Apply-Localization {
    param([object]$Window, [string]$ForceLocale = $null)
    
    if ($script:IsApplyingLocalization) { return }
    $script:IsApplyingLocalization = $true
    
    try {
        $locale = $ForceLocale
        if (-not $locale) {
            $locale = $script:UserSelectedLocale
            if (-not $locale) {
                $lang = "auto"
                $settingsJson = $null
                if ($ProjectRoot) {
                    $settingsPath = Join-Path $ProjectRoot "configuration/settings.json"
                    if (Test-Path $settingsPath) {
                        try { $settingsJson = Get-Content $settingsPath -Raw -Encoding UTF8 } catch {}
                    }
                }
                if (-not $settingsJson -and $script:EmbeddedSettingsJson) {
                    $settingsJson = $script:EmbeddedSettingsJson
                }
                if ($settingsJson) {
                    try { $lang = ($settingsJson | ConvertFrom-Json).default_language } catch {}
                }
                $locale = if ($lang -eq "auto") {
                    if ((Get-Culture).TwoLetterISOLanguageName -eq "ru") { "ru" } else { "en" }
                } else { $lang }
            }
        }
        
        Initialize-Localization -Locale $locale
        
        $Window.Title = Get-LocalizedString "app_title" "Windows Optimizer"
        
        $tabControl = $Window.FindName("MainTabControl")
        if ($tabControl) {
            foreach ($tab in $tabControl.Items) {
                $key = switch ($tab.Name) {
                    "InstallTab"       { "tab_install" }
                    "TweaksTab"        { "tab_debloat" }
                    "OptimizationTab"  { "tab_optimization" }
                    "GuideTab"         { "tab_guide" }
                }
                if ($key) { $tab.Header = Get-LocalizedString $key $tab.Header }
            }
        }
        
        foreach ($key in @("SearchBox", "BtnInstall", "BtnOpenAppwiz", "BtnOpenCleanMgr")) {
            $ctrl = $Window.FindName($key)
            if ($ctrl) {
                $transKey = switch ($key) {
                    "SearchBox"       { "search_placeholder" }
                    "BtnInstall"      { "btn_install" }
                    "BtnOpenAppwiz"   { "btn_open_appwiz" }
                    "BtnOpenCleanMgr" { "btn_open_cleanmgr" }
                }
                $fallback = switch ($key) {
                    "SearchBox"       { "Search..." }
                    "BtnInstall"      { "Install Selected" }
                    "BtnOpenAppwiz"   { "🗑️ Programs & Features" }
                    "BtnOpenCleanMgr" { "🧹 Disk Cleanup" }
                }
                Set-ElementText -Element $ctrl -Text (Get-LocalizedString $transKey -Fallback $fallback)
            }
        }
        
        $appwizBtn = $Window.FindName("BtnOpenAppwiz")
        if ($appwizBtn) { $appwizBtn.ToolTip = Get-LocalizedString "btn_open_appwiz_tooltip" -Fallback "" }
        
        $cleanMgrBtn = $Window.FindName("BtnOpenCleanMgr")
        if ($cleanMgrBtn) { $cleanMgrBtn.ToolTip = Get-LocalizedString "btn_open_cleanmgr_tooltip" -Fallback "" }
        
        $applyBtn = $Window.FindName("BtnApplyTweaks")
        if ($applyBtn) { Set-ElementText -Element $applyBtn -Text (Get-LocalizedString "btn_apply_tweaks" -Fallback "Delete Selected") }
        
        $optBtn = $Window.FindName("BtnApplyOptimization")
        if ($optBtn) { Set-ElementText -Element $optBtn -Text (Get-LocalizedString "btn_apply_optimization" -Fallback "Apply Selected") }
        
        foreach ($storage in @($script:TweakItemHeaders, $script:CategoryHeaders, $script:OptimizationItemHeaders)) {
            if ($storage) {
                foreach ($catKey in $storage.Keys) {
                    $info = $storage[$catKey]
                    if (-not $info) { continue }
                    $translated = Get-LocalizedString $info.TranslationKey -Fallback $info.DisplayName
                    $fullText = if ($info.Icon) { "$($info.Icon) $translated" } else { $translated }
                    Set-ElementText -Element $info.Control -Text $fullText
                }
            }
        }
        
        Update-SelectedCount
        Update-TweaksCount
        Update-OptimizationCount
        
        if ($script:SelectAllHeaders) {
            $text = Get-LocalizedString "select_all" -Fallback "Select All"
            foreach ($key in $script:SelectAllHeaders.Keys) {
                $ctrl = $script:SelectAllHeaders[$key]
                if ($ctrl) { Set-ElementText -Element $ctrl -Text $text }
            }
        }
        
        $installDesc = $Window.FindName("TabDescriptionInstall")
        if ($installDesc) { $installDesc.Text = Get-LocalizedString "tab_install_desc" }
        
        $vpnNote = $Window.FindName("VpnNoteInstall")
        if ($vpnNote) { $vpnNote.Text = Get-LocalizedString "install_vpn_note" }
        
        $debloatDesc = $Window.FindName("TabDescriptionDebloat")
        if ($debloatDesc) { $debloatDesc.Text = Get-LocalizedString "tab_debloat_desc" }
        
        $optimizationDesc = $Window.FindName("TabDescriptionOptimization")
        if ($optimizationDesc) { $optimizationDesc.Text = Get-LocalizedString "tab_optimization_desc" }
        
        $guideDesc = $Window.FindName("TabDescriptionGuide")
        if ($guideDesc) { $guideDesc.Text = Get-LocalizedString "tab_guide_desc" }
        
        if ($script:CurrentSpinnerPrefix) {
            $progressText = $Window.FindName("$($script:CurrentSpinnerPrefix)ProgressText")
            if ($progressText) {
                $key = if ($script:CurrentProgressKey) { $script:CurrentProgressKey } else { "install_progress" }
                $progressText.Text = Get-LocalizedString $key
            }
        }
        
        Update-ThemeButton -Window $Window
        
        $langCombo = $Window.FindName("LanguageComboBox")
        if ($langCombo) {
            $index = if ($locale -eq "ru") { 0 } else { 1 }
            $langCombo.SelectedIndex = $index
        }
        
        if ($script:OptimizationCheckBoxes -and $script:OptimizationCheckBoxes.Count -gt 0) {
            foreach ($funcName in $script:OptimizationCheckBoxes.Keys) {
                $info = $script:OptimizationCheckBoxes[$funcName]
                if ($info -and $info.CheckBox -and $info.TranslationKey) {
                    $translated = Get-LocalizedString $info.TranslationKey -Fallback $info.Fallback
                    if ($translated -and $info.CheckBox.Content -ne $translated) {
                        $info.CheckBox.Content = $translated
                    }
                }
            }
        }
        
        # ИСПРАВЛЕНИЕ: Принудительное обновление текста секции ручной загрузки при смене языка
        # Что делает этот блок: Проверяет наличие сохранённых элементов ручной загрузки и обновляет их текст через Get-LocalizedString.
        if ($script:ManualDownloadsTexts) {
            $script:ManualDownloadsTexts["Title"].Text = Get-LocalizedString "manual_downloads_title" -Fallback "🔗 Manual Downloads"
            $script:ManualDownloadsTexts["Desc"].Text = Get-LocalizedString "manual_downloads_desc" -Fallback "These programs are not available in package managers."
        }
        
        $guidePanel = $Window.FindName("GuideCategoriesPanel")
        if ($guidePanel -and $guidePanel.Children.Count -gt 0) {
            Build-GuidePanel -Window $Window
        }
    }
    finally {
        $script:IsApplyingLocalization = $false
    }
}

# Переключает язык интерфейса с защитой от повторных вызовов
function Switch-Language {
    param([string]$Locale, [object]$Window)
    if ($script:IsApplyingLocalization -or $script:CurrentLocale -eq $Locale) { return }
    $script:UserSelectedLocale = $Locale
    Apply-Localization -Window $Window -ForceLocale $Locale
}