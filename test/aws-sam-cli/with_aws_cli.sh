#!/bin/bash

set -e

source dev-container-features-test-lib

check "aws --version" aws --version
check "sam --version" sam --version

reportResults
