local log = require("p4.log")

local env = require("p4.core.env")
local P4_CL = require("p4.core.lib.cl")

--- @class P4_Current_CL : P4_CL
local P4_Current_CL = {}

P4_Current_CL.__index = P4_Current_CL

setmetatable(P4_Current_CL, {__index = P4_CL})

--- Creates a new current CL
---
--- @param cl P4_New_CL_Information P4 CL info
--- @return P4_Current_CL P4_Current_CL A new current P4 client
--- @nodiscard
function P4_Current_CL:new(cl)

  log.trace("P4_Current_CL: new")

  local new = P4_CL:new(cl)

  setmetatable(new, {__index = P4_Current_CL})

  return new
end

--- Reads the current CL spec
---
--- @async
function P4_Current_CL:read_spec()

  log.trace("P4_Current_CL: read_spec")

  P4_CL.get_spec(self)

  -- Make sure this CL belongs to the current user.
  if env.user ~= self.spec.user then
    log.error("P4 CL is not owned by the current user")

    self.spec = nil
  end

  -- Make sure this CL belongs to the current client.
  if env.client ~= self.spec.client then
    log.error("P4 CL does not belong to the current client")

    self.spec = nil
  end
end

return P4_Current_CL
