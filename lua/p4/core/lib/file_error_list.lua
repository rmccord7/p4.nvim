local file_error_lib = require("p4.core.lib.file_error")

--- @class P4_File_Error_List
--- @field protected files P4_File_Error[] P4 files.
local P4_File_Error_List = {}

P4_File_Error_List.__index = P4_File_Error_List

--- Wrapper function to check if a table is an instance of this class.
function P4_File_Error_List:_check_instance()
  assert(P4_File_Error_List.is_instance(self) == true, "Not a P4 file list class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
---
--- @async
--- @nodiscard
function P4_File_Error_List:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object and object.__index == P4_File_Error_List then
      return true
    end
  end

  return false
end

--- Creates a new P4 file list.
---
--- @param files (P4_File_Error|P4_File_Error)[]? List of file errors.
--- @return P4_File_Error_List P4_File_Error_List A new P4 file list if this function is sucessful.
---
--- @nodiscard
function P4_File_Error_List:new(files)
  vim.validate("files", files, "table", true)

  local new = setmetatable({}, P4_File_Error_List)

  new.files = {}

  if files then
    for _, file  in ipairs(files) do
      if file_error_lib.is_instance(file) then
        table.insert(new.files, file)
      else
        for _, error_file in ipairs(files) do
          if file_error_lib.is_instance(error_file) then
            table.insert(self.files, error_file)
          else
            assert(false, "Not a file error class instance")
          end
        end
      end
    end
  end

  return new
end

--- Adds a new P4 file to the list of P4 files.
---
--- @param files P4_File_Error|P4_File_Error[] List of file errors.
function P4_File_Error_List:add_file(files)
  vim.validate("files", files, "table")

  self:_check_instance()

  if file_error_lib.is_instance(files) then
    table.insert(self.files, files)
  else
    for _, error_file in ipairs(files) do
      if file_error_lib.is_instance(error_file) then
        table.insert(self.files, error_file)
      else
        assert(false, "Not a file error class instance")
      end
    end
  end
end

--- Returns the list of files.
---
--- @return P4_File_Error[] result File_Errors.
function P4_File_Error_List:get_files()
  self:_check_instance()

  return self.files
end

return P4_File_Error_List
