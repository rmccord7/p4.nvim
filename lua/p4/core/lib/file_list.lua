nio = require("nio")

--- @class P4_File_List : table
--- @field private list P4_File[] P4 file list.
--- @field private client? P4_Client P4 Client.
P4_File_List = {}

--- Creates a new P4 file list.
---
--- @param new_files New_P4_File[] One or more new files.
--- @param client P4_Client P4 client.
--- @return P4_File_List P4_File_List A new P4 file list.
--- @nodiscard
function P4_File_List:new(new_files, client)

  P4_File_List.__index = P4_File_List

  ---@class P4_File_List
  local new = setmetatable({}, P4_File_List)

  local P4_File = require("p4.core.lib.file")

  new.list = {}

  for _, path in ipairs(new_files) do
    local p4_file = P4_File:new(path)

    table.insert(new.list, p4_file)
  end

  new.client = client

  return new
end

--- Returns the list of P4 files.
---
--- @return P4_File[] result A list of P4 files.
function P4_File_List:get()
  return self.list
end

--- Generates a file path list.
---
--- @return string[] file_paths A list of file paths.
function P4_File_List:build_file_path_list()
  local result = {}

  for _, p4_file in ipairs(self.list) do
    table.insert(result, p4_file:get_file_path())
  end

  return result
end

--- Opens each file for add.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File_List:add(on_exit)

  log.debug("Opening each file for add")

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
  end)
end

--- Opens each file for edit.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File_List:edit(on_exit)

  log.debug("Opening each file for edit")

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
  end)
end

--- Reverts each file.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File_List:revert(on_exit)

  log.debug("Reverting each file")

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
  end)
end

--- Opens each file for delete.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File_List:delete(on_exit)

  log.debug("Opening each file for delete")

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
  end)
end

--- Updates each file's stats.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File_List:update_stats(on_exit)

  log.debug("Updating each file's stats")

  nio.run(function()

    local P4_Command_FStat = require("p4.core.lib.command.fstat")

    local cmd = P4_Command_FStat:new(self:build_file_path_list())

    local success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then

      log.debug("Successfully updated each file's stats")

      --- @type P4_Command_FStat_Result
      local result = cmd:process_response(sc.stdout)

      for index, p4_file in ipairs(self.list) do
        p4_file.fstat = result[index]
      end
    else
      log.fmt_debug("Failed to update each file's stats: %s", sc.stderr)
    end

    on_exit(success)
  end)
end

return P4_File_List
