#!/usr/bin/env bash
set -eu

progname="${0##*/}"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
target_script="$repo_root/norm-vid"

pass_count=0
fail_count=0
say() { printf '%s\n' "$*"; }
pass() { pass_count=$((pass_count + 1)); printf 'PASS: %s\n' "$*"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL: %s\n' "$*"; }
run_expect_failure() { test_name=$1; shift; if "$@" >/dev/null 2>&1; then fail "$test_name"; else pass "$test_name"; fi; }
run_expect_failure_message() {
    test_name=$1; expected=$2; shift 2
    if output=$("$@" 2>&1); then fail "$test_name"; return; fi
    case "$output" in *"$expected"*) pass "$test_name" ;; *) fail "$test_name" ;; esac
}
make_temp_dir() { if command -v mktemp >/dev/null 2>&1; then mktemp -d; else temp_dir="${TMPDIR:-/tmp}/norm-vid-smoke-$$"; mkdir -p "$temp_dir"; printf '%s\n' "$temp_dir"; fi; }
cleanup() { if [ -n "${tmp_dir:-}" ] && [ -d "${tmp_dir:-}" ]; then rm -rf "$tmp_dir"; fi; }

if [ ! -f "$target_script" ]; then printf 'FAIL: target script not found: %s\n' "$target_script" >&2; exit 1; fi
tmp_dir=$(make_temp_dir)
trap cleanup EXIT INT TERM HUP
say "Running smoke tests against: $target_script"
say

run_expect_failure "no arguments should fail" "$target_script"
run_expect_failure_message "--fps and --cfr together should fail" "--fps and --cfr cannot be used together" "$target_script" --fps 30 --cfr "$tmp_dir/missing.flv"
run_expect_failure_message "invalid start timestamp should fail" "start must be in [[h:]m:]s[.ms] form" "$target_script" --start 0:61:00 "$tmp_dir/missing.flv"
run_expect_failure_message "invalid end timestamp should fail" "end must be in [[h:]m:]s[.ms] form" "$target_script" --end 1:61 "$tmp_dir/missing.flv"
run_expect_failure_message "clip end must be later than start" "--end must be later than --start" "$target_script" --start 60 --end 59.999 "$tmp_dir/missing.flv"
run_expect_failure_message "zero end time should fail" "--end must be later than the start of the input" "$target_script" --end 0 "$tmp_dir/missing.flv"
run_expect_failure_message "removed trim-seconds option should fail" "unknown option: --trim-seconds" "$target_script" --trim-seconds 0.04 "$tmp_dir/missing.flv"

run_expect_failure_message "invalid frame timestamp should fail" "frame must be in [[h:]m:]s[.ms] form" "$target_script" --frame 1:61 "$tmp_dir/missing.flv"
run_expect_failure_message "jpeg quality requires frame mode" "--jpeg-quality requires --frame or --frames" "$target_script" --jpeg-quality 90 "$tmp_dir/missing.flv"
run_expect_failure_message "jpeg quality zero should fail" "jpeg-quality must be an integer from 1 to 100" "$target_script" --frame 10 --jpeg-quality 0 "$tmp_dir/missing.flv"
run_expect_failure_message "single and multi frame modes conflict" "--frame and --frames cannot be used together" "$target_script" --frame 10 --frames 20 --interval 5 --count 2 "$tmp_dir/missing.flv"
run_expect_failure_message "interval without frames should fail" "--interval requires --frames" "$target_script" --interval 5 "$tmp_dir/missing.flv"
run_expect_failure_message "count without frames should fail" "--count requires --frames" "$target_script" --count 3 "$tmp_dir/missing.flv"
run_expect_failure_message "frames requires interval" "--frames requires --interval" "$target_script" --frames 10 --count 3 "$tmp_dir/missing.flv"
run_expect_failure_message "frames requires count" "--frames requires --count" "$target_script" --frames 10 --interval 5 "$tmp_dir/missing.flv"
run_expect_failure_message "zero interval should fail" "interval must be greater than zero" "$target_script" --frames 10 --interval 0 --count 3 "$tmp_dir/missing.flv"
run_expect_failure_message "noninteger count should fail" "count must be a positive integer" "$target_script" --frames 10 --interval 5 --count 2.5 "$tmp_dir/missing.flv"
run_expect_failure_message "zero count should fail" "count must be a positive integer" "$target_script" --frames 10 --interval 5 --count 0 "$tmp_dir/missing.flv"
run_expect_failure_message "multi frame and clip should conflict" "frame capture cannot be used with --start or --end" "$target_script" --frames 10 --interval 5 --count 3 --start 1 "$tmp_dir/missing.flv"
run_expect_failure_message "multi frame and fps should conflict" "frame capture cannot be used with --fps or --cfr" "$target_script" --frames 10 --interval 5 --count 3 --fps 30 "$tmp_dir/missing.flv"
run_expect_failure_message "multi frame and metadata should conflict" "frame capture cannot be used with metadata options" "$target_script" --frames 10 --interval 5 --count 3 --title Test "$tmp_dir/missing.flv"

run_expect_failure "single frame with default quality should pass validation" "$target_script" --frame 10 "$tmp_dir/missing.flv"
run_expect_failure "multi frame should pass validation" "$target_script" --frames 10 --interval 5 --count 4 "$tmp_dir/missing.flv"
run_expect_failure "multi frame accepts time interval syntax" "$target_script" --frames 1:00 --interval 0:10.500 --count 3 "$tmp_dir/missing.flv"
run_expect_failure "multi frame accepts jpeg quality" "$target_script" --frames 10 --interval 5 --count 4 --jpeg-quality 95 "$tmp_dir/missing.flv"

run_expect_failure "nonexistent input should fail" "$target_script" "$tmp_dir/missing.flv"
mkdir "$tmp_dir/input-dir"
run_expect_failure "directory input should fail" "$target_script" "$tmp_dir/input-dir"
touch "$tmp_dir/unreadable.flv"; chmod 000 "$tmp_dir/unreadable.flv"
run_expect_failure "unreadable input should fail" "$target_script" "$tmp_dir/unreadable.flv"
chmod 600 "$tmp_dir/unreadable.flv"
touch "$tmp_dir/sample.flv"
run_expect_failure "same input and output path should fail" "$target_script" "$tmp_dir/sample.flv" "$tmp_dir/sample.flv"
touch "$tmp_dir/existing.mp4"
run_expect_failure "existing output should fail" "$target_script" "$tmp_dir/sample.flv" "$tmp_dir/existing.mp4"

say
say "Summary:"
say "  Passed: $pass_count"
say "  Failed: $fail_count"
if [ "$fail_count" -ne 0 ]; then exit 1; fi
