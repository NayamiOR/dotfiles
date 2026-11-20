# starship prompt：初始化 + 按终端明暗自动切换配色
# starship 自身不支持按明暗切 palette（starship#6991 仍 open），
# 这里借 fish 的 $fish_terminal_color_theme（终端 mode 2031 上报驱动）选配置。
#
# 重要：$status / $pipestatus 必须在一开始就抓下来，
#      任何 set/test/if 调用都会把它改成自己的返回值（否则状态码会一直显示 1）。

if status is-interactive; and type -q starship
    starship init fish | source

    function __starship_pick_config --description '按终端背景明暗选 starship 配置'
        if test "$fish_terminal_color_theme" = light
            set -gx STARSHIP_CONFIG ~/.config/starship-light.toml
        else
            # dark 与 unknown（终端不上报背景色）都退回深色
            set -gx STARSHIP_CONFIG ~/.config/starship-dark.toml
        end
    end

    function __starship_keymap --description 'Vi 模式下的 keymap，普通模式返回 insert'
        switch "$fish_key_bindings"
            case fish_hybrid_key_bindings fish_vi_key_bindings fish_helix_key_bindings
                echo "$fish_bind_mode"
            case '*'
                echo insert
        end
    end

    function fish_prompt
        set -l __ss $status
        set -l __ps $pipestatus
        set -l __dur "$CMD_DURATION$cmd_duration"
        set -l __keymap (__starship_keymap)
        __starship_set_job_count
        __starship_pick_config
        starship prompt --terminal-width="$COLUMNS" \
            --status=$__ss --pipestatus="$__ps" \
            --keymap=$__keymap --cmd-duration=$__dur --jobs=$STARSHIP_JOBS
    end

    function fish_right_prompt
        set -l __ss $status
        set -l __ps $pipestatus
        set -l __dur "$CMD_DURATION$cmd_duration"
        set -l __keymap (__starship_keymap)
        __starship_set_job_count
        __starship_pick_config
        starship prompt --right --terminal-width="$COLUMNS" \
            --status=$__ss --pipestatus="$__ps" \
            --keymap=$__keymap --cmd-duration=$__dur --jobs=$STARSHIP_JOBS
    end

    # Ghostty 切换明暗时 $fish_terminal_color_theme 会变，立刻重绘
    function __starship_repaint_on_theme_change --on-variable fish_terminal_color_theme
        __starship_pick_config
        commandline -f repaint 2>/dev/null
    end
end
