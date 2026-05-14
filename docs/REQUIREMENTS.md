# all2mp4 Requirements

## 1. Purpose

`all2mp4` is a shell-based utility for converting arbitrary input video files into a standardized MP4 output format for broad compatibility.

The primary use case is taking older, inconsistently encoded, or awkwardly formatted video files and producing a predictable output that:
- uses H.264 video,
- uses AAC audio when audio is present,
- is wrapped in an `.mp4` container,
- plays reliably across common operating systems, browsers, media players, and consumer devices.

## 2. Goals

The project shall:

1. Accept a wide variety of input video file formats and codecs.
2. Produce a standardized output format based on H.264 video in an MP4 container.
3. Preserve the essential content of the input file, including video and audio when present.
4. Prefer compatibility and reliability over perfect fidelity to the source format.
5. Be simple to run from a shell with minimal setup beyond requiring `ffmpeg`.
6. Be understandable and maintainable as a small shell-script-based project.

## 3. Non-Goals

The project is not intended to:

1. Preserve the original codec or container format.
2. Perform lossless archival transcoding.
3. Handle professional editing workflows or mezzanine formats.
4. Preserve every possible stream type from the source file.
5. Serve as a full media library manager.
6. Provide a GUI in the initial version.
7. Optimize for every edge case before a usable first release exists.

## 4. Target Output Standard

The default output produced by `all2mp4` shall conform to the following standard:

- **Container:** MP4
- **Video codec:** H.264
- **Audio codec:** AAC, when an audio stream exists
- **Pixel format:** `yuv420p` by default for broad compatibility
- **Streaming optimization:** `faststart` enabled when practical
- **Dimensions:** output dimensions should be valid for H.264 encoding, including adjustment to even-numbered dimensions if required

## 5. Functional Requirements

### 5.1 Input Handling

The tool shall:

1. Accept a path to a single input video file.
2. Support common and uncommon input containers, including older formats, so long as `ffmpeg` can decode them.
3. Fail with a clear error message if the input file does not exist.
4. Fail with a clear error message if the input file is not readable.
5. Fail with a clear error message if no video stream is present.
6. Include the first audio stream when present.
7. Succeed for video-only inputs by producing an MP4 without audio, if feasible.

### 5.2 Output Handling

The tool shall:

1. Produce an output file with the `.mp4` extension.
2. Allow the caller to specify an explicit output path.
3. Derive a default output path from the input filename when no explicit output path is given.
4. Avoid silently overwriting an existing file unless explicitly instructed to do so in a future option or flag.
5. Return a non-zero exit code when output creation fails.

### 5.3 Transcoding Behavior

The tool shall:

1. Re-encode video to H.264 using `ffmpeg`.
2. Re-encode audio to AAC when audio is present and supported by the installed `ffmpeg`.
3. Use defaults that favor broad playback compatibility over aggressive compression.
4. Adjust frame dimensions when necessary to satisfy encoder requirements.
5. Exclude subtitle, data, and other non-essential streams in the initial version unless explicitly supported later.
6. Handle malformed or older files as robustly as practical using conservative `ffmpeg` settings.

### 5.4 Command-Line Interface

The initial CLI shall:

1. Be invokable from a shell script or terminal.
2. Support the form:

   ```sh
   all2mp4 INPUT [OUTPUT]
   ```

3. Display a short usage message when invoked incorrectly.
4. Return exit status `0` on success.
5. Return a non-zero exit status on failure.

### 5.5 Dependencies

The project shall:

1. Require a POSIX-like shell environment.
2. Require `ffmpeg` to be installed and accessible on `PATH`.
3. Optionally use `ffprobe` if needed for validation or diagnostics.
4. Avoid introducing unnecessary runtime dependencies beyond common shell utilities in the initial version.

## 6. Quality Requirements

The tool should:

1. Be easy to inspect and modify by a user comfortable with shell scripts.
2. Use readable shell code and simple control flow.
3. Emit clear human-readable error messages.
4. Prefer deterministic behavior over surprising heuristics.
5. Be structured so that future enhancements can add batch processing, options, and tests without major redesign.

## 7. Compatibility Requirements

The output should be compatible with:

- modern web browsers,
- common desktop media players,
- mobile devices,
- standard MP4/H.264 playback environments.

The project should be usable on:

- Linux,
- macOS,
- other Unix-like environments where shell scripts and `ffmpeg` are available.

Windows support may be possible through environments such as Git Bash, MSYS2, or WSL, but is not a primary requirement for the initial version.

## 8. Error Handling Requirements

The tool shall report meaningful errors for at least the following cases:

- missing input argument,
- input file not found,
- input file unreadable,
- `ffmpeg` not installed,
- input cannot be decoded,
- output file cannot be written,
- transcoding process fails.

Error messages should be concise and actionable where possible.

## 9. Initial Project Scope

Version 1 should include:

1. Single-file conversion.
2. Optional explicit output filename.
3. Basic validation of dependencies and input file presence.
4. Standardized H.264/AAC MP4 output.
5. Basic documentation covering installation and usage.

## 10. Future Enhancements

Potential future work includes:

- batch conversion of directories,
- recursive conversion,
- configurable quality and encoder presets,
- overwrite flags,
- subtitle handling,
- metadata preservation options,
- structured logging,
- test fixtures and automated smoke tests,
- packaging and installation helpers.

## 11. Acceptance Criteria

The initial version will be considered acceptable if:

1. A user can run a single shell command against a supported input video file.
2. The command produces an `.mp4` output file.
3. The output uses H.264 video.
4. The output uses AAC audio when the source includes audio.
5. The resulting file plays successfully in common media players.
6. Failure cases produce understandable error messages and non-zero exit codes.

## 12. Design Principles

The project should follow these principles:

- **Compatibility first**
- **Simple invocation**
- **Reasonable defaults**
- **Clear failures**
- **Minimal dependencies**
- **Incremental evolution**