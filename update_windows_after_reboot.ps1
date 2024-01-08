
# Создаем функцию логирования
function WriteLog {
    Param ([string]$LogString)

    $Stamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-Content $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

$LogFile = "C:\Scripts\windows_update.log" # Файл логирования
Set-ExecutionPolicy RemoteSigned -Force
# Проверка и запуск службы обновления Windows
$windowsUpdateService = Get-Service -Name wuauserv
if ($windowsUpdateService.Status -ne "Running") {
    WriteLog "Запуск службы обновления Windows(After)"
    Start-Service -Name wuauserv
} else {
    WriteLog "Служба обновления Windows уже запущена(After)"
}

# Установка модуля PackageManagement, если отсутствует
if (-not (Get-Module -ListAvailable -Name PackageManagement)) {
    WriteLog "Установка модуля PackageManagement(After)"
    Install-Module -Name PackageManagement -Force -Scope CurrentUser
} else {
    WriteLog "Модуль PackageManagement уже установлен(After)"
}

# Проверка и установка модуля PSWindowsUpdate
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    WriteLog "Установка модуля PSWindowsUpdate(After)"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser
} else {
    WriteLog "Модуль PSWindowsUpdate уже установлен(After)"
}

# Задержка перед установкой обновлений (если это необходимо)
Start-Sleep -Seconds 30

# Установка обновлений Windows
$UpdateLogPath = "C:\Scripts\WindowsUpdate_Temp_AfterReboot.log"
WriteLog "Установка обновлений Windows(After)"
Install-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-File -FilePath $UpdateLogPath -Force
WriteLog "Установка обновлений завершена(After)"



      $files = dir C:\Scripts\WindowsUpdate_Temp_AfterReboot.log
if ($files -ne $null)
{
   WriteLog "обновление windows завершено - OK(After)”
}
else
{
   WriteLog "обновление windows завершено - FAIL(After)”
}

Unregister-ScheduledTask -TaskName "update_windows_after_reboot" -Confirm:$false
$wshell = New-Object -ComObject Wscript.Shell
$Output = $wshell.Popup("Обновление завершено",0,"Обновление windows")