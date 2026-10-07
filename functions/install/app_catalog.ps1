# functions/install/app_catalog.ps1
# Каталог программ для установки через Chocolatey и список программ для ручной загрузки.

# Основной каталог программ для установки через Chocolatey
$script:AppCatalog = @{
    # Browsers
    "Brave"           = @{ choco = "brave"; foss = $true; category = "Browsers" }
    "Chrome"          = @{ choco = "googlechrome"; foss = $false; category = "Browsers" }
    "Firefox"         = @{ choco = "firefox"; foss = $true; category = "Browsers" }
    "Tor Browser"     = @{ choco = "tor-browser"; foss = $true; category = "Browsers"; vpn = $true }
    "Vivaldi"         = @{ choco = "vivaldi.portable"; foss = $true; category = "Browsers" }
    
    # Communications
    "Discord"         = @{ choco = "discord.install"; foss = $false; category = "Communications"; vpn = $true }
    "Telegram"        = @{ choco = "telegram.install"; foss = $true; category = "Communications" }
    "Signal"          = @{ choco = "signal"; foss = $true; category = "Communications"; vpn = $true }
    "Zoom"            = @{ choco = "zoom"; foss = $false; category = "Communications" }
    "TeamSpeak"       = @{ choco = "teamspeak"; foss = $false; category = "Communications" }
    
    # Development
    "VS Code"         = @{ choco = "vscode.install"; foss = $true; category = "Development"; path = "C:\Program Files\Microsoft VS Code\bin" }
    "Git"             = @{ choco = "git.install"; foss = $true; category = "Development"; path = "C:\Program Files\Git\cmd" }
    "Python3"         = @{ choco = "python312"; foss = $true; category = "Development"; path = "C:\Python312;C:\Python312\Scripts" }
    "NodeJS LTS"      = @{ choco = "nodejs-lts"; foss = $true; category = "Development"; path = "C:\Program Files\nodejs" }
    "GitHub CLI"      = @{ choco = "gh"; foss = $true; category = "Development"; path = "C:\Program Files\GitHub CLI" }
    "MinGW (GCC)"     = @{ choco = "mingw"; foss = $true; category = "Development"; path = "C:\ProgramData\mingw64\mingw64\bin" }
    "Notepad++"       = @{ choco = "notepadplusplus.install"; foss = $true; category = "Development" }
    
    # Games
    "Steam"           = @{ choco = "steam"; foss = $false; category = "Games" }
    "Epic Games"      = @{ choco = "epicgameslauncher"; foss = $false; category = "Games" }
    "GOG Galaxy"      = @{ choco = "goggalaxy"; foss = $false; category = "Games" }
    
    # Microsoft Tools
    "PowerToys"       = @{ choco = "powertoys"; foss = $true; category = "Microsoft" }
    "Windows Terminal" = @{ choco = "microsoft-windows-terminal"; foss = $true; category = "Microsoft" }
    ".NET Desktop Runtime 8" = @{ choco = "dotnet-8.0-desktopruntime"; foss = $true; category = "Microsoft" }
    
    # Multimedia
    "VLC"             = @{ choco = "vlc.install"; foss = $true; category = "Multimedia" }
    "OBS Studio"      = @{ choco = "obs-studio.install"; foss = $true; category = "Multimedia" }
    "GIMP"            = @{ choco = "gimp"; foss = $true; category = "Multimedia" }
    "Blender"         = @{ choco = "blender"; foss = $true; category = "Multimedia" }
    
    # Utilities
    "7-Zip"           = @{ choco = "7zip.install"; foss = $true; category = "Utilities" }
    "WinRAR"          = @{ choco = "winrar"; foss = $false; category = "Utilities" }
    "Bitwarden"       = @{ choco = "bitwarden"; foss = $true; category = "Utilities" }
    "Rufus"           = @{ choco = "rufus"; foss = $true; category = "Utilities"; desktop = $true; exePath = "C:\ProgramData\chocolatey\lib\rufus\tools\rufus.exe" }
    "Everything"      = @{ choco = "everything"; foss = $false; category = "Utilities" }
    "ShareX"          = @{ choco = "sharex"; foss = $true; category = "Utilities" }
    "Wireshark"       = @{ choco = "wireshark"; foss = $true; category = "Utilities" }
    "PuTTY"           = @{ choco = "putty.install"; foss = $true; category = "Utilities" }
    "WinSCP"          = @{ choco = "winscp.install"; foss = $true; category = "Utilities" }
    "CPU-Z"           = @{ choco = "cpu-z.install"; foss = $false; category = "Utilities" }
    "HWiNFO"          = @{ choco = "hwinfo.install"; foss = $false; category = "Utilities" }
    "Revo Uninstaller" = @{ choco = "revo-uninstaller"; foss = $false; category = "Utilities" }
    "TreeSize Free"   = @{ choco = "treesizefree"; foss = $false; category = "Utilities" }
}

# Список программ для ручной загрузки (без чекбоксов, только ссылки)
# Что делает переменная: Хранит названия, URL-адреса и ключи перевода для программ, отсутствующих в Chocolatey.
$script:ManualDownloads = @{
    "CapCut" = @{
        Name = "CapCut"
        Url = "https://www.capcut.com/tools/desktop-video-editor"
        TranslationKey = "link_capcut"
    }
    "GeForce" = @{
        Name = "GeForce Experience"
        Url = "https://www.nvidia.com/en-us/geforce/geforce-experience/download/"
        TranslationKey = "link_geforce"
    }
}

# Соответствие категорий и ключей перевода
$script:CategoryNames = @{
    "Browsers"        = "cat_browsers"
    "Communications"  = "cat_communications"
    "Development"     = "cat_development"
    "Games"           = "cat_games"
    "Microsoft"       = "cat_microsoft"
    "Multimedia"      = "cat_multimedia"
    "Utilities"       = "cat_utilities"
}

# Иконки категорий
$script:CategoryIcons = @{
    "Browsers"        = "🌐"
    "Communications"  = "💬"
    "Development"     = "💻"
    "Games"           = "🎮"
    "Microsoft"       = "🔧"
    "Multimedia"      = "🎵"
    "Utilities"       = "🛠️"
}

# Порядок отображения категорий
$script:CategoryOrder = @(
    "Browsers", "Communications", "Development",
    "Games", "Microsoft", "Multimedia", "Utilities"
)

# Возвращает метаданные программы по её имени.
# Что делает функция: Ищет приложение в каталоге по ключу и возвращает его хеш-таблицу с настройками или $null, если не найдено.
function Get-AppInfo {
    param([string]$AppName)
    if ($script:AppCatalog.ContainsKey($AppName)) { return $script:AppCatalog[$AppName] }
    return $null
}