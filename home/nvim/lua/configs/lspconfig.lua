local configs = require "nvchad.configs.lspconfig"

local on_attach = configs.on_attach
local on_init = configs.on_init
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"
local servers = { "terraformls", "rust_analyzer", "bashls", "nil_ls", "gleam" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_init = on_init,
    on_attach = function(client)
      on_attach(client)
      vim.keymap.del("n", "<leader>sh")
    end,
    capabilities = capabilities,
  }
end

lspconfig.tsserver.setup {
  on_init = on_init,
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
    on_attach(client)
    vim.keymap.del("n", "<leader>sh")
  end,
  capabilities = capabilities,
  cmd_env = { NODE_OPTIONS = "--max-old-space-size=4096" },
}
