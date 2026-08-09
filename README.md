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
./norm-vid --trim-seconds 0.04 input.mp4 output.mp4
./norm-vid --fps 30 input.mov
./norm-vid --cfr input.mov
```

If `OUTPUT` is omitted, the script derives it from the input filename by replacing the extension with `.mp4`.

Examples:

- `movie.avi` -> `movie.mp4`
- `clip.flv` -> `clip.mp4`
- `recording` -> `recording.mp4`

Existing MP4 inputs are also fully normalized and regenerated through the same conversion pipeline.

## Frame Rate

The `--fps N` option converts the output video to an explicit frame rate of `N` frames per second.

The `--cfr` option forces constant-frame-rate output while allowing `ffmpeg` to determine the output rate from the source timing.

These two options are alternatives and cannot be used together.

Examples:

```sh
./norm-vid --fps 30 input.mov output.mp4
./norm-vid --cfr input.mov output.mp4
```

## Trim Seconds

The `--trim-seconds` option trims a small amount from the beginning of the media during conversion.

Example:

```sh
./norm-vid --trim-seconds 0.04 input.mp4 output.mp4
```

This can be useful when:

- removing problematic leading frames
- slightly shifting media timing during normalization
- regenerating output that differs from the original timing structure

The value is specified in seconds and may be fractional.

Examples:

- `0.04`
- `0.0333`
- `1.5`

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
