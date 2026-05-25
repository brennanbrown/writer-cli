# lib/setup.sh — interactive first-run / --setup onboarding wizard
# Sourced by writer.sh. Do not execute directly.

_prompt() {
    # _prompt <label> <description> <current_value>
    # Prints a labelled prompt with the current value shown as default.
    # Reads into global REPLY_VAL; keeps current value if user presses Enter.
    local label="$1" desc="$2" current="$3"
    printf "\n${CYAN}%s${RESET}\n" "$label"
    printf "  %s\n" "$desc"
    if [[ -n "$current" ]]; then
        printf "  Current: ${GREEN}%s${RESET}\n" "$current"
        printf "  Press Enter to keep, or type a new value: "
    else
        printf "  Enter value: "
    fi
    read -r REPLY_VAL || true
    REPLY_VAL="${REPLY_VAL#"${REPLY_VAL%%[![:space:]]*}"}"
    REPLY_VAL="${REPLY_VAL%"${REPLY_VAL##*[![:space:]]}"}" 
    if [[ -z "$REPLY_VAL" ]]; then
        REPLY_VAL="$current"
    fi
}

run_onboarding() {
    local config_path="${HOME}/.config/writer/config"
    local is_first_run="$1"  # "true" = first-run banner, "false" = re-run banner

    printf "\n"
    if [[ "$is_first_run" == "true" ]]; then
        printf "${CYAN}┌─────────────────────────────────────────┐${RESET}\n"
        printf "${CYAN}│  Welcome to writer — first-time setup   │${RESET}\n"
        printf "${CYAN}└─────────────────────────────────────────┘${RESET}\n"
        printf "No global config found. Let's set up %s\n" "$config_path"
    else
        printf "${CYAN}┌─────────────────────────────────────────┐${RESET}\n"
        printf "${CYAN}│  writer — setup wizard                  │${RESET}\n"
        printf "${CYAN}└─────────────────────────────────────────┘${RESET}\n"
        printf "Updating %s\n" "$config_path"
        if [[ -f "$config_path" ]]; then
            _parse_config_file "$config_path"
        fi
    fi
    # Ensure hardcoded defaults fill any still-blank variables (first run or missing keys)
    if [[ -z "$BUNDLE_FORMAT" ]];      then BUNDLE_FORMAT="true"; fi
    if [[ -z "$FRONTMATTER_FORMAT" ]]; then FRONTMATTER_FORMAT="yaml"; fi
    printf "Press Enter to accept the shown default for each setting.\n"

    # --- SSG ---
    _prompt "SSG" \
        "Static site generator. Supported: hugo, eleventy, jekyll" \
        "$SSG"
    local new_ssg="$REPLY_VAL"

    # --- BUILD_CMD ---
    _prompt "BUILD_CMD" \
        "Shell command to build the site (e.g. hugo --minify, npx @11ty/eleventy)" \
        "$BUILD_CMD"
    local new_build_cmd="$REPLY_VAL"

    # --- CONTENT_DIR ---
    _prompt "CONTENT_DIR" \
        "Directory that holds posts, relative to the site root (e.g. content, src/posts)" \
        "$CONTENT_DIR"
    local new_content_dir="$REPLY_VAL"

    # --- DEFAULT_SECTION ---
    _prompt "DEFAULT_SECTION" \
        "Default sub-directory inside CONTENT_DIR for new posts (e.g. posts, blog, notes)" \
        "$DEFAULT_SECTION"
    local new_section="$REPLY_VAL"

    # --- DEFAULT_TAGS ---
    _prompt "DEFAULT_TAGS" \
        "Comma-separated tags pre-filled at the tags prompt (e.g. personal,blog). Leave blank for none." \
        "$DEFAULT_TAGS"
    local new_default_tags="$REPLY_VAL"

    # --- BUNDLE_FORMAT ---
    printf "\n${CYAN}BUNDLE_FORMAT${RESET}\n"
    printf "  File layout for new posts.\n"
    printf "    true  → content/<section>/<slug>/index.md  (page bundle, supports co-located assets)\n"
    printf "    false → content/<section>/<slug>.md        (flat file)\n"
    printf "  Current: ${GREEN}%s${RESET}\n" "$BUNDLE_FORMAT"
    printf "  Enter 'true' or 'false' [Enter to keep]: "
    read -r REPLY_VAL || true
    REPLY_VAL="${REPLY_VAL#"${REPLY_VAL%%[![:space:]]*}"}"; REPLY_VAL="${REPLY_VAL%"${REPLY_VAL##*[![:space:]]}"}" 
    if [[ -z "$REPLY_VAL" ]]; then REPLY_VAL="$BUNDLE_FORMAT"; fi
    while [[ "$REPLY_VAL" != "true" && "$REPLY_VAL" != "false" ]]; do
        printf "  ${RED}Must be 'true' or 'false':${RESET} "
        read -r REPLY_VAL || true
        REPLY_VAL="${REPLY_VAL#"${REPLY_VAL%%[![:space:]]*}"}"; REPLY_VAL="${REPLY_VAL%"${REPLY_VAL##*[![:space:]]}"}" 
        if [[ -z "$REPLY_VAL" ]]; then REPLY_VAL="$BUNDLE_FORMAT"; fi
    done
    local new_bundle="$REPLY_VAL"

    # --- FRONTMATTER_FORMAT ---
    printf "\n${CYAN}FRONTMATTER_FORMAT${RESET}\n"
    printf "  Frontmatter syntax for new posts.\n"
    printf "    yaml → --- delimiters (Hugo default)\n"
    printf "    toml → +++ delimiters\n"
    printf "  Current: ${GREEN}%s${RESET}\n" "$FRONTMATTER_FORMAT"
    printf "  Enter 'yaml' or 'toml' [Enter to keep]: "
    read -r REPLY_VAL || true
    REPLY_VAL="${REPLY_VAL#"${REPLY_VAL%%[![:space:]]*}"}"; REPLY_VAL="${REPLY_VAL%"${REPLY_VAL##*[![:space:]]}"}" 
    if [[ -z "$REPLY_VAL" ]]; then REPLY_VAL="$FRONTMATTER_FORMAT"; fi
    while [[ "$REPLY_VAL" != "yaml" && "$REPLY_VAL" != "toml" ]]; do
        printf "  ${RED}Must be 'yaml' or 'toml':${RESET} "
        read -r REPLY_VAL || true
        REPLY_VAL="${REPLY_VAL#"${REPLY_VAL%%[![:space:]]*}"}"; REPLY_VAL="${REPLY_VAL%"${REPLY_VAL##*[![:space:]]}"}" 
        if [[ -z "$REPLY_VAL" ]]; then REPLY_VAL="$FRONTMATTER_FORMAT"; fi
    done
    local new_fm_format="$REPLY_VAL"

    # --- EDITOR ---
    _prompt "EDITOR" \
        "Terminal editor binary to open for writing (e.g. micro, nano, vim, nvim)" \
        "$EDITOR_CMD"
    local new_editor="$REPLY_VAL"

    # --- GIT_COMMIT_MSG ---
    _prompt "GIT_COMMIT_MSG" \
        "Commit message template. Use {slug} as a placeholder for the post slug." \
        "$GIT_COMMIT_MSG"
    local new_commit_msg="$REPLY_VAL"

    # --- TIMEZONE ---
    printf "\n${CYAN}TIMEZONE${RESET}\n"
    printf "  Timezone for post dates.\n"
    printf "    auto → use the system timezone\n"
    printf "    or a valid IANA name, e.g. America/Winnipeg, Europe/London, UTC\n"
    printf "  Current: ${GREEN}%s${RESET}\n" "$TIMEZONE"
    printf "  Enter timezone [Enter to keep]: "
    read -r REPLY_VAL || true
    if [[ -z "$REPLY_VAL" ]]; then REPLY_VAL="$TIMEZONE"; fi
    local new_timezone="$REPLY_VAL"

    # --- SITE_DIR ---
    printf "\n${CYAN}SITE_DIR${RESET}\n"
    printf "  Absolute path to your site root. Leave blank to use the current directory.\n"
    printf "  Useful when running writer from outside the site (e.g. via SSH, cron, or\n"
    printf "  a shell alias from your home directory).\n"
    local site_display="$SITE_DIR"
    if [[ -z "$site_display" ]]; then site_display="(blank — use current directory)"; fi
    printf "  Current: ${GREEN}%s${RESET}\n" "$site_display"
    printf "  Enter absolute path [Enter to keep]: "
    read -r REPLY_VAL || true
    local new_site_dir="$REPLY_VAL"
    # Validate if non-blank
    if [[ -n "$new_site_dir" && ! -d "$new_site_dir" ]]; then
        printf "  ${RED}Warning: '$new_site_dir' is not an existing directory.${RESET}\n"
        printf "  It will be saved anyway — create the directory before running writer.\n"
    fi

    # --- Write config ---
    printf "\n"
    mkdir -p "$(dirname "$config_path")"
    cat > "$config_path" <<EOF
# writer config — written by setup wizard on $(date '+%Y-%m-%d')
# Re-run setup at any time with: writer --setup
# Project-local overrides: place a .writerrc in your site root.

SSG=${new_ssg}
BUILD_CMD=${new_build_cmd}
CONTENT_DIR=${new_content_dir}
DEFAULT_SECTION=${new_section}
DEFAULT_TAGS=${new_default_tags}
BUNDLE_FORMAT=${new_bundle}       # true = slug/index.md, false = slug.md
FRONTMATTER_FORMAT=${new_fm_format}  # yaml or toml
EDITOR=${new_editor}
GIT_COMMIT_MSG=${new_commit_msg}
TIMEZONE=${new_timezone}          # auto = system TZ; or e.g. America/Winnipeg
SITE_DIR=${new_site_dir}
EOF

    ok "Config saved to $config_path"
    printf "\n"
    printf "  Run ${CYAN}writer <slug>${RESET} to create your first post.\n"
    printf "  Run ${CYAN}writer --setup${RESET} at any time to update these settings.\n"
    printf "\n"
}
