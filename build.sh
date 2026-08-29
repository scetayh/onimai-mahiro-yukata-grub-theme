#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -Eeo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

#-------------------------------------------------------------------------------
# Macros
#-------------------------------------------------------------------------------
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME
readonly VERSION=0.3.3

readonly MAXCOL=80

readonly THEME_NAME_BASE=onimai_mahiro_yukata
readonly THEME_FRIENDLY_NAME="Onimai Mahiro (Yukata) GRUB Theme"
readonly ASSETS_DIR=assets
readonly SCRIPTS_DIR=scripts
readonly BUILD_DIR=build
readonly FONT_FILE="MapleMono-NF-CN-Regular.ttf"
readonly FONT_NAME="Maple Mono NF CN"
readonly FONT_STYLE="Regular"
readonly GRUB_CUSTOM_CONFIG="99_mahiro"

readonly ONIMAI_PINK=#ee858c
readonly ONIMAI_BLUE=#45bbff
readonly ONIMAI_LIGHT_PINK=#ffd9dc
readonly ONIMAI_LIGHT_BLUE=#d4efff
readonly ONIMAI_BROWN=#926453
readonly ONIMAI_YELLOW=#fff899
readonly DARK_GRAY=#777777

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
    fmt -w $MAXCOL -s >&2 << EOF
Usage: $0 [ option ]
$THEME_FRIENDLY_NAME build script

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
      Warning: To ensure maximum compatibility, it is suggested that the suffix
      contains lowercase letters, numbers, and underscores only.
    -s, --scale=<scale>
      Specify the zoom scale of elements except the background.
      Note: If expected to show larger and fewer elements on high-resolution
      displayers, the scale should be set to 1.5 and even bigger.
    -c, --color={ pink | blue }
      Specify the boot menu item color style. [default: pink]
      Pink is with female symbols, blue with male ones.
    -l, --language=<language>
      Sepcify the timeout prompt language. [default: en]
      Available languages: 'en', 'zh-CN', 'zh-TW', 'es', 'fr', 'de', 'ja', 'ko',
      'ru', 'ar', 'pt', 'hi', 'it'.
    -v, --verbose
      Display detailed information.

Examples:
  $0 -l zh-CN
  $0 -s 1.5 -c blue -l zh-TW -v
  $0 --color=pink --language=ja --verbose
  $0 --scale 0.75 --color blue --language en --suffix=_tux
EOF
}

