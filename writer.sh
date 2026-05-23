#!/usr/bin/env bash
#title          :writer.sh
#description    :CLI post creation tool for blogs using static site generators
#author         :Brennan Kenneth Brown 
#repo           :https://github.com/brennanbrown/writer-cli
#date           :20250523
#version        :1.0.0
#usage          :writer <slug> [options] | writer --setup
#notes          :Requires bash 3.2+, git, and a terminal editor (default: micro)
#bash_version   :3.2+
#license        :AGPL-3.0
#============================================================================

set -euo pipefail

# Resolve the directory this script lives in so lib/ can be found regardless
# of the working directory the user invokes writer from.
WRITER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/defaults.sh
source "${WRITER_DIR}/lib/defaults.sh"
# shellcheck source=lib/config.sh
source "${WRITER_DIR}/lib/config.sh"
# shellcheck source=lib/args.sh
source "${WRITER_DIR}/lib/args.sh"
# shellcheck source=lib/setup.sh
source "${WRITER_DIR}/lib/setup.sh"
# shellcheck source=lib/validate.sh
source "${WRITER_DIR}/lib/validate.sh"
# shellcheck source=lib/frontmatter.sh
source "${WRITER_DIR}/lib/frontmatter.sh"
# shellcheck source=lib/deps.sh
source "${WRITER_DIR}/lib/deps.sh"
# shellcheck source=lib/post.sh
source "${WRITER_DIR}/lib/post.sh"

main "$@"
