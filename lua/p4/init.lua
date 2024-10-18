local config = require("p4.config")

local core = require("p4.core")
local log = require("p4.core.log")

--- P4 context.
local M = {
  p4 = { -- perforce config
      cache = { -- cached data
        clients = { -- p4 clients cache
          last_checked = 0, -- last time the cached client list was checked
          list = {}, -- list of cached clients
        },
      },
  },
}

--- Initializes the plugin.
---
--- @param opts table? P4 options
function M.setup(opts)
  if vim.fn.has("nvim-0.7.2") == 0 then
    log.error("P4 needs Neovim >= 0.7.2")
    return
  end

  config.setup(opts)

  local group = vim.api.nvim_create_augroup("P4", {})

  --- If directory has changed, then we may have left the
  --- current P4 workspace.
  ---
  vim.api.nvim_create_autocmd({"DirChanged"}, {
    group = group,
    pattern = "*",
    callback = function()

      -- Force search for the new P4CONFIG since directory changed.
      core.config.clear()

      -- Force the P4 environment information update
      core.env.clear()
      core.env.update()
    end,
  })

  -- Updated the environement to kick things off.
  core.env.update()
end

return M
