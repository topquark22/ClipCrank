# norm-vid

`norm-vid` converts many kinds of video files into standardized MP4 output using `ffmpeg`. It can also create clips based on starting and/or ending timestamps, and capture one or more JPEG still frames from a video.

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

## Supported Input Video Formats

`norm-vid` does not maintain its own list of input formats. It relies on the locally installed `ffmpeg`, so it can accept any video container and codec combination that the local `ffmpeg` build can demux and decode.

Common supported video file formats include:

- MP4 / MPEG-4 (`.mp4`, `.m4v`)
- QuickTime (`.mov`)
- Matroska (`.mkv`)
- WebM (`.webm`)
- AVI (`.avi`)
- Flash Video (`.flv`, `.f4v`)
- MPEG Program Stream (`.mpg`, `.mpeg`, `.vob`)
- MPEG Transport Stream (`.ts`, `.m2ts`, `.mts`)
- Windows Media / ASF (`.wmv`, `.asf`)
- Ogg Video (`.ogv`, `.ogg`)
- 3GPP / 3GPP2 (`.3gp`, `.3g2`)
- Material Exchange Format (`.mxf`)
- NUT (`.nut`)
- General eXchange Format (`.gxf`)
- raw H.264 / AVC (`.h264`, `.264`)
- raw H.265 / HEVC (`.h265`, `.265`, `.hevc`)
- raw MPEG-1 / MPEG-2 video (`.m1v`, `.m2v`)
- raw MPEG-4 Part 2 video (`.m4v`)
- Motion JPEG (`.mjpg`, `.mjpeg`)
- AV1 bitstreams where supported by the installed `ffmpeg`

This list covers common video formats rather than imposing a whitelist. Less common and legacy formats may also work if `ffmpeg` can read and decode them.

To see the input formats enabled in your installed `ffmpeg` build, run:

```sh
ffmpeg -demuxers
```

or, for the combined list of input and output formats:

```sh
ffmpeg -formats
```

Actual codec support can vary between `ffmpeg` builds, so a recognized container is usable only when the streams inside it can also be decoded by the installed build.

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

Clip timestamps are not automatically included in the default output filename. If `OUTPUT` is omitted, the normal derived `.mp4` filename is used regardless of whether `--start`, `--end`, or both are specified. Specify `OUTPUT` explicitly if you want the clip boundaries reflected in the filename.

## JPEG Frame Capture

### Single frame

```sh
./norm-vid --frame 1:23.500 input.mp4
```

With no output filename, the timestamp is normalized and appended so generated filenames sort chronologically:

```text
input-01-23.500.jpg
```

Minutes and seconds are zero-padded to at least two digits. Hours are included only when hours were supplied in the `--frame` timestamp. Milliseconds are included only when milliseconds were supplied. Seconds-only values are normalized into minutes and seconds, so `--frame 72` produces a suffix of `01-12`.

Use `--jpeg-quality N` for quality 1–100; the default is 90.

### Multiple frames

Use `--frame START`, `--interval TIME`, and `--count N` together:

```sh
./norm-vid --frame 10 --interval 5 --count 4 input.mp4
```

This produces:

```text
input-00-10.jpg
input-00-15.jpg
input-00-20.jpg
input-00-25.jpg
```

An optional output argument supplies the base name:

```sh
./norm-vid --frame 1:00 --interval 10 --count 3 input.mp4 shots.jpg
```

produces `shots-01-00.jpg`, `shots-01-10.jpg`, and `shots-01-20.jpg`.

If either the starting timestamp or interval includes milliseconds, generated filenames include milliseconds consistently across the sequence. If the starting timestamp includes hours, generated filenames include hours consistently across the sequence.

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
