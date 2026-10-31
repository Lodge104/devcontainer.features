#!/bin/bash

set -e

source dev-container-features-test-lib

check "sam --version" sam --version
check "installed from pip virtual env" bash -c "readlink /usr/local/bin/sam | grep -q aws-sam-cli-venv"

reportResults
