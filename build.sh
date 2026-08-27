#!/usr/bin/env bash

# SPDX-License-Identifier: GPL-3.0-or-later

set -Eeo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

readonly VERSION=0.3.0
export VERSION
readonly ASSETS_DIR=assets
export ASSETS_DIR
readonly FONT_FILENAME="MapleMono-NF-CN-Regular.ttf"
export FONT_FILENAME
readonly FFMPEG_LOGLEVEL="trace"
export FFMPEG_LOGLEVEL

echo_err() {
    echo "Error: $*" >&2
}

is_positive() {
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
Onimai Mahiro (Yukata) GRUB Theme build script

Options:
  -V, --version
         Output version information and exit.
  -h, --help
         Display this help and exit.
  -S, --suffix=<suffix>
         Append a suffix to the release.
         Note: You may need to add an underscore (_) at the beginning of the
         suffix.
         Warning: To ensure maximum compatibility, it is suggested that the
         suffix contains lowercase letters, numbers, and underscores only.
  -s, --scale=<scale>
         Specify the zoom scale of elements except the background.
         Character illustrations included in the background.
         Note: If expected to show larger and fewer elements on high-resolution
         displayers, the scale should be set to 1.5 and even bigger.
  -c, --color={ pink | blue }
         Specify the boot menu item color.
         If not specified, the color will be 'pink'.
         Pink is with female symbols, blue with male ones.
  -l, --language=<language>
         Sepcify the timeout prompt language.
         Available languages: 'en' (default), 'zh-CN', 'zh-TW', 'es', 'fr',
         'de', 'ja', 'ko', 'ru', 'ar', 'pt', 'hi', 'it'.

Examples:
  $0 -l zh-CN
  $0 -s 1.5 -c blue -l zh-TW
  $0 --color=pink --language=ja
  $0 --scale 0.75 --color blue --language en --suffix=_tux
EOF
}

