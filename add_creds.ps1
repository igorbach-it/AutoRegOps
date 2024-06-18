# Устанавливаем политику выполнения скриптов
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

Start-Sleep -Seconds 5

# 1. Скачивание PSTools.zip
$source = "https://download.sysinternals.com/files/PSTools.zip"
$destination = "C:\temp\PSTools.zip"
Invoke-WebRequest -Uri $source -OutFile $destination

# 2. Распаковываем архив
Expand-Archive -LiteralPath $destination -DestinationPath C:\temp\pstools -Force

# Путь к файлу с зашифрованными данными
New-Item -ErrorAction Ignore -ItemType directory -Path "C:\Scripts\RegOps"

$scriptContent = {

$username = 'regops@service.efsol.ru'
$password = Read-Host "Введите пароль от $username" -AsSecureString
$toAddress = Read-Host "Введите адрес электронной почты получателя"

$credObject = New-Object System.Management.Automation.PSCredential ($username, $password)

$credsAndRecipient = [PSCustomObject]@{
    Credential = $credObject
    Recipient = $toAddress
}

$credsAndRecipient | Export-Clixml -Path "C:\Scripts\RegOps\creds.enc"
Write-Host "Логин и пароль зашифрованы и сохранены."

 
exit
}

Start-Process -FilePath "C:\temp\PSTools\psexec.exe" -ArgumentList "-i -s powershell.exe -NoExit -Command `"$scriptContent`"" -Wait


Get-ChildItem -Path "C:\temp\" -Filter "pstools*" -Directory | ForEach-Object { Remove-Item $_.FullName -Recurse -Force }
Remove-Item -Path "C:\temp\PSTools.zip" -Force
