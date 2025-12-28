local log = require("p4.log")

local env = require("p4.core.env")

--- @class P4_Current_CL : P4_CL
local P4_Current_CL = {}

P4_Current_CL.__index = P4_Current_CL

--- Wrapper function to check if a table is an instance of this class.
function P4_Current_CL:_check_instance()
  assert(P4_Current_CL.is_instance(self) == true, "Not a P4 CL class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_Current_CL:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_Current_CL then
      return true
    end
  end

  return false
end

--- Creates a new current CL
---
--- @param cl P4_New_CL_Information P4 CL info
--- @return boolean success True if this function is successful.
--- @return P4_Current_CL P4_Current_CL A new current P4 client
---
--- @async
--- @nodiscard
function P4_Current_CL:new(cl)
  log.trace("P4_Current_CL (new): Enter")

  local P4_CL = require("p4.core.lib.cl")

  setmetatable(P4_Current_CL, {__index = P4_CL})

  --- @type P4_New_CL_Information
  local new_cl = {
    change = cl.change,
  }

  local success, new = P4_CL:new(new_cl)

  if success then
    setmetatable(new, P4_Current_CL)
  end

  log.trace("P4_Current_CL (new): Exit")

  return success, new
end

--- Reads the current CL spec
---
--- @return boolean success True if this function is successful.
--- @return P4_CL_Spec spec P4 CL spec.
---
--- @async
--- @nodiscard
function P4_Current_CL:get_spec()
  log.trace("P4_Current_CL (read_spec): Enter")

  self:_check_instance()

  local P4_CL = require("p4.core.lib.cl")

  local success = P4_CL.get_spec(self)

  if success then

    -- Make sure this CL belongs to the current user.
    if env.user ~= self.spec.user then
      log.error("P4 CL is not owned by the current user")
    end

    -- Make sure this CL belongs to the current client.
    if env.client ~= self.spec.client then
      log.error("P4 CL does not belong to the current client")
    end
  end

  if not success then
    self.spec = nil
  end

  log.trace("P4_Current_CL (read_spec): Exit")

  return success, self.spec
end

return P4_Current_CL
