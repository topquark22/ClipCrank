#!/usr/bin/env bash
set -eu

progname="${0##*/}"

usage() {
    cat <<EOF
Usage: $progname INPUT [OUTPUT]

Convert INPUT video into a standardized H.264/AAC MP4 file.

Arguments:
  INPUT     Path to input video file
  OUTPUT    Optional output .mp4 path

Examples:
  $progname old-video.avi
  $progname input.mov output.mp4
EOF
}

error() {
    printf '%s: %s\n' "$progname" "$*" >&2
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

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage >&2
    exit 2
fi

input=$1
output=${2:-$(derive_output_path "$input")}

if ! have_command ffmpeg; then
    error "ffmpeg is not installed or not on PATH"
    exit 127
fi

if [ ! -e "$input" ]; then
    error "input file does not exist: $input"
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

tmp_output="${output}.part"

cleanup() {
    if [ -e "$tmp_output" ]; then
        rm -f "$tmp_output"
    fi
}

trap cleanup EXIT INT TERM HUP

if ! ffmpeg \
    -hide_banner \
    -loglevel error \
    -y \
    -fflags +genpts \
    -i "$input" \
    -map 0:v:0 \
    -map 0:a? \
    -dn \
    -sn \
    -c:v libx264 \
    -preset medium \
    -crf 23 \
    -pix_fmt yuv420p \
    -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
    -movflags +faststart \
    -c:a aac \
    -b:a 192k \
    "$tmp_output"
then
    error "conversion failed"
    exit 1
fi

mv -- "$tmp_output" "$output"

trap - EXIT INT TERM HUP

printf 'created: %s\n' "$output"