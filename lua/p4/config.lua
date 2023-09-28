util = require('p4.util')

local M = {}

local defaults = {
  debug = true,
  p4 = {
      config = os.getenv('P4CONFIG'),
      user = os.getenv('P4USER') or "",
      host = os.getenv('P4HOST') or "",
      port = os.getenv('P4PORT') or "",
      client = os.getenv('P4CLIENT') or "",
  },
}

M.opts = {}

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})

  util.debug("P4CONFIG :" .. M.opts.p4.config)
  util.debug("P4USER :" .. M.opts.p4.user)
  util.debug("P4HOST :" .. M.opts.p4.host)
  util.debug("P4PORT :" .. M.opts.p4.port)
  util.debug("P4CLIENT :" .. M.opts.p4.client)
end

return M
