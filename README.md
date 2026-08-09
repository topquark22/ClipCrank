# norm-vid

`norm-vid` is a small shell script that converts many kinds of video files into standardized MP4 output using `ffmpeg`.

The goal is practical normalization:
- MP4 container,
- H.264 video,
- AAC audio when audio is present,
- broadly compatible pixel format and playback behavior.

This project is intentionally simple. It is meant to be easy to read, easy to run, and useful on real media files, including older formats, as long as `ffmpeg` can decode them.

`norm-vid` is not intended to replace `ffmpeg`.

Instead, it acts as a practical simplification layer for common transcoding tasks. The script aims to expose a small number of useful and understandable options while relying on `ffmpeg` to perform the actual media processing.

The design goal is convenience without unnecessary complexity.

## Features

- Converts a wide range of input containers to MP4
- Encodes video as H.264
- Encodes audio as AAC when audio exists
- Automatically detects a usable H.264 encoder from the local `ffmpeg` environment
- Can create clips using an optional start time, end time, or both
- Tolerates missing audio streams
- Ignores subtitle and data streams
- Scales output dimensions to even values for encoder compatibility
- Uses a temporary output file and only moves the final file into place after success
- Refuses to overwrite an existing output file
- Cleans up partial output on failure or interruption

## Requirements

- A POSIX-like shell environment
- `ffmpeg` installed and available on `PATH`

The script depends on the capabilities of the local `ffmpeg` build.

It currently looks for a supported H.264 encoder in this order:

1. `libx264`
2. `libopenh264`
3. `h264_nvenc`
4. `h264_qsv`
5. `h264_amf`
6. `h264_mf`
7. `h264_d3d12va`
8. `h264_vulkan`
9. `h264_videotoolbox`

It also requires an AAC encoder to be available in `ffmpeg`.

Because `ffmpeg` builds vary by platform and packaging, the exact encoder used may differ from one machine to another.

## Usage

```sh
./norm-vid INPUT [OUTPUT]
```

Examples:

```sh
./norm-vid old-video.avi
./norm-vid archive.flv
./norm-vid input.mov output.mp4
./norm-vid --start 12.500 input.mov clip.mp4
./norm-vid --end 2:05 input.mov clip.mp4
./norm-vid --start 1:12.500 --end 2:05 input.mov clip.mp4
./norm-vid --start 1:03:04.250 --end 1:04:10.500 input.mov clip.mp4
./norm-vid --fps 30 input.mov
./norm-vid --cfr input.mov
```

If `OUTPUT` is omitted, the script derives it from the input filename by replacing the extension with `.mp4`.

Examples:

- `movie.avi` -> `movie.mp4`
- `clip.flv` -> `clip.mp4`
- `recording` -> `recording.mp4`

Existing MP4 inputs are also fully normalized and regenerated through the same conversion pipeline.

## Video Clips

Use `--start TIME`, `--end TIME`, or both to create an output containing only part of the original video.

The general time form is:

```text
[[h:]m:]s[.ms]
```

This means all three of these forms are accepted:

```text
s[.ms]
m:s[.ms]
h:m:s[.ms]
```

If minutes are omitted, they default to zero. If hours are omitted, they also default to zero. The seconds-only field may be any non-negative number of seconds. In the two-field form, seconds must be between 0 and 59. In the three-field form, both minutes and seconds must be between 0 and 59. The optional fractional part may contain one to three digits.

Examples of equivalent times:

```text
72.500
1:12.500
0:01:12.500
```

`--start` specifies where the output begins. If `--end` is omitted, the output continues to the end of the input.

```sh
./norm-vid --start 12.500 input.mov clip.mp4
```

`--end` specifies where the output ends. If `--start` is omitted, the output begins at the start of the input.

```sh
./norm-vid --end 125 input.mov clip.mp4
```

When both are supplied, the output contains the interval between the two positions:

```sh
./norm-vid --start 72.500 --end 2:05 input.mov clip.mp4
```

Longer timestamps may still include hours explicitly:

```sh
./norm-vid --start 1:03:04.250 --end 1:04:10.500 input.mov clip.mp4
```

When both are supplied, the end time must be later than the start time. The clip is still fully normalized through the usual H.264/AAC conversion pipeline.

## Frame Rate

The `--fps N` option converts the output video to an explicit frame rate of `N` frames per second.

The `--cfr` option forces constant-frame-rate output while allowing `ffmpeg` to determine the output rate from the source timing.

These two options are alternatives and cannot be used together.

Examples:

```sh
./norm-vid --fps 30 input.mov output.mp4
./norm-vid --cfr input.mov output.mp4
```

## What the Script Does

The script runs `ffmpeg` with behavior intended to be safe and practical:

- uses the first video stream,
- uses the first audio stream if present,
- tolerates inputs with no audio,
- drops subtitle and data streams,
- generates timestamps when needed,
- writes to a temporary `.mp4` path first,
- renames the completed file into place only after success.

On successful conversion, it prints:
- the selected video encoder,
- the created output path.

## Example Output

```text
using video encoder: libopenh264
created: Smile.mp4
```

The exact encoder shown will depend on the local `ffmpeg` installation.

## Supported Inputs

This tool is intended for practical use with many common and legacy containers, including examples such as:

- `.flv`
- `.avi`
- `.mov`
- `.mkv`
- `.mp4`
- and other formats decodable by `ffmpeg`

Support ultimately depends on whether the local `ffmpeg` build can decode the input file.

## What This Tool Does Not Try to Do

This script currently does not try to:

- preserve subtitle streams,
- preserve data streams,
- preserve all metadata,
- preserve chapters,
- expose advanced quality controls,
- batch-convert directories,
- overwrite existing outputs automatically,
- guarantee identical output across different systems.

It is a simple normalization tool, not a full transcoding framework.

## Testing

This repository includes:

- `TEST_PLAN.md` for the manual test strategy and test matrix
- `test/smoke-test.sh` for basic command-line smoke testing of failure paths

To run the smoke tests:

```sh
chmod +x test/smoke-test.sh
./test/smoke-test.sh
```

For media-based validation, see `TEST_PLAN.md`.

## Notes on Portability

`ffmpeg` support differs across environments.

For example, one machine may provide:
- `libx264`

while another may provide:
- `libopenh264`
- `h264_qsv`
- `h264_nvenc`
- or other platform-specific H.264 encoders

This project handles that by detecting supported H.264 encoders at runtime and choosing one automatically.

Even so, hardware-backed encoders may still fail at runtime if drivers or system support are incomplete.

## Exit Behavior

- exits with status `0` on success
- exits non-zero on failure

Errors are reported with human-readable messages on standard error.
