# Requirements

## Overview

`clipcrank` is a shell wrapper around `ffmpeg` and `ffprobe` that provides simpler, more intuitive commands for common video operations.

The script is intended to be:
- simple,
- practical,
- portable across environments where the required FFmpeg tools are available,
- and robust enough to handle old or awkward media formats when `ffmpeg` can decode them.

The current implementation supports H.264/AAC MP4 re-encoding, video clipping, JPEG frame capture, metadata inspection and editing, frame-rate control, adding or replacing audio, and safe overwrite handling.

Operations must be selected explicitly. Running the script with an input file but no operation shall print usage information rather than implicitly re-encoding the file.

## Functional Requirements

### 1. Operation Selection

The script shall support the following operations:

- `--reencode` to create standardized H.264/AAC MP4 output,
- `--add-audio` to add or replace audio using a video or JPEG/PNG still image as the visual input,
- `--show-metadata` to display input metadata and exit,
- `--frame TIME` to capture one or more JPEG still frames.

Only one operation may be selected per invocation.

If no operation is selected, the script shall print a usage message and exit non-zero.

### 2. Input Handling

The script shall:

- accept one required input path argument for operations other than `--add-audio`,
- accept one visual input path and one audio input path for `--add-audio`,
- accept one optional output path argument when the selected operation permits output,
- derive an output path when no explicit output path is provided,
- reject execution when the wrong number of arguments is provided,
- reject execution when an input file does not exist,
- reject execution when an input path is not a regular file,
- reject execution when an input file is not readable,
- reject execution when input and output paths are the same.

For `--add-audio`, the first input shall be either a video file or a JPEG/PNG still image. The second input may use any audio format that the installed `ffmpeg` can decode.

### 3. Output Naming

For video re-encoding, when no explicit output path is given, the script shall:

- replace the input file extension with `.mp4`, if an extension exists,
- otherwise append `.mp4` to the input path.

For `--add-audio` with video input, when no explicit output path is given, the script shall derive the `.mp4` output path from the video input path.

For `--add-audio` with JPEG/PNG still-image input, when no explicit output path is given, the script shall derive the output basename from the audio input filename and use an `.mp4` extension.

For single-frame capture, when no explicit output path is given, the script shall append a normalized timestamp to the input base name and use a `.jpg` extension.

Frame timestamps used in filenames shall:

- zero-pad supplied hour, minute, and second fields as needed,
- normalize seconds values greater than 59 into minutes and seconds,
- include hours only when required by the supplied timestamp or by a multi-frame sequence that crosses an hour boundary,
- include milliseconds only when milliseconds are supplied or required by the frame interval,
- remain sortable in chronological order within a generated sequence.

The script shall write media output to a temporary output path before moving the completed file into place.

Temporary video output shall preserve a `.mp4` suffix so that `ffmpeg` can infer or accept the MP4 container correctly.

### 4. Overwrite Behavior

The script shall refuse to overwrite existing output files by default.

The script shall support `-f` and `--force` to allow existing output files to be replaced.

For multi-frame capture without `--force`, all target filenames shall be checked before capture begins. If any target already exists, no frames shall be created.

With `--force`, an existing final output shall be replaced only after the new temporary output has been created successfully.

### 5. Re-encoding Behavior

When `--reencode` is selected, the script shall invoke `ffmpeg` to:

- read the input media file,
- include the first video stream,
- include audio streams when audio exists,
- tolerate missing audio streams,
- omit subtitle streams,
- omit data streams,
- generate timestamps when needed,
- write MP4 output,
- move the completed temporary file into place only after successful conversion.

### 6. Video Encoding

The script shall encode re-encoded video as H.264.

The script shall select an available H.264 encoder at runtime rather than assuming a single encoder is always present.

The current preferred encoder order is:

1. `libx264`
2. `libopenh264`
3. `h264_nvenc`
4. `h264_qsv`
5. `h264_amf`
6. `h264_mf`
7. `h264_d3d12va`
8. `h264_vulkan`
9. `h264_videotoolbox`

The script shall fail with a clear error message if no supported H.264 encoder is available.

The script shall normalize output to `yuv420p`.

The script shall scale output dimensions to even-numbered width and height values.

The script shall use `+faststart` for MP4 output.

### 7. Audio Encoding

The script shall encode audio as AAC when audio is present.

The script shall verify that an AAC encoder is available in the local `ffmpeg` environment before attempting re-encoding or `--add-audio` output.

The script shall fail with a clear error message if no AAC encoder is available.

### 8. Add Audio

When `--add-audio` is selected, the script shall accept:

```text
--add-audio VIDEO AUDIO [OUTPUT]
```

or:

```text
--add-audio IMAGE AUDIO [OUTPUT]
```

When the first input is video, the script shall:

- use the video stream from the first input,
- use the audio stream from the second input,
- replace any existing audio from the video input,
- encode output as H.264/AAC MP4.

When the first input is a JPEG or PNG still image, the script shall:

- loop the still image as the video source,
- use the audio stream from the second input,
- produce output for the duration of the audio,
- encode output as H.264/AAC MP4.

`--add-audio` shall not be accepted with `--start` or `--end`.

`--preserve-metadata` shall not be accepted with still-image `--add-audio` input.

### 9. Frame Rate

The script shall support `--fps N` to convert output video to an explicit frame rate.

The script shall support `--cfr` to force constant-frame-rate output while allowing `ffmpeg` to determine the rate.

`--fps` and `--cfr` shall not be accepted together.

Frame-rate options shall not be accepted with frame-capture operations.

### 10. Video Clipping

The script shall support `--start TIME` and `--end TIME` with `--reencode`.

Accepted timestamps shall use:

```text
[[h:]m:]s[.ms]
```

