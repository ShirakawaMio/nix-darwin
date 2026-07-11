{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    package = pkgs.yazi;

    plugins = {
      smart-enter = pkgs.yaziPlugins.smart-enter;
      smart-filter = pkgs.yaziPlugins.smart-filter;
      git = pkgs.yaziPlugins.git;
      chmod = pkgs.yaziPlugins.chmod;
      mount = pkgs.yaziPlugins.mount;
    };

    flavors = {
    };

    initLua = ''
      require("git"):setup()
    '';

    keymap = {
      input.prepend_keymap = [
      ];
      mgr.prepend_keymap = [
        { run = "plugin chmod"; on = [ "c" "m"]; } # chmod on selected files
        { run = "plugin smart-enter"; on = [ "l" ]; }
        { run = "plugin smart-filter"; on = [ "F" ]; }
        { run = "plugin mount"; on = [ "M" ]; }
      ];
    };

    settings = {
    };
  };
}
