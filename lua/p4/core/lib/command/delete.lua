---@module "nio"

local cmd_lib = require("p4.core.lib.command")

local error_api = require("p4.api.error")

--- @class P4_Command_Delete_Options
--- @field change string? Opens for delete in the specified CL.

--- @class P4_Command_Delete_Result_Success : P4_Command_Common_Result_Success
--- @field messages string[]? List of informational messages.
--- @field depotFile Depot_File_Path Depot file path.
--- @field action string? Action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).
--- @field clientFile Local_File_Path? Local file path.
--- @field workRev string? Revision number.
---
--- 1. If the file is opened for delete.

--- @class P4_Command_Delete_Result_Error
--- @field depotFile Depot_File_Path Depot file path.
--- @field reason string? Error reason.
---
--- 1. If a file is not mapped to the client workspace (severity: 2, generic: 17).
---
--- 2. If a file does not exist in the depot (severity: 2, generic: 17).
---
--- 3. If file is already open for delete (Information message level:0).

--- @class P4_Command_Delete_Result : P4_Command_Common_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Delete_Result_Success | P4_Command_Delete_Result_Error Hold's information about the result.

--- @class P4_Command_Delete : P4_Command
--- @field opts P4_Command_Delete_Options Command options.
local P4_Command_Delete = {}

P4_Command_Delete.__index = P4_Command_Delete

setmetatable(P4_Command_Delete, {__index = cmd_lib})

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Delete:_check_instance()
  assert(self:is_instance() == true, "Not a class instance")
end

--- Helper function to process a command result success.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Delete_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Delete:_cmd_result_success_handler(cmd_result, results)
  local cmd_result_success = cmd_result.data

  ---@cast cmd_result_success P4_Command_Delete_Result_Success

  -- Handle information messages.
  if cmd_result_success.level then

    -- Must have a data field with the reason.
    if cmd_result_success.data then

      -- This message indicates a file could not be opened for edit for some reason,
      if cmd_result_success.level == 0 then

          local chunks = {}
          for substring in cmd_result_success.data:gmatch("%S+") do
            table.insert(chunks, substring)
            -- Small optimization we only care about the first match.
            break
          end

          -- We only get the depot file path for this message.
          --- @type string
          local depot_path = chunks[1]

          -- Remove revision if present
          if depot_path:find("#", 1, true) then
            cmd_result_success.depotFile = vim.split(depot_path, '#')[1]
          else
            cmd_result_success.depotFile = depot_path
          end

          --- @type P4_Command_Delete_Result
          result = {
            success = false,
            data = {
              depotFile = depot_path,
              reason = vim.split(cmd_result_success.data, " - ", {plain = true})[2],
            }
          }

          table.insert(results, result)

      -- Information messages (ex. opened for edit by another user).
      else
        -- Informational messages shoud always have a success result before it and a level other than zero.
        if not vim.tbl_isempty(results) then
          local prev_success_result = results[#results].data

          ---@cast prev_success_result P4_Command_Delete_Result_Success

          table.insert(prev_success_result.messages, cmd_result_success.data)
        else
          error(error_api:new(P4_RESULT_CODE_COMMAND_RESULT_PARSING_FAILED))
        end
      end
    else
      error(error_api:new(P4_RESULT_CODE_COMMAND_RESULT_PARSING_FAILED))
    end

  -- Table contains all data for success.
  else
    ---@type P4_Command_Delete_Result
    local new_result = {
      success = true,
      data = cmd_result_success,
    }

    new_result.data.messages = {}

    table.insert(results, new_result)
  end
end

--- Helper function to process a command result error.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Delete_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Delete:_cmd_result_error_handler(cmd_result, results)
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

    --- @type P4_Command_Delete_Result
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
--- @return P4_Command_Delete_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_Delete:_process_response(sc)
  local cmd_results = cmd_lib._process_response(self, sc)

  -- P4 errors have already been processed. Success results are command dependent and may need further processing ince
  -- there may be some entries that need to be filtered out as information messages or treated as errors.

  --- @type P4_Command_Delete_Result[]
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
--- @param opts? P4_Command_Delete_Options P4 command options.
--- @return P4_Command_Delete P4_Command_Delete P4 command.
function P4_Command_Delete:new(file_specs, opts)
  opts = opts or {}

  local command = {
    "delete",
  }

  -- Specify change list
  if opts.change then

    local ext_cmd = {
      "-c",
      opts.change,
    }

    vim.list_extend(command, ext_cmd)
  end

  vim.list_extend(command, file_specs)

  local new = cmd_lib:new(command)

  --- @cast new P4_Command_Delete

  setmetatable(new, P4_Command_Delete)

  return new
end

--- Runs the P4 command.
---
--- @return P4_Command_Delete_Result[] results Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Delete:run()
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

return P4_Command_Delete
