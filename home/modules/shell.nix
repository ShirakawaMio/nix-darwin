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

  home.sessionPath = [
  ];

  programs.zsh = {

    dotDir = config.home.homeDirectory;

    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "fzf"
      ];
    };

    shellAliases = {
      zshconfig = "$EDITOR ~/.zshrc";
      ll = "ls -lah";
    };

    profileExtra = ''
      if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || true
    '';

    initContent = ''
      zstyle ':completion:*' matcher-list \
        'm:{a-z0-9}={A-Z0-9}' \
        'r:|[._-]=* r:|=*' \
        'l:|=* r:|=*'

      y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if [ -s "$tmp" ]; then
          local dir="$(cat "$tmp")"
          rm -f "$tmp"
          if command -v zoxide >/dev/null; then
            z "$dir"
          else
            cd "$dir"
          fi
        fi
      }
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ../files/starship.toml);
  };
}
