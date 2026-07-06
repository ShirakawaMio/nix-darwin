{ ... }:

{
  xdg.enable = true;

  xdg.configFile = {
    "ghostty/config".source = ../files/ghostty/config.ghostty;
    "htop/htoprc".source = ../files/htop/htoprc;
    "nvim".source = ../files/nvim;
  };
}
