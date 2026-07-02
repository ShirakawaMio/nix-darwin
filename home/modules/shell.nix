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

      alt-tab = "open -a \"AltTab\"";
      telegram = "open -a \"Telegram\"";
      tencent-lemon = "open -a \"Tencent Lemon\"";
      clash = "open -a \"Clash Verge\"";
      chrome = "open -a \"Google Chrome Canary\"";
      hammerspoon = "open -a \"Hammerspoon\"";
      pdf-expert = "open -a \"PDF Expert\"";
      homerow = "open -a \"Homerow\"";
      vivaldi = "open -a \"Vivaldi\"";
      karabiner = "open -a \"Karabiner-Elements\"";
      steam = "open -a \"Steam\"";
      whatsapp = "open -a \"WhatsApp\"";
      iphone = "open -a \"iPhone Mirroring\"";
      notes = "open -a \"Notes\"";
      wechat = "open -a \"WeChat\"";
      reminder = "open -a \"Reminders\"";
      calendar = "open -a \"Calendar\"";
      mail = "open -a \"Mail\"";
      cisco = "open -a \"Cisco Secure Client\"";
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
