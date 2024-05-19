local util = require("p4.util")
local commands = require("p4.commands")

local core = require("p4.core")

--- P4 check
local M = {}

--- Make sure the user is logged into the P4 server.
function M.check()

  -- Ensure P4 environment information is valid
  if core.env.update() then

    -- Verify the user is logged into configured P4 server.
    local opts = {
      check = true,
    }

    local result = core.shell.run(commands.login(opts))

    if result.code ~= 0 then
      util.error("Not logged in")
      return false
    end

  else
    return false
  end

  return true
end

return M

