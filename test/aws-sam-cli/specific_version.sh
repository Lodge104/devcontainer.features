#!/bin/bash

set -e

source dev-container-features-test-lib

check "sam version is pinned" bash -c "sam --version | grep -F '1.100.0'"

reportResults
