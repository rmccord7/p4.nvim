local config = require("p4.config")
local log = require("p4.log")

local env = require("p4.core.env")

--- @class P4_Context
--- @field current_client P4_Current_Client? Current client
local context = {}

-- Check if telescope is supported
 local has_telescope, _ = pcall(require, "telescope")

 if has_telescope then

   context.telescope = true
 else
   context.telescope = false
 end

--- Initializes the plugin.
---
--- @param opts table? P4 options
function context.setup(opts)
  if vim.fn.has("nvim-0.7.2") == 0 then
    log.error("P4 needs Neovim >= 0.7.2")
    return
  end

  config.setup(opts)

  -- Reload enviroment
  env.update()
end

return context
