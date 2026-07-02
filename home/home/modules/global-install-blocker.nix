{ config, pkgs, lib, ... }:

let
  blockedDir = "${config.home.homeDirectory}/.local/state/global-install-blocked";

  realBun = "${pkgs.bun}/bin/bun";
  realUv = "${pkgs.uv}/bin/uv";
  realBrew =
    if pkgs.stdenv.isAarch64 then
      "/opt/homebrew/bin/brew"
    else
      "/usr/local/bin/brew";

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
    real_brew="${realBrew}"

    if [ ! -x "$real_brew" ]; then
      echo "Blocked: Homebrew executable not found at $real_brew"
      exit 127
    fi

    case "$1" in
      install)
        shift

        allow_cask=0
        for arg in "$@"; do
          case "$arg" in
            --cask|--casks)
              allow_cask=1
              ;;
          esac
        done

        if [ "$allow_cask" -ne 1 ]; then
          echo "Blocked: brew formula installation is disabled."
          echo "Use 'brew install --cask <name>' for casks, or install CLI tools with Nix/Home Manager."
          exit 1
        fi

        exec "$real_brew" install "$@"
        ;;

      reinstall)
        shift

        allow_cask=0
        for arg in "$@"; do
          case "$arg" in
            --cask|--casks)
              allow_cask=1
              ;;
          esac
        done

        if [ "$allow_cask" -ne 1 ]; then
          echo "Blocked: brew formula reinstallation is disabled."
          echo "Use 'brew reinstall --cask <name>' for casks."
          exit 1
        fi

        exec "$real_brew" reinstall "$@"
        ;;

      upgrade)
        shift

        if [ "$#" -eq 0 ]; then
          echo "Blocked: unrestricted 'brew upgrade' is disabled."
          echo "Use 'brew upgrade --cask' or manage CLI tools with Nix/Home Manager."
          exit 1
        fi

        allow_cask=0
        for arg in "$@"; do
          case "$arg" in
            --cask|--casks)
              allow_cask=1
              ;;
          esac
        done

        if [ "$allow_cask" -ne 1 ]; then
          echo "Blocked: brew formula upgrade is disabled."
          echo "Use 'brew upgrade --cask' for casks."
          exit 1
        fi

        exec "$real_brew" upgrade "$@"
        ;;

      uninstall|remove|rm)
        shift

        allow_cask=0
        for arg in "$@"; do
          case "$arg" in
            --cask|--casks)
              allow_cask=1
              ;;
          esac
        done

        if [ "$allow_cask" -ne 1 ]; then
          echo "Blocked: brew formula uninstall is disabled through this wrapper."
          echo "Use 'brew uninstall --cask <name>' for casks."
          exit 1
        fi

        exec "$real_brew" uninstall "$@"
        ;;

      tap)
        echo "Blocked: 'brew tap' is disabled."
        echo "Manage taps manually only when needed, or use Nix/Home Manager for CLI tools."
        exit 1
        ;;

      bundle)
        echo "Blocked: 'brew bundle' is disabled because it may install formulae."
        echo "Use explicit 'brew install --cask <name>' commands instead."
        exit 1
        ;;

      *)
        exec "$real_brew" "$@"
        ;;
    esac
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
