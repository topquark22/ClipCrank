# norm-vid

`norm-vid` converts many kinds of video files into standardized MP4 output using `ffmpeg`. It can also capture one or more JPEG still frames from a video.

The normalization goal is practical compatibility:
- MP4 container,
- H.264 video,
- AAC audio when audio is present,
- broadly compatible pixel format and playback behavior.

The project is intentionally simple: a small convenience layer over `ffmpeg`, not a replacement for it.

## Features

- Converts a wide range of input containers to MP4
- Encodes video as H.264 and audio as AAC
- Automatically detects a usable H.264 encoder
- Creates clips using an optional start time, end time, or both
- Captures one JPEG still frame at a requested timestamp
- Captures multiple JPEG frames from a start time, interval, and count
- Supports configurable JPEG quality, defaulting to 90
- Tolerates missing audio streams
- Ignores subtitle and data streams
- Refuses to overwrite existing output
- Cleans up partial output on failure or interruption

## Requirements

- A POSIX-like shell environment
- `ffmpeg` installed and available on `PATH`

No ImageMagick or other image-processing package is required for JPEG frame capture.

## Usage

```sh
./norm-vid [OPTIONS] INPUT [OUTPUT]
```

Examples:

```sh
./norm-vid old-video.avi
./norm-vid input.mov output.mp4
./norm-vid --start 12.500 --end 2:05 input.mov clip.mp4
./norm-vid --frame 1:23.500 input.mp4
./norm-vid --frames 10 --interval 5 --count 4 input.mp4
./norm-vid --frames 1:00 --interval 10 --count 3 input.mp4 shots.jpg
./norm-vid --frame 1:23.500 --jpeg-quality 95 input.mp4 still.jpg
```

For normal video conversion, omitted `OUTPUT` is derived by replacing the input extension with `.mp4`.

Existing output files are never overwritten.

## Video Clips

Use `--start TIME`, `--end TIME`, or both to create an output containing only part of the original video.

The general time form is:

```text
[[h:]m:]s[.ms]
```

Accepted forms are:

```text
s[.ms]
m:s[.ms]
h:m:s[.ms]
```

Examples of equivalent times:

```text
72.500
1:12.500
0:01:12.500
```

If `--start` is omitted, output begins at the start of the input. If `--end` is omitted, output continues to the end. When both are supplied, `--end` must be later than `--start`.

## JPEG Frame Capture

### Single frame

Use `--frame TIME` to capture one still frame from the first video stream:

```sh
./norm-vid --frame 83.500 input.mp4 still.jpg
./norm-vid --frame 1:23.500 input.mp4 still.jpg
```

If no output path is supplied, the timestamp is appended to the input base name:

```text
input.mp4 + --frame 83.500   -> input-83.500.jpg
input.mp4 + --frame 1:23.500 -> input-1-23.500.jpg
```

### Multiple frames

Use `--frames START`, `--interval TIME`, and `--count N` together to capture a sequence of still frames.

```sh
./norm-vid --frames 10 --interval 5 --count 4 input.mp4
```

This captures frames at 10, 15, 20, and 25 seconds. With no output base supplied, the input basename is used:

```text
input-10.000.jpg
input-15.000.jpg
input-20.000.jpg
input-25.000.jpg
```

The start time and interval both use the same `[[h:]m:]s[.ms]` syntax. The interval must be greater than zero, and `--count` must be a positive integer.

An optional `OUTPUT` supplies the base name for the generated files. A `.jpg` or `.jpeg` suffix is treated as part of the base specification and removed before timestamp suffixes are added:

```sh
./norm-vid --frames 1:00 --interval 10 --count 3 input.mp4 shots.jpg
```

produces:

```text
shots-1-00.000.jpg
shots-1-10.000.jpg
shots-1-20.000.jpg
```

All target filenames are checked before capture starts. If any target already exists, no frames are created.

### JPEG quality

JPEG quality defaults to `90`. Override it with `--jpeg-quality N`, where `N` is an integer from 1 through 100:

```sh
./norm-vid --frames 10 --interval 5 --count 4 --jpeg-quality 95 input.mp4
```

The user-facing 1–100 quality value is translated internally to ffmpeg's JPEG quality scale.

`--jpeg-quality` is valid with either `--frame` or `--frames`.

Frame capture is a separate output mode. `--frame` and `--frames` cannot be combined with:

- `--start` or `--end`
- `--fps` or `--cfr`
- MP4 metadata options

`--frame` and `--frames` cannot be used together.

## Frame Rate

`--fps N` converts output video to an explicit frame rate of `N` frames per second.

`--cfr` forces constant-frame-rate output while allowing `ffmpeg` to determine the output rate from source timing.

The two options cannot be used together.

## Video Conversion Behavior

For MP4 conversion the script:

- uses the first video stream,
- includes audio if present,
- drops subtitle and data streams,
- generates timestamps when needed,
- scales dimensions to even values,
- writes H.264 video and AAC audio,
- writes to a temporary file before moving the completed output into place.

The script searches for an H.264 encoder in this order:

1. `libx264`
2. `libopenh264`
3. `h264_nvenc`
4. `h264_qsv`
5. `h264_amf`
6. `h264_mf`
7. `h264_d3d12va`
8. `h264_vulkan`
9. `h264_videotoolbox`

Encoder availability depends on the local `ffmpeg` build.

## Testing

The repository includes `TEST_PLAN.md` and `test/smoke-test.sh`.

```sh
chmod +x test/smoke-test.sh
./test/smoke-test.sh
```

## Exit Behavior

- status `0` on success
- non-zero status on failure

Errors are reported on standard error.
