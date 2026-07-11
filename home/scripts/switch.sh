#!/usr/bin/env bash
set -euo pipefail

config_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd -P)"

load_env_file() {
  local key value

  if [ -f "$config_dir/.env" ]; then
    while IFS='=' read -r key value; do
      case "$key" in
        NIX_DARWIN_HOSTNAME|NIX_DARWIN_USER|NIX_DARWIN_HOME|NIX_DARWIN_ENABLE_HOMEBREW_CASKS|HOME_MANAGER_USER|HOME_MANAGER_HOME|HOME_MANAGER_CONFIG|HOME_MANAGER_SYSTEM)
          if [ -z "${!key:-}" ]; then
            eval "$key=$value"
            export "$key"
          fi
          ;;
      esac
    done < "$config_dir/.env"
  fi
}

load_env_file

config_name="${HOME_MANAGER_CONFIG:-$(id -un)}"
home_manager_user="${HOME_MANAGER_USER:-$(id -un)}"
home_manager_home="${HOME_MANAGER_HOME:-$HOME}"
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

export HOME_MANAGER_CONFIG="$config_name"
export HOME_MANAGER_USER="$home_manager_user"
export HOME_MANAGER_HOME="$home_manager_home"
export HOME_MANAGER_SYSTEM="${HOME_MANAGER_SYSTEM:-}"

exec home-manager switch --flake "$config_dir#$config_name" --impure "$@"
