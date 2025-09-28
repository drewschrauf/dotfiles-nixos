require("nvchad.configs.lspconfig").defaults()
local on_attach = require("nvchad.configs.lspconfig").on_attach

local servers = { "terraformls", "bashls", "nil_ls", "gleam", "ts_ls", "rust_analyzer" }
vim.lsp.enable(servers)

vim.lsp.config["ts_ls"] = {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
    on_attach(client)
  end,
  cmd_env = { NODE_OPTIONS = "--max-old-space-size=4096" },
}

vim.lsp.config["rust_analyzer"] = {
  settings = {
    ["rust-analyzer"] = {
      procMacro = {
        ignored = {
          leptos_macro = {
            "server",
          },
        },
      },
      diagnostics = {
        disabled = { "proc-macro-disabled" },
      },
      cargo = {
        features = { "ssr" },
      },
    },
  },
}
