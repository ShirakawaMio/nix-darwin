{ ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/git.nix
    ./modules/xdg-configs.nix
    ./modules/global-install-blocker.nix
    ./modules/hammerspoon.nix
    ./modules/neovim.nix
    ./modules/yazi.nix
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "26.05";
}
