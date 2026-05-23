# tests/lib/test_deps.sh — §11 Dependency pre-flight checks
# Sourced by test_writer.sh. Do not execute directly.

# ---------------------------------------------------------------------------
# §11 — Dependency Pre-flight
# ---------------------------------------------------------------------------
section "§11 Dependency Pre-flight"

# Missing editor
TMPDIR_DEPS="$(mktemp -d)"
cat > "$TMPDIR_DEPS/.writerrc" <<'CFGEOF'
EDITOR=nonexistent-editor-abc123
CFGEOF
STATUS=0
STDOUT=$(cd "$TMPDIR_DEPS" && printf "Post\n\n" | HOME="$TEST_HOME" bash "$SCRIPT" dep-post 2>/tmp/_tw_stderr) || STATUS=$?
STDERR=$(cat /tmp/_tw_stderr)
if [[ "$STATUS" -eq 1 ]]; then
    printf "  \033[0;32m✓\033[0m missing editor → exit 1\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m missing editor: expected exit 1, got %d\n" "$STATUS"; FAIL=$(( FAIL + 1 ))
    ERRORS+=("missing editor: expected exit 1, got $STATUS")
fi
if printf "%s" "$STDERR" | grep -qF "not found"; then
    printf "  \033[0;32m✓\033[0m missing editor → 'not found' in stderr\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m missing editor → 'not found' missing from stderr\n  stderr: %s\n" "$STDERR"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("missing editor: 'not found' missing from stderr")
fi

# Missing build command (using a real editor to pass that check, fake build)
cat > "$TMPDIR_DEPS/.writerrc" <<'CFGEOF'
EDITOR=bash
BUILD_CMD=nonexistent-ssg-abc123 --build
CFGEOF
STATUS=0
STDOUT=$(cd "$TMPDIR_DEPS" && printf "Post\n\n" | HOME="$TEST_HOME" bash "$SCRIPT" dep-post 2>/tmp/_tw_stderr) || STATUS=$?
STDERR=$(cat /tmp/_tw_stderr)
if [[ "$STATUS" -eq 1 ]]; then
    printf "  \033[0;32m✓\033[0m missing build binary → exit 1\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m missing build binary: expected exit 1, got %d\n" "$STATUS"; FAIL=$(( FAIL + 1 ))
    ERRORS+=("missing build binary: expected exit 1, got $STATUS")
fi
if printf "%s" "$STDERR" | grep -qF "Build command not found"; then
    printf "  \033[0;32m✓\033[0m missing build binary → 'Build command not found' in stderr\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m missing build binary → message missing from stderr\n  stderr: %s\n" "$STDERR"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("missing build binary: message missing from stderr")
fi

# --no-build skips build binary check
cat > "$TMPDIR_DEPS/.writerrc" <<'CFGEOF'
EDITOR=bash
BUILD_CMD=nonexistent-ssg-abc123 --build
CFGEOF
STATUS=0
STDOUT=$(cd "$TMPDIR_DEPS" && printf "Post\n\n" | HOME="$TEST_HOME" bash "$SCRIPT" dep-post --no-build --no-push --dry-run 2>/tmp/_tw_stderr) || STATUS=$?
if [[ "$STATUS" -eq 0 ]]; then
    printf "  \033[0;32m✓\033[0m --dry-run skips all dep checks → exit 0\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m --dry-run should skip dep checks, got exit %d\n" "$STATUS"; FAIL=$(( FAIL + 1 ))
    ERRORS+=("--dry-run dep skip: expected exit 0, got $STATUS")
fi

rm -rf "$TMPDIR_DEPS"
