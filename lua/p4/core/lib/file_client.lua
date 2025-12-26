local log = require("p4.log")

local P4_File = require("p4.core.lib.file")

--- @class P4_File_Client : P4_File
local P4_File_Client = {}

P4_File_Client.__index = P4_File_Client

setmetatable(P4_File_Client, {__index = P4_File})

--- @class P4_File_Client_New
--- @field protected path Client_File_Path P4 client file path.
--- @field protected in_depot boolean Indicates if the file is in the P4 depot.
--- @field protected get_stats boolean Get file stats from P4 server.
--- @field protected client? P4_Client Optional P4 Client.
--- @field protected cl? P4_CL Optional P4 CL.

--- Wrapper function to check if a table is an instance of this class.
function P4_File_Client:_check_instance()
  assert(P4_File_Client.is_instance(self) == true, "Not a P4 file client class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a P4 file list instance.
---
--- @async
--- @nodiscard
function P4_File_Client:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_File_Client then
      return true
    end
  end

  return false
end

--- Creates a new P4 file.
---
--- @param new_client_file P4_File_Client_New New P4 file information.
--- @return boolean success True if this function is successful.
--- @return P4_File_Client P4_File_Client A new P4 file.
---
--- @async
--- @nodiscard
function P4_File_Client:new(new_client_file)
  log.trace("P4_File_Client (new): Enter")

  ---@type P4_File_New
  local new_file = {
    path = new_client_file.path,
    check_in_depot = false, -- Already know file is in the depot.
    get_stats = new_client_file.get_stats,
    client = new_client_file.client,
    cl = new_client_file.cl,
  }

  local success, new = P4_File:new(new_file)

  setmetatable(new, P4_File_Client)

  log.trace("P4_File_Client (new): Exit")

  return success, new
end

return P4_File_Client
