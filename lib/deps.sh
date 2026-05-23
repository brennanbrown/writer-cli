# lib/deps.sh — dependency pre-flight checks
# Sourced by writer.sh. Do not execute directly.

check_deps() {
    local missing=0

    # --dry-run only prints frontmatter; no editor, build, or git needed
    if [[ "$FLAG_DRY_RUN" == "true" ]]; then
        return 0
    fi

    if ! command -v "${EDITOR_CMD}" >/dev/null 2>&1; then
        err "Required editor not found: ${EDITOR_CMD}"
        err "Install it or set EDITOR in your writer config."
        missing=1
    fi

    if [[ "$FLAG_NO_BUILD" == "false" ]]; then
        # Check the first word of BUILD_CMD (the actual binary)
        local build_bin
        build_bin="${BUILD_CMD%% *}"
        if ! command -v "${build_bin}" >/dev/null 2>&1; then
            err "Build command not found: ${build_bin}"
            err "Install it or set BUILD_CMD in your writer config."
            missing=1
        fi
    fi

    if [[ "$FLAG_NO_PUSH" == "false" ]]; then
        if ! command -v git >/dev/null 2>&1; then
            err "Required tool not found: git"
            missing=1
        else
            # Verify we are inside a git repo
            if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                err "Not inside a git repository. Run writer from your site root or set SITE_DIR."
                missing=1
            fi
        fi
    fi

    if [[ $missing -ne 0 ]]; then exit 1; fi
}
