# tests/lib/test_config.sh — §9 Config file (.writerrc) parsing
# Sourced by test_writer.sh. Do not execute directly.

# ---------------------------------------------------------------------------
# §9 — Config File (.writerrc)
# ---------------------------------------------------------------------------
section "§9 Config File (.writerrc)"

TMPDIR_CFG="$(mktemp -d)"

# Valid config
cat > "$TMPDIR_CFG/.writerrc" <<'CFGEOF'
SSG=hugo
BUILD_CMD=hugo --minify
DEFAULT_SECTION=notes
BUNDLE_FORMAT=false
FRONTMATTER_FORMAT=yaml
EDITOR=micro
GIT_COMMIT_MSG=new post: {slug}
TIMEZONE=auto
CFGEOF

# Run from the tmpdir so .writerrc is picked up
STATUS=0
STDOUT=$(cd "$TMPDIR_CFG" && printf "Config Post\n\n" | HOME="$TEST_HOME" bash "$SCRIPT" config-post --dry-run 2>/tmp/_tw_stderr) || STATUS=$?
STDERR=$(cat /tmp/_tw_stderr)
if [[ "$STATUS" -eq 0 ]]; then
    printf "  \033[0;32m✓\033[0m valid .writerrc loads without error → exit 0\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m valid .writerrc → unexpected exit %d\n  stderr: %s\n" "$STATUS" "$STDERR"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("valid .writerrc: unexpected exit $STATUS")
fi

# Unknown key in config → exit 5
cat > "$TMPDIR_CFG/.writerrc" <<'CFGEOF'
UNKNOWN_KEY=value
CFGEOF
STATUS=0
STDERR=""
STDOUT=$(cd "$TMPDIR_CFG" && printf "Post\n\n" | HOME="$TEST_HOME" bash "$SCRIPT" some-post --dry-run 2>/tmp/_tw_stderr) || STATUS=$?
STDERR=$(cat /tmp/_tw_stderr)
if [[ "$STATUS" -eq 5 ]]; then
    printf "  \033[0;32m✓\033[0m unknown config key → exit 5\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m unknown config key: expected exit 5, got %d\n" "$STATUS"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("unknown config key: expected exit 5, got $STATUS")
fi
if printf "%s" "$STDERR" | grep -qF "Config parse error"; then
    printf "  \033[0;32m✓\033[0m unknown config key → 'Config parse error' in stderr\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m unknown config key → missing 'Config parse error' in stderr\n"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("unknown config key: 'Config parse error' missing from stderr")
fi

# Comments and blank lines are ignored
cat > "$TMPDIR_CFG/.writerrc" <<'CFGEOF'
# This is a comment
SSG=hugo

# Another comment
CFGEOF
STATUS=0
STDOUT=$(cd "$TMPDIR_CFG" && printf "Post\n\n" | HOME="$TEST_HOME" bash "$SCRIPT" comment-post --dry-run 2>/tmp/_tw_stderr) || STATUS=$?
if [[ "$STATUS" -eq 0 ]]; then
    printf "  \033[0;32m✓\033[0m comments and blank lines in config ignored → exit 0\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m comments/blank lines caused unexpected exit %d\n" "$STATUS"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("comments in config: unexpected exit $STATUS")
fi

# Inline comments are stripped
cat > "$TMPDIR_CFG/.writerrc" <<'CFGEOF'
SSG=hugo  # inline comment
CFGEOF
STATUS=0
STDOUT=$(cd "$TMPDIR_CFG" && printf "Post\n\n" | HOME="$TEST_HOME" bash "$SCRIPT" inline-comment-post --dry-run 2>/tmp/_tw_stderr) || STATUS=$?
if [[ "$STATUS" -eq 0 ]]; then
    printf "  \033[0;32m✓\033[0m inline config comment stripped → exit 0\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m inline config comment not stripped → exit %d\n" "$STATUS"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("inline config comment: exit $STATUS")
fi

# FRONTMATTER_FORMAT=toml in config overrides default
cat > "$TMPDIR_CFG/.writerrc" <<'CFGEOF'
FRONTMATTER_FORMAT=toml
CFGEOF
STATUS=0
STDOUT=$(cd "$TMPDIR_CFG" && printf "Post\n\n" | HOME="$TEST_HOME" bash "$SCRIPT" toml-from-config --dry-run 2>/tmp/_tw_stderr) || STATUS=$?
if printf "%s" "$STDOUT" | grep -qF '+++'; then
    printf "  \033[0;32m✓\033[0m FRONTMATTER_FORMAT=toml in config → TOML output\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m FRONTMATTER_FORMAT=toml in config did not produce TOML\n  stdout: %s\n" "$STDOUT"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("FRONTMATTER_FORMAT=toml in config: no TOML output")
fi

# CLI --toml overrides config FRONTMATTER_FORMAT=yaml
cat > "$TMPDIR_CFG/.writerrc" <<'CFGEOF'
FRONTMATTER_FORMAT=yaml
CFGEOF
STATUS=0
STDOUT=$(cd "$TMPDIR_CFG" && printf "Post\n\n" | HOME="$TEST_HOME" bash "$SCRIPT" cli-toml-override --dry-run --toml 2>/tmp/_tw_stderr) || STATUS=$?
if printf "%s" "$STDOUT" | grep -qF '+++'; then
    printf "  \033[0;32m✓\033[0m CLI --toml overrides config YAML setting\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m CLI --toml did not override config YAML setting\n"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("CLI --toml override: no TOML output despite config YAML")
fi

rm -rf "$TMPDIR_CFG"
