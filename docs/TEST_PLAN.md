# Test Plan

This document describes how to test `clipcrank`.

The project is small, so the testing approach is intentionally practical:
- verify that each supported operation works on representative real-world files,
- verify that common failure cases are handled clearly,
- verify that generated media has the expected format and codec properties,
- verify that filename generation and overwrite behavior are predictable.

## Goals

The test plan aims to confirm that `clipcrank`:

- requires an explicit operation,
- re-encodes supported input media into standardized H.264/AAC MP4 output,
- selects a working H.264 encoder from the local `ffmpeg` environment,
- uses AAC audio when audio is present,
- adds or replaces audio on video input,
- creates video from still-image input plus audio,
- detects still-image input from media content rather than filename extension,
- extracts the first audio stream to MP3,
- removes audio while retaining H.264 video,
- creates clips using a start time, end time, or both,
- accepts timestamps in `[[h:]m:]s[.ms]` form,
- captures single JPEG frames,
- captures multiple JPEG frames using an interval and count,
- generates sortable timestamp-based frame filenames,
- includes hours consistently when a frame sequence crosses an hour boundary,
- supports configurable JPEG quality,
- supports explicit frame-rate conversion and constant-frame-rate output,
- displays metadata using `ffprobe`,
- supports preserving, clearing, and setting metadata during re-encoding,
- avoids overwriting existing output by default,
- overwrites existing output only when `-f` or `--force` is supplied,
- succeeds on old or awkward media when `ffmpeg` can decode it,
- fails clearly when prerequisites or input files are missing.

## Out of Scope

This project does not currently aim to prove:

- bit-exact reproducibility,
- archival-quality transcoding,
- subtitle retention,
- data-stream retention,
- chapter preservation,
- support for every codec or still-image format ever produced,
- identical encoding results across all platforms or `ffmpeg` builds,
- successful runtime use of every hardware encoder reported by `ffmpeg`.

Because encoder and decoder availability differs by environment, tests focus on successful operation, playable output, and expected media properties rather than identical binary output.

## Test Approach

Testing combines:

1. **Automated smoke testing** with `test/smoke-test.sh`.
2. **Real-media integration testing** using committed fixtures under `examples/`.
3. **Manual media testing** using representative files.
4. **Output inspection** with `ffprobe` for codecs, duration, metadata, and stream properties.

The smoke test should normally be run from the repository root:

```sh
./test/smoke-test.sh
```

The current smoke suite contains 46 tests.

## Operations

ClipCrank currently exposes these primary operations:

```text
--reencode
--add-audio
--extract-audio
--remove-audio
--show-metadata
--frame TIME
```

Only one operation may be selected at a time.

Running `clipcrank` without an operation shall print Usage and exit non-zero.

## Re-encoding Tests

### Basic re-encoding

```sh
./clipcrank --reencode input.webm output.mp4
```

Expected:
- exit status `0`,
- output file exists,
- output container is MP4,
- output video codec is H.264,
- output audio codec is AAC when the source contains audio,
- output is playable.

### Real VP9 fixture

The repository contains:

```text
examples/Big_Buck_Bunny_720_10s_1MB.webm
```

The source video codec shall be verified as VP9:

```sh
ffprobe -v error \
  -select_streams v:0 \
  -show_entries stream=codec_name \
  -of default=noprint_wrappers=1:nokey=1 \
  examples/Big_Buck_Bunny_720_10s_1MB.webm
```

Expected output:

```text
vp9
```

Re-encode it with:

```sh
./clipcrank --force --reencode \
  examples/Big_Buck_Bunny_720_10s_1MB.webm \
  tmp/Big_Buck_Bunny_720_10s_1MB.mp4
```

Verify the output codec:

```sh
ffprobe -v error \
  -select_streams v:0 \
  -show_entries stream=codec_name \
  -of default=noprint_wrappers=1:nokey=1 \
  tmp/Big_Buck_Bunny_720_10s_1MB.mp4
```

Expected output:

```text
h264
```

When native Windows `ffprobe` is used under Cygwin, its output may contain carriage returns. Automated comparisons therefore normalize `ffprobe` output with:

```sh
tr -d '\r'
```

## Add-Audio Tests

The canonical audio fixture is:

```text
examples/bah.wav
```

The canonical still-image fixture is:

```text
examples/lenna.png
```

### Still image plus audio

```sh
./clipcrank --force --add-audio \
  examples/lenna.png \
  examples/bah.wav \
  tmp/bah.mp4
```

Expected:
- output file exists,
- output video codec is H.264,
- output audio codec is AAC,
- the still image is displayed for the duration of the audio,
- the output basename corresponds to the audio input basename when the default naming rule is exercised.

### Format-agnostic still-image detection

The automated smoke suite copies the Lenna image to a temporary filename with a non-image extension:

```text
tmp/lenna.still
```

It then runs `--add-audio` using that file as the visual input.

Expected: the operation succeeds because the visual input is classified from decoded media content rather than from `.jpg`, `.jpeg`, or `.png` naming.

### Video plus replacement audio

