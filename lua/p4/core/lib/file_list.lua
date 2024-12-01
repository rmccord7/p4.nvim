local nio = require("nio")

local log = require("p4.log")
local task = require("p4.task")

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
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File_List:add(on_exit)

  log.trace("P4_File_List: add")

  nio.run(function()

    local P4_Command_add = require("p4.core.lib.command.add")

    local cmd = P4_Command_add:new(self:build_file_path_list())

    local success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then

      log.debug("Successfully opened each file for add")

    else
      log.fmt_debug("Failed to open each file for add: %s", sc.stderr)
    end

    on_exit(success)
  end, function(success, ...)
    task.complete(on_exit, success, ...)
  end)
end

--- Opens each file for edit.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File_List:edit(on_exit)

  log.trace("P4_File_List: edit")

  nio.run(function()

    local P4_Command_Edit = require("p4.core.lib.command.edit")

    local cmd = P4_Command_Edit:new(self:build_file_path_list())

    local success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then

      log.debug("Successfully opened each file for edit")

    else
      log.fmt_debug("Failed to open each file for edit: %s", sc.stderr)
    end

    on_exit(success)
  end, function(success, ...)
    task.complete(on_exit, success, ...)
  end)
end

--- Reverts each file.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File_List:revert(on_exit)

  log.trace("P4_File_List: revert")

  nio.run(function()

    local P4_Command_Edit = require("p4.core.lib.command.edit")

    local cmd = P4_Command_Edit:new(self:build_file_path_list())

    local success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then

      log.debug("Successfully reverted each file")

    else
      log.fmt_debug("Failed to revert each file: %s", sc.stderr)
    end

    on_exit(success)
  end, function(success, ...)
    task.complete(on_exit, success, ...)
  end)
end

--- Opens each file for delete.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File_List:delete(on_exit)

  log.trace("P4_File_List: delete")

  nio.run(function()

    local P4_Command_delete = require("p4.core.lib.command.delete")

    local cmd = P4_Command_delete:new(self:build_file_path_list())

    local success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then

      log.debug("Successfully opened each file for delete")

    else
      log.fmt_debug("Failed to open each file for delete: %s", sc.stderr)
    end

    on_exit(success)
  end, function(success, ...)
    task.complete(on_exit, success, ...)
  end)
end

--- Updates each file's stats.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File_List:update_stats(on_exit)

  log.trace("P4_File_List: update_stats")

  nio.run(function()

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

    on_exit(success)
  end, function(success, ...)
    task.complete(on_exit, success, ...)
  end)
end

return P4_File_List
