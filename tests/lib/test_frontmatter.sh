# tests/lib/test_frontmatter.sh — §3.1 Title, §3.2/§4.2 YAML/TOML content,
#   §2 --draft/--section/--toml flags, §3.1 tags edge cases, §3.2 date, §5 cursor line
# Sourced by test_writer.sh. Do not execute directly.

# ---------------------------------------------------------------------------
# §3.1 — Title Prompt
# ---------------------------------------------------------------------------
section "§3.1 Title Prompt"

run_writer $'\n\n' empty-title-test --dry-run 2>/dev/null || true
assert_exit 1 "empty title (two tries) → exit 1"
assert_stderr_contains "Title cannot be empty" "empty title → message in stderr"

# Re-prompt: first blank, second filled
run_writer $'\nMy Real Title\n\n' retry-title --dry-run
assert_exit 0 "blank title then valid title → exit 0"
assert_stdout_contains "My Real Title" "retry title → correct title in frontmatter"

# ---------------------------------------------------------------------------
# §3.2 / §4.2 — Frontmatter Content (YAML)
# ---------------------------------------------------------------------------
section "§3.2 / §4.2 Frontmatter (YAML)"

run_writer $'On the Meaning of Home\nplace, memory\n' on-the-meaning-of-home --dry-run
assert_exit 0 "full YAML frontmatter → exit 0"
assert_stdout_contains 'title: "On the Meaning of Home"'     "YAML title field"
assert_stdout_contains 'slug: "on-the-meaning-of-home"'      "YAML slug field"
assert_stdout_contains 'date:'                               "YAML date field present"
assert_stdout_contains 'tags:'                               "YAML tags block header"
assert_stdout_contains '  - place'                           "YAML tag: place"
assert_stdout_contains '  - memory'                          "YAML tag: memory"
assert_stdout_contains 'draft: false'                        "YAML draft: false by default"
assert_stdout_not_contains 'description:'                    "YAML description absent when not provided"

run_writer $'My Post\n\n' no-tags --dry-run
assert_stdout_not_contains 'tags:'                           "YAML no tags field when none given"

# ---------------------------------------------------------------------------
# §4.2 — Frontmatter Content (TOML)
# ---------------------------------------------------------------------------
section "§4.2 Frontmatter (TOML)"

run_writer $'On the Meaning of Home\nplace, memory\n' on-the-meaning-of-home --dry-run --toml
assert_exit 0 "full TOML frontmatter → exit 0"
assert_stdout_contains 'title = "On the Meaning of Home"'    "TOML title field"
assert_stdout_contains 'slug = "on-the-meaning-of-home"'     "TOML slug field"
assert_stdout_contains 'date ='                              "TOML date field present"
assert_stdout_contains 'tags = ["place", "memory"]'          "TOML tags array"
assert_stdout_contains 'draft = false'                       "TOML draft: false"
assert_stdout_not_contains 'description ='                   "TOML description absent when not provided"

run_writer $'My Post\n\n' no-tags-toml --dry-run --toml
assert_stdout_not_contains 'tags ='                          "TOML no tags field when none given"

# ---------------------------------------------------------------------------
# §2 / §4.2 — --draft flag
# ---------------------------------------------------------------------------
section "§2 --draft flag"

run_writer $'Draft Post\n\n' draft-post --dry-run --draft
assert_exit 0 "--draft flag → exit 0"
assert_stdout_contains 'draft: true'                         "YAML draft: true with --draft"

run_writer $'Draft Post\n\n' draft-post-toml --dry-run --draft --toml
assert_stdout_contains 'draft = true'                        "TOML draft = true with --draft"

# ---------------------------------------------------------------------------
# §3.1 — Tags Edge Cases
# ---------------------------------------------------------------------------
section "§3.1 Tags Edge Cases"

run_writer $'My Post\nfoo,,bar, , baz\n' tag-edges --dry-run
assert_stdout_contains '  - foo'   "double comma: foo included"
assert_stdout_contains '  - bar'   "double comma: bar included"
assert_stdout_contains '  - baz'   "double comma: baz included"
# Verify no blank tag entries — count lines starting with '  - '
tag_count=$(printf "%s" "$STDOUT" | grep -c '^  - ' 2>/dev/null || echo 0)
if [[ "$tag_count" -eq 3 ]]; then
    printf "  \033[0;32m✓\033[0m tags list has exactly 3 entries (no blank entries)\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m expected 3 tag entries, got %d\n" "$tag_count"; FAIL=$(( FAIL + 1 ))
    ERRORS+=("tag count: expected 3, got $tag_count")
fi

# Whitespace-only tag is not written
run_writer $'My Post\nfoo, , bar\n' tag-whitespace --dry-run
assert_stdout_contains '  - foo'   "whitespace-only tag skipped, foo present"
assert_stdout_contains '  - bar'   "whitespace-only tag skipped, bar present"

