#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
reject() { if ./clipcrank "$@" > "$work/error" 2>&1; then fail "unexpected success: $*"; fi; }
ffmpeg -v error -f lavfi -i sine=frequency=440:sample_rate=44100 -t 1 -c:a libmp3lame "$work/one's audio.mp3"
ffmpeg -v error -f lavfi -i sine=frequency=880:sample_rate=44100 -t 1 -c:a libmp3lame "$work/two.mp3"
ffmpeg -v error -f lavfi -i sine=frequency=880:sample_rate=48000 -t 1 -ac 2 -c:a libmp3lame "$work/different.mp3"
./clipcrank --join "$work/one's audio.mp3" "$work/two.mp3" "$work/copied.mp3"
# Stream copying must retain the exact packet payloads from both inputs.
for name in "one's audio" two copied; do
    ffmpeg -v error -i "$work/$name.mp3" -map 0:a:0 -c copy -f data "$work/$name.data"
done
cat "$work/one's audio.data" "$work/two.data" > "$work/expected.data"
cmp "$work/expected.data" "$work/copied.data" || fail 'stream copy changed packets'
reject --join "$work/two.mp3" "$work/different.mp3" "$work/rejected.mp3"
rg -q 'use --join --reencode' "$work/error" || fail 'missing compatibility error'
[ ! -e "$work/rejected.mp3" ] || fail 'output from failed precheck'
./clipcrank --join --reencode "$work/one's audio.mp3" "$work/different.mp3" "$work/normalized.mp3"
[ "$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels -of csv=p=0 "$work/normalized.mp3")" = 'mp3,48000,2' ] || fail 'normalized audio format'
duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$work/normalized.mp3")
awk -v d="$duration" 'BEGIN { exit !(d >= 2 && d < 2.1) }' || fail 'joined duration'
ffmpeg -v error -i "$work/normalized.mp3" -f null -
# Verify ordering from the decoded signal, using zero crossings of each tone.
ffmpeg -v error -i "$work/normalized.mp3" -ac 1 -f s16le "$work/decoded.pcm"
python3 - "$work/decoded.pcm" <<'PY'
import array, sys
samples = array.array('h', open(sys.argv[1], 'rb').read())
for start, expected in [(0.2, 440), (1.2, 880)]:
    window = samples[int(start*48000):int((start+0.5)*48000)]
    crossings = sum(a < 0 <= b for a, b in zip(window, window[1:]))
    assert abs(crossings*2-expected) < 10, (start, crossings)
PY
ffmpeg -v error -i "$work/two.mp3" "$work/audio.wav"
reject --join "$work/audio.wav" "$work/two.mp3" "$work/wav-copy.mp3"
rg -q 'use --join --reencode' "$work/error" || fail 'non-MP3 copying rejection'
./clipcrank --join --reencode "$work/audio.wav" "$work/two.mp3" "$work/from-wav.mp3"
# Embedded cover art does not make an MP3 a video; joined output omits it.
./clipcrank --join examples/with_image.mp3 examples/with_image.mp3 "$work/cover.mp3"
[ -z "$(ffprobe -v error -select_streams v -show_entries stream=index -of csv=p=0 "$work/cover.mp3")" ] || fail 'cover art retained'
reject --join --fps 25 "$work/two.mp3" "$work/two.mp3" "$work/bad.mp3"
reject --join "$work/two.mp3" "$work/two.mp3" "$work/bad.mp4"
reject --join "$work/two.mp3" "$work/two.mp3" "$work/copied.mp3"
./clipcrank --join --force "$work/two.mp3" "$work/two.mp3" "$work/copied.mp3"
reject --join --force "$work/two.mp3" "$work/two.mp3" "$work/two.mp3"
ffmpeg -v error -f lavfi -i color=s=32x32 -t 0.2 -c:v libx264 "$work/video.mp4"
reject --join --reencode "$work/two.mp3" "$work/video.mp4" "$work/mixed.mp3"
rg -q 'cannot mix audio-only and video' "$work/error" || fail 'mixed media rejection'
printf 'PASS: audio joining copy integrity, normalization, duration, order, cover art, and validation\n'
