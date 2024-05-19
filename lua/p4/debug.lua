local M = {
  enable_debug = false, -- Enables debug prints
}

function M.debug(msg)
    if M.enable_debug then
        vim.notify(msg, vim.log.levels.DEBUG, { title = "P4" })
    end
end

return M.debug
