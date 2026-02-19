---@module "nio"

local cmd_lib = require("p4.core.lib.command")

local error_api = require("p4.api.error")

--- @class P4_Command_Reopen_Options
--- @field cl string Reopen files in the specified changelist.

--- @class P4_Command_Reopen_Result_Success : P4_Command_Common_Result_Success
--TODO: Needs testing

--- @class P4_Command_Reopen_Result_Error
--- @field depotFile Depot_File_Path Depot file path.
--- @field reason string? Error reason.
---
--- 1. If a file is not mapped to the client workspace (severity: 2, generic: 17).
---
--- 2. If a file does not exist in the depot (severity: 2, generic: 17).

--- @class P4_Command_Reopen_Result : P4_Command_Common_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Reopen_Result_Success | P4_Command_Reopen_Result_Error Hold's information about the result.

--- @class P4_Command_Reopen : P4_Command
--- @field opts P4_Command_Reopen_Options Command options.
local P4_Command_Reopen = {}

P4_Command_Reopen.__index = P4_Command_Reopen

setmetatable(P4_Command_Reopen, {__index = cmd_lib})

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Reopen:_check_instance()
  assert(self:is_instance() == true, "Not a class instance")
end

--- Helper function to process a command result success.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Reopen_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Reopen:_cmd_result_success_handler(cmd_result, results)
  local cmd_result_success = cmd_result.data

  ---@cast cmd_result_success P4_Command_Reopen_Result_Success

    ---@type P4_Command_Reopen_Result
    local new_result = {
      success = true,
      data = cmd_result_success,
    }

    table.insert(results, new_result)
end

--- Helper function to process a command result error.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Reopen_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Reopen:_cmd_result_error_handler(cmd_result, results)
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
  local generic = cmd_result_error:get_generic()

  -- Check if we can pass the error up to the caller.
  if error_is_not_in_client_view(severity, generic) or
     error_is_not_in_depot(severity, generic) then

    --- @type P4_Command_Reopen_Result
    result = {
      success = false,
      data = {
        depotFile = vim.split(cmd_result_error.data, " - ", {plain = true})[1],
      }
    }

    table.insert(results, result)
  else

    -- We didn't handle this case or something really bad happened.

    --- @type P4_API_Command_Error
    local new_cmd_error = {
      name = self:get_command_name(),
      command = self:get_command(),
      results = cmd_result,
    }

    error(error_api:new(P4_RESULT_CODE_COMMAND_FAILED, new_cmd_error))
  end
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Parsed command result.
--- @return P4_Command_Reopen_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_Reopen:_process_response(sc)
  local cmd_results = cmd_lib._process_response(self, sc)

  -- P4 errors have already been processed. Success results are command dependent and may need further processing ince
  -- there may be some entries that need to be filtered out as information messages or treated as errors.

  --- @type P4_Command_Reopen_Result[]
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
--- @param file_spec_list File_Spec[] File spec.
--- @param opts? P4_Command_Reopen_Options P4 command options.
--- @return P4_Command_Reopen P4_Command_Reopen P4 command.
function P4_Command_Reopen:new(file_spec_list, opts)
  opts = opts or {}

  local command = {
    "reopen",
  }

  assert(opts.cl, "CL option must be specified for P4 reopen command.")

  if opts.cl then

    local ext_cmd = {
      "-c",
      opts.cl,
    }

    vim.list_extend(command, ext_cmd)
  end

  table.insert(command, file_spec_list)

  local new = cmd_lib:new(command)

  --- @cast new P4_Command_Reopen

  setmetatable(new, P4_Command_Reopen)

  return new
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
---
--- @nodiscard
function P4_Command_Reopen:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object and object.__index == P4_Command_Reopen then
      return true
    end
  end

  return false
end

--- Runs the P4 command.
---
--- @return P4_Command_Reopen_Result Result Indicates if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Reopen:run()
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

return P4_Command_Reopen
