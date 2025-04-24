local config = require("p4.config")
local log = require("p4.log")

local p4_env = require("p4.core.env")

local p4_config = require("p4.core.config")

if vim.fn.has("nvim-0.7.2") == 0 then
  log.error("P4 needs Neovim >= 0.7.2")
  return
end

-- Initialize plugin defaults
config.load_defaults()

log.trace("Plugin start")

--- Update the P4 workspace if the directory changed.
local group = vim.api.nvim_create_augroup("P4", {})

vim.api.nvim_create_autocmd({"DirChanged"}, {
  group = group,
  pattern = "*",
  callback = function()
    log.debug("Directory Changed")

    -- Set up the user commands.
    require("p4.commands")

    -- Check if the P4 environment was previoulsy set since this will be cleared. This will always be false at startup
    -- so we won't load the P4 enviroment until the user performs a command.
    local reload = false

    if p4_env.check(false) then
     reload = true
    end

    -- Force the P4 environment information update
    p4_env.clear()

    -- Clear the current P4CONFIG path if it exists.
    p4_config.clear()

    -- Reload the P4 environemnt if it was previously set for the previous directory since we may have just changed
    -- projects.
    if reload then
      p4_env:update()
    end
  end
})
