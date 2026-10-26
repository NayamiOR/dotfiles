#!/usr/bin/env bash
# 白霜拼音（rime-frost）：方案/词库 + 八股文语法模型。
#
# 这些资产合计约 480MB（词库 200MB+、语法模型 206MB），不进 git。
# 本脚本只在「脚本内容变化」时重跑，且每一步都是「缺了才做」，可安全重复执行。
#
# 小配置文件（default.custom.yaml / rime_frost.custom.yaml / fcitx5 配置）
# 由 chezmoi 自己管理，见 dot_config/fcitx5 与 dot_local/private_share/fcitx5。
set -euo pipefail

case "$(uname -s)" in
  Linux) : ;;
  *) exit 0 ;;
esac

RIME="${XDG_DATA_HOME:-$HOME/.local/share}/fcitx5/rime"
FRAMEWORK_REPO="https://github.com/gaboolic/rime-frost.git"
GRAM_VERSION="20260712"
GRAM_NAME="zh-hans-t-essay-bgw.gram"        # 全量版，约 206MB；换 -compact 可降到 41MB
GRAM_PATH="rime-octagram-data/releases/download/${GRAM_VERSION}/${GRAM_NAME}"
# 直连慢/失败时依次回退到镜像
GRAM_MIRRORS=(
  "https://github.com/lotem/${GRAM_PATH}"
  "https://ghfast.top/https://github.com/lotem/${GRAM_PATH}"
  "https://gh-proxy.com/https://github.com/lotem/${GRAM_PATH}"
)

if ! command -v fcitx5 >/dev/null 2>&1; then
  echo "rime-frost: 未安装 fcitx5，跳过（先跑 run_onchange_install-packages.sh）"
  exit 0
fi

mkdir -p "$RIME"

# 1) 方案 + 词库：缺失才拉取；已存在的文件一律不覆盖（-n），保护 chezmoi 管理的 custom 文件
if [ ! -f "$RIME/rime_frost.schema.yaml" ]; then
  echo "rime-frost: 拉取方案与词库…"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  # git clone 失败时回退到 codeload tarball（国内网络下 git 协议偶发 SSL 中断）
  if git clone --depth=1 "$FRAMEWORK_REPO" "$tmp/frost" 2>/dev/null; then
    cp -an "$tmp/frost/." "$RIME"/
  elif curl -fL --retry 3 -o "$tmp/frost.tar.gz" \
         "https://codeload.github.com/gaboolic/rime-frost/tar.gz/refs/heads/master" \
       || curl -fL --retry 3 -o "$tmp/frost.tar.gz" \
         "https://ghfast.top/https://github.com/gaboolic/rime-frost/archive/refs/heads/master.tar.gz"; then
    tar xzf "$tmp/frost.tar.gz" -C "$tmp" && cp -an "$tmp/rime-frost-master/." "$RIME"/
  else
    echo "rime-frost: 方案下载失败，请检查网络后重新 chezmoi apply" >&2
  fi
fi

# 2) 八股文语法模型：缺失才下载
if [ ! -f "$RIME/$GRAM_NAME" ]; then
  echo "rime-frost: 下载语法模型 $GRAM_NAME（约 200MB）…"
  ok=0
  for url in "${GRAM_MIRRORS[@]}"; do
    echo "  ← $url"
    if curl -fL --retry 2 --connect-timeout 10 -o "$RIME/$GRAM_NAME.part" "$url"; then ok=1; break; fi
    rm -f "$RIME/$GRAM_NAME.part"
  done
  if [ "$ok" = 1 ]; then
    mv "$RIME/$GRAM_NAME.part" "$RIME/$GRAM_NAME"
  else
    echo "rime-frost: 语法模型下载失败；方案仍可用，只是没有整句模型" >&2
  fi
fi

# 3) 如果 fcitx5 正在运行，触发重新部署
if command -v fcitx5-remote >/dev/null 2>&1 && pgrep -x fcitx5 >/dev/null 2>&1; then
  fcitx5-remote -r >/dev/null 2>&1 || true
  echo "rime-frost: 已通知 fcitx5 重新部署"
fi
