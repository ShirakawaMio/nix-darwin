{ lib, pkgs, ... }:

let
  maybePackage = attrPath:
    let
      parts = lib.splitString "." attrPath;
    in
    if lib.hasAttrByPath parts pkgs then
      [ (lib.getAttrFromPath parts pkgs) ]
    else
      lib.warn "home.packages: package `${attrPath}` not found in pkgs, skipping it" [ ];
  maybePackages = names:
    lib.flatten (map maybePackage names);
in
{
  home.packages = maybePackages [
    "bat"
    "bun"
    "cloudflared"
    "codex"
    "docker"
    "ffmpeg"
    "fzf"
    "gh"
    "git"
    "htop"
    "p7zip"
    "rename"
    "ripgrep"
    "starship"
    "tree"
    "unzip"
    "uv"
    "w3m"
    "zoxide"
    "zsh-syntax-highlighting"
  ];
}