main() {
    # ===== Argument Parsing =====

    opt_short=Vhs:S:c:l:
    opt_long=version,help,scale:,suffix:,color:,language:

    opt="$(getopt -o "$opt_short" -l "$opt_long" -n "$0" -- "$@")"
    eval set -- "$opt"

    declare -A flags
    declare -A opts
    
    while true; do
        case "$1" in
            -V|--version)
                flags[V]=
                shift 1
                ;;
            -h|--help)
                flags[h]=
                shift 1
                ;;
            -s|--scale)
                opts[s]="$2"
                shift 2
                ;;
            -S|--suffix)
                opts[S]="$2"
                shift 2
                ;;
            -c|--color)
                opts[c]="$2"
                shift 2
                ;;
            -l|--language)
                opts[l]="$2"
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

    # script information

    [[ -v flags[V] ]] && {
        echo $VERSION
        return 0
    }
    
    [[ -v flags[h] ]] && {
        usage
        return 0
    }

    # operands

    [[ $# -eq 0 ]] || {
        echo_err "too many arguments"
        return 1
    }

    # options

    [[ -v opts[s] ]] && {
        is_positive "${opts[s]}" || {
            echo_err "invalid scale '${opts[s]}'"
            return 1
        }
    }

    [[ -v opts[c] ]] && {
        [[ "${opts[c]}" =~ ^(pink|blue)$ ]] || {
            echo_err "color '${opts[c]}' not supported"
            return 1
        }
    }

    [[ -v opts[l] ]] && {
        [[ "${opts[l]}" =~ ^(en|zh-CN|zh-TW|es|fr|de|ja|ko|ru|ar|pt|hi|it)$ ]] || {
            echo_err "language '${opts[l]}' not supported"
            return 1
        }
    }

    # ===== Variable Calculation =====

    # non-export

    build_dir="themes/onimai_mahiro_yukata${opts[S]}"

    scale=1
    [[ -v opts[s] ]] && \
        scale=${opts[s]}

    item_color=pink
    [[ -v opts[c] ]] && \
        item_color=${opts[c]}

    item_w_width=$(float_multiple_round 24 "$scale")

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
    ITEM_COLOR_HEX=#ee858c
    [[ ${opts[c]} = blue ]] && \
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
    [[ ${opts[l]} = zh-CN ]] && \
        TIMEOUT_TEXT="所选操作系统将在 %d 秒后启动"
    [[ ${opts[l]} = zh-TW ]] && \
        TIMEOUT_TEXT="所選作業系統將在 %d 秒後啟動"
    [[ ${opts[l]} = es ]] && \
        TIMEOUT_TEXT="El sistema operativo seleccionado se iniciará en %d segundos"
    [[ ${opts[l]} = fr ]] && \
        TIMEOUT_TEXT="Le système d'exploitation sélectionné sera démarré dans %d secondes"
    [[ ${opts[l]} = de ]] && \
        TIMEOUT_TEXT="Das ausgewählte Betriebssystem wird in %d Sekunden gestartet"
    [[ ${opts[l]} = ja ]] && \
        TIMEOUT_TEXT="選択されたOSは %d 秒後に起動します"
    [[ ${opts[l]} = ko ]] && \
        TIMEOUT_TEXT="선택한 운영 체제가 %d 초 후에 부팅됩니다"
    [[ ${opts[l]} = ru ]] && \
        TIMEOUT_TEXT="Выбранная ОС будет загружена через %d секунд"
    [[ ${opts[l]} = ar ]] && \
        TIMEOUT_TEXT="سيتم تشغيل نظام التشغيل المحدد خلال %d ثانية"
    [[ ${opts[l]} = pt ]] && \
        TIMEOUT_TEXT="O sistema operacional selecionado será inicializado em %d segundos"
    [[ ${opts[l]} = hi ]] && \
        TIMEOUT_TEXT="चयनित OS %d सेकंड में बूट हो जाएगा"
    [[ ${opts[l]} = it ]] && \
        TIMEOUT_TEXT="Il sistema operativo selezionato verrà avviato in %d secondi"
        
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

    mkdir -v -p "$build_dir/icons"

    # copy background

    cp -v $ASSETS_DIR/images/background.png "$build_dir"

    # create fonts

    for font_size in $FONT_SIZE_LARGER \
        $FONT_SIZE_SMALLER;
    do
        grub-mkfont -v \
            --name="$FONT_NAME" \
            --size="$font_size" \
            --output="$build_dir/${FONT_FILENAME%.*}-$font_size.pf2" \
            $ASSETS_DIR/fonts/$FONT_FILENAME
    done

    # copy font license

    cp -v $ASSETS_DIR/fonts/OFL.txt "$build_dir"

    # copy terminal box elements

    cp -v $ASSETS_DIR/images/terminal_box/* "$build_dir"

    # convert title

    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i $ASSETS_DIR/images/title.png \
        -vf "scale=$TITLE_WIDTH:-1" \
        "$build_dir/title.png"

    # convert distro icons

    for icon in "$ASSETS_DIR"/icons/*; do
        ffmpeg -loglevel $FFMPEG_LOGLEVEL \
            -i "$icon" \
            -vf "scale=$ICON_SIZE:$ICON_SIZE" \
            "$build_dir/icons/$(basename "$icon")"
    done

    # convert unselected item elements

    # west
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/item/$item_color/item_w_c.png" \
        -vf "scale=$item_w_width:$ITEM_HEIGHT" \
        "$build_dir/item_w.png"

    # central
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/item/$item_color/item_w_c.png" \
        -vf "scale=1:$ITEM_HEIGHT" \
        "$build_dir/item_c.png"

    # east
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/item/$item_color/item_e.png" \
        -vf "scale=-1:$ITEM_HEIGHT" \
        "$build_dir/item_e.png"

    # convert selected item elements

    # west
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/selected_item/$item_color/selected_item_w_c.png" \
        -vf "scale=$item_w_width:$ITEM_HEIGHT" \
        "$build_dir/selected_item_w.png"
    
    # central
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/selected_item/$item_color/selected_item_w_c.png" \
        -vf "scale=1:$ITEM_HEIGHT" \
        "$build_dir/selected_item_c.png"

    # east
    ffmpeg -loglevel $FFMPEG_LOGLEVEL \
        -i "$ASSETS_DIR/images/selected_item/$item_color/selected_item_e.png" \
        -vf "scale=-1:$ITEM_HEIGHT" \
        "$build_dir/selected_item_e.png"

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

    envsubst < $ASSETS_DIR/theme.txt.conf | tee "$build_dir/theme.txt"
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo_err "Do not 'source' this script. You should run it directly."
    exit 1
elif [[ "$(pwd -P)" != "$(cd "$(dirname "$0")" && pwd -P)" ]]; then
    echo_err "You should run this script in the project root directory."
    exit 1
else
    for cmd in bc grub-mkfont ffmpeg identify; do
        command -v $cmd >& /dev/null || {
            echo_err "command '$cmd' not found"
            exit 1
        }
    done
    
    main "$@"
    exit $?
fi