# Changelog

All notable changes to writer-cli are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.2] - 2026-05-25

### Fixed
- `INSTALL.sh`: PATH setup on fresh Linux — more specific grep prevents Ubuntu's default `~/.bashrc` block from suppressing the PATH export entry
- `INSTALL.sh`: `~/.bash_profile` is now created (or amended) to source `~/.bashrc` when missing, ensuring login shells pick up the PATH on first install
- `INSTALL.sh`: reload instruction is now displayed in a prominent yellow-boxed "ACTION REQUIRED" block showing the exact single command needed (`source ~/.bashrc` or `source ~/.zshrc`)
- `INSTALL.sh`: prerequisites notice added after the success banner so users know a terminal editor, SSG, and git repo are required before `writer` can publish

### Changed
- `README.md`: install command kept as `curl | bash` (reverted from `eval`) for security; other install methods (Homebrew, Basher) added to README

[1.1.2]: https://github.com/brennanbrown/writer-cli/compare/v1.1.1...v1.1.2

---

## [1.1.1] - 2026-05-25

### Fixed
- `writer.sh`: symlink resolution now correctly handles relative `readlink` output (e.g. on macOS/Homebrew), preventing `cd: ../libexec: No such file or directory` when invoked via a Homebrew-managed symlink

[1.1.1]: https://github.com/brennanbrown/writer-cli/compare/v1.1.0...v1.1.1

---

## [1.1.0] - 2026-05-25

### Fixed
- `INSTALL.sh` and `lib/setup.sh`: all `read` calls now use `</dev/tty` so the setup wizard works correctly when invoked via `curl | bash` (previously, stdin was the pipe and printf output was consumed as user input, corrupting the saved config)
- `INSTALL.sh`: reload hint at the end of install now shows the correct shell-specific command (`source ~/.bash_profile && source ~/.bashrc` for bash, `source ~/.zprofile && source ~/.zshrc` for zsh)
- `lib/setup.sh`: whitespace is trimmed from `read` input in the `BUNDLE_FORMAT` and `FRONTMATTER_FORMAT` validation loops, preventing spurious re-prompt cycles when the user presses space+Enter
- `lib/setup.sh`: `BUNDLE_FORMAT` and `FRONTMATTER_FORMAT` now default correctly on first run when no config exists
- `INSTALL.sh`: `export PATH` line now runs before the smoke test, ensuring `writer` is available in the current install session
- `lib/deps.sh`: git repo detection relaxed to handle bare repos and non-standard `.git` configurations
- `lib/post.sh`: title prompt clarified
- `writer.sh`: symlink resolved at startup so `lib/` modules are found correctly when `writer` is invoked via `~/.local/bin/writer` symlink

[1.1.0]: https://github.com/brennanbrown/writer-cli/compare/v1.0.0...v1.1.0

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
