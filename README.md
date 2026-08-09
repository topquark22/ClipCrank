# norm-vid

`norm-vid` converts many kinds of video files into standardized MP4 output using `ffmpeg`. It can also capture one or more JPEG still frames from a video.

## Features

- Converts video to H.264/AAC MP4
- Creates clips using optional start/end times
- Captures single or multiple JPEG frames
- JPEG quality defaults to 90 and is configurable
- Refuses to overwrite existing output by default
- Supports `-f` / `--force` to overwrite existing output
- Cleans up partial output on failure or interruption

## Requirements

- A POSIX-like shell environment
- `ffmpeg` installed and available on `PATH`

No ImageMagick or other image-processing package is required.

## Usage

```sh
./norm-vid [OPTIONS] INPUT [OUTPUT]
```

### Overwriting existing files

By default, `norm-vid` refuses to overwrite an existing output file. Use `-f` or `--force` to allow replacement:

```sh
./norm-vid -f input.mov output.mp4
./norm-vid --force --frame 1:23.500 input.mp4 still.jpg
./norm-vid -f --frame 10 --interval 5 --count 4 input.mp4
```

This applies to normal video conversion, single-frame capture, and every output in multi-frame capture. Temporary files are still used, so the existing final output is replaced only after the new output has been successfully created.

## Video Clips

Use `--start TIME`, `--end TIME`, or both. Times use:

```text
[[h:]m:]s[.ms]
```

Examples:

```sh
./norm-vid --start 12.500 input.mov clip.mp4
./norm-vid --end 2:05 input.mov clip.mp4
./norm-vid --start 1:12.500 --end 2:05 input.mov clip.mp4
```

If `--start` is omitted, output begins at the start of the input. If `--end` is omitted, output continues to the end. When both are supplied, `--end` must be later than `--start`.

## JPEG Frame Capture

### Single frame

```sh
./norm-vid --frame 1:23.500 input.mp4
```

With no output filename, the timestamp is appended:

```text
input-1-23.500.jpg
```

Use `--jpeg-quality N` for quality 1–100; the default is 90.

### Multiple frames

Use `--frame START`, `--interval TIME`, and `--count N` together:

```sh
./norm-vid --frame 10 --interval 5 --count 4 input.mp4
```

This produces:

```text
input-10.000.jpg
input-15.000.jpg
input-20.000.jpg
input-25.000.jpg
```

An optional output argument supplies the base name:

```sh
./norm-vid --frame 1:00 --interval 10 --count 3 input.mp4 shots.jpg
```

produces `shots-1-00.000.jpg`, `shots-1-10.000.jpg`, and `shots-1-20.000.jpg`.

Without `--force`, all multi-frame target names are checked before capture starts; if any already exists, nothing is created. With `--force`, existing target images are replaced as each newly captured frame completes successfully.

## Frame Rate

`--fps N` converts output video to an explicit frame rate. `--cfr` forces constant-frame-rate output while allowing `ffmpeg` to determine the rate. They cannot be used together.

## Frame-capture option compatibility

`--frame` cannot be combined with `--start`, `--end`, `--fps`, `--cfr`, or MP4 metadata options.

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
