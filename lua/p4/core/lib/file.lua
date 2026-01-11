local log = require("p4.log")

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
--- @field protected info? P4_File_Info P4 file stats.
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
--- @field get_info boolean Get file stats from P4 server.
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
  new.in_depot = nil
  new.info = nil
  new.client = new_file.client or nil
  new.cl = new_file.cl or nil

  if success then
    if new_file.check_in_depot then
      success = new:get_in_depot()
    end
  end

  if success then
    if new_file.get_info then
      success = new:get_info()
    end
  end

  log.fmt_trace("P4_File (new): Exit, %s", tostring(success))

  return success, new
end

--- Gets the P4 file's path.
---
--- @return File_Path P4 file path.
---
--- @nodiscard
function P4_File:get_file_path()
  log.trace("P4_File (get_file_path): Enter")

  self:_check_instance()

  log.trace("P4_File (get_file_path): Exit")

  return self.path
end

--- Checks if a file is open for edit
---
--- @return boolean success Indicates the result of the function.
--- @return boolean is_open_for_edit True if the file is open for edit.
---
--- @nodiscard
function P4_File:is_open_for_edit()
  log.trace("P4_File (is_open_for_edit): Enter")

  self:_check_instance()

  local is_open_for_edit = false

  local success, _ = self:get_info()

  if success then

    if self.info.isMapped and
      self.info.action and
      self.info.action == "edit" then

      is_open_for_edit = true
    end
  end

  log.trace("P4_File (is_open_for_edit): Exit")

  return success, is_open_for_edit
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

    success, results = P4_Command_Files:new({self.path}):run()

    if success and results then

      assert(#results == 1, "Unexpected number of results")

      ---@type P4_Command_Files_Result
      local result = results[1]

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

--- Get's the file's information.
---
--- @param opts? P4_File_Get_FStat_Opts Options.
--- @return boolean success True if this function is successful.
--- @return P4_File_Info? P4_File_Info P4 file information.
---
--- @async
--- @nodiscard
function P4_File:get_info(opts)
  log.trace("P4_File (get_info): Enter")

  self:_check_instance()

  opts = vim.tbl_deep_extend("force", P4_File_Get_FStat_Opts, opts or {})

  local success = true

  if not self.info or opts.force  then
    success = self:update_info()
  end

  log.trace("P4_File (get_info): Exit")

  return success, self.info
end

--- Set's the file's information.
---
--- @param info P4_File_Info P4 file info.
function P4_File:set_info(info)
  log.trace("P4_File (set_info): Enter")

  self:_check_instance()

  log.trace("P4_File (set_info): Exit")

  self.info = info
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

--- Updates the file's information.
---
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File:update_info()
  log.trace("P4_File (update_info): Enter")

  self:_check_instance()

  local P4_Command_FStat = require("p4.core.lib.command.fstat")

  local success, result = P4_Command_FStat:new({self.path}):run()

  if success and result then

    --- @cast result P4_Command_FStat_Result
    self.info = result.file_info_list[1]

  end

  log.trace("P4_File (update_info): Exit")

  return success
end

--- Returns the file as output for the specified file revision.
---
--- @return boolean success Result of the function.
--- @return string file_ouput Hold's the file output for the specified revision.
---
--- @async
--- @nodiscard
function P4_File:get_file_revision()
  log.trace("P4_File (get_diff): Enter")

  self:_check_instance()

  local file_output

  local success = self:update_info()

  if success then
    local P4_Command_Print = require("p4.core.lib.command.print")

    local results
    success, results = P4_Command_Print:new({self.path .. "#head"}):run()

    if success and results then

      assert(#results == 1, "Unexpected number of results")

      ---@type P4_Command_Print_Result
      local result = results[1]

      if result.success then
        file_output = result.data.output
      else
        -- All errors are fatal.
        success = false
      end
    end
  end

  log.trace("P4_File (get_diff): Exit")

  return success, file_output
end

return P4_File
