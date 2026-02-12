require "nvchad.options"

vim.o.colorcolumn = "100"
vim.opt.tabstop = 2
vim.opt.swapfile = false
vim.o.autoread = true

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  pattern = "*",
  command = "checktime",
})
