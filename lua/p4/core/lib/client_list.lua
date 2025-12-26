local log = require("p4.log")

--- @class P4_Client_List : table
--- @field protected list P4_Client[] P4 client list.
local P4_Client_List = {}

--- Creates a new P4 client list.
---
--- @param new_clients string[] One or more P4 client names.
--- @return P4_Client_List P4_Client_List A new P4 file list.
--- @nodiscard
function P4_Client_List:new(new_clients)

  log.trace("P4_Client_List: new")

  P4_Client_List.__index = P4_Client_List

  ---@class P4_Client_List
  local new = setmetatable({}, P4_Client_List)

  local P4_Client = require("p4.core.lib.client")

  new.list = {}

  for _, client_name in ipairs(new_clients) do
    local p4_client = P4_Client:new(client_name)

    table.insert(new.list, p4_client)
  end

  return new
end

--- Returns the list of P4 clients.
---
--- @return P4_Client[] result A list of P4 clients.
function P4_Client_List:get()
  log.trace("P4_Client_List: get")

  return self.list
end

return P4_Client_List
