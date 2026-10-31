## Supported platforms

| Platform                                      | Architecture      | Install method                         |
| --------------------------------------------- | ----------------- | -------------------------------------- |
| Debian / Ubuntu (glibc)                       | x86_64, arm64     | Official AWS SAM CLI zip installer     |
| RHEL / Fedora / CentOS / Amazon Linux / SUSE  | x86_64, arm64     | Official AWS SAM CLI zip installer     |
| Alpine (musl)                                 | x86_64, arm64     | `pip` into an isolated virtual env     |

The official installer is a PyInstaller bundle linked against glibc, so it can't run on musl-based distros such as Alpine. On those, the feature falls back to installing the `aws-sam-cli` PyPI package into `/usr/local/aws-sam-cli` and links `sam` into `/usr/local/bin`.

The architecture is detected with `uname -m`. Anything other than `x86_64`/`amd64` or `aarch64`/`arm64` fails with an error.

## Running `sam local` / `sam build --use-container`

These commands need access to a Docker daemon. Add either the `docker-in-docker` or `docker-outside-of-docker` feature alongside this one.

## Verification

The official zip is downloaded over HTTPS from the `aws/aws-sam-cli` GitHub releases. GPG signature verification is not performed by the feature.
