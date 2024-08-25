require("lint").linters_by_ft = {
  typescript = { "eslint_d" },
  typescriptreact = { "eslint_d" },
  javascript = { "eslint_d" },
  javascriptreact = { "eslint_d" },
  sh = { "shellcheck" },
}

vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged" }, {
  callback = function()
    local lint_status, lint = pcall(require, "lint")
    if lint_status then
      lint.try_lint()
    end
  end,
})
