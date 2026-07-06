{ ... }:

{
  xdg.enable = true;

  xdg.configFile = {
    "ghostty/config".source = ../files/ghostty/config.ghostty;
    "htop/htoprc".source = ../files/htop/htoprc;
    "karabiner".source = ../files/karabiner;
    "nvim".source = ../files/nvim;
  };
}
