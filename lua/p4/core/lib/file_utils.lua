--- @enum P4_File_Path_Type
P4_FILE_PATH_TYPE = {
  depot = 0,
  client = 1,
  host = 2, -- Can't use local keyword
}

--- @class New_P4_File
--- @field file_path_type P4_File_Path_Type Indicates the type of file path.
--- @field file_path string P4 file path.
--- @field p4_cl P4_CL P4 CL.

--- @class P4_File_Path : table
--- @field depot string P4 depot file path
--- @field client string P4 client file path
--- @field host string P4 local file path

local M = {}

--- Sets the file path based on the type.
---
--- @param type P4_File_Path_Type Indicates the type of file path.
--- @param path string P4 file path.
--- @return P4_File_Path result P4 file path.
function M.set_file_path(type, path)
  --- @type P4_File_Path
  local result = {
    depot = "",
    client = "",
    host = "",
  }

  if type == P4_FILE_PATH_TYPE.depot then
    result.depot = path
    return result
  end

  if type == P4_FILE_PATH_TYPE.client then
    result.client = path
    return result
  end

  if type == P4_FILE_PATH_TYPE.host then
    result.host = path
    return result
  end

  assert(result.depot or result.client or result.host)

  return result
end

return M
