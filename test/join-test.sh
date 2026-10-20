#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
reject() { if ./clipcrank "$@" > "$work/error" 2>&1; then fail "unexpected success: $*"; fi; }
ffmpeg -v error -f lavfi -i testsrc2=s=160x120:r=24 -f lavfi -i sine=r=44100 -t 1 -c:v libx264 -c:a aac "$work/one's video.mp4"
cp "$work/one's video.mp4" "$work/two.mp4"
ffmpeg -v error -i "$work/two.mp4" -c copy "$work/other-container.mov"
ffmpeg -v error -f lavfi -i color=red:s=120x160:r=30 -t 1 -c:v libvpx-vp9 "$work/mixed.webm"
./clipcrank --join "$work/one's video.mp4" "$work/other-container.mov" "$work/copy.mp4"
[ "$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$work/copy.mp4")" = h264 ] || fail 'copied codec'
reject --join "$work/one's video.mp4" "$work/mixed.webm" "$work/rejected.mp4"
rg -q 'use --join --reencode' "$work/error" || fail 'missing actionable error'
[ ! -e "$work/rejected.mp4" ] || fail 'created incompatible output'
ffmpeg -v error -i "$work/two.mp4" -an -c:v copy "$work/no-audio.mp4"
reject --join "$work/two.mp4" "$work/no-audio.mp4" "$work/audio-mismatch.mp4"
rg -q 'use --join --reencode' "$work/error" || fail 'audio compatibility check'
ffmpeg -v error -i "$work/two.mp4" -vf scale=128:96 -c:v libx264 -c:a copy "$work/different-size.mp4"
reject --join "$work/two.mp4" "$work/different-size.mp4" "$work/size-mismatch.mp4"
rg -q 'use --join --reencode' "$work/error" || fail 'same-codec compatibility check'
./clipcrank --join --reencode "$work/one's video.mp4" "$work/mixed.webm" "$work/normalized.mp4"
[ "$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 "$work/normalized.mp4")" = '160,120,24/1' ] || fail 'video normalization'
[ "$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels -of csv=p=0 "$work/normalized.mp4")" = 'aac,48000,2' ] || fail 'audio normalization'
duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$work/normalized.mp4")
awk -v d="$duration" 'BEGIN { exit !(d >= 1.9 && d <= 2.2) }' || fail 'joined duration'
# Decode the whole file and verify the second segment is red and silent.
ffmpeg -v error -i "$work/normalized.mp4" -f null -
ffmpeg -v error -ss 1.5 -i "$work/normalized.mp4" -frames:v 1 -vf crop=2:2,scale=1:1 -pix_fmt rgb24 -f rawvideo "$work/pixel"
read -r red green blue <<< "$(od -An -tu1 "$work/pixel")"
[ "$red" -gt 180 ] && [ "$green" -lt 40 ] && [ "$blue" -lt 40 ] || fail 'segment order/content'
ffmpeg -hide_banner -ss 1.5 -i "$work/normalized.mp4" -t 0.3 -af volumedetect -f null - 2> "$work/volume"
rg -q 'max_volume: -(9[01]|[1-9][0-9]{2})' "$work/volume" || fail 'missing silent audio'
reject --join "$work/one's video.mp4" "$work/two.mp4" "$work/copy.mp4"
rg -q 'already exists' "$work/error" || fail 'overwrite protection'
./clipcrank --join --force "$work/two.mp4" "$work/two.mp4" "$work/copy.mp4"
reject --join "$work/two.mp4" "$work/missing.mp4" "$work/missing-output.mp4"
[ ! -e "$work/missing-output.mp4" ] || fail 'output after missing input'
reject --join --force "$work/two.mp4" "$work/one's video.mp4" "$work/two.mp4"
rg -q 'paths must be different' "$work/error" || fail 'input preservation'
reject --join "$work/two.mp4" "$work/short.mp4"
reject --join --start 0 "$work/two.mp4" "$work/two.mp4" "$work/bad.mp4"
./clipcrank --join --reencode --fps 25 "$work/mixed.webm" "$work/mixed.webm" "$work/silent.mp4"
[ -z "$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$work/silent.mp4")" ] || fail 'unexpected audio'
printf 'PASS: join compatibility, normalization, content, duration, silence, and validation\n'
