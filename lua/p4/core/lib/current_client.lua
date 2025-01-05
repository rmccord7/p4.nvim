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

--- Sets the current P4 client's CL.
---
--- @param cl string P4 CL.
--- @return nio.control.Future future Future to wait on.
--- @nodiscard
--- @async
function P4_Current_Client:set_cl(cl)

  log.trace("P4_Current_Client: set_cl")

  local future = nio.control.future()

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

    local success = pcall(p4_cl:read_spec().wait)

    -- Make sure it exists by reading the spec.
    if success then

      self.cl = p4_cl

      log.fmt_info("Client: %s", self.name);
      log.fmt_info("Client CL: %s", self.cl.name);

      future.set()
    else
      future.set_error()
    end

  else
    log.warn("CL already set as the current client's CL")

    future.set_error()
  end

  return future
end

return P4_Current_Client
