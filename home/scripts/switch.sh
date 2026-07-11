#!/usr/bin/env bash
set -euo pipefail

config_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd -P)"
config_name="${HOME_MANAGER_CONFIG:-$(id -un)}"
nix_config="extra-experimental-features = nix-command flakes"

case "${NIX_CONFIG:-}" in
  *accept-flake-config*)
    ;;
  *)
    nix_config="$nix_config
accept-flake-config = true"
    ;;
esac

if [ -n "${NIX_CONFIG:-}" ]; then
  export NIX_CONFIG="$NIX_CONFIG
$nix_config"
else
  export NIX_CONFIG="$nix_config"
fi

exec home-manager switch --flake "$config_dir#$config_name" "$@"
