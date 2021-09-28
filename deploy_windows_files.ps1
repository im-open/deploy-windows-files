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

Write-Output "Deploy Windows Files"
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

Write-Output "Copy file: $source_zip_file_path"

[Byte[]]$zip = Get-Content -Path $source_zip_file_path -AsByteStream -Raw
$zip_size = (Get-Item -Path $source_zip_file_path).Length / 1KB

Write-Output "Zip Size: $zip_size"

$copy = {
    param([string]$path, [string]$file, [Byte[]]$zip_data, [int]$file_size)
    Write-Host "Writing Package Archive: $file"
    Write-Host "File Size: $file_size KB"
    Set-Content -Path $file -Value $zip_data -AsByteStream

    Write-Host "Expanding package archive..."
    Expand-Archive -LiteralPath $file -DestinationPath $path -Force

    Write-Host "Removing package archive...."
    Remove-Item -LiteralPath $file
}

Invoke-RemoteCommand -Command $copy -Arguments $deployment_folder_path, $destination_zip_file_path, $zip, $zip_size

Write-Output "Web Application Files deployed."
