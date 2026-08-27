#!/usr/bin/env bash

# SPDX-License-Identifier: GPL-3.0-or-later

# WARNING: Run after reading this script carefully!

set -Eeo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

rm -rf themes/
./build.sh -l zh-CN -s 0.9
sudo rm -rf /boot/grub/themes/onimai_mahiro_yukata/
sudo cp -r themes/onimai_mahiro_yukata/ /boot/grub/themes/
sudo grub-mkconfig -o /boot/grub/grub.cfg
