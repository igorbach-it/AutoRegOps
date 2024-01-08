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
    
gci 'C:\inetpub\logs\LogFiles' -Include '*.log' -Recurse | ? LastWriteTime -LT (Get-Date).AddDays(-7) | Remove-Item


    $files = dir C:\inetpub\logs\LogFiles
if ($files -ne $null)
{
   WriteLog "Чистка логов iis завершена - OK”
}
else
{
   WriteLog "Чистка логов iis завершена - FAIL”
}
 

Dism.exe /Online /Cleanup-Image /StartComponentCleanup

    WriteLog "Чистка хранилища компонентов WinSxS завершена”

$KVRTPath = "C:\Scripts\KVRT"

    Write-Verbose "Создаем директории"
    New-Item -ErrorAction Ignore -ItemType directory -Path $KVRTPath
    New-Item -ErrorAction Ignore -ItemType directory -Path "$KVRTPath\UU"

    $KVRTurl = "http://devbuilds.kaspersky-labs.com/devbuilds/KVRT/latest/full/KVRT.exe"
    Write-Verbose "Загружаем Kaspersky Virus Removal Tool из: $KVRTurl"
    Invoke-WebRequest -URI $KVRTurl -UseBasicParsing -OutFile "$KVRTPath\KVRT.exe"


    $files = dir C:\Scripts\KVRT\*.exe
if ($files -ne $null)
{
   WriteLog "антивирус скачан - OK”
}
else
{
   WriteLog "антивирус скачан - FAIL”
}
    

  $scannowDate = Get-Date -Format "yyyyMMdd"
  New-Item -ErrorAction Ignore -ItemType directory -Path "$KVRTPath\$scannowDate"
  Write-Verbose "Запускаем сканирование ..."
  $resultScan = & "$KVRTPath\KVRT.exe" -d "$KVRTPath\$scannowDate" -accepteula -silent -processlevel 1 -dontencrypt | Out-Null # запускает сканирование антивирусом
  Remove-item C:\Scripts\KVRT\KVRT.exe

      $files = dir $KVRTPath\$scannowDate\Reports
if ($files -ne $null)
{
   WriteLog "антивирус завершил сканирование, результаты можно посмотреть $KVRTPath\$scannowDate\Reports - OK”
}
else
{
   WriteLog "антивирус завершил сканирование, результаты можно посмотреть $KVRTPath\$scannowDate\Reports - FAIL”
}


$Output = $wshell.Popup("Сканирование завершено, результаты можно будет посмотреть в каталоге $KVRTPath\$scannowDate\Reports",30,"Сканирование на вирусы")

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # для windows server 2016
Install-PackageProvider NuGet -Force
Install-Module PSWindowsUpdate -Confirm:$false -Force # установщик обновлений через Pshell
Install-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-File "C:\Scripts\WindowsUpdate_Temp.log" -force # скачивание и установка обновлений Windows

      $files = dir C:\Scripts\WindowsUpdate_Temp.log
if ($files -ne $null)
{
   WriteLog "обновление windows завершено - OK”
}
else
{
   WriteLog "обновление windows завершено - FAIL”
}

#Remove-item C:\Scripts\WindowsUpdate_Temp.log

$Output = $wshell.Popup("обновление завершено",0,"Обновление windows")

shutdown -r
