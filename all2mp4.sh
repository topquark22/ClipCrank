#!/usr/bin/env bash
set -eu

progname="${0##*/}"

preserve_metadata=false
clear_metadata=false
metadata_args=()
positional_args=()

usage() {
    cat <<EOF
Usage: $progname [OPTIONS] INPUT [OUTPUT]

Convert INPUT video into a standardized H.264/AAC MP4 file.

Arguments:
  INPUT                    Path to input video file
  OUTPUT                   Optional output .mp4 path

Options:
  --metadata KEY=VALUE     Set an MP4 metadata field; may be repeated
  --title TEXT             Set title metadata
  --artist TEXT            Set artist metadata
  --album TEXT             Set album metadata
  --date TEXT              Set date metadata
  --comment TEXT           Set comment metadata
  --preserve-metadata      Preserve input global metadata before applying edits
  --clear-metadata         Clear input global metadata before applying edits
  -h, --help               Show this help text

Examples:
  $progname old-video.avi
  $progname input.mov output.mp4
  $progname --title "New Title" input.avi
  $progname --clear-metadata --comment "recoded" input.wmv output.mp4
EOF
}

error() {
    printf '%s: %s\n' "$progname" "$*" >&2
}

info() {
    printf '%s: %s\n' "$progname" "$*"
}

have_command() {
    command -v "$1" >/dev/null 2>&1
}

derive_output_path() {
    input=$1

    case "$input" in
        *.*) printf '%s\n' "${input%.*}.mp4" ;;
        *)   printf '%s\n' "${input}.mp4" ;;
    esac
}

add_metadata() {
    key=$1
    value=$2

    metadata_args+=( -metadata "$key=$value" )
}

add_metadata_pair() {
    pair=$1

    case "$pair" in
        *=*) metadata_args+=( -metadata "$pair" ) ;;
        *)
            error "metadata must be in KEY=VALUE form: $pair"
            exit 2
            ;;
    esac
}

require_option_value() {
    option=$1

    if [ "$#" -lt 2 ]; then
        error "$option requires a value"
        exit 2
    fi
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --metadata)
                require_option_value "$1" "${2-}"
                add_metadata_pair "$2"
                shift 2
                ;;
            --metadata=*)
                add_metadata_pair "${1#--metadata=}"
                shift
                ;;
            --title)
                require_option_value "$1" "${2-}"
                add_metadata title "$2"
                shift 2
                ;;
            --title=*)
                add_metadata title "${1#--title=}"
                shift
                ;;
            --artist)
                require_option_value "$1" "${2-}"
                add_metadata artist "$2"
                shift 2
                ;;
            --artist=*)
                add_metadata artist "${1#--artist=}"
                shift
                ;;
            --album)
                require_option_value "$1" "${2-}"
                add_metadata album "$2"
                shift 2
                ;;
            --album=*)
                add_metadata album "${1#--album=}"
                shift
                ;;
            --date)
                require_option_value "$1" "${2-}"
                add_metadata date "$2"
                shift 2
                ;;
            --date=*)
                add_metadata date "${1#--date=}"
                shift
                ;;
            --comment)
                require_option_value "$1" "${2-}"
                add_metadata comment "$2"
                shift 2
                ;;
            --comment=*)
                add_metadata comment "${1#--comment=}"
                shift
                ;;
            --preserve-metadata)
                preserve_metadata=true
                shift
                ;;
            --clear-metadata)
                clear_metadata=true
                shift
                ;;
            --)
                shift
                while [ "$#" -gt 0 ]; do
                    positional_args+=( "$1" )
                    shift
                done
                ;;
            --*)
                error "unknown option: $1"
                usage >&2
                exit 2
                ;;
            *)
                positional_args+=( "$1" )
                shift
                ;;
        esac
    done

    if [ "$preserve_metadata" = true ] && [ "$clear_metadata" = true ]; then
        error "--preserve-metadata and --clear-metadata cannot be used together"
        exit 2
    fi
}

have_encoder() {
    encoder=$1
    ffmpeg -hide_banner -encoders 2>/dev/null | awk '{print $2}' | grep -Fx "$encoder" >/dev/null 2>&1
}

