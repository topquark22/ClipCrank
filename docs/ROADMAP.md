# ClipCrank Roadmap

ClipCrank is intended to be a practical, intuitive wrapper around `ffmpeg` and `ffprobe`. The goal is not to reproduce every `ffmpeg` option. Instead, ClipCrank should expose common user intentions through simple, memorable operations and hide the lower-level codec, filter, stream-mapping, and container details where reasonable.

## Design Principles

- Prefer task-oriented operations over direct exposure of raw `ffmpeg` flags.
- Keep command syntax simple enough that common operations do not require consulting the `ffmpeg` manual.
- Preserve access to predictable, explicit behavior rather than relying unnecessarily on `ffmpeg` defaults.
- Avoid introducing new dependencies when `ffmpeg` or `ffprobe` can perform the operation directly.
- Keep operations composable where combinations are well-defined, but reject conflicting or ambiguous combinations.
- Preserve safe output behavior: do not overwrite existing files unless `--force` is specified.
- Continue supporting useful filename normalization for generated clips and frame captures.
- Add real-media regression tests for operations that depend on codecs, containers, timing, or metadata.

## Current Capabilities

ClipCrank currently provides:

- Re-encoding video as standardized H.264/AAC MP4 with `--reencode`.
- Optional constant or explicit frame-rate conversion.
- Video clipping with `--start` and `--end`.
- Single and multiple JPEG frame capture.
- Configurable JPEG quality.
- Metadata inspection with `--show-metadata`.
- Metadata preservation, clearing, and explicit metadata editing.
- Safe overwrite handling with `--force`.

## Near-Term Priorities

### 1. Extract Audio to MP3

Allow extraction of the audio stream from a video file.

In keeping with ClipCrank's goal of providing a simple interface rather than exposing every `ffmpeg` possibility, extracted audio will always be written as MP3. Supporting multiple audio output formats would add command-line and encoding complexity without improving the primary use case.

Possible interface:

```sh
clipcrank --extract-audio input.mp4 output.mp3
```

When no output filename is supplied, derive an `.mp3` filename from the input filename.

### 2. Replace Audio

Allow the video from one input file to be combined with audio from a separate audio file.

The replacement audio input may use any audio format that the installed `ffmpeg` can decode. The resulting video output will use ClipCrank's standard H.264/AAC MP4 format.

Possible interface:

```sh
clipcrank --replace-audio input.mp4 soundtrack.wav output.mp4
```

### 3. Remove Audio

Provide an operation that creates a video without an audio stream.

Possible interface:

```sh
clipcrank --remove-audio input.mp4 output.mp4
```

This operation should remove the audio stream rather than merely setting its volume to zero. Output should remain in ClipCrank's standard H.264 MP4 format.

### Media Information

Provide a general inspection operation, building on `--show-metadata`, that reports useful media properties in a concise form:

- container format
- duration
- video codec
- resolution
- frame rate
- pixel format
- video bitrate
- audio codec
- sample rate
- channel count
- audio bitrate

The objective is a friendlier summary than raw `ffprobe` output.

### Resize and Scale

Provide intuitive video resizing without requiring users to write an `ffmpeg` filter expression.

Possible interface:

```sh
clipcrank --resize 1280x720 input.mp4 output.mp4
clipcrank --width 1280 input.mp4 output.mp4
clipcrank --height 720 input.mp4 output.mp4
```

When only one dimension is specified, preserve the source aspect ratio automatically.

### Crop and Pad

Support common framing operations:

- explicit crop dimensions and offsets
- center crop
- square crop
- common aspect ratios such as 16:9, 4:3, and 9:16
- padding to a target aspect ratio without cropping

### Rotate and Flip

Provide simple operations for:

- 90-degree clockwise rotation
- 90-degree counter-clockwise rotation
- 180-degree rotation
- horizontal flip
- vertical flip

### Playback Speed

Support changing playback speed while keeping video and audio synchronized.

Possible interface:

