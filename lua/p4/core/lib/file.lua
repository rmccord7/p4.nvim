local log = require("p4.log")

--- Represents a path to a file.
---@alias Local_File_Path string Local path to the file.
---@alias Depot_File_Path string Depot path to the file.
---@alias Client_File_Path string Client path to the file.
---@alias File_Path Local_File_Path | Depot_File_Path | Client_File_Path Any file path.

--- Represents one or more files (wildcard).
---@alias Local_File_Spec string Local file syntax.
---@alias Depot_File_Spec string Depot file syntax.
---@alias Client_File_Spec string Client file syntax.
---@alias File_Spec Local_File_Spec | Depot_File_Spec | Client_File_Spec Any file syntax.

--- @class P4_File_Stats : table
--- @field clientFile Client_File_Path Local path to the file.
--- @field depotFile Depot_File_Path Depot path to the file.
--- @field isMapped boolean Indicates if file is mapped to the current client workspace.
--- @field shelved boolean Indicates if file is shelved.
--- @field change string Open change list number if file is opened in client workspace.
--- @field headRev integer Head revision number if in depot.
--- @field haveRev integer Revision last synced to workpace.
--- @field workRev integer Revision if file is opened.
--- @field action string Open action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).

--- @class P4_File_Revision : table
--- @field depot_file Depot_File_Path Depot path to the file.
--- @field number string Revision number.
--- @field action string CL Action.
--- @field cl string CL ID.
--- @field user string CL user.
--- @field client string Name of the client associated with the CL.
--- @field date P4_Command_Describe_Result_Date_Time CL submission date/time.
--- @field description string CL description.

--- @class P4_File : table
--- @field protected path File_Path File spec.
--- @field protected in_depot boolean Indicates if the file is in the P4 depot.
--- @field protected fstat? P4_File_Stats P4 file stats.
--- @field protected client? P4_Client P4 client for the current file.
--- @field protected cl? P4_CL P4 CL for the current file.
local P4_File = {}

