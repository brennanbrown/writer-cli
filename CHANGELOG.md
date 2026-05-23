# Changelog

All notable changes to writer-cli are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-05-23

### Added
- `writer <slug>` command: full post creation workflow (title, tags, editor, description, build, push)
- YAML and TOML frontmatter generation
- Interactive setup wizard (`writer --setup`) with prompted defaults
- Global config at `~/.config/writer/config`; project-local override via `.writerrc`
- `DEFAULT_TAGS` config key: comma-separated tags pre-filled at the prompt
- CLI flags: `--draft`, `--no-push`, `--no-build`, `--toml`, `--dry-run`, `--section`, `--ssg`, `--setup`
- Timezone-aware ISO 8601 date generation with GNU/BSD `date` compatibility
- Slug validation: lowercase, alphanumeric, hyphens only
- Dependency pre-flight checks (editor, build binary, git, repo detection)
- Bundle format support: `slug/index.md` or `slug.md`
- `SITE_DIR` support for SSH/remote workflows
- One-command installer (`INSTALL.sh`)
- Modular architecture: eight sourced `lib/` modules
- Test suite: 104 assertions, isolated `$HOME` per test
- Eleventy documentation site (`site/`)
- Script header metadata (`#title`, `#description`, `#author`, etc.)

### Changed
- Replaced `eval "$BUILD_CMD"` with `bash -c "$BUILD_CMD"` (style guide compliance)
- Replaced unquoted `$tz_arg` string with a `tz_prefix` array for safe expansion

[1.0.0]: https://github.com/brennanbrown/writer-cli/releases/tag/v1.0.0
