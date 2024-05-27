local M = {
  enabled = false, -- Enables debug prints
}

function M.print(msg)
    if M.enabled then
        vim.notify(msg, vim.log.levels.DEBUG, { title = "P4" })
    end
end

return M
