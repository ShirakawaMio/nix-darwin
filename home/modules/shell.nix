{ config, ... }:

let
  home = config.home.homeDirectory;
in
{
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    YAZI_CONFIG_HOME = "${home}/.config/yazi";
  };

  home.sessionPath = [ ];
}
