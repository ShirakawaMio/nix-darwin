{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;

    # make copilot happy
    withNodeJs = true;
    extraPackages = with pkgs; [
      nodejs_22
      curl
    ];
  };
}

