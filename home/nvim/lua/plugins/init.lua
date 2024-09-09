return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost", "TextChanged" },
    lazy = false,
    config = function()
      require "configs.nvim-lint"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "hcl",
        "terraform",
        "gleam",
      },
    },
  },

  {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",
  },
  { "vim-scripts/BufOnly.vim", cmd = "BufOnly" },
  { "romainl/vim-cool", event = "VeryLazy" },
  { "kdheepak/lazygit.nvim", cmd = "LazyGit" },
  { "tpope/vim-fugitive", event = "VeryLazy" },
  { "tpope/vim-surround", event = "VeryLazy" },
  { "gbprod/yanky.nvim", event = "VeryLazy", opts = {} },
  {
    "ggandor/leap.nvim",
    lazy = false,
    config = function()
      require("leap").add_default_mappings()
    end,
  },
}
