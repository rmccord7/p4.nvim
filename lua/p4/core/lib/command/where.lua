local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Where_Result_Success
--- @field depotFile Depot_File_Path? Depot path to the file
--- @field clientFile Client_File_Path? Client path to the file in local syntax
--- @field path Local_File_Path? Local path to the file

--- @class P4_Command_Where_Result_Error
--- @field error P4_Command_Result_Error Hold's the error information.

--- @class P4_Command_Where_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Where_Result_Success | P4_Command_Where_Result_Error Hold's information about the result.

--- @class P4_Command_Where : P4_Command
--- @field file_specs File_Spec[] File specs.
local P4_Command_Where = {}

P4_Command_Where.__index = P4_Command_Where

setmetatable(P4_Command_Where, {__index = P4_Command})

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Where:_check_instance()
  assert(P4_Command.is_instance(self) == true, "Not a class instance")
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Parsed command result.
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Files_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_Where:_process_response(sc)
  log.trace("P4_Command_Where: process_response")

  -- Call base to process the response since we should have one JSON table per file spec.
  local success, results = P4_Command._process_response(self, sc)

  --- @cast results P4_Command_Where_Result[]

  if success then
    assert(#results == #self.file_specs, "Unexpected number of results")
  end

  return success, results
end

--- Creates the P4 command.
---
--- @param file_specs File_Spec[] File specs.
--- @return P4_Command_Where P4_Command_Where P4 command.
---
--- @nodiscard
function P4_Command_Where:new(file_specs)
  log.trace("P4_Command_Where: new")

  -- Save so we can verify the number of results.
  self.file_specs = file_specs

  local command = {
    "where",
  }

  vim.list_extend(command, file_specs)

  ---@type P4_Command_New
  local info = {
    command = command,
    name = command[1],
  }

  --- @type P4_Command_Where
  local new = P4_Command:new(info)

  setmetatable(new, P4_Command_Where)

  return new
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
---
--- @nodiscard
function P4_Command_Where:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object.__index == P4_Command_Where then
      return true
    end
  end

  return false
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Where[]? results Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Where:run()
  self:_check_instance()

  local results = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    if sc then
      success, results = P4_Command_Where:_process_response(sc)
    else
      success = false
    end
  end

  return success, results
end

return P4_Command_Where
