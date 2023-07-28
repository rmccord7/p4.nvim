local config = require("p4.config")

local M = {}

function M.warn(msg)
  vim.notify(msg, vim.log.levels.WARN, { title = "Trouble" })
end

function M.error(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "Trouble" })
end

function M.debug(msg)
  if config.options.debug then
    vim.notify(msg, vim.log.levels.DEBUG, { title = "Trouble" })
  end
end

return M
