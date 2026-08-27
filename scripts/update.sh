#!/usr/bin/env bash

# SPDX-License-Identifier: GPL-3.0-or-later

# WARNING: Run after reading this script carefully!

set -Eeo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

./build.sh
sudo cp -r themes/onimai_mahiro_yukata/ /boot/grub/themes/
sudo grub-mkconfig -o /boot/grub/grub.cfg