# tests/lib/test_setup.sh — --setup / Onboarding wizard
# Sourced by test_writer.sh. Do not execute directly.

# ---------------------------------------------------------------------------
# --setup / Onboarding wizard
# ---------------------------------------------------------------------------
section "--setup / Onboarding"

# --setup alone (no slug) must exit 0
TMPDIR_SETUP="$(mktemp -d)"
STATUS=0
# Feed answers for all prompts: accept every default by pressing Enter 10 times
STDOUT=$(printf '\n\n\n\n\n\n\n\n\n\n' | HOME="$TMPDIR_SETUP" bash "$SCRIPT" --setup 2>/tmp/_tw_stderr) || STATUS=$?
STDERR=$(cat /tmp/_tw_stderr)
if [[ "$STATUS" -eq 0 ]]; then
    printf "  \033[0;32m✓\033[0m --setup exits 0\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m --setup: expected exit 0, got %d\n  stderr: %s\n" "$STATUS" "$STDERR"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("--setup: expected exit 0, got $STATUS")
fi

# Config file must be written to HOME/.config/writer/config
if [[ -f "$TMPDIR_SETUP/.config/writer/config" ]]; then
    printf "  \033[0;32m✓\033[0m --setup writes config file\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m --setup did not write config file\n"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("--setup: config file not written")
fi

# Config must contain all known keys
for key in SSG BUILD_CMD CONTENT_DIR DEFAULT_SECTION BUNDLE_FORMAT FRONTMATTER_FORMAT EDITOR GIT_COMMIT_MSG TIMEZONE SITE_DIR; do
    if grep -qF "$key=" "$TMPDIR_SETUP/.config/writer/config" 2>/dev/null; then
        printf "  \033[0;32m✓\033[0m config contains %s\n" "$key"; PASS=$(( PASS + 1 ))
    else
        printf "  \033[0;31m✗\033[0m config missing key: %s\n" "$key"; FAIL=$(( FAIL + 1 ))
        ERRORS+=("--setup: config missing key $key")
    fi
done

# Saved config must be parseable by writer itself (no unknown keys)
STATUS=0
STDOUT=$(printf "Test Post\n\n" | HOME="$TMPDIR_SETUP" bash "$SCRIPT" test-post --dry-run 2>/tmp/_tw_stderr) || STATUS=$?
if [[ "$STATUS" -eq 0 ]]; then
    printf "  \033[0;32m✓\033[0m saved config is valid (writer exits 0 after setup)\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m saved config caused exit %d\n  stderr: %s\n" "$STATUS" "$(cat /tmp/_tw_stderr)"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("--setup: saved config rejected by writer")
fi

# First-run auto-trigger: no config → onboarding fires, exits 0 after wizard
TMPDIR_FRESH="$(mktemp -d)"
STATUS=0
STDOUT=$(printf '\n\n\n\n\n\n\n\n\n\n' | HOME="$TMPDIR_FRESH" bash "$SCRIPT" my-post 2>/tmp/_tw_stderr) || STATUS=$?
if [[ "$STATUS" -eq 0 ]]; then
    printf "  \033[0;32m✓\033[0m first-run (no config): onboarding fires and exits 0\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m first-run: expected exit 0, got %d\n  stderr: %s\n" "$STATUS" "$(cat /tmp/_tw_stderr)"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("first-run: expected exit 0, got $STATUS")
fi
if [[ -f "$TMPDIR_FRESH/.config/writer/config" ]]; then
    printf "  \033[0;32m✓\033[0m first-run: config file created\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m first-run: config file not created\n"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("first-run: config file not created")
fi

# --setup with a slug argument: slug is ignored, wizard still runs
STATUS=0
STDOUT=$(printf '\n\n\n\n\n\n\n\n\n\n' | HOME="$TMPDIR_SETUP" bash "$SCRIPT" my-post --setup 2>/tmp/_tw_stderr) || STATUS=$?
if [[ "$STATUS" -eq 0 ]]; then
    printf "  \033[0;32m✓\033[0m --setup with extra slug arg → exits 0\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m --setup with slug: expected exit 0, got %d\n" "$STATUS"; FAIL=$(( FAIL + 1 ))
    ERRORS+=("--setup with slug: expected exit 0, got $STATUS")
fi

rm -rf "$TMPDIR_SETUP" "$TMPDIR_FRESH"
