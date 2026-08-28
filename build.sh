#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -Eeo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

#-------------------------------------------------------------------------------
# Macros
#-------------------------------------------------------------------------------
readonly VERSION=0.3.0
readonly THEME_NAME_BASE=onimai_mahiro_yukata
readonly ASSETS_DIR=assets
readonly BUILD_DIR=build
readonly FONT_FILE="MapleMono-NF-CN-Regular.ttf"
readonly FONT_NAME="Maple Mono NF CN"
readonly FONT_STYLE="Regular"

#-------------------------------------------------------------------------------
# Utility Functions
#-------------------------------------------------------------------------------
echo_err() {
    echo "Error: $*" >&2
}

is_positive() {
    local str
    str="$(
        printf '%s' "$1" | \
            sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
    )"
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

#-------------------------------------------------------------------------------
# Business Functions
#-------------------------------------------------------------------------------
usage() {
    cat >&2 << EOF
Usage: $0 [ option ]
Onimai Mahiro (Yukata) GRUB Theme build script

Options:
  [Script information]
    -h, --help
        Display this help and exit.
    -V, --version
        Output version information and exit.
  [Build]
    -S, --suffix=<suffix>
        Append a suffix to the theme name.
        Note: You may need to add an underscore (_) at the beginning of the
          suffix.
        Warning: To ensure maximum compatibility, it is suggested that the
          suffix contains lowercase letters, numbers, and underscores only.
    -s, --scale=<scale>
        Specify the zoom scale of elements except the background.
        Note: If expected to show larger and fewer elements on high-resolution
          displayers, the scale should be set to 1.5 and even bigger.
    -c, --color={ pink | blue }
        Specify the boot menu item color style. [default: pink]
        Pink is with female symbols, blue with male ones.
    -l, --language=<language>
        Sepcify the timeout prompt language. [default: en]
        Available languages: 'en', 'zh-CN', 'zh-TW', 'es', 'fr', 'de', 'ja',
          'ko', 'ru', 'ar', 'pt', 'hi', 'it'.

Examples:
  $0 -l zh-CN
  $0 -s 1.5 -c blue -l zh-TW
  $0 --color=pink --language=ja
  $0 --scale 0.75 --color blue --language en --suffix=_tux
EOF
}

gen_terminal_box() {
    local border_outer_thickness=10
    local border_inner_thickness=4

    local border_outer_color="#FFB8C6"
    local border_inner_color="#FFE796"

    local output_prefix="${theme_output_dir:=.}/terminal_box"

    local fillet_radius=$((border_outer_thickness + border_inner_thickness + 2))
    local full_image_sidelen=$((fillet_radius * 2 + 1))

    local border_outer_x1=0
    local border_outer_y1=0
    local border_outer_x2=$((full_image_sidelen - 1))
    local border_outer_y2=$((full_image_sidelen - 1))
    local border_outer_radius=$fillet_radius

    local border_inner_x1=$border_outer_thickness
    local border_inner_y1=$border_outer_thickness
    local border_inner_x2=$((full_image_sidelen - 1 - border_outer_thickness))
    local border_inner_y2=$((full_image_sidelen - 1 - border_outer_thickness))
    local border_inner_radius=$((fillet_radius - border_outer_thickness))

    local content_x1=$((border_outer_thickness + border_inner_thickness))
    local content_y1=$((border_outer_thickness + border_inner_thickness))
    local content_x2=$((
        full_image_sidelen - 1 - border_outer_thickness - border_inner_thickness
    ))
    local content_y2=$((
        full_image_sidelen - 1 - border_outer_thickness - border_inner_thickness
    ))
    local content_radius=$((
        fillet_radius - border_outer_thickness - border_inner_thickness
    ))

    local tmp
    tmp=$(mktemp -d "/tmp/XXXXXXXXXX")

    local full_image="$tmp/full_image.png"

    convert -size ${full_image_sidelen}x${full_image_sidelen} xc:none \
        -fill "$border_outer_color" \
            -draw "roundrectangle $border_outer_x1,$border_outer_y1 $border_outer_x2,$border_outer_y2 $border_outer_radius,$border_outer_radius" \
        -fill "$border_inner_color" \
            -draw "roundrectangle $border_inner_x1,$border_inner_y1 $border_inner_x2,$border_inner_y2 $border_inner_radius,$border_inner_radius" \
        -fill "$BACKGROUND_COLOR" \
            -draw "roundrectangle $content_x1,$content_y1 $content_x2,$content_y2 $content_radius,$content_radius" \
        -alpha on -colorspace sRGB \
        "$full_image"

    local default_opts=(+repage -alpha on -define png:format=png32)
    convert "$full_image" -crop ${fillet_radius}x${fillet_radius}+0+0 "${default_opts[@]}" "${output_prefix}_nw.png"
    convert "$full_image" -crop $((full_image_sidelen - 2*fillet_radius))x${fillet_radius}+${fillet_radius}+0 "${default_opts[@]}" "${output_prefix}_n.png"
    convert "$full_image" -crop ${fillet_radius}x${fillet_radius}+$((full_image_sidelen - fillet_radius))+0 "${default_opts[@]}" "${output_prefix}_ne.png"
    convert "$full_image" -crop ${fillet_radius}x$((full_image_sidelen - 2*fillet_radius))+0+${fillet_radius} "${default_opts[@]}" "${output_prefix}_w.png"
    convert "$full_image" -crop $((full_image_sidelen - 2*fillet_radius))x$((full_image_sidelen - 2*fillet_radius))+${fillet_radius}+${fillet_radius} "${default_opts[@]}" "${output_prefix}_c.png"
    convert "$full_image" -crop ${fillet_radius}x$((full_image_sidelen - 2*fillet_radius))+$((full_image_sidelen - fillet_radius))+${fillet_radius} "${default_opts[@]}" "${output_prefix}_e.png"
    convert "$full_image" -crop ${fillet_radius}x${fillet_radius}+0+$((full_image_sidelen - fillet_radius)) "${default_opts[@]}" "${output_prefix}_sw.png"
    convert "$full_image" -crop $((full_image_sidelen - 2*fillet_radius))x${fillet_radius}+${fillet_radius}+$((full_image_sidelen - fillet_radius)) "${default_opts[@]}" "${output_prefix}_s.png"
    convert "$full_image" -crop ${fillet_radius}x${fillet_radius}+$((full_image_sidelen - fillet_radius))+$((full_image_sidelen - fillet_radius)) "${default_opts[@]}" "${output_prefix}_se.png"
}

