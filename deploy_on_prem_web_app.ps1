Param(
    [parameter(Mandatory = $true)]
    [string]$server,
    [parameter(Mandatory = $true)]
    [string]$user_id,
    [parameter(Mandatory = $true)]
    [SecureString]$password,
    [parameter(Mandatory = $true)]
    [string]$source_zip_file_path,
    [parameter(Mandatory = $true)]
    [string]$deployment_folder_path,
    [parameter(Mandatory = $true)]
    [bool]$clean_deployment_folder,
    [parameter(Mandatory = $true)]
    [string]$cert_path
)

Write-Output "Deploy On-Prem Web Application"
Write-Output "Server: $server"

$source_file_parts = $source_zip_file_path.Replace('/', '\').Split('\')
$source_file_name = $source_file_parts[$source_file_parts.Length - 1]
$destination_zip_file_path = (Join-Path -Path $deployment_folder_path -ChildPath $source_file_name)

$credential = [PSCredential]::new($user_id, $password)
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

Write-Output "Importing remote server cert..."
Import-Certificate -Filepath $cert_path -CertStoreLocation "Cert:\LocalMachine\Root"

function Invoke-RemoteCommand($Command, $Arguments) {
    Invoke-Command -ComputerName $server `
        -Credential $credential `
        -UseSSL `
        -SessionOption $so `
        -ScriptBlock $command `
        -ArgumentList $arguments
}

if ($clean_deployment_folder) {
    Write-Output "Cleaning Target Folder: $deployment_folder_path"

    $clean = {
        param([string]$path)
        Write-Host "Cleaning destination folder: $path"
        Get-ChildItem -Path $path -Recurse | ForEach-Object { Remove-item -Recurse -path $_.FullName }
    }

    Invoke-RemoteCommand -Command $clean -Arguments $deployment_folder_path
}

[Byte[]]$zip = Get-Content -Path $source_zip_file_path -Encoding Byte
Write-Host "File Size: ${$zip.Length}"
$copy = {
    param([string]$path, [string]$file, [Byte[]]$zip_data)
    Write-Host "Writing Package Archive: $file"
    Set-Content -Path $file -Value $zip_data -Encoding Byte

    Write-Host "Expanding Package Archive: $file"
    Expand-Archive -LiteralPath $file -DestinationPath $path -Force
}

Invoke-RemoteCommand -Command $copy -Arguments $deployment_folder_path, $destination_zip_file_path, $zip

# Remove-Item -Path $destination_zip_file_path `
#     -ToSession $so -Credential $credential

Write-Output "Web Application Files deployed."
