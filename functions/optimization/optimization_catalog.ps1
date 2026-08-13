# functions/optimization/optimization_catalog.ps1
# Каталог системных оптимизаций

$script:OptimizationCatalog = [ordered]@{
    "GamingPerformance" = @{
        DisplayName = "Gaming Performance"; TranslationKey = "optimization_gaming"; Icon = "🎮"
        Description = "Оптимизация для игр и снижения инпут-лага"; Order = 1
        Items = @(
            @{ Name = "Disable GameDVR"; TranslationKey = "gaming_disable_gamedvr"; FunctionName = "Disable-GameDVR"; Safe = $true; Description = "Отключает Xbox Game Bar — освобождает ресурсы" }
            @{ Name = "Disable Fullscreen Optimizations"; TranslationKey = "gaming_disable_fso"; FunctionName = "Disable-FullscreenOptimizations"; Safe = $false; Description = "Отключает FSO для снижения инпут-лага в играх" }
            @{ Name = "Disable Network Throttling"; TranslationKey = "gaming_disable_network_throttling"; FunctionName = "Disable-NetworkThrottling"; Safe = $true; Description = "Снижает пинг в онлайн-играх" }
            @{ Name = "Disable Mouse Acceleration"; TranslationKey = "gaming_disable_mouse_accel"; FunctionName = "Disable-MouseAcceleration"; Safe = $true; Description = "Отключает ускорение мыши для 1:1 отклика" }
            @{ Name = "Enable Game Mode"; TranslationKey = "gaming_enable_game_mode"; FunctionName = "Enable-GameMode"; Safe = $true; Description = "Приоритизирует игры над фоновыми процессами (+5-10% FPS)" }
            @{ Name = "Enable HAGS"; TranslationKey = "gaming_enable_hags"; FunctionName = "Enable-HAGS"; Safe = $true; Description = "Аппаратное планирование GPU (+5-15% FPS, требует перезагрузку)" }
            @{ Name = "High Performance Power Plan"; TranslationKey = "gaming_high_performance_power"; FunctionName = "Enable-HighPerformancePower"; Safe = $true; Description = "Стабилизирует FPS, убирает микро-фризы" }
            @{ Name = "Disable Core Isolation"; TranslationKey = "gaming_disable_core_isolation"; FunctionName = "Disable-CoreIsolation"; Safe = $false; Description = "⚠️ +10-20% FPS, снижает защиту от rootkit-атак" }
        )
    }
    
    "Privacy" = @{
        DisplayName = "Privacy"; TranslationKey = "optimization_privacy"; Icon = "🔒"
        Description = "Отключение слежки и снижения нагрузки"; Order = 2
        Items = @(
            @{ Name = "Disable Telemetry (DiagTrack)"; TranslationKey = "privacy_disable_telemetry"; FunctionName = "Disable-Telemetry"; Safe = $true; Description = "Отключает сбор данных Microsoft — снижает нагрузку" }
            @{ Name = "Disable Advertising ID"; TranslationKey = "privacy_disable_advertising"; FunctionName = "Disable-AdvertisingID"; Safe = $true; Description = "Запрещает рекламное отслеживание" }
            @{ Name = "Disable Web Search in Start"; TranslationKey = "privacy_disable_websearch"; FunctionName = "Disable-WebSearchStartMenu"; Safe = $true; Description = "Поиск в Пуск ищет только локальные файлы" }
        )
    }
    
    "FileExplorer" = @{
        DisplayName = "File Explorer"; TranslationKey = "optimization_explorer"; Icon = "📁"
        Description = "Скрытие лишних элементов из боковой панели проводника"; Order = 3
        Items = @(
            @{ Name = "Hide Home"; TranslationKey = "explorer_hide_home"; FunctionName = "Hide-Home"; Safe = $true; Description = "Скрывает 'Главная' из боковой панели" }
            @{ Name = "Hide Gallery"; TranslationKey = "explorer_hide_gallery"; FunctionName = "Hide-Gallery"; Safe = $true; Description = "Скрывает 'Галерея' из боковой панели" }
            @{ Name = "Hide OneDrive"; TranslationKey = "explorer_hide_onedrive"; FunctionName = "Hide-OneDrive"; Safe = $true; Description = "Скрывает OneDrive из боковой панели" }
            @{ Name = "Hide Network"; TranslationKey = "explorer_hide_network"; FunctionName = "Hide-Network"; Safe = $true; Description = "Скрывает 'Сеть' из боковой панели" }
            @{ Name = "Hide Removable Drives"; TranslationKey = "explorer_hide_removable"; FunctionName = "Hide-RemovableDrives"; Safe = $true; Description = "Скрывает съёмные диски (убирает дублирование флешек)" }
        )
    }
    
    "Cleanup" = @{
        DisplayName = "System Cleanup"; TranslationKey = "optimization_cleanup"; Icon = "🗑️"
        Description = "Очистка системного мусора и освобождение места на диске"; Order = 4
        Items = @(
            @{ Name = "Clean WinSxS (DISM)"; TranslationKey = "cleanup_dism_winsxs"; FunctionName = "Invoke-DismCleanup"; Safe = $true; Description = "Глубокая очистка старых компонентов Windows (освобождает 2-5 ГБ)" }
        )
    }
}