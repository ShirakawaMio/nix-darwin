{
  description = ''Mio Home Manager configuration'';

  nixConfig = {
    extra-experimental-features = [
      ''nix-command''
      ''flakes''
    ];
    pure-eval = false;
  };

  inputs = {
    nixpkgs.url = ''github:NixOS/nixpkgs/nixpkgs-unstable'';

    home-manager = {
      url = ''github:nix-community/home-manager'';
      inputs.nixpkgs.follows = ''nixpkgs'';
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
  let
    lib = nixpkgs.lib;
    envFile = ./.env;
    envFileValues =
      if builtins.pathExists envFile then
        let
          parseLine = line:
            let
              match = builtins.match "([A-Za-z_][A-Za-z0-9_]*)='?([^']*)'?" line;
            in
            if match == null then
              null
            else
              {
                name = builtins.elemAt match 0;
                value = builtins.elemAt match 1;
              };
          parsed = builtins.filter (value: value != null)
            (map parseLine (lib.splitString "\n" (builtins.readFile envFile)));
        in
        builtins.listToAttrs parsed
      else
        {};

    fileOr = name: fallback:
      if builtins.hasAttr name envFileValues then
        builtins.getAttr name envFileValues
      else
        fallback;

    envOr = name: fallback:
      let
        value = builtins.getEnv name;
      in
      if value == "" then fileOr name fallback else value;

    defaultUsername = "mio";
    defaultHomeDirectory = "/home/${defaultUsername}";
    defaultSystem = "x86_64-linux";

    username = envOr "HOME_MANAGER_USER" (envOr "NIX_DARWIN_USER" defaultUsername);
    homeDirectory = envOr "HOME_MANAGER_HOME" (envOr "NIX_DARWIN_HOME" "/home/${username}");
    system = envOr "HOME_MANAGER_SYSTEM" defaultSystem;
    configName = envOr "HOME_MANAGER_CONFIG" username;

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

    mkHomeConfiguration = username: homeDirectory: system:
      home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs system;

        modules = [
          ./home.nix
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
          }
        ];
      };
  in {
    homeConfigurations = {
      ${defaultUsername} = mkHomeConfiguration defaultUsername defaultHomeDirectory defaultSystem;
    } // lib.optionalAttrs (configName != defaultUsername) {
      ${configName} = mkHomeConfiguration username homeDirectory system;
    };
  };
}
