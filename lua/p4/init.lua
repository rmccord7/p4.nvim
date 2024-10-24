local config = require("p4.config")
local log = require("p4.log")

local env = require("p4.core.env")

--- P4 context.
local M = {}

--- Initializes the plugin.
---
--- @param opts table? P4 options
function M.setup(opts)
  if vim.fn.has("nvim-0.7.2") == 0 then
    log.error("P4 needs Neovim >= 0.7.2")
    return
  end

  config.setup(opts)

  -- Reload enviroment
  env.update()
end

return M
