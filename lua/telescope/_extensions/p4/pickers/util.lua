M = {}

function M.warn_no_selection_action()
  vim.notify("Please make a valid selection before performing the action.", vim.log.levels.WARN)
end

return M
