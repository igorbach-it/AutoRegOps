# Создаем функцию логирования
function WriteLog {
    Param ([string]$LogString)

    $Stamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-Content $LogFile -Value $LogMessage
    Write-Host $LogMessage
}
$regDate = Get-Date -Format "dd/MM/yyyy"
New-Item -ErrorAction Ignore -ItemType directory -Path "C:\Scripts\RegOps\Log_$regDate"
$LogFile = "C:\Scripts\RegOps\Log_$regDate\RegOps.log" # Файл логирования
Set-ExecutionPolicy RemoteSigned -Force
# Проверка и запуск службы обновления Windows
$windowsUpdateService = Get-Service -Name wuauserv
if ($windowsUpdateService.Status -ne "Running") {
    WriteLog "Запуск службы обновления Windows(Script After Reboot)"
    Start-Service -Name wuauserv
} else {
    WriteLog "Служба обновления Windows уже запущена(Script After Reboot)"
}

# Установка модуля PackageManagement, если отсутствует
if (-not (Get-Module -ListAvailable -Name PackageManagement)) {
    WriteLog "Установка модуля PackageManagement(Script After Reboot)"
    Install-Module -Name PackageManagement -Force -Scope CurrentUser
} else {
    WriteLog "Модуль PackageManagement уже установлен(Script After Reboot)"
}

# Проверка и установка модуля PSWindowsUpdate
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    WriteLog "Установка модуля PSWindowsUpdate(Script After Reboot)"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser
} else {
    WriteLog "Модуль PSWindowsUpdate уже установлен(Script After Reboot)"
}

# Задержка перед установкой обновлений (если это необходимо)
Start-Sleep -Seconds 20

# Установка обновлений Windows
$UpdateLogPath = "C:\Scripts\RegOps\Log_$regDate\WindowsUpdate_Temp_AfterReboot.log"
WriteLog "Установка обновлений Windows(Script After Reboot)"
Install-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-File -FilePath $UpdateLogPath -Force
WriteLog "Установка обновлений завершена(Script After Reboot)"



      $files = dir C:\Scripts\RegOps\Log_$regDate\WindowsUpdate_Temp_AfterReboot.log
if ($files -ne $null)
{
   WriteLog "Новые обновления найдены и установлены(Script After Reboot)”
}
else
{
   WriteLog "Новых обновлений не найдено(Script After Reboot)”
}

Unregister-ScheduledTask -TaskName "update_windows_after_reboot" -Confirm:$false

# Проверка наличия файла с учетными данными
if (Test-Path -Path "C:\Scripts\RegOps\creds.enc") {

$PSEmailServer = 'smtp.mail.ru'
$client = $env:computername
# Путь к файлу с зашифрованными данными
$encryptedFilePath = "C:\Scripts\RegOps\creds.enc"

$reportRegOps = "C:\Scripts\RegOps\Log_$regDate"
#$cred = Import-Clixml -Path $encryptedFilePath
$credsAndRecipient = Import-Clixml -Path "C:\Scripts\RegOps\creds.enc"
# Извлечение учетных данных и адреса получателя
$cred = $credsAndRecipient.Credential
$toAddress = $credsAndRecipient.Recipient

New-Item -ErrorAction Ignore -ItemType directory -Path "C:\Scripts\RegOps\Log_$regDate"
Compress-Archive -Path $reportRegOps  -DestinationPath  C:\Scripts\RegOps\Log_$regDate\$client-$regDate.zip -CompressionLevel Optimal -Force
$attachments = "C:\Scripts\RegOps\Log_$regDate\$client-$regDate.zip"

Start-Sleep -Seconds 5

# Попытка отправки почты
Send-MailMessage -Port 587 `
     -From "$client <regops@efsol.ru>" `
     -To $toAddress `
     -Subject "Отчет Регламентные Операции $client" `
     -Body "Отчет Регламентные Операции $client" `
     -UseSsl `
     -Credential $cred `
     -Encoding 'UTF8' `
     -Attachments $attachments

     WriteLog "Отчет отправлен на адрес $toAddress”
} else {
    # Вывод сообщения об отсутствии файла и выход из скрипта
     WriteLog "Файл C:\Scripts\RegOps\creds.enc не найден. Отчет не будет отправлен."
}