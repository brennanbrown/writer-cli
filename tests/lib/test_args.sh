# tests/lib/test_args.sh — §2 Invocation / Argument Parsing, §6 Slug Validation
# Sourced by test_writer.sh. Do not execute directly.

# ---------------------------------------------------------------------------
# §2 — Invocation / Argument Parsing
# ---------------------------------------------------------------------------
section "§2 Invocation / Argument Parsing"

run_writer "" 2>/dev/null || true
assert_exit 1 "no args → exit 1"
assert_stderr_contains "Missing argument" "no args → 'Missing argument' in stderr"

run_writer "" --dry-run 2>/dev/null || true
assert_exit 1 "no slug with --dry-run flag only → exit 1"

run_writer "" my-post --unknown-flag --dry-run 2>/dev/null || true
assert_exit 1 "unknown double-dash flag → exit 1"
assert_stderr_contains "Unknown flag" "unknown flag → 'Unknown flag' in stderr"

run_writer "" my-post --ssg 2>/dev/null || true
assert_exit 1 "--ssg with no value → exit 1"
assert_stderr_contains "--ssg requires a value" "--ssg missing value → message in stderr"

run_writer "" my-post --section 2>/dev/null || true
assert_exit 1 "--section with no value → exit 1"
assert_stderr_contains "--section requires a value" "--section missing value → message in stderr"

run_writer $'My Post\n\n' my-post extra-arg --dry-run 2>/dev/null || true
assert_exit 1 "extra positional arg → exit 1"
assert_stderr_contains "Unexpected argument" "extra positional arg → message in stderr"

# -h / --help
STATUS=0
HOME="$TEST_HOME" bash "$SCRIPT" -h >/dev/null 2>&1 || STATUS=$?
if [[ "$STATUS" -eq 0 ]]; then
    printf "  \033[0;32m✓\033[0m -h exits 0\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m -h should exit 0, got %d\n" "$STATUS"; FAIL=$(( FAIL + 1 ))
    ERRORS+=("-h: should exit 0, got $STATUS")
fi

# ---------------------------------------------------------------------------
# §6 — Slug Validation
# ---------------------------------------------------------------------------
section "§6 Slug Validation"

run_writer "" "Bad_Slug" --dry-run 2>/dev/null || true
assert_exit 1 "uppercase/underscore slug → exit 1"
assert_stderr_contains "Invalid slug" "invalid slug → 'Invalid slug' in stderr"
assert_stderr_contains "lowercase" "invalid slug → hints at lowercase rule"

run_writer "" "-leading-hyphen" --dry-run 2>/dev/null || true
assert_exit 1 "leading hyphen slug → exit 1"
assert_stderr_contains "Invalid slug" "leading hyphen → 'Invalid slug' in stderr"

run_writer "" "trailing-hyphen-" --dry-run 2>/dev/null || true
assert_exit 1 "trailing hyphen slug → exit 1"
assert_stderr_contains "Invalid slug" "trailing hyphen → 'Invalid slug' in stderr"

run_writer "" "has spaces" --dry-run 2>/dev/null || true
assert_exit 1 "slug with spaces → exit 1"

run_writer "" "ALLCAPS" --dry-run 2>/dev/null || true
assert_exit 1 "all-caps slug → exit 1"

run_writer "" "has.dot" --dry-run 2>/dev/null || true
assert_exit 1 "slug with dot → exit 1"

run_writer "" "--double-dash-slug" --dry-run 2>/dev/null || true
assert_exit 1 "double-dash-prefixed arg (treated as unknown flag) → exit 1"

# Valid slugs
run_writer $'My Post\n\n' "valid-slug" --dry-run
assert_exit 0 "valid slug → exit 0"

run_writer $'A\n\n' "a" --dry-run
assert_exit 0 "single-char slug → exit 0"

run_writer $'Post 123\n\n' "slug-with-123" --dry-run
assert_exit 0 "slug with digits → exit 0"

run_writer $'Post\n\n' "123" --dry-run
assert_exit 0 "all-digit slug → exit 0"

run_writer $'Post\n\n' "a-b-c" --dry-run
assert_exit 0 "multi-hyphen slug → exit 0"
