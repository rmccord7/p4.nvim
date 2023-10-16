local p4 = require("p4")
local p4_commands = require("p4.commands")
local p4_util = require("p4.util")

M = {}

function M.warn_no_selection_action()
  p4_util.warn("Please make a valid selection before performing the action.")
end

-- Performs checks to prevent picker from launching.
function M.verify_p4_picker()

  -- Verify there is P4CONFIG at root of workspace.
  if p4.verify_workspace() then

    -- Verify the user is logged into configured perforce server for the P4 workspace.
    local result = p4_util.run_command(p4_commands.check_login())

    if result.code ~= 0 then
      p4_util.error("Not logged in")
      return false
    end
  else
    return false
  end

  return true
end

return M
