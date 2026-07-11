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
      "chatgpt"
      "hammerspoon"
      "parallels"
      "telegram"
      "cc-switch"
      "dockdoor"
      "homerow"
      "pdf-expert"
      "tencent-lemon"
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
