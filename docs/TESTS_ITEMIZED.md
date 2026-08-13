# ClipCrank Itemized Smoke Tests

This document is an appendix to `TEST_PLAN.md`. It itemizes the automated cases in `test/smoke-test.sh` and groups them by the behavior they verify.

The current smoke suite contains **68 test cases**.

## Command-Line and Operation Validation

1. **No arguments should fail** — verifies that invoking ClipCrank without an operation or input exits unsuccessfully.
2. **`--fps` and `--cfr` together should fail** — verifies that mutually exclusive frame-rate controls are rejected.
3. **Invalid start timestamp should fail** — verifies rejection of an invalid `--start` timestamp such as `0:61:00`.
4. **Clip end must be later than start** — verifies that `--end` cannot precede or equal `--start`.
5. **Clip across hour boundary should pass validation** — verifies that a valid clip range crossing an hour boundary is accepted by timestamp validation and proceeds to input validation.
6. **Standalone clip should count as an operation** — verifies that `--start` or `--end` selects clip creation without requiring `--reencode`.
7. **Copy stream requires clip boundary** — verifies that `--copy-stream` is invalid unless `--start` or `--end` is supplied.
8. **Copy stream and reencode should conflict** — verifies that `--copy-stream` cannot be combined with `--reencode`.
9. **Removed `--trim-seconds` option should fail** — verifies that the obsolete option remains rejected rather than being silently accepted.
10. **Remove audio requires output file** — verifies that `--remove-audio` requires an explicit output path.
11. **Remux requires output file** — verifies that `--remux` requires an explicit output path.

## Frame-Capture Validation

12. **JPEG quality requires frame mode** — verifies that `--jpeg-quality` cannot be used without `--frame`.
13. **Removed `--frames` option should fail** — verifies that the obsolete `--frames` option remains rejected.
14. **Interval without frame should fail** — verifies that `--interval` requires `--frame`.
15. **Frame count requires interval** — verifies that `--count` requires `--interval`.
16. **Frame interval requires count** — verifies that `--interval` requires `--count`.
17. **Zero interval should fail** — verifies that frame intervals must be greater than zero.
18. **Noninteger count should fail** — verifies that `--count` must be a positive integer.
19. **Multi-frame and clip should conflict** — verifies that frame capture cannot be combined with `--start` or `--end`.
20. **Reencode and frame operations should conflict** — verifies that frame capture and `--reencode` cannot both be selected as operations.

## Force and Overwrite Option Parsing

21. **Short force flag should parse** — verifies recognition of `-f` with re-encoding.
22. **Long force flag should parse** — verifies recognition of `--force` with re-encoding.
23. **Force with single frame should parse** — verifies recognition of `-f` in single-frame mode.
24. **Force with multiple frames should parse** — verifies recognition of `--force` in multi-frame mode.

## Frame Filename Generation

25. **Frame filenames crossing hour boundary should include hours** — captures frames around the one-hour boundary and verifies chronologically sortable names such as `00-59-59`, `01-00-00`, and `01-00-01`.

## Metadata and Information Modes

26. **Show metadata should display ffprobe metadata** — verifies that `--show-metadata` displays metadata returned by `ffprobe`.
27. **Show metadata should reject output file** — verifies that inspection mode does not accept an output path.
28. **Show metadata should reject output options** — verifies that `--show-metadata` cannot be combined with output-modifying options such as `--start`.
29. **Info should reject output file** — verifies that `--info` does not accept an output path.
30. **Info should reject output options** — verifies that `--info` cannot be combined with output-modifying options.
31. **Remux should reject video options** — verifies that `--remux` cannot be combined with video transformation or metadata options such as `--fps`.

## Input and Output Safety

32. **Input without operation should show usage** — verifies that an input file alone is insufficient to select an operation.
33. **Nonexistent input should fail** — verifies rejection of a missing input file.
34. **Directory input should fail** — verifies that an input path must identify a regular file.
35. **Unreadable input should fail** — verifies rejection of an input file without read permission.
36. **Same input and output path should fail without force** — protects the source file from in-place replacement.
37. **Same input and output path should still fail with force** — verifies that `--force` does not override the prohibition on identical input and output paths.
38. **Existing output should fail without force** — verifies overwrite protection for an already existing output file.