```sh
./clipcrank --force --add-audio \
  examples/Big_Buck_Bunny_720_10s_1MB.webm \
  examples/bah.wav \
  tmp/Big_Buck_Bunny_add_audio.mp4
```

Expected:
- output file exists,
- output video codec is H.264,
- output audio codec is AAC.

## Extract-Audio Tests

The smoke suite uses the generated still-image-plus-audio video:

```text
tmp/bah.mp4
```

Run:

```sh
./clipcrank --force --extract-audio tmp/bah.mp4
```

Expected:
- the default output is `tmp/bah.mp3`,
- the output file exists,
- the output contains an MP3 audio stream.

Verify the codec with:

```sh
ffprobe -v error \
  -select_streams a:0 \
  -show_entries stream=codec_name \
  -of default=noprint_wrappers=1:nokey=1 \
  tmp/bah.mp3
```

Expected output:

```text
mp3
```

An explicit output path shall use the `.mp3` extension.

## Remove-Audio Tests

The smoke suite uses the generated H.264/AAC video:

```text
tmp/bah.mp4
```

Run:

```sh
./clipcrank --force --remove-audio tmp/bah.mp4 tmp/bah-silent.mp4
```

Expected:
- the output file exists,
- the output video codec is H.264,
- no audio stream is present,
- the output filename is mandatory.

Running `--remove-audio` without an output argument shall print Usage and exit non-zero.

## Clip Timestamp Formats

Accepted timestamp syntax is:

```text
[[h:]m:]s[.ms]
```

Examples:

```text
12
12.500
1:12.500
0:01:12.500
59:59
1:00:01
```

When fewer fields are supplied, omitted higher-order fields default to zero.

In three-field form, minutes and seconds must be between 0 and 59. In two-field form, seconds must be between 0 and 59. A seconds-only value may exceed 59 and is interpreted as total seconds.

## Manual Clip Tests

### Start and end

```sh
./clipcrank --reencode --start 10.250 --end 20.750 input.mp4 clip.mp4
```

Expected:
- begins at approximately 10.250 seconds,
- ends at approximately 20.750 seconds,
- duration approximately 10.500 seconds.

### Start only

```sh
./clipcrank --reencode --start 1:12.500 input.mp4 clip.mp4
```

Expected: starts at 1 minute 12.500 seconds and continues to EOF.

### End only

```sh
./clipcrank --reencode --end 2:05 input.mp4 clip.mp4
```

Expected: starts at the beginning and ends at 2 minutes 5 seconds.

### Cross an hour boundary

```sh
./clipcrank --reencode --start 59:59 --end 1:00:01 input.mp4 clip.mp4
```

Expected: produces an approximately two-second clip crossing the one-hour boundary.

## Frame Capture Tests

### Single frame

```sh
./clipcrank --frame 12.500 input.mp4
```

Expected:
- one JPEG is created,
- default JPEG quality is 90,
- generated filename contains the normalized timestamp.

### Explicit JPEG quality

```sh
./clipcrank --frame 12.500 --jpeg-quality 75 input.mp4 still.jpg
```

Expected: one JPEG is created using the requested quality setting.

### Multiple frames

```sh
./clipcrank --frame 10 --interval 5 --count 4 input.mp4
```

Expected: four JPEG files are created at approximately 10, 15, 20, and 25 seconds.

### Filename normalization

A frame requested at:

```text
72
```

shall use a filename timestamp equivalent to:

```text
01-12
```

Hours shall not be included unless required by the supplied or generated timestamps. Milliseconds shall not be included unless the starting timestamp or interval uses milliseconds.

### Hour-boundary filename sorting

```sh
./clipcrank --frame 59:59 --interval 1 --count 3 input.mp4 hour.jpg
```

Expected filenames:

```text
hour-00-59-59.jpg
hour-01-00-00.jpg
hour-01-00-01.jpg
```

All filenames in the sequence must include hours once any generated frame reaches one hour or more.

## Frame-Rate Tests

### Explicit FPS

```sh
./clipcrank --reencode --fps 30 input.mp4 output.mp4
```

Expected: output is converted to the requested frame rate.

### Constant frame rate

```sh
./clipcrank --reencode --cfr input.mp4 output.mp4
```

Expected: output uses constant-frame-rate behavior while allowing `ffmpeg` to determine the rate.

### Conflicting frame-rate options

```sh
./clipcrank --reencode --fps 30 --cfr input.mp4 output.mp4
```

Expected: clear error because `--fps` and `--cfr` cannot be used together.

## Metadata Tests

### Display metadata

```sh
./clipcrank --show-metadata input.mp4
```

Expected:
- metadata is printed,
- no output file is created,
- operation exits successfully when `ffprobe` is available.

`--show-metadata` shall reject an output filename and output-modifying options.

### Preserve metadata

```sh
./clipcrank --reencode --preserve-metadata input.mp4 output.mp4
```

Expected: input global metadata is copied before explicit metadata edits are applied.

### Clear metadata

```sh
./clipcrank --reencode --clear-metadata input.mp4 output.mp4
```

Expected: input global metadata is not copied into the output, except metadata generated by the output format or encoder itself.

