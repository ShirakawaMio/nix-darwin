#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/boot.sh [options]

Bootstrap a macOS machine from this nix-darwin flake.

Options:
  --hostname NAME         Host flake output and generated hosts/<name>.nix.
                          Default: macOS LocalHostName or hostname -s
  --target-dir PATH       Canonical config path to sync this repo into.
                          Default: /etc/nix-darwin
  --user NAME             macOS user managed by the generated host module.
                          Default: current user
  --home PATH             Home directory for --user.
                          Default: current $HOME
  --install-nix           Install Nix first when it is missing.
  --install-homebrew      Install Homebrew first when it is missing.
  --no-sync               Do not copy this checkout into --target-dir.
  --force-sync            Allow replacing files in --target-dir with rsync.
  --check-only            Generate host config, check, and build, but do not switch.
  -h, --help              Show this help.

Environment overrides:
  NIX_DARWIN_HOSTNAME, TARGET_DIR, TARGET_USER, TARGET_HOME

The script itself does not install normal packages globally. Nix and Homebrew
bootstrap are explicit opt-ins because the darwin config depends on Nix and
declares Homebrew casks.
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '==> %s\n' "$*"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

script_dir() {
  local src
  src="${BASH_SOURCE[0]}"
  cd -- "$(dirname -- "$src")" >/dev/null 2>&1
  pwd -P
}

canonical_path() {
  local path
  path="$1"

  if [ -e "$path" ]; then
    cd -- "$path" >/dev/null 2>&1
    pwd -P
    return
  fi

  cd -- "$(dirname -- "$path")" >/dev/null 2>&1
  printf '%s/%s\n' "$(pwd -P)" "$(basename -- "$path")"
}

has_files() {
  local dir
  dir="$1"

  [ -d "$dir" ] || return 1
  find "$dir" -mindepth 1 -maxdepth 1 -print -quit | grep -q .
}

sanitize_hostname() {
  local sanitized
  sanitized="$(printf '%s' "$1" | tr -c '[:alnum:]_-' '-')"
  sanitized="${sanitized##-}"
  sanitized="${sanitized%%-}"

  [ -n "$sanitized" ] || die "hostname is empty after sanitizing"
  printf '%s\n' "$sanitized"
}

detect_hostname() {
  local name
  name=""

  if command_exists scutil; then
    name="$(scutil --get LocalHostName 2>/dev/null || true)"
  fi

  if [ -z "$name" ]; then
    name="$(hostname -s 2>/dev/null || hostname)"
  fi

  sanitize_hostname "$name"
}

