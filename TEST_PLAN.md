# Test Plan

This document describes how to test `all2mp4.sh`.

The project is small, so the testing approach is intentionally practical:
- verify that the script works on representative real-world files,
- verify that common failure cases are handled clearly,
- verify that output files are playable and normalized as expected.

## Goals

The test plan aims to confirm that `all2mp4.sh`:

- accepts a variety of input containers,
- converts them into playable `.mp4` output,
- selects a working H.264 encoder from the local `ffmpeg` environment,
- uses AAC audio when audio is present,
- succeeds on old or awkward media when `ffmpeg` can decode it,
- fails clearly when prerequisites or input files are missing,
- avoids clobbering existing output files.

## Out of Scope

This project does not currently aim to prove:

- bit-exact reproducibility,
- archival-quality transcoding,
- preservation of all metadata,
- subtitle retention,
- support for every codec ever produced,
- identical encoding results across all platforms.

Because encoder availability differs by environment, tests focus on:
- successful operation,
- playable output,
- expected output format,
rather than identical binary output.

## Test Approach

Testing should combine:

1. **Manual real-file testing**
   - Use actual media files from different eras and containers.
   - Confirm that output is created and plays.

2. **Command-line behavior testing**
   - Verify argument handling and error reporting.

3. **Output inspection**
   - Use `ffprobe` where available to confirm output container and codecs.

## Environment Notes

The script depends heavily on the local `ffmpeg` build.

Different machines may expose different encoders, for example:
- `libx264`
- `libopenh264`
- `h264_nvenc`
- `h264_qsv`
- `h264_amf`
- other platform-specific H.264 encoders

Therefore:
- tests should verify that the script chooses a working encoder,
- tests should not assume the same encoder exists everywhere.

## Core Success Criteria

A test is considered successful when:

- the script exits with status `0`,
- the output file is created,
- the output file is an `.mp4`,
- the output is playable in a normal media player,
- the output video codec is H.264,
- the output audio codec is AAC when the source contains audio.

## Manual Test Matrix

### 1. Legacy FLV with audio

**Purpose:** confirm that an old Flash-era file can be converted successfully.

Example command:

```sh
./all2mp4.sh sample.flv output.mp4
```

Expected result:
- succeeds,
- produces playable MP4,
- output video is H.264,
- output audio is AAC if present.

### 2. FLV without audio

**Purpose:** confirm that optional audio mapping behaves correctly.

Example command:

```sh
./all2mp4.sh silent.flv silent.mp4
```

Expected result:
- succeeds,
- produces MP4 with video only,
- no failure due to missing audio stream.

### 3. AVI input

**Purpose:** confirm support for a common legacy container.

Example command:

```sh
./all2mp4.sh sample.avi sample.mp4
```

Expected result:
- succeeds,
- output is playable,
- output video is H.264.

### 4. MOV input

**Purpose:** confirm support for camera/editor style source files.

Example command:

```sh
./all2mp4.sh sample.mov sample.mp4
```

Expected result:
- succeeds,
- output is playable.

### 5. MKV input

**Purpose:** confirm support for a modern but flexible container.

Example command:

```sh
./all2mp4.sh sample.mkv sample.mp4
```

Expected result:
- succeeds,
- output is playable.

### 6. Video with odd dimensions

**Purpose:** verify that scaling to even dimensions works.

Example command:

```sh
./all2mp4.sh odd-dimensions.mkv odd-dimensions.mp4
```

Expected result:
- succeeds,
- output dimensions are encoder-safe,
- output remains playable.

### 7. Video-only input

**Purpose:** confirm success when no audio stream exists.

Example command:

```sh
./all2mp4.sh video-only.avi video-only.mp4
```

Expected result:
- succeeds,
- output has video only,
- no failure due to missing audio.

### 8. Input with subtitles or data streams

**Purpose:** verify that extra streams do not break conversion.

Example command:

```sh
./all2mp4.sh extra-streams.mkv extra-streams.mp4
```

Expected result:
- succeeds,
- output contains normalized video,
- audio included if present,
- subtitle/data streams are omitted.

### 9. Already-MP4 input

**Purpose:** verify that MP4 input can still be normalized.

Example command:

```sh
./all2mp4.sh input.mp4 normalized.mp4
```

Expected result:
- succeeds,
- output is recreated cleanly,
- no conflict with temporary filename behavior.

## Failure Case Matrix

### 10. Missing input argument

Command:

```sh
./all2mp4.sh
```

Expected result:
- usage shown,
- non-zero exit status.

### 11. Nonexistent input file

Command:

```sh
./all2mp4.sh does-not-exist.flv out.mp4
```

Expected result:
- clear error message,
- non-zero exit status.

### 12. Input path is not a regular file

Command:

```sh
./all2mp4.sh . out.mp4
```

Expected result:
- clear error message,
- non-zero exit status.

### 13. Output file already exists

Command:

```sh
touch out.mp4
./all2mp4.sh sample.flv out.mp4
```

Expected result:
- clear error message,
- existing output file is not overwritten,
- non-zero exit status.

### 14. ffmpeg missing from PATH

Method:
- temporarily run in an environment where `ffmpeg` is not available.

Expected result:
- clear error message,
- exit status indicates failure.

### 15. No usable H.264 encoder available

Method:
- run in an environment where `ffmpeg` exists but exposes no supported H.264 encoder.

Expected result:
- clear error message,
- non-zero exit status.

### 16. No AAC encoder available

Method:
- run in an environment where `ffmpeg` exists but has no AAC encoder.

Expected result:
- clear error message,
- non-zero exit status.

## Output Verification

Where `ffprobe` is available, inspect the output:

```sh
ffprobe -v error -show_entries format=format_name -of default=nw=1 output.mp4
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1 output.mp4
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1 output.mp4
```

Expected values:
- format includes `mp4`,
- video codec is `h264`,
- audio codec is `aac` when audio exists.

For video-only outputs, the audio probe may return nothing.

## Recommended Test Media Set

A useful starter set would include:

- one old `.flv` music or web video,
- one `.avi`,
- one `.mov`,
- one `.mkv`,
- one file with no audio,
- one file with odd dimensions,
- one file with subtitles or extra streams.

These files do not need to be large. Short samples are preferable.

## Regression Testing

After every meaningful script change, re-run at least:

1. one known-good FLV conversion,
2. one no-audio case,
3. one failure case such as nonexistent input,
4. one case where output file already exists.

This gives a fast confidence check without requiring a full test pass.

## Future Improvements

Possible future testing improvements:

- a `smoke-test.sh` helper script,
- automated fixture-based tests,
- scripted `ffprobe` assertions,
- CI coverage for argument and error behavior,
- a small set of reusable sample media files if repository size allows.

## Pass/Fail Summary Template

For manual test sessions, record results like this:

| Test Case | Input | Expected | Actual | Pass/Fail | Notes |
|---|---|---|---|---|---|
| FLV with audio | `sample.flv` | Playable MP4 with H.264/AAC |  |  |  |
| AVI input | `sample.avi` | Playable MP4 |  |  |  |
| Missing input | none | Usage + non-zero exit |  |  |  |
| Output exists | `sample.flv` -> existing `out.mp4` | Refuse overwrite |  |  |  |

## Conclusion

For this project, testing should remain simple, concrete, and media-driven.

The priority is not perfect formalism. The priority is confidence that:
- old and awkward files can be converted,
- the output is playable,
- the script fails clearly when it should,
- and behavior remains stable as the script evolves.