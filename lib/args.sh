# lib/args.sh — usage text and CLI argument parsing
# Sourced by writer.sh. Do not execute directly.

usage() {
    cat <<'EOF'
Usage: writer <slug> [options]
       writer --setup

Options:
  --ssg <name>       Override default SSG (hugo, eleventy, jekyll)
  --section <name>   Override content section/directory (default: posts)
  --draft            Set draft: true in frontmatter
  --no-push          Build only; skip git push
  --no-build         Skip build; git commit and push only
  --toml             Use TOML frontmatter instead of YAML
  --dry-run          Preview generated frontmatter without writing any files
  --setup            Run the interactive setup wizard
  -h, --help         Show this help message

Configuration:
  ~/.config/writer/config   Global config (INI key=value)
  .writerrc                 Project-local config (takes precedence)
EOF
}

parse_args() {
    # Allow no-arg invocation only when --setup is the sole argument (checked below)
    if [[ $# -eq 0 ]]; then
        err "Missing argument: <slug>"
        usage
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --setup)
                FLAG_SETUP="true"
                shift
                ;;
            --ssg)
                if [[ -z "${2:-}" ]]; then err "--ssg requires a value"; exit 1; fi
                OVERRIDE_SSG="$2"
                shift 2
                ;;
            --section)
                if [[ -z "${2:-}" ]]; then err "--section requires a value"; exit 1; fi
                OVERRIDE_SECTION="$2"
                shift 2
                ;;
            --draft)
                FLAG_DRAFT="true"
                shift
                ;;
            --no-push)
                FLAG_NO_PUSH="true"
                shift
                ;;
            --no-build)
                FLAG_NO_BUILD="true"
                shift
                ;;
            --toml)
                FLAG_TOML="true"
                shift
                ;;
            --dry-run)
                FLAG_DRY_RUN="true"
                shift
                ;;
            --*)
                err "Unknown flag: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$SLUG" ]]; then
                    SLUG="$1"
                else
                    err "Unexpected argument: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # --setup is valid without a slug
    if [[ "$FLAG_SETUP" == "true" ]]; then
        return 0
    fi

    if [[ -z "$SLUG" ]]; then
        err "Missing argument: <slug>"
        usage
        exit 1
    fi
}
