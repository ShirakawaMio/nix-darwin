{ inputs, ... }:

{
  imports = [
    ./modules/homebrew.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.accept-flake-config = true;
  nixpkgs.config.allowUnfree = true;

  nixpkgs.flake = {
      source = inputs.nixpkgs;
      setNixPath = true;
      setFlakeRegistry = true;
  };

  nix.nixPath = [
    "nixpkgs=flake:nixpkgs"
  ];

  system.stateVersion = 6;
}
