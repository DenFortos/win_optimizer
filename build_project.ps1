# build_project.ps1

# Сборщик: объединяет модули и XAML в единый optimizer.ps1

# Чтение конфигурации сборки
$configPath = Join-Path $PSScriptRoot "configuration/config.json"
$config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Путь к выходному файлу
$outputFile = $config.build.output_file
if ($config.build.output_path -eq ".") {
    $outputPath = Join-Path $PSScriptRoot $outputFile
} else {
    $outputPath = Join-Path $PSScriptRoot (Join-Path $config.build.output_path $outputFile)
}

# UTF-8 с BOM — для корректной работы PowerShell 5.1 при локальном запуске
$encoding = New-Object System.Text.UTF8Encoding $true

Write-Host "Building $($config.project.name) v$($config.project.version)..." -ForegroundColor Cyan
Write-Host "Output: $outputPath" -ForegroundColor Gray

# Заголовок с датой сборки
$header = $config.build.header_comment -replace '\{date\}', (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$output = ""
foreach ($line in $header -split "`n") { $output += "# $line`n" }
$output += "`n"

# Стандартные параметры и корень проекта
$output += @"
param([switch]`$DarkTheme)

`$ProjectRoot = if (`$PSScriptRoot) { `$PSScriptRoot } else { `$env:TEMP }

"@

# Встраивание конфигурационных JSON для автономной работы
$embeddedConfigs = @(
    @{ Var = "EmbeddedTranslationsJson"; File = "configuration/translations.json" }
    @{ Var = "EmbeddedThemesJson";       File = "configuration/themes.json" }
    @{ Var = "EmbeddedSettingsJson";     File = "configuration/settings.json" }
)

$output += "# === Embedded configuration (autonomous mode) ===`n"
foreach ($cfg in $embeddedConfigs) {
    $cfgPath = Join-Path $PSScriptRoot $cfg.File
    if (Test-Path $cfgPath) {
        $jsonContent = (Get-Content $cfgPath -Raw -Encoding UTF8).TrimStart([char]0xFEFF).TrimEnd()
        $output += '$script:' + $cfg.Var + " = @'" + "`n"
        $output += $jsonContent + "`n"
        $output += "'@" + "`n`n"
        Write-Host "  Embedded: $($cfg.File)" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: $($cfg.File) not found, skipping embed" -ForegroundColor Yellow
    }
}
$output += "`n"

# Обработка модулей из modules_order
foreach ($module in $config.build.modules_order) {
    $fullPath = Join-Path $PSScriptRoot $module
    
    if (-not (Test-Path $fullPath)) {
        Write-Host "  WARNING: $module not found!" -ForegroundColor Yellow
        continue
    }
    
    # Перед main.ps1 вставляет XAML со всеми include
    if ($module -eq "main.ps1") {
        $xamlPath = Join-Path $PSScriptRoot $config.build.xaml_file
        
        if (Test-Path $xamlPath) {
            $xamlContent = Get-Content $xamlPath -Raw -Encoding UTF8
            $xamlDir = Split-Path $xamlPath
            
            # Раскрытие INCLUDE-маркеров в содержимом файлов
            foreach ($match in [regex]::Matches($xamlContent, '<!--\s*INCLUDE:\s*([^\s>]+)\s*-->')) {
                $includePath = Join-Path $xamlDir $match.Groups[1].Value
                if (Test-Path $includePath) {
                    $xamlContent = $xamlContent -replace [regex]::Escape($match.Value), (Get-Content $includePath -Raw -Encoding UTF8)
                    Write-Host "    Including: $($match.Groups[1].Value)" -ForegroundColor Green
                } else {
                    Write-Host "    WARNING: Include not found: $($match.Groups[1].Value)" -ForegroundColor Yellow
                }
            }
            
            # Обёртка XAML в here-string для runtime
            $output += @"

# Load XAML
`$xaml = @'
$xamlContent
'@

"@
            Write-Host "  Added: $($config.build.xaml_file)" -ForegroundColor Green
        } else {
            Write-Host "  ERROR: XAML file not found at: $xamlPath" -ForegroundColor Red
        }
    }
    
    # Чтение содержимого модуля
    $content = Get-Content $fullPath -Raw -Encoding UTF8
    
    # Удаление param() из main.ps1 (уже есть в заголовке)
    if ($config.build.remove_param_from_main -and $module -eq "main.ps1") {
        $content = $content -replace '(?s)^.*?param\s*\([^)]*\)\s*', ''
    }
    
    # Добавление модуля в итоговый файл
    $output += "`n# === $module ===`n$content`n"
    Write-Host "  Adding: $module" -ForegroundColor Green
}

# Запись итогового optimizer.ps1
[System.IO.File]::WriteAllText($outputPath, $output, $encoding)

# Статистика сборки
$fileSize = [math]::Round((Get-Item $outputPath).Length / 1KB, 2)
Write-Host ''
Write-Host ('Build complete: ' + $outputPath) -ForegroundColor Green
Write-Host ('File size: ' + $fileSize + ' KB') -ForegroundColor Gray


# ============================================================================
# УПАКОВКА В АРХИВ ДЛЯ РЕЛИЗА
# ============================================================================
$releaseDir   = Join-Path $PSScriptRoot "release"
$packageDir   = Join-Path $releaseDir "win_optimizer"
$zipName      = "win_optimizer_v$($config.project.version).zip"
$zipPath      = Join-Path $releaseDir $zipName

# Очищаем предыдущую сборку
if (Test-Path $releaseDir) { Remove-Item $releaseDir -Recurse -Force }

# Создаём структуру папки внутри архива
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null

# Копируем собранный .ps1 в подпапку
Copy-Item $outputPath -Destination $packageDir -Force

# Генерируем .bat лаунчер (снимающий MOTW и запрашивающий UAC)
$batContent = @"
@echo off
title Windows Optimizer Launcher

:: 1. Запрос прав администратора (UAC)
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0'"
    exit /b
)

:: 2. Снятие блокировки "Скачано из интернета" (Mark of the Web)
powershell -NoProfile -Command "Unblock-File -Path '%~dp0win_optimizer.ps1'" >nul 2>&1

:: 3. Запуск скрипта в обход ExecutionPolicy
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0win_optimizer.ps1" %*
"@
$batPath = Join-Path $packageDir "win_optimizer.bat"
# Записываем bat в ANSI (Default), чтобы cmd.exe не сломался
[System.IO.File]::WriteAllText($batPath, $batContent, [System.Text.Encoding]::Default)

# Создаём ZIP-архив
Compress-Archive -Path $packageDir -DestinationPath $zipPath -Force

# Удаляем временную подпапку, оставляя только готовый ZIP и сам .ps1 в корне
Remove-Item $packageDir -Recurse -Force

# Статистика архива
$zipSize = [math]::Round((Get-Item $zipPath).Length / 1KB, 2)
Write-Host ''
Write-Host ('Package created: ' + $zipPath) -ForegroundColor Green
Write-Host ('Archive size: ' + $zipSize + ' KB') -ForegroundColor Gray