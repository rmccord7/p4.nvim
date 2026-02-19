---@module "nio"

local error_api = require("p4.api.error")

local cmd_lib = require("p4.core.lib.command")

--- @class P4_Client_Spec

--- @class P4_Command_Client_Read_Options
--- @field raw_output boolean Returns the raw output read from the table.
--- @field template string Copies options and view from the specified template client.

--- @class P4_Command_Client_Write_Options
--- @field input string[]? Write input.

--- @class P4_Command_Client_Options
--- @field client string? Optional Client name.
--- @field type P4_COMMAND_CLIENT_OPTS_TYPE Indicates the available options that may be used for the command.
--- @field read? P4_Command_Client_Read_Options Read options.
--- @field write? P4_Command_Client_Write_Options Write options.

--- @class P4_Command_Client_Result_Success_Raw
--- @field output string Read change spec output.

--- @class P4_Command_Client_Result_Success : P4_Command_Common_Result_Success
--- @field Access string Date/time this client was last used
--- @field Backup string Date/time this client was last used
--- @field Client string Name of the client
--- @field Description string Client description
--- @field Host string Host that owns the client
--- @field LineEnd string Text file line endings on the client
--- @field Options string Client options
--- @field Owner string Client options
--- @field Root string Base directory for client workspace
--- @field AltRoot table Up to two alternate client roots
--- @field SubmitOptions string Submit options for the workspace
--- @field Update string Date/time this client was modified
--- @field View string[] Lines to map depot files to the current workpace

--- @class P4_Command_Client_Result_Error
--- @field reason string? Error reason.
---
--- 1. Invalid client (generic: 1, severity: 3)
---
--- 2. Unknown client (generic: 2, severity: 3)

--- @class P4_Command_Client_Result : P4_Command_Common_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Client_Result_Success | P4_Command_Client_Result_Success_Raw | P4_Command_Client_Result_Error Hold's information about the result.

--- @class P4_Command_Client : P4_Command
--- @field client string P4 client name.
--- @field opts P4_Command_Client_Options Command options.
local P4_Command_Client = {}

P4_Command_Client.__index = P4_Command_Client

setmetatable(P4_Command_Client, {__index = cmd_lib})

--- @enum P4_COMMAND_CLIENT_OPTS_TYPE
P4_Command_Client.opts_type = {
    READ = 0,
    WRITE = 1,
}

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Client:_check_instance()
  assert(self:is_instance() == true, "Not a class instance")
end

--- Helper function to process a command result success.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Client_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Client:_cmd_result_success_handler(cmd_result, results)
  local cmd_result_success = cmd_result.data

  ---@cast cmd_result_success P4_Command_Client_Result_Success

  ---@type P4_Command_Client_Result
  local new_result = {
    success = true,
    data = cmd_result_success
  }

  table.insert(results, new_result)
end

--- Helper function to process a command result error.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Client_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Client:_cmd_result_error_handler(cmd_result, results)
  -- Invalid CL number (generic: 1, severity: 3)
  local function error_is_invalid_client(severity, generic)
    if severity == P4_SEVERITY_FAILED and generic == P4_GENERIC_USAGE then
      return true
    end
    return false
  end

  -- Invalid CL number (generic: 1, severity: 3)
  local function error_is_unknown_client(severity, generic)
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
  if error_is_invalid_client(severity, generic) or
     error_is_unknown_client(severity, generic) then

    --- @type P4_Command_Client_Result
    local result = {
      success = false,
      data = {
        reason = cmd_result_error.data,
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
--- @return P4_Command_Client_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_Client:_process_response(sc)
  --- @type P4_Command_Client_Result[]
  local results = {}

  if self.opts.type == P4_Command_Client.opts_type.READ and
    self.opts.read.raw_output then

    ---@type P4_Command_Client_Result
    local result = {
      success = true,
      data = {
        output = sc.stdout
      }
    }

    table.insert(results, result)
  elseif self.opts.type == P4_Command_Client.opts_type.WRITE then
    --TODO: Need to see what this does for JSON output and do we really care?
  else
    local cmd_results = cmd_lib._process_response(self, sc)

    for _, cmd_result in ipairs(cmd_results) do
      if cmd_result.success then
        self:_cmd_result_success_handler(cmd_result, results)
      else
        self:_cmd_result_error_handler(cmd_result, results)
      end
    end
  end

  return results
end

--- Creates the P4 command.
---
--- @param opts? P4_Command_Client_Options P4 command options.
--- @return P4_Command_Client P4_Command_Client P4 command.
---
--- @nodiscard
function P4_Command_Client:new(opts)
  opts = opts or {}

  local command = {
    "client",
  }

  if opts.type == P4_Command_Client.opts_type.READ then

    local ext_cmd = {
      "-o", -- Read client spec to STDOUT
    }

    vim.list_extend(command, ext_cmd)

    if opts.read and opts.read.template then

      ext_cmd = {
        "-t", -- Get options and view from the specified template for the new client.
        opts.read.template
      }

      vim.list_extend(command, ext_cmd)
    end
  end

  if opts.type == P4_Command_Client.opts_type.WRITE then

    local ext_cmd = {
      "-i", -- Write client spec to STDIN
    }

    vim.list_extend(command, ext_cmd)
  end

  if opts.client then
    table.insert(command, opts.client)
  end

  ---@type P4_Command_New
  local info = {
    command = command,
    name = command[1],
  }

  if opts.type == P4_Command_Client.opts_type.READ and
    opts.read.raw_output then
    info.global_opts = {
      json = false,
    }
  end

  if opts.type == P4_Command_Client.opts_type.WRITE then
    info.global_opts = {
      json = false,
    }
  end

  local new = cmd_lib:new(info)

  --- @cast new P4_Command_Client

  setmetatable(new, P4_Command_Client)

  new.opts = opts

  if opts.type == P4_Command_Client.opts_type.WRITE then
    assert(opts.write and opts.write.input, "Input required for STDIN")

    -- Input needs to be supplied to STDIN.
    new.sys_opts["stdin"] = opts.write.input
  end

  return new
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
---
--- @nodiscard
function P4_Command_Client:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object and object.__index == P4_Command_Client then
      return true
    end
  end

  return false
end

--- Runs the P4 command.
---
--- @return P4_Command_Change_Result[] results Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Client:run()
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

return P4_Command_Client
