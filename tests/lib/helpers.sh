# tests/lib/helpers.sh — shared test harness: isolated HOME, run_writer, assert helpers
# Sourced by test_writer.sh. Do not execute directly.
# All tests use --dry-run to avoid needing real deps (micro, hugo, git).
# Tests that exercise dep-checking pass fake tool paths via .writerrc.

# ---------------------------------------------------------------------------
# Isolated HOME — prevents first-run onboarding from firing during tests
# and ensures every writer.sh invocation sees a known config.
# ---------------------------------------------------------------------------
TEST_HOME="$(mktemp -d)"
mkdir -p "${TEST_HOME}/.config/writer"
cat > "${TEST_HOME}/.config/writer/config" <<'HOMECFG'
SSG=hugo
BUILD_CMD=hugo --minify
CONTENT_DIR=content
DEFAULT_SECTION=posts
BUNDLE_FORMAT=true
FRONTMATTER_FORMAT=yaml
EDITOR=micro
GIT_COMMIT_MSG=new post: {slug}
TIMEZONE=auto
SITE_DIR=
HOMECFG
trap 'rm -rf "$TEST_HOME"' EXIT

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# run_writer <stdin_string> [writer args...]
# Runs writer.sh with the given stdin and args.
# Sets global STDOUT, STDERR, STATUS.
STDOUT=""
STDERR=""
STATUS=0

run_writer() {
    local input="$1"
    shift
    STDOUT=""
    STDERR=""
    STATUS=0
    # Use printf %b to expand \n escape sequences in the input string
    # HOME is overridden to TEST_HOME so writer.sh sees a known global config
    # and never triggers first-run onboarding.
    STDOUT=$(printf '%b' "$input" | HOME="$TEST_HOME" bash "$SCRIPT" "$@" 2>/tmp/_tw_stderr) || STATUS=$?
    STDERR=$(cat /tmp/_tw_stderr)
}

assert_exit() {
    local expected="$1" label="$2"
    if [[ "$STATUS" -eq "$expected" ]]; then
        printf "  \033[0;32m✓\033[0m %s\n" "$label"
        PASS=$(( PASS + 1 ))
    else
        printf "  \033[0;31m✗\033[0m %s  (expected exit %d, got %d)\n" "$label" "$expected" "$STATUS"
        FAIL=$(( FAIL + 1 ))
        ERRORS+=("$label: expected exit $expected, got $STATUS")
    fi
}

assert_stdout_contains() {
    local needle="$1" label="$2"
    if printf "%s" "$STDOUT" | grep -qF -- "$needle"; then
        printf "  \033[0;32m✓\033[0m %s\n" "$label"
        PASS=$(( PASS + 1 ))
    else
        printf "  \033[0;31m✗\033[0m %s\n  stdout did not contain: %s\n  stdout was: %s\n" \
            "$label" "$needle" "$STDOUT"
        FAIL=$(( FAIL + 1 ))
        ERRORS+=("$label: stdout missing '$needle'")
    fi
}

assert_stderr_contains() {
    local needle="$1" label="$2"
    if printf "%s" "$STDERR" | grep -qF -- "$needle"; then
        printf "  \033[0;32m✓\033[0m %s\n" "$label"
        PASS=$(( PASS + 1 ))
    else
        printf "  \033[0;31m✗\033[0m %s\n  stderr did not contain: %s\n  stderr was: %s\n" \
            "$label" "$needle" "$STDERR"
        FAIL=$(( FAIL + 1 ))
        ERRORS+=("$label: stderr missing '$needle'")
    fi
}

assert_stdout_not_contains() {
    local needle="$1" label="$2"
    if ! printf "%s" "$STDOUT" | grep -qF -- "$needle"; then
        printf "  \033[0;32m✓\033[0m %s\n" "$label"
        PASS=$(( PASS + 1 ))
    else
        printf "  \033[0;31m✗\033[0m %s\n  stdout unexpectedly contained: %s\n" "$label" "$needle"
        FAIL=$(( FAIL + 1 ))
        ERRORS+=("$label: stdout unexpectedly contained '$needle'")
    fi
}

section() { printf "\n\033[1;36m## %s\033[0m\n" "$1"; }
