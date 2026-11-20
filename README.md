# dotfiles

用 [chezmoi](https://www.chezmoi.io/) 管理的个人配置。同一套源，铺在：

| 机器 | 系统 | 桌面 |
|---|---|---|
| 主机 | Fedora 44 Workstation | niri + DMS，fcitx5 + Rime（白霜拼音） |
| 副机 | Windows | scoop |

跨机差异全部交给模板（`.tmpl`）和 `.chezmoiignore` 里的 `chezmoi.os` 判断，不维护多份分支。

---

## 新机器：三步起来

### 1. 先装 chezmoi 本体

仓库不负责自举——得先有 chezmoi 才能读仓库：

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/bin"
```

装到 `~/bin`。`~/bin` 和 `~/.local/bin` 已经在 `dot_config/fish/conf.d/user-path.fish` 里进了 PATH；
bash 侧靠发行版默认的 `.bashrc`（本仓库不托管 `.bashrc` 顶层文件）。

### 2. 拉下来应用

```sh
~/bin/chezmoi init --apply NayamiOR/dotfiles
```

会同时跑安装脚本：

- **Linux**（`run_onchange_install-packages.sh`）：dnf/pacman/apt 装基础包 → rustup（rsproxy 镜像）→
  pnpm → jj → fcitx5 + Rime → uv + Python 3.12 → fish 设为登录 shell → pi →
  linuxbrew（`NONINTERACTIVE`，GitHub 直连失败退 gh-proxy）→ brew 的 node → dsh
- **Windows**（`run_onchange_install-tools.ps1`）：scoop → git / nodejs-lts / neovim / jj / pnpm /
  rustup / uv / Python 3.12 / pi

### 3. 在图形会话里再 apply 一次

`run_onchange_after_20-dsh-service.sh` 负责把 dsh web 设成开机自启，它依赖 `systemctl --user`。
刚 ssh 上去、还没有用户级 systemd 时脚本会静默跳过，所以第一次登录桌面后再跑一次：

```sh
chezmoi apply
# 或者直接：systemctl --user enable --now dsh-web.service
```

---

## 结构约定

| 前缀 / 文件 | 含义 |
|---|---|
| `dot_xxx` | 落地成 `~/.xxx` |
| `private_xxx` | 落地权限 0600 / 目录 0700（`.dsh`、fcitx5 的 profile 等） |
| `executable_xxx` | 保留可执行位 |
| `xxx.tmpl` | Go 模板，按 `chezmoi.os` / `.name` 等渲染 |
| `.chezmoidata.toml` | 四台机器共用、无需询问的值（name / email） |
| `.chezmoiignore` | 按 OS 排除目标（非 Linux 排除 `.config/niri`、`.Xresources`、`.config/systemd` 等） |
| `run_onchange_xxx.sh` | 内容一变就重跑（装包、拉资产） |
| `run_onchange_after_xxx.sh` | 同上，但在所有文件落地之后跑（开机自启、Rime 资产） |

---

## 故意不同步的东西

| 东西 | 原因 |
|---|---|
| Rime 词库 + 语法模型（约 480 MB） | 由 `run_onchange_after_10-rime-frost.sh` 按需拉取，带多镜像回退 |
| 字体（约 420 MB） | 同上，体量不适合进 git |
| DMS 生成物：`niri/dms/*.kdl`、`gtk-*/dank-colors.css`、`ghostty/themes/dankcolors`、`alacritty/dank-theme.toml`、`zed/themes/dank-zed-theme.json` | 文件头写着 `DO NOT EDIT / AUTO-GENERATED`，唯一真源是 `dot_config/dms/settings.json` |
| 凭据：`.ssh/`、`.config/gh/hosts.yml`、`.pi/agent/auth.json`、`.dsh/.credentials.yaml` | 仓库是公开的，没有加密通道就不入库 |
| `.local/state`、VS Code 的 `globalStorage` / `History`、`herdr` 日志 | 机器本地状态 |

---

## 已知坑

1. **`~/.config/fcitx5/config` 会被 fcitx5 自己回写**（去注释、加默认值），所以 `chezmoi apply`
   偶尔会问 `has changed since chezmoi last wrote it?`。要么 `--force`，要么先 `chezmoi add` 收编现状。
2. **无 TTY 的 `chezmoi apply` 会在脚本层失败**：安装脚本里到处是 `sudo`，`sudo: 读取密码需要一个终端`。
   跑之前确保在能输密码的终端里。
3. **niri 的 DMS include 是条件包含**：`config.kdl.tmpl` 里用 `glob` 判断 `dms/input.kdl` 是否存在，
   因为 niri 遇到缺失的 include 会整份配置加载失败、会话直接起不来，而这两个文件要等 DMS 首次运行才生成。
4. **dsh 需要 `node >= 24.9`**，所以走 linuxbrew 的 node，不用发行版自带的那份。
   Windows 侧目前**没有**装 dsh。
5. **`chezmoi apply --dry-run` 在这套仓库上会卡住**——dry-run 也会尝试执行 `run_` 脚本，卡在 sudo 上。
   想预演用 `chezmoi archive --output /tmp/x.tar` 代替（只渲染文件层，不跑脚本）。
6. 仓库公开，`.chezmoidata.toml` 里是真实姓名和邮箱。

---

## 日常

```sh
chezmoi add ~/.config/foo      # 收编一个新文件
chezmoi add --template ~/.bar  # 收编成模板
chezmoi status                 # 只看有没有漂移
chezmoi diff                   # 看具体差了什么
chezmoi apply                  # 落地
chezmoi cd                     # 进源目录，正常 git 操作
```