select_video_encoder() {
    for encoder in \
        libx264 \
        libopenh264 \
        h264_nvenc \
        h264_qsv \
        h264_amf \
        h264_mf \
        h264_d3d12va \
        h264_vulkan \
        h264_videotoolbox
    do
        if have_encoder "$encoder"; then
            printf '%s\n' "$encoder"
            return 0
        fi
    done

    return 1
}

have_aac_encoder() {
    have_encoder aac
}

video_encoder_args() {
    encoder=$1

    case "$encoder" in
        libx264)
            printf '%s\n' \
                -c:v libx264 \
                -preset medium \
                -crf 23
            ;;
        libopenh264)
            printf '%s\n' \
                -c:v libopenh264 \
                -b:v 5000k
            ;;
        h264_nvenc|h264_qsv|h264_amf|h264_mf|h264_d3d12va|h264_vulkan|h264_videotoolbox)
            printf '%s\n' \
                -c:v "$encoder" \
                -b:v 5000k
            ;;
        *)
            error "unsupported encoder selection: $encoder"
            return 1
            ;;
    esac
}

run_ffmpeg() {
    encoder=$1
    input=$2
    tmp_output=$3

    encoder_args=()
    while IFS= read -r arg; do
        encoder_args+=( "$arg" )
    done <<EOF
$(video_encoder_args "$encoder")
EOF

    metadata_mode_args=()
    if [ "$clear_metadata" = true ]; then
        metadata_mode_args=( -map_metadata -1 )
    elif [ "$preserve_metadata" = true ]; then
        metadata_mode_args=( -map_metadata 0 )
    fi

    ffmpeg \
        -hide_banner \
        -loglevel error \
        -y \
        -fflags +genpts \
        -i "$input" \
        -map 0:v:0 \
        -map 0:a? \
        -dn \
        -sn \
        "${metadata_mode_args[@]}" \
        "${metadata_args[@]}" \
        "${encoder_args[@]}" \
        -pix_fmt yuv420p \
        -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
        -movflags +faststart \
        -c:a aac \
        -b:a 192k \
        -f mp4 \
        "$tmp_output"
}

parse_args "$@"

if [ "${#positional_args[@]}" -lt 1 ] || [ "${#positional_args[@]}" -gt 2 ]; then
    usage >&2
    exit 2
fi

input=${positional_args[0]}
output=${positional_args[1]:-$(derive_output_path "$input")}

if ! have_command ffmpeg; then
    error "ffmpeg is not installed or not on PATH"
    exit 127
fi

if [ ! -e "$input" ]; then
    error "input file not found: $input"
    exit 1
fi

if [ ! -f "$input" ]; then
    error "input path is not a regular file: $input"
    exit 1
fi

if [ ! -r "$input" ]; then
    error "input file is not readable: $input"
    exit 1
fi

if [ "$input" = "$output" ]; then
    error "input and output paths must be different"
    exit 1
fi

if [ -e "$output" ]; then
    error "output file already exists: $output"
    exit 1
fi

if ! have_aac_encoder; then
    error "AAC encoder not found in ffmpeg"
    exit 1
fi

case "$output" in
    *.mp4) tmp_output="${output%.mp4}.part.mp4" ;;
    *)     tmp_output="${output}.part.mp4" ;;
esac

if ! video_encoder=$(select_video_encoder); then
    error "no supported H.264 encoder found in ffmpeg"
    error "tried: libx264, libopenh264, h264_nvenc, h264_qsv, h264_amf, h264_mf, h264_d3d12va, h264_vulkan, h264_videotoolbox"
    exit 1
fi

info "using video encoder: $video_encoder"

cleanup() {
    if [ -e "$tmp_output" ]; then
        rm -f "$tmp_output"
    fi
}

trap cleanup EXIT INT TERM HUP

if ! run_ffmpeg "$video_encoder" "$input" "$tmp_output"; then
    error "conversion failed"
    exit 1
fi

mv -- "$tmp_output" "$output"

trap - EXIT INT TERM HUP

printf 'created: %s\n' "$output"
