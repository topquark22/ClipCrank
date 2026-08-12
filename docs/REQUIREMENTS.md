# Requirements

## Overview

`clipcrank` is a shell wrapper around `ffmpeg` and `ffprobe` that provides simpler, more intuitive commands for common video operations.

The script is intended to be:
- simple,
- practical,
- portable across environments where the required FFmpeg tools are available,
- and robust enough to handle old or awkward media formats when `ffmpeg` can decode them.

The current implementation supports H.264/AAC MP4 re-encoding, video clipping, JPEG frame capture, metadata inspection and editing, frame-rate control, audio addition or replacement, still-image plus audio video creation, MP3 audio extraction, audio removal, container remuxing, and safe overwrite handling.

Operations must normally be selected explicitly. `--start` or `--end` may select clip creation directly when the input is already suitable for H.264/AAC stream copying. Running the script with an input file but no operation or clip boundary shall print usage information rather than implicitly re-encoding the file.

## Functional Requirements

### 1. Operation Selection

The script shall support the following operations:

- `--reencode` to create standardized H.264/AAC MP4 output,
- `--add-audio` to add or replace audio using video or still-image visual input,
- `--extract-audio` to extract the first audio stream as MP3,
- `--remove-audio` to create H.264 MP4 output without an audio stream,
- `--remux` to change the media container without re-encoding streams,
- `--show-metadata` to display stored input metadata tags and exit,
- `--frame TIME` to capture one or more JPEG still frames.

The planned `--info` operation shall provide concise technical media information without changing the file.

Only one operation may be selected per invocation.

`--start` or `--end` without another operation shall select clip creation. If the input is not eligible for H.264/AAC stream-copy clipping, the invocation shall fail and instruct the user to add `--reencode`.

If no operation or clip boundary is selected, the script shall print a usage message and exit non-zero.

### 2. Input Handling

The script shall:

- accept one required input path argument,
- accept one optional output path argument when the selected operation permits output,
- accept a separate required audio input path for `--add-audio`,
- require an explicit output path for `--remove-audio` and `--remux`,
- derive an output path when no explicit output path is provided and the selected operation permits default naming,
- reject execution when the wrong number of arguments is provided,
- reject execution when an input file does not exist,
- reject execution when an input path is not a regular file,
- reject execution when an input file is not readable,
- reject execution when input and output paths are the same.

For `--add-audio`, the visual input shall be classified using `ffprobe` rather than by filename extension. A single-frame visual input shall be treated as a still image; visual input containing multiple frames shall be treated as video. Input that cannot be classified as either a supported still image or video shall be rejected.

For `--remove-audio`, both the input path and output path shall be required. The operation shall not derive a default output filename.

For `--remux`, both the input path and output path shall be required. The output path shall include a filename extension so that FFmpeg can determine the requested target container.

The planned `--info` operation shall accept exactly one input file and no output path.

### 3. Output Naming

For video re-encoding, when no explicit output path is given, the script shall:

- replace the input file extension with `.mp4`, if an extension exists,
- otherwise append `.mp4` to the input path.

For stream-copy clipping, the same derived `.mp4` output naming rule shall apply when no explicit output path is given.

For `--add-audio` with video input, the default output path shall be derived from the video input path.

For `--add-audio` with still-image input, the default output basename shall be derived from the audio input filename with an `.mp4` extension.

For `--extract-audio`, when no explicit output path is given, the script shall replace the input extension with `.mp3`, or append `.mp3` if the input has no extension.

Explicit `--extract-audio` output paths shall use the `.mp3` extension.

For `--remove-audio`, an explicit `.mp4` output path shall be mandatory. No default output path shall be generated.

For `--remux`, an explicit output path with a filename extension shall be mandatory. The extension shall determine the requested target container. No default output path shall be generated.

For single-frame capture, when no explicit output path is given, the script shall append a normalized timestamp to the input base name and use a `.jpg` extension.

Frame timestamps used in filenames shall:

- zero-pad supplied hour, minute, and second fields as needed,
- normalize seconds values greater than 59 into minutes and seconds,
- include hours only when required by the supplied timestamp or by a multi-frame sequence that crosses an hour boundary,
- include milliseconds only when milliseconds are supplied or required by the frame interval,
- remain sortable in chronological order within a generated sequence.

The script shall write media output to a temporary output path before moving the completed file into place.

Temporary video output shall preserve a `.mp4` suffix so that `ffmpeg` can infer or accept the MP4 container correctly. Temporary extracted-audio output shall preserve a `.mp3` suffix. Temporary remux output shall preserve the requested target filename extension.

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

For `--extract-audio`, the script shall select an available MP3 encoder from supported local FFmpeg encoders and encode the extracted audio at 192 kb/s.

