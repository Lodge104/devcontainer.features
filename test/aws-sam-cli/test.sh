#!/bin/bash

# This test file is executed against an auto-generated devcontainer.json that
# includes the 'aws-sam-cli' feature with no options.
#
# Eg:
# {
#    "image": "<..some-base-image...>",
#    "features": {
#      "aws-sam-cli": {}
#    },
#    "remoteUser": "root"
# }
#
# Thus, the value of all options will fall back to the default value in the
# feature's `devcontainer-feature.json`.
#
# This test can be run with the following command:
#
#    devcontainer features test \
#                   --features aws-sam-cli \
#                   --remote-user root \
#                   --skip-scenarios \
#                   --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#                   /path/to/this/repo

set -e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
check "sam is on the PATH" bash -c "command -v sam"
check "sam --version" sam --version
check "sam reports a version number" bash -c "sam --version | grep -E 'SAM CLI, version [0-9]+\.[0-9]+\.[0-9]+'"

# Report result
reportResults
