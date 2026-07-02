# nix-darwin
Mio's nix-darwin configuration

## 新设备复现

在新设备上先把仓库放到任意临时目录，然后运行：

```sh
./scripts/boot.sh --install-nix --install-homebrew
```

macOS 会按当前机器的 LocalHostName 和当前用户生成本地 `.env`，
再把主仓库同步到 `/etc/nix-darwin`，检查 flake，构建
`darwinConfigurations.<hostname>.system`，然后执行
`darwin-rebuild switch --flake /etc/nix-darwin#<hostname> --impure`。

Linux 会把主仓库同步到 `~/.config/nix-home`，用 `home/flake.nix`
生成当前用户的 standalone Home Manager 配置，构建
`homeConfigurations.<user>.activationPackage`，然后激活用户环境。

如果已经装好 Nix 和 Homebrew，可以省略安装参数：

```sh
./scripts/boot.sh
```

Linux 不需要 Homebrew：

```sh
./scripts/boot.sh --install-nix
```

只验证不切换：

```sh
./scripts/boot.sh --check-only
```

## 提交检查

安装本仓库的 Git hook：

```sh
./scripts/install-hooks.sh
```

`pre-commit` 只做快速检查：shell 语法、Nix 语法、nix-darwin eval、
standalone Home Manager eval。hook 会拒绝 tracked unstaged changes，
确保检查内容和即将提交的 staged 内容一致。

脚本读取 `.env` 中的本机 host/user/home 配置；如果缺少必要内容会自动
补齐。`.env` 已加入 `.gitignore`，不会进入提交。

因为 `.env` 是 ignored 的本机文件，裸 `sudo darwin-rebuild switch`
无法在纯 flake eval 中读取它。请使用 `./scripts/boot.sh`，或显式运行：

```sh
sudo darwin-rebuild switch --flake /etc/nix-darwin#$(. /etc/nix-darwin/.env; printf '%s' "$NIX_DARWIN_HOSTNAME") --impure
```

也可以手动运行：

```sh
./scripts/ci-check.sh eval
```

## 稳定分支

`stable` 是稳定版本分支，不直接人工提交。需要发布稳定版本时，在
GitHub Actions 手动运行 `Promote stable` workflow，选择要发布的
`source_ref`。

workflow 会先构建候选版本：

- Linux standalone Home Manager activation package
- macOS nix-darwin system

两个 build 都通过后，workflow 才会把候选 tree squash 成一个 commit
并推送到 `stable`。

建议在 GitHub 上保护 `stable` 分支，只允许 GitHub Actions 或专用 bot
推送该分支。
