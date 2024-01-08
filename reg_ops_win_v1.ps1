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

# Получите корень каталога профиля пользователя
$userProfileRoot = [System.Environment]::GetEnvironmentVariable("USERPROFILE")
$userProfileRoot = Split-Path $userProfileRoot

# Получите системный каталог TEMP и каталог Windows
$tempDir = [System.Environment]::GetEnvironmentVariable("TEMP")
$windowsDir = [System.Environment]::GetEnvironmentVariable("WINDIR")

# Для каждого подкаталога в корневом каталоге профиля пользователя
Get-ChildItem $userProfileRoot | ForEach-Object {
    if ($_.Name -notin @("all users", "default user", "localservice", "networkservice")) {
        WriteLog "Обработка профиля: $($_.Name)"
        
        # Удалить указанные папки
        $foldersToDelete | ForEach-Object {
            $folderToDelete = $_
            $folderPath = Join-Path -Path $userProfileRoot -ChildPath ("{0}\{1}" -f $_.Name, $folderToDelete)
            if (Test-Path $folderPath) {
                WriteLog "Удаление $folderPath"
                Remove-Item -Path $folderPath -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                WriteLog "Папка для удаления не найдена: $folderPath"
            }
        }
    }
}

# Удалить содержимое системного каталога TEMP
WriteLog "Обработка папки: $tempDir"
Remove-Item -Path "$tempDir\*" -Recurse -Force -ErrorAction SilentlyContinue

# Удалить содержимое каталога Windows\Temp
$windowsTemp = Join-Path -Path $windowsDir -ChildPath "Temp"
WriteLog "Обработка папки: $windowsTemp"
Remove-Item -Path "$windowsTemp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Создаем функцию для удаления файлов
function DeleteFiles {
    Param ([string]$Path, [string]$Pattern)
    try {
        Get-ChildItem -Path $Path -Filter $Pattern -Recurse -ErrorAction Stop | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -ErrorAction Stop
    } catch {
        WriteLog "Ошибка при удалении файлов: $($_.Exception.Message)"
    }
}

#DeleteFiles 'C:\inetpub\logs\LogFiles' '*.log'
#WriteLog "Чистка временных файлов завершена"

#Dism.exe /Online /Cleanup-Image /StartComponentCleanup
#WriteLog "Чистка хранилища компонентов WinSxS завершена"

$wshell = New-Object -ComObject Wscript.Shell

WriteLog "--------------------------------"


$files = Get-ChildItem 'C:\inetpub\logs\LogFiles' -Include '*.log' -Recurse | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -ErrorAction SilentlyContinue
if ($files -ne $null) {
    WriteLog "Чистка логов IIS завершена - OK"
} else {
    WriteLog "Чистка логов IIS завершена - FAIL"
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

#$Output = $wshell.Popup("Сканирование завершено, результаты можно будет посмотреть в каталоге $KVRTPath\$scannowDate\Reports", 30, "Сканирование на вирусы")

if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)){
    WriteLog "Установка модуля PSWindowsUpdate"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -Force -Confirm:$false
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
    WriteLog "Ставим обновления"
    Install-WindowsUpdate -AcceptAll -Install | Out-File "C:\Scripts\WindowsUpdate_Temp.log" -Force
}

$files = Get-ChildItem "C:\Scripts\WindowsUpdate_Temp.log"
if ($files -ne $null) {
    WriteLog "Обновление Windows завершено - OK"
} else {
    WriteLog "Обновление Windows завершено - FAIL"
}

#$Output = $wshell.Popup("Обновление завершено", 30, "Обновление Windows")

$Confirmation = $wshell.Popup("Выполнить перезагрузку?", 4, "Перезагрузка")
if ($Confirmation -eq 6) {
    shutdown -r
} else {
    WriteLog "Перезагрузка не выполнена"
}
