require "nvchad.mappings"

vim.keymap.del("n", "<C-n>")

local map = vim.keymap.set

map("n", "<leader>s", ":update<CR>", { desc = "save" })
map("n", "<leader>i", "^", { desc = "start of line" })
map("n", "<leader>a", "$", { desc = "end of line" })
map("n", "Q", ":qa<CR>", { desc = "quick close" })

map("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>")
map("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>")
map("n", "<C-j>", "<cmd>TmuxNavigateUp<CR>")
map("n", "<C-k>", "<cmd>TmuxNavigateDown<CR>")

map("n", "<leader>tp", ":silent exec '!tmux split-window -h -p 30'<CR>", { desc = "new tmux pane" })

map("n", "<leader>o", ":BufOnly<CR>", { desc = "close other buffers" })
map("n", "<leader>lg", ":LazyGit<CR>", { desc = "open lazygit" })

map("n", "p", "<Plug>(YankyPutAfter)")
map("n", "P", "<Plug>(YankyPutBefore)")
map("n", "<C-n>", "<Plug>(YankyCycleForward)")
map("n", "<C-p>", "<Plug>(YankyCycleBackward)")

map("i", "jj", "<ESC>", { desc = "exit insert mode" })
