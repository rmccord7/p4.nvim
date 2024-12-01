local p4 = require("p4")

local log = require("p4.log")
local notify = require("p4.notify")

local env = require("p4.core.env")

--- @class P4_Telescope_API
local P4_Telescope_API = {}

--- Performs common checks for all Telescope APIs to make sure that
--- the plugin has been configured correctly for their use.
function P4_Telescope_API.check()

  log.trace("P4_Telescope_API: check")

  -- Make sure the P4 environment is valid.
  if not env.check() then
    return false
  end

  -- Make sure telescope is supported.
  if not p4.telescope then
    notify("Command not supported", vim.log.levels.ERROR)

    log.error("Telescope not supported")

    return false
  end

  return true
end

return P4_Telescope_API
