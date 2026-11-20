# 用户级 bin 目录加入 PATH（与 ~/.bashrc 保持一致）
# ~/.local/bin 里有 pi、uv、uvx 等；~/bin 里有 chezmoi 等
fish_add_path --prepend "$HOME/.local/bin" "$HOME/bin"
