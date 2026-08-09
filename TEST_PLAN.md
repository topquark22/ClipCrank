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
- creates clips using a start time, end time, or both,
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

```sh
./norm-vid sample.flv output.mp4
```

Expected: playable H.264/AAC MP4.

### 2. FLV without audio

```sh
./norm-vid silent.flv silent.mp4
```

Expected: playable video-only MP4.

### 3. AVI input

```sh
./norm-vid sample.avi sample.mp4
```

Expected: playable H.264 MP4.

### 4. MOV input

```sh
./norm-vid sample.mov sample.mp4
```

Expected: playable output.

### 5. MKV input

```sh
./norm-vid sample.mkv sample.mp4
```

Expected: playable output.

### 6. Video with odd dimensions

```sh
./norm-vid odd-dimensions.mkv odd-dimensions.mp4
```

Expected: encoder-safe even dimensions and playable output.

### 7. Video-only input

```sh
./norm-vid video-only.avi video-only.mp4
```

Expected: successful video-only output.

### 8. Input with subtitles or data streams

```sh
./norm-vid extra-streams.mkv extra-streams.mp4
```

Expected: normalized video/audio with subtitle and data streams omitted.

### 9. Already-MP4 input

```sh
./norm-vid input.mp4 normalized.mp4
```

Expected: cleanly regenerated MP4.

### 10. Clip with start and end

```sh
./norm-vid --start 0:00:10.250 --end 0:00:20.750 input.mp4 clip.mp4
```

Expected:
- begins at approximately 10.250 seconds in the source,
- ends at approximately 20.750 seconds,
- duration approximately 10.500 seconds.

### 11. Clip with start only

```sh
./norm-vid --start 0:00:10.250 input.mp4 clip.mp4
```

Expected:
- begins at approximately 10.250 seconds in the source,
- continues to the end of the input.

### 12. Clip with end only

```sh
./norm-vid --end 0:00:20.750 input.mp4 clip.mp4
```

Expected:
- begins at the start of the input,
- ends at approximately 20.750 seconds,
- duration approximately 20.750 seconds.

Small differences at frame or audio-sample boundaries are acceptable.

## Failure Case Matrix

### 13. Missing input argument

```sh
./norm-vid
```

Expected: usage shown and non-zero exit status.

### 14. Nonexistent input file

```sh
./norm-vid does-not-exist.flv out.mp4
```

Expected: clear error and non-zero exit status.

### 15. Input path is not a regular file

```sh
./norm-vid . out.mp4
```

Expected: clear error and non-zero exit status.

### 16. Output file already exists

```sh
touch out.mp4
./norm-vid sample.flv out.mp4
```

Expected: existing output is not overwritten.

### 17. Clip end before start

```sh
./norm-vid --start 0:00:20 --end 0:00:10 input.mp4 out.mp4
```

Expected: clear error that the end must be later than the start.

### 18. Invalid clip timestamp

```sh
./norm-vid --start 0:61:00 input.mp4 out.mp4
```

Expected: clear timestamp-format error.

### 19. Removed trim-seconds option

```sh
./norm-vid --trim-seconds 0.04 input.mp4 out.mp4
```

Expected: unknown-option error and non-zero exit status.

### 20. ffmpeg missing from PATH

Expected: clear error and failure status.

### 21. No usable H.264 encoder available

Expected: clear error and non-zero exit status.

### 22. No AAC encoder available

Expected: clear error and non-zero exit status.

## Output Verification

Where `ffprobe` is available:

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

For clips with both boundaries, compare duration with `end - start`. For end-only clips, compare duration with `end`. For start-only clips, confirm the output continues through the source's end.

## Recommended Test Media Set

Use short samples where possible, including:

- one old `.flv`,
- one `.avi`,
- one `.mov`,
- one `.mkv`,
- one file with no audio,
- one file with odd dimensions,
- one file with subtitles or extra streams,
- one input long enough to test clipping at known visual or audio landmarks.

## Regression Testing

After every meaningful script change, re-run at least:

1. one known-good conversion,
2. one no-audio case,
3. start-only, end-only, and bounded clip conversions,
4. one failure case such as nonexistent input,
5. one case where output already exists.

## Future Improvements

Possible future testing improvements:

- automated fixture-based tests,
- scripted `ffprobe` assertions,
- CI coverage for argument and error behavior,
- a small set of reusable sample media files if repository size allows.

## Conclusion

The priority is confidence that old and awkward files can be converted, requested clips contain the intended portion of the source, output is playable, and failures are clear and predictable.