The script shall:

- default `--start` to the beginning of the input when omitted,
- default `--end` to the end of the input when omitted,
- accept seconds-only, minutes-and-seconds, and hours-minutes-seconds forms,
- accept up to three decimal digits of milliseconds,
- require `--end` to be later than `--start` when both are supplied,
- reject invalid minute or second fields,
- reject clipping options when frame capture is selected.

Clip timestamps are not required to be incorporated automatically into the default video output filename.

### 11. JPEG Frame Capture

The script shall support capture of a single JPEG frame using:

```text
--frame TIME
```

The script shall support capture of multiple JPEG frames using:

```text
--frame START --interval TIME --count N
```

For multi-frame capture:

- `--interval` and `--count` shall require each other,
- the interval shall be greater than zero,
- the count shall be a positive integer,
- generated filenames shall include normalized timestamps,
- if any generated timestamp reaches hour 1 or later, all filenames in the sequence shall include an hour field.

The script shall support `--jpeg-quality N`, with values from 1 through 100.

JPEG quality shall default to 90 when not specified.

`--jpeg-quality` shall require frame-capture mode.

Frame capture shall not be accepted with clipping, frame-rate, or metadata-editing options.

### 12. Metadata

The script shall support display of metadata using:

```text
--show-metadata INPUT
```

Metadata inspection shall use `ffprobe`, shall not create output, and shall not accept output-modifying options.

The script shall support the following metadata controls for generated MP4 output:

- `--metadata KEY=VALUE`, repeatable for arbitrary metadata fields,
- `--title TEXT`,
- `--artist TEXT`,
- `--album TEXT`,
- `--date TEXT`,
- `--comment TEXT`,
- `--preserve-metadata`,
- `--clear-metadata`.

`--preserve-metadata` and `--clear-metadata` shall not be accepted together.

Metadata options shall not be accepted with frame capture.

### 13. Dependency Handling

The script shall require `ffmpeg` to be installed and available on `PATH` for media-writing operations.

The script shall require `ffprobe` to be installed and available on `PATH` for metadata inspection.

The script shall fail clearly when a required executable is unavailable.

Because FFmpeg builds differ by platform and distribution, the script shall adapt to the encoders exposed by the local `ffmpeg` binary.

### 14. Messaging and Exit Behavior

The script shall:

- print a usage message for invalid invocation,
- print clear error messages to standard error,
- print the selected video encoder during re-encoding and audio-addition operations,
- print created output paths after successful operations,
- exit non-zero on failure,
- exit zero on success.

### 15. Cleanup Behavior

The script shall remove partial temporary output files when an operation fails or is interrupted.

The script shall avoid leaving incomplete output in the final destination path.

## Non-Functional Requirements

### 1. Simplicity

The project should remain easy to read and maintain.

The implementation should remain a single flat shell script unless a clear reason emerges to increase structure.

ClipCrank should expose common user intentions rather than merely reproducing raw `ffmpeg` command-line syntax under different option names.

### 2. Practical Portability

The script should work across different environments where shell execution and the required FFmpeg tools are available.

Behavior shall not depend on the presence of a single specific H.264 encoder implementation.

Tests that invoke native Windows FFmpeg tools under Cygwin shall avoid POSIX absolute paths where native Windows executables cannot resolve them.

### 3. Conservative Output Compatibility

Standard generated video output should be broadly playable in common software and devices.

To support this, the script should:
- use MP4 output,
- use H.264 video,
- use AAC audio,
- use `yuv420p`,
- use `+faststart`.

### 4. Safety

The script should avoid accidental overwrites by default.

The script should avoid leaving broken partial output files behind.

## Current Known Limitations

The script does not currently aim to:

- preserve subtitle streams,
- preserve data streams,
- preserve chapter information,
- provide configurable video quality settings,
- provide batch conversion as a built-in operation,
- provide recursive directory traversal,
- provide a `--verbose` or `--quiet` mode,
- guarantee identical output across different `ffmpeg` builds,
- guarantee support for every possible codec or damaged media file.

Hardware-backed encoders may be detected by `ffmpeg` but still fail at runtime depending on the local system configuration, drivers, or device availability.

## Testing Requirements

The project shall be tested using both:

1. manual media-based testing, and
2. automated smoke and fixture-based testing.

At minimum, testing should cover:

- operation-selection validation,
- successful VP9-to-H.264 conversion of the committed Big Buck Bunny sample video,
- verification of the input and output video codecs with `ffprobe`,
- still-image plus audio generation using the committed Lenna and `bah.wav` fixtures,
- video plus replacement-audio generation,
- H.264/AAC verification of `--add-audio` output,
- default still-image `--add-audio` output basename derived from the audio filename,
- missing input handling,
- invalid input path handling,
- output-already-exists handling,
- force-overwrite parsing and behavior,
- timestamp validation,
- clipping across an hour boundary,
- frame filename normalization,
- multi-frame filename sorting across an hour boundary,
- metadata inspection,
- encoder-detection behavior,
- cleanup of temporary output artifacts on failure.

The real-media codec tests shall tolerate CRLF line endings from native Windows `ffprobe` when run under Cygwin.

Generated integration-test artifacts shall be written under `tmp/` and may be retained after successful tests for manual inspection and UAT.

## Future Requirements Candidates

The project roadmap is maintained in `docs/ROADMAP.md`.

Potential future capabilities include:

- resizing and scaling,
- cropping and padding,
- rotation and flipping,
- audio extraction and removal,
- audio normalization and volume adjustment,
- playback-speed changes,
- concatenation,
- GIF and animated-image creation,
- subtitle handling,
- text and image overlays,
- target-quality or target-size compression,
- additional output codecs and containers,
- richer media-information reporting.