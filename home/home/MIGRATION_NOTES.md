# Home Manager 迁移说明

## 暂不自动迁移

这些目录或文件可能含 token、会话、数据库、设备授权、二进制运行时，初始迁移没有复制：

- `~/.ssh`
- `~/.config/gh`
- `~/.config/clash`
- `~/.npmrc`
- `~/.claude.json`
- Anki 用户数据
- Hammerspoon 当前配置
- Karabiner 当前配置

Hammerspoon 和 Karabiner 是工作流关键配置，但它们依赖 macOS 辅助功能权限、Karabiner profile、Hammerspoon IPC，以及当前 `.hammerspoon/hs/libaxuielement.dylib` 这类本机文件。建议第二步单独迁移并验证。

## GUI 应用

Home Manager 不负责 Homebrew cask。`darwin-homebrew.nix` 是可选的 nix-darwin 模块草稿，保留了当前 Homebrew leaves、taps 和 casks。等 Home Manager 配置稳定后，可以再决定是否引入 nix-darwin 管理 GUI 应用和 Homebrew。

## 后续迁移建议

1. 先执行 `build`，处理 nixpkgs 包名缺口。
2. 再执行 `switch -b hm-backup`，让 Home Manager 接管 shell、git 和 XDG 快照。
3. 单独迁移 Hammerspoon/Karabiner，并在切换后验证窗口布局、输入法和 profile 切换。
4. 最后再决定是否迁移带凭据的服务配置；这类文件更适合用 `sops-nix`、`agenix`、1Password CLI 或手动恢复。
