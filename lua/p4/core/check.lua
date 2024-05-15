local p4_commands = require("p4.commands")
local p4_util = require("p4.util")

local p4c_env = require("p4.core.env")

--- P4 check
local M = {}

--- Make sure the user is logged into the P4 server.
function M.login()

  -- Ensure P4 environment information is valid
  if p4c_env.update() then

    -- Verify the user is logged into configured P4 server.
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

