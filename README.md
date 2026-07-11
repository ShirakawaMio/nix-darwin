# nix-darwin
Mio's nix-darwin configuration

## 新设备复现

在新设备上可以直接运行：

```sh
sh <(curl -fsSL https://static.mio.cat/scripts/nix-darwin/install.sh) --install-nix --install-cask
```

Linux 不需要 Homebrew：

```sh
sh <(curl -fsSL https://static.mio.cat/scripts/nix-darwin/install.sh) --install-nix
```

安装器默认使用 `stable`。需要直接使用 `main` 时加 `--unstable`。

也可以先把仓库放到任意临时目录，然后运行：

```sh
./scripts/boot.sh --install-nix --install-cask
```

macOS 会按当前机器的 LocalHostName 和当前用户生成本地 `.env`，
再把主仓库同步到 `/etc/nix-darwin`，检查 flake，构建
`darwinConfigurations.<hostname>.system`，然后执行
`darwin-rebuild switch --flake /etc/nix-darwin#<hostname> --impure`。

macOS 的 `--install-cask` 会安装 Homebrew 并启用 `homebrew.nix` 管理
cask；如果跳过 cask/Homebrew，`homebrew.nix` 不会启用。
`--install-homebrew` 仅作为兼容旧命令的别名保留。

Linux 不会把整个 nix-darwin 仓库放进目标机器。安装器只把 `home/`
里的 standalone Home Manager 配置和配套脚本同步到
`~/.config/home-manager`，在该目录构建
`homeConfigurations.<user>.activationPackage`，然后激活用户环境。
首次安装时，脚本会为本次 Nix 调用显式启用 `nix-command flakes` 和
`accept-flake-config`，不依赖目标机器已有 Nix 配置。激活后，
Home Manager 会继续管理用户级 `~/.config/nix/nix.conf`，保持这些
Nix 默认行为。

后续在目标机器上可以直接使用标准 Home Manager 目录：

```sh
home-manager switch
```

也可以使用同步过去的脚本显式按 flake output 切换；该脚本会为本次命令启用
所需 Nix 选项，不需要先修改全局 Nix 配置：

```sh
~/.config/home-manager/scripts/switch.sh
```

如果已经装好 Nix 和 Homebrew，可以省略安装参数：

```sh
./scripts/boot.sh
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
并推送到 `stable`。这个 squash commit 的标题是自动生成的版本号：
`YYYY.MM.DD.N`，日期使用 UTC，`N` 是 GitHub Actions run number。

commit 正文会写入 `Change log since last update`。workflow 会根据上一次
`stable` commit 里的 `Squashed from <sha>` 找到上次发布的源提交，再调用
GitHub Models 生成中文详细 changelog；如果模型调用失败，会回退为普通
git log 列表并继续发布。

建议在 GitHub 上保护 `stable` 分支，只允许 GitHub Actions 或专用 bot
推送该分支。
