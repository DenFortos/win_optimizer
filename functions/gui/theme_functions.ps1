# functions/gui/theme_functions.ps1
# Управление темами оформления (light/dark)

# Fallback-цвета на случай отсутствия themes.json
$script:ThemeColors = @{
    "light" = @{
        "MainBG" = "#F5F5F5"; "PanelBG" = "#FFFFFF"; "TextFG" = "#333333"
        "ButtonBG" = "#0078D4"; "ButtonFG" = "#FFFFFF"; "BorderBrush" = "#CCCCCC"
        "HeaderBG" = "#0078D4"; "HeaderFG" = "#FFFFFF"
        "TabBG" = "#E0E0E0"; "TabFG" = "#333333"
        "TabSelectedBG" = "#0078D4"; "TabSelectedFG" = "#FFFFFF"
        "ComboBoxBG" = "#FFFFFF"; "ComboBoxFG" = "#333333"; "ComboBoxBorder" = "#CCCCCC"
    }
    "dark" = @{
        "MainBG" = "#1E1E1E"; "PanelBG" = "#252526"; "TextFG" = "#FFFFFF"
        "ButtonBG" = "#0E639C"; "ButtonFG" = "#FFFFFF"; "BorderBrush" = "#3E3E42"
        "HeaderBG" = "#2D2D30"; "HeaderFG" = "#FFFFFF"
        "TabBG" = "#2D2D30"; "TabFG" = "#CCCCCC"
        "TabSelectedBG" = "#0E639C"; "TabSelectedFG" = "#FFFFFF"
        "ComboBoxBG" = "#3E3E42"; "ComboBoxFG" = "#FFFFFF"; "ComboBoxBorder" = "#555555"
    }
}

# Применяет тему к ресурсам окна (внешний themes.json → встроенный ресурс → fallback)
function Set-Theme {
    param([string]$ThemeName, [object]$Window)
    
    $themesJson = $null
    if ($ProjectRoot) {
        $themesPath = Join-Path $ProjectRoot "configuration/themes.json"
        if (Test-Path $themesPath) {
            try { $themesJson = Get-Content $themesPath -Raw -Encoding UTF8 } catch {}
        }
    }
    if (-not $themesJson -and $script:EmbeddedThemesJson) {
        $themesJson = $script:EmbeddedThemesJson
    }
    
    if ($themesJson) {
        try {
            $allThemes = $themesJson | ConvertFrom-Json
            $themeColors = $allThemes.$ThemeName
            
            if ($themeColors) {
                foreach ($prop in $themeColors.PSObject.Properties) {
                    try {
                        $color = [Windows.Media.ColorConverter]::ConvertFromString($prop.Value)
                        $Window.Resources[$prop.Name] = [Windows.Media.SolidColorBrush]::new($color)
                    }
                    catch { Write-Log "Failed to set color $($prop.Name) = $($prop.Value)" "WARNING" }
                }
                return
            }
        }
        catch { Write-Log "Failed to parse themes JSON: $_" "WARNING" }
    }
    
    # Fallback на захардкоженные цвета
    Write-Log "Using fallback colors for $ThemeName theme" "WARNING"
    $themeColors = $script:ThemeColors[$ThemeName]
    if ($themeColors) {
        foreach ($key in $themeColors.Keys) {
            $color = [Windows.Media.ColorConverter]::ConvertFromString($themeColors[$key])
            $Window.Resources[$key] = [Windows.Media.SolidColorBrush]::new($color)
        }
    }
}