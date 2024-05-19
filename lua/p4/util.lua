local M = {}

function M.print(msg)
    vim.notify(msg, vim.log.levels.INFO, { title = "P4" })
end

function M.warn(msg)
    vim.notify(msg, vim.log.levels.WARN, { title = "P4" })
end

function M.error(msg)
    vim.notify(msg, vim.log.levels.ERROR, { title = "P4" })
end

M.debug = require("p4.debug")

return M
