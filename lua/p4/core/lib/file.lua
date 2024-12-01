local nio = require("nio")

local log = require("p4.log")
local task = require("p4.task")

local P4_File_Path = require("p4.core.lib.file_path")

--- @class P4_File : table
--- @field protected path P4_File_Path P4 file path.
--- @field protected cl? P4_CL P4 CL.
--- @field protected fstat? P4_FStat P4 file stats.
local P4_File = {}

--- @class P4_New_File_Information
--- @field path P4_Path P4 file path.
--- @field cl? P4_CL P4 CL.

--- Creates a new P4 file.
---
--- @param new_file P4_New_File_Information New P4 file information.
--- @return P4_File P4_File A new P4 file.
--- @nodiscard
function P4_File:new(new_file)

  log.trace("P4_File: new")

  P4_File.__index = P4_File

  local new = setmetatable({}, P4_File)

  new.path = P4_File_Path:new(new_file.path)

  -- A new file may not have a CL associated with it yet until it has been
  -- opened in the client workspace.
  new.cl = new_file.cl or nil

  return new
end

--- @class P4_File_Information
--- @field path P4_File_Path P4 file path.
--- @field p4_cl P4_CL P4 CL.

--- Returns the File's information.
---
--- @return P4_File_Information result P4 file list.
--- @nodiscard
function P4_File:get()
  log.trace("P4_File: get")

  return {
    self.path,
  }
end

--- Sets the P4 CL.
---
--- @param cl P4_CL P4 cl.
function P4_File:set_cl(cl)
  log.trace("P4_File: set_cl")

  self.cl = cl
end

--- Returns the P4 CL.
---
--- @return P4_CL cl? P4 CL.
--- @nodiscard
function P4_File:get_cl()
  log.trace("P4_File: get_cl")

  return self.cl
end

--- Set's the file's stats.
---
--- @param fstat P4_FStat P4 file stat.
function P4_File:set_file_stats(fstat)
  log.trace("P4_File: set_file_stats")

  self.fstat = fstat
end

--- Returns the file's stats.
---
--- @return P4_FStat P4 file stats.
--- @nodiscard
function P4_File:get_file_stats()
  log.trace("P4_File: get_file_stats")

  return self.fstat
end

--- Opens the file for add.
---
--- @param on_exit? fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File:add(on_exit)

  log.trace("P4_File: add")

  nio.run(function()

    P4_Command_Add = require("p4.core.lib.command.add")

    local cmd = P4_Command_Add:new(self.path:get_file_path())

    local success, _ = pcall(cmd:run().wait)

    if success then

      log.fmt_debug("Successfully opened the file for add: %s", self.path:get_file_path())

    else
      log.fmt_debug("Failed to open the file for add: %s", self.path:get_file_path())
    end

    if on_exit then
      on_exit(success)
    end
  end, function(success, ...)
    task.complete(on_exit, success, ...)
  end)
end

--- Open the file for edit.
---
--- @param on_exit? fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File:edit(on_exit)

  log.trace("P4_File: edit")

  nio.run(function()

    P4_Command_edit = require("p4.core.lib.command.edit")

    local cmd = P4_Command_edit:new(self.path:get_file_path())

    local success, _ = pcall(cmd:run().wait)

    if success then

      log.fmt_debug("Successfully opened the file for edit: %s", self.path:get_file_path())

    else
      log.fmt_debug("Failed to open the file for edit: %s", self.path:get_file_path())
    end

    if on_exit then
      on_exit(success)
    end
  end, function(success, ...)
    task.complete(on_exit, success, ...)
  end)
end

--- Reverts the file.
---
--- @param on_exit? fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File:revert(on_exit)

  log.trace("P4_File: revert")

  nio.run(function()

    P4_Command_revert = require("p4.core.lib.command.revert")

    local cmd = P4_Command_revert:new(self.path:get_file_path())

    local success, _ = pcall(cmd:run().wait)

    if success then

      log.fmt_debug("Successfully reverted the file: %s", self.path:get_file_path())

    else
      log.fmt_debug("Failed to revert the file: %s", self.path:get_file_path())
    end

    if on_exit then
      on_exit(success)
    end
  end, function(success, ...)
    task.complete(on_exit, success, ...)
  end)
end

--- Open the file for delete.
---
--- @param on_exit? fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File:delete(on_exit)

  log.trace("P4_File: delete")

  nio.run(function()

    P4_Command_delete = require("p4.core.lib.command.delete")

    local cmd = P4_Command_delete:new(self.path:get_file_path())

    local success, _ = pcall(cmd:run().wait)

    if success then

      log.fmt_debug("Successfully opened the file for delete: %s", self.path:get_file_path())

    else
      log.fmt_debug("Failed to open the file for delete: %s", self.path:get_file_path())
    end

    if on_exit then
      on_exit(success)
    end
  end, function(success, ...)
    task.complete(on_exit, success, ...)
  end)
end

--- Updates the file's stats.
---
--- @param on_exit? fun(success: boolean) Callback to invoke when the task is complete.
--- @async
function P4_File:update_stats(on_exit)

  log.trace("P4_File: update_stats")

  nio.run(function()

    local P4_Command_FStat = require("p4.core.lib.command.fstat")

    local cmd = P4_Command_FStat:new(self.path:get_file_path())

    local success, sc = pcall(cmd:run().wait)

    if success then

      log.fmt_debug("Successfully updated the file's stats: %s", self.path:get_file_path())

      --- @cast sc vim.SystemCompleted

      self.spec = cmd:process_response(sc.stdout)[1]

    else
      log.fmt_debug("Failed to update the file's stats: %s", self.path:get_file_path())
    end

    if on_exit then
      on_exit(success)
    end
  end, function(success, ...)
    task.complete(on_exit, success, ...)
  end)
end

return P4_File
