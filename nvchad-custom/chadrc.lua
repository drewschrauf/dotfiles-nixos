---@type ChadrcConfig
local M = {}
M.ui = {
  theme = "catppuccin",
  hl_override = require "custom.highlights",
}
M.plugins = "custom.plugins"
M.mappings = require "custom.mappings"
return M
