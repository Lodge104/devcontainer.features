# AWS SAM CLI (aws-sam-cli)

Installs the AWS Serverless Application Model (SAM) CLI. Detects the OS, CPU architecture and package manager and picks the right install method.

## Example Usage

```json
"features": {
    "ghcr.io/lodge104/devcontainer.features/aws-sam-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the AWS SAM CLI version to install (e.g. 'latest' or '1.100.0'). | string | latest |
| installCfnLint | Also install the cfn-lint CloudFormation linter. | boolean | true |

## Customizations

### VS Code Extensions

- `AmazonWebServices.aws-toolkit-vscode`

## OS Support

| Platform | Architecture | Install method |
|-----|-----|-----|
| Debian / Ubuntu (glibc) | x86_64, arm64 | Official AWS SAM CLI zip installer |
| RHEL / Fedora / CentOS / Amazon Linux / SUSE | x86_64, arm64 | Official AWS SAM CLI zip installer |
| Alpine (musl) | x86_64, arm64 | `pip` in an isolated virtual environment |

The official AWS installer is linked against glibc and cannot run on musl-based distributions such as Alpine. On Alpine, this feature installs the `aws-sam-cli` PyPI package in an isolated environment instead. Other operating systems and architectures are not supported.

## Docker

`sam local` and `sam build --use-container` require access to a Docker daemon. Add the `docker-in-docker` or `docker-outside-of-docker` feature to your dev container to use these commands.

## cfn-lint

By default, the feature also installs [`cfn-lint`](https://github.com/aws-cloudformation/cfn-lint) in an isolated Python virtual environment. Set `installCfnLint` to `false` to skip it.

---

_Note: This file was generated from [devcontainer-feature.json](https://github.com/Lodge104/devcontainer.features/blob/main/src/aws-sam-cli/devcontainer-feature.json). Additional notes are maintained in [NOTES.md](./NOTES.md)._
