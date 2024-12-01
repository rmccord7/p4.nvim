local nio = require("nio")

local log = require("p4.log")

local env = require("p4.core.env")

--- @class P4_Current_Client : P4_Client
--- @field semaphore nio.control.Semaphore Semaphore for the current client
local P4_Current_Client = {}

--- Creates a new current client
---
--- @param client_name string P4 client name
--- @return P4_Current_Client P4_Current_Client A new current P4 client
--- @nodiscard
function P4_Current_Client:new(client_name)

  log.trace("P4_Current_Client: new")

  P4_Current_Client.__index = P4_Current_Client

  local P4_Client = require("p4.core.lib.client")

  setmetatable(P4_Current_Client, {__index = P4_Client})

  --- @type P4_Current_Client
  local new = P4_Client:new(client_name)

  setmetatable(new, P4_Current_Client)

  new.semaphore = nio.control.semaphore(1)

  return new
end

--- Reads the current client's spec.
---
--- @param on_exit fun(success: boolean, ...) Will be called once the function completes.
--- @async
function P4_Current_Client:read_spec(on_exit)

  log.trace("P4_Current_Client: read_spec")

  local P4_Client = require("p4.core.lib.client")

  P4_Client.read_spec(self, function(success)

    if success then
      log.fmt_info("Client root: %s", self.spec.root);
    end

    on_exit(success)
  end)
end

--- Sets the current P4 client's CL.
---
--- @param cl string P4 CL.
--- @return boolean result Returns true if the current client's CL has been set
function P4_Current_Client:set_cl(cl)

  log.trace("P4_Current_Client: set_cl")

  -- If CL has never been current or CL is not
  -- the current CL, then we need to update it.
  if not self.cl or cl ~= tonumber(self.cl.name) then

    local P4_Current_CL = require("p4.core.lib.current_cl")

    --- @type P4_New_CL_Information
    local new_cl = {
      name = cl,
      client = self,
      user = env.user,
      description = nil,
      status = nil,
    }

    local p4_cl = P4_Current_CL:new(new_cl)

    -- Make sure it exists by reading the spec.
    if p4_cl:read_spec() then

      self.cl = p4_cl

      log.fmt_info("Client: %s", self.name);
      log.fmt_info("Client CL: %s", self.cl.name);
    end
  else
    log.warn("CL already set as the current client's CL")
    return false
  end

  return true
end

return P4_Current_Client
