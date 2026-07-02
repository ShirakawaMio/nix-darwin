{
  description = "Mio nix-darwin configuration";

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
    envOr = name: fallback:
      let
        value = builtins.getEnv name;
      in
      if value == "" then fallback else value;

    hostName = envOr "NIX_DARWIN_HOSTNAME" "bootstrap";
    hostModulePath = builtins.getEnv "NIX_DARWIN_HOST_MODULE";
    hostModules =
      if hostModulePath == "" then
        []
      else
        [ (/. + hostModulePath) ];
  in {
    darwinConfigurations.${hostName} = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";

      specialArgs = {
        inherit inputs;
      };

      modules = [
        ./configuration.nix
        ./brew.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = {
            inherit inputs;
          };
        }
      ] ++ hostModules;
    };
  };
}
