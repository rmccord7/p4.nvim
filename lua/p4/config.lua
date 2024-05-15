local M = {}

M.namespace = vim.api.nvim_create_namespace("P4")

--- Export default options
---
---@class P4Options
---@field p4? table
local defaults = {
  debug = false,
  p4 = { -- P4 config.
      config = os.getenv('P4CONFIG') or "", -- Workspace P4CONFIG file name
  },
  clients = {
    cache = true, -- Cache P4USER clients
    frequency = 60000, -- Time to cache P4USER clients (ms)
    notify = true, -- Notify user once P4USER clients cached
  }
}

---@type P4Options
---
M.opts = {}
---@return P4Options

--- Initializes the plugin.
---
--- @param opts table? Optional parameters. Not used.
---
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

return M
