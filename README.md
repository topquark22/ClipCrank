# ClipCrank

`clipcrank` is a command-line utility for video manipulation. The code is `bash` shell script, to run in a POSIX-compatible environment.

`clipcrank` can convert (re-encode) many kinds of video files into standardized MP4 output using `ffmpeg`. It can also create clips based on starting and/or ending timestamps, capture one or more JPEG still frames from a video, add or replace audio using either a video or still image as the visual source, extract audio to MP3, remove audio from video, and change media containers without re-encoding.

`clipcrank` is a wrapper for `ffmpeg`, intended to simplify the invocation of common `ffmpeg` operations and provide a more intuitive command-line interface. It does not replace `ffmpeg`; instead, it handles the underlying invocation and options for common video conversion, clipping, frame-capture, metadata, audio, and remuxing tasks.

## Features

- Converts (re-encodes) video to H.264/AAC MP4
- Creates clips using optional start/end times, re-encoding to H.264/AAC by default
- Captures single or multiple JPEG frames
- Adds or replaces audio on video input
- Creates H.264/AAC MP4 video from a still image plus audio
- Extracts audio from video to MP3
- Removes audio from video
- Remuxes media to a different container without re-encoding
- Displays technical media information
- Cleans up partial output on failure or interruption

## Requirements

- Bash in a POSIX-like shell environment
- `ffmpeg` and `ffprobe` installed and available on `PATH`

Linux and other POSIX-like systems can normally use their native Bash and FFmpeg packages.

Windows does not provide a native POSIX shell environment. To run ClipCrank on Windows, use a POSIX-compatible environment such as Cygwin. Native Windows builds of `ffmpeg` and `ffprobe` may be used from Cygwin and are the recommended configuration tested during ClipCrank development. See [INSTALL.md](./INSTALL.md) for installation instructions and important notes about Cygwin paths when using native Windows FFmpeg executables.

No ImageMagick or other image-processing package is required.

## Supported Input Video Formats

