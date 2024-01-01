local M = {}

M.namespace = vim.api.nvim_create_namespace("P4")


--- Export default options
---
---@class P4Options
---@field p4? table
local defaults = {
  debug = false,
  p4 = { -- P4 config.
      config = os.getenv('P4CONFIG') or "", -- Workspace P4CONFIG file name.
  },
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
