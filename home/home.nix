{ ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/nix.nix
    ./modules/shell.nix
    ./modules/zsh.nix
    ./modules/fzf.nix
    ./modules/zoxide.nix
    ./modules/starship.nix
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
