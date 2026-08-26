#!/usr/bin/env bash

# SPDX-License-Identifier: GPL-3.0-or-later

set -Eeo pipefail
shopt -s inherit_errexit
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
IFS=$'\n\t'

readonly VERSION=0.1.1
export VERSION
readonly ASSETS_DIR=assets
export ASSETS_DIR
readonly BUILD_DIR=themes/onimai_mahiro_yukata
export BUILD_DIR
readonly FONT_FILENAME="MapleMono-NF-CN-Regular.ttf"
export FONT_FILENAME
readonly FFMPEG_LOGLEVEL="repeat+level+time+datetime+trace"
export FFMPEG_LOGLEVEL

echo_err() {
    echo "Error: $*" >&2
}

is_gt_zero() {
    local str
    str="$(printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -z "$str" ] && \
        return 1

    if [[ $str =~ ^[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?$ ]]; then
        [ "$(echo "$str > 0" | bc 2>/dev/null)" = "1" ]
    else
        return 1
    fi
}

float_multiple() {
    local product=1

    for multiplier in "$@"; do
        product=$(bc -l <<< "$product * $multiplier")
    done

    printf %f "$product"
}

round() {
    printf %.0f "$@"
}

float_multiple_round() {
    round "$(float_multiple "$@")"
}

usage() {
    cat >&2 << EOF
Usage: $0 [ option ]
GRUB Theme Onimai: Mahiro (Yukata) build script

Options:
  -V, --version
         Output version information and exit.
  -h, --help
         Display this help and exit.
  -s, --scale=<scale>
         Specify the zoom scale of elements except the background.
         Character illustrations included in the background.
         Note: If expected to show larger elements on high-resolution
         displayers, the scale should be set to 1.5 and even bigger.
  -c, --color={ pink | blue }
         Specify the boot menu item color.
         If not specified, the color will be 'pink'.
         Pink is with female symbols, blue with male ones.
  -l, --language={ en | zh-cn | zh-tr | ja }
         Sepcify the timeout prompt language.
         If not specified, the language will be 'en'.

Examples:
  $0 -l zh-cn
  $0 -s 1.5 -c blue -l zh-tr
  $0 --color=pink --language=ja
  $0 --scale 0.75 --color blue --language en
EOF
}

main() {
    # ===== Argument Parsing =====

    opt_short=Vhs:c:l:
    opt_long=version,help,scale:,color:,language:

    opt="$(getopt -o "$opt_short" -l "$opt_long" -n "$0" -- "$@")"
    eval set -- "$opt"

    has_flag_V=0
    has_flag_h=0
    has_option_s=0
    option_s_value=""
    has_option_c=0
    option_c_value=""
    has_option_l=0
    option_l_value=""
    
    while true; do
        case "$1" in
            -V|--version)
                has_flag_V=1
                shift 1
                ;;
            -h|--help)
                has_flag_h=1
                shift 1
                ;;
            -s|--scale)
                has_option_s=1
                option_s_value="$2"
                shift 2
                ;;
            -c|--color)
                has_option_c=1
                option_c_value="$2"
                shift 2
                ;;
            -l|--language)
                has_option_l=1
                option_l_value="$2"
                shift 2
                ;;
            --)
                shift 1
                break
                ;;
            *)
                echo_err "unparsed option '$1'"
                return 1
                ;;
        esac
    done

    # ===== Argument Check =====

    (( has_flag_V )) && {
        echo $VERSION
        return 0
    }
    (( has_flag_h )) && {
        usage
        return 0
    }

    [[ $# -eq 0 ]] || {
        echo_err "too many arguments"
        return 1
    }

    (( has_option_s )) && {
        is_gt_zero "$option_s_value" || {
            echo_err "invalid scale '$option_s_value'"
            return 1
        }
    }

    if (( has_option_c )); then
        [[ "$option_c_value" =~ ^(pink|blue)$ ]] || {
            echo_err "color '$option_c_value' not supported"
            return 1
        }
    fi
    if (( has_option_l )); then
        [[ "$option_l_value" =~ ^(en|zh-cn|zh-tr|ja)$ ]] || {
            echo_err "language '$option_l_value' not supported"
            return 1
        }
    fi

    if (( has_option_s )); then
        scale=$option_s_value
    else
        scale=1
    fi
    item_w_width=$(float_multiple_round 24 "$scale")

    # ===== Theme Element Location & Size Calculation =====

    # fonts

    FONT_NAME="Maple Mono NF CN"
    FONT_STYLE="Regular"
    FONT_SIZE_LARGER=$(float_multiple_round 22 "$scale")
    FONT_SIZE_SMALLER=$(float_multiple_round 18 "$scale")

    # title

    TITLE_WIDTH=$(float_multiple_round 850 "$scale")
    TITLE_TOP=$(float_multiple_round 54 "$scale")
    TITLE_HEIGHT=$(
        float_multiple_round \
            "$TITLE_WIDTH" \
            "$(identify -format '%h/%w' $ASSETS_DIR/images/title.png)" \
            "$scale"
    )

    # boot menu

    BOOT_MENU_WIDTH=$(float_multiple_round 667 "$scale")
    BOOT_MENU_TOP=$(float_multiple_round 300 "$scale")
    BOOT_MENU_HEIGHT=84%-$BOOT_MENU_TOP

    # icon

    ICON_SIZE=$(float_multiple_round 36 "$scale")

    # item

    ITEM_HEIGHT=$(float_multiple_round 68 "$scale")
    ITEM_ICON_SPACE=$(float_multiple_round 18 "$scale")
    ITEM_SPACING=$(float_multiple_round 16 "$scale")
    [[ $option_c_value = pink ]] && \
        ITEM_COLOR_HEX=#ee858c
    [[ $option_c_value = blue ]] && \
        ITEM_COLOR_HEX=#45bbff

    # timeout prompt

    TIMEOUT_LEFT=$(float_multiple_round 77 "$scale")
    TIMEOUT_TOP=$(
        round "$(
            bc -l \
                <<< "($TITLE_TOP + $TITLE_HEIGHT + $BOOT_MENU_TOP) / 2 \
                    - $FONT_SIZE_LARGER * 3 / 4"
        )"
    )
    TIMEOUT_TEXT="Selected OS will be booted in %d seconds"
    [[ $option_l_value = zh-cn ]] && \
        TIMEOUT_TEXT="所选操作系统将在 %d 秒后启动"
    [[ $option_l_value = zh-tr ]] && \
        TIMEOUT_TEXT="所選操作系統將在 %d 秒後啟動"
    [[ $option_l_value = ja ]] && \
        TIMEOUT_TEXT="選択したOSは %d 秒後に起動します"
        
    # terminal

    TERMINAL_LEFT=$(float_multiple_round 19 "$scale")
    TERMINAL_WIDTH=46%
    TERMINAL_TOP=$(
        round "$(
            bc -l \
                <<< "($TITLE_TOP + $TITLE_HEIGHT + $BOOT_MENU_TOP) / 2"
        )"
    )
    TERMINAL_HEIGHT=84%-$TERMINAL_TOP

    # ===== Theme Generation =====

    # create necessary directories

    mkdir -v -p $BUILD_DIR/icons

    # copy background

    cp -v $ASSETS_DIR/images/background.png $BUILD_DIR

    # create fonts

    for font_size in $FONT_SIZE_LARGER \
        $FONT_SIZE_SMALLER;
    do
        grub-mkfont -v \
            --name="$FONT_NAME" \
            --size="$font_size" \
            --output="$BUILD_DIR/${FONT_FILENAME%.*}-$font_size.pf2" \
            $ASSETS_DIR/fonts/$FONT_FILENAME
    done

    # copy font license

    cp -v $ASSETS_DIR/fonts/OFL.txt $BUILD_DIR

    # copy terminal box elements

    cp -v $ASSETS_DIR/images/terminal_box/* $BUILD_DIR

    # convert title

    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i $ASSETS_DIR/images/title.png \
        -vf "scale=$TITLE_WIDTH:-1" \
        $BUILD_DIR/title.png

    # convert distro icons

    for icon in "$ASSETS_DIR"/icons/*; do
        ffmpeg -loglevel $FFMPEG_LOGLEVEL \
            -i "$icon" \
            -vf "scale=$ICON_SIZE:$ICON_SIZE" \
            "$BUILD_DIR/icons/$(basename "$icon")"
    done

    # convert unselected item elements

    # set item color
    item_color=pink
    (( has_option_c )) && \
        item_color=$option_c_value

    # west
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/item/$item_color/item_w_c.png" \
        -vf "scale=$item_w_width:$ITEM_HEIGHT" \
        $BUILD_DIR/item_w.png

    # central
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/item/$item_color/item_w_c.png" \
        -vf "scale=1:$ITEM_HEIGHT" \
        $BUILD_DIR/item_c.png

    # east
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/item/$item_color/item_e.png" \
        -vf "scale=-1:$ITEM_HEIGHT" \
        $BUILD_DIR/item_e.png

    # convert selected item elements

    # west
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/selected_item/$item_color/selected_item_w_c.png" \
        -vf "scale=$item_w_width:$ITEM_HEIGHT" \
        $BUILD_DIR/selected_item_w.png
    
    # central
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/selected_item/$item_color/selected_item_w_c.png" \
        -vf "scale=1:$ITEM_HEIGHT" \
        $BUILD_DIR/selected_item_c.png

    # east
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/selected_item/$item_color/selected_item_e.png" \
        -vf "scale=-1:$ITEM_HEIGHT" \
        $BUILD_DIR/selected_item_e.png

    # generate theme configuration

    export TITLE_WIDTH
    export TITLE_TOP
    export TITLE_HEIGHT
    export TIMEOUT_LEFT
    export TIMEOUT_TOP
    export TIMEOUT_TEXT
    export FONT_NAME
    export FONT_STYLE
    export FONT_SIZE_LARGER
    export FONT_SIZE_SMALLER
    export TERMINAL_LEFT
    export TERMINAL_WIDTH
    export TERMINAL_TOP
    export TERMINAL_HEIGHT
    export BOOT_MENU_WIDTH
    export BOOT_MENU_TOP
    export BOOT_MENU_HEIGHT
    export ICON_SIZE
    export ITEM_HEIGHT
    export ITEM_ICON_SPACE
    export ITEM_SPACING
    export ITEM_COLOR_HEX

    envsubst < $ASSETS_DIR/theme.txt.conf | tee $BUILD_DIR/theme.txt
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo_err "Do not 'source' this script. You should run it directly."
    exit 1
elif [[ "$(pwd -P)" != "$(cd "$(dirname "$0")" && pwd -P)" ]]; then
    echo_err "You should run this script in the project root directory."
    exit 1
else
    for cmd in bc grub-mkfont ffmpeg magick identify; do
        command -v $cmd >& /dev/null || {
            echo_err "command '$cmd' not found"
            exit 1
        }
    done
    
    main "$@"
    exit $?
fi