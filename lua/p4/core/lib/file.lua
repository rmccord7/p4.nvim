local nio = require("nio")

local log = require("p4.log")

local P4_File_Path = require("p4.core.lib.file_path")

--- @class P4_File_Stats : table
--- @field clientFile P4_Host_File_Path Local path to the file.
--- @field depotFile P4_Depot_File_Path Depot path to the file.
--- @field isMapped boolean Indicates if file is mapped to the current client workspace.
--- @field shelved boolean Indicates if file is shelved.
--- @field change string Open change list number if file is opened in client workspace.
--- @field headRev integer Head revision number if in depot.
--- @field haveRev integer Revision last synced to workpace.
--- @field workRev integer Revision if file is opened.
--- @field action string Open action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).

--- @class P4_File_Revision : table
--- @field depot_file P4_Depot_File_Path Depot path to the file.
--- @field number string Revision number.
--- @field action string CL Action.
--- @field cl string CL ID.
--- @field user string CL user.
--- @field client string Name of the client associated with the CL.
--- @field date P4_Command_Describe_Result_Date_Time CL submission date/time.
--- @field description string CL description.

--- @class P4_File : table
--- @field protected client P4_Client P4 Client.
--- @field protected cl P4_CL P4 CL.
--- @field protected path P4_File_Path P4 file path.
--- @field protected fstat? P4_File_Stats P4 file stats.
local P4_File = {}

--- @class P4_New_File_Information
--- @field client P4_Client P4 Client.
--- @field cl P4_CL P4 CL.
--- @field path P4_Path P4 file path.

--- Creates a new P4 file.
---
--- @param new_file P4_New_File_Information New P4 file information.
--- @return P4_File P4_File A new P4 file.
--- @nodiscard
function P4_File:new(new_file)

  log.trace("P4_File: new")

  P4_File.__index = P4_File

  local new = setmetatable({}, P4_File)

  new.client = new_file.client
  new.cl = new_file.cl
  new.path = P4_File_Path:new(new_file.path)

  return new
end

--- @class P4_File_Information
--- @field client P4_Client P4 Client.
--- @field cl P4_CL P4 CL.
--- @field path P4_File_Path P4 file path.

--- Returns the File's information.
---
--- @return P4_File_Information result P4 file list.
--- @nodiscard
function P4_File:get()
  log.trace("P4_File: get")

  return {
    client = self.client,
    cl = self.cl,
    path = self.path,
  }
end

--- Sets the P4 CL.
---
--- @param cl P4_CL P4 cl.
function P4_File:set_cl(cl)
  log.trace("P4_File: set_cl")

  self.cl = cl
end

--- Set's the file's stats.
---
--- @param fstat P4_File_Stats P4 file stat.
function P4_File:set_file_stats(fstat)
  log.trace("P4_File: set_file_stats")

  self.fstat = fstat
end

--- Returns the file's stats.
---
--- @return P4_File_Stats? P4 file stats.
--- @nodiscard
function P4_File:get_file_stats()
  log.trace("P4_File: get_file_stats")

  return self.fstat
end

--- Opens the file for add.
---
--- @return nio.control.Future future Future to wait on.
--- @nodiscard
--- @async
function P4_File:add()

  log.trace("P4_File: add")

  local future = nio.control.future()

  local P4_Command_Add = require("p4.core.lib.command.add")

  local cmd = P4_Command_Add:new({self.path:get_file_path()})

  local success, _ = pcall(cmd:run().wait)

  if success then
    log.fmt_debug("Successfully opened the file for add: %s", self.path:get_file_path())

    future.set()
  else
    log.fmt_debug("Failed to open the file for add: %s", self.path:get_file_path())

    future.set_error()
  end

  return future
end

--- Open the file for edit.
---
--- @return nio.control.Future future Future to wait on.
--- @nodiscard
--- @async
function P4_File:edit()

  log.trace("P4_File: edit")

  local future = nio.control.future()

  local P4_Command_Edit = require("p4.core.lib.command.edit")

  local cmd = P4_Command_Edit:new({self.path:get_file_path()})

  local success, _ = pcall(cmd:run().wait)

  if success then
    log.fmt_debug("Successfully opened the file for edit: %s", self.path:get_file_path())

    future.set()
  else
    log.fmt_debug("Failed to open the file for edit: %s", self.path:get_file_path())

    future.set_error()
  end

  return future
end

--- Reverts the file.
---
--- @return nio.control.Future future Future to wait on.
--- @nodiscard
--- @async
function P4_File:revert()

  log.trace("P4_File: revert")

  local future = nio.control.future()

  local P4_Command_Revert = require("p4.core.lib.command.revert")

  local cmd = P4_Command_Revert:new({self.path:get_file_path()})

  local success, _ = pcall(cmd:run().wait)

  if success then
    log.fmt_debug("Successfully reverted the file: %s", self.path:get_file_path())

    future.set()
  else
    log.fmt_debug("Failed to revert the file: %s", self.path:get_file_path())

    future.set_error()
  end

  return future
end

--- Open the file for delete.
---
--- @return nio.control.Future future Future to wait on.
--- @nodiscard
--- @async
function P4_File:delete()

  log.trace("P4_File: delete")

  local future = nio.control.future()

  local P4_Command_Delete = require("p4.core.lib.command.delete")

  local cmd = P4_Command_Delete:new({self.path:get_file_path()})

  local success, _ = pcall(cmd:run().wait)

  if success then
    log.fmt_debug("Successfully opened the file for delete: %s", self.path:get_file_path())

    future.set()
  else
    log.fmt_debug("Failed to open the file for delete: %s", self.path:get_file_path())

    future.set_error()
  end

  return future
end

--- Updates the file's stats.
---
--- @return nio.control.Future future Future to wait on.
--- @nodiscard
--- @async
function P4_File:update_stats()

  log.trace("P4_File: update_stats")

  local future = nio.control.future()

  local P4_Command_FStat = require("p4.core.lib.command.fstat")

  local cmd = P4_Command_FStat:new({self.path:get_file_path()})

  local success, sc = pcall(cmd:run().wait)

  if success then

    log.fmt_debug("Successfully updated the file's stats: %s", self.path:get_file_path())

    --- @cast sc vim.SystemCompleted

    self.spec = cmd:process_response(sc.stdout)[1]

    future.set()
  else
    log.fmt_debug("Failed to update the file's stats: %s", self.path:get_file_path())

    future.set_error()
  end

  return future
end

return P4_File
