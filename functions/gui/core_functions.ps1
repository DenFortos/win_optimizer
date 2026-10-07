# functions/gui/core_functions.ps1
# Базовые функции логирования и проверки прав администратора

# Таблица цветов для уровней логирования
$script:LogColors = @{
    "INFO"    = "White"
    "SUCCESS" = "Green"
    "WARNING" = "Yellow"
    "ERROR"   = "Red"
    "DEBUG"   = "Gray"
}

# Выводит сообщение в консоль с таймстампом и цветом по уровню
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $color = $script:LogColors[$Level]
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Проверяет, запущен ли скрипт с правами администратора
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Запрашивает права администратора (legacy - теперь логика в main.ps1)
function Request-Admin {
    if (Test-Admin) { return }
    Write-Log "Request-Admin called but admin check is now in main.ps1" "WARNING"
}