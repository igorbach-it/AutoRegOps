$wshell = New-Object -ComObject Wscript.Shell

Install-PackageProvider NuGet -Force
Install-Module PSWindowsUpdate -Confirm:$false -Force # ���������� ���������� ����� Pshell
Install-WindowsUpdate -AcceptAll -Install | Out-File "C:\Scripts\WindowsUpdate_Temp_AfterReboot.log" -force # ���������� � ��������� ���������� Windows
Unregister-ScheduledTask -TaskName "update_windows_after_reboot" -Confirm:$false

$Output = $wshell.Popup("���������� ���������",0,"���������� windows")