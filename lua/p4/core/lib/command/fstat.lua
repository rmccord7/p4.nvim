---@module "nio"

local cmd_lib = require("p4.core.lib.command")

local error_api = require("p4.api.error")

--- @class P4_Command_FStat_Result_Success : P4_Command_Common_Result_Success
--- @field clientFile Client_File_Path Local path to the file.
--- @field depotFile Depot_File_Path Depot path to the file.
--- @field isMapped boolean Indicates if file is mapped to the current client workspace.
--- @field shelved boolean Indicates if file is shelved.
--- @field change string Open change list number if file is opened in client workspace.
--- @field haveRev integer Revision last synced to workpace.
--- @field headAction string Head revision number if in depot.
--- @field headChange string Head revision number if in depot.
--- @field headModTime string Head revision number if in depot.
--- @field headRev integer Head revision number if in depot.
--- @field headTime integer Head revision number if in depot.

--- @class P4_Command_FStat_Result_Error
--- @field reason string? Error reason.

--- @class P4_Command_FStat_Result : P4_Command_Common_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_FStat_Result_Success | P4_Command_FStat_Result_Error Hold's information about the result.

--- @class P4_Command_FStat : P4_Command
local P4_Command_FStat = {}

P4_Command_FStat.__index = P4_Command_FStat

setmetatable(P4_Command_FStat, {__index = cmd_lib})

--- Wrapper function to check if a table is an instance of this class.
function P4_Command_FStat:_check_instance()
  assert(P4_Command_FStat.is_instance(self) == true, "Not a class instance")
end

--- Helper function to process a command result success.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_FStat_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_FStat:_cmd_result_success_handler(cmd_result, results)
  local cmd_result_success = cmd_result.data

  ---@cast cmd_result_success P4_Command_FStat_Result_Success

  ---@type P4_Command_FStat_Result
  local new_result = {
    success = true,
    data = cmd_result_success,
  }

  table.insert(results, new_result)
end

--- Helper function to process a command result error.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_FStat_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_FStat:_cmd_result_error_handler(cmd_result, results)
  -- A file that is not in the client view (generic: 17, severity: 2).
  local function error_is_not_in_client_view(severity, generic)
    if severity == P4_SEVERITY_WARN and generic == P4_GENERIC_EMTPY then
      return true
    end
    return false
  end

  -- A file that is not in the depot (generic: 17, severity: 2).
  local function error_is_not_in_depot(severity, generic)
    if severity == P4_SEVERITY_FAILED and generic == P4_GENERIC_UNKNOWN then
      return true
    end
    return false
  end

  ---@type P4_Command_Result_Error
  local cmd_result_error = cmd_result.data.error

  local severity = cmd_result_error:get_severity()
  local generic = cmd_result_error:get_severity()

  -- Check if we can pass the error up to the caller.
  if error_is_not_in_client_view(severity, generic) or
     error_is_not_in_depot(severity, generic) then

    --- @type P4_Command_FStat_Result
    result = {
      success = false,
      data = {
        reason = vim.split(cmd_result_error.data, " - ", {plain = true})[2],
      }
    }

    table.insert(results, result)
  else

    -- We didn't handle this case or something really bad happened.

    --- @type P4_API_Command_Error
    local new_cmd_error = {
      name = cmd:get_command_name(),
      command = cmd:get_command(),
      results = cmd_result,
    }

    error(error_api:new(P4_RESULT_CODE_COMMAND_FAILED, new_cmd_error))
  end
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Parsed command result.
--- @return P4_Command_FStat_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_FStat:_process_response(sc)
  local cmd_results = cmd_lib._process_response(self, sc)

  -- P4 errors have already been processed. Success results are command dependent and may need further processing ince
  -- there may be some entries that need to be filtered out as information messages or treated as errors.

  --- @type P4_Command_FStat_Result[]
  local results = {}

  for _, cmd_result in ipairs(cmd_results) do

    if cmd_result.success then
      self:_cmd_result_success_handler(cmd_result, results)
    else
      self:_cmd_result_error_handler(cmd_result, results)
    end
  end

  return results
end

--- Creates the P4 command.
---
--- @param file_specs File_Spec[] One or more file paths.
--- @return P4_Command_FStat P4_Command_FStat P4 command.
function P4_Command_FStat:new(file_specs)
  opts = opts or {}

  local command = {
    "fstat",
  }

  vim.list_extend(command, file_specs)

  ---@type P4_Command_New
  local info = {
    command = command,
    name = command[1],
  }

  local new = cmd_lib:new(info)

  --- @cast new P4_Command_FStat

  setmetatable(new, P4_Command_FStat)

  return new
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
---
--- @nodiscard
function P4_Command_FStat:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object.__index == P4_Command_FStat then
      return true
    end
  end

  return false
end

--- Runs the P4 command.
---
--- @return P4_Command_FStat_Result[] results Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_FStat:run()
  self:_check_instance()

  local results = {}
  local success, sc = pcall(cmd_lib.run(self).wait)

  if success then
    if sc then
      results = self:_process_response(sc)
    else
      success = false
    end
  else
    local cmd_error = {
      name = self.name,
      command = self.command,
      results = results,
    }

    error(error_api:new(P4_RESULT_CODE_COMMAND_FAILED, cmd_error))
  end

  return results
end

return P4_Command_FStat
