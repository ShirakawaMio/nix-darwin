{ config, pkgs, lib, ... }:

let
  blockedDir = "${config.home.homeDirectory}/.local/state/global-install-blocked";

  realBun = "${pkgs.bun}/bin/bun";
  realUv = "${pkgs.uv}/bin/uv";

  bunBlocker = pkgs.writeShellScriptBin "bun" ''
    if [ "$1" = "install" ] || [ "$1" = "add" ]; then
      for arg in "$@"; do
        case "$arg" in
          -g|--global)
            echo 'Blocked: global bun install is disabled.'
            echo 'Use project dependencies or bunx instead.'
            exit 1
            ;;
        esac
      done
    fi

    if [ "$1" = "pm" ] && [ "$2" = "trust" ]; then
      for arg in "$@"; do
        case "$arg" in
          -g|--global)
            echo 'Blocked: global bun trust is disabled.'
            exit 1
            ;;
        esac
      done
    fi

    exec ${realBun} "$@"
  '';

  uvBlocker = pkgs.writeShellScriptBin "uv" ''
    if [ "$1" = "tool" ]; then
      case "$2" in
        install|upgrade|update-shell)
          echo "Blocked: uv global tool management is disabled."
          echo "Use uvx or uv add --dev instead."
          exit 1
          ;;
      esac
    fi

    exec ${realUv} "$@"
  '';

  brewBlocker = pkgs.writeShellScriptBin "brew" ''
    echo "Blocked: Homebrew is disabled on this system."
    echo "Use Nix, nix-darwin, or Home Manager instead."
    exit 1
  '';

in
{
  home.packages = [
    (lib.hiPrio bunBlocker)
    (lib.hiPrio uvBlocker)
    (lib.hiPrio brewBlocker)
  ];

  home.sessionVariables = {
    BUN_INSTALL = "${blockedDir}/bun";
    UV_TOOL_DIR = "${blockedDir}/uv/tools";
    UV_TOOL_BIN_DIR = "${blockedDir}/uv/bin";
  };

  home.activation.blockGlobalInstallDirs =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${blockedDir}"
      chmod 500 "${blockedDir}"
    '';
}