{ systemUser, ... }:

{
  system.primaryUser = systemUser;
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
    };

    taps = [
    ];

    casks = [
      "anki"
      "codex-app"
      "hammerspoon"
      "parallels"
      "telegram"
      "cc-switch"
      "dockdoor"
      "homerow"
      "pdf-expert"
      "tencent-lemon"
      "chatgpt"
      "font-symbols-only-nerd-font"
      "karabiner-elements"
      "prince"
      "visual-studio-code"
      "clash-verge-rev"
      "ghostty"
      "keka"
      "raycast"
      "vivaldi"
      "google-chrome@canary"
      "orbstack"
      "steam"
      "whatsapp"
    ];
  };
}
