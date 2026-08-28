#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -Eeo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

rm -rf build/*
./build.sh -s 0.75

peekaboot -r 1920x1200 -c "#FFF9F2" -C dark-gray/black build/themes/onimai_mahiro_yukata