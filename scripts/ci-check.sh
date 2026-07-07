#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '==> %s\n' "$*"
}

REPO_ROOT=""

usage() {
  cat <<'USAGE'
Usage: scripts/ci-check.sh COMMAND

Commands:
  eval              Check shell syntax, Nix syntax, and flake eval.
  pre-commit        Reject tracked unstaged changes, then run eval.
  build-darwin      Build the nix-darwin system for a CI host.
  build-home-linux  Build the Linux Home Manager activation package.
USAGE
}

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || {
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1
    pwd -P
  }
}

tracked_or_found_files() {
  local pattern
  pattern="$1"

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files "$pattern"
  else
    find . -type f -name "$pattern" \
      ! -path './.git/*' \
      ! -path './result/*' \
      ! -path './result-*/*'
  fi
}

detect_hostname() {
  local name
  name=""

  if [ -z "$name" ]; then
    name="$(hostname -s 2>/dev/null || hostname)"
  fi

  if command -v scutil >/dev/null 2>&1; then
    name="$(scutil --get LocalHostName 2>/dev/null || printf '%s' "$name")"
  fi

  printf '%s' "$name" | tr -c '[:alnum:]_-' '-'
}

env_escape() {
  printf '%s' "$1" | sed "s/'/'\\\\''/g"
}

validate_bool() {
  local name value
  name="$1"
  value="$2"

  case "$value" in
    true|false)
      ;;
    *)
      die "$name must be 'true' or 'false'"
      ;;
  esac
}

load_env_file() {
  local key value

  if [ -f "$REPO_ROOT/.env" ]; then
    while IFS='=' read -r key value; do
      case "$key" in
        NIX_DARWIN_HOSTNAME|NIX_DARWIN_USER|NIX_DARWIN_HOME|NIX_DARWIN_ENABLE_HOMEBREW_CASKS|HOME_MANAGER_CONFIG|HOME_MANAGER_SYSTEM)
          if [ -z "${!key:-}" ]; then
            eval "$key=$value"
            export "$key"
          fi
          ;;
      esac
    done < "$REPO_ROOT/.env"
  fi
}

ensure_env_file() {
  local changed host user home enable_casks config system
  changed=0
  host="${NIX_DARWIN_HOSTNAME:-}"
  user="${NIX_DARWIN_USER:-}"
  home="${NIX_DARWIN_HOME:-}"
  enable_casks="${NIX_DARWIN_ENABLE_HOMEBREW_CASKS:-}"
  config="${HOME_MANAGER_CONFIG:-}"
  system="${HOME_MANAGER_SYSTEM:-}"

  if [ -z "$host" ]; then
    host="$(detect_hostname)"
    changed=1
  fi

  if [ -z "$user" ]; then
    user="$(id -un)"
    changed=1
  fi

  if [ -z "$home" ]; then
    home="$HOME"
    changed=1
  fi

  if [ -z "$enable_casks" ]; then
    enable_casks="false"
    changed=1
  fi

  validate_bool NIX_DARWIN_ENABLE_HOMEBREW_CASKS "$enable_casks"

  if [ -z "$config" ]; then
    config="$user"
    changed=1
  fi

  if [ "$changed" -eq 1 ] || [ ! -f "$REPO_ROOT/.env" ]; then
    cat > "$REPO_ROOT/.env" <<EOF
NIX_DARWIN_HOSTNAME='$(env_escape "$host")'
NIX_DARWIN_USER='$(env_escape "$user")'
NIX_DARWIN_HOME='$(env_escape "$home")'
NIX_DARWIN_ENABLE_HOMEBREW_CASKS='$(env_escape "$enable_casks")'
HOME_MANAGER_CONFIG='$(env_escape "$config")'
HOME_MANAGER_SYSTEM='$(env_escape "$system")'
EOF
    info "Updated machine-local .env"
  fi

  export NIX_DARWIN_HOSTNAME="$host"
  export NIX_DARWIN_USER="$user"
  export NIX_DARWIN_HOME="$home"
  export NIX_DARWIN_ENABLE_HOMEBREW_CASKS="$enable_casks"
  export HOME_MANAGER_CONFIG="$config"
  export HOME_MANAGER_SYSTEM="$system"
}

require_nix() {
  command -v nix >/dev/null 2>&1 || die "nix is required"
}

check_shell_syntax() {
  local files=()
  local file

  while IFS= read -r file; do
    files+=("$file")
  done < <(
    tracked_or_found_files '*.sh'
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git ls-files '.githooks/*'
    elif [ -d .githooks ]; then
      find .githooks -type f
    fi
  )

  if [ "${#files[@]}" -eq 0 ]; then
    return
  fi

  info "Checking shell syntax"
  for file in "${files[@]}"; do
    [ -f "$file" ] || continue
    bash -n "$file"
  done
}

