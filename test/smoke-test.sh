#!/usr/bin/env bash
set -eu

progname="${0##*/}"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target_script="$script_dir/all2mp4.sh"

pass_count=0
fail_count=0

say() {
    printf '%s\n' "$*"
}

pass() {
    pass_count=$((pass_count + 1))
    printf 'PASS: %s\n' "$*"
}

fail() {
    fail_count=$((fail_count + 1))
    printf 'FAIL: %s\n' "$*"
}

run_expect_success() {
    test_name=$1
    shift

    if "$@" >/dev/null 2>&1; then
        pass "$test_name"
    else
        fail "$test_name"
    fi
}

run_expect_failure() {
    test_name=$1
    shift

    if "$@" >/dev/null 2>&1; then
        fail "$test_name"
    else
        pass "$test_name"
    fi
}

make_temp_dir() {
    if command -v mktemp >/dev/null 2>&1; then
        mktemp -d
        return
    fi

    temp_dir="${TMPDIR:-/tmp}/all2mp4-smoke-$$"
    mkdir -p "$temp_dir"
    printf '%s\n' "$temp_dir"
}

cleanup() {
    if [ -n "${tmp_dir:-}" ] && [ -d "${tmp_dir:-}" ]; then
        rm -rf "$tmp_dir"
    fi
}

if [ ! -f "$target_script" ]; then
    printf 'FAIL: target script not found: %s\n' "$target_script" >&2
    exit 1
fi

tmp_dir=$(make_temp_dir)
trap cleanup EXIT INT TERM HUP

say "Running smoke tests against: $target_script"
say

run_expect_failure "no arguments should fail" \
    "$target_script"

run_expect_failure "nonexistent input should fail" \
    "$target_script" "$tmp_dir/does-not-exist.flv"

mkdir "$tmp_dir/input-dir"
run_expect_failure "directory input should fail" \
    "$target_script" "$tmp_dir/input-dir"

touch "$tmp_dir/unreadable.flv"
chmod 000 "$tmp_dir/unreadable.flv"
run_expect_failure "unreadable input should fail" \
    "$target_script" "$tmp_dir/unreadable.flv"
chmod 600 "$tmp_dir/unreadable.flv"

touch "$tmp_dir/sample.flv"
run_expect_failure "same input and output path should fail" \
    "$target_script" "$tmp_dir/sample.flv" "$tmp_dir/sample.flv"

touch "$tmp_dir/existing.mp4"
run_expect_failure "existing output should fail" \
    "$target_script" "$tmp_dir/sample.flv" "$tmp_dir/existing.mp4"

say
say "Summary:"
say "  Passed: $pass_count"
say "  Failed: $fail_count"

if [ "$fail_count" -ne 0 ]; then
    exit 1
fi