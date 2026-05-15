# Requirements

## Overview

`all2mp4.sh` is a shell script that converts a wide range of input video files into standardized MP4 output using `ffmpeg`.

The script is intended to be:
- simple,
- practical,
- portable across environments where `ffmpeg` is available,
- and robust enough to handle old or awkward media formats when `ffmpeg` can decode them.

The current implementation supports runtime detection of available encoders and selects a usable H.264 video encoder automatically.

## Functional Requirements

### 1. Input Handling

The script shall:

- accept one required input path argument,
- accept one optional output path argument,
- derive the output path from the input path when no output path is provided,
- reject execution when the wrong number of arguments is provided,
- reject execution when the input file does not exist,
- reject execution when the input path is not a regular file,
- reject execution when the input file is not readable,
- reject execution when input and output paths are the same,
- reject execution when the output file already exists.

### 2. Output Naming

When no explicit output path is given, the script shall:

- replace the input file extension with `.mp4`, if an extension exists,
- otherwise append `.mp4` to the input path.

The script shall write to a temporary output path before moving the completed file into place.

The temporary output path shall preserve a `.mp4` suffix so that `ffmpeg` can infer or accept the MP4 container correctly.

### 3. Conversion Behavior

The script shall invoke `ffmpeg` to:

- read the input media file,
- include the first video stream,
- include the first audio stream when audio exists,
- tolerate missing audio streams,
- omit subtitle streams,
- omit data streams,
- generate timestamps when needed,
- write MP4 output,
- move the completed temporary file into place only after successful conversion.

### 4. Video Encoding

The script shall encode video as H.264.

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

### 5. Audio Encoding

The script shall encode audio as AAC when audio is present.

The script shall verify that an AAC encoder is available in the local `ffmpeg` environment before attempting conversion.

The script shall fail with a clear error message if no AAC encoder is available.

### 6. Dependency Handling

The script shall require `ffmpeg` to be installed and available on `PATH`.

The script shall fail clearly when `ffmpeg` is unavailable.

Because `ffmpeg` builds differ by platform and distribution, the script shall adapt to the encoders exposed by the local `ffmpeg` binary.

### 7. Messaging and Exit Behavior

The script shall:

- print a usage message for invalid invocation,
- print clear error messages to standard error,
- print the selected video encoder during normal operation,
- print the created output path after successful conversion,
- exit non-zero on failure,
- exit zero on success.

### 8. Cleanup Behavior

The script shall remove partial temporary output files when conversion fails or is interrupted.

The script shall avoid leaving incomplete output in the final destination path.

## Non-Functional Requirements

### 1. Simplicity

The project should remain easy to read and maintain.

The implementation should remain a single flat shell script unless a clear reason emerges to increase structure.

### 2. Practical Portability

The script should work across different environments where shell execution and `ffmpeg` are available.

Behavior shall not depend on the presence of a single specific H.264 encoder implementation.

### 3. Conservative Output Compatibility

Output should be broadly playable in common software and devices.

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
- preserve all metadata,
- preserve chapter information,
- provide configurable encoding quality settings,
- provide batch conversion,
- provide recursive directory traversal,
- provide a `--force` overwrite mode,
- provide a `--verbose` or `--quiet` mode,
- guarantee identical output across different `ffmpeg` builds,
- guarantee support for every possible codec or damaged media file.

Hardware-backed encoders may be detected by `ffmpeg` but still fail at runtime depending on the local system configuration, drivers, or device availability.

## Testing Requirements

The project shall be tested using both:

1. manual media-based testing, and
2. simple smoke testing of failure paths.

At minimum, testing should cover:

- successful conversion of representative real-world files,
- missing input handling,
- invalid input path handling,
- output-already-exists handling,
- encoder-detection behavior,
- cleanup of temporary output artifacts on failure.

## Future Requirements Candidates

Possible future requirements may include:

- configurable encoder preference,
- configurable quality settings,
- overwrite mode,
- batch mode,
- better reporting of selected audio encoder,
- optional `ffprobe`-based post-conversion verification,
- automated fixture-based conversion tests.