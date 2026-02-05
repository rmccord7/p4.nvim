---@module "nio"

local error_api = require("p4.api.error")

local cmd_lib = require("p4.core.lib.command")

--- @class P4_Command_Clients_Result_Success : P4_Command_Common_Result_Success
--- @field Access string Action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).
--- @field Backup Local_File_Path Local file path.
--- @field Description Depot_File_Path Depot file path.
--- @field Host string Revision number.
--- @field LineEnd string Revision number.
--- @field Options string Revision number.
--- @field Owner string Revision number.
--- @field Root string Revision number.
--- @field AltRoots string[]? Revision number.
--- @field SubmitOptions string Revision number.
--- @field Type string Revision number.
--- @field Udpate string Revision number.
--- @field client string Revision number.

--- @class P4_Command_Clients_Result_Error
--- @field reason string? Error reason.

--- @class P4_Command_Clients_Result : P4_Command_Common_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Clients_Result_Success | P4_Command_Clients_Result_Error Hold's information about the result.

--- @class P4_Command_Clients : P4_Command
local P4_Command_Clients = {}

P4_Command_Clients.__index = P4_Command_Clients

setmetatable(P4_Command_Clients, {__index = cmd_lib})

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Clients:_check_instance()
  assert(self:is_instance() == true, "Not a class instance")
end

--- Helper function to process a command result success.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Clients_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Clients:_cmd_result_success_handler(cmd_result, results)
  local cmd_result_success = cmd_result.data

  ---@cast cmd_result_success P4_Command_Clients_Result_Success

  ---@type P4_Command_Clients_Result
  local new_result = {
    success = true,
    data = cmd_result_success
  }

  table.insert(results, new_result)
end

--- Helper function to process a command result error.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Clients_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Clients:_cmd_result_error_handler(cmd_result, results)
  results = results or {} -- Remove if used

  -- We didn't handle this case or something really bad happened.

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
--- @return P4_Command_Clients_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_Clients:_process_response(sc)
  --- @type P4_Command_Clients_Result[]
  local results = {}

  local cmd_results = cmd_lib._process_response(self, sc)

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
--- @return P4_Command_Clients P4_Command_Clients P4 command.
---
--- @nodiscard
function P4_Command_Clients:new()
  local command = {
    "clients",
    "--me", -- Current user
    "-a", -- Get all clients (not just the ones on the connected p4 server)
  }

  ---@type P4_Command_New
  local info = {
    command = command,
    name = command[1],
  }

  local new = cmd_lib:new(info)

  --- @cast new P4_Command_Clients

  setmetatable(new, P4_Command_Clients)

  return new
end

--- Runs the P4 command.
---
--- @return P4_Command_Clients_Result[] results Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Clients:run()
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

return P4_Command_Clients
