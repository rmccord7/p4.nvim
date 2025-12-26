local log = require("p4.log")

local P4_File = require("p4.core.lib.file")

--- @class P4_File_Depot : P4_File
local P4_File_Depot = {}

P4_File_Depot.__index = P4_File_Depot

setmetatable(P4_File_Depot, {__index = P4_File})

--- @class P4_File_Depot_New
--- @field protected path Depot_File_Path P4 depot file path.
--- @field protected get_stats boolean Get file stats from P4 server.
--- @field protected client? P4_Client Optional P4 Client.
--- @field protected cl? P4_CL Optional P4 CL.

--- Wrapper function to check if a table is an instance of this class.
function P4_File_Depot:_check_instance()
  assert(P4_File_Depot.is_instance(self) == true, "Not a P4 file depot class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a P4 file list instance.
---
--- @async
--- @nodiscard
function P4_File_Depot:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_File_Depot then
      return true
    end
  end

  return false
end

--- Creates a new P4 file.
---
--- @param new_depot_file P4_File_Depot_New New P4 file information.
--- @return boolean success True if this function is successful.
--- @return P4_File_Depot P4_File_Depot A new P4 file.
---
--- @async
--- @nodiscard
function P4_File_Depot:new(new_depot_file)
  log.trace("P4_File_Depot (new): Enter")

  ---@type P4_File_New
  local new_file = {
    path = new_depot_file.path,
    check_in_depot = false, -- Already know file is in the depot.
    get_stats = new_depot_file.get_stats,
    client = new_depot_file.client,
    cl = new_depot_file.cl,
  }

  local success, new = P4_File:new(new_file)

  setmetatable(new, P4_File_Depot)

  log.trace("P4_File_Depot (new): Exit")

  return success, new
end

return P4_File_Depot
