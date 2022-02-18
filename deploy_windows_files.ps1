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
    [bool]$clean_deployment_folder
)

Write-Output "Deploy Windows Files"
Write-Output "Server: $server"

$source_file_parts = $source_zip_file_path.Replace('/', '\').Split('\')
$source_file_name = $source_file_parts[$source_file_parts.Length - 1]
$destination_zip_file_path = (Join-Path -Path $deployment_folder_path -ChildPath $source_file_name)

$credential = [PSCredential]::new($user_id, $password)
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
$session = New-PSSession $server -SessionOption $so -UseSSL -Credential $credential

function Invoke-RemoteCommand($Command, $Arguments) {
    Invoke-Command `
        -Session $session `
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
Copy-Item -Path $source_zip_file_path -ToSession $session -Destination $destination_zip_file_path

$copy = {
    param([string]$path, [string]$file)

    Write-Host "Expanding package archive..."
    Expand-Archive -LiteralPath $file -DestinationPath $path -Force

    Write-Host "Removing package archive...."
    Remove-Item -LiteralPath $file
}

Invoke-RemoteCommand -Command $copy -Arguments $deployment_folder_path, $destination_zip_file_path

Write-Output "Web Application Files deployed."
