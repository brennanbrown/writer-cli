#!/usr/bin/env bash
# INSTALL.sh — writer installer
#
# What this does:
#   1. Checks that git is available
#   2. Clones writer-cli into ~/.local/share/writer-cli (or pulls if already cloned)
#   3. Creates ~/.local/bin/ if it does not exist
#   4. Puts a 'writer' symlink in ~/.local/bin/
#   5. Adds ~/.local/bin to PATH in your shell profile if it isn't there already
#   6. Runs 'writer --setup' so you can configure it right away
#
# Nothing is installed system-wide. Everything goes in your home directory.
# To uninstall: rm -rf ~/.local/share/writer-cli ~/.local/bin/writer

set -euo pipefail

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

say()  { printf "${CYAN}→ %s${RESET}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${RESET}\n" "$*"; }
warn() { printf "${YELLOW}! %s${RESET}\n" "$*"; }
die()  { printf "${RED}✗ %s${RESET}\n" "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Destination paths
# ---------------------------------------------------------------------------
INSTALL_DIR="${HOME}/.local/share/writer-cli"
BIN_DIR="${HOME}/.local/bin"
BIN_LINK="${BIN_DIR}/writer"
REPO_URL="https://github.com/brennanbrown/writer-cli.git"

printf "\n"
printf "${CYAN}┌──────────────────────────────────────────┐${RESET}\n"
printf "${CYAN}│  Installing writer                       │${RESET}\n"
printf "${CYAN}└──────────────────────────────────────────┘${RESET}\n"
printf "\n"

# ---------------------------------------------------------------------------
# 1. Check dependencies
# ---------------------------------------------------------------------------
say "Checking dependencies..."

if ! command -v git >/dev/null 2>&1; then
    die "git is required but not found. Install it first:
  macOS:  git is included with Xcode Command Line Tools — run: xcode-select --install
  Linux:  sudo apt install git   (Debian/Ubuntu)
          sudo dnf install git   (Fedora)
          sudo pacman -S git     (Arch)"
fi
ok "git found: $(git --version)"

if ! command -v bash >/dev/null 2>&1; then
    die "bash is required but not found."
fi
ok "bash found: $(bash --version | head -1)"

# ---------------------------------------------------------------------------
# 2. Clone or update the repo
# ---------------------------------------------------------------------------
if [[ -d "$INSTALL_DIR/.git" ]]; then
    say "writer-cli already downloaded — pulling latest version..."
    git -C "$INSTALL_DIR" pull --ff-only
    ok "Updated to latest version"
else
    say "Downloading writer-cli to ${INSTALL_DIR}..."
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
    ok "Downloaded"
fi

chmod +x "${INSTALL_DIR}/writer.sh"

# ---------------------------------------------------------------------------
# 3. Create ~/.local/bin and symlink
# ---------------------------------------------------------------------------
mkdir -p "$BIN_DIR"

if [[ -L "$BIN_LINK" ]]; then
    say "Updating symlink at ${BIN_LINK}..."
    ln -sf "${INSTALL_DIR}/writer.sh" "$BIN_LINK"
elif [[ -e "$BIN_LINK" ]]; then
    warn "${BIN_LINK} already exists and is not a symlink — leaving it alone."
    warn "If you want writer to be managed by this installer, remove it first:"
    warn "  rm ${BIN_LINK}"
else
    say "Creating ${BIN_LINK}..."
    ln -s "${INSTALL_DIR}/writer.sh" "$BIN_LINK"
fi
ok "writer → ${INSTALL_DIR}/writer.sh"

# ---------------------------------------------------------------------------
# 4. Add ~/.local/bin to PATH in the shell profile if needed
# ---------------------------------------------------------------------------
_add_to_path() {
    local profile="$1"
    local export_line='export PATH="$HOME/.local/bin:$PATH"'
    if [[ -f "$profile" ]] && grep -qF '.local/bin' "$profile" 2>/dev/null; then
        return 0  # already present
    fi
    printf '\n# Added by writer installer\n%s\n' "$export_line" >> "$profile"
    ok "Added PATH entry to ${profile}"
}

PATH_ADDED=false
if [[ "$SHELL" == */zsh ]]; then
    _add_to_path "${HOME}/.zshrc"
    _add_to_path "${HOME}/.zprofile"
    PATH_ADDED=true
elif [[ "$SHELL" == */bash ]]; then
    _add_to_path "${HOME}/.bashrc"
    _add_to_path "${HOME}/.bash_profile"
    PATH_ADDED=true
fi
if [[ "$PATH_ADDED" == "false" ]]; then
    # Fall back to .profile (POSIX)
    _add_to_path "${HOME}/.profile"
fi

# Make it available in the current session immediately
export PATH="${BIN_DIR}:${PATH}"

# ---------------------------------------------------------------------------
# 5. Quick smoke test
# ---------------------------------------------------------------------------
say "Testing installation..."
if ! bash "${INSTALL_DIR}/writer.sh" --help >/dev/null 2>&1; then
    die "writer --help returned an error. Installation may be incomplete."
fi
ok "writer is working"

# ---------------------------------------------------------------------------
# 6. Done — prompt to run setup
# ---------------------------------------------------------------------------
printf "\n"
printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
printf "${GREEN}  writer is installed!${RESET}\n"
printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
printf "\n"
printf "  Installed to:  ${CYAN}%s${RESET}\n" "$INSTALL_DIR"
printf "  Command:       ${CYAN}writer${RESET}\n"
printf "\n"

# Check if writer config already exists
if [[ -f "${HOME}/.config/writer/config" ]]; then
    printf "  A config file already exists at:\n"
    printf "    ${CYAN}%s${RESET}\n" "${HOME}/.config/writer/config"
    printf "\n"
    printf "  Run ${CYAN}writer --setup${RESET} at any time to change your settings.\n"
else
    printf "  ${YELLOW}No config file found yet.${RESET}\n"
    printf "  Let's run the setup wizard so writer knows where your blog lives.\n"
    printf "\n"
    printf "  Press Enter to start setup, or Ctrl+C to set it up later: "
    read -r _skip || true
    printf "\n"
    exec bash "${INSTALL_DIR}/writer.sh" --setup
fi

printf "\n"
printf "  To start writing, open a new terminal and run:\n"
printf "    ${CYAN}writer my-first-post${RESET}\n"
printf "\n"
printf "  Or reload your shell profile now:\n"
printf "    ${CYAN}source ~/.zprofile && source ~/.zshrc${RESET}   (zsh)\n"
printf "    ${CYAN}source ~/.bash_profile${RESET}                  (bash)\n"
printf "\n"
