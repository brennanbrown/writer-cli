#!/usr/bin/env bash
# tests/test_writer.sh — test suite runner for writer.sh
# Run from the repo root: bash tests/test_writer.sh

set -euo pipefail

SUITE_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$SUITE_DIR/.." && pwd)/writer.sh"

PASS=0
FAIL=0
ERRORS=()

# shellcheck source=tests/lib/helpers.sh
source "${SUITE_DIR}/lib/helpers.sh"
# shellcheck source=tests/lib/test_args.sh
source "${SUITE_DIR}/lib/test_args.sh"
# shellcheck source=tests/lib/test_frontmatter.sh
source "${SUITE_DIR}/lib/test_frontmatter.sh"
# shellcheck source=tests/lib/test_config.sh
source "${SUITE_DIR}/lib/test_config.sh"
# shellcheck source=tests/lib/test_deps.sh
source "${SUITE_DIR}/lib/test_deps.sh"
# shellcheck source=tests/lib/test_exit.sh
source "${SUITE_DIR}/lib/test_exit.sh"
# shellcheck source=tests/lib/test_setup.sh
source "${SUITE_DIR}/lib/test_setup.sh"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf "\n\033[1m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n"
printf "\033[1mResults: \033[0;32m%d passed\033[0m, \033[0;31m%d failed\033[0m\n" "$PASS" "$FAIL"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
    printf "\n\033[1;31mFailed tests:\033[0m\n"
    for e in "${ERRORS[@]}"; do
        printf "  • %s\n" "$e"
    done
fi

printf "\n"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
