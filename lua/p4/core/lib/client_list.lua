local log = require("p4.log")

--- @class P4_Client_List : table
--- @field protected list P4_Client[] P4 client list.
local P4_Client_List = {}

--- Wrapper function to check if a table is an instance of this class.
function P4_Client_List:_check_instance()
  assert(P4_Client_List.is_instance(self) == true, "Not a P4 client list class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_Client_List:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_Client_List then
      return true
    end
  end

  return false
end

--- Creates a new P4 client list.
---
--- @param new_clients string[] One or more P4 client names.
--- @return boolean success True if this function is successful.
--- @return P4_Client_List P4_Client_List A new P4 file list.
---
--- @async
--- @nodiscard
function P4_Client_List:new(new_clients)
  log.trace("P4_Client_List (new): Enter")

  local success = false

  P4_Client_List.__index = P4_Client_List

  ---@class P4_Client_List
  local new = setmetatable({}, P4_Client_List)

  local P4_Client = require("p4.core.lib.client")

  new.list = {}

  for _, client_name in ipairs(new_clients) do
    local p4_client
    success, p4_client = P4_Client:new(client_name)

    if success and p4_client then
      table.insert(new.list, p4_client)
    else
      break
    end
  end

  log.trace("P4_Client_List (new): Exit")

  return success, new
end

--- Returns the list of P4 clients.
---
--- @return P4_Client[] result A list of P4 clients.
function P4_Client_List:get_clients()
  log.trace("P4_Client_List (get): Enter")

  self:_check_instance()

  log.trace("P4_Client_List (get): Exit")

  return self.list
end

return P4_Client_List