nix_string_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\${/\\${/g'
}

load_nix_profile() {
  if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    set +u
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    set -u
  fi
}

find_nix() {
  if command_exists nix; then
    command -v nix
    return
  fi

  if [ -x /nix/var/nix/profiles/default/bin/nix ]; then
    printf '%s\n' /nix/var/nix/profiles/default/bin/nix
    return
  fi

  return 1
}

install_nix() {
  command_exists curl || die "curl is required to install Nix"
  info "Installing Nix with the official macOS installer"
  curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
  load_nix_profile
}

find_homebrew() {
  local brew_path

  if [ -x /opt/homebrew/bin/brew ]; then
    printf '%s\n' /opt/homebrew/bin/brew
    return
  fi

  if [ -x /usr/local/bin/brew ]; then
    printf '%s\n' /usr/local/bin/brew
    return
  fi

  if command_exists brew; then
    brew_path="$(command -v brew)"
    case "$brew_path" in
      /nix/store/*|/etc/profiles/*|/run/current-system/*)
        return 1
        ;;
      *)
        printf '%s\n' "$brew_path"
        return
        ;;
    esac
  fi

  return 1
}

install_homebrew() {
  command_exists curl || die "curl is required to install Homebrew"
  info "Installing Homebrew because brew.nix declares Homebrew casks"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

sync_repo() {
  local source_root target_dir source_real target_real
  source_root="$1"
  target_dir="$2"
  source_real="$(canonical_path "$source_root")"
  target_real="$(canonical_path "$target_dir")"

  if [ "$source_real" = "$target_real" ]; then
    printf '%s\n' "$source_real"
    return
  fi

  info "Syncing checkout to $target_dir"
  sudo mkdir -p "$target_dir"
  sudo chown "$(id -un):$(id -gn)" "$target_dir"

  if has_files "$target_dir" && [ "$FORCE_SYNC" -ne 1 ]; then
    die "$target_dir is not empty. Re-run with --force-sync after reviewing it, or use --no-sync."
  fi

  if [ "$FORCE_SYNC" -eq 1 ]; then
    rsync -a --delete --exclude result --exclude hosts "$source_root"/ "$target_dir"/
  else
    rsync -a --exclude result --exclude hosts "$source_root"/ "$target_dir"/
  fi

  canonical_path "$target_dir"
}

ensure_hosts_git() {
  local hosts_dir
  hosts_dir="$1"

  command_exists git || die "git is required to manage hosts as a nested repo"
  mkdir -p "$hosts_dir"

  if [ ! -d "$hosts_dir/.git" ]; then
    info "Initializing nested hosts git repo"
    git -C "$hosts_dir" init
  fi

  if ! git -C "$hosts_dir" config user.name >/dev/null; then
    git -C "$hosts_dir" config user.name "nix-darwin bootstrap"
  fi

  if ! git -C "$hosts_dir" config user.email >/dev/null; then
    git -C "$hosts_dir" config user.email "nix-darwin-bootstrap@localhost"
  fi
}

generate_host_module() {
  local repo_root host_name user_name home_dir hosts_dir host_file
  local escaped_host escaped_user escaped_home
  repo_root="$1"
  host_name="$2"
  user_name="$3"
  home_dir="$4"
  hosts_dir="$repo_root/hosts"
  host_file="$hosts_dir/$host_name.nix"

  ensure_hosts_git "$hosts_dir"

  escaped_host="$(nix_string_escape "$host_name")"
  escaped_user="$(nix_string_escape "$user_name")"
  escaped_home="$(nix_string_escape "$home_dir")"

  cat > "$host_file" <<EOF
{ ... }:

{
  # Generated by scripts/boot.sh for ${escaped_host}.
  nix.settings.trusted-users = [
    "root"
    "${escaped_user}"
  ];

  users.users."${escaped_user}" = {
    name = "${escaped_user}";
    home = "${escaped_home}";
  };

  home-manager.users."${escaped_user}" = {
    imports = [
      ../home/home.nix
      {
        home.username = "${escaped_user}";
        home.homeDirectory = "${escaped_home}";
      }
    ];
  };
}
EOF

  git -C "$hosts_dir" add "$host_name.nix"
  if ! git -C "$hosts_dir" diff --cached --quiet; then
    git -C "$hosts_dir" commit -m "Update $host_name host config"
  fi

  printf '%s\n' "$host_file"
}

DETECTED_HOSTNAME="$(detect_hostname)"
HOST_NAME="${NIX_DARWIN_HOSTNAME:-${DARWIN_CONFIGURATION:-$DETECTED_HOSTNAME}}"
TARGET_DIR="${TARGET_DIR:-/etc/nix-darwin}"
TARGET_USER="${TARGET_USER:-$(id -un)}"
TARGET_HOME="${TARGET_HOME:-$HOME}"
INSTALL_NIX=0
INSTALL_HOMEBREW=0
SYNC_TO_TARGET=1
FORCE_SYNC=0
CHECK_ONLY=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --hostname|--configuration)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      HOST_NAME="$2"
      shift 2
      ;;
    --target-dir)
      [ "$#" -ge 2 ] || die "--target-dir requires a value"
      TARGET_DIR="$2"
      shift 2
      ;;
    --user)
      [ "$#" -ge 2 ] || die "--user requires a value"
      TARGET_USER="$2"
      shift 2
      ;;
    --home)
      [ "$#" -ge 2 ] || die "--home requires a value"
      TARGET_HOME="$2"
      shift 2
      ;;
    --install-nix)
      INSTALL_NIX=1
      shift
      ;;
    --install-homebrew)
      INSTALL_HOMEBREW=1
      shift
      ;;
    --no-sync)
      SYNC_TO_TARGET=0
      shift
      ;;
    --force-sync)
      FORCE_SYNC=1
      shift
      ;;
    --check-only)
      CHECK_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

HOST_NAME="$(sanitize_hostname "$HOST_NAME")"

[ "$(uname -s)" = "Darwin" ] || die "this bootstrap script only supports macOS"

if [ "$(id -u)" -eq 0 ]; then
  die "run this as the target user, not root"
fi

if [ "$(id -un)" != "$TARGET_USER" ]; then
  die "current user is $(id -un), but target user is $TARGET_USER. Login as $TARGET_USER or pass --user $(id -un)."
fi

if [ "$(uname -m)" != "arm64" ]; then
  die "this flake currently targets aarch64-darwin, but this machine is $(uname -m)"
fi

SCRIPT_DIR="$(script_dir)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"

if [ "$SYNC_TO_TARGET" -eq 1 ]; then
  REPO_ROOT="$(sync_repo "$REPO_ROOT" "$TARGET_DIR")"
fi

HOST_MODULE_FILE="$(generate_host_module "$REPO_ROOT" "$HOST_NAME" "$TARGET_USER" "$TARGET_HOME")"

load_nix_profile
if ! NIX_BIN="$(find_nix)"; then
  if [ "$INSTALL_NIX" -ne 1 ]; then
    die "Nix is not installed. Re-run with --install-nix, or install Nix first and run again."
  fi

  install_nix
  NIX_BIN="$(find_nix)" || die "Nix installer finished, but nix is still not on PATH"
fi

if ! find_homebrew >/dev/null 2>&1; then
  if [ "$INSTALL_HOMEBREW" -ne 1 ]; then
    die "Homebrew is not installed, but brew.nix declares casks. Re-run with --install-homebrew or install Homebrew first."
  fi

  install_homebrew
  find_homebrew >/dev/null 2>&1 || die "Homebrew installer finished, but brew was not found"
fi

export NIX_DARWIN_HOSTNAME="$HOST_NAME"
export NIX_DARWIN_HOST_MODULE="$HOST_MODULE_FILE"
export NIX_DARWIN_USER="$TARGET_USER"
export NIX_DARWIN_HOME="$TARGET_HOME"

NIX_FLAGS=(--extra-experimental-features "nix-command flakes")

info "Checking flake for host $HOST_NAME"
"$NIX_BIN" "${NIX_FLAGS[@]}" flake check --impure "$REPO_ROOT"

info "Building darwinConfigurations.${HOST_NAME}.system"
"$NIX_BIN" "${NIX_FLAGS[@]}" build --impure "$REPO_ROOT#darwinConfigurations.${HOST_NAME}.system"

if [ "$CHECK_ONLY" -eq 1 ]; then
  info "Check-only mode complete"
  exit 0
fi

info "Requesting sudo for nix-darwin activation"
sudo -v

info "Switching nix-darwin configuration $HOST_NAME"
sudo env \
  NIX_DARWIN_HOSTNAME="$HOST_NAME" \
  NIX_DARWIN_HOST_MODULE="$HOST_MODULE_FILE" \
  NIX_DARWIN_USER="$TARGET_USER" \
  NIX_DARWIN_HOME="$TARGET_HOME" \
  "$NIX_BIN" "${NIX_FLAGS[@]}" run --impure nix-darwin/master#darwin-rebuild -- switch --flake "$REPO_ROOT#$HOST_NAME" --impure

info "Bootstrap complete. Open a new shell to pick up Home Manager changes."