## Real-Media Fixture and Information Verification

39. **Example video should use VP9 codec** — verifies that the committed Big Buck Bunny fixture has the expected VP9 source codec.
40. **Info should summarize video without audio** — verifies `--info` output for the VP9 fixture, including its video codec and absence of audio.

## Clip Boundary Validation

41. **Clip start beyond input duration should fail** — verifies that `--start` at or beyond the probed input duration is rejected before FFmpeg creates output.
42. **Clip end beyond input duration should fail** — verifies that `--end` beyond the probed input duration is rejected before FFmpeg creates output.
43. **Copy stream should reject non-H.264 input** — verifies that `--copy-stream` refuses a VP9 source instead of silently re-encoding it.
44. **Clip should re-encode by default** — verifies successful clip creation from the VP9 fixture without explicitly specifying `--reencode`.
45. **Default clip should use H.264 codec** — verifies with `ffprobe` that default clip creation produces H.264 video.

## Re-Encoding

46. **Example VP9 video should re-encode successfully** — verifies successful explicit conversion of the VP9 fixture to MP4.
47. **Re-encoded example video should use H.264 codec** — verifies with `ffprobe` that the re-encoded output video is H.264.

## Frame-Rate Conversion

48. **Example video should re-encode at 24 FPS** — verifies successful explicit conversion of the 30 FPS fixture to 24 FPS.
49. **24 FPS output should report 24/1 frame rate** — verifies the generated frame rate with `ffprobe` rather than relying only on successful command execution.

## Still Image plus Audio

50. **Image add-audio output should use audio filename** — verifies that still-image `--add-audio` output uses the input audio basename when the default name is exercised.
51. **Image add-audio output should use H.264 video** — verifies the generated video codec with `ffprobe`.
52. **Image add-audio output should use AAC audio** — verifies the generated audio codec with `ffprobe`.
53. **Info should summarize video with audio** — verifies that `--info` reports both H.264 video and AAC audio on the generated fixture.

## Stream-Copy Clipping

54. **H.264/AAC clip should be created with `--copy-stream`** — verifies successful explicit stream-copy clipping of compatible media.
55. **Stream-copy clip should report actual keyframe start** — verifies that ClipCrank reports the requested start and the usable source keyframe timestamp.
56. **Stream-copy clip should preserve H.264 and AAC codecs** — verifies with `ffprobe` that stream copying does not transcode either stream.

## Remuxing

57. **Remux should create output without re-encoding** — verifies successful MP4-to-Matroska remuxing.
58. **Remux output should use requested Matroska container** — verifies the target container with `ffprobe`.
59. **Remux should preserve H.264 and AAC codecs** — verifies that remuxing leaves the stream codecs unchanged.

## Audio Extraction

60. **Extract audio should create default MP3 output** — verifies successful `--extract-audio` operation and default output naming.
61. **Extracted audio should use MP3 codec** — verifies the extracted audio codec with `ffprobe`.

## Audio Removal

62. **Remove audio should create output video** — verifies successful creation of a silent video.
63. **Remove audio output should use H.264 video** — verifies the resulting video codec with `ffprobe`.
64. **Remove audio output should contain no audio stream** — verifies with `ffprobe` that the audio stream was actually removed.

## Format-Agnostic Still-Image Detection

65. **Add audio should detect still image without relying on extension** — copies the Lenna image to a nonstandard `.still` filename and verifies that media-based still-image detection continues to work.

## Adding Audio to Video

66. **Add audio to video should create output video** — verifies successful replacement/addition of audio on the video fixture.
67. **Video add-audio output should use H.264 video** — verifies the output video codec with `ffprobe`.
68. **Video add-audio output should use AAC audio** — verifies the output audio codec with `ffprobe`.

## Maintenance Note

This appendix should be updated whenever `test/smoke-test.sh` gains, removes, or materially changes a test case. The numbered list is intended to make the suite count auditable and to complement the higher-level testing strategy in `TEST_PLAN.md`.