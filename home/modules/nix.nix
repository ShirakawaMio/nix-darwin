{ ... }:

{
  xdg.configFile."nix/nix.conf".text = ''
    extra-experimental-features = nix-command flakes
    accept-flake-config = true
  '';
}