check_nix_syntax() {
  local file

  command -v nix-instantiate >/dev/null 2>&1 || die "nix-instantiate is required"

  info "Checking Nix syntax"
  while IFS= read -r file; do
    nix-instantiate --parse "$file" >/dev/null
  done < <(tracked_or_found_files '*.nix')
}

eval_darwin() {
  local enable_casks
  enable_casks="$1"

  info "Evaluating nix-darwin system with Homebrew casks $enable_casks"
  env \
    NIX_DARWIN_HOSTNAME="${NIX_DARWIN_HOSTNAME:-ci-darwin}" \
    NIX_DARWIN_USER="${NIX_DARWIN_USER:-runner}" \
    NIX_DARWIN_HOME="${NIX_DARWIN_HOME:-/Users/${NIX_DARWIN_USER:-runner}}" \
    NIX_DARWIN_ENABLE_HOMEBREW_CASKS="$enable_casks" \
    nix "${NIX_FLAGS[@]}" eval --impure \
      ".#darwinConfigurations.${NIX_DARWIN_HOSTNAME:-ci-darwin}.system.drvPath" >/dev/null
}

eval_home_linux() {
  info "Evaluating Linux Home Manager activation package"
  env \
    HOME_MANAGER_USER="${HOME_MANAGER_USER:-runner}" \
    HOME_MANAGER_HOME="${HOME_MANAGER_HOME:-/home/${HOME_MANAGER_USER:-runner}}" \
    HOME_MANAGER_SYSTEM="${HOME_MANAGER_SYSTEM:-x86_64-linux}" \
    HOME_MANAGER_CONFIG="${HOME_MANAGER_CONFIG:-ci-linux}" \
    nix "${NIX_FLAGS[@]}" eval --impure \
      "./home#homeConfigurations.${HOME_MANAGER_CONFIG:-ci-linux}.activationPackage.drvPath" >/dev/null
}

run_eval() {
  require_nix
  load_env_file
  ensure_env_file
  check_shell_syntax
  check_nix_syntax
  eval_darwin false
  eval_darwin true
  eval_home_linux
}

run_pre_commit() {
  if ! git diff --quiet; then
    die "tracked unstaged changes exist. Stage or revert them before committing."
  fi

  NIX_FLAGS+=(--no-warn-dirty)
  run_eval
}

build_darwin() {
  load_env_file
  ensure_env_file

  info "Building nix-darwin system"
  env \
    NIX_DARWIN_HOSTNAME="${NIX_DARWIN_HOSTNAME:-ci-darwin}" \
    NIX_DARWIN_USER="${NIX_DARWIN_USER:-runner}" \
    NIX_DARWIN_HOME="${NIX_DARWIN_HOME:-/Users/${NIX_DARWIN_USER:-runner}}" \
    NIX_DARWIN_ENABLE_HOMEBREW_CASKS="${NIX_DARWIN_ENABLE_HOMEBREW_CASKS:-false}" \
    nix "${NIX_FLAGS[@]}" build --impure --no-link \
      ".#darwinConfigurations.${NIX_DARWIN_HOSTNAME:-ci-darwin}.system"
}

build_home_linux() {
  local user home config system
  load_env_file
  ensure_env_file
  user="${HOME_MANAGER_USER:-${NIX_DARWIN_USER:-runner}}"
  home="${HOME_MANAGER_HOME:-/home/$user}"
  config="${HOME_MANAGER_CONFIG:-ci-linux}"
  system="${HOME_MANAGER_SYSTEM:-x86_64-linux}"

  info "Building Linux Home Manager activation package"
  env \
    HOME_MANAGER_USER="$user" \
    HOME_MANAGER_HOME="$home" \
    HOME_MANAGER_SYSTEM="$system" \
    HOME_MANAGER_CONFIG="$config" \
    nix "${NIX_FLAGS[@]}" build --impure --no-link \
      "./home#homeConfigurations.${config}.activationPackage"
}

main() {
  local command
  command="${1:-}"

  if [ -z "$command" ] || [ "$command" = "-h" ] || [ "$command" = "--help" ]; then
    usage
    exit 0
  fi

  REPO_ROOT="$(repo_root)"
  cd -- "$REPO_ROOT"
  NIX_FLAGS=(--extra-experimental-features "nix-command flakes" --accept-flake-config)

  case "$command" in
    eval)
      run_eval
      ;;
    pre-commit)
      run_pre_commit
      ;;
    build-darwin)
      require_nix
      build_darwin
      ;;
    build-home-linux)
      require_nix
      build_home_linux
      ;;
    *)
      usage >&2
      die "unknown command: $command"
      ;;
  esac
}

main "$@"
