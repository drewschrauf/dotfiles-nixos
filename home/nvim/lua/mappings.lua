require "nvchad.mappings"

vim.keymap.del("n", "<C-n>")
-- vim.keymap.del("n", "<C-h>")
-- vim.keymap.del("n", "<C-l>")
-- vim.keymap.del("n", "<C-j>")
-- vim.keymap.del("n", "<C-k>")

local map = vim.keymap.set

map("n", "<leader>s", ":update<CR>", { desc = "save" })
map("n", "<leader>i", "^", { desc = "start of line" })
map("n", "<leader>a", "$", { desc = "end of line" })
map("n", "Q", ":qa<CR>", { desc = "quick close" })

map("n", "<leader>df", function()
  vim.diagnostic.open_float()
end, { desc = "Show diagnostics under the cursor" })

-- map("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>")
-- map("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>")
-- map("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>")
-- map("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>")

map("n", "<leader>tp", ":silent exec '!tmux split-window -h -p 30'<CR>", { desc = "new tmux pane" })

map("n", "<leader>o", ":BufOnly<CR>", { desc = "close other buffers" })
map("n", "<leader>lg", ":LazyGit<CR>", { desc = "open lazygit" })

map("n", "p", "<Plug>(YankyPutAfter)")
map("n", "P", "<Plug>(YankyPutBefore)")
map("n", "<C-n>", "<Plug>(YankyCycleForward)")
map("n", "<C-p>", "<Plug>(YankyCycleBackward)")

map("i", "jj", "<ESC>", { desc = "exit insert mode" })

map("n", "<leader>gr", ":OpenInGHRepo<CR>")
map("n", "<leader>gf", ":OpenInGHFile<CR>")
map("v", "<leader>gf", ":OpenInGHFileLines<CR>")

map("n", "<leader>gn", ":Neogit<CR>")
map("n", "<leader>gb", ":Gitsigns blame<CR>")
