# 别酱了浴衣真寻 GRUB 主题

<p align="center">
  <a href="../README.md">English</a> | <b>简体中文</b>
</p>

![预览](https://blog.tarikkochan.top/onimai_mahiro_yukata_grub_theme_preview.jpg)

## 简介

**Onimai Mahiro (Yukata) GRUB Theme** 是一个模仿 TV 动画[《别当欧尼酱了！》](https://onimai.jp/)（日语：お兄ちゃんはおしまい！）风格并采用浴衣苹果糖绪山真寻相关元素的 GRUB 主题。

本主题的设计灵感来源于 [itrocaiks](https://github.com/itrocaiks/) 的 [OnimaiGRUB](https://github.com/itrocaiks/OnimaiGRUB) 项目。

## 特性

- 采用脚本控制构建过程
- 依赖于 ImageMagick 和 FFmpeg 等
- 启动菜单项样式支持**粉色**和**蓝色**两种颜色及对应性别符号
- 超时提示支持几种常见语言
- 支持自定义缩放比例

## 开始使用

### 依赖

- `getopt`
- `bc`
- `grub-mkfont` (GRUB)
- `ffmpeg`
- `identify` (ImageMagick)

### 构建

> [!TIP]
> 自 v0.2.0 起，用户可以在 [Releases](https://github.com/scetayh/onimai-mahiro-yukata-grub-theme/releases/) 中直接下载已构建好的不同颜色样式和不同语言的无缩放主题。下载后解压即可得到构建产物，并跳到[安装](#安装)章节。

克隆并进入本仓库：

```bash
git clone https://github.com/scetayh/onimai-mahiro-yukata-grub-theme.git
cd onimai-mahiro-yukata-grub-theme/
```

运行 `build.sh` 脚本以启动构建。

默认情况下，直接运行脚本会构建一个带有**粉色**样式菜单项和**英文**超时提示的主题：

```bash
./build.sh
```

向脚本传递不同参数，可以构建不同颜色样式、不同语言超时提示、自定义缩放比例的主题。执行 `./build.sh --help` 以查看脚本用法。

构建产物位于 `themes/onimai_mahiro_yukata<suffix>`。

### 安装

如果没有在脚本中使用 `-S` 或 `--suffix` 选项指定后缀，那么构建产物应该位于 `themes/onimai_mahiro_yukata` 。将其复制到本地的 GRUB 主题目录下，这通常是 `/boot/grub/themes/`：

```bash
sudo cp -r themes/onimai_mahiro_yukata/ /boot/grub/themes/
```

编辑 `/etc/default/grub` 以设置 `GRUB_THEME` 变量为复制得到的 `theme.txt` 路径（如 `"/boot/grub/themes/onimai_mahiro_yukata/theme.txt"`），或者直接追加一行：

```bash
sudo echo 'GRUB_THEME="/boot/grub/themes/onimai_mahiro_yukata/theme.txt"' >> /etc/default/grub
```

根据发行版种类，使用 `grub-mkconfig`、`grub2-mkconfig` 或 `update-grub` 等重新生成 GRUB 配置，例如：

``` bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

重启查看主题效果。

## 版权

见 [COPYRIGHT](../COPYRIGHT) 文件。
