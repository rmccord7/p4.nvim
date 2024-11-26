local env = require("p4.core.env")

--- @class P4_Current_CL : P4_CL
local P4_Current_CL = {}

--- Creates a new current CL
---
--- @param cl string P4 CL.
--- @return P4_Current_CL P4_Current_CL A new current P4 client
--- @nodiscard
function P4_Current_CL:new(cl)

  P4_Current_CL.__index = P4_Current_CL

  local P4_CL = require("p4.core.lib.cl")

  setmetatable(P4_Current_CL, {__index = P4_CL})

  local new = P4_CL:new(cl)

  setmetatable(new, {__index = P4_Current_CL})

  return new
end

--- Reads the current CL spec
function P4_Current_CL:read_spec()

  local P4_CL = require("p4.core.lib.cl")

  if P4_CL.read_spec(self) then

    -- Make sure this CL belongs to the current user.
    if env.user ~= self.spec.user then
      log.error("P4 CL is not owned by the current user")

      self.spec = nil
      return false
    end

    -- Make sure this CL belongs to the current client.
    if env.client ~= self.spec.client then
      log.error("P4 CL does not belong to the current client")

      self.spec = nil
      return false
    end
  else
    return false
  end

  return true
end

return P4_Current_CL
