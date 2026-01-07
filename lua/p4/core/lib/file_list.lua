local log = require("p4.log")

--- @class P4_File_List : table
--- @field protected file_paths File_Spec[] P4 files for efficient command usage.
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

    if object == P4_File_List then
      return true
    end
  end

  return false
end

--- @class P4_File_List_New
--- @field paths File_Spec[] P4 file path for each new file.
--- @field convert_depot_paths boolean If the list of file paths are depot paths that need to be converted to local paths.
--- @field check_in_depot boolean Check if the file is in the P4 depot.
--- @field get_info boolean Get the file's inforamtion from P4 server.
--- @field client P4_Client? Optional P4 client for all files.
--- @field cls P4_CL|P4_CL[]? Optional P4 CL for all files or a list of a CLs for each new file.

--- Creates a new P4 file list.
---
--- @param new_file_list P4_File_List_New New file list inforamtion.
--- @return boolean success True if this function is successful.
--- @return P4_File_List P4_File_List A new P4 file list if this function is sucessful.
---
--- @async
--- @nodiscard
function P4_File_List:new(new_file_list)
  log.trace("P4_File_List (new): Enter")

  local success = true

  local new = setmetatable({}, P4_File_List)

  local P4_File = require("p4.core.lib.file")

  new.file_paths = new_file_list.paths
  new.files = {}

  if new_file_list.cls and type(new_file_list.cls) == table then
    assert(#new_file_list.paths == #new_file_list.cls, "Path and CL lists must have the same length")
  end

  for index, path in ipairs(new_file_list.paths) do

    ---@type P4_File_New
    local new_file = {
      path = path,
      check_in_depot = false, -- More efficient to query for all files at once.
      get_stats = false, -- More efficient to query for all files at once.
      client = new_file_list.client,
    }

    -- All files may be the same CL or files may have different CLs.
    if new_file_list.cls then
      if type(new_file_list.cls) == "table" then
        new_file.cl = new_file_list.cls[index]
      else
        new_file.cl = new_file_list.cls
      end
    end

    --TODO: Maybe handle duplicates

    local p4_file

    success, p4_file = P4_File:new(new_file)

    if success and p4_file then
      table.insert(new.files, p4_file)
    else
      success = false
      break
    end
  end

  if success then
    if new_file_list.convert_depot_paths then
      local P4_Where_Commands = require("p4.core.lib.command.where")

      local results_list

      success, results_list = P4_Where_Commands:new(new_file_list.paths):run()

      if success and results_list then

        ---@cast results_list P4_Command_Where_Result[]
        for index, result in ipairs(results_list) do
          new.files[index].path = result.host
        end
      end
    end
  end

  if success then
    if new_file_list.check_in_depot then
      success = new:get_in_depot()
    end
  end

  if success then
    if new_file_list.get_info then
      success = new:update_info()
    end
  end

  new.client = new_file_list.client

  if new_file_list.cls and type(new_file_list) ~= "table" then
    new.cl = new_file_list.cls
  end

  log.trace("P4_File_List (new): Exit")

  return success, new
end

--- @class P4_File_List_Add_Entry : P4_File_New

--- Adds a new file to the file list.
---
--- @param file P4_File_List_Add_Entry P4 file to add the list.
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File_List:add_file(file)

  self:_check_instance()

  -- If this list belongs to a P4 client ensure this file also belongs to the same client.
  if self.cl then

    assert(self.client and file.client and self.client == file.client, "New file does not belong to the same client for current files in the list")

    return false
  end

  -- If this list belongs to a P4 CL ensure this file also belongs to the same CL.
  if self.cl then

    assert(self.cl and file.cl and self.cl == file.cl, "New file does not belong to the same CL for current files in the list")

    return false
  end

  table.insert(self.file_paths, file.path)

  local P4_File = require("p4.core.lib.file")

  local success, new_file = P4_File:new(file)

  if success then
    table.insert(self.files, new_file)
  end

  return success
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
        if path == self.files[index]:get_file_path() then
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

-- --- Builds a P4 file list from a a list of P4_Files[].
-- ---
-- --- @param p4_file_list P4_File[] One or more P4 files.
-- --- @return P4_File_List P4_File_List A new P4 file list.
-- --- @nodiscard
-- function P4_File_List:build(p4_file_list)
--
--   log.trace("P4_File_List: build")
--
--   assert(#p4_file_list, "File list is empty")
--
--   P4_File_List.__index = P4_File_List
--
--   ---@class P4_File_List
--   local new = setmetatable({}, P4_File_List)
--
--   new.files = {}
--   new.client = p4_file_list[1]:get().client
--
--   for _, p4_file in ipairs(p4_file_list) do
--     assert(p4_file.client == new.client, "Files in the file list must belong to the same client")
--
--     -- Files in the list may belong to different CLs.
--   end
--
--   new.files = p4_file_list
--
--   return new
-- end

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
--- @nodiscard
function P4_File_List:get_in_depot()
  log.trace("P4_File_List (get_in_depot): Enter")

  self:_check_instance()

  local P4_Command_Files = require("p4.core.lib.command.files")

  local success, result = P4_Command_Files:new(self.file_paths):run()

  if success then

    -- If we didn't get a result for every file then fail.
    if not vim.tbl_isempty(result.list) and vim.tbl_isempty(result.errors) then
      for index, _ in ipairs(result.list) do
        self.files[index].in_depot = true
      end
    else
      success = false
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
--- @return boolean success Indicates if the function was successful.
---
--- @async
--- @nodiscard
function P4_File_List:edit()
  log.trace("P4_File_List (edit): Enter")

  self:_check_instance()

  local P4_Command_Edit = require("p4.core.lib.command.edit")

  local success = P4_Command_Edit:new(self:build_file_path_list()):run()

  log.trace("P4_File_List (edit): Exit")

  return success
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

  local success, result = P4_Command_FStat:new(self.file_paths):run()

  if success and result then

    --- @cast result P4_Command_FStat_Result

    for index, file in ipairs(self.files) do
      file:set_info(result.file_info_list[index])
    end
  end

  log.trace("P4_File_List (update_info): Exit")

  return success
end

return P4_File_List
