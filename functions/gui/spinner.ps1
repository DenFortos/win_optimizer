# functions/gui/spinner.ps1
# Управление спиннером прогресса по префиксу раздела ({Prefix}Progress, {Prefix}SpinnerEllipse, {Prefix}ProgressText)

$script:CurrentSpinnerPrefix = $null   # Префикс активного спиннера
$script:CurrentProgressKey = $null     # Ключ перевода активной операции

# Показывает/скрывает спиннер раздела, управляет анимацией и текстом операции
function Set-Spinner {
    param(
        [string]$Prefix,
        [bool]$Visible,
        [string]$ProgressKey
    )
    if (-not $script:MainWindow) { return }
    try {
        $progress = $script:MainWindow.FindName("$($Prefix)Progress")
        if (-not $progress) { return }
        
        $ellipse = $script:MainWindow.FindName("$($Prefix)SpinnerEllipse")
        if ($Visible) {
            if ($ProgressKey) { $script:CurrentProgressKey = $ProgressKey }
            $script:CurrentSpinnerPrefix = $Prefix
            $progressText = $script:MainWindow.FindName("$($Prefix)ProgressText")
            if ($progressText) {
                $key = if ($script:CurrentProgressKey) { $script:CurrentProgressKey } else { "install_progress" }
                $progressText.Text = Get-LocalizedString $key
            }
            $progress.Visibility = "Visible"
            if ($ellipse) {
                $sb = $ellipse.Parent.Resources["SpinnerStoryboard"]
                if ($sb) { $sb.Begin($ellipse, $true) }
            }
        } else {
            if ($ellipse) {
                $sb = $ellipse.Parent.Resources["SpinnerStoryboard"]
                if ($sb) { $sb.Stop($ellipse) }
            }
            $progress.Visibility = "Collapsed"
            if ($script:CurrentSpinnerPrefix -eq $Prefix) {
                $script:CurrentSpinnerPrefix = $null
                $script:CurrentProgressKey = $null
            }
        }
    }
    catch { Write-Log "Failed to toggle spinner ${Prefix}: $_" "WARNING" }
}