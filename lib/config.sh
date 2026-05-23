# lib/config.sh — config file parsing and loading
# Sourced by writer.sh. Do not execute directly.

# Parse a single config file into the global variables.
# Exits 5 on unknown keys.
_parse_config_file() {
    local config_file="$1"
    local line key value
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Strip inline comments and trim whitespace
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        if [[ -z "$line" ]]; then continue; fi

        key="${line%%=*}"
        value="${line#*=}"

        # Trim whitespace from key and value
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        case "$key" in
            SSG)                SSG="$value" ;;
            BUILD_CMD)          BUILD_CMD="$value" ;;
            CONTENT_DIR)        CONTENT_DIR="$value" ;;
            DEFAULT_SECTION)    DEFAULT_SECTION="$value" ;;
            DEFAULT_TAGS)       DEFAULT_TAGS="$value" ;;
            BUNDLE_FORMAT)
                if [[ "$value" != "true" && "$value" != "false" ]]; then
                    err "Config parse error in $config_file: BUNDLE_FORMAT must be 'true' or 'false', got '$value'"
                    exit 5
                fi
                BUNDLE_FORMAT="$value"
                ;;
            FRONTMATTER_FORMAT)
                if [[ "$value" != "yaml" && "$value" != "toml" ]]; then
                    err "Config parse error in $config_file: FRONTMATTER_FORMAT must be 'yaml' or 'toml', got '$value'"
                    exit 5
                fi
                FRONTMATTER_FORMAT="$value"
                ;;
            EDITOR)             EDITOR_CMD="$value" ;;
            GIT_COMMIT_MSG)     GIT_COMMIT_MSG="$value" ;;
            TIMEZONE)           TIMEZONE="$value" ;;
            SITE_DIR)           SITE_DIR="$value" ;;
            *)
                err "Config parse error in $config_file: unknown key '$key'"
                err "  ↳ Valid keys: SSG, BUILD_CMD, CONTENT_DIR, DEFAULT_SECTION, DEFAULT_TAGS, BUNDLE_FORMAT,"
                err "              FRONTMATTER_FORMAT, EDITOR, GIT_COMMIT_MSG, TIMEZONE, SITE_DIR"
                exit 5
                ;;
        esac
    done < "$config_file"
}

# Load global config first, then overlay project-local .writerrc.
# Caller is responsible for cd-ing to SITE_DIR before calling load_local_config.
load_global_config() {
    if [[ -f "${HOME}/.config/writer/config" ]]; then
        _parse_config_file "${HOME}/.config/writer/config"
    fi
}

load_local_config() {
    if [[ -f ".writerrc" ]]; then
        _parse_config_file ".writerrc"
    fi
}
