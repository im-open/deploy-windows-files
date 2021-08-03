# Deploy On-Premises Web App

## Index <!-- omit in toc -->

- [Inputs](#inputs)
- [Outputs](#outputs)
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


## Outputs

None


## Example

```yml
...
env:
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
          service-account-id: ${{secrets.iis_admin_user}}
          service-account-password: ${{secrets.iis_admin_password}}
          source-zip-file-path: ${{env.web-app-archive}}
          deployment-folder-path: 'C:\iis\app_pool'
          clean-deployment-folder: 'true'
          server-public-key: ${{ env.cert-path }}
```


## Code of Conduct

This project has adopted the [im-open's Code of Conduct](https://github.com/im-open/.github/blob/master/CODE_OF_CONDUCT.md).

## License

Copyright &copy; 2021, Extend Health, LLC. Code released under the [MIT license](LICENSE).
