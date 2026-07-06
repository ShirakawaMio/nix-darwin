{ ... }:

{
  xdg.enable = true;

  xdg.configFile = {
    "ghostty/config".source = ../files/ghostty/config.ghostty;
    "karabiner".source = ../files/karabiner;
    "nvim".source = ../files/nvim;
  };
}
