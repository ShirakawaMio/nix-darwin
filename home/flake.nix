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
    envOr = name: fallback:
      let
        value = builtins.getEnv name;
      in
      if value == "" then fallback else value;

    username = envOr "HOME_MANAGER_USER" "user";
    homeDirectory = envOr "HOME_MANAGER_HOME" "/home/${username}";
    system = envOr "HOME_MANAGER_SYSTEM" "x86_64-linux";
    configName = envOr "HOME_MANAGER_CONFIG" username;

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
  in {
    homeConfigurations.${configName} = home-manager.lib.homeManagerConfiguration {
      pkgs = mkPkgs system;

      modules = [
        ./home.nix
        {
          home.username = username;
          home.homeDirectory = homeDirectory;
        }
      ];
    };
  };
}
