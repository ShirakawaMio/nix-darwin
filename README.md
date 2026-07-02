# nix-darwin
Mio's nix-darwin configuration

## 新设备复现

在新 Mac 上先把仓库放到任意临时目录，然后运行：

```sh
./scripts/boot.sh --install-nix --install-homebrew
```

脚本会按当前机器的 LocalHostName 和当前用户生成
`hosts/<hostname>.nix`，把 `hosts/` 初始化为独立的本地 Git 仓库，
再把主仓库同步到 `/etc/nix-darwin`，检查 flake，构建
`darwinConfigurations.<hostname>.system`，然后执行
`darwin-rebuild switch --flake /etc/nix-darwin#<hostname>`。

如果已经装好 Nix 和 Homebrew，可以省略安装参数：

```sh
./scripts/boot.sh
```

只验证不切换：

```sh
./scripts/boot.sh --check-only
```
