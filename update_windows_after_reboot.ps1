# ������� ������� �����������
function WriteLog {
    Param ([string]$LogString)

    $Stamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-Content $LogFile -Value $LogMessage
    Write-Host $LogMessage
}
$regDate = Get-Date -Format "dd/MM/yyyy"
New-Item -ErrorAction Ignore -ItemType directory -Path "C:\Scripts\RegOps\Log_$regDate"
$LogFile = "C:\Scripts\RegOps\Log_$regDate\RegOps.log" # ���� �����������
Set-ExecutionPolicy RemoteSigned -Force
# �������� � ������ ������ ���������� Windows
$windowsUpdateService = Get-Service -Name wuauserv
if ($windowsUpdateService.Status -ne "Running") {
    WriteLog "������ ������ ���������� Windows(Script After Reboot)"
    Start-Service -Name wuauserv
} else {
    WriteLog "������ ���������� Windows ��� ��������(Script After Reboot)"
}

# ��������� ������ PackageManagement, ���� �����������
if (-not (Get-Module -ListAvailable -Name PackageManagement)) {
    WriteLog "��������� ������ PackageManagement(Script After Reboot)"
    Install-Module -Name PackageManagement -Force -Scope CurrentUser
} else {
    WriteLog "������ PackageManagement ��� ����������(Script After Reboot)"
}

# �������� � ��������� ������ PSWindowsUpdate
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    WriteLog "��������� ������ PSWindowsUpdate(Script After Reboot)"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser
} else {
    WriteLog "������ PSWindowsUpdate ��� ����������(Script After Reboot)"
}

# �������� ����� ���������� ���������� (���� ��� ����������)
Start-Sleep -Seconds 20

# ��������� ���������� Windows
$UpdateLogPath = "C:\Scripts\RegOps\Log_$regDate\WindowsUpdate_Temp_AfterReboot.log"
WriteLog "��������� ���������� Windows(Script After Reboot)"
Install-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-File -FilePath $UpdateLogPath -Force
WriteLog "��������� ���������� ���������(Script After Reboot)"



      $files = dir C:\Scripts\RegOps\Log_$regDate\WindowsUpdate_Temp_AfterReboot.log
if ($files -ne $null)
{
   WriteLog "����� ���������� ������� � �����������(Script After Reboot)�
}
else
{
   WriteLog "����� ���������� �� �������(Script After Reboot)�
}

Unregister-ScheduledTask -TaskName "update_windows_after_reboot" -Confirm:$false

# �������� ������� ����� � �������� �������
if (Test-Path -Path "C:\Scripts\RegOps\creds.enc") {

$PSEmailServer = 'smtp.mail.ru'
$client = $env:computername
# ���� � ����� � �������������� �������
$encryptedFilePath = "C:\Scripts\RegOps\creds.enc"

$reportRegOps = "C:\Scripts\RegOps\Log_$regDate"
#$cred = Import-Clixml -Path $encryptedFilePath
$credsAndRecipient = Import-Clixml -Path "C:\Scripts\RegOps\creds.enc"
# ���������� ������� ������ � ������ ����������
$cred = $credsAndRecipient.Credential
$toAddress = $credsAndRecipient.Recipient

New-Item -ErrorAction Ignore -ItemType directory -Path "C:\Scripts\RegOps\Log_$regDate"
Compress-Archive -Path $reportRegOps  -DestinationPath  C:\Scripts\RegOps\Log_$regDate\$client-$regDate.zip -CompressionLevel Optimal -Force
$attachments = "C:\Scripts\RegOps\Log_$regDate\$client-$regDate.zip"

Start-Sleep -Seconds 5

# ������� �������� �����
Send-MailMessage -Port 587 `
     -From "$client <regops@efsol.ru>" `
     -To $toAddress `
     -Subject "����� ������������ �������� $client" `
     -Body "����� ������������ �������� $client" `
     -UseSsl `
     -Credential $cred `
     -Encoding 'UTF8' `
     -Attachments $attachments

     WriteLog "����� ��������� �� ����� $toAddress�
} else {
    # ����� ��������� �� ���������� ����� � ����� �� �������
     WriteLog "���� C:\Scripts\RegOps\creds.enc �� ������. ����� �� ����� ���������."
}