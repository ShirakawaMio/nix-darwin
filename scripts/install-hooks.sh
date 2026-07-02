#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1
  pwd -P
})"

cd -- "$repo_root"
git config core.hooksPath .githooks
printf 'Configured git hooks path: .githooks\n'
