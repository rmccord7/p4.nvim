---@module "nio"

local cmd_lib = require("p4.core.lib.command")

local error_api = require("p4.api.error")

--- @class P4_Command_Print_Result_Success : P4_Command_Common_Result_Success
--- @field action string Action
--- @field change string Identifies the CL
--- @field depotFile Depot_File_Path Name of the file in the depot for this file
--- @field fileSize string Size of the file
--- @field rev string Revision number
--- @field time string Time/date revision was integrated
--- @field output string File output

--- @class P4_Command_Print_Result_Error
--- @field depotFile Depot_File_Path Depot file path.
--- @field reason string? Reason could not be opened for add.
---
--- 1. If a file is not mapped to the client workspace (generic: 17, severity: 2).
---
--- 2. If a file does not exist in the depot (generic: 17, severity: 2).

--- @class P4_Command_Print_Result : P4_Command_Common_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Print_Result_Success | P4_Command_Print_Result_Error Hold's information about the result.

--- @class P4_Command_Print : P4_Command
local P4_Command_Print = {}

P4_Command_Print.__index = P4_Command_Print

setmetatable(P4_Command_Print, {__index = cmd_lib})

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Print:_check_instance()
  assert(cmd_lib.is_instance(self) == true, "Not a class instance")
end

--- Helper function to process a command result success.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Print_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Print:_cmd_result_success_handler(cmd_result, results)
  local cmd_result_success = cmd_result.data

  ---@cast cmd_result_success P4_Command_Print_Result_Success

  -- Start of a file spec result
  if cmd_result_success.action then

    -- Start a new entry with information about the current file spec.
    ---@type P4_Command_Print_Result
    local new_result = {
      success = true,
      data = cmd_result_success
    }

    table.insert(results, new_result)
  elseif cmd_result_success.data then
    -- Sometimes multiple success tables are present with data that needs to be concatenated.
    if cmd_result.data.data ~= "" then
      local current = results[#results].data

      if current.output then
        current.output = current.output .. cmd_result.data.data
      else
        current.output = cmd_result.data.data
      end
    end
  end
end

--- Helper function to process a command result error.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Print_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Print:_cmd_result_error_handler(cmd_result, results)
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

    --- @type P4_Command_Print_Result
    result = {
      success = false,
      data = {
        depotFile = vim.split(cmd_result_error.data, " - ", {plain = true})[1],
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
--- @return P4_Command_Print_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_Print:_process_response(sc)
  local cmd_results = cmd_lib._process_response(self, sc)

  -- P4 errors have already been processed. Success results are command dependent and may need further processing ince
  -- there may be some entries that need to be filtered out as information messages or treated as errors.

  --- @type P4_Command_Print_Result[]
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
--- @param file_specs File_Spec[] File specs.
--- @return P4_Command_Print P4_Command_Print P4 command.
---
--- @nodiscard
function P4_Command_Print:new(file_specs)
  opts = opts or {}

  local command = {
    "print",
    "-q", --Suppress the one line file header added to the file output by perforce.
  }

  vim.list_extend(command, file_specs)

  ---@type P4_Command_New
  local info = {
    command = command,
    name = command[1],
  }

  local new = cmd_lib:new(info)

  --- @cast new P4_Command_Print

  setmetatable(new, P4_Command_Print)

  return new
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
---
--- @nodiscard
function P4_Command_Print:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object.__index == P4_Command_Print then
      return true
    end
  end

  return false
end

--- Runs the P4 command.
---
--- @return P4_Command_Print_Result[] results Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Print:run()
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


return P4_Command_Print
