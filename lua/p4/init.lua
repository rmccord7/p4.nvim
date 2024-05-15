local p4_config = require("p4.config")
local p4_util = require("p4.util")

local p4c_config = require("p4.core.config")
local p4c_env = require("p4.core.env")

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
    p4_util.error("P4 needs Neovim >= 0.7.2")
    return
  end

  p4_config.setup(opts)

  p4c_env.update()
end

local group_id = vim.api.nvim_create_augroup("P4", {})

--- Check for P4 workspace when buffer is entered.
---
vim.api.nvim_create_autocmd("BufEnter", {
  group = group_id,
  pattern = "*",
  callback = function()

    if p4c_env.update() then

      -- Set buffer to reload for changes made outside vim such as
      -- pulling latest revisions.
      vim.api.nvim_set_option_value("autoread", false, { scope = "local" })

    end
  end,
})

return M
