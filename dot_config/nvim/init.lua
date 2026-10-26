-- ~/.config/nvim/init.lua
local map = vim.keymap.set

-- 插入模式：jk 快速退出到普通模式
map("i", "jk", "<Esc>", { desc = "退出插入模式" })

-- 普通模式：H 行首、L 行尾
map("n", "H", "^", { desc = "跳到行首" })
map("n", "L", "$", { desc = "跳到行尾" })
