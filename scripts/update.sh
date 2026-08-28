#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -Eeo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

rm -rfv build/*
./build.sh -l zh-CN -s 0.95
sudo rm -rfv /boot/grub/themes/onimai_mahiro_yukata/
sudo cp -rv build/themes/onimai_mahiro_yukata/ /boot/grub/themes/
sudo cp -v build/99_mahiro /etc/grub.d/
sudo grub-mkconfig -o /boot/grub/grub.cfg
