# cargo/rustup 的 bin 目录加入 PATH（幂等，避免重复）
case ":$PATH:" in
  *:"$HOME/.cargo/bin":*) ;;
  *) export PATH="$HOME/.cargo/bin:$PATH" ;;
esac