--- Wrapper function to check if a table is an instance of this class.
function P4_File:_check_instance()
  assert(P4_File.is_instance(self) == true, "Not a P4 file class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_File:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_File then
      return true
    end
  end

  return false
end

--- @class P4_File_New
--- @field path File_Path P4 file path.
--- @field check_in_depot boolean Check if the file is in the P4 depot.
--- @field get_stats boolean Get file stats from P4 server.
--- @field client? P4_Client Optional P4 Client.
--- @field cl? P4_CL Optional P4 CL.

--- Creates a new P4 file.
---
--- @param new_file P4_File_New New P4 file information.
--- @return boolean success True if this function is successful.
--- @return P4_File P4_File A new P4 file if this function is successful.
---
--- @async
--- @nodiscard
function P4_File:new(new_file)
  log.trace("P4_File (new): Enter")

  local success = true

  P4_File.__index = P4_File

  local new = setmetatable({}, P4_File)

  new.path = new_file.path
  new.fstat = nil
  new.client = new_file.client or nil
  new.cl = new_file.cl or nil

  if success then
    if new_file.check_in_depot then
      success = new:get_in_depot()
    end
  end

  if success then
    if new_file.get_stats then
      success = new:get_fstat()
    end
  end

  log.trace("P4_File (new): Exit")

  return success, new
end

--- Gets the P4 file's path.
---
--- @return File_Path? P4 file path.
---
--- @nodiscard
function P4_File:get_file_path()
  log.trace("P4_File (get_file_path): Enter")

  self:_check_instance()

  log.trace("P4_File (get_file_path): Exit")

  return self.path
end

--- @class P4_File_Get_In_Depot_Opts : table
--- @field force boolean Forces an fstat update for the P4 file before returning the value.
local P4_File_Get_In_Depot_Opts = {
  force = false,
}

--- Updates if the file is in the depot.
---
--- @param opts? P4_File_Get_In_Depot_Opts Options.
--- @return boolean success True if this function is successful.
--- @return boolean? in_depot True if file is in the depot.
---
--- @async
--- @nodiscard
function P4_File:get_in_depot(opts)
  log.trace("P4_File (get_in_depot): Enter")

  self:_check_instance()

  opts = vim.tbl_deep_extend("force", P4_File_Get_In_Depot_Opts, opts or {})

  local success = true

  if not self.in_depot or opts.force then

    local P4_Command_Files = require("p4.core.lib.command.files")

    success, result_list = P4_Command_Files:new({self.path}):run()

    if success then

      if #result_list then
        self.in_depot = true
      else
        self.in_depot = false
      end
    end
  end

  log.trace("P4_File (get_in_depot): Exit")

  return success, self.in_depot
end

--- @class P4_File_Get_FStat_Opts : table
--- @field force boolean Forces an fstat update for the P4 file before returning the value.
local P4_File_Get_FStat_Opts = {
  force = false,
}

--- Get's the file's stats.
---
--- @param opts? P4_File_Get_FStat_Opts Options.
--- @return boolean success True if this function is successful.
--- @return P4_File_Stats? P4_File_Stats P4 files stats.
---
--- @async
--- @nodiscard
function P4_File:get_fstat(opts)
  log.trace("P4_File (get_fstat): Enter")

  self:_check_instance()

  opts = vim.tbl_deep_extend("force", P4_File_Get_FStat_Opts, opts or {})

  local success = true

  if not self.fstat or opts.force  then
    success = self:update_stats()
  end

  log.trace("P4_File (get_fstat): Exit")

  return success, self.fstat
end

--- Set's the file's stats.
---
--- @param fstat P4_File_Stats P4 file stat.
function P4_File:set_fstat(fstat)
  log.trace("P4_File (set_fstat): Enter")

  self:_check_instance()

  log.trace("P4_File (set_fstat): Exit")

  self.fstat = fstat
end

--- Gets the P4 CL.
---
--- @return P4_CL? P4 CL.
---
--- @nodiscard
function P4_File:get_cl()
  log.trace("P4_File (get_cl): Enter")

  self:_check_instance()

  log.trace("P4_File (get_cl): Exit")

  return(self.cl)
end

--- Sets the P4 CL.
---
--- @param cl P4_CL P4 cl.
function P4_File:set_cl(cl)
  log.trace("P4_File (set_cl): Enter")

  self:_check_instance()

  self.cl = cl

  log.trace("P4_File (set_cl): Exit")
end

--- Gets the P4 Client.
---
--- @return P4_Client? P4 Client.
---
--- @nodiscard
function P4_File:get_client()
  log.trace("P4_File (get_client): Enter")

  self:_check_instance()

  return(self.client)
end

--- Sets the P4 Client.
---
--- @param client P4_Client P4 client.
function P4_File:set_client(client)
  log.trace("P4_File (set_client): Enter")

  self:_check_instance()

  self.client = client

  log.trace("P4_File (set_client): Exit")
end

--- Opens the file for add.
---
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File:add()
  log.trace("P4_File (add): Enter")

  self:_check_instance()

  local success = false

  -- Ensure file has not already been added to the depot.
  if self:get_in_depot() then

    if not self.in_depot then
      local P4_Command_Add = require("p4.core.lib.command.add")

      success = P4_Command_Add:new({self.path}):run()
    else
      log.error("P4_File (add): Can't add a file that is already in the depot")
    end
  end

  log.trace("P4_File (add): Exit")

  return success
end

--- Open the file for edit.
---
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File:edit()
  log.trace("P4_File (edit): Enter")

  self:_check_instance()

  local success = false

  -- Ensure file has not already been added to the depot.
  if self:get_in_depot() then

    if self.in_depot then
      local P4_Command_Edit = require("p4.core.lib.command.edit")

      success = P4_Command_Edit:new({self.path}):run()
    else
      log.error("P4_File (add): Can't edit a file that is not in the depot")
    end
  end

  log.trace("P4_File (edit): Exit")

  return success
end

--- Reverts the file.
---
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File:revert()
  log.trace("P4_File (revert): Enter")

  self:_check_instance()

  local P4_Command_Revert = require("p4.core.lib.command.revert")

  local success = P4_Command_Revert:new({self.path}):run()

  log.trace("P4_File (revert): Exit")

  return success
end

--- Open the file for delete.
---
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File:delete()
  log.trace("P4_File (delete): Enter")

  self:_check_instance()

  local P4_Command_Delete = require("p4.core.lib.command.delete")

  local success = P4_Command_Delete:new({self.path}):run()

  log.trace("P4_File (delete): Exit")

  return success
end

--- Updates the file's stats.
---
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File:update_stats()
  log.trace("P4_File (update_stats): Enter")

  self:_check_instance()

  local P4_Command_FStat = require("p4.core.lib.command.fstat")

  local success, result_list = P4_Command_FStat:new({self.path}):run()

  if success then

    --- @cast result_list P4_Command_FStat_Result[]
    self.fstat = {
      clientFile = result_list[1].clientFile,
      depotFile = result_list[1].depotFile,
      isMapped = result_list[1].isMapped,
      shelved = result_list[1].shelved,
      change = result_list[1].change,
      headRev = result_list[1].headRev,
      haveRev = result_list[1].haveRev,
      workRev = result_list[1].workRev,
      action = result_list[1].action,
    }

  end

  log.trace("P4_File (update_stats): Exit")

  return success
end

return P4_File
