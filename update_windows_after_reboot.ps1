$wshell = New-Object -ComObject Wscript.Shell

Install-PackageProvider NuGet -Force
Install-Module PSWindowsUpdate -Confirm:$false -Force # установщик обновлений через Pshell
Install-WindowsUpdate -AcceptAll -Install | Out-File "C:\Scripts\WindowsUpdate_Temp_AfterReboot.log" -force # скачивание и установка обновлений Windows
Unregister-ScheduledTask -TaskName "update_windows_after_reboot" -Confirm:$false

$Output = $wshell.Popup("обновление завершено",0,"Обновление windows")