local null_ls = require "null-ls"
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local formatting = null_ls.builtins.formatting
local lint = null_ls.builtins.diagnostics

local gleam_formatter = {
  name = "gleam_formatter",
  method = null_ls.methods.FORMATTING,
  filetypes = { "gleam" },
  generator = null_ls.formatter {
    command = "gleam",
    args = { "format", "--stdin" },
    to_stdin = true,
    from_stderr = true,
  },
}
null_ls.register(gleam_formatter)

local sources = {
  formatting.prettier,
  formatting.stylua,
  formatting.rustfmt,
  formatting.terraform_fmt.with {
    extra_filetypes = { "hcl" },
  },
  formatting.shfmt,
  formatting.alejandra,
  lint.eslint,
  lint.shellcheck,
}

null_ls.setup {
  debug = true,
  sources = sources,
  on_attach = function(client, bufnr)
    if client.supports_method "textDocument/formatting" then
      vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format { async = false }
        end,
      })
    end
  end,
}
