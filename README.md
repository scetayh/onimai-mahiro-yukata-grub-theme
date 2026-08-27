# Onimai Mahiro (Yukata) GRUB Theme

<p align="center">
  <b>English</b> | <a href="docs/README.zh-CN.md">简体中文</a>
</p>

![Preview](https://blog.tarikkochan.top/onimai_mahiro_yukata_grub_theme_preview.jpg)

## Introduction

**Onimai Mahiro (Yukata) GRUB Theme** is a GRUB theme inspired by the TV anime [*Onimai: I'm Now Your Sister!*](https://onimai.jp/) (Japanese: お兄ちゃんはおしまい！), featuring Mahiro Oyama in a yukata with a candy apple.

This theme was inspired by [itrocaiks](https://github.com/itrocaiks/)' [OnimaiGRUB](https://github.com/itrocaiks/OnimaiGRUB) project.

## Features

- Script-controlled build process
- Depends on ImageMagick, FFmpeg, etc.
- Boot menu item styling supports **pink** and **blue** color schemes with corresponding gender symbols
- Timeout prompt supports several common languages
- Customizable scaling ratio

## Getting Started

### Dependencies

- `getopt`
- `bc`
- `grub-mkfont` (GRUB)
- `ffmpeg`
- `magick` (ImageMagick)
- `identify` (ImageMagick)

### Build

> [!TIP]
> Starting from v0.2.0, users can access [Releases](https://github.com/scetayh/onimai-mahiro-yukata-grub-theme/releases/) to download the pre-built non-scaled themes in different color styles and languages directly. Download and unzip to get the build artifact, and skip to the [Installation](#installation) chapter.

Clone and enter the repository:

```bash
git clone https://github.com/scetayh/onimai-mahiro-yukata-grub-theme.git
cd onimai-mahiro-yukata-grub-theme/
```

Run the `build.sh` script to start the build.

By default, running the script directly builds a theme with **pink** menu items and an **English** timeout prompt:

```bash
./build.sh
```

By passing different arguments to the script, you can build themes with different color schemes, different language timeout prompts, and custom scaling ratios. Run `./build.sh --help` to view the script usage.

The build artifact is located at `themes/onimai_mahiro_yukata<suffix>`.

### Installation

If the suffix is not specified using the `-S` or `--suffix` options in the script, the build artifact should be located at `themes/animai_mahiro_yukata`. Copy it to your local GRUB themes directory, which is typically `/boot/grub/themes/`:

```bash
sudo cp -r themes/onimai_mahiro_yukata/ /boot/grub/themes/
```

Edit `/etc/default/grub` to set the `GRUB_THEME` variable to the path of the copied `theme.txt` (e.g., `"/boot/grub/themes/onimai_mahiro_yukata/theme.txt"`), or simply append a line:

```bash
sudo echo 'GRUB_THEME="/boot/grub/themes/onimai_mahiro_yukata/theme.txt"' >> /etc/default/grub
```

Depending on your distribution, regenerate the GRUB configuration using `grub-mkconfig`, `grub2-mkconfig`, or `update-grub`, for example:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Reboot to see the theme in action.

## Copyright

See the [COPYRIGHT](COPYRIGHT) file.
