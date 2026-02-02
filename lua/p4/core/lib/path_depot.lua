local path_lib = require("p4.core.lib.path")

--- @class P4_Path_Depot : P4_Path
--- @field path Depot_File_Path Depot path.
local P4_Path_Depot = {}

P4_Path_Depot.__index = P4_Path_Depot

setmetatable(P4_Path_Depot, {__index = path_lib})

--- Wrapper function to check if a table is an instance of this class.
function P4_Path_Depot:_check_instance()
  assert(P4_Path_Depot.is_instance(self) == true, "Not a class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a P4 file list instance.
---
--- @nodiscard
function P4_Path_Depot:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object.__index == P4_Path_Depot then
      return true
    end
  end

  return false
end

--- Creates a new class instance.
---
--- @param path Depot_File_Path
--- @return P4_Path_Depot P4_Path A new P4 file.
---
--- @nodiscard
function P4_Path_Depot:new(path)

  local new = path_lib:new()

  setmetatable(new, P4_Path_Depot)

  --- @cast new P4_Path_Depot

  new.path = path

  return new
end

return P4_Path_Depot

