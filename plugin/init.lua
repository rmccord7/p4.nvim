local config = require("p4.config")
local log = require("p4.log")

local p4_env = require("p4.core.env")

local p4_config = require("p4.core.config")

if vim.fn.has("nvim-0.11.0") == 0 then
  log.error("P4 needs Neovim >= 0.11.0")
  return
end

-- Initialize plugin defaults
config.load_defaults()

log.trace("Plugin start")

-- Set up the user commands.
require("p4.commands")

--- Update the P4 workspace if the directory changed.
local group = vim.api.nvim_create_augroup("P4", {})

vim.api.nvim_create_autocmd({"DirChanged"}, {
  group = group,
  pattern = "*",
  callback = function()
    log.debug("Directory Changed")

    -- Clear the previous P4 environment since we may be changing projects.
    p4_env.clear()

    -- Clear the current P4CONFIG path if it exists.
    p4_config.clear()

    -- Update the P4 enviroment.
    p4_env:update()
  end
})
