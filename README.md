# nix-darwin
Mio's nix-darwin configuration

## 新设备复现

在新 Mac 上先把仓库放到任意临时目录，然后运行：

```sh
./scripts/bootstrap-new-device.sh --install-nix --install-homebrew
```

脚本会把仓库同步到 `/etc/nix-darwin`，检查 flake，构建
`darwinConfigurations.Mios-MacBook-Air.system`，然后执行
`darwin-rebuild switch --flake /etc/nix-darwin#Mios-MacBook-Air`。

如果已经装好 Nix 和 Homebrew，可以省略安装参数：

```sh
./scripts/bootstrap-new-device.sh
```

只验证不切换：

```sh
./scripts/bootstrap-new-device.sh --check-only
```
