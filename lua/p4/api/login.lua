local log = require("p4.log")

local env = require("p4.core.env")
local shell = require("p4.core.shell")

local login_cmds = require("p4.core.commands.login")

--- P4 check
local api = {}

--- Make sure the user is logged into the P4 server.
function api.check()

  -- Ensure P4 environment information is valid
  if env.update() then

    -- Verify the user is logged into configured P4 server.
    local opts = {
      check = true,
    }

    local result = shell.run(login_cmds.login(opts))

    if result.code ~= 0 then
      log.error("Not logged in")
      return false
    end

  else
    return false
  end

  return true
end

return api

