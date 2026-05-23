# Contributing to writer-cli

Thanks for your interest in contributing! writer-cli is a bash tool designed
to stay simple and dependency-free, and we'd love to keep it that way. Please
keep that philosophy in mind when proposing changes.

## Getting Started

```bash
git clone https://github.com/brennanbrown/writer-cli.git
cd writer-cli
```

There's no build step and no `npm install`. The project is plain bash.

## Running the Tests

```bash
bash tests/test_writer.sh
```

The suite creates an isolated `$HOME` via `mktemp -d` for each test, so your
real config is never touched. All 104 tests should pass before opening a PR.

## Style Guide

Shell code follows the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html). Key rules:

- 2-space indentation, no tabs
- `[[ … ]]` not `[ … ]`
- `$(…)` not backticks
- `local` for all function-scoped variables; declare and assign separately when the value comes from a command substitution
- No `eval`: use `bash -c` or arrays
- Errors to STDERR via `err()`; normal output via `info()` / `ok()`
- `UPPER_CASE` for globals, `lower_case` for locals and functions

Run [ShellCheck](https://www.shellcheck.net/) before submitting:

```bash
shellcheck writer.sh lib/*.sh INSTALL.sh
```

The `.shellcheckrc` at the project root sets the target shell and disables
SC2034 (unused variable warnings that are expected in sourced lib files).

## Project Structure

```
writer.sh          ← thin entry point, sources all lib/ modules
lib/
  defaults.sh      ← global variable defaults and output helpers (err/info/ok)
  config.sh        ← INI config file parser, load_global_config / load_local_config
  args.sh          ← CLI flag parsing and usage text
  setup.sh         ← interactive onboarding wizard
  validate.sh      ← slug validation and ISO 8601 date generation
  frontmatter.sh   ← YAML / TOML frontmatter builders and line counter
  deps.sh          ← dependency pre-flight checks
  post.sh          ← main workflow orchestration
tests/
  test_writer.sh   ← self-contained test harness
site/              ← Eleventy documentation site
config.example     ← annotated example config file
INSTALL.sh         ← one-command installer
```

## Adding a Config Key

1. Add the variable and default in `lib/defaults.sh`
2. Add a `case` branch in `_parse_config_file()` in `lib/config.sh`
3. Update the valid-keys error message in the same function
4. Add a `_prompt` call in `run_onboarding()` in `lib/setup.sh`
5. Write it into the config `cat <<EOF` block in the same function
6. Add a row to the config table in `site/src/reference.njk`
7. Add a line to `config.example`
8. Add tests

## Pull Requests

- Keep PRs focused, one concern per PR
- Update `CHANGELOG.md` under `[Unreleased]`
- Ensure `bash tests/test_writer.sh` exits 0
- Add tests for any new behaviour

## Reporting Issues

Open a [GitHub issue](https://github.com/brennanbrown/writer-cli/issues).
Include your OS, bash version (`bash --version`), and the full error output.
