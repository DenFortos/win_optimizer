# functions/gui/main_window.ps1
# Инициализация обработчиков событий окна

$script:MainWindow = $null            # Ссылка на главное окно WPF
$script:InstallTimer = $null          # Таймер мониторинга установки
$script:TweaksTimer = $null           # Таймер мониторинга применения твиков
$script:OptimizationTimer = $null     # Таймер мониторинга применения оптимизаций

# Инициализирует обработчики всех зон UI (шапка, поиск, контент)
function Initialize-UIHandlers {
    param([object]$Window)
    
    if (-not $Window) {
        Write-Log "Window is null, cannot initialize UI handlers" "ERROR"
        return
    }
    
    $script:MainWindow = $Window
    
    Initialize-HeaderHandlers -Window $Window
    Initialize-SearchHandlers -Window $Window
    Initialize-ContentHandlers -Window $Window
}

# Подключает обработчики кнопок действий для всех вкладок
function Initialize-ContentHandlers {
    param([object]$Window)
    
    $btnInstall = $Window.FindName("BtnInstall")
    $btnOpenAppwiz = $Window.FindName("BtnOpenAppwiz")
    $btnClearSelection = $Window.FindName("BtnClearSelection")
    $btnApplyTweaks = $Window.FindName("BtnApplyTweaks")
    $btnClearTweaks = $Window.FindName("BtnClearTweaks")
    $btnApplyOptimization = $Window.FindName("BtnApplyOptimization")
    $btnOpenCleanMgr = $Window.FindName("BtnOpenCleanMgr")
    $btnClearOptimization = $Window.FindName("BtnClearOptimization")
    
    # Установка выбранных программ через Chocolatey
    if ($btnInstall) {
        $btnInstall.Add_Click({
            if ($script:InstallJob -and $script:InstallJob.PowerShell) { return }
            
            $selectedApps = Get-SelectedApps -Window $script:MainWindow
            if ($selectedApps.Count -eq 0) { return }
            
            Set-InstallUILocked -Locked $true
            Set-Spinner -Prefix "Install" -Visible $true -ProgressKey "install_progress"
            Install-ChocoPrograms -AppNames $selectedApps
            
            if (-not $script:InstallJob -or -not $script:InstallJob.PowerShell) {
                Set-Spinner -Prefix "Install" -Visible $false
                Set-InstallUILocked -Locked $false
                return
            }
            
            if ($script:InstallTimer) { try { $script:InstallTimer.Stop() } catch {} }
            
            $script:InstallTimer = New-Object System.Windows.Threading.DispatcherTimer
            $script:InstallTimer.Interval = [TimeSpan]::FromMilliseconds(500)
            $script:InstallTimer.Add_Tick({
                $job = $script:InstallJob
                if (-not $job -or -not $job.PowerShell -or -not $job.AsyncResult) { $this.Stop(); return }
                
                if ($job.AsyncResult.IsCompleted) {
                    $this.Stop()
                    $exitCode = 1
                    try {
                        $job.PowerShell.EndInvoke($job.AsyncResult) | Out-Null
                        if ($job.ResultHash -and $null -ne $job.ResultHash.ExitCode) {
                            $exitCode = [int]$job.ResultHash.ExitCode
                        }
                    } catch {}
                    
                    try { $job.PowerShell.Dispose(); $job.Runspace.Close(); $job.Runspace.Dispose() } catch {}
                    $script:InstallJob = $null
                    
                    Set-Spinner -Prefix "Install" -Visible $false
                    Clear-AllSelections -Window $script:MainWindow
                    Update-SelectedCount
                    Show-InstallResult -Success ($exitCode -eq 0) -ExitCode $exitCode
                    Set-InstallUILocked -Locked $false
                }
            })
            $script:InstallTimer.Start()
        })
    }
    
    # Открытие системного апплета «Программы и компоненты»
    if ($btnOpenAppwiz) {
        $btnOpenAppwiz.Add_Click({
            try {
                Start-Process "appwiz.cpl"
            }
            catch {
                Write-Log "Failed to open appwiz.cpl: $_" "ERROR"
            }
        })
    }
    
    # Сброс всех галочек во вкладке Install
    if ($btnClearSelection) {
        $btnClearSelection.Add_Click({
            Clear-AllSelections -Window $script:MainWindow
            Update-SelectedCount
        })
    }
    
    # Применение твиков Debloat
    if ($btnApplyTweaks) {
        $btnApplyTweaks.Add_Click({
            if ($script:TweaksJob -and $script:TweaksJob.PowerShell) { return }
            
            $selectedTweaks = Get-SelectedTweaks -Window $script:MainWindow
            if ($selectedTweaks.Count -eq 0) { return }
            
            Set-TweaksUILocked -Locked $true
            Set-Spinner -Prefix "Tweaks" -Visible $true -ProgressKey "tweaks_progress"
            
            $selectedTags = $selectedTweaks | ForEach-Object { $_.Tag }
            Apply-Debloat -SelectedTags $selectedTags
            
            if (-not $script:TweaksJob -or -not $script:TweaksJob.PowerShell) {
                Set-Spinner -Prefix "Tweaks" -Visible $false
                Set-TweaksUILocked -Locked $false
                return
            }
            
            if ($script:TweaksTimer) { try { $script:TweaksTimer.Stop() } catch {} }
            
            $script:TweaksTimer = New-Object System.Windows.Threading.DispatcherTimer
            $script:TweaksTimer.Interval = [TimeSpan]::FromMilliseconds(500)
            $script:TweaksTimer.Add_Tick({
                $job = $script:TweaksJob
                if (-not $job -or -not $job.PowerShell -or -not $job.AsyncResult) { $this.Stop(); return }
                
                if ($job.AsyncResult.IsCompleted) {
                    $this.Stop()
                    $successCount = 0; $failedCount = 0
                    try {
                        $job.PowerShell.EndInvoke($job.AsyncResult) | Out-Null
                        if ($job.ResultHash) {
                            $successCount = [int]$job.ResultHash.Success
                            $failedCount = [int]$job.ResultHash.Failed
                        }
                    } catch { $failedCount = 1 }
                    
                    try { $job.PowerShell.Dispose(); $job.Runspace.Close(); $job.Runspace.Dispose() } catch {}
                    $script:TweaksJob = $null
                    
                    Set-Spinner -Prefix "Tweaks" -Visible $false
                    Clear-TweaksSelections -Window $script:MainWindow
                    Update-TweaksCount
                    Show-TweaksResult -SuccessCount $successCount -FailedCount $failedCount
                    Set-TweaksUILocked -Locked $false
                }
            })
            $script:TweaksTimer.Start()
        })
    }
    
    # Сброс всех галочек во вкладке Debloat
    if ($btnClearTweaks) {
        $btnClearTweaks.Add_Click({
            Clear-TweaksSelections -Window $script:MainWindow
            Update-TweaksCount
        })
    }
    
    # Применение системных оптимизаций
    if ($btnApplyOptimization) {
        $btnApplyOptimization.Add_Click({
            if ($script:OptimizationJob -and $script:OptimizationJob.PowerShell) { return }
            
            $selectedOptimizations = Get-SelectedOptimizations -Window $script:MainWindow
            if ($selectedOptimizations.Count -eq 0) { return }
            
            Set-OptimizationUILocked -Locked $true
            Apply-Optimizations -SelectedFunctions $selectedOptimizations
            
            if (-not $script:OptimizationJob -or -not $script:OptimizationJob.PowerShell) {
                Set-OptimizationUILocked -Locked $false
                return
            }
            
            if ($script:OptimizationTimer) { try { $script:OptimizationTimer.Stop() } catch {} }
            
            $script:OptimizationTimer = New-Object System.Windows.Threading.DispatcherTimer
            $script:OptimizationTimer.Interval = [TimeSpan]::FromMilliseconds(500)
            $script:OptimizationTimer.Add_Tick({
                $job = $script:OptimizationJob
                if (-not $job -or -not $job.PowerShell -or -not $job.AsyncResult) { $this.Stop(); return }
                
                if ($job.AsyncResult.IsCompleted) {
                    $this.Stop()
                    $successCount = 0; $failedCount = 0
                    try {
                        $job.PowerShell.EndInvoke($job.AsyncResult) | Out-Null
                        if ($job.ResultHash) {
                            $successCount = [int]$job.ResultHash.Success
                            $failedCount = [int]$job.ResultHash.Failed
                        }
                    } catch { $failedCount = 1 }
                    
                    try { $job.PowerShell.Dispose(); $job.Runspace.Close(); $job.Runspace.Dispose() } catch {}
                    $script:OptimizationJob = $null
                    
                    Clear-OptimizationsSelections -Window $script:MainWindow
                    Update-OptimizationCount
                    Show-OptimizationResult -SuccessCount $successCount -FailedCount $failedCount
                    Set-OptimizationUILocked -Locked $false
                }
            })
            $script:OptimizationTimer.Start()
        })
    }
    
    # Запуск встроенной утилиты очистки диска
    if ($btnOpenCleanMgr) {
        $btnOpenCleanMgr.Add_Click({
            try {
                Start-Process "cleanmgr.exe"
            }
            catch {
                Write-Log "Failed to open cleanmgr.exe: $_" "ERROR"
            }
        })
    }
    
    # Сброс всех галочек во вкладке Optimization
    if ($btnClearOptimization) {
        $btnClearOptimization.Add_Click({
            Clear-OptimizationsSelections -Window $script:MainWindow
            Update-OptimizationCount
        })
    }
}

