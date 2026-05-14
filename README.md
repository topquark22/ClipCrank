# all2mp4

`all2mp4` is a small shell utility for converting arbitrary video files into standardized H.264/AAC MP4 output.

The goal is simple: take old, unusual, or inconsistent video files and produce an `.mp4` that is much more likely to play reliably across common devices, browsers, and media players.

## Features

- Converts many input video formats into `.mp4`
- Standardizes video to **H.264**
- Standardizes audio to **AAC** when audio is present
- Uses `yuv420p` for broad compatibility
- Enables `faststart` for better playback and streaming behavior
- Adjusts odd dimensions when needed for H.264 compatibility
- Keeps the project small and shell-script-friendly

## Requirements

- POSIX-like shell
- `ffmpeg` installed and available on `PATH`

Optional:
- `ffprobe` for diagnostics or future enhancements

## Installation

Clone the repository:

```sh
git clone https://github.com/topquark22/all2mp4.git
cd all2mp4
```

Make the script executable:

```sh
chmod +x all2mp4
```

Run it directly:

```sh
./all2mp4 input.avi
```

## Usage

```sh
./all2mp4 INPUT [OUTPUT]
```

Examples:

```sh
./all2mp4 old-video.avi
./all2mp4 input.mov output.mp4
./all2mp4 weird_1997_capture.mkv normalized.mp4
```

If `OUTPUT` is omitted, the tool should derive the output filename from the input name and replace the extension with `.mp4`.

## Output Standard

The tool is intended to produce output with:

- **Container:** MP4
- **Video codec:** H.264
- **Audio codec:** AAC, if audio exists
- **Pixel format:** `yuv420p`
- **Faststart:** enabled

A representative `ffmpeg` command looks like this:

```sh
ffmpeg -fflags +genpts -i input_video.ext \
  -map 0:v:0 -map 0:a? \
  -dn -sn \
  -c:v libx264 -preset medium -crf 23 \
  -pix_fmt yuv420p \
  -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
  -movflags +faststart \
  -c:a aac -b:a 192k \
  output.mp4
```

## Behavior Notes

- The first video stream is used.
- The first audio stream is included when present.
- Subtitle and data streams are omitted in the initial version.
- Video is re-encoded to H.264.
- Audio is re-encoded to AAC when present.
- Dimensions may be adjusted to even values to satisfy encoder requirements.

## Errors

The script should report clear errors for cases such as:

- missing input argument,
- input file not found,
- input file unreadable,
- `ffmpeg` not installed,
- decode failure,
- output write failure.

It should return:
- `0` on success,
- non-zero on failure.

## Project Structure

This repository intentionally uses a flat layout:

```text
all2mp4/
├── README.md
├── REQUIREMENTS.md
├── all2mp4
├── smoke-test.sh
├── .gitignore
└── LICENSE
```

## Scope

Initial scope:

- single-file conversion,
- optional explicit output filename,
- compatibility-focused defaults,
- minimal shell-script implementation,
- basic documentation.

Possible future enhancements:

- batch conversion,
- recursive processing,
- configurable quality settings,
- overwrite flags,
- metadata options,
- subtitle handling,
- more complete tests.

## Non-Goals

`all2mp4` is not intended to:

- preserve original codecs,
- perform lossless archival transcoding,
- serve as a full media library manager,
- provide a GUI.

## License

TBD