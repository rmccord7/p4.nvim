local p4 = require("p4")

local config = require("p4.config")
local log = require("p4.log")

local p4_env = require("p4.core.env")

local p4_config = require("p4.core.config")

--- Starts the plugin
local function start()

  -- Initialize plugin defaults
  config.setup()

  log.debug("Plugin start")

  --- Update the P4 workspace if the directory changed.
  local group = vim.api.nvim_create_augroup("P4", {})

  vim.api.nvim_create_autocmd({"DirChanged"}, {
    group = group,
    pattern = "*",
    callback = function()
      log.debug("Directory Changed")

      -- Set up the Rocks user command
      require("p4.commands").create_commands()

      -- Clear the current P4CONFIG path if it exists.
      p4_config.clear()

      -- Force the P4 environment information update
      p4_env.clear()
      p4_env.update()
    end
  })
end

--- Start the plugin
start()
