# Test Plan

This document describes how to test `norm-vid`.

The project is small, so the testing approach is intentionally practical:
- verify that the script works on representative real-world files,
- verify that common failure cases are handled clearly,
- verify that output files are playable and normalized as expected.

## Goals

The test plan aims to confirm that `norm-vid`:

- accepts a variety of input containers,
- converts them into playable `.mp4` output,
- selects a working H.264 encoder from the local `ffmpeg` environment,
- uses AAC audio when audio is present,
- creates clips with the requested start and end times,
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
   - Use `ffprobe` where available to confirm output container, codecs, duration, and clip timing.

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
./norm-vid sample.flv output.mp4
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
./norm-vid silent.flv silent.mp4
```

Expected result:
- succeeds,
- produces MP4 with video only,
- no failure due to missing audio stream.

### 3. AVI input

**Purpose:** confirm support for a common legacy container.

Example command:

```sh
./norm-vid sample.avi sample.mp4
```

Expected result:
- succeeds,
- output is playable,
- output video is H.264.

### 4. MOV input

**Purpose:** confirm support for camera/editor style source files.

Example command:

```sh
./norm-vid sample.mov sample.mp4
```

Expected result:
- succeeds,
- output is playable.

### 5. MKV input

**Purpose:** confirm support for a modern but flexible container.

Example command:

```sh
./norm-vid sample.mkv sample.mp4
```

Expected result:
- succeeds,
- output is playable.

### 6. Video with odd dimensions

**Purpose:** verify that scaling to even dimensions works.

Example command:

```sh
./norm-vid odd-dimensions.mkv odd-dimensions.mp4
```

Expected result:
- succeeds,
- output dimensions are encoder-safe,
- output remains playable.

### 7. Video-only input

**Purpose:** confirm success when no audio stream exists.

Example command:

```sh
./norm-vid video-only.avi video-only.mp4
```

Expected result:
- succeeds,
- output has video only,
- no failure due to missing audio.

### 8. Input with subtitles or data streams

**Purpose:** verify that extra streams do not break conversion.

Example command:

```sh
./norm-vid extra-streams.mkv extra-streams.mp4
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
./norm-vid input.mp4 normalized.mp4
```

Expected result:
- succeeds,
- output is recreated cleanly,
- no conflict with temporary filename behavior.

### 10. Create a video clip

**Purpose:** verify that explicit start and end times produce only the requested portion of the input.

Example command:

```sh
./norm-vid --start 0:00:10.250 --end 0:00:20.750 input.mp4 clip.mp4
```

Expected result:
- succeeds,
- output begins at approximately 10.250 seconds in the original input,
- output ends at approximately 20.750 seconds in the original input,
- output duration is approximately 10.500 seconds,
- output remains normalized as H.264/AAC.

Use `ffprobe` to check the resulting duration when practical. Small differences at frame or audio-sample boundaries are acceptable.

## Failure Case Matrix

### 11. Missing input argument

Command:

```sh
./norm-vid
```

Expected result:
- usage shown,
- non-zero exit status.

### 12. Nonexistent input file

Command:

```sh
./norm-vid does-not-exist.flv out.mp4
```

Expected result:
- clear error message,
- non-zero exit status.

### 13. Input path is not a regular file

Command:

```sh
./norm-vid . out.mp4
```

Expected result:
- clear error message,
- non-zero exit status.

### 14. Output file already exists

Command:

```sh
touch out.mp4
./norm-vid sample.flv out.mp4
```

Expected result:
- clear error message,
- existing output file is not overwritten,
- non-zero exit status.

### 15. Clip start without end

Command:

```sh
./norm-vid --start 0:00:10 input.mp4 out.mp4
```

Expected result:
- clear error that `--start` requires `--end`,
- non-zero exit status.

### 16. Clip end before start

Command:

```sh
./norm-vid --start 0:00:20 --end 0:00:10 input.mp4 out.mp4
```

Expected result:
- clear error that the end must be later than the start,
- non-zero exit status.

### 17. Invalid clip timestamp

Command:

```sh
./norm-vid --start 0:61:00 --end 1:00:00 input.mp4 out.mp4
```

Expected result:
- clear timestamp-format error,
- non-zero exit status.

### 18. Clip combined with trim-seconds

Command:

```sh
./norm-vid --trim-seconds 0.04 --start 0:00:10 --end 0:00:20 input.mp4 out.mp4
```

Expected result:
- clear option-conflict error,
- non-zero exit status.

### 19. ffmpeg missing from PATH

Method:
- temporarily run in an environment where `ffmpeg` is not available.

Expected result:
- clear error message,
- exit status indicates failure.

### 20. No usable H.264 encoder available

Method:
- run in an environment where `ffmpeg` exists but exposes no supported H.264 encoder.

Expected result:
- clear error message,
- non-zero exit status.

### 21. No AAC encoder available

Method:
- run in an environment where `ffmpeg` exists but has no AAC encoder.

Expected result:
- clear error message,
- non-zero exit status.

## Output Verification

Where `ffprobe` is available, inspect the output:

```sh
ffprobe -v error -show_entries format=format_name,duration -of default=nw=1 output.mp4
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1 output.mp4
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1 output.mp4
```

Expected values:
- format includes `mp4`,
- video codec is `h264`,
- audio codec is `aac` when audio exists.

For video-only outputs, the audio probe may return nothing.

For clip outputs, compare the reported duration with `end - start`, allowing for normal frame/audio-sample boundary differences.

## Recommended Test Media Set

A useful starter set would include:

- one old `.flv` music or web video,
- one `.avi`,
- one `.mov`,
- one `.mkv`,
- one file with no audio,
- one file with odd dimensions,
- one file with subtitles or extra streams,
- one input long enough to test clipping at known visual or audio landmarks.

These files do not need to be large. Short samples are preferable.

## Regression Testing

After every meaningful script change, re-run at least:

1. one known-good FLV conversion,
2. one no-audio case,
3. one clip conversion,
4. one failure case such as nonexistent input,
5. one case where output file already exists.

This gives a fast confidence check without requiring a full test pass.

## Future Improvements

Possible future testing improvements:

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
| Video clip | `input.mp4` | Requested interval only |  |  |  |
| Missing input | none | Usage + non-zero exit |  |  |  |
| Output exists | `sample.flv` -> existing `out.mp4` | Refuse overwrite |  |  |  |

## Conclusion

For this project, testing should remain simple, concrete, and media-driven.

The priority is not perfect formalism. The priority is confidence that:
- old and awkward files can be converted,
- requested clips contain the intended portion of the source,
- the output is playable,
- the script fails clearly when it should,
- and behavior remains stable as the script evolves.
