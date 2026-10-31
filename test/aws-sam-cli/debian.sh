#!/bin/bash

set -e

source dev-container-features-test-lib

check "sam --version" sam --version

reportResults
