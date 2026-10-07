param([switch]$DarkTheme)

$ErrorActionPreference = 'Continue'
trap {
    Write-Host "`n❌ КРИТИЧЕСКАЯ ОШИБКА:" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Yellow
    Write-Host "`nСтек вызовов:" -ForegroundColor Cyan
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    Read-Host "`nНажми Enter для выхода"
    exit 1
}

$ErrorActionPreference = 'Stop'

# Определяем, запущены ли мы из файла или из RAM (iex)
$IsRunningFromFile = [bool]$PSCommandPath
$ScriptPath = if ($IsRunningFromFile) { $PSCommandPath } else { Join-Path $env:TEMP "win_optimizer_temp.ps1" }

# 1. ПРОВЕРКА ПРАВ АДМИНИСТРАТОРА
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Если запущены из RAM — сохраняем скрипт во временный файл
    if (-not $IsRunningFromFile) {
        Write-Host "Сохранение во временный файл для запроса прав..." -ForegroundColor Cyan
        try {
            # Сохраняем весь текущий скрипт во временный файл (через MyInvocation)
            $scriptContent = $MyInvocation.MyCommand.ScriptBlock.Ast.Extent.Text
            [System.IO.File]::WriteAllText($ScriptPath, $scriptContent, [System.Text.Encoding]::UTF8)
        } catch {
            Write-Host "❌ Не удалось сохранить скрипт: $_" -ForegroundColor Red
            Read-Host "Нажми Enter для выхода"
            exit 1
        }
    }
    
    # Перезапуск от админа
    $argList = "-STA -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
    if ($DarkTheme) { $argList += " -DarkTheme" }
    Start-Process powershell.exe -Verb RunAs -WindowStyle Normal -ArgumentList $argList
    
    # Если это временный файл — удаляем его после запуска нового процесса
    if (-not $IsRunningFromFile) {
        Start-Sleep -Seconds 2
        Remove-Item $ScriptPath -Force -ErrorAction SilentlyContinue
    }
    exit
}

# 2. ПРОВЕРКА STA-РЕЖИМА (уже с правами админа)
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    $argList = "-STA -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
    if ($DarkTheme) { $argList += " -DarkTheme" }
    Start-Process powershell.exe -WindowStyle Normal -ArgumentList $argList
    exit
}

# Корень проекта
if (-not $ProjectRoot) { 
    $ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { $env:TEMP }
}

# Кастомный загрузчик
if (Get-Command -Name Start-CustomDownloads -ErrorAction SilentlyContinue) {
    Start-CustomDownloads
}

# Загрузка WPF
try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $Window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Host "❌ Не удалось загрузить интерфейс: $_" -ForegroundColor Red
    Read-Host "Нажми Enter для выхода"
    exit 1
}

$script:MainWindow = $Window
$script:IsInitializing = $true

# Построение панелей
foreach ($buildFunc in @("Build-CategoriesPanel", "Build-TweaksPanel", "Build-OptimizationPanel")) {
    if (Get-Command -Name $buildFunc -ErrorAction SilentlyContinue) {
        & $buildFunc -Window $Window
    }
}

# Локализация и обработчики
Apply-Localization -Window $Window
Initialize-UIHandlers -Window $Window
Initialize-TabHandlers -Window $Window

$script:IsInitializing = $false

# Тема
$themeName = if ($DarkTheme) { "dark" } else { "light" }
Set-Theme -ThemeName $themeName -Window $Window
$script:IsDarkTheme = [bool]$DarkTheme
Update-ThemeButton -Window $Window

# Очистка временного файла после закрытия окна (если запускались из RAM)
$Window.Add_Closed({
    if (-not $script:IsRunningFromFile -and (Test-Path $script:ScriptPath)) {
        Remove-Item $script:ScriptPath -Force -ErrorAction SilentlyContinue
    }
})

# Запуск окна
$Window.ShowDialog() | Out-Null

# Финальная очистка временного файла
if (-not $IsRunningFromFile -and (Test-Path $ScriptPath)) {
    Remove-Item $ScriptPath -Force -ErrorAction SilentlyContinue
}