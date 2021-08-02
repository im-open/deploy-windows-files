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

# $source_file_parts = $source_zip_file_path.Split('\')
# $source_file_name = $source_file_parts[$source_file_parts.Length - 1]
# $destination_zip_file_path = (Join-Path -Path $deployment_folder_path -ChildPath $source_file_name)

$credential = [PSCredential]::new($user_id, $password)
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

Write-Output "Importing remote server cert..."
Import-Certificate -Filepath $cert_path -CertStoreLocation "Cert:\LocalMachine\Root"

if ($clean_deployment_folder) {
    $script = {
        Param($clean_folder)
        Write-Host "$clean_folder"
        Remove-Item "$clean_folder\*.*"
    }

    Invoke-Command -ComputerName $server `
        -Credential $credential `
        -UseSSL `
        -SessionOption $so `
        -ScriptBlock $script `
        -ArgumentList $deployment_folder_path
}

# Copy-Item $source_zip_file_path `
#     -Destination $deployment_folder_path `
#     -ToSession $so -Credential $credential -Recurse

# Expand-Archive -Path $destination_zip_file_path `
#     -DestinationPath $deployment_folder_path `
#     -ToSession $so -Credential $credential

# Remove-Item -Path $destination_zip_file_path `
#     -ToSession $so -Credential $credential

Write-Output "Web Application Files deployed."
