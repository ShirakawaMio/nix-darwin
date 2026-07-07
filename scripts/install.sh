#!/bin/sh
set -eu

repo_owner="${BOOT_REPO_OWNER:-ShirakawaMio}"
repo_name="${BOOT_REPO_NAME:-nix-darwin}"
unstable=0

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

arg_count=$#
while [ "$arg_count" -gt 0 ]; do
  arg="$1"
  shift
  case "$arg" in
    --unstable)
      unstable=1
      ;;
    *)
      set -- "$@" "$arg"
      ;;
  esac
  arg_count=$((arg_count - 1))
done

if [ -n "${BOOT_ARCHIVE_URL:-}" ]; then
  ref="${BOOT_REF:-custom}"
  archive_url="$BOOT_ARCHIVE_URL"
elif [ -n "${BOOT_REF:-}" ]; then
  ref="$BOOT_REF"
  archive_url="https://github.com/$repo_owner/$repo_name/archive/refs/heads/$ref.tar.gz"
elif [ "$unstable" -eq 1 ]; then
  ref="main"
  archive_url="https://github.com/$repo_owner/$repo_name/archive/refs/heads/$ref.tar.gz"
else
  ref="stable"
  if [ -t 0 ]; then
    printf 'Install channel [stable/unstable] (default: stable): ' >&2
    IFS= read -r channel || channel=
    case "$channel" in
      unstable|main|u|U)
        ref="main"
        ;;
      stable|s|S|"")
        ref="stable"
        ;;
      *)
        die "unknown install channel: $channel"
        ;;
    esac
  fi
  archive_url="https://github.com/$repo_owner/$repo_name/archive/refs/heads/$ref.tar.gz"
fi

command_exists curl || die "curl is required"
command_exists tar || die "tar is required"
command_exists mktemp || die "mktemp is required"
command_exists bash || die "bash is required"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT HUP INT TERM

run_and_exit() {
  set +e
  bash "$@"
  status=$?
  set -e
  cleanup
  trap - EXIT HUP INT TERM
  exit "$status"
}

info "Downloading $repo_owner/$repo_name@$ref"
curl -fsSL "$archive_url" | tar -xzf - -C "$tmp_dir"

checkout_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | sed -n '1p')"
[ -n "$checkout_dir" ] || die "downloaded archive did not contain a checkout"

cd "$checkout_dir"
if [ "${1:-}" = "ci-check" ]; then
  shift
  run_and_exit ./scripts/ci-check.sh "$@"
fi

run_and_exit ./scripts/boot.sh "$@"
