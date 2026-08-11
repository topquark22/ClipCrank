#!/usr/bin/env bash
set -eu

progname="${0##*/}"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
target_script="$repo_root/clipcrank"

pass_count=0
fail_count=0
say() { printf '%s\n' "$*"; }
pass() { pass_count=$((pass_count + 1)); printf 'PASS: %s\n' "$*"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL: %s\n' "$*"; }
run_expect_failure() { test_name=$1; shift; if "$@" >/dev/null 2>&1; then fail "$test_name"; else pass "$test_name"; fi; }
run_expect_failure_message() { test_name=$1; expected=$2; shift 2; if output=$("$@" 2>&1); then fail "$test_name"; return; fi; case "$output" in *"$expected"*) pass "$test_name" ;; *) fail "$test_name" ;; esac; }
make_temp_dir() { if command -v mktemp >/dev/null 2>&1; then mktemp -d; else temp_dir="${TMPDIR:-/tmp}/clipcrank-smoke-$$"; mkdir -p "$temp_dir"; printf '%s\n' "$temp_dir"; fi; }
cleanup() { if [ -n "${tmp_dir:-}" ] && [ -d "${tmp_dir:-}" ]; then rm -rf "$tmp_dir"; fi; }

if [ ! -f "$target_script" ]; then printf 'FAIL: target script not found: %s\n' "$target_script" >&2; exit 1; fi
tmp_dir=$(make_temp_dir); trap cleanup EXIT INT TERM HUP
say "Running smoke tests against: $target_script"; say

run_expect_failure "no arguments should fail" "$target_script"
run_expect_failure_message "--fps and --cfr together should fail" "--fps and --cfr cannot be used together" "$target_script" --reencode --fps 30 --cfr "$tmp_dir/missing.flv"
run_expect_failure_message "invalid start timestamp should fail" "start must be in [[h:]m:]s[.ms] form" "$target_script" --reencode --start 0:61:00 "$tmp_dir/missing.flv"
run_expect_failure_message "clip end must be later than start" "--end must be later than --start" "$target_script" --reencode --start 60 --end 59.999 "$tmp_dir/missing.flv"
run_expect_failure_message "clip across hour boundary should pass validation" "input file not found" "$target_script" --reencode --start 59:59 --end 1:00:01 "$tmp_dir/missing.flv"
run_expect_failure_message "removed trim-seconds option should fail" "unknown option: --trim-seconds" "$target_script" --trim-seconds 0.04 "$tmp_dir/missing.flv"

run_expect_failure_message "jpeg quality requires frame mode" "--jpeg-quality requires --frame" "$target_script" --jpeg-quality 90 "$tmp_dir/missing.flv"
run_expect_failure_message "removed frames option should fail" "unknown option: --frames" "$target_script" --frames 20 --interval 5 --count 2 "$tmp_dir/missing.flv"
run_expect_failure_message "interval without frame should fail" "--interval requires --frame" "$target_script" --interval 5 "$tmp_dir/missing.flv"
run_expect_failure_message "frame count requires interval" "--count requires --interval" "$target_script" --frame 10 --count 3 "$tmp_dir/missing.flv"
run_expect_failure_message "frame interval requires count" "--interval requires --count" "$target_script" --frame 10 --interval 5 "$tmp_dir/missing.flv"
run_expect_failure_message "zero interval should fail" "interval must be greater than zero" "$target_script" --frame 10 --interval 0 --count 3 "$tmp_dir/missing.flv"
run_expect_failure_message "noninteger count should fail" "count must be a positive integer" "$target_script" --frame 10 --interval 5 --count 2.5 "$tmp_dir/missing.flv"
run_expect_failure_message "multi frame and clip should conflict" "frame capture cannot be used with --start or --end" "$target_script" --frame 10 --interval 5 --count 3 --start 1 "$tmp_dir/missing.flv"
run_expect_failure_message "reencode and frame operations should conflict" "only one operation may be specified" "$target_script" --reencode --frame 10 "$tmp_dir/missing.flv"

