---@module "nio"

local cmd_lib = require("p4.core.lib.command")

local error_api = require("p4.api.error")

--- @class P4_Command_Opened_Options
--- @field cl? string Only files in the specified changelist.

--- @class P4_Command_Opened_Result_Success : P4_Command_Common_Result_Success
--- @field action string Action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).
--- @field change string Change list number.
--- @field client string Client.
--- @field clientFile Local_File_Path Local file path.
--- @field depotFile Depot_File_Path Depot file path.
--- @field haveRev string Have revision number.
--- @field rev string Revision number.
--- @field user string User.

--- @class P4_Command_Opened_Result_Error
--- @field reason string? Error reason.
---
--- 1. If no files are opened.

--- @class P4_Command_Opened_Result : P4_Command_Common_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Opened_Result_Success | P4_Command_Opened_Result_Error Hold's information about the result.

--- @class P4_Command_Opened : P4_Command
--- @field opts P4_Command_Opened_Options Command options.
local P4_Command_Opened = {}

P4_Command_Opened.__index = P4_Command_Opened

setmetatable(P4_Command_Opened, {__index = cmd_lib})

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Opened:_check_instance()
  assert(cmd_lib.is_instance(self) == true, "Not a class instance")
end

--- Helper function to process a command result success.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Opened_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Opened:_cmd_result_success_handler(cmd_result, results)
  local cmd_result_success = cmd_result.data

  ---@cast cmd_result_success P4_Command_Opened_Result_Success

  ---@type P4_Command_Opened_Result
  local new_result = {
    success = true,
    data = cmd_result_success,
  }

  table.insert(results, new_result)
end

--- Helper function to process a command result error.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Opened_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Opened:_cmd_result_error_handler(cmd_result, results)
  results = results or {} -- Remove if used.

  -- If an error ocurred, then it will be the first entry and the rest of the entries can be considered to have
  -- failed.

  --- @type P4_API_Command_Error
  local new_cmd_error = {
    name = cmd:get_command_name(),
    command = cmd:get_command(),
    results = cmd_result,
  }

  error(error_api:new(P4_RESULT_CODE_COMMAND_FAILED, new_cmd_error))
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Parsed command result.
--- @return P4_Command_Opened_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_Opened:_process_response(sc)
  ---@type P4_Command_Opened_Result[]
  local results = {}

  -- This command returns nothing if there are no open files in the client workspace. Nothing is also returned if there
  -- are no open files that match the client spec.
  if sc.stdout:len() > 0 then

    -- P4 errors have already been processed. Success results are command dependent and may need further processing ince
    -- there may be some entries that need to be filtered out as information messages or treated as errors.

    local cmd_results = cmd_lib._process_response(self, sc)

    for _, cmd_result in ipairs(cmd_results) do
      if cmd_result.success then
        self:_cmd_result_success_handler(cmd_result, results)
      else
        self:_cmd_result_error_handler(cmd_result, results)
      end
    end
  else
    --- @type P4_Command_Opened_Result
    local new_result = {
      success = false,
      data = {
        reason = "No open files.",
      }
    }

    table.insert(results, new_result)
  end

  return results
end

--- Creates the P4 command.
---
--- @param file_specs File_Spec[]? File specs.
--- @param opts P4_Command_Opened_Options? P4 command options
--- @return P4_Command_Opened P4_Command_Opened P4 command.
---
--- @nodiscard
function P4_Command_Opened:new(file_specs, opts)
  opts = opts or {}

  local command = {
    "opened",
  }

  if opts.cl then

    local ext_cmd = {
      "-c",
      opts.cl,
    }

    vim.list_extend(command, ext_cmd)
  end

  if file_specs then
    vim.list_extend(command, file_specs)
  end

  ---@type P4_Command_New
  local info = {
    command = command,
    name = command[1],
  }

  local new = cmd_lib:new(info)

  --- @cast new P4_Command_Opened

  setmetatable(new, P4_Command_Opened)

  return new
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
---
--- @nodiscard
function P4_Command_Opened:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object and object.__index == P4_Command_Opened then
      return true
    end
  end

  return false
end

--- Runs the P4 command.
---
--- @return P4_Command_Opened_Result[] results Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Opened:run()
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

return P4_Command_Opened