The current MP3 encoder preference is:

1. `libmp3lame`
2. `libshine`
3. `mp3_mf`

The script shall fail with a clear error message if no supported MP3 encoder is available.

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

### 9. Extract Audio

The script shall support:

```text
--extract-audio INPUT [OUTPUT]
```

The operation shall extract the first audio stream from the input and encode it as MP3.

The operation shall omit video, subtitle, and data streams.

If the input does not contain a usable audio stream, the operation shall fail without creating the final output file.

`--extract-audio` shall not accept clipping, frame-rate, or metadata options.

### 10. Remove Audio

The script shall support:

```text
--remove-audio INPUT OUTPUT
```

Both input and output paths shall be mandatory.

The operation shall omit all audio streams from the output rather than muting them.

The output shall contain the first video stream encoded as H.264 in an MP4 container.

The operation shall omit subtitle and data streams.

`--remove-audio` shall not accept clipping, frame-rate, or metadata options.

### 11. Frame Rate

The script shall support `--fps N` to convert output video to an explicit frame rate.

The script shall support `--cfr` to force constant-frame-rate output while allowing `ffmpeg` to determine the rate.

`--fps` and `--cfr` shall not be accepted together.

Frame-rate options shall not be accepted with frame-capture operations.

### 12. Video Clipping

The script shall support `--start TIME` and `--end TIME` either with `--reencode` or as a standalone clip operation when stream copying is possible.

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

When `--start` or `--end` is used without `--reencode`, the script shall use `ffprobe` to verify that:

- the first video stream uses H.264,
- every audio stream, if present, uses AAC.

H.264 video with no audio stream shall be eligible for stream-copy clipping.

If the input is eligible, the script shall create MP4 output by copying the existing video and audio streams without re-encoding.

If the input is not eligible, the script shall fail clearly and require the user to specify `--reencode`.

Standalone stream-copy clipping shall not accept frame-rate or metadata-editing options.

When standalone stream-copy clipping includes `--start`, the script shall use `ffprobe` to determine the preceding usable video keyframe. If the keyframe timestamp differs from the requested start timestamp, the script shall print the requested timestamp, the keyframe timestamp, and the difference before creating output.

When such an adjustment is required, the script shall prompt:

```text
Continue without re-encoding? [Y/n]
```

The default response shall be yes. A response of `n` or `no` shall cancel the operation without creating output and shall advise the user to use `--reencode` for an exact start time.

The script shall support `-y` and `--yes` to accept a keyframe-adjusted stream-copy start without prompting. This option shall not suppress the informational timestamp messages.

If the requested start already corresponds to the usable keyframe, no confirmation prompt shall be required. End-only stream-copy clipping shall not require a keyframe confirmation prompt.

Stream-copy clipping is constrained by existing keyframes and is not required to be frame-exact at the requested start timestamp. `--reencode` remains available when exact transcoded clipping or codec normalization is required.

Clip timestamps are not required to be incorporated automatically into the default video output filename.

### 13. JPEG Frame Capture

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

### 14. Metadata

The script shall support display of stored metadata tags using:

```text
--show-metadata INPUT
```

Metadata inspection shall use `ffprobe`, shall not create output, and shall not accept output-modifying options.

`--show-metadata` shall remain semantically limited to stored descriptive metadata tags. Technical media properties such as codec, resolution, frame rate, duration, and bitrate shall belong to `--info` rather than `--show-metadata`.

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

Metadata options shall not be accepted with frame capture, `--extract-audio`, `--remove-audio`, or `--remux`.

### 15. Media Information

The planned `--info` operation shall support:

```text
--info INPUT
```

`--info` shall be a read-only inspection operation and shall not create or modify any output file.

`--info` shall use `ffprobe` to report concise, human-readable technical media information, including where applicable:

- container format,
- duration,
- overall bitrate,
- video codec,
- resolution,
- frame rate,
- pixel format,
- video bitrate,
- audio codec,
- sample rate,
- channel count,
- audio bitrate.

Information shall be grouped into logical sections such as File or Container, Video, and Audio.

Sections that do not apply to the input shall be omitted or clearly reported as absent. Audio-only input shall not require a Video section, and video without audio shall clearly indicate that no audio stream is present.

`--info` shall accept exactly one input file, shall not accept an output path, and shall not accept output-modifying options.

`--info` shall not replace or duplicate `--show-metadata`; the two operations shall remain distinct, with `--info` reporting technical media properties and `--show-metadata` reporting stored metadata tags.

### 16. Dependency Handling

The script shall require `ffmpeg` to be installed and available on `PATH` for media-writing operations.

The script shall require `ffprobe` to be installed and available on `PATH` for metadata inspection, planned `--info` media inspection, `--add-audio` visual-input classification, standalone clip codec validation, and stream-copy keyframe inspection.