#-------------------------------------------------------------------------------
# Main Functions
#-------------------------------------------------------------------------------
main() {
    # >>> Stage A: Parse arguments

    opt_short=hVs:S:c:l:
    opt_long=help,version,scale:,suffix:,color:,language:

    opt="$(getopt -o "$opt_short" -l "$opt_long" -n "$0" -- "$@")"
    eval set -- "$opt"

    declare -A flags
    declare -A opts
    
    while true; do
        case "$1" in
            -h|--help)
                flags[h]=
                shift 1
                ;;
            -V|--version)
                flags[V]=
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

    # >>> Stage B: Check arguments

    #   1. Script information

    [[ -v flags[h] ]] && {
        usage
        return 0
    }

    [[ -v flags[V] ]] && {
        echo "$VERSION"
        return 0
    }
    
    #   2. Operands

    [[ $# -eq 0 ]] || {
        echo_err "too many arguments"
        return 1
    }

    #   3. Options

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

    # >>> Stage C: Declare variables

    #   1. For theme output

    theme_name="${THEME_NAME_BASE}${opts[S]}"
    theme_output_dir="$BUILD_DIR/themes/$theme_name"

    #   2. Local

    scale=${opts[s]:=1}

    font="$FONT_NAME $FONT_STYLE"
    font_size_larger=$(float_multiple_round 22 "$scale")
    font_size_smaller=$(float_multiple_round 19 "$scale")
    font_larger="$font $font_size_larger"
    font_smaller="$font $font_size_smaller"

    brand_h2w_ratio="$(identify -format '%h/%w' $ASSETS_DIR/images/brand.png)"

    icon_size=$(float_multiple_round 36 "$scale")

    item_color_style=${opts[c]:=pink}

    item_w_width=$(float_multiple_round 24 "$scale")

    #   3. For theme config

    DESKTOP_IMAGE=background.png
    DESKTOP_IMAGE_SCALE_METHOD=crop

    TITLE_TEXT=" "

    MESSAGE_FONT="$font_larger"

    BRAND_LEFT=0
    BRAND_WIDTH=$(float_multiple_round 850 "$scale")
    BRAND_TOP=$(float_multiple_round 54 "$scale")
    BRAND_HEIGHT=$(float_multiple_round "$BRAND_WIDTH" "$brand_h2w_ratio")
    BRAND_FILE=brand.png

    BOOT_MENU_LEFT=0
    BOOT_MENU_WIDTH=$(float_multiple_round 667 "$scale")
    BOOT_MENU_TOP=$(float_multiple_round 300 "$scale")
    BOOT_MENU_HEIGHT=84%-$BOOT_MENU_TOP

    ICON_WIDTH=$icon_size
    ICON_HEIGHT=$icon_size

    ITEM_HEIGHT=$(float_multiple_round 68 "$scale")
    ITEM_PADDING=0
    ITEM_ICON_SPACE=$(float_multiple_round 18 "$scale")
    ITEM_SPACING=$(float_multiple_round 16 "$scale")
    ITEM_COLOR=#ee858c
    [[ $item_color_style = blue ]] && \
        ITEM_COLOR=#45bbff
    ITEM_FONT="$font_larger"
    ITEM_PIXMAP_STYLE='item_*.png'

    SELECTED_ITEM_COLOR=#926453
    SELECTED_ITEM_FONT="$font_larger"
    SELECTED_ITEM_PIXMAP_STYLE='selected_item_*.png'

    TIMEOUT_LEFT=$(float_multiple_round 77 "$scale")
    TIMEOUT_TOP=$(
        round "$(
            bc -l \
                <<< "($BRAND_TOP + $BRAND_HEIGHT + $BOOT_MENU_TOP) / 2 \
                    - $font_size_larger * 3 / 4"
        )"
    )
    TIMEOUT_ALIGN=center
    TIMEOUT_FONT="$font_larger"
    case ${opts[l]} in
        zh-CN)
            TIMEOUT_TEXT="所选操作系统将在 %d 秒后启动"
            ;;
        zh-TW)
            TIMEOUT_TEXT="所選作業系統將在 %d 秒後啟動"
            ;;
        es)
            TIMEOUT_TEXT="El sistema operativo seleccionado se iniciará en %d segundos"
            ;;
        fr)
            TIMEOUT_TEXT="Le système d'exploitation sélectionné sera démarré dans %d secondes"
            ;;
        de)
            TIMEOUT_TEXT="Das ausgewählte Betriebssystem wird in %d Sekunden gestartet"
            ;;
        ja)
            TIMEOUT_TEXT="選択されたOSは %d 秒後に起動します"
            ;;
        ko)
            TIMEOUT_TEXT="선택한 운영 체제가 %d 초 후에 부팅됩니다"
            ;;
        ru)
            TIMEOUT_TEXT="Выбранная ОС будет загружена через %d секунд"
            ;;
        ar)
            TIMEOUT_TEXT="سيتم تشغيل نظام التشغيل المحدد خلال %d ثانية"
            ;;
        pt)
            TIMEOUT_TEXT="O sistema operacional selecionado será inicializado em %d segundos"
            ;;
        hi)
            TIMEOUT_TEXT="चयनित OS %d सेकंड में बूट हो जाएगा"
            ;;
        it)
            TIMEOUT_TEXT="Il sistema operativo selezionato verrà avviato in %d secondi"
            ;;
        *)
            TIMEOUT_TEXT="Selected OS will be booted in %d seconds"
            ;;
    esac
    TIMEOUT_COLOR=#777777

    TERMINAL_FONT="$font_smaller"
    TERMINAL_BOX='terminal_box_*.png'
    TERMINAL_LEFT=$(float_multiple_round 32 "$scale")
    TERMINAL_WIDTH=48%
    TERMINAL_TOP=$(
        round "$(
            bc -l \
                <<< "($BRAND_TOP + $BRAND_HEIGHT + $BOOT_MENU_TOP) / 2"
        )"
    )
    TERMINAL_HEIGHT=84%-$TERMINAL_TOP
    TERMINAL_BORDER=0

    #   4. For customized config script

    BACKGROUND_COLOR=#FFF9F2
    COLOR_NORMAL=dark-gray/black

    # >>> Stage D: Generate theme

    #   1. Create necessary directories

    mkdir -v -p "$theme_output_dir/icons"

    #   2. Copy background image (desktop image)

    cp -v $ASSETS_DIR/images/$DESKTOP_IMAGE "$theme_output_dir"

    #   3. Create fonts

    for font_size in $font_size_larger $font_size_smaller; do
        grub-mkfont -v \
            --name="$FONT_NAME" \
            --size="$font_size" \
            --output="$theme_output_dir/${FONT_FILE%.*}-$font_size.pf2" \
            $ASSETS_DIR/fonts/$FONT_FILE
    done

    #   4. Copy font license

    cp -v $ASSETS_DIR/fonts/OFL.txt "$theme_output_dir"

    #   5. Convert brand picture

    ffmpeg -loglevel trace \
        -i $ASSETS_DIR/images/brand.png \
        -vf "scale=$BRAND_WIDTH:-1" \
        "$theme_output_dir/brand.png"

    #   6. Convert distro icons

    for icon in "$ASSETS_DIR"/icons/*; do
        ffmpeg -loglevel trace \
            -i "$icon" \
            -vf "scale=$ICON_WIDTH:$ICON_HEIGHT" \
            "$theme_output_dir/icons/$(basename "$icon")"
    done

    #   7. Convert unselected item elements

    # west
    ffmpeg -loglevel trace \
        -i "$ASSETS_DIR/images/item/$item_color_style/item_w_c.png" \
        -vf "scale=$item_w_width:$ITEM_HEIGHT" \
        "$theme_output_dir/item_w.png"

    # central
    ffmpeg -loglevel trace \
        -i "$ASSETS_DIR/images/item/$item_color_style/item_w_c.png" \
        -vf "scale=1:$ITEM_HEIGHT" \
        "$theme_output_dir/item_c.png"

    # east
    ffmpeg -loglevel trace \
        -i "$ASSETS_DIR/images/item/$item_color_style/item_e.png" \
        -vf "scale=-1:$ITEM_HEIGHT" \
        "$theme_output_dir/item_e.png"

    #   8. Convert selected item elements

    # west
    ffmpeg -loglevel trace \
        -i "$ASSETS_DIR/images/selected_item/$item_color_style/selected_item_w_c.png" \
        -vf "scale=$item_w_width:$ITEM_HEIGHT" \
        "$theme_output_dir/selected_item_w.png"
    
    # central
    ffmpeg -loglevel trace \
        -i "$ASSETS_DIR/images/selected_item/$item_color_style/selected_item_w_c.png" \
        -vf "scale=1:$ITEM_HEIGHT" \
        "$theme_output_dir/selected_item_c.png"

    # east
    ffmpeg -loglevel trace \
        -i "$ASSETS_DIR/images/selected_item/$item_color_style/selected_item_e.png" \
        -vf "scale=-1:$ITEM_HEIGHT" \
        "$theme_output_dir/selected_item_e.png"

    #   9. Create terminal box elements

    gen_terminal_box

    #   10. Generate theme config

    export DESKTOP_IMAGE
    export DESKTOP_IMAGE_SCALE_METHOD

    export TITLE_TEXT

    export MESSAGE_FONT

    export BRAND_LEFT
    export BRAND_WIDTH
    export BRAND_TOP
    export BRAND_HEIGHT
    export BRAND_FILE

    export BOOT_MENU_LEFT
    export BOOT_MENU_WIDTH
    export BOOT_MENU_TOP
    export BOOT_MENU_HEIGHT

    export ICON_WIDTH
    export ICON_HEIGHT

    export ITEM_HEIGHT
    export ITEM_PADDING
    export ITEM_ICON_SPACE
    export ITEM_SPACING
    export ITEM_COLOR
    export ITEM_FONT
    export ITEM_PIXMAP_STYLE

    export SELECTED_ITEM_COLOR
    export SELECTED_ITEM_FONT
    export SELECTED_ITEM_PIXMAP_STYLE

    export TIMEOUT_LEFT
    export TIMEOUT_TOP
    export TIMEOUT_ALIGN
    export TIMEOUT_FONT
    export TIMEOUT_TEXT

    export TIMEOUT_COLOR

    export TERMINAL_FONT
    export TERMINAL_BOX
    export TERMINAL_LEFT
    export TERMINAL_WIDTH
    export TERMINAL_TOP
    export TERMINAL_HEIGHT
    export TERMINAL_BORDER

    envsubst < $ASSETS_DIR/theme.txt.template | tee "$theme_output_dir/theme.txt"

    #   11. Generate customized config script

    export BACKGROUND_COLOR
    export COLOR_NORMAL

    echo
    envsubst < $ASSETS_DIR/99_mahiro.template | tee "$BUILD_DIR/99_mahiro"
    echo
    chmod -v +x "$BUILD_DIR/99_mahiro"
}

#-------------------------------------------------------------------------------
# Program Entry
#-------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo_err "Do not 'source' this script. You should run it directly."
    exit 1
elif [[ "$(pwd -P)" != "$(cd "$(dirname "$0")" && pwd -P)" ]]; then
    echo_err "You should run this script in the project root directory."
    exit 1
else
    for cmd in bc grub-mkfont ffmpeg identify convert; do
        command -v $cmd >& /dev/null || {
            echo_err "command '$cmd' not found"
            exit 1
        }
    done
    
    main "$@"
    exit $?
fi