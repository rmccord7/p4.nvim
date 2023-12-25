local M = {}

local defaults = {
  debug = false,
  p4 = {
      config = os.getenv('P4CONFIG') or "",
  },
}

M.opts = {}

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

return M