#-------------------------------------------------------------------------------
# Main Functions
#-------------------------------------------------------------------------------
main() {
    # >>> Stage A: Check command existence and versions

    for cmd in bc grub-mkfont identify magick convert; do
        command -v $cmd >& /dev/null || {
            echo_err "command '$cmd' not found"
            exit 1
        }
    done

    if magick -version 2>/dev/null | grep -q "ImageMagick 7"; then
        convert_cmd=(magick)
    else
        convert_cmd=(convert)
    fi

    # >>> Stage B: Check work directory

    [[ "$(pwd -P)" = "$(cd "$(dirname "$0")" && pwd -P)" ]] || {
        echo_err "You should run this script from its own directory."
        exit 1
    }

    # >>> Stage C: Parse arguments

    short_opts=hVs:S:c:l:v
    long_opts=help,version,scale:,suffix:,color:,language:,verbose,

    opts="$(getopt -o "$short_opts" -l "$long_opts" -n "$0" -- "$@")"
    eval set -- "$opts"

    declare -A flags params
    
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
                params[s]="$2"
                shift 2
                ;;
            -S|--suffix)
                params[S]="$2"
                shift 2
                ;;
            -c|--color)
                params[c]="$2"
                shift 2
                ;;
            -l|--language)
                params[l]="$2"
                shift 2
                ;;
            -v|--verbose)
                flags[v]=
                shift 1
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

    # >>> Stage D: Check arguments

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

    [[ -v params[s] ]] && {
        is_positive "${params[s]}" || {
            echo_err "invalid scale '${params[s]}'"
            return 1
        }
    }

    [[ -v params[c] ]] && {
        [[ "${params[c]}" =~ ^(pink|blue)$ ]] || {
            echo_err "color '${params[c]}' not supported"
            return 1
        }
    }

    [[ -v params[l] ]] && {
        [[ "${params[l]}" =~ ^(en|zh-CN|zh-TW|es|fr|de|ja|ko|ru|ar|pt|hi|it)$ ]] || {
            echo_err "language '${params[l]}' not supported"
            return 1
        }
    }

    #   4. Flags

    if [[ -v flags[v] ]]; then
        default_opts=(-v)
        convert_default_opts=(-debug Exception)
    else
        default_opts=()
        convert_default_opts=()
    fi

    # >>> Stage E: Declare variables

    #   1. For theme output

    THEME_NAME="${THEME_NAME_BASE}${params[S]}"
    THEME_DIR="themes/$THEME_NAME"

    #   2. Local

    scale=${params[s]:=1}

    font="$FONT_NAME $FONT_STYLE"
    font_size_larger=$(float_multiple_round 22 "$scale")
    font_size_smaller=$(float_multiple_round 19 "$scale")
    font_larger="$font $font_size_larger"
    font_smaller="$font $font_size_smaller"

    brand_h2w_ratio="$(identify -format '%h/%w' $ASSETS_DIR/images/brand.png)"

    icon_size=$(float_multiple_round 36 "$scale")

    color_style=${params[c]:=pink}

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
    ITEM_COLOR=$ONIMAI_PINK
    [[ $color_style = blue ]] && \
        ITEM_COLOR=$ONIMAI_BLUE
    ITEM_FONT="$font_larger"
    ITEM_PIXMAP_STYLE='item_*.png'

    SELECTED_ITEM_COLOR=$ONIMAI_BROWN
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
    case ${params[l]} in
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
    TIMEOUT_COLOR=$DARK_GRAY

    TERMINAL_FONT="$font_smaller"
    TERMINAL_BOX='terminal_box_*.png'
    TERMINAL_LEFT=$(float_multiple_round 36 "$scale")
    TERMINAL_WIDTH=48%
    TERMINAL_TOP=$(
        round "$(
            bc -l \
                <<< "($BRAND_TOP + $BRAND_HEIGHT + $BOOT_MENU_TOP) / 2"
        )"
    )
    TERMINAL_HEIGHT=88%-$TERMINAL_TOP
    TERMINAL_BORDER=0

    #   4. For customized config script

    BACKGROUND_COLOR=$ONIMAI_LIGHT_PINK
    [[ $color_style = blue ]] && \
        BACKGROUND_COLOR=$ONIMAI_LIGHT_BLUE
    COLOR_NORMAL=brown/black

    # >>> Stage F: Generate theme

    #   1. Create necessary directories

    mkdir "${default_opts[@]}" -p "$BUILD_DIR/$THEME_DIR/icons"

    #   2. Copy background image (desktop image)

    cp "${default_opts[@]}" $ASSETS_DIR/images/$DESKTOP_IMAGE "$BUILD_DIR/$THEME_DIR"

    #   3. Create fonts

    for font_size in $font_size_larger $font_size_smaller; do
        grub-mkfont "${default_opts[@]}" \
            --name="$FONT_NAME" \
            --size="$font_size" \
            --output="$BUILD_DIR/$THEME_DIR/${FONT_FILE%.*}-$font_size.pf2" \
            $ASSETS_DIR/fonts/$FONT_FILE
    done

    #   4. Copy font license

    cp "${default_opts[@]}" $ASSETS_DIR/fonts/OFL.txt "$BUILD_DIR/$THEME_DIR"

    #   5. Convert brand picture

    convert_default_opts+=(-define png:format=png32)

    "${convert_cmd[@]}" "${convert_default_opts[@]}" \
        "$ASSETS_DIR/images/brand.png" \
        -resize "${BRAND_WIDTH}x" \
        "$BUILD_DIR/$THEME_DIR/brand.png"

    #   6. Convert distro icons

    for icon in "$ASSETS_DIR"/icons/*; do
        "${convert_cmd[@]}" "${convert_default_opts[@]}" \
            "$icon" \
            -resize "${ICON_WIDTH}x${ICON_HEIGHT}!" \
            "$BUILD_DIR/$THEME_DIR/icons/$(basename "$icon")"
    done

    #   7. Convert unselected item elements

    # west
    "${convert_cmd[@]}" "${convert_default_opts[@]}" \
        "$ASSETS_DIR/images/item/$color_style/item_w_c.png" \
        -resize "${item_w_width}x${ITEM_HEIGHT}!" \
        "$BUILD_DIR/$THEME_DIR/item_w.png"

    # central
    "${convert_cmd[@]}" "${convert_default_opts[@]}" \
        "$ASSETS_DIR/images/item/$color_style/item_w_c.png" \
        -resize "1x${ITEM_HEIGHT}!" \
        "$BUILD_DIR/$THEME_DIR/item_c.png"

    # east
    "${convert_cmd[@]}" "${convert_default_opts[@]}" \
        "$ASSETS_DIR/images/item/$color_style/item_e.png" \
        -resize "x${ITEM_HEIGHT}" \
        "$BUILD_DIR/$THEME_DIR/item_e.png"

    #   8. Convert selected item elements

    # west
    "${convert_cmd[@]}" "${convert_default_opts[@]}" \
        "$ASSETS_DIR/images/selected_item/$color_style/selected_item_w_c.png" \
        -resize "${item_w_width}x${ITEM_HEIGHT}!" \
        "$BUILD_DIR/$THEME_DIR/selected_item_w.png"

    # central
    "${convert_cmd[@]}" "${convert_default_opts[@]}" \
        "$ASSETS_DIR/images/selected_item/$color_style/selected_item_w_c.png" \
        -resize "1x${ITEM_HEIGHT}!" \
        "$BUILD_DIR/$THEME_DIR/selected_item_c.png"

    # east
    "${convert_cmd[@]}" "${convert_default_opts[@]}" \
        "$ASSETS_DIR/images/selected_item/$color_style/selected_item_e.png" \
        -resize "x${ITEM_HEIGHT}" \
        "$BUILD_DIR/$THEME_DIR/selected_item_e.png"

    #   9. Create terminal box elements

    border_outer_thickness=5
    border_inner_thickness=9

    border_outer_color="${ONIMAI_YELLOW}"
    border_inner_color="${ONIMAI_PINK}"
    [[ $color_style = blue ]] && \
        border_inner_color="${ONIMAI_BLUE}"

    output_prefix="$BUILD_DIR/$THEME_DIR/terminal_box"

    fillet_radius=$((border_outer_thickness + border_inner_thickness + 2))
    full_image_sidelen=$((fillet_radius * 2 + 1))

    border_outer_x1=0
    border_outer_y1=0
    border_outer_x2=$((full_image_sidelen - 1))
    border_outer_y2=$((full_image_sidelen - 1))
    border_outer_radius=$fillet_radius

    border_inner_x1=$border_outer_thickness
    border_inner_y1=$border_outer_thickness
    border_inner_x2=$((full_image_sidelen - 1 - border_outer_thickness))
    border_inner_y2=$((full_image_sidelen - 1 - border_outer_thickness))
    border_inner_radius=$((fillet_radius - border_outer_thickness))

    content_x1=$((border_outer_thickness + border_inner_thickness))
    content_y1=$((border_outer_thickness + border_inner_thickness))
    content_x2=$((
        full_image_sidelen - 1 - border_outer_thickness - border_inner_thickness
    ))
    content_y2=$((
        full_image_sidelen - 1 - border_outer_thickness - border_inner_thickness
    ))
    content_radius=$((
        fillet_radius - border_outer_thickness - border_inner_thickness
    ))

    tmp=$(mktemp -d "/tmp/XXXXXXXXXX")

    full_image="$tmp/full_image.png"

    "${convert_cmd[@]}" "${convert_default_opts[@]}" \
        -size ${full_image_sidelen}x${full_image_sidelen} xc:none \
        -fill "$border_outer_color" \
        -draw "roundrectangle $border_outer_x1,$border_outer_y1 $border_outer_x2,$border_outer_y2 $border_outer_radius,$border_outer_radius" \
        -fill "$border_inner_color" \
        -draw "roundrectangle $border_inner_x1,$border_inner_y1 $border_inner_x2,$border_inner_y2 $border_inner_radius,$border_inner_radius" \
        -fill "$BACKGROUND_COLOR" \
        -draw "roundrectangle $content_x1,$content_y1 $content_x2,$content_y2 $content_radius,$content_radius" \
        -alpha on -colorspace sRGB \
        "$full_image"

    convert_default_opts+=(+repage -alpha on)
    
    "${convert_cmd[@]}" "$full_image" \
        -crop ${fillet_radius}x${fillet_radius}+0+0 \
        "${convert_default_opts[@]}" \
        "${output_prefix}_nw.png"
    "${convert_cmd[@]}" "$full_image" \
        -crop $((full_image_sidelen - 2*fillet_radius))x${fillet_radius}+${fillet_radius}+0 \
        "${convert_default_opts[@]}" \
        "${output_prefix}_n.png"
    "${convert_cmd[@]}" "$full_image" \
        -crop ${fillet_radius}x${fillet_radius}+$((full_image_sidelen - fillet_radius))+0 \
        "${convert_default_opts[@]}" \
        "${output_prefix}_ne.png"
    "${convert_cmd[@]}" "$full_image" \
        -crop ${fillet_radius}x$((full_image_sidelen - 2*fillet_radius))+0+${fillet_radius} \
        "${convert_default_opts[@]}" \
        "${output_prefix}_w.png"
    "${convert_cmd[@]}" "$full_image" \
        -crop $((full_image_sidelen - 2*fillet_radius))x$((full_image_sidelen - 2*fillet_radius))+${fillet_radius}+${fillet_radius} \
        "${convert_default_opts[@]}" \
        "${output_prefix}_c.png"
    "${convert_cmd[@]}" "$full_image" \
        -crop ${fillet_radius}x$((full_image_sidelen - 2*fillet_radius))+$((full_image_sidelen - fillet_radius))+${fillet_radius} \
        "${convert_default_opts[@]}" \
        "${output_prefix}_e.png"
    "${convert_cmd[@]}" "$full_image" \
        -crop ${fillet_radius}x${fillet_radius}+0+$((full_image_sidelen - fillet_radius)) \
        "${convert_default_opts[@]}" \
        "${output_prefix}_sw.png"
    "${convert_cmd[@]}" "$full_image" \
        -crop $((full_image_sidelen - 2*fillet_radius))x${fillet_radius}+${fillet_radius}+$((full_image_sidelen - fillet_radius)) \
        "${convert_default_opts[@]}" \
        "${output_prefix}_s.png"
    "${convert_cmd[@]}" "$full_image" \
        -crop ${fillet_radius}x${fillet_radius}+$((full_image_sidelen - fillet_radius))+$((full_image_sidelen - fillet_radius)) \
        "${convert_default_opts[@]}" \
        "${output_prefix}_se.png"

    #   10. Generate theme config

    whitelist=(
        DESKTOP_IMAGE
        DESKTOP_IMAGE_SCALE_METHOD

        TITLE_TEXT

        MESSAGE_FONT

        BRAND_LEFT
        BRAND_WIDTH
        BRAND_TOP
        BRAND_HEIGHT
        BRAND_FILE

        BOOT_MENU_LEFT
        BOOT_MENU_WIDTH
        BOOT_MENU_TOP
        BOOT_MENU_HEIGHT

        ICON_WIDTH
        ICON_HEIGHT

        ITEM_HEIGHT
        ITEM_PADDING
        ITEM_ICON_SPACE
        ITEM_SPACING
        ITEM_COLOR
        ITEM_FONT
        ITEM_PIXMAP_STYLE

        SELECTED_ITEM_COLOR
        SELECTED_ITEM_FONT
        SELECTED_ITEM_PIXMAP_STYLE

        TIMEOUT_LEFT
        TIMEOUT_TOP
        TIMEOUT_ALIGN
        TIMEOUT_FONT
        TIMEOUT_TEXT

        TIMEOUT_COLOR

        TERMINAL_FONT
        TERMINAL_BOX
        TERMINAL_LEFT
        TERMINAL_WIDTH
        TERMINAL_TOP
        TERMINAL_HEIGHT
        TERMINAL_BORDER
    )

    export "${whitelist[@]}"

    if [[ -v flags[v] ]]; then
        envsubst "$(printf '$%s ' "${whitelist[@]}")" \
            < $ASSETS_DIR/theme.txt.template | \
                tee "$BUILD_DIR/$THEME_DIR/theme.txt"
        echo >&2
    else
        envsubst "$(printf '$%s ' "${whitelist[@]}")" \
            < $ASSETS_DIR/theme.txt.template \
                > "$BUILD_DIR/$THEME_DIR/theme.txt"
    fi

    #   11. Generate customized config script

    whitelist=(
        BACKGROUND_COLOR
        COLOR_NORMAL
    )

    export "${whitelist[@]}"

    envsubst "$(printf '$%s ' "${whitelist[@]}")" \
        < $ASSETS_DIR/$GRUB_CUSTOM_CONFIG.template \
            > "$BUILD_DIR/$GRUB_CUSTOM_CONFIG"

    chmod "${default_opts[@]}" +x "$BUILD_DIR/$GRUB_CUSTOM_CONFIG"

    #   12. Generate installation script

    whitelist=(
        MAXCOL
        THEME_FRIENDLY_NAME
        SCRIPT_NAME
        VERSION
        THEME_DIR
        GRUB_CUSTOM_CONFIG
        THEME_NAME
    )

    export "${whitelist[@]}"

    envsubst "$(printf '$%s ' "${whitelist[@]}")" \
        < $SCRIPTS_DIR/install.sh.template \
            > "$BUILD_DIR/install.sh"

    chmod "${default_opts[@]}" +x "$BUILD_DIR/install.sh"

    # >>> Stage G: Print Build Completion info

    echo "Build completed. Run 'cd build && sudo ./install.sh' to install." >&2
}

#-------------------------------------------------------------------------------
# Program Entry
#-------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo_err "Do not 'source' this script. You should run it directly."
    exit 1
else
    main "$@"
    exit $?
fi