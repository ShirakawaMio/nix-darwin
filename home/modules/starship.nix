{ ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ../files/starship.toml);
  };
}