run_expect_failure "short force flag should parse" "$target_script" --reencode -f "$tmp_dir/missing.flv"
run_expect_failure "long force flag should parse" "$target_script" --reencode --force "$tmp_dir/missing.flv"
run_expect_failure "force with single frame should parse" "$target_script" -f --frame 10 "$tmp_dir/missing.flv"
run_expect_failure "force with multiple frames should parse" "$target_script" --force --frame 10 --interval 5 --count 4 "$tmp_dir/missing.flv"

mkdir "$tmp_dir/bin"
cat > "$tmp_dir/bin/ffmpeg" <<'EOF'
#!/usr/bin/env bash
for arg in "$@"; do
    output=$arg
done
: > "$output"
EOF
chmod +x "$tmp_dir/bin/ffmpeg"
touch "$tmp_dir/hour-boundary.mp4"
if PATH="$tmp_dir/bin:$PATH" "$target_script" --frame 59:59 --interval 1 --count 3 "$tmp_dir/hour-boundary.mp4" "$tmp_dir/hour.jpg" >/dev/null 2>&1 &&
   [ -f "$tmp_dir/hour-00-59-59.jpg" ] &&
   [ -f "$tmp_dir/hour-01-00-00.jpg" ] &&
   [ -f "$tmp_dir/hour-01-00-01.jpg" ]; then
    pass "frame filenames crossing hour boundary should include hours"
else
    fail "frame filenames crossing hour boundary should include hours"
fi

cat > "$tmp_dir/bin/ffprobe" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '[FORMAT]' 'TAG:title=Example Title' '[/FORMAT]'
EOF
chmod +x "$tmp_dir/bin/ffprobe"
touch "$tmp_dir/metadata.mp4"
if output=$(PATH="$tmp_dir/bin:$PATH" "$target_script" --show-metadata "$tmp_dir/metadata.mp4" 2>&1) &&
   case "$output" in *"TAG:title=Example Title"*) true ;; *) false ;; esac; then
    pass "show metadata should display ffprobe metadata"
else
    fail "show metadata should display ffprobe metadata"
fi
run_expect_failure_message "show metadata should reject output file" "--show-metadata does not accept an output file" "$target_script" --show-metadata "$tmp_dir/metadata.mp4" "$tmp_dir/out.mp4"
run_expect_failure_message "show metadata should reject output options" "--show-metadata cannot be combined with output options" "$target_script" --show-metadata --start 1 "$tmp_dir/metadata.mp4"

run_expect_failure_message "input without operation should show usage" "Usage:" "$target_script" "$tmp_dir/metadata.mp4"
run_expect_failure "nonexistent input should fail" "$target_script" --reencode "$tmp_dir/missing.flv"
mkdir "$tmp_dir/input-dir"; run_expect_failure "directory input should fail" "$target_script" --reencode "$tmp_dir/input-dir"
touch "$tmp_dir/unreadable.flv"; chmod 000 "$tmp_dir/unreadable.flv"; run_expect_failure "unreadable input should fail" "$target_script" --reencode "$tmp_dir/unreadable.flv"; chmod 600 "$tmp_dir/unreadable.flv"
touch "$tmp_dir/sample.flv"
run_expect_failure "same input and output path should fail without force" "$target_script" --reencode "$tmp_dir/sample.flv" "$tmp_dir/sample.flv"
run_expect_failure "same input and output path should still fail with force" "$target_script" --reencode -f "$tmp_dir/sample.flv" "$tmp_dir/sample.flv"
touch "$tmp_dir/existing.mp4"
run_expect_failure "existing output should fail without force" "$target_script" --reencode "$tmp_dir/sample.flv" "$tmp_dir/existing.mp4"

say; say "Summary:"; say "  Passed: $pass_count"; say "  Failed: $fail_count"
if [ "$fail_count" -ne 0 ]; then exit 1; fi
