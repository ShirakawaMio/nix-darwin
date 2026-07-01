{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "mio" ];
  nixpkgs.config.allowUnfree = true;

  users.users.mio = {
    name = "mio";
    home = "/Users/mio";
  };

  system.stateVersion = 6;
}
