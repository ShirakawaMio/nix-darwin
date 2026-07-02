{ ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.accept-flake-config = true;
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = 6;
}