# Single tag
run_writer $'My Post\nonlyone\n' single-tag --dry-run
assert_stdout_contains '  - onlyone' "single tag written"

# Tags with surrounding whitespace
run_writer $'My Post\n  padded  ,  tag  \n' padded-tags --dry-run
assert_stdout_contains '  - padded' "leading/trailing whitespace trimmed from tag"
assert_stdout_contains '  - tag'    "second padded tag trimmed"

# ---------------------------------------------------------------------------
# §2 — --section override
# ---------------------------------------------------------------------------
section "§2 --section override"

run_writer $'My Post\n\n' my-note --dry-run --section notes
assert_exit 0 "--section notes → exit 0"
assert_stdout_contains 'slug: "my-note"' "--section: slug still correct"

# ---------------------------------------------------------------------------
# §2 — --toml via config vs flag
# ---------------------------------------------------------------------------
section "§2 --toml flag"

run_writer $'Post\n\n' toml-slug --dry-run --toml
assert_stdout_contains '+++'   "--toml: TOML delimiter present"
# The dry-run header contains '---' so we check the frontmatter block specifically
if printf "%s" "$STDOUT" | grep -v -F -e '--- Dry run' | grep -qF -- '---'; then
    printf "  \033[0;31m✗\033[0m --toml: YAML delimiter present in frontmatter (should be absent)\n"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("--toml: YAML delimiter found in frontmatter")
else
    printf "  \033[0;32m✓\033[0m --toml: YAML delimiter absent from frontmatter\n"; PASS=$(( PASS + 1 ))
fi

run_writer $'Post\n\n' yaml-slug --dry-run
assert_stdout_contains '---'   "default YAML: YAML delimiter present"
assert_stdout_not_contains '+++' "default YAML: TOML delimiter absent"

# ---------------------------------------------------------------------------
# §3.2 — Date Format (ISO 8601 with timezone offset)
# ---------------------------------------------------------------------------
section "§3.2 Date Format"

run_writer $'Date Post\n\n' date-post --dry-run
# Should match pattern like 2026-05-23T14:32:00-06:00
if printf "%s" "$STDOUT" | grep -qE 'date: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}'; then
    printf "  \033[0;32m✓\033[0m date is ISO 8601 with timezone offset\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m date is not ISO 8601 with timezone offset\n  stdout: %s\n" "$STDOUT"
    FAIL=$(( FAIL + 1 ))
    ERRORS+=("date format: not ISO 8601 with timezone offset")
fi

# ---------------------------------------------------------------------------
# §5 — Cursor Line Calculation (via frontmatter line count in dry-run output)
# ---------------------------------------------------------------------------
section "§5 Cursor Line Calculation"

# No tags, no description: 2 delimiters + 4 fields = 6 frontmatter lines; cursor = 7
run_writer $'No Tags Post\n\n' cursor-test --dry-run
assert_exit 0 "cursor: no-tags dry-run exits 0"
# Count lines between the two '---' delimiters (inclusive)
fm_block=$(printf "%s" "$STDOUT" | sed -n '/^---$/,/^---$/p')
fm_block_lines=$(printf "%s" "$fm_block" | grep -c '^' 2>/dev/null || echo 0)
if [[ "$fm_block_lines" -eq 6 ]]; then
    printf "  \033[0;32m✓\033[0m no-tags frontmatter is 6 lines (cursor lands on line 7)\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m expected 6 frontmatter lines, got %d\n" "$fm_block_lines"; FAIL=$(( FAIL + 1 ))
    ERRORS+=("cursor no-tags: expected 6 fm lines, got $fm_block_lines")
fi

# With 2 YAML tags: 2 delimiters + 4 fields + 1 (tags:) + 2 items = 9 lines; cursor = 10
run_writer $'Tag Count Post\nalpha, beta\n' cursor-tags --dry-run
assert_exit 0 "cursor: with-tags dry-run exits 0"
fm_block_tags=$(printf "%s" "$STDOUT" | sed -n '/^---$/,/^---$/p')
fm_block_tag_lines=$(printf "%s" "$fm_block_tags" | grep -c '^' 2>/dev/null || echo 0)
if [[ "$fm_block_tag_lines" -eq 9 ]]; then
    printf "  \033[0;32m✓\033[0m 2-tag frontmatter is 9 lines (cursor lands on line 10)\n"; PASS=$(( PASS + 1 ))
else
    printf "  \033[0;31m✗\033[0m expected 9 frontmatter lines, got %d\n" "$fm_block_tag_lines"; FAIL=$(( FAIL + 1 ))
    ERRORS+=("cursor with-tags: expected 9 fm lines, got $fm_block_tag_lines")
fi
