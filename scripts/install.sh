#!/bin/sh
set -eu

repo_owner="${BOOT_REPO_OWNER:-ShirakawaMio}"
repo_name="${BOOT_REPO_NAME:-nix-darwin}"
ref="${BOOT_REF:-main}"
archive_url="${BOOT_ARCHIVE_URL:-https://github.com/$repo_owner/$repo_name/archive/refs/heads/$ref.tar.gz}"

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

command_exists curl || die "curl is required"
command_exists tar || die "tar is required"
command_exists mktemp || die "mktemp is required"
command_exists bash || die "bash is required"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT HUP INT TERM

info "Downloading $repo_owner/$repo_name@$ref"
curl -fsSL "$archive_url" | tar -xzf - -C "$tmp_dir"

checkout_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | sed -n '1p')"
[ -n "$checkout_dir" ] || die "downloaded archive did not contain a checkout"

cd "$checkout_dir"
if [ "${1:-}" = "ci-check" ]; then
  shift
  exec bash ./scripts/ci-check.sh "$@"
fi

exec bash ./scripts/boot.sh "$@"
