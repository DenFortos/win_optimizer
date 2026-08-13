@echo off
title Windows Optimizer Launcher

:: 1. Запрос прав администратора (UAC)
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0'"
    exit /b
)

:: 2. Снятие блокировки "Скачано из интернета" (Mark of the Web)
powershell -NoProfile -Command "Unblock-File -Path '%~dp0win_optimizer.ps1'" >nul 2>&1

:: 3. Запуск скрипта в обход ExecutionPolicy
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0win_optimizer.ps1" %*