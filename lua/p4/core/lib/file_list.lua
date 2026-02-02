local log = require("p4.log")

local error_handler_api = require("p4.api.error_handler")

--- @class P4_File_List : table
--- @field protected file_paths File_Path[] P4 files for efficient command usage.
--- @field protected files P4_File[] P4 files.
--- @field protected client P4_Client? P4 Client for all files.
--- @field protected cl P4_CL? P4 CL for all files. Only valid if all files have the same CL.
local P4_File_List = {}

P4_File_List.__index = P4_File_List

--- Wrapper function to check if a table is an instance of this class.
function P4_File_List:_check_instance()
  assert(P4_File_List.is_instance(self) == true, "Not a P4 file list class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
---
--- @async
--- @nodiscard
function P4_File_List:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object.__index == P4_File_List then
      return true
    end
  end

  return false
end

--- Creates a new P4 file list.
---
--- @param files (File_Path[] | P4_File[])? File paths.
--- @return P4_File_List P4_File_List A new P4 file list if this function is sucessful.
---
--- @nodiscard
function P4_File_List:new(files)
  vim.validate("files", files, "table", true)

  local new = setmetatable({}, P4_File_List)

  new.files = {}
  new.file_paths = {}

  local file_lib = require("p4.core.lib.file")

  if files then
    for _, file  in ipairs(files) do

      --- @cast file P4_File

      if file_lib.is_instance(file) then
        table.insert(new.files, file)
        table.insert(new.file_paths, file:get_info().path)
      else

        --- @cast file File_Path
        table.insert(new.files, file_lib:new(file))
        table.insert(new.file_paths, file)
      end
    end
  end

  return new
end

--- Adds a new P4 file to the list of P4 files.
---
--- @param file File_Path | P4_File P4 file.
function P4_File_List:add_file(file)
  vim.validate("file", file, {"string", "table"})

  self:_check_instance()

  --- @cast file P4_File

  local file_lib = require("p4.core.lib.file")

  if file_lib.is_instance(file) then
    table.insert(self.files, file)
    table.insert(self.file_paths, file:get_info())
  else

    --- @cast file File_Path
    table.insert(self.files, file_lib:new(file))
    table.insert(self.file_paths, file)
  end
end

--- Removes a file from the file list.
---
--- @param path File_Spec P4 file to add the list.
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File_List:remove_file(path)

  self:_check_instance()

  local success = false

  if #self.file_paths and #self.files then

    for index, current in ipairs(self.file_paths) do
      if current == path  then
        table.remove(self.file_paths, index)

        -- These should be in sync
        if path == self.files[index]:get_info() then
          table.remove(self.files, index)
        else
          -- If they are not in sync we need to find it.
          for index2, current2 in ipairs(self.files) do
            if current2 == path  then
              table.remove(self.files, index2)
              break
            end
          end
        end

        success = true
        break
      end
    end
  end

  return success
end

--- Returns the list of file paths.
---
--- @return string[] result File paths.
function P4_File_List:get_file_paths()
  log.trace("P4_File_List (get_file_paths): Enter")

  self:_check_instance()

  log.trace("P4_File_List (get_file_paths): Exit")

  return self.file_paths
end

--- Returns the list of files.
---
--- @return P4_File[] result Files.
function P4_File_List:get_files()
  log.trace("P4_File_List (get_files): Enter")

  self:_check_instance()

  log.trace("P4_File_List (get_files): Exit")

  return self.files
end

--- Updates if the files are in the depot.
---
--- @return boolean success True if this function is successful.
---
--- @async
function P4_File_List:get_in_depot()
  log.trace("P4_File_List (get_in_depot): Enter")

  self:_check_instance()

  local P4_Command_Files = require("p4.core.lib.command.files")

  local success, results = P4_Command_Files:new(self.file_paths):run()

  if success and results then

    assert(#results == #self.file_paths, "Unexpected number of results")

    for _, result in ipairs(results) do
      if result.success then

        --TODO: Could update some file information here.
        self.in_depot = true
      else
        local error = result.data.error

        -- If file doens't exist on the P4 server, then it is not in the depot.
        if error:is_file_does_not_exist() then
          self.in_depot = false
        else
          -- Any other error is fatal.
          success = false
        end
        break
      end
    end
  end

  log.trace("P4_File_List (get_in_depot): Exit")

  return success
end

--- Generates a file path list.
---
--- @return string[] file_paths A list of file paths.
function P4_File_List:build_file_path_list()
  log.trace("P4_File_List (build_file_path_list): Enter")

  self:_check_instance()

  local result = {}

  for _, p4_file in ipairs(self.files) do
    table.insert(result, p4_file.path)
  end

  log.trace("P4_File_List (build_file_path_list): Exit")

  return result
end

--- Opens each file for add.
---
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File_List:add()
  log.trace("P4_File_List (add): Enter")

  self:_check_instance()

  local P4_Command_Add = require("p4.core.lib.command.add")

  local success = P4_Command_Add:new(self:build_file_path_list()):run()

  log.trace("P4_File_List (add): Exit")

  return success
end

--- Opens each file for edit.
---
--- @return P4_File[] results List of P4 files that have been opened for edit.

--- @async
--- @nodiscard
function P4_File_List:edit()
  self:_check_instance()

  -- Make sure all the files are in the depot.
  self:get_in_depot()

  if self.in_depot then

    local file_api = require("p4.api.file")

    -- Get the list of files.
    local file_paths = self:get_file_paths()

    local success, result_file_list = xpcall(file_api.edit, error_handler_api.process, file_paths)

    if success then

      local files = self:get_files()
      local result_files = result_file_list:get_files()

      assert(#files == #result_files)

      for index, value in ipairs(t) do

      end
    end
  end
end

--- Reverts each file.
---
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File_List:revert()
  log.trace("P4_File_List (revert): Enter")

  self:_check_instance()

  local P4_Command_Edit = require("p4.core.lib.command.edit")

  local success = P4_Command_Edit:new(self:build_file_path_list()):run()

  log.trace("P4_File_List (revert): Exit")

  return success
end

--- Opens each file for delete.
---
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File_List:delete()
  log.trace("P4_File_List (delete): Enter")

  self:_check_instance()

  local P4_Command_delete = require("p4.core.lib.command.delete")

  local success = P4_Command_delete:new(self:build_file_path_list()):run()

  log.trace("P4_File_List (delete): Exit")

  return success
end

--- Updates each file's information.
---
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File_List:update_info()
  log.trace("P4_File_List (update_info): Enter")

  self:_check_instance()

  assert(#self.file_paths, "No file paths")

  local P4_Command_FStat = require("p4.core.lib.command.fstat")

  local success, results = P4_Command_FStat:new(self.file_paths):run()

  if success and results then

    assert(#results == #self.file_paths, "Unexpected number of results")

    for index, result in ipairs(results) do
      if result.success then
        local file = self.files[index]

        file:update(result.data)
      else
        -- Any other error is fatal.
        success = false
        break
      end
    end
  end

  log.trace("P4_File_List (update_info): Exit")

  return success
end

return P4_File_List
