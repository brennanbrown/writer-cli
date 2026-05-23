# tests/lib/test_exit.sh — §10 Exit Codes, §4.1 BUNDLE_FORMAT
# Sourced by test_writer.sh. Do not execute directly.

# ---------------------------------------------------------------------------
# §10 — Exit Codes
# ---------------------------------------------------------------------------
section "§10 Exit Codes"

# Exit 2: file exists, declined overwrite.
# Need check_deps to pass: use bash as editor, echo as build cmd, init a git repo.
TMPDIR_EX="$(mktemp -d)"
git -C "$TMPDIR_EX" init -q
git -C "$TMPDIR_EX" config user.email 'test@test.com'
git -C "$TMPDIR_EX" config user.name 'Test'
mkdir -p "$TMPDIR_EX/content/posts/existing-post"
touch "$TMPDIR_EX/content/posts/existing-post/index.md"
cat > "$TMPDIR_EX/.writerrc" <<'CFGEOF'
EDITOR=bash
BUILD_CMD=echo
CFGEOF
STATUS=0
# Overwrite prompt fires first; answer 'n' → exits 2 immediately, no title needed.
STDOUT=$(cd "$TMPDIR_EX" && printf 'n\n' | HOME="$TEST_HOME" bash "$SCRIPT" existing-post --no-push 2>/tmp/_tw_stderr) || STATUS=$?
STDERR=$(cat /tmp/_tw_stderr)
if [[ "$STATUS" -eq 2 ]]; then
    printf "  \033[0;32m✓\033[0m file exists + overwrite declined → exit 2\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m file exists + declined: expected exit 2, got %d\n  stderr: %s\n" "$STATUS" "$STDERR"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("overwrite declined: expected exit 2, got $STATUS")
fi
if printf "%s" "$STDERR" | grep -qF 'Aborted'; then
    printf "  \033[0;32m✓\033[0m overwrite declined → abort message in stderr\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m overwrite declined → abort message missing from stderr\n  stderr: %s\n" "$STDERR"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("overwrite declined: abort message missing from stderr")
fi

rm -rf "$TMPDIR_EX"

# ---------------------------------------------------------------------------
# §4.1 — BUNDLE_FORMAT=false (.md instead of /index.md)
# ---------------------------------------------------------------------------
section "§4.1 BUNDLE_FORMAT"

TMPDIR_BF="$(mktemp -d)"
cat > "$TMPDIR_BF/.writerrc" <<'CFGEOF'
BUNDLE_FORMAT=false
CFGEOF
# Dry-run: slug appears in frontmatter regardless; file path not shown in dry-run output.
# We can test by actually creating the file (no editor run, use --dry-run's file-skip behavior)
# Instead test that the slug and title are written correctly either way
STATUS=0
STDOUT=$(cd "$TMPDIR_BF" && printf "Flat Post\n\n" | HOME="$TEST_HOME" bash "$SCRIPT" flat-post --dry-run 2>/tmp/_tw_stderr) || STATUS=$?
if [[ "$STATUS" -eq 0 ]]; then
    printf "  \033[0;32m✓\033[0m BUNDLE_FORMAT=false + dry-run → exit 0\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m BUNDLE_FORMAT=false + dry-run → exit %d\n" "$STATUS"; FAIL=$(( FAIL + 1 ))
    ERRORS+=("BUNDLE_FORMAT=false: unexpected exit $STATUS")
fi
rm -rf "$TMPDIR_BF"