`clipcrank` does not maintain its own list of input formats. It relies on the locally installed `ffmpeg`, so it can accept any video container and codec combination that the local `ffmpeg` build can demux and decode.

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
./clipcrank [OPTIONS] INPUT [OUTPUT]
```

An operation must be selected explicitly, except that `--start` or `--end` may directly select clip creation. Clip creation re-encodes to H.264/AAC by default. Otherwise, if no operation is specified, `clipcrank` prints its usage message and exits without processing the input.

The available operations currently are:

- `--reencode` — recode video as standardized H.264/AAC MP4
- `--add-audio` — add or replace audio using a video or still image as input
- `--extract-audio` — extract the first audio stream as MP3
- `--remove-audio` — remove the audio stream and create H.264 MP4 output
- `--remux` — change the media container without re-encoding streams
- `--info` — display technical media information and exit
- `--show-metadata` — display metadata and exit
- `--frame TIME` — capture one or more JPEG frames

Only one operation may be selected at a time.

### Recoding

Use `--reencode` to convert an input video into standardized MP4 output:

```sh
./clipcrank --reencode input.mov
./clipcrank --reencode input.mov output.mp4
```

### Adding or replacing audio

Use `--add-audio` with a video input to add or replace its audio track:

```sh
./clipcrank --add-audio input.mp4 soundtrack.wav output.mp4
```

The replacement audio may use any format that the installed `ffmpeg` can decode. Output is standardized H.264/AAC MP4.

`--add-audio` also accepts a still image as the visual input:

```sh
./clipcrank --add-audio image.jpg soundtrack.wav output.mp4
./clipcrank --add-audio image.tiff soundtrack.mp3 output.mp4
```

Still-image input is detected from the media itself rather than from a filename-extension whitelist, so any still-image format that the installed FFmpeg can decode may be used. The still image is displayed for the duration of the audio. If the output filename is omitted for still-image input, the default output basename is derived from the audio filename with an `.mp4` extension.

### Extracting audio

Use `--extract-audio` to extract the first audio stream from a video and encode it as MP3:

```sh
./clipcrank --extract-audio input.mp4
./clipcrank --extract-audio input.mp4 output.mp3
```

If the output filename is omitted, the input extension is replaced with `.mp3`. Explicit output filenames must use the `.mp3` extension.

### Removing audio

Use `--remove-audio` to create an H.264 MP4 containing the video stream without audio:

```sh
./clipcrank --remove-audio input.mp4 output.mp4
```

The output filename is mandatory. No default output filename is generated.

### Remuxing

Use `--remux` to change the media container without re-encoding the streams:

```sh
./clipcrank --remux input.mp4 output.mkv
./clipcrank --remux input.mkv output.mp4
```

Both input and output filenames are mandatory. The output filename extension selects the target container. ClipCrank uses FFmpeg stream copying, so the existing video, audio, subtitle, and other streams are copied rather than transcoded.

`--remux` does not fall back to re-encoding. If the target container cannot accept one or more streams from the input file, the operation fails without creating the final output file.

### Overwriting existing files

By default, `clipcrank` refuses to overwrite an existing output file. Use `-f` or `--force` to allow replacement:

```sh
./clipcrank --reencode -f input.mov output.mp4
./clipcrank --force --frame 1:23.500 input.mp4 still.jpg
./clipcrank -f --frame 10 --interval 5 --count 4 input.mp4
```

This applies to recoding, clipping, audio operations, remuxing, single-frame capture, and every output in multi-frame capture. Temporary files are still used, so the existing final output is replaced only after the new output has been successfully created.

## Media Information

Use `--info` to display technical information about the input file without creating an output file:

```sh
./clipcrank --info input.mp4
```

This reports technical media properties using `ffprobe`, including the container format, duration and bitrate, and available video and audio stream information such as codecs, resolution, frame rate, pixel format, sample rate, and channel count. `--info` is an inspection mode and cannot be combined with output or conversion options.

## Metadata

Use `--show-metadata` to display the metadata already stored in the input file without creating an output file:

```sh
./clipcrank --show-metadata input.mp4
```

This displays container-level and stream-level metadata using `ffprobe`, then exits. `--show-metadata` is an inspection mode and cannot be combined with output or conversion options.

## Video Clips

Use `--start TIME`, `--end TIME`, or both. Times use:

```text
[[h:]m:]s[.ms]
```

ClipCrank re-encodes clips to standardized H.264/AAC MP4 by default:

```sh
./clipcrank --start 12.500 input.mov clip.mp4
./clipcrank --end 2:05 input.mov clip.mp4
./clipcrank --start 1:12.500 --end 2:05 input.mov clip.mp4
```

The explicit `--reencode` form remains valid but is not required for clipping:

```sh
./clipcrank --reencode --start 12.500 --end 2:05 input.mov clip.mp4
```

If the input already uses H.264 video and AAC audio, use `--copy-stream` to create the clip without re-encoding:

```sh
./clipcrank --copy-stream --start 12.500 input.mp4 clip.mp4
./clipcrank --copy-stream --end 2:05 input.mp4 clip.mp4
./clipcrank --copy-stream --start 1:12.500 --end 2:05 input.mp4 clip.mp4
```

A video with H.264 video and no audio can also be clipped with `--copy-stream`. If audio streams are present, they must all use AAC. `--copy-stream` does not silently fall back to re-encoding if those requirements are not met.

Stream-copy clipping does not create new keyframes. Before clipping with a specified `--start`, ClipCrank determines and reports the usable keyframe timestamp. When it differs from the requested start, ClipCrank also reports the difference. No confirmation prompt is used because stream copying is explicitly requested by `--copy-stream`.

Use the default clipping mode when an exact transcoded start or codec normalization is required.

If `--start` is omitted, output begins at the start of the input. If `--end` is omitted, output continues to the end. When both are supplied, `--end` must be later than `--start`.

Clip timestamps are not automatically included in the default output filename. If `OUTPUT` is omitted, the normal derived `.mp4` filename is used regardless of whether `--start`, `--end`, or both are specified. Specify `OUTPUT` explicitly if you want the clip boundaries reflected in the filename.

## JPEG Frame Capture

### Single frame

```sh
./clipcrank --frame 1:23.500 input.mp4
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
./clipcrank --frame 10 --interval 5 --count 4 input.mp4
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
./clipcrank --frame 1:00 --interval 10 --count 3 input.mp4 shots.jpg
```

produces `shots-01-00.jpg`, `shots-01-10.jpg`, and `shots-01-20.jpg`.

If either the starting timestamp or interval includes milliseconds, generated filenames include milliseconds consistently across the sequence. If the starting timestamp includes hours, generated filenames include hours consistently across the sequence.

Without `--force`, all multi-frame target names are checked before capture starts; if any already exists, nothing is created. With `--force`, existing target images are replaced as each newly captured frame completes successfully.

## Frame Rate

Use `--reencode` with `--fps N` to convert output video to an explicit frame rate. `--cfr` forces constant-frame-rate output while allowing `ffmpeg` to determine the rate. They cannot be used together.

## Frame-capture option compatibility

`--frame` cannot be combined with `--reencode`, `--add-audio`, `--extract-audio`, `--remove-audio`, `--remux`, `--show-metadata`, `--start`, `--end`, `--fps`, `--cfr`, or MP4 metadata options.

## Testing

The repository includes `docs/TEST_PLAN.md` and `test/smoke-test.sh`.

```sh
chmod +x test/smoke-test.sh
./test/smoke-test.sh
```

## Exit Behavior

- status `0` on success
- non-zero status on failure

Errors are reported on standard error.
