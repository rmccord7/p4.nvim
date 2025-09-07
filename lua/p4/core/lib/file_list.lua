local log = require("p4.log")

--- @class P4_File_List : table
--- @field protected files P4_File[] P4 files.
--- @field protected client P4_Client P4 Client.
local P4_File_List = {}

--- Creates a new P4 file list.
---
--- @param new_file_info_list P4_New_File_Information[] One or more new files.
--- @return P4_File_List P4_File_List A new P4 file list.
--- @nodiscard
function P4_File_List:new(new_file_info_list)

  log.trace("P4_File_List: new")

  P4_File_List.__index = P4_File_List

  ---@class P4_File_List
  local new = setmetatable({}, P4_File_List)

  local P4_File = require("p4.core.lib.file")

  new.files = {}
  new.client = new_file_info_list[1].client

  for _, new_file_info in ipairs(new_file_info_list) do
    local p4_file = P4_File:new(new_file_info)

    assert(p4_file.client == new.client, "Files in the file list must belong to the same client")

    -- Files in the list may belong to different CLs.

    table.insert(new.files, p4_file)
  end

  return new
end

--- Builds a P4 file list from a a list of P4_Files[].
---
--- @param p4_file_list P4_File[] One or more P4 files.
--- @return P4_File_List P4_File_List A new P4 file list.
--- @nodiscard
function P4_File_List:build(p4_file_list)

  log.trace("P4_File_List: build")

  assert(#p4_file_list, "File list is empty")

  P4_File_List.__index = P4_File_List

  ---@class P4_File_List
  local new = setmetatable({}, P4_File_List)

  new.files = {}
  new.client = p4_file_list[1]:get().client

  for _, p4_file in ipairs(p4_file_list) do
    assert(p4_file.client == new.client, "Files in the file list must belong to the same client")

    -- Files in the list may belong to different CLs.
  end

  new.files = p4_file_list

  return new
end

--- @class P4_File_List_Information
--- @field files P4_File[] P4 files.
--- @field client P4_Client P4 client.

--- Returns the File list's information.
---
--- @return P4_File_List_Information result P4 file list information..
function P4_File_List:get()
  log.trace("P4_File_List: get")

  return {
    files = self.files,
    client = self.client,
  }
end

--- Generates a file path list.
---
--- @return string[] file_paths A list of file paths.
function P4_File_List:build_file_path_list()
  log.trace("P4_File_List: build_file_path_list")

  local result = {}

  for _, p4_file in ipairs(self.files) do
    table.insert(result, p4_file.path:get_file_path())
  end

  return result
end

--- Opens each file for add.
---
--- @async
function P4_File_List:add()

  log.trace("P4_File_List: add")

  local P4_Command_Add = require("p4.core.lib.command.add")

  local cmd = P4_Command_Add:new(self:build_file_path_list())

  local success, sc = pcall(cmd:run().wait)

  --- @cast sc vim.SystemCompleted

  if success then

    log.debug("Successfully opened each file for add")
  else
    log.fmt_debug("Failed to open each file for add: %s", sc.stderr)
  end
end

--- Opens each file for edit.
---
--- @async
function P4_File_List:edit()

  log.trace("P4_File_List: edit")

  local P4_Command_Edit = require("p4.core.lib.command.edit")

  local cmd = P4_Command_Edit:new(self:build_file_path_list())

  local success, sc = pcall(cmd:run().wait)

  --- @cast sc vim.SystemCompleted

  if success then
    log.debug("Successfully opened each file for edit")
  else
    log.fmt_debug("Failed to open each file for edit: %s", sc.stderr)
  end
end

--- Reverts each file.
---
--- @async
function P4_File_List:revert()

  log.trace("P4_File_List: revert")

  local P4_Command_Edit = require("p4.core.lib.command.edit")

  local cmd = P4_Command_Edit:new(self:build_file_path_list())

  local success, sc = pcall(cmd:run().wait)

  --- @cast sc vim.SystemCompleted

  if success then
    log.debug("Successfully reverted each file")
  else
    log.fmt_debug("Failed to revert each file: %s", sc.stderr)
  end
end

--- Opens each file for delete.
---
--- @async
function P4_File_List:delete()

  log.trace("P4_File_List: delete")

  local P4_Command_delete = require("p4.core.lib.command.delete")

  local cmd = P4_Command_delete:new(self:build_file_path_list())

  local success, sc = pcall(cmd:run().wait)

  --- @cast sc vim.SystemCompleted

  if success then
    log.debug("Successfully opened each file for delete")
  else
    log.fmt_debug("Failed to open each file for delete: %s", sc.stderr)
  end
end

--- Updates each file's stats.
---
--- @async
function P4_File_List:update_stats()

  log.trace("P4_File_List: update_stats")

  local P4_Command_FStat = require("p4.core.lib.command.fstat")

  local cmd = P4_Command_FStat:new(self:build_file_path_list())

  local success, sc = pcall(cmd:run().wait)

  --- @cast sc vim.SystemCompleted

  if success then

    log.debug("Successfully updated each file's stats")

    --- @type P4_Command_FStat_Result
    local result = cmd:process_response(sc.stdout)

    for index, file in ipairs(self.files) do
      file:set_file_stats(result[index])
    end
  else
    log.fmt_debug("Failed to update each file's stats: %s", sc.stderr)
  end
end

return P4_File_List
