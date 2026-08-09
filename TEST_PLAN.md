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
- accepts clip timestamps as either `m:s[.ms]` or `h:m:s[.ms]`,
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

Because encoder availability differs by environment, tests focus on successful operation, playable output, and expected output format rather than identical binary output.

## Test Approach

Testing should combine:

1. **Manual real-file testing** using representative media.
2. **Command-line behavior testing** for parsing and errors.
3. **Output inspection** with `ffprobe` for codecs, duration, and clip timing.

## Core Success Criteria

A test is considered successful when:

- the script exits with status `0`,
- the output file is created,
- the output file is an `.mp4`,
- the output is playable,
- the output video codec is H.264,
- the output audio codec is AAC when audio exists.

## Clip Timestamp Formats

Both of these forms are valid:

```text
m:s[.ms]
h:m:s[.ms]
```

Examples:

```text
1:12.500
0:01:12.500
59:30
1:00:00
```

If hours are omitted, they default to zero. In the two-field form, minutes may exceed 59. In the three-field form, minutes must be between 0 and 59. Seconds must always be between 0 and 59.

## Manual Clip Tests

### Start and end, abbreviated form

```sh
./norm-vid --start 0:10.250 --end 0:20.750 input.mp4 clip.mp4
```

Expected:
- begins at approximately 10.250 seconds,
- ends at approximately 20.750 seconds,
- duration approximately 10.500 seconds.

### Start only

```sh
./norm-vid --start 1:12.500 input.mp4 clip.mp4
```

Expected: starts at 1 minute 12.500 seconds and continues to EOF.

### End only

```sh
./norm-vid --end 2:05 input.mp4 clip.mp4
```

Expected: starts at the beginning and ends at 2 minutes 5 seconds.

### Explicit hours

```sh
./norm-vid --start 1:03:04.250 --end 1:04:10.500 input.mp4 clip.mp4
```

Expected: correct interval in a source longer than one hour.

### Mixed forms

```sh
./norm-vid --start 59:30 --end 1:00:00 input.mp4 clip.mp4
```

Expected: start is interpreted as 59 minutes 30 seconds and end as 1 hour exactly, producing a clip of approximately 30 seconds.

## Failure Cases

### End before start

```sh
./norm-vid --start 1:00 --end 0:59 input.mp4 out.mp4
```

Expected: clear error that `--end` must be later than `--start`.

### Invalid three-field minutes

```sh
./norm-vid --start 0:61:00 input.mp4 out.mp4
```

Expected: timestamp-format error.

### Invalid seconds

```sh
./norm-vid --end 1:61 input.mp4 out.mp4
```

Expected: timestamp-format error.

### Zero end time

```sh
./norm-vid --end 0:00 input.mp4 out.mp4
```

Expected: end must be later than the start of the input.

### Removed trim-seconds option

```sh
./norm-vid --trim-seconds 0.04 input.mp4 out.mp4
```

Expected: unknown-option error.

## Output Verification

Where `ffprobe` is available:

```sh
ffprobe -v error -show_entries format=format_name,duration -of default=nw=1 output.mp4
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1 output.mp4
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1 output.mp4
```

For clips with both boundaries, compare duration with `end - start`. For end-only clips, compare duration with `end`. For start-only clips, confirm that output continues through the source's end.

Small differences at frame or audio-sample boundaries are acceptable.

## Regression Testing

After every meaningful script change, re-run at least:

1. one known-good conversion,
2. one no-audio case,
3. start-only, end-only, and bounded clips,
4. abbreviated and full timestamp forms,
5. one invalid timestamp case,
6. one nonexistent-input case,
7. one existing-output case.

## Conclusion

The priority is confidence that the accepted timestamp forms are interpreted consistently, requested clips contain the intended portion of the source, output remains normalized and playable, and invalid input fails clearly.
