
# ������� ������� �����������
function WriteLog {
    Param ([string]$LogString)

    $Stamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-Content $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

$LogFile = "C:\Scripts\windows_update.log" # ���� �����������
Set-ExecutionPolicy RemoteSigned -Force
# �������� � ������ ������ ���������� Windows
$windowsUpdateService = Get-Service -Name wuauserv
if ($windowsUpdateService.Status -ne "Running") {
    WriteLog "������ ������ ���������� Windows(After)"
    Start-Service -Name wuauserv
} else {
    WriteLog "������ ���������� Windows ��� ��������(After)"
}

# ��������� ������ PackageManagement, ���� �����������
if (-not (Get-Module -ListAvailable -Name PackageManagement)) {
    WriteLog "��������� ������ PackageManagement(After)"
    Install-Module -Name PackageManagement -Force -Scope CurrentUser
} else {
    WriteLog "������ PackageManagement ��� ����������(After)"
}

# �������� � ��������� ������ PSWindowsUpdate
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    WriteLog "��������� ������ PSWindowsUpdate(After)"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser
} else {
    WriteLog "������ PSWindowsUpdate ��� ����������(After)"
}

# �������� ����� ���������� ���������� (���� ��� ����������)
Start-Sleep -Seconds 30

# ��������� ���������� Windows
$UpdateLogPath = "C:\Scripts\WindowsUpdate_Temp_AfterReboot.log"
WriteLog "��������� ���������� Windows(After)"
Install-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-File -FilePath $UpdateLogPath -Force
WriteLog "��������� ���������� ���������(After)"



      $files = dir C:\Scripts\WindowsUpdate_Temp_AfterReboot.log
if ($files -ne $null)
{
   WriteLog "���������� windows ��������� - OK(After)�
}
else
{
   WriteLog "���������� windows ��������� - FAIL(After)�
}

Unregister-ScheduledTask -TaskName "update_windows_after_reboot" -Confirm:$false
$wshell = New-Object -ComObject Wscript.Shell
$Output = $wshell.Popup("���������� ���������",0,"���������� windows")