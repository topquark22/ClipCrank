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

run_ffmpeg() {
    encoder=$1
    input=$2
    tmp_output=$3

    case "$encoder" in
        libx264)
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
                -c:v libx264 \
                -preset medium \
                -crf 23 \
                -pix_fmt yuv420p \
                -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
                -movflags +faststart \
                -c:a aac \
                -b:a 192k \
                -f mp4 \
                "$tmp_output"
            ;;
        libopenh264)
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
                -c:v libopenh264 \
                -b:v 5000k \
                -pix_fmt yuv420p \
                -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
                -movflags +faststart \
                -c:a aac \
                -b:a 192k \
                -f mp4 \
                "$tmp_output"
            ;;
        h264_nvenc)
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
                -c:v h264_nvenc \
                -b:v 5000k \
                -pix_fmt yuv420p \
                -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
                -movflags +faststart \
                -c:a aac \
                -b:a 192k \
                -f mp4 \
                "$tmp_output"
            ;;
        h264_qsv)
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
                -c:v h264_qsv \
                -b:v 5000k \
                -pix_fmt yuv420p \
                -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
                -movflags +faststart \
                -c:a aac \
                -b:a 192k \
                -f mp4 \
                "$tmp_output"
            ;;
        h264_amf)
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
                -c:v h264_amf \
                -b:v 5000k \
                -pix_fmt yuv420p \
                -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
                -movflags +faststart \
                -c:a aac \
                -b:a 192k \
                -f mp4 \
                "$tmp_output"
            ;;
        h264_mf)
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
                -c:v h264_mf \
                -b:v 5000k \
                -pix_fmt yuv420p \
                -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
                -movflags +faststart \
                -c:a aac \
                -b:a 192k \
                -f mp4 \
                "$tmp_output"
            ;;
        h264_d3d12va)
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
                -c:v h264_d3d12va \
                -b:v 5000k \
                -pix_fmt yuv420p \
                -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
                -movflags +faststart \
                -c:a aac \
                -b:a 192k \
                -f mp4 \
                "$tmp_output"
            ;;
        h264_vulkan)
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
                -c:v h264_vulkan \
                -b:v 5000k \
                -pix_fmt yuv420p \
                -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
                -movflags +faststart \
                -c:a aac \
                -b:a 192k \
                -f mp4 \
                "$tmp_output"
            ;;
        h264_videotoolbox)
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
                -c:v h264_videotoolbox \
                -b:v 5000k \
                -pix_fmt yuv420p \
                -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
                -movflags +faststart \
                -c:a aac \
                -b:a 192k \
                -f mp4 \
                "$tmp_output"
            ;;
        *)
            error "unsupported encoder selection: $encoder"
            return 1
            ;;
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