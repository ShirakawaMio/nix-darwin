{ ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/git.nix
    ./modules/xdg-configs.nix
    ./modules/global-install-blocker.nix
  ];

  home.username = "mio";
  home.homeDirectory = "/Users/mio";

  programs.home-manager.enable = true;
  home.stateVersion = "26.05";
}
