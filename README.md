# Deploy Windows Files

This action deploys files to a windows machine.

## Index <!-- omit in toc -->

- [Inputs](#inputs)
- [Prerequisites](#prerequisites)
- [Example](#example)
- [Contributing](#contributing)
  - [Incrementing the Version](#incrementing-the-version)
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

## Prerequisites

1. The target windows machine that will be running the service will need to have a WinRM SSL listener setup. This will have to be setup through a service ticket because a specifically formatted SSL certificate will need be set up in the correct certificate container.
2. A deployment service account will need to be created and put into the local admins group of the target server. This has to be done through a service desk ticket by an team.

## Example

```yml
...
env:
  server: web-app.domain.com
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
      uses: im-open/deploy-windows-files@v2.0.3
        with:
          server: ${{ env.server }}
          service-account-id: ${{secrets.windows_admin_user}}
          service-account-password: ${{secrets.windows_admin_password}}
          source-zip-file-path: ${{env.web-app-archive}}
          deployment-folder-path: 'C:\services\web_app_dir'
          clean-deployment-folder: 'true'
```

## Contributing

When creating new PRs please ensure:
1. For major or minor changes, at least one of the commit messages contains the appropriate `+semver:` keywords listed under [Incrementing the Version](#incrementing-the-version).
2. The `README.md` example has been updated with the new version.  See [Incrementing the Version](#incrementing-the-version).
3. The action code does not contain sensitive information.

### Incrementing the Version

This action uses [git-version-lite] to examine commit messages to determine whether to perform a major, minor or patch increment on merge.  The following table provides the fragment that should be included in a commit message to active different increment strategies.
| Increment Type | Commit Message Fragment                     |
| -------------- | ------------------------------------------- |
| major          | +semver:breaking                            |
| major          | +semver:major                               |
| minor          | +semver:feature                             |
| minor          | +semver:minor                               |
| patch          | *default increment type, no comment needed* |

## Code of Conduct

This project has adopted the [im-open's Code of Conduct](https://github.com/im-open/.github/blob/master/CODE_OF_CONDUCT.md).

## License

Copyright &copy; 2021, Extend Health, LLC. Code released under the [MIT license](LICENSE).

<!-- Links -->
[git-version-lite]: https://github.com/im-open/git-version-lite
[PowerShell Remoting over HTTPS with a self-signed SSL certificate]: https://4sysops.com/archives/powershell-remoting-over-https-with-a-self-signed-ssl-certificate
[WSMan]: https://docs.microsoft.com/en-us/windows/win32/winrm/ws-management-protocol
[WinRM]: https://docs.microsoft.com/en-us/windows/win32/winrm/about-windows-remote-management