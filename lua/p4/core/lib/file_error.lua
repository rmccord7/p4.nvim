local path_depot_lib = require("p4.core.lib.path_depot")

--- @class P4_File_Error_Info
--- @field path Depot_File_Path | Local_File_Path Depot path or name of file if not in the client view.
--- @field reason string Reason for the error.

--- @class P4_File_Error
--- @field protected path P4_Path_Depot | Local_File_Path
--- @field protected reason string
local P4_File_Error = {}

P4_File_Error.__index = P4_File_Error

--- Wrapper function to check if a table is an instance of this class.
function P4_File_Error:_check_instance()
  assert(P4_File_Error.is_instance(self) == true, "Not a class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a P4 file list instance.
---
--- @nodiscard
function P4_File_Error:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object.__index == P4_File_Error then
      return true
    end
  end

  return false
end

--- Creates a new P4 error file.
---
--- @param info P4_File_Error_Info File error inforamtion.
--- @return P4_File_Error P4_File_Error A new P4 file error.
---
--- @nodiscard
function P4_File_Error:new(info)
  vim.validate("info", info, "table")

  local new = setmetatable({}, P4_File_Error)

  -- Check for depot path prefix.
  if info.path:find("^//") then
    new.path = path_depot_lib:new(info.path)
  else
    new.path = info.path
  end

  new.reason = info.reason

  return new
end

--- Creates a new P4 error file.
---
--- @return P4_File_Error_Info result P4 file error information.
---
--- @nodiscard
function P4_File_Error:get_info()
  self:_check_instance()

  local path

  if type(self.path) == "table" then
    path = self.path.path
  else
    path = self.path
  end

  return {
    path = path,
    reason = self.reason,
  }
end

return P4_File_Error
