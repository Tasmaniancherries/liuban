#!/usr/bin/env bash
set -euo pipefail

if ! command -v actionlint >/dev/null 2>&1; then
  echo "actionlint not found. Install: https://github.com/rhysd/actionlint"
  exit 1
fi

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck not found. Install: https://www.shellcheck.net/"
  exit 1
fi

# Keep local checks aligned with .github/workflows/meta-lint.yml.
actionlint
shellcheck tool/*.sh
