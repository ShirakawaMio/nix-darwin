{ ... }:

{
  xdg.enable = true;

  xdg.configFile = {
    "ghostty/config".source = ../files/ghostty/config.ghostty;
    "yazi/keymap.toml".source = ../files/yazi/keymap.toml;
    "yazi/init.lua".source = ../files/yazi/init.lua;
    "htop/htoprc".source = ../files/htop/htoprc;
    "nvim".source = ../files/nvim;
  };
}
