# Deploy On-Premises Web App

## Index <!-- omit in toc -->

- [Inputs](#inputs)
- [Prerequisites](#prerequisites)
- [Example](#example)
- [Code of Conduct](#code-of-conduct)
- [License](#license)

## Inputs

| Parameter                  | Is Required | Description                                                                       |
| -------------------------- | ----------- | --------------------------------------------------------------------------------- |
| `server`                   | true        | The name of the target server                                                     |
| `service-account-id`       | true        | The service account name                                                          |
| `service-account-password` | true        | The service account password                                                      |
| `source-zip-file-path`     | true        | The path to the zip file that contains the application files                      |
| `deployment-folder-path`   | true        | The path to deploy the application files to                                       |
| `clean-deployment-folder`  | false       | Remove files that are not in the source zip file, accepts values of true or false |
| `server-public-key`        | true        | Path to remote server public ssl key (local path like c:\folder)                  |

## Prerequisites

The On-Premises Web Application Deployment action uses Web Services for Management, [WSMan], and Windows Remote Management, [WinRM], to create remote administrative sessions. Because of this Self-Hosted, Windows OS GitHubs Actions Runners, `runs-on: [self-hosted, windows-2019]`, must be used.  This will also allow the actions runner access to our on-premises applications servers.

Inbound secure WinRm network traffic (TCP port 5986) must be allowed from the GitHub Actions Runners virtual network so that remote sessions can be received.

Prep the remote Windows server to accept WinRM management calls.  In general the Windows server needs to have a [WSMan] listener that looks for incoming [WinRM] calls. Firewall exceptions need to be added for the secure WinRM TCP ports, and non-secure firewall rules should be disabled. Here is an example script that would be run on the Windows server:

  ```powershell
  $Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName <<ip-address|fqdn-host-name>>

  Export-Certificate -Cert $Cert -FilePath C:\temp\<<cert-name>>

  Enable-PSRemoting -SkipNetworkProfileCheck -Force

  # Check for HTTP listeners
  dir wsman:\localhost\listener

  # If HTTP Listeners exist, remove them
  Get-ChildItem WSMan:\Localhost\listener | Where -Property Keys -eq "Transport=HTTP" | Remove-Item -Recurse

  # If HTTPs Listeners don't exist, add one
  New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint –Force

  # This allows old WinRm hosts to use port 443
  Set-Item WSMan:\localhost\Service\EnableCompatibilityHttpsListener -Value true

  # Make sure an HTTPs inbound rule is allowed
  New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP

  # For security reasons, you might want to disable the firewall rule for HTTP that *Enable-PSRemoting* added:
  Disable-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"
  ```

- `ip-address` or `fqdn-host-name` can be used for the `DnsName` property in the certificate creation. It should be the name that the actions runner will use to call to the Windows server.
- `cert-name` can be any name.  This file will used to secure the traffic between the actions runner and the Windows server

## Example

```yml
...
env:
  server: web-app.domain.com
  cert-path: ./public-server-key
  web-app-archive: ./src/build/web-app.zip

jobs:
  ...

  build-and-deploy:
    runs-on: [windows-2019]
    steps:
      # build the application files and package in a single archive file
      build-package:
      ...
        with:
          target-archive-name: ${{env.web-app-archive}}
      ...

      deploy-package:
      uses: 'im-open/deploy-on-prem-web-app@v1.0.0'
        with:
          server: ${{ env.server }}
          service-account-id: ${{secrets.windows_admin_user}}
          service-account-password: ${{secrets.windows_admin_password}}
          source-zip-file-path: ${{env.web-app-archive}}
          deployment-folder-path: 'C:\services\web_app_dir'
          clean-deployment-folder: 'true'
          server-public-key: ${{ env.cert-path }}
```

## Code of Conduct

This project has adopted the [im-open's Code of Conduct](https://github.com/im-open/.github/blob/master/CODE_OF_CONDUCT.md).

## License

Copyright &copy; 2021, Extend Health, LLC. Code released under the [MIT license](LICENSE).

<!-- Links -->
[PowerShell Remoting over HTTPS with a self-signed SSL certificate]: https://4sysops.com/archives/powershell-remoting-over-https-with-a-self-signed-ssl-certificate
[WSMan]: https://docs.microsoft.com/en-us/windows/win32/winrm/ws-management-protocol
[WinRM]: https://docs.microsoft.com/en-us/windows/win32/winrm/about-windows-remote-management