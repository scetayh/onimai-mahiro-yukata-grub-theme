#!/usr/bin/env bash

# SPDX-License-Identifier: GPL-3.0-or-later

# WARNING: Run after reading this script carefully!

set -Eeo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

rm -rf themes/
./build.sh
peekaboot themes/onimai_mahiro_yukata