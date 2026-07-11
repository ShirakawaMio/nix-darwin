#!/usr/bin/env bash
set -euo pipefail

config_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd -P)"
config_name="${HOME_MANAGER_CONFIG:-$(id -un)}"

exec home-manager switch --flake "$config_dir#$config_name" "$@"
