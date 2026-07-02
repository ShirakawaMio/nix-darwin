{ config, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "ShirakawaMio";
        email = "abcgfsmile@gmail.com";
      };

      code.editor = "vim";
      init.defaultBranch = "main";
      core.excludesFile = "${config.home.homeDirectory}/.config/git/ignore";
    };
  };

  xdg.configFile."git/ignore".source = ../files/git/ignore;
}
