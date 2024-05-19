local util = require("p4.util")

M = {}

function M.warn_no_selection_action()
  util.warn("Please make a valid selection before performing the action.")
end

return M
