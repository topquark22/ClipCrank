#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
reject() { if ./clipcrank "$@" > "$work/error" 2>&1; then fail "unexpected success: $*"; fi; }
ffmpeg -v error -f lavfi -i sine=frequency=440 -t 1 -c:a libmp3lame -metadata title='Test song' "$work/plain.mp3"
./clipcrank --add-thumbnail --image examples/lenna.png "$work/plain.mp3" "$work/covered.mp3"
[ "$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name:stream_disposition=attached_pic -of csv=p=0 "$work/covered.mp3")" = 'mjpeg,1' ] || fail 'missing cover'
[ "$(ffprobe -v error -show_entries format_tags=title -of csv=p=0 "$work/covered.mp3")" = 'Test song' ] || fail 'metadata lost'
for name in plain covered; do
    ffmpeg -v error -i "$work/$name.mp3" -map 0:a:0 -c copy -f data "$work/$name.data"
done
cmp "$work/plain.data" "$work/covered.data" || fail 'audio was modified'
ffmpeg -v error -i "$work/covered.mp3" -map 0:a:0 -f null -
reject --add-thumbnail --image examples/lenna.png "$work/covered.mp3" "$work/rejected.mp3"
rg -q 'use --replace' "$work/error" || fail 'missing replacement warning'
[ ! -e "$work/rejected.mp3" ] || fail 'created output after rejection'
ffmpeg -v error -f lavfi -i color=red:s=32x32 -frames:v 1 "$work/red.jpg"
./clipcrank --add-thumbnail --replace --image "$work/red.jpg" "$work/covered.mp3" "$work/replaced.mp3"
[ "$(ffprobe -v error -select_streams v -show_entries stream=index -of csv=p=0 "$work/replaced.mp3" | wc -l)" -eq 1 ] || fail 'multiple covers'
[ "$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$work/replaced.mp3")" = '32,32' ] || fail 'cover not replaced'
reject --add-thumbnail --image examples/lenna.png "$work/plain.mp3"
rg -q 'explicit output file' "$work/error" || fail 'missing explicit output guidance'
reject --add-thumbnail --image examples/lenna.png "$work/plain.mp3" ''
rg -q 'explicit output file' "$work/error" || fail 'empty output accepted'
./clipcrank --add-thumbnail --replace --image examples/lenna.png examples/with_image.mp3 "$work/fixture-cover.mp3"
[ "$(ffprobe -v error -show_entries format=format_name -of csv=p=0 "$work/fixture-cover.mp3")" = mp3 ] || fail 'MP3 cover fixture misclassified'
reject --add-thumbnail "$work/plain.mp3" "$work/no-image.mp3"
rg -q 'require --image' "$work/error" || fail 'missing image guidance'
reject --add-thumbnail --frame 0 "$work/plain.mp3" "$work/frame.mp3"
reject --add-thumbnail --image examples/lenna.png "$work/plain.mp3" "$work/wrong.mp4"
reject --add-thumbnail --image examples/lenna.png "$work/plain.mp3" "$work/covered.mp3"
rg -q 'already exists' "$work/error" || fail 'overwrite protection'
./clipcrank --add-thumbnail --force --image examples/lenna.png "$work/plain.mp3" "$work/covered.mp3"
ln "$work/plain.mp3" "$work/alias.mp3"
reject --add-thumbnail --force --image examples/lenna.png "$work/plain.mp3" "$work/alias.mp3"
rg -q 'paths must be different' "$work/error" || fail 'input alias protection'
# Invalid cover input must not replace an existing output.
reject --add-thumbnail --force --image "$work/plain.mp3" "$work/plain.mp3" "$work/covered.mp3"
ffmpeg -v error -i "$work/covered.mp3" -map 0:a:0 -c copy -f data "$work/after.data"
cmp "$work/plain.data" "$work/after.data" || fail 'failed operation damaged output'
[ -z "$(find "$work" -name '*.part.*' -print)" ] || fail 'temporary files left behind'
printf 'PASS: MP3 cover addition, replacement, audio integrity, metadata, and validation\n'
