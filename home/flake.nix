{
  description = ''Mio Home Manager configuration'';

  inputs = {
    nixpkgs.url = ''github:NixOS/nixpkgs/nixpkgs-unstable'';

    home-manager = {
      url = ''github:nix-community/home-manager'';
      inputs.nixpkgs.follows = ''nixpkgs'';
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
  let
    username = ''mio'';

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
  in {
    homeConfigurations.mio-linux = home-manager.lib.homeManagerConfiguration {
      pkgs = mkPkgs ''x86_64-linux'';

      modules = [
        ./home.nix
        {
          home.username = username;
          home.homeDirectory = ''/home/${username}'';
        }
      ];
    };

    homeConfigurations.mio-darwin = home-manager.lib.homeManagerConfiguration {
      pkgs = mkPkgs ''aarch64-darwin'';

      modules = [
        ./home.nix
        {
          home.username = username;
          home.homeDirectory = ''/Users/${username}'';
        }
      ];
    };
  };
}