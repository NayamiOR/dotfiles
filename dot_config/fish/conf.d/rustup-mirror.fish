# rustup 工具链下载走 rsproxy 国内镜像（无代理提速）
set -gx RUSTUP_DIST_SERVER "https://rsproxy.cn"
set -gx RUSTUP_UPDATE_ROOT "https://rsproxy.cn/rustup"