### Set metadata

Examples:

```sh
./clipcrank --reencode --title "Example" input.mp4 output.mp4
./clipcrank --reencode --metadata genre=Animation input.mp4 output.mp4
```

Expected: requested metadata fields appear in the generated MP4.

`--preserve-metadata` and `--clear-metadata` shall not be accepted together.

## Overwrite Tests

### Existing output without force

```sh
./clipcrank --reencode input.webm existing.mp4
```

Expected: failure without modifying the existing file.

### Existing output with force

```sh
./clipcrank --reencode --force input.webm existing.mp4
```

Expected: successful replacement after the new output has been created successfully.

The same behavior applies to audio operations, single-frame output, and multiple-frame output.

Input and output paths that refer to the same file shall be rejected even when `--force` is supplied.

## Failure Cases

### No operation

```sh
./clipcrank input.mp4
```

Expected: Usage is printed and the command exits non-zero.

### Multiple operations

```sh
./clipcrank --reencode --frame 10 input.mp4
```

Expected: clear error that only one operation may be specified.

### Missing remove-audio output

```sh
./clipcrank --remove-audio input.mp4
```

Expected: Usage is printed and the command exits non-zero.

### End before start

```sh
./clipcrank --reencode --start 1:00 --end 0:59 input.mp4 out.mp4
```

Expected: clear error that `--end` must be later than `--start`.

### Invalid timestamp

```sh
./clipcrank --reencode --start 0:61:00 input.mp4 out.mp4
```

Expected: timestamp-format error.

### Invalid frame options

Examples that shall fail:

```sh
./clipcrank --interval 5 input.mp4
./clipcrank --frame 10 --count 3 input.mp4
./clipcrank --frame 10 --interval 5 input.mp4
./clipcrank --frame 10 --interval 0 --count 3 input.mp4
./clipcrank --frame 10 --interval 5 --count 2.5 input.mp4
```

### Removed options

The removed options shall remain rejected:

```sh
./clipcrank --trim-seconds 1 input.mp4
./clipcrank --frames 10 --interval 5 --count 2 input.mp4
```

Expected: unknown-option errors.

## Output Verification

Where `ffprobe` is available:

```sh
ffprobe -v error -show_entries format=format_name,duration -of default=nw=1 output.mp4
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,pix_fmt,width,height,r_frame_rate -of default=nw=1 output.mp4
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1 output.mp4
```

For standard re-encoded and `--add-audio` output, verify as applicable:

- MP4-compatible container,
- H.264 video,
- AAC audio,
- `yuv420p` pixel format,
- even-numbered output dimensions.

For `--extract-audio`, verify that the output contains an MP3 audio stream and no video stream.

For `--remove-audio`, verify that the output contains H.264 video and no audio stream.

For clips with both boundaries, compare duration with `end - start`. For end-only clips, compare duration with `end`. For start-only clips, confirm that output continues through the source's end.

Small differences at frame or audio-sample boundaries are acceptable.

## Cleanup Verification

Conversion, audio, and frame-capture operations use temporary output files.

Tests shall confirm that:

- partial temporary files are removed after failure or interruption,
- final output paths are populated only after successful generation,
- integration-test output may intentionally be retained after failure for diagnosis,
- generated real-media integration artifacts are retained under `tmp/` for inspection and overwritten on subsequent runs with `--force`.

## Regression Testing

After every meaningful script change, run:

```sh
./test/smoke-test.sh
```

The current suite covers 46 cases, including:

- explicit operation selection,
- option conflicts,
- timestamp validation,
- hour-boundary clipping validation,
- removed options,
- frame option dependencies,
- force parsing,
- sortable frame filenames across an hour boundary,
- metadata inspection,
- input validation,
- overwrite protection,
- real VP9 fixture verification,
- real VP9-to-H.264 re-encoding,
- post-conversion H.264 verification,
- still-image plus audio creation,
- video plus replacement-audio creation,
- H.264/AAC verification for audio-addition operations,
- default audio-derived basename checking,
- still-image detection independent of filename extension,
- MP3 audio extraction,
- MP3 codec verification,
- mandatory `--remove-audio` output validation,
- audio removal,
- H.264 verification after audio removal,
- confirmation that removed-audio output contains no audio stream.

Manual regression testing should additionally include representative files with and without audio and at least one long-duration source when hour-boundary behavior is relevant.

## Platform Notes

The shell script is intended for POSIX-like environments with `ffmpeg` and `ffprobe` available on `PATH`.

Under Cygwin, native Windows `ffmpeg.exe` and `ffprobe.exe` may not understand Cygwin absolute paths such as `/home/...`. Real-media tests therefore use repository-relative paths and assume the smoke test is launched from the repository root.

Native Windows `ffprobe` may emit CRLF line endings. Automated codec and input-classification comparisons strip carriage returns before comparing values.

## Conclusion

The priority is confidence that ClipCrank translates simple user-facing operations into correct `ffmpeg` behavior, produces predictable and playable output, preserves safe overwrite semantics, and handles timestamps, filenames, codecs, metadata, and audio operations consistently across supported environments.
