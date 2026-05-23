# lib/validate.sh — slug validation and ISO 8601 date generation
# Sourced by writer.sh. Do not execute directly.

validate_slug() {
    local slug="$1"

    if [[ -z "$slug" ]]; then
        err "Slug cannot be empty."
        exit 1
    fi

    # Only lowercase letters, digits, hyphens; no leading/trailing hyphens
    if [[ ! "$slug" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
        err "Invalid slug: '$slug'"
        if [[ "$slug" =~ [A-Z] ]]; then
            err "  ↳ Contains uppercase letters — slugs must be all-lowercase."
        fi
        if [[ "$slug" =~ [^a-z0-9-] ]]; then
            err "  ↳ Contains invalid characters — only a-z, 0-9, and hyphens (-) are allowed."
        fi
        if [[ "$slug" =~ ^- || "$slug" =~ -$ ]]; then
            err "  ↳ Must not start or end with a hyphen."
        fi
        err "  Hint: try '$(printf '%s' "$slug" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-' | sed 's/^-//;s/-$//')'"
        exit 1
    fi
}

get_iso_date() {
    local custom_tz=""

    if [[ "$TIMEZONE" != "auto" && -n "$TIMEZONE" ]]; then
        if ! TZ="$TIMEZONE" date >/dev/null 2>&1; then
            err "Invalid TIMEZONE value: '$TIMEZONE'"
            err "  ↳ Use 'auto' for system timezone, or a valid TZ name like 'America/Winnipeg'."
            exit 1
        fi
        custom_tz="$TIMEZONE"
    fi

    # Try GNU date --iso-8601=seconds first; fall back to BSD date +%z format
    if [[ -n "$custom_tz" ]]; then
        if TZ="$custom_tz" date --iso-8601=seconds 2>/dev/null; then return 0; fi
    else
        if date --iso-8601=seconds 2>/dev/null; then return 0; fi
    fi

    local result
    if [[ -n "$custom_tz" ]]; then
        result=$(TZ="$custom_tz" date +"%Y-%m-%dT%H:%M:%S%z" 2>/dev/null) || true
    else
        result=$(date +"%Y-%m-%dT%H:%M:%S%z" 2>/dev/null) || true
    fi

    if [[ -z "$result" ]]; then
        err "Failed to get current date/time — 'date' command is not working as expected."
        err "  ↳ Ensure GNU coreutils or BSD date is installed."
        exit 1
    fi

    printf '%s' "$result" | sed 's/\([+-][0-9]\{2\}\)\([0-9]\{2\}\)$/\1:\2/'
}
