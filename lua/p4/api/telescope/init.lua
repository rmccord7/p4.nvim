
local log = require("p4.log")
local notify = require("p4.notify")

local p4_env = require("p4.core.env")

--- @class P4_Telescope_API
local P4_Telescope_API = {}

--- Performs common checks for all Telescope APIs to make sure that
--- the plugin has been configured correctly for their use.
function P4_Telescope_API.check()

  log.trace("P4_Telescope_API: check")

  -- Ensure P4 environment is set.
  if not p4_env.update() then
    return false
  end

  local p4_context = require("p4.context")

  -- Ensure the telescope plugin is supported.
  if not p4_context.telescope then
    notify("Telescope not supported", vim.log.levels.ERROR)

    log.error("Telescope not supported")

    return false
  end

  return true
end

return P4_Telescope_API
