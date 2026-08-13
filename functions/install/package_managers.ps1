# functions/install/package_managers.ps1
# Управление Chocolatey: проверка, установка, восстановление

# Стандартные пути Chocolatey
$script:ChocoExePath = "C:\ProgramData\chocolatey\bin\choco.exe"
$script:ChocoBinPath = "C:\ProgramData\chocolatey\bin"

# Проверяет наличие choco.exe в системе
function Test-ChocolateyInstalled {
    if (Test-Path $script:ChocoExePath) { return $true }
    return [bool](Get-Command choco -ErrorAction SilentlyContinue)
}

# Проверяет работоспособность Chocolatey командой --version
function Test-ChocolateyIntegrity {
    if (-not (Test-Path $script:ChocoExePath)) { return $false }
    try {
        $null = & $script:ChocoExePath --version 2>$null
        return $LASTEXITCODE -eq 0
    } catch { return $false }
}

# Устанавливает Chocolatey через официальный скрипт
function Install-Chocolatey {
    Write-Log "Installing Chocolatey..." "INFO"
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        if ($env:PATH -notlike "*$($script:ChocoBinPath)*") { $env:PATH += ";$($script:ChocoBinPath)" }
        
        if (Test-ChocolateyInstalled) {
            Write-Log "Chocolatey installed successfully" "SUCCESS"
            return $true
        }
        Write-Log "Chocolatey installation failed" "ERROR"
        return $false
    } catch {
        Write-Log "Error installing Chocolatey: $_" "ERROR"
        return $false
    }
}

# Восстанавливает повреждённый Chocolatey переустановкой
function Repair-Chocolatey {
    Write-Log "Repairing Chocolatey..." "WARNING"
    return Install-Chocolatey
}

# Гарантирует наличие рабочего Chocolatey: проверка → восстановление → установка
function Ensure-Chocolatey {
    if (Test-ChocolateyIntegrity) { return $true }
    if (Test-ChocolateyInstalled) {
        Write-Log "Chocolatey needs repair, reinstalling..." "WARNING"
        return Repair-Chocolatey
    }
    Write-Log "Chocolatey not found, installing..." "WARNING"
    return Install-Chocolatey
}