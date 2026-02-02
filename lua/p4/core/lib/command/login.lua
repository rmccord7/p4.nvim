---@module "nio"

local cmd_lib = require("p4.core.lib.command")

local error_api = require("p4.api.error")

--- @class P4_Command_Login_Options
--- @field check? boolean Checks if a user is logged in.
--- @field password? string Password for login. Required if check is nil or false.

--- @class P4_Command_Login_Result_Check_Success : P4_Command_Common_Result_Success
--- @field TicketExperation string Ticket expiration time.
--- @field User string P4 user.
--- @field AuthedBy string Type of ticket.

--- @class P4_Command_Login_Result_Pass_Success : P4_Command_Common_Result_Success
--- @field TicketExperation string Ticket expiration time.
--- @field User string P4 user.

--- Depends on input options.
--- @alias P4_Command_Login_Result_Success P4_Command_Login_Result_Check_Success | P4_Command_Login_Result_Pass_Success

--- @class P4_Command_Login_Result_Error
--- @field error P4_Command_Result_Error Hold's error information.

--- @class P4_Command_Login_Result : P4_Command_Common_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Login_Result_Success | P4_Command_Login_Result_Error Hold's information about the result.

--- @class P4_Command_Login : P4_Command
--- @field opts P4_Command_Login_Options Command options.
local P4_Command_Login = {}

P4_Command_Login.__index = P4_Command_Login

setmetatable(P4_Command_Login, {__index = cmd_lib})

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Login:_check_instance()
  assert(P4_Command_Login.is_instance(self) == true, "Not a class instance")
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Parsed command result.
--- @return P4_Command_Login_Result[] results Hold's the formatted command result.
---
--- @package
function P4_Command_Login:_process_response(sc)
  return cmd_lib._process_response(self, sc)
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_Command_Login:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object.__index == P4_Command_Login then
      return true
    end
  end

  return false
end

--- Creates the P4 command.
---
--- @param opts? P4_Command_Login_Options P4 command options
--- @return P4_Command_Login P4_Command_Opened A new current P4 client
function P4_Command_Login:new(opts)
  opts = opts or {}

  local command = {
    "login",
  }

  if opts.check then

    local ext_cmd = {
      "-s",
    }

    vim.list_extend(command, ext_cmd)
  end

  ---@type P4_Command_New
  local info = {
    command = command,
    name = command[1],
  }

  local new = cmd_lib:new(info)

  --- @cast new P4_Command_Login

  setmetatable(new, P4_Command_Login)

  if not opts.check then
    assert(opts.password, "Password is required for P4 login command")

    new.sys_opts["stdin"] = opts.password
  end

  return new
end

--- Runs the P4 command.
---
--- @return P4_Command_Login_Result result Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Login:run()
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

return P4_Command_Login