The script shall fail clearly when a required executable is unavailable.

Because FFmpeg builds differ by platform and distribution, the script shall adapt to the encoders and decoders exposed by the local FFmpeg installation.

### 17. Messaging and Exit Behavior

The script shall:

- print a usage message for invalid invocation,
- print clear error messages to standard error,
- print the selected video or audio encoder when applicable,
- print created output paths after successful operations,
- exit non-zero on failure,
- exit zero on success.

### 18. Remux

The script shall support:

```text
--remux INPUT OUTPUT
```

Both input and output paths shall be mandatory.

The operation shall copy all input streams with FFmpeg stream copying rather than re-encoding them.

The operation shall use the output filename extension to select the target container.

The operation shall not silently fall back to transcoding. If the target container cannot accept one or more input streams, the remux operation shall fail without creating the final output file.

`--remux` shall not select or require H.264, AAC, or MP3 encoders.

`--remux` shall not accept clipping, frame-rate, or metadata-editing options.

The operation shall preserve normal overwrite protection and temporary-output cleanup behavior.

### 19. Cleanup Behavior

The script shall remove partial temporary output files when an operation fails or is interrupted.

The script shall avoid leaving incomplete output in the final destination path.

## Non-Functional Requirements

### 1. Simplicity

The project should remain easy to read and maintain.

The implementation should remain a single flat shell script unless a clear reason emerges to increase structure.

ClipCrank should expose common user intentions rather than merely reproducing raw `ffmpeg` command-line syntax under different option names.

### 2. Practical Portability

The script should work across different environments where shell execution and the required FFmpeg tools are available.

Behavior shall not depend on the presence of a single specific H.264 or MP3 encoder implementation.

Tests that invoke native Windows FFmpeg tools under Cygwin shall avoid POSIX absolute paths where native Windows executables cannot resolve them.

### 3. Conservative Output Compatibility

Standard re-encoded output should be broadly playable in common software and devices.

To support this, the script should:
- use MP4 output,
- use H.264 video,
- use AAC audio,
- use `yuv420p`,
- use `+faststart`.

Extracted audio should use MP3 for broad compatibility.

Audio-removed video should use H.264 MP4 without an audio stream.

### 4. Safety

The script should avoid accidental overwrites by default.

The script should avoid leaving broken partial output files behind.

## Current Known Limitations

The script does not currently aim to:

- preserve subtitle streams,
- preserve data streams,
- preserve chapter information,
- provide configurable video quality settings,
- provide configurable extracted-audio format,
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
- standalone clip operation selection with `--start` or `--end`,
- rejection of standalone clipping for non-H.264/AAC input with guidance to use `--reencode`,
- successful stream-copy clipping of H.264/AAC input,
- preservation of H.264/AAC codecs in stream-copy clip output,
- reporting of the requested and usable keyframe start timestamps when they differ,
- `-y` / `--yes` suppression of the confirmation prompt without suppressing informational output,
- cancellation without output when the user declines an adjusted stream-copy start,
- successful VP9-to-H.264 conversion of the committed Big Buck Bunny sample video,
- verification of the input and output video codecs with `ffprobe`,
- still-image plus audio creation using the committed Lenna and `bah.wav` fixtures,
- video plus replacement-audio creation using the committed video and audio fixtures,
- still-image detection that does not depend on a `.jpg` or `.png` filename extension,
- H.264/AAC verification of `--add-audio` output,
- default still-image output basename derivation from the audio input filename,
- extraction of MP3 audio from a generated video containing AAC audio,
- MP3 codec verification with `ffprobe`,
- default `.mp3` output naming,
- mandatory output handling for `--remove-audio`,
- H.264 verification of `--remove-audio` output,
- verification that `--remove-audio` output contains no audio stream,
- mandatory output handling for `--remux`,
- rejection of incompatible video or metadata options with `--remux`,
- successful remuxing to a different container,
- verification of the requested remux container with `ffprobe`,
- verification that remuxing preserves the input video and audio codecs,
- missing input handling,
- invalid input path handling,
- output-already-exists handling,
- force-overwrite parsing and behavior,
- timestamp validation,
- clipping across an hour boundary,
- frame filename normalization,
- multi-frame filename sorting across an hour boundary,
- metadata inspection,
- planned `--info` technical media inspection,
- encoder-detection behavior,
- cleanup of temporary output artifacts on failure.

The real-media codec tests shall tolerate CRLF line endings from native Windows `ffprobe` when run under Cygwin.

## Future Requirements Candidates

The project roadmap is maintained in `docs/ROADMAP.md`.

Potential future capabilities include:

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
- additional output codecs and containers.