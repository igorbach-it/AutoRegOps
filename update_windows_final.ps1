$wshell = New-Object -ComObject Wscript.Shell

$Logfile = "C:\Scripts\update_windows_final.log"
function WriteLog
{
Param ([string]$LogString)

$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
$LogMessage = "$Stamp $LogString"
Add-content $LogFile -value $LogMessage
}

    WriteLog "--------------------------------”
    WriteLog "Чистка ременных файлов завершена”
    WriteLog "Чистка кеша сервера 1с завершена”

$KVRTPath = "C:\Scripts\KVRT"

    Write-Verbose "Создаем директории"
    New-Item -ErrorAction Ignore -ItemType directory -Path $KVRTPath
    New-Item -ErrorAction Ignore -ItemType directory -Path "$KVRTPath\UU"

    $KVRTurl = "http://devbuilds.kaspersky-labs.com/devbuilds/KVRT/latest/full/KVRT.exe"
    Write-Verbose "Загружаем Kaspersky Virus Removal Tool из: $KVRTurl"
    Invoke-WebRequest -URI $KVRTurl -UseBasicParsing -OutFile "$KVRTPath\KVRT.exe"

    WriteLog "антивирус скачан”

  $scannowDate = Get-Date -Format "yyyyMMdd"
  New-Item -ErrorAction Ignore -ItemType directory -Path "$KVRTPath\$scannowDate"
  Write-Verbose "Запускаем сканирование ..."
  $resultScan = & "$KVRTPath\KVRT.exe" -d "$KVRTPath\$scannowDate" -accepteula -silent -processlevel 1 -dontencrypt | Out-Null # запускает сканирование антивирусом
  Remove-item C:\Scripts\KVRT\KVRT.exe

  WriteLog "антивирус завершил сканирование, результаты можно посмотреть $KVRTPath\$scannowDate\Reports”

$Output = $wshell.Popup("Сканирование завершено, результаты можно будет посмотреть в каталоге $KVRTPath\$scannowDate\Reports",30,"Сканирование на вирусы")

Install-PackageProvider NuGet -Force
Install-Module PSWindowsUpdate -Confirm:$false -Force # установщик обновлений через Pshell
Get-WindowsUpdate -AcceptAll -Install -AutoReboot # скачивание и установка обновлений Windows

WriteLog "обновление windows завершено”

$Output = $wshell.Popup("обновление завершено",0,"Обновление windows")