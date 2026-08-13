# functions/guide/guide_content.ps1
# Гайд по приложению: описание логики всех чекбоксов в трёх разделах.
# Все тексты поддерживают два языка: en и ru.

$script:GuideContent = [ordered]@{
    "Install" = @{
        TranslationKey = "guide_section_install"
        Icon = "📦"
        Order = 1
        Sections = @(
            @{
                Heading = @{ en = "How installation works"; ru = "Как работает установка" }
                Body = @{
                    en = "Programs are installed via Chocolatey — a Windows package manager. Tick the apps you need, press 'Install Selected', and Chocolatey downloads and installs the latest versions automatically. Running it again updates programs to the newest version. Apps marked ⚠️ (Tor Browser, Discord, Signal) need a VPN — their servers are unavailable from Russia."
                    ru = "Программы устанавливаются через Chocolatey — пакетный менеджер Windows. Отметь нужные приложения, нажми «Установить выбранные» — Chocolatey сам скачает и поставит последние версии. Повторный запуск обновляет программы до актуальной версии. Приложения с меткой ⚠️ (Tor Browser, Discord, Signal) требуют VPN — их серверы недоступны из России."
                }
            }
            @{
                Heading = @{ en = "Available programs"; ru = "Доступные программы" }
                Body = @{
                    en = "🌐 Browsers: Brave, Chrome, Firefox, Tor Browser ⚠️, Vivaldi`n💬 Communications: Discord ⚠️, Telegram, Signal ⚠️, Zoom, TeamSpeak`n💻 Development: VS Code, Git, Python3, NodeJS LTS, GitHub CLI, MinGW (GCC), Notepad++`n🎮 Games: Steam, Epic Games, GOG Galaxy`n🔧 Microsoft Tools: PowerToys, Windows Terminal, .NET Desktop Runtime 8`n🎵 Multimedia: VLC, OBS Studio, GIMP, Blender`n🛠️ Utilities: 7-Zip, WinRAR, Bitwarden, Rufus, Everything, ShareX, Wireshark, PuTTY, WinSCP, CPU-Z, HWiNFO, Revo Uninstaller, TreeSize Free"
                    ru = "🌐 Браузеры: Brave, Chrome, Firefox, Tor Browser ⚠️, Vivaldi`n💬 Коммуникации: Discord ⚠️, Telegram, Signal ⚠️, Zoom, TeamSpeak`n💻 Разработка: VS Code, Git, Python3, NodeJS LTS, GitHub CLI, MinGW (GCC), Notepad++`n🎮 Игры: Steam, Epic Games, GOG Galaxy`n🔧 Инструменты Microsoft: PowerToys, Windows Terminal, .NET Desktop Runtime 8`n🎵 Мультимедиа: VLC, OBS Studio, GIMP, Blender`n🛠️ Утилиты: 7-Zip, WinRAR, Bitwarden, Rufus, Everything, ShareX, Wireshark, PuTTY, WinSCP, CPU-Z, HWiNFO, Revo Uninstaller, TreeSize Free"
                }
            }
            @{
                Heading = @{ en = "Uninstalling programs"; ru = "Удаление программ" }
                Body = @{
                    en = "Uninstall via the '🗑️ Programs & Features' button — it opens the Windows system panel where each program is removed by its own uninstaller. Chocolatey does not uninstall programs."
                    ru = "Удаление — через кнопку «🗑️ Программы и компоненты»: она открывает системный раздел Windows, где каждая программа удаляется своим штатным деинсталлятором. Chocolatey программы не удаляет."
                }
            }
        )
    }
    
    "Debloat" = @{
        TranslationKey = "guide_section_debloat"
        Icon = "🗑️"
        Order = 2
        Sections = @(
            @{
                Heading = @{ en = "What are UWP apps and why remove them"; ru = "Что такое UWP и зачем их удалять" }
                Body = @{
                    en = "UWP (Universal Windows Platform) are modern apps pre-installed with Windows 11. Many of them are bloatware: they run in the background, consume RAM/CPU, show ads and collect telemetry. Removal is safe — apps are removed both for the current user and from the system image (they won't come back for new users). Files stay in C:\Program Files\WindowsApps and can be restored from Microsoft Store."
                    ru = "UWP (Universal Windows Platform) — это современные приложения, предустановленные в Windows 11. Многие из них — мусор: работают в фоне, потребляют RAM/CPU, показывают рекламу и собирают телеметрию. Удаление безопасно — приложения снимаются и для текущего пользователя, и из образа системы (новым пользователям не вернутся). Файлы остаются в C:\Program Files\WindowsApps и могут быть восстановлены из Microsoft Store."
                }
            }
            @{
                Heading = @{ en = "🗑️ Microsoft Bloat"; ru = "🗑️ Мусор от Microsoft" }
                Body = @{
                    en = "Bing News/Weather/Search — Bing news and weather widgets`nSolitaire Collection — card games with ads`nMicrosoft 365 (Copilot) — Office/Copilot shortcut-ad`nPower Automate — task automation (rarely needed)`nMicrosoft Teams — corporate messenger`nMicrosoft To Do — task list`nOutlook for Windows — new mail client (ad)`nGet Help — Windows help (online)`nFeedback Hub — send feedback to Microsoft`nYour Phone — Android phone link`nQuick Assist — remote assistance"
                    ru = "Bing News/Weather/Search — новостные и погодные виджеты Bing`nSolitaire Collection — карточные игры с рекламой`nMicrosoft 365 (Copilot) — ярлык-реклама Office/Copilot`nPower Automate — автоматизация задач (нужна редко)`nMicrosoft Teams — корпоративный мессенджер`nMicrosoft To Do — список задач`nOutlook for Windows — новый почтовый клиент (реклама)`nGet Help — справка Windows (работает онлайн)`nFeedback Hub — отправка отзывов Microsoft`nYour Phone — связь с телефоном Android`nQuick Assist — удалённая помощь"
                }
            }
            @{
                Heading = @{ en = "🎵 Media & Streaming"; ru = "🎵 Медиа и стриминг" }
                Body = @{
                    en = "Clipchamp — Microsoft online video editor`nGroove Music — music player (obsolete)`nYandex Music — Russian streaming service"
                    ru = "Clipchamp — онлайн-видеоредактор Microsoft`nGroove Music — музыкальный плеер (устарел)`nYandex Music — российский стриминговый сервис"
                }
            }
            @{
                Heading = @{ en = "🎮 Xbox & Gaming"; ru = "🎮 Игры и Xbox" }
                Body = @{
                    en = "Xbox Game Bar — game overlay (⚠️ don't remove if you play via Xbox)`nXbox App — Xbox app (⚠️ needed for Microsoft Store games)`nEdge Game Assist — gaming assistant in Edge"
                    ru = "Xbox Game Bar — игровой оверлей (⚠️ не удаляй, если играешь через Xbox)`nXbox App — приложение Xbox (⚠️ нужно для игр из Microsoft Store)`nEdge Game Assist — игровой помощник в Edge"
                }
            }
            @{
                Heading = @{ en = "💻 Windows 11 Features"; ru = "💻 Функции Windows 11" }
                Body = @{
                    en = "Widgets (Web Experience) — taskbar widgets`nWidgets Platform — widget runtime environment`nCross Device Experience — link between Microsoft devices`nDev Home — developer dashboard"
                    ru = "Widgets (Web Experience) — виджеты на панели задач`nWidgets Platform — среда выполнения виджетов`nCross Device Experience — связь между устройствами Microsoft`nDev Home — панель для разработчиков"
                }
            }
            @{
                Heading = @{ en = "📦 Optional Apps"; ru = "📦 Опциональные приложения" }
                Body = @{
                    en = "Sticky Notes — sticky notes`nSound Recorder — voice recorder`nClock — clock, alarm, timer`n⚠️ These apps may be useful — remove with caution"
                    ru = "Sticky Notes — липкие заметки`nSound Recorder — диктофон`nClock — часы, будильник, таймер`n⚠️ Эти приложения могут быть полезны — удаляй с осторожностью"
                }
            }
        )
    }
    
    "Optimization" = @{
        TranslationKey = "guide_section_optimization"
        Icon = "⚙️"
        Order = 3
        Sections = @(
            @{
                Heading = @{ en = "🎮 Gaming Performance"; ru = "🎮 Игровая производительность" }
                Body = @{
                    en = "Tweaks to raise FPS and reduce input lag. Most apply instantly, some need a reboot."
                    ru = "Твики для повышения FPS и снижения инпут-лага. Большинство применяются мгновенно, некоторые требуют перезагрузки."
                }
            }
            @{
                Heading = @{ en = "Disable GameDVR"; ru = "Отключить GameDVR" }
                Body = @{
                    en = "📍 HKCU\System\GameConfigStore\GameDVR_Enabled = 0`n🔧 Disables Xbox Game Bar background recording`n✅ Frees CPU/GPU resources, +3-5% FPS`n🔄 Reboot: not required"
                    ru = "📍 HKCU\System\GameConfigStore\GameDVR_Enabled = 0`n🔧 Отключает фоновую запись Xbox Game Bar`n✅ Освобождает CPU/GPU ресурсы, +3-5% FPS`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Disable Fullscreen Optimizations"; ru = "Отключить оптимизацию полноэкранного режима" }
                Body = @{
                    en = "📍 HKCU\System\GameConfigStore\GameDVR_FSEBehaviorMode = 2`n🔧 Disables Windows FSO (Fullscreen Optimizations)`n✅ Reduces input lag by 20-30ms`n⚠️ May cause issues in some games`n🔄 Reboot: not required"
                    ru = "📍 HKCU\System\GameConfigStore\GameDVR_FSEBehaviorMode = 2`n🔧 Отключает FSO (Fullscreen Optimizations) Windows`n✅ Снижает инпут-лаг на 20-30ms`n⚠️ Может вызвать проблемы в некоторых играх`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Disable Network Throttling"; ru = "Отключить сетевой троттлинг" }
                Body = @{
                    en = "📍 HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\NetworkThrottlingIndex = 0xffffffff`n🔧 Disables network performance throttling`n✅ Reduces ping in online games by 10-30ms`n🔄 Reboot: not required"
                    ru = "📍 HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\NetworkThrottlingIndex = 0xffffffff`n🔧 Отключает ограничение сетевой производительности`n✅ Снижает пинг в онлайн-играх на 10-30ms`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Disable Mouse Acceleration"; ru = "Отключить ускорение мыши" }
                Body = @{
                    en = "📍 HKCU\Control Panel\Mouse\MouseSpeed = 0`n🔧 Disables mouse acceleration (Raw Input)`n✅ 1:1 mouse movement without acceleration`n🔄 Reboot: not required"
                    ru = "📍 HKCU\Control Panel\Mouse\MouseSpeed = 0`n🔧 Отключает ускорение мыши (Raw Input)`n✅ Движение мыши 1:1 без акселерации`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Enable Game Mode"; ru = "Включить игровой режим" }
                Body = @{
                    en = "📍 HKCU\SOFTWARE\Microsoft\GameBar\AllowAutoGameMode = 1`n🔧 Enables Windows Game Mode`n✅ Prioritizes games over background processes, +5-10% FPS`n🔄 Reboot: not required"
                    ru = "📍 HKCU\SOFTWARE\Microsoft\GameBar\AllowAutoGameMode = 1`n🔧 Включает игровой режим Windows`n✅ Приоритизирует игры над фоновыми процессами, +5-10% FPS`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Enable HAGS"; ru = "Включить HAGS" }
                Body = @{
                    en = "📍 HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\HwSchMode = 2`n🔧 Enables Hardware-Accelerated GPU Scheduling`n✅ Reduces latency, +5-15% FPS`n🔄 Reboot: required"
                    ru = "📍 HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\HwSchMode = 2`n🔧 Включает аппаратное планирование GPU (HAGS)`n✅ Снижает задержки, +5-15% FPS`n🔄 Перезагрузка: требуется"
                }
            }
            @{
                Heading = @{ en = "High Performance Power Plan"; ru = "Схема высокой производительности" }
                Body = @{
                    en = "📍 powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c`n🔧 Activates the 'High Performance' power plan`n✅ Stabilizes FPS, eliminates micro-stutters`n🔄 Reboot: not required"
                    ru = "📍 powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c`n🔧 Активирует схему питания 'Высокая производительность'`n✅ Стабилизирует FPS, убирает микро-фризы`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Disable Core Isolation"; ru = "Отключить изоляцию ядра" }
                Body = @{
                    en = "📍 HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity\Enabled = 0`n🔧 Disables Core Isolation (Memory Integrity / HVCI)`n✅ +10-20% FPS in games`n⚠️ Reduces protection against rootkit attacks and kernel exploits`n🔄 Reboot: required"
                    ru = "📍 HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity\Enabled = 0`n🔧 Отключает изоляцию ядра (Memory Integrity / HVCI)`n✅ +10-20% FPS в играх`n⚠️ Снижает защиту от rootkit-атак и эксплойтов ядра`n🔄 Перезагрузка: требуется"
                }
            }
            @{
                Heading = @{ en = "🔒 Privacy"; ru = "🔒 Конфиденциальность" }
                Body = @{
                    en = "Disabling Microsoft telemetry and tracking. All changes are safe and do not affect system operation."
                    ru = "Отключение телеметрии и слежки Microsoft. Все изменения безопасны и не влияют на работу системы."
                }
            }
            @{
                Heading = @{ en = "Disable Telemetry (DiagTrack)"; ru = "Отключить телеметрию (DiagTrack)" }
                Body = @{
                    en = "📍 Services: DiagTrack, dmwappushservice → Disabled`n📍 HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry = 0`n🔧 Disables Microsoft diagnostic data collection`n✅ Reduces CPU load, more privacy`n🔄 Reboot: not required"
                    ru = "📍 Службы: DiagTrack, dmwappushservice → Disabled`n📍 HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry = 0`n🔧 Отключает сбор диагностических данных Microsoft`n✅ Снижает нагрузку на CPU, больше приватности`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Disable Advertising ID"; ru = "Отключить рекламный ID" }
                Body = @{
                    en = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled = 0`n🔧 Disables the Windows advertising identifier`n✅ Blocks personalized advertising`n🔄 Reboot: not required"
                    ru = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled = 0`n🔧 Отключает рекламный идентификатор Windows`n✅ Запрещает персонализированную рекламу`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Disable Web Search in Start"; ru = "Отключить веб-поиск в Пуске" }
                Body = @{
                    en = "📍 HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer\DisableSearchBoxSuggestions = 1`n📍 HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search\ConnectedSearchUseWeb = 0`n🔧 Disables web search in the Start menu`n✅ Search works locally only — faster and more private`n🔄 Reboot: not required"
                    ru = "📍 HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer\DisableSearchBoxSuggestions = 1`n📍 HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search\ConnectedSearchUseWeb = 0`n🔧 Отключает веб-поиск в меню Пуск`n✅ Поиск работает только локально — быстрее и приватнее`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "📁 File Explorer"; ru = "📁 Проводник" }
                Body = @{
                    en = "Hiding unnecessary items from the Explorer sidebar. All changes apply instantly (Explorer restarts automatically)."
                    ru = "Скрытие лишних элементов из боковой панели проводника. Все изменения применяются мгновенно (проводник перезапускается автоматически)."
                }
            }
            @{
                Heading = @{ en = "Hide Home"; ru = "Скрыть 'Главная'" }
                Body = @{
                    en = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum\{f874310e-b6b7-47dc-bc84-b9e6b38f5903} = 1`n🔧 Hides 'Home' from the Explorer sidebar`n✅ Cleaner Explorer interface`n🔄 Reboot: not required"
                    ru = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum\{f874310e-b6b7-47dc-bc84-b9e6b38f5903} = 1`n🔧 Скрывает 'Главная' из боковой панели проводника`n✅ Чище интерфейс проводника`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Hide Gallery"; ru = "Скрыть 'Галерея'" }
                Body = @{
                    en = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c} = 1`n🔧 Hides 'Gallery' from the sidebar`n✅ Removes photo duplication`n🔄 Reboot: not required"
                    ru = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c} = 1`n🔧 Скрывает 'Галерея' из боковой панели`n✅ Убирает дублирование фотографий`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Hide OneDrive"; ru = "Скрыть OneDrive" }
                Body = @{
                    en = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum\{018D5C66-4533-4307-9B53-224DE2ED1FE6} = 1`n🔧 Hides OneDrive from the sidebar`n✅ Cleaner interface if you don't use OneDrive`n🔄 Reboot: not required"
                    ru = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum\{018D5C66-4533-4307-9B53-224DE2ED1FE6} = 1`n🔧 Скрывает OneDrive из боковой панели`n✅ Чище интерфейс, если не используешь OneDrive`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Hide Network"; ru = "Скрыть 'Сеть'" }
                Body = @{
                    en = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C} = 1`n🔧 Hides 'Network' from the sidebar`n✅ Cleaner Explorer interface`n🔄 Reboot: not required"
                    ru = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C} = 1`n🔧 Скрывает 'Сеть' из боковой панели`n✅ Чище интерфейс проводника`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "Hide Removable Drives"; ru = "Скрыть съёмные диски" }
                Body = @{
                    en = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83} = 1`n🔧 Hides removable drives from the sidebar`n✅ Removes USB duplication (only shown in 'This PC')`n🔄 Reboot: not required"
                    ru = "📍 HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\NonEnum\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83} = 1`n🔧 Скрывает съёмные диски из боковой панели`n✅ Убирает дублирование флешек (остаются только в 'Этот компьютер')`n🔄 Перезагрузка: не требуется"
                }
            }
            @{
                Heading = @{ en = "🗑️ System Cleanup"; ru = "🗑️ Очистка системы" }
                Body = @{
                    en = "Cleaning system junk to free up disk space. Disk Cleanup (cleanmgr) is a separate '🧹 Disk Cleanup' button — it opens the built-in Windows utility where you pick what to remove."
                    ru = "Очистка системного мусора для освобождения места на диске. Очистка диска (cleanmgr) — отдельная кнопка «🧹 Очистка диска»: она открывает встроенную утилиту Windows, где ты сам выбираешь, что удалить."
                }
            }
            @{
                Heading = @{ en = "Clean WinSxS (DISM)"; ru = "Очистка WinSxS (DISM)" }
                Body = @{
                    en = "📍 Dism /Online /Cleanup-Image /StartComponentCleanup`n🔧 Deep cleanup of the Windows component store (WinSxS)`n✅ Frees 2-5 GB by removing old component versions`n⏳ May take 5-15 minutes`n🔄 Reboot: not required"
                    ru = "📍 Dism /Online /Cleanup-Image /StartComponentCleanup`n🔧 Глубокая очистка хранилища компонентов Windows (WinSxS)`n✅ Освобождает 2-5 ГБ, удаляя старые версии компонентов`n⏳ Может занять 5-15 минут`n🔄 Перезагрузка: не требуется"
                }
            }
        )
    }
}