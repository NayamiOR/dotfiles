# Homebrew 环境（缓存 shellenv，避免每次启动 fork 一次 brew）
# 注意：fish 先 source conf.d/*.fish，最后才 source config.fish，
#      所以这里必须比 starship.fish 先加载（00- 前缀保证顺序）。

set -l brew_bin /home/linuxbrew/.linuxbrew/bin/brew
set -l cache ~/.cache/fish/brew-shellenv.fish

if test -x $brew_bin
    if not test -s $cache
        mkdir -p (dirname $cache)
        $brew_bin shellenv fish > $cache 2>/dev/null
    end
    if test -s $cache
        source $cache
    end
end
