# lib/post.sh — main post-creation workflow
# Sourced by writer.sh. Do not execute directly.

main() {
    parse_args "$@"

    # --setup: run wizard, then exit (no slug needed)
    if [[ "$FLAG_SETUP" == "true" ]]; then
        run_onboarding "false"
        exit 0
    fi

    # First-run auto-trigger: no global config exists yet
    if [[ ! -f "${HOME}/.config/writer/config" ]]; then
        run_onboarding "true"
        exit 0
    fi

    # Config loading order:
    #   1. Global config (~/.config/writer/config)
    #   2. cd to SITE_DIR (if set by global config)
    #   3. Project-local .writerrc (overrides global)
    load_global_config

    if [[ -n "$SITE_DIR" ]]; then
        if [[ ! -e "$SITE_DIR" ]]; then
            err "SITE_DIR does not exist: '$SITE_DIR'"
            err "  ↳ Create the directory or correct the SITE_DIR value in your config."
            exit 1
        fi
        if [[ ! -d "$SITE_DIR" ]]; then
            err "SITE_DIR is not a directory: '$SITE_DIR'"
            err "  ↳ SITE_DIR must be the root directory of your Hugo/SSG project."
            exit 1
        fi
        cd "$SITE_DIR" || {
            err "Failed to change directory to SITE_DIR: '$SITE_DIR'"
            err "  ↳ Check permissions."
            exit 1
        }
    fi

    load_local_config

    # Apply CLI flag overrides (highest priority, after all config)
    if [[ -n "$OVERRIDE_SECTION" ]]; then DEFAULT_SECTION="$OVERRIDE_SECTION"; fi
    if [[ -n "$OVERRIDE_SSG" ]];    then SSG="$OVERRIDE_SSG"; fi
    if [[ "$FLAG_TOML" == "true" ]]; then FRONTMATTER_FORMAT="toml"; fi

    validate_slug "$SLUG"

    check_deps

    # Determine output path
    local section="$DEFAULT_SECTION"
    local file_path

    if [[ "$BUNDLE_FORMAT" == "true" ]]; then
        file_path="${CONTENT_DIR}/${section}/${SLUG}/index.md"
    else
        file_path="${CONTENT_DIR}/${section}/${SLUG}.md"
    fi

    # Check for existing file
    if [[ -f "$file_path" ]]; then
        printf "File already exists: %s\n" "$file_path"
        printf "Overwrite? [y/N]: "
        read -r overwrite_answer || true
        case "$(printf '%s' "$overwrite_answer" | tr '[:upper:]' '[:lower:]')" in
            y|yes)
                info "Overwriting existing file."
                ;;
            *)
                err "Aborted — file not overwritten."
                err "  ↳ Use a different slug, or re-run and answer 'y' to overwrite."
                exit 2
                ;;
        esac
    fi

    # Prompt: Title (required)
    local title=""
    printf "Title: "
    read -r title || true
    if [[ -z "$title" ]]; then
        printf "Title (cannot be blank): "
        read -r title || true
        if [[ -z "$title" ]]; then
            err "Title cannot be empty."
            err "  ↳ A title is required. Re-run and provide a non-blank title."
            exit 1
        fi
    fi

    # Prompt: Tags (optional) — pre-filled from DEFAULT_TAGS if set
    local tags=""
    if [[ -n "$DEFAULT_TAGS" ]]; then
        printf "Tags (comma-separated) [%s]: " "$DEFAULT_TAGS"
        read -r tags || true
        if [[ -z "$tags" ]]; then
            tags="$DEFAULT_TAGS"
        fi
    else
        printf "Tags (comma-separated): "
        read -r tags || true
    fi

    # Get timestamp
    local post_date
    post_date="$(get_iso_date)"

    # Draft flag
    local draft_value="false"
    if [[ "$FLAG_DRAFT" == "true" ]]; then draft_value="true"; fi

    # Build frontmatter (description left blank until post-editor)
    local frontmatter
    if [[ "$FRONTMATTER_FORMAT" == "toml" ]]; then
        frontmatter="$(build_toml_frontmatter "$title" "$SLUG" "$post_date" "$tags" "" "$draft_value")"
    else
        frontmatter="$(build_yaml_frontmatter "$title" "$SLUG" "$post_date" "$tags" "" "$draft_value")"
    fi

    # --dry-run: print frontmatter and exit
    if [[ "$FLAG_DRY_RUN" == "true" ]]; then
        printf "\n--- Dry run — no files written ---\n\n"
        printf "%s\n" "$frontmatter"
        exit 0
    fi

    # Create directory and file
    if ! mkdir -p "$(dirname "$file_path")"; then
        err "Failed to create directory: $(dirname "$file_path")"
        err "  ↳ Check that you have write permission to '${CONTENT_DIR}'."
        exit 1
    fi
    if ! printf "%s\n" "$frontmatter" > "$file_path"; then
        err "Failed to write file: '$file_path'"
        err "  ↳ Check disk space and write permissions."
        exit 1
    fi

    info "Created: $file_path"
    info "Opening in ${EDITOR_CMD}..."

    local fm_lines
    fm_lines="$(count_frontmatter_lines "$FRONTMATTER_FORMAT" "$title" "$tags" "")"
    local cursor_line=$(( fm_lines + 1 ))

    # Open editor, blocking
    if ! "${EDITOR_CMD}" "+${cursor_line}" "$file_path"; then
        err "Editor '${EDITOR_CMD}' exited with a non-zero status."
        err "  ↳ Your file was saved at: $file_path"
        err "  ↳ You can re-open it manually and then run the build/push steps yourself."
    fi

    # ---------------------------------------------------------------------------
    # Secondary prompts (post-editor)
    # ---------------------------------------------------------------------------
    printf "\n"

    local description=""
    printf "Summary / description: "
    read -r description || true

    # Re-write frontmatter with description prepended (insert before draft line)
    if [[ -n "$description" ]]; then
        if [[ "$FRONTMATTER_FORMAT" == "toml" ]]; then
            frontmatter="$(build_toml_frontmatter "$title" "$SLUG" "$post_date" "$tags" "$description" "$draft_value")"
        else
            frontmatter="$(build_yaml_frontmatter "$title" "$SLUG" "$post_date" "$tags" "$description" "$draft_value")"
        fi

        # Read body (everything after closing delimiter) and reconstruct file
        local delimiter="---"
        if [[ "$FRONTMATTER_FORMAT" == "toml" ]]; then delimiter="+++"; fi

        # Find the line number of the second delimiter in the file
        local delim_count=0
        local body_start=0
        local lineno=0
        while IFS= read -r line; do
            lineno=$((lineno + 1))
            if [[ "$line" == "$delimiter" ]]; then
                delim_count=$((delim_count + 1))
                if [[ $delim_count -eq 2 ]]; then
                    body_start=$lineno
                    break
                fi
            fi
        done < "$file_path"

        # Extract body lines (everything after closing delimiter)
        local body=""
        if [[ $body_start -gt 0 ]]; then
            body="$(tail -n +"$((body_start + 1))" "$file_path")"
        fi

        # Write updated file
        printf "%s\n" "$frontmatter" > "$file_path"
        if [[ -n "$body" ]]; then
            printf "%s\n" "$body" >> "$file_path"
        fi
    fi

    # Confirm build and push
    printf "Confirm build and push? [Y/n]: "
    read -r confirm || true
    case "$(printf '%s' "$confirm" | tr '[:upper:]' '[:lower:]')" in
        n|no)
            info "Skipped build and push."
            ok "Post saved: $SLUG"
            exit 0
            ;;
    esac

    # ---------------------------------------------------------------------------
    # Build step
    # ---------------------------------------------------------------------------
    if [[ "$FLAG_NO_BUILD" == "false" ]]; then
        info "Building site..."
        local build_start build_end build_elapsed
        build_start="$(date +%s)"

        if ! bash -c "$BUILD_CMD"; then
            err "Build command failed: $BUILD_CMD"
            err "  ↳ The site was not built. Your post file is at: $file_path"
            err "  ↳ Fix the build error above, then run the build and git steps manually:"
            err "      $BUILD_CMD"
            err "      git add . && git commit -m \"${GIT_COMMIT_MSG//\{slug\}/$SLUG}\" && git push"
            exit 3
        fi

        build_end="$(date +%s)"
        build_elapsed=$(( build_end - build_start ))
        info "Build done (${build_elapsed}s)"
    fi

    # ---------------------------------------------------------------------------
    # Git step
    # ---------------------------------------------------------------------------
    if [[ "$FLAG_NO_PUSH" == "true" ]]; then
        ok "Build complete. Post not pushed (--no-push)."
        exit 0
    fi

    local commit_msg="${GIT_COMMIT_MSG//\{slug\}/$SLUG}"

    info "git add ."
    if ! git add .; then
        err "'git add' failed."
        err "  ↳ Check that you are inside a git repository (git status)."
        exit 4
    fi

    info "git commit -m \"${commit_msg}\""
    if ! git commit -m "$commit_msg"; then
        err "'git commit' failed."
        err "  ↳ There may be nothing to commit, or git identity is not configured."
        err "  ↳ Run: git config user.name 'Your Name' && git config user.email 'you@example.com'"
        exit 4
    fi

    info "git push..."
    if ! git push; then
        err "'git push' failed."
        err "  ↳ Check your remote URL: git remote -v"
        err "  ↳ Ensure SSH keys or credentials are configured for push access."
        err "  ↳ Your commit was made locally. Run 'git push' manually once the issue is resolved."
        exit 4
    fi

    ok "Published: $SLUG"
    exit 0
}