```sh
clipcrank --speed 0.5 input.mp4 output.mp4
clipcrank --speed 1.5 input.mp4 output.mp4
clipcrank --speed 2 input.mp4 output.mp4
```

Audio pitch should remain natural where practical.

### GIF Creation

Create animated GIFs directly from video, optionally combined with existing clip controls.

Possible interface:

```sh
clipcrank --gif --start 10 --end 15 input.mp4 output.gif
```

ClipCrank should hide palette-generation details required for good GIF quality.

### Concatenate Videos

Provide a straightforward way to join multiple compatible videos.

Possible interface:

```sh
clipcrank --concat first.mp4 second.mp4 third.mp4 output.mp4
```

Where possible, avoid re-encoding when the input streams are already compatible. When re-encoding is required, make that behavior explicit.

## Medium-Term Features

### Volume Adjustment and Loudness Normalization

Support both simple gain changes and standards-based normalization.

Potential operations include:

- percentage or dB volume adjustment
- peak normalization
- LUFS loudness normalization
- EBU R128-compatible normalization

### Text and Image Overlays

Allow common overlays without requiring users to construct filter graphs:

- text labels
- timestamps
- image or logo overlays
- simple position presets such as top-left, top-right, bottom-left, and bottom-right

### Subtitle Operations

Provide separate operations to:

- burn subtitles into the video
- extract subtitle streams
- copy subtitle streams when producing compatible containers

### Contact Sheets

Build on the existing multi-frame capture support to generate thumbnail/contact sheets containing a grid of representative frames.

### Fade In and Fade Out

Support simple audio and video fades with configurable durations.

### Remux Without Re-Encoding

Allow container changes when the existing codecs are already compatible with the target container.

Possible interface:

```sh
clipcrank --remux input.mkv output.mp4
```

This should use stream copying and avoid generation loss whenever possible.

### Video Quality and Compression Presets

Provide user-oriented quality controls instead of requiring knowledge of CRF values, encoder presets, and bitrates.

Possible examples:

```sh
clipcrank --quality high input.mov output.mp4
clipcrank --quality medium input.mov output.mp4
```

A later extension could support approximate target file sizes.

### Split Video

Allow splitting a source into multiple clips by:

- fixed duration
- explicit timestamps
- approximate target file size

### Create Video from Images

Support image sequences and simple slideshows.

Potential use cases include:

- numbered image sequences
- still-image slideshows
- configurable image duration
- optional transitions

## Longer-Term Possibilities

These features are useful but should be added only if they can retain ClipCrank's simple command-line model:

- scene-change detection
- automatic thumbnail selection
- video denoising
- sharpening
- deinterlacing
- automatic black-bar detection and cropping
- reverse video or audio
- looping clips
- picture-in-picture
- side-by-side or vertically stacked video composition
- blur or redact a selected region
- portrait-video background padding or blur
- mono/stereo conversion and channel selection
- waveform and spectrogram image generation
- HLS or DASH output for streaming
- animated WebP or AVIF output
- AV1, VP9, ProRes, and other explicit output-codec targets
- social-media-oriented presets for common dimensions and frame rates

## Out of Scope by Default

ClipCrank should not become a second syntax for arbitrary `ffmpeg` command lines. In particular, exposing unrestricted equivalents of `-vf`, `-af`, `-filter_complex`, stream maps, and arbitrary pass-through arguments should be approached cautiously.

Advanced users who already need arbitrary filter graphs or detailed stream control are generally better served by invoking `ffmpeg` directly. ClipCrank is most valuable when it makes common operations significantly easier to discover, remember, and use.

## Testing Strategy

New operations should generally include:

- argument-validation tests
- option-conflict tests
- output-name and overwrite tests where applicable
- real-media tests where codec or container behavior matters
- `ffprobe` verification of generated output properties
- tests for Windows/Cygwin interoperability where native Windows `ffmpeg` or `ffprobe` behavior differs from POSIX tools

The committed Big Buck Bunny VP9 WebM sample can serve as a canonical real-video fixture for future codec and container tests.
