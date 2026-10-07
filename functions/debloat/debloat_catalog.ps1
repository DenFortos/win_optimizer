# functions/debloat/debloat_catalog.ps1
# Каталог UWP-приложений для удаления (Windows 11 Pro 24H2)

$script:DebloatCatalog = [ordered]@{
    "MicrosoftBloat" = @{
        DisplayName = "Microsoft Bloat"; TranslationKey = "debloat_microsoft"; Icon = "🗑️"
        Description = "Предустановленные приложения Microsoft (безопасно удалять)"; Order = 1
        Items = @(
            @{ Name = "Bing News"; PackageName = "Microsoft.BingNews"; Type = "UWP"; Safe = $true }
            @{ Name = "Bing Weather"; PackageName = "Microsoft.BingWeather"; Type = "UWP"; Safe = $true }
            @{ Name = "Bing Search"; PackageName = "Microsoft.BingSearch"; Type = "UWP"; Safe = $true }
            @{ Name = "Solitaire Collection"; PackageName = "Microsoft.MicrosoftSolitaireCollection"; Type = "UWP"; Safe = $true }
            @{ Name = "Microsoft 365 (Copilot)"; PackageName = "Microsoft.MicrosoftOfficeHub"; Type = "UWP"; Safe = $true }
            @{ Name = "Power Automate"; PackageName = "Microsoft.PowerAutomateDesktop"; Type = "UWP"; Safe = $true }
            @{ Name = "Microsoft Teams"; PackageName = "MSTeams"; Type = "UWP"; Safe = $true }
            @{ Name = "Microsoft To Do"; PackageName = "Microsoft.Todos"; Type = "UWP"; Safe = $true }
            @{ Name = "Outlook for Windows"; PackageName = "Microsoft.OutlookForWindows"; Type = "UWP"; Safe = $true }
            @{ Name = "Get Help"; PackageName = "Microsoft.GetHelp"; Type = "UWP"; Safe = $true }
            @{ Name = "Feedback Hub"; PackageName = "Microsoft.WindowsFeedbackHub"; Type = "UWP"; Safe = $true }
            @{ Name = "Your Phone"; PackageName = "Microsoft.YourPhone"; Type = "UWP"; Safe = $true }
            @{ Name = "Quick Assist"; PackageName = "MicrosoftCorporationII.QuickAssist"; Type = "UWP"; Safe = $true }
        )
    }
    
    "MediaBloat" = @{
        DisplayName = "Media & Streaming"; TranslationKey = "debloat_media"; Icon = "🎵"
        Description = "Предустановленные стриминги и медиа-сервисы"; Order = 2
        Items = @(
            @{ Name = "Clipchamp"; PackageName = "Clipchamp.Clipchamp"; Type = "UWP"; Safe = $true }
            @{ Name = "Groove Music"; PackageName = "Microsoft.ZuneMusic"; Type = "UWP"; Safe = $true }
            @{ Name = "Yandex Music"; PackageName = "A025C540.Yandex.Music"; Type = "UWP"; Safe = $true }
        )
    }
    
    "GamingBloat" = @{
        DisplayName = "Xbox & Gaming"; TranslationKey = "debloat_gaming"; Icon = "🎮"
        Description = "Игровые приложения (не удаляй если играешь через Xbox)"; Order = 3
        Items = @(
            @{ Name = "Xbox Game Bar"; PackageName = "Microsoft.XboxGamingOverlay"; Type = "UWP"; Safe = $false }
            @{ Name = "Xbox App"; PackageName = "Microsoft.GamingApp"; Type = "UWP"; Safe = $false }
            @{ Name = "Edge Game Assist"; PackageName = "Microsoft.Edge.GameAssist"; Type = "UWP"; Safe = $true }
        )
    }
    
    "WindowsFeatures" = @{
        DisplayName = "Windows 11 Features"; TranslationKey = "debloat_windows"; Icon = "💻"
        Description = "Новые функции Windows 11 (виджеты, cross-device, Dev Home)"; Order = 4
        Items = @(
            @{ Name = "Widgets (Web Experience)"; PackageName = "MicrosoftWindows.Client.WebExperience"; Type = "UWP"; Safe = $true }
            @{ Name = "Widgets Platform"; PackageName = "Microsoft.WidgetsPlatformRuntime"; Type = "UWP"; Safe = $true }
            @{ Name = "Cross Device Experience"; PackageName = "MicrosoftWindows.CrossDevice"; Type = "UWP"; Safe = $true }
            @{ Name = "Dev Home"; PackageName = "Microsoft.Windows.DevHome"; Type = "UWP"; Safe = $true }
        )
    }
    
    "OptionalApps" = @{
        DisplayName = "Optional Apps"; TranslationKey = "debloat_optional"; Icon = "📦"
        Description = "Опциональные приложения (могут быть полезны)"; Order = 5
        Items = @(
            @{ Name = "Sticky Notes"; PackageName = "Microsoft.MicrosoftStickyNotes"; Type = "UWP"; Safe = $true }
            @{ Name = "Sound Recorder"; PackageName = "Microsoft.WindowsSoundRecorder"; Type = "UWP"; Safe = $true }
            @{ Name = "Clock"; PackageName = "Microsoft.WindowsAlarms"; Type = "UWP"; Safe = $true }
        )
    }
}

# Возвращает метаданные приложения из каталога по категории и имени
function Get-DebloatInfo {
    param([string]$CategoryName, [string]$ItemName)
    
    if ($script:DebloatCatalog.Contains($CategoryName)) {
        return $script:DebloatCatalog[$CategoryName].Items | Where-Object { $_.Name -eq $ItemName } | Select-Object -First 1
    }
    return $null
}