local log = require("p4.log")

--- @class P4_Current_Client : P4_Client
local P4_Current_Client = {}

P4_Current_Client.__index = P4_Current_Client

--- Wrapper function to check if a table is an instance of this class.
function P4_Current_Client:_check_instance()
  assert(P4_Current_Client.is_instance(self) == true, "Not a P4 CL class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_Current_Client:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_Current_Client then
      return true
    end
  end

  return false
end

--- Creates a new current client
---
--- @param client_name string P4 client name
--- @return boolean success True if this function is successful.
--- @return P4_Current_Client P4_Current_Client A new current P4 client
---
--- @nodiscard
function P4_Current_Client:new(client_name)
  log.trace("P4_Current_Client (new): Enter")

  local P4_Client = require("p4.core.lib.client")

  setmetatable(P4_Current_Client, {__index = P4_Client})

  local success, new = P4_Client:new(client_name)

  if success then
    setmetatable(new, P4_Current_Client)
  end

  log.trace("P4_Current_Client (new): Exit")

  return success, new
end

--- Sets the current P4 client's CL.
---
--- @param cl string P4 CL.
--- @return boolean success True if this function is successful.
---
--- @async
--- @nodiscard
function P4_Current_Client:set_cl(cl)
  log.trace("P4_Current_Client (new): Enter")

  self:_check_instance()

  local success = false

  -- If CL has never been current or CL is not
  -- the current CL, then we need to update it.
  if not self.cl.change or cl ~= tonumber(self.cl.change) then

    local P4_Current_CL = require("p4.core.lib.current_cl")

    --- @type P4_New_CL_Information
    local new_cl = {
      change = cl,
      client = self,
    }

    local p4_cl
    success, p4_cl = P4_Current_CL:new(new_cl)

    if success then

      success = p4_cl:get_spec()

      if success then

        self.cl = p4_cl

        log.fmt_info("Client: %s", self.name);
        log.fmt_info("Client CL: %s", self.cl.change);
      end
    end

  else
    log.warn("CL already set as the current client's CL")
  end

  log.trace("P4_Current_Client (new): Exit")

  return success
end

return P4_Current_Client
