nio = require("nio")

local file_utils = require("p4.core.lib.file_utils")

--- @class P4_File : table
--- @field path_type P4_File_Path_Type Indicates the type of file path.
--- @field path P4_File_Path P4 file path
--- @field p4_cl P4_CL P4 CL.
--- @field fstat? P4_FStat P4 file stats.
P4_File = {}

--- Creates a new P4 file.
---
--- @param new_file New_P4_File New P4 file information.
--- @return P4_File P4_File A new P4 file.
--- @nodiscard
function P4_File:new(new_file)

  P4_File.__index = P4_File

  local new = setmetatable({}, P4_File)

  new.path_type = new_file.file_path_type
  new.path = file_utils.set_file_path(new_file.file_path_type, new_file.file_path)
  new.p4_cl = new_file.p4_cl

  return new
end

--- Gets the file path based on the type.
---
--- @return string result P4 file path.
function P4_File:get_file_path()
  --- @type string
  local result = nil

  if self.path_type == P4_FILE_PATH_TYPE.depot then
    result = self.path.depot
    return result
  end

  if self.path_type == P4_FILE_PATH_TYPE.client then
    result = self.path.client
    return result
  end

  if self.path_type == P4_FILE_PATH_TYPE.host then
    result = self.path.client
    return result
  end

  assert(result)

  return result
end


--- Opens the file for add.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
function P4_File:add(on_exit)

  log.fmt_debug("Opening the file for add: %s", self:get_file_path())

  nio.run(function()

    P4_Command_Add = require("p4.core.lib.command.add")

    local cmd = P4_Command_Add:new(self:get_file_path())

    local success, _ = pcall(cmd:run().wait)

    if success then

      log.fmt_debug("Successfully opened the file for add: %s", self:get_file_path())

    else
      log.fmt_debug("Failed to open the file for add: %s", self:get_file_path())
    end

    on_exit(success)
  end)
end

--- Open the file for edit.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
function P4_File:edit(on_exit)

  log.fmt_debug("Opening the file for edit: %s", self:get_file_path())

  nio.run(function()

    P4_Command_edit = require("p4.core.lib.command.edit")

    local cmd = P4_Command_edit:new(self:get_file_path())

    local success, _ = pcall(cmd:run().wait)

    if success then

      log.fmt_debug("Successfully opened the file for edit: %s", self:get_file_path())

    else
      log.fmt_debug("Failed to open the file for edit: %s", self:get_file_path())
    end

    on_exit(success)
  end)
end

--- Reverts the file.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
function P4_File:revert(on_exit)

  log.fmt_debug("Reverting the file: %s", self:get_file_path())

  nio.run(function()

    P4_Command_revert = require("p4.core.lib.command.revert")

    local cmd = P4_Command_revert:new(self:get_file_path())

    local success, _ = pcall(cmd:run().wait)

    if success then

      log.fmt_debug("Successfully reverted the file: %s", self:get_file_path())

    else
      log.fmt_debug("Failed to revert the file: %s", self:get_file_path())
    end

    on_exit(success)
  end)
end

--- Open the file for delete.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
function P4_File:delete(on_exit)

  log.fmt_debug("Opening the file for delete: %s", self:get_file_path())

  nio.run(function()

    P4_Command_delete = require("p4.core.lib.command.delete")

    local cmd = P4_Command_delete:new(self:get_file_path())

    local success, _ = pcall(cmd:run().wait)

    if success then

      log.fmt_debug("Successfully opened the file for delete: %s", self:get_file_path())

    else
      log.fmt_debug("Failed to open the file for delete: %s", self:get_file_path())
    end

    on_exit(success)
  end)
end

--- Updates the file's stats.
---
--- @param on_exit fun(success: boolean) Callback to invoke when the task is complete.
function P4_File:update_stats(on_exit)

  log.fmt_debug("Updating the file's stats: %s", self:get_file_path())

  nio.run(function()

    local P4_Command_FStat = require("p4.core.lib.command.fstat")

    local cmd = P4_Command_FStat:new(self:get_file_path())

    local success, sc = pcall(cmd:run().wait)

    if success then

      log.fmt_debug("Successfully updated the file's stats: %s", self:get_file_path())

      --- @cast sc vim.SystemCompleted

      self.spec = cmd:process_response(sc.stdout)[1]

    else
      log.fmt_debug("Failed to update the file's stats: %s", self:get_file_path())
    end

    on_exit(success)
  end)
end

return P4_File
