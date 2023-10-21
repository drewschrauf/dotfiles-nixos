local M = {}

M.disabled = {
  n = {
    ["<C-n>"] = "",
  },
}

M.general = {
  n = {
    ["<leader>s"] = { ":update<CR>", "save" },
    ["<leader>i"] = { "^", "start of line" },
    ["<leader>a"] = { "$", "end of line" },
    ["<C-h>"] = { "<cmd> TmuxNavigateLeft<CR>", "window left" },
    ["<C-l>"] = { "<cmd> TmuxNavigateRight<CR>", "window right" },
    ["<C-j>"] = { "<cmd> TmuxNavigateDown<CR>", "window down" },
    ["<C-k>"] = { "<cmd> TmuxNavigateUp<CR>", "window up" },
    ["<leader>o"] = { ":BufOnly<CR>", "close other buffers" },
    ["<leader>lg"] = { ":LazyGit<CR>", "open lazygit" },
    ["Q"] = { ":qa<CR>", "quick close" },
    ["<leader>tp"] = { ":silent exec '!tmux split-window -h -p 30'<CR>", "new tmux pane" },

    ["p"] = { "<Plug>(YankyPutAfter)" },
    ["P"] = { "<Plug>(YankyPutBefore)" },
    ["<C-n>"] = { "<Plug>(YankyCycleForward)" },
    ["<C-p>"] = { "<Plug>(YankyCycleBackward)" },
  },

  i = {
    ["jj"] = { "<ESC>", "escape insert mode", opts = { nowait = true } },
  },
}

return M
