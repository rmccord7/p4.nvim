local nio = require("nio")

local log = require("p4.log")

local env = require("p4.core.env")

--- @class P4_Current_CL : P4_CL
local P4_Current_CL = {}

--- Creates a new current CL
---
--- @param cl P4_New_CL_Information P4 CL info
--- @return P4_Current_CL P4_Current_CL A new current P4 client
--- @nodiscard
function P4_Current_CL:new(cl)

  log.trace("P4_Current_CL: new")

  P4_Current_CL.__index = P4_Current_CL

  local P4_CL = require("p4.core.lib.cl")

  setmetatable(P4_Current_CL, {__index = P4_CL})

  local new = P4_CL:new(cl)

  setmetatable(new, {__index = P4_Current_CL})

  return new
end

--- Reads the current CL spec
---
--- @return nio.control.Future future Future to wait on.
--- @nodiscard
--- @async
function P4_Current_CL:read_spec()

  log.trace("P4_Current_CL: read_spec")

  local future = nio.control.future()

  local P4_CL = require("p4.core.lib.cl")

  local success = pcall(P4_CL.read_spec(self).wait)

  if success then

    -- Make sure this CL belongs to the current user.
    if env.user ~= self.spec.user then
      log.error("P4 CL is not owned by the current user")

      self.spec = nil

      future.set_error()
    end

    -- Make sure this CL belongs to the current client.
    if env.client ~= self.spec.client then
      log.error("P4 CL does not belong to the current client")

      self.spec = nil

      future.set_error()
    end

    if not future.is_set() then
      future.set()
    end
  else
    future.set_error()
  end

  return future
end

return P4_Current_CL
