# lib/defaults.sh — global defaults, flags, colours, and utility output functions
# Sourced by writer.sh. Do not execute directly.

# ---------------------------------------------------------------------------
# Defaults (overridden by config file)
# ---------------------------------------------------------------------------
SSG="hugo"
BUILD_CMD="hugo --minify"
CONTENT_DIR="content"
DEFAULT_SECTION="posts"
DEFAULT_TAGS=""
BUNDLE_FORMAT="true"
FRONTMATTER_FORMAT="yaml"
EDITOR_CMD="micro"
GIT_COMMIT_MSG="new post: {slug}"
TIMEZONE="auto"
SITE_DIR=""

# ---------------------------------------------------------------------------
# Flags (set by CLI arguments)
# ---------------------------------------------------------------------------
FLAG_DRAFT="false"
FLAG_NO_PUSH="false"
FLAG_NO_BUILD="false"
FLAG_TOML="false"
FLAG_DRY_RUN="false"
FLAG_SETUP="false"
OVERRIDE_SECTION=""
OVERRIDE_SSG=""
SLUG=""

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

err()  { printf "${RED}✗ %s${RESET}\n" "$*" >&2; }
info() { printf "${CYAN}→ %s${RESET}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${RESET}\n" "$*"; }
