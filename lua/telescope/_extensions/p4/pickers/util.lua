local log = require("p4.core.log")

M = {}

function M.warn_no_selection_action()
  log.warn("Please make a valid selection before performing the action.")
end

return M
