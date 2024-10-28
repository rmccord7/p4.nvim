local config = require("p4.config")
local log = require("p4.log")

local p4_config = require("p4.core.config")

--- Starts the plugin
local function Start()

  -- Initialize plugin defaults
  config.setup()

  vim.api.nvim_create_user_command(
    "P4Log",
    function()
      vim.cmd(([[tabnew %s]]):format(log.outfile))
    end,
    {
      desc = "Opens the p4.nvim log.",
    }
  )

  log.debug("Plugin start")

  --- Update the P4 workspace if the directory changed.
  local group = vim.api.nvim_create_augroup("P4", {})

  vim.api.nvim_create_autocmd({"DirChanged"}, {
    group = group,
    pattern = "*",
    callback = function()

      log.debug("Directory Changed")

      -- Load user commands.
      require("p4.api.commands.file.user")

      -- Clear the current P4CONFIG path if it exists.
      p4_config.clear()

      -- Force the P4 environment information update
      env.clear()
      env.update()
    end,
  })
end

--- Start the plugin
Start()
