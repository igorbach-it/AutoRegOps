﻿Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# Создаем функцию логирования
function WriteLog {
    Param ([string]$LogString)

    $Stamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-Content $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

$LogFile = "C:\Scripts\windows_update.log" # Файл логирования

WriteLog "Начало выполнения скрипта"

# Проверяем существование необходимых файлов и папок
$requiredPaths = @("C:\Scripts\update_windows_after_reboot.bat", "C:\Scripts\KVRT", "C:\Scripts")
foreach ($path in $requiredPaths) {
    if (-not (Test-Path $path)) {
        WriteLog "Не найден путь $path, создание..."
        New-Item -ItemType Directory -Path $path -ErrorAction SilentlyContinue | Out-Null
    }
}

$Trigger = New-ScheduledTaskTrigger -AtStartup
$User = "NT AUTHORITY\SYSTEM"
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "C:\Scripts\update_windows_after_reboot.bat"
Register-ScheduledTask -TaskName "update_windows_after_reboot" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force

WriteLog "Скрипт на обновления после перезагрузки добавлен"
WriteLog "--------------------------------"

# Определите список папок для удаления для каждого профиля пользователя
$foldersToDelete = @(
    "Local\Temp"
#    "Local\Temporary Internet Files\Content.IE5",
#    "Local\Temporary Internet Files\Content.MSO",
#    "Local\Temporary Internet Files",
#    "Local\Application Data\Mozilla\Firefox\Profiles",
#    "\ocal Settings\Google\Chrome\User Data\Default\Cache"
)

# Получите список всех профилей пользователей, исключая системные аккаунты
$userProfiles = Get-ChildItem C:\Users -Directory | Where-Object { $_.Name -notin @("Public", "Default", "Default User", "All Users", "localservice", "networkservice", ".NET v4.5") }

foreach ($profile in $userProfiles) {
    # Получите полный путь к папке Temp каждого пользователя
    $tempPath = Join-Path -Path $profile.FullName -ChildPath "AppData\Local\Temp"

    if (Test-Path $tempPath) {
        WriteLog "Удаление содержимого $tempPath"
        # Удаление всех файлов и поддиректорий внутри Temp, но не саму директорию Temp
        Get-ChildItem -Path $tempPath -Recurse | ForEach-Object {
            Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    } else {
        WriteLog "Папка Temp не найдена: $tempPath"
    }
}

WriteLog "Чистка временных файлов завершена"

WriteLog "--------------------------------"

# Проверка, установлен ли IIS
$IisInstalled = Get-WindowsFeature -Name Web-Server
if ($IisInstalled.Installed) {
    # Проверка, запущена ли служба IIS
    $iisService = Get-Service -Name W3SVC
    if ($iisService.Status -eq 'Running') {
        # Служба IIS запущена, выполнение скрипта очистки логов

        $files = Get-ChildItem 'C:\inetpub\logs' -Include '*.log' -Recurse | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }

        if ($files) {
            $files | Remove-Item -ErrorAction SilentlyContinue
            $deletedFiles = $files | Where-Object { -not (Test-Path $_.FullName) }

            if ($deletedFiles) {
                WriteLog "Чистка логов IIS завершена - OK"
            } else {
                WriteLog "Чистка логов IIS завершена - FAIL"
            }
        } else {
            WriteLog "Нет файлов для удаления"
        }

    } else {
        WriteLog "Служба IIS не запущена"
    }
} else {
    WriteLog "IIS не установлен"
}


$KVRTPath = "C:\Scripts\KVRT"

WriteLog "Создаем директории C:\Scripts\KVR"
New-Item -ErrorAction Ignore -ItemType directory -Path $KVRTPath
New-Item -ErrorAction Ignore -ItemType directory -Path "$KVRTPath\UU"


$KVRTurl = "http://devbuilds.kaspersky-labs.com/devbuilds/KVRT/latest/full/KVRT.exe"
WriteLog "Загружаем Kaspersky Virus Removal Tool из: $KVRTurl"
Invoke-WebRequest -URI $KVRTurl -UseBasicParsing -OutFile "$KVRTPath\KVRT.exe"

$files = Get-ChildItem "$KVRTPath\*.exe"
if ($files -ne $null) {
    WriteLog "Антивирус скачан - OK"
} else {
    WriteLog "Антивирус скачан - FAIL"
}

$scannowDate = Get-Date -Format "yyyyMMdd"
New-Item -ErrorAction Ignore -ItemType directory -Path "$KVRTPath\$scannowDate"
WriteLog "Запускаем сканирование ..."
$resultScan = & "$KVRTPath\KVRT.exe" -d "$KVRTPath\$scannowDate" -accepteula -silent -processlevel 1 -dontencrypt | Out-Null
Remove-Item "$KVRTPath\KVRT.exe"

$files = Get-ChildItem "$KVRTPath\$scannowDate\Reports"
if ($files -ne $null) {
    WriteLog "Антивирус завершил сканирование, результаты можно посмотреть $KVRTPath\$scannowDate\Reports - OK"
} else {
    WriteLog "Антивирус завершил сканирование, результаты можно посмотреть $KVRTPath\$scannowDate\Reports - FAIL"
}

# Получение информации о службе обновления Windows
$windowsUpdateService = Get-Service -Name wuauserv

# Проверка, не установлен ли тип запуска службы как "Disabled"
if ((Get-WmiObject -Class Win32_Service -Filter "Name='wuauserv'").StartMode -eq "Disabled") {
    WriteLog "Изменение типа запуска службы обновления Windows на 'Manual'"
    # Изменение типа запуска на "Manual"
    Set-Service -Name wuauserv -StartupType Manual
}

# Проверка статуса службы
if ($windowsUpdateService.Status -ne "Running") {
    WriteLog "Запуск службы обновления Windows"
    # Запуск службы
    Start-Service -Name wuauserv
} else {
    WriteLog "Служба обновления Windows уже запущена"
}



# Установка модуля PackageManagement, если отсутствует
if (-not (Get-Module -ListAvailable -Name PackageManagement)) {
    WriteLog "Установка модуля PackageManagement"
    Install-Module -Name PackageManagement -Force -Scope CurrentUser
} else {
    WriteLog "Модуль PackageManagement уже установлен"
}

# Проверка и установка модуля PSWindowsUpdate
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    WriteLog "Установка модуля PSWindowsUpdate"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser
} else {
    WriteLog "Модуль PSWindowsUpdate уже установлен"
}

# Задержка перед установкой обновлений (если это необходимо)
Start-Sleep -Seconds 30

# Установка обновлений Windows
$UpdateLogPath = "C:\Scripts\WindowsUpdate_Temp.log"
WriteLog "Установка обновлений Windows"
Install-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-File -FilePath $UpdateLogPath -Force
WriteLog "Установка обновлений завершена"



      $files = dir C:\Scripts\WindowsUpdate_Temp.log
if ($files -ne $null)
{
   WriteLog "обновление windows завершено - OK”
}
else
{
   WriteLog "обновление windows завершено - FAIL”
}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Undefined
WriteLog "Запущена автоматическая перезагрузка"
Restart-Computer -Force