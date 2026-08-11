# Requirements

## Overview

`clipcrank` is a shell wrapper around `ffmpeg` and `ffprobe` that provides simpler, more intuitive commands for common video operations.

The script is intended to be:
- simple,
- practical,
- portable across environments where the required FFmpeg tools are available,
- and robust enough to handle old or awkward media formats when `ffmpeg` can decode them.

The current implementation supports H.264/AAC MP4 re-encoding, video clipping, JPEG frame capture, metadata inspection and editing, frame-rate control, audio addition or replacement, still-image plus audio video creation, and safe overwrite handling.

Operations must be selected explicitly. Running the script with an input file but no operation shall print usage information rather than implicitly re-encoding the file.

## Functional Requirements

### 1. Operation Selection

The script shall support the following operations:

- `--reencode` to create standardized H.264/AAC MP4 output,
- `--add-audio` to add or replace audio using video or still-image visual input,
- `--show-metadata` to display input metadata and exit,
- `--frame TIME` to capture one or more JPEG still frames.

Only one operation may be selected per invocation.

If no operation is selected, the script shall print a usage message and exit non-zero.

### 2. Input Handling

The script shall:

- accept one required input path argument,
- accept one optional output path argument when the selected operation permits output,
- accept a separate required audio input path for `--add-audio`,
- derive an output path when no explicit output path is provided,
- reject execution when the wrong number of arguments is provided,
- reject execution when an input file does not exist,
- reject execution when an input path is not a regular file,
- reject execution when an input file is not readable,
- reject execution when input and output paths are the same.

For `--add-audio`, the visual input shall be classified using `ffprobe` rather than by filename extension. A single-frame visual input shall be treated as a still image; visual input containing multiple frames shall be treated as video. Input that cannot be classified as either a supported still image or video shall be rejected.

### 3. Output Naming

For video re-encoding, when no explicit output path is given, the script shall:

- replace the input file extension with `.mp4`, if an extension exists,
- otherwise append `.mp4` to the input path.

For `--add-audio` with video input, the default output path shall be derived from the video input path.

For `--add-audio` with still-image input, the default output basename shall be derived from the audio input filename with an `.mp4` extension.

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

The script shall encode audio as AAC when audio is present in standardized MP4 output.

The script shall verify that an AAC encoder is available in the local `ffmpeg` environment before attempting re-encoding or `--add-audio` output.

The script shall fail with a clear error message if no AAC encoder is available.

### 8. Add Audio

The script shall support:

```text
--add-audio VISUAL AUDIO [OUTPUT]
```

When `VISUAL` is video, the supplied audio shall replace or provide the output audio stream.

When `VISUAL` is a still image, the image shall be repeated for the duration of the supplied audio and combined with the audio to create H.264/AAC MP4 output.

Still-image input shall not be restricted by filename extension. Any still-image format that the installed FFmpeg build can decode may be used.

The script shall classify still-image versus video input from decoded media content using `ffprobe`.

The script shall use generic input looping for still-image input rather than depending on an image-format-specific looping option.

`--add-audio` shall not accept `--start` or `--end`.

`--add-audio` with still-image input shall not accept `--preserve-metadata`.

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

The script shall support the following metadata controls for re-encoded MP4 output:

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

The script shall require `ffprobe` to be installed and available on `PATH` for metadata inspection and `--add-audio` visual-input classification.

The script shall fail clearly when a required executable is unavailable.

Because FFmpeg builds differ by platform and distribution, the script shall adapt to the encoders and decoders exposed by the local FFmpeg installation.

### 14. Messaging and Exit Behavior

The script shall:

- print a usage message for invalid invocation,
- print clear error messages to standard error,
- print the selected video encoder during re-encoding,
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

Standard re-encoded output should be broadly playable in common software and devices.

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
- guarantee support for every possible codec, still-image format, or damaged media file.

Hardware-backed encoders may be detected by `ffmpeg` but still fail at runtime depending on the local system configuration, drivers, or device availability.

## Testing Requirements

The project shall be tested using both:

1. manual media-based testing, and
2. automated smoke and fixture-based testing.

At minimum, testing should cover:

- operation-selection validation,
- successful VP9-to-H.264 conversion of the committed Big Buck Bunny sample video,
- verification of the input and output video codecs with `ffprobe`,
- still-image plus audio creation using the committed Lenna and `bah.wav` fixtures,
- video plus replacement-audio creation using the committed video and audio fixtures,
- still-image detection that does not depend on a `.jpg` or `.png` filename extension,
- H.264/AAC verification of `--add-audio` output,
- default still-image output basename derivation from the audio input filename,
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

## Future Requirements Candidates

The project roadmap is maintained in `docs/ROADMAP.md`.

Potential future capabilities include:

- audio extraction and removal,
- resizing and scaling,
- cropping and padding,
- rotation and flipping,
- audio normalization and volume adjustment,
- playback-speed changes,
- concatenation,
- GIF and animated-image creation,
- subtitle handling,
- text and image overlays,
- target-quality or target-size compression,
- additional output codecs and containers,
- richer media-information reporting.