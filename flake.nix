{
  description = "Mio nix-darwin configuration";

  nixConfig = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
    pure-eval = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    ...
  }:
  let
    lib = nixpkgs.lib;
    envFile = /etc/nix-darwin/.env;
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

    boolEnvOr = name: fallback:
      let
        value = envOr name fallback;
      in
      if value == "true" then
        true
      else if value == "false" then
        false
      else
        throw "${name} must be 'true' or 'false'";

    hostName = envOr "NIX_DARWIN_HOSTNAME" "bootstrap";
    darwinUser = envOr "NIX_DARWIN_USER" "bootstrap";
    darwinHome = envOr "NIX_DARWIN_HOME" "/Users/${darwinUser}";
    enableHomebrewCasks = boolEnvOr "NIX_DARWIN_ENABLE_HOMEBREW_CASKS" "false";
  in {
    darwinConfigurations.${hostName} = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";

      specialArgs = {
        inherit inputs;
        systemUser = darwinUser;
      };

      modules = [
        ./darwin
        home-manager.darwinModules.home-manager
      ] ++ lib.optionals enableHomebrewCasks [
        ./darwin/modules/homebrew.nix
      ] ++ [
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = {
            inherit inputs;
          };
        }
        {
          nix.settings.trusted-users = [
            "root"
            darwinUser
          ];

          users.users.${darwinUser} = {
            name = darwinUser;
            home = darwinHome;
          };

          home-manager.users.${darwinUser} = {
            imports = [
              ./home/home.nix
              {
                home.username = darwinUser;
                home.homeDirectory = darwinHome;
              }
            ];
          };
        }
      ];
    };
  };
}
