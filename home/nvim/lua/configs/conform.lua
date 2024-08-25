local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    nix = { "alejandra" },
    sh = { "shfmt" },

    typescript = { "prettierd" },
    typescriptreact = { "prettierd" },
    javascript = { "prettierd" },
    javascriptreact = { "prettierd" },
    json = { "prettierd" },
    html = { "prettierd" },
    css = { "prettierd" },

    tf = { "terraform_fmt" },
    hcl = { "terraform_fmt" },

    gleam = { "gleam" },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
