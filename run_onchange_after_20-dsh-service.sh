#!/bin/sh
# dsh web 的开机自启：unit 一改就重跑（run_onchange）。
# 只做 daemon-reload + enable，必要时 start；绝不 restart ——
# 当前 GUI 就跑在这个服务里，restart 会把正在用的会话踢掉。
set -eu

command -v systemctl >/dev/null 2>&1 || exit 0
[ -n "${XDG_RUNTIME_DIR:-}" ] || exit 0

# unit 文件已由 chezmoi 写好，先让 systemd 重新读盘
systemctl --user daemon-reload || exit 0

# graphical-session.target 里的 WantedBy 依赖靠这一步建立软链
systemctl --user enable dsh-web.service || true

# 没在跑就拉起来；已在运行时 systemd 直接返回 0，不影响现有进程
systemctl --user start dsh-web.service || true