# Применяет переводы к заголовкам категорий и чекбоксам «Выбрать всё» панели
function Apply-TranslationsToPanel {
    param(
        [hashtable]$HeadersStorage,
        [string]$PanelPrefix
    )
    
    # Заголовки категорий
    if ($HeadersStorage) {
        foreach ($catKey in $HeadersStorage.Keys) {
            $info = $HeadersStorage[$catKey]
            if ($info -and $info.Control -and $info.TranslationKey) {
                $translated = Get-LocalizedString $info.TranslationKey -Fallback $info.DisplayName
                $fullText = if ($info.Icon) { "$($info.Icon) $translated" } else { $translated }
                $info.Control.Text = $fullText
                $info.Control.FontFamily = "Segoe UI Emoji, Segoe UI"
            }
        }
    }
    
    # Чекбоксы «Выбрать всё»
    if ($script:SelectAllHeaders) {
        $selectAllText = Get-LocalizedString "select_all" -Fallback "Select All"
        foreach ($key in $script:SelectAllHeaders.Keys) {
            if ($key -like "${PanelPrefix}*") {
                $ctrl = $script:SelectAllHeaders[$key]
                if ($ctrl) { $ctrl.Content = $selectAllText }
            }
        }
    }
}

# Подключает обработчик переключения вкладок для перестройки панелей
function Initialize-TabHandlers {
    param([object]$Window)
    
    $tabControl = $Window.FindName("MainTabControl")
    if (-not $tabControl) { return }
    
    $tabControl.Add_SelectionChanged({
        param($sender, $eventArgs)
        
        if ($script:IsInitializing) { return }
        
        $selectedTab = $sender.SelectedItem
        if (-not $selectedTab) { return }
        
        # Перестроение панели активной вкладки
        if ($selectedTab.Name -eq "OptimizationTab") {
            Build-OptimizationPanel -Window $script:MainWindow
            Apply-TranslationsToPanel -HeadersStorage $script:OptimizationItemHeaders -PanelPrefix "OptimizationCategoriesPanel"
            
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
        }
        
        if ($selectedTab.Name -eq "InstallTab") {
            Build-CategoriesPanel -Window $script:MainWindow
            Apply-TranslationsToPanel -HeadersStorage $script:CategoryHeaders -PanelPrefix "CategoriesPanel"
        }
        
        if ($selectedTab.Name -eq "TweaksTab") {
            Build-TweaksPanel -Window $script:MainWindow
            Apply-TranslationsToPanel -HeadersStorage $script:TweakItemHeaders -PanelPrefix "TweaksCategoriesPanel"
        }
        
        if ($selectedTab.Name -eq "GuideTab") {
            Build-GuidePanel -Window $script:MainWindow
        }
    })
}