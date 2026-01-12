local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Login_Options : table
--- @field check? boolean Checks if a user is logged in.
--- @field password? string Password for login. Required if check is nil or false.

--- @class P4_Command_Login_Result_Check_Success
--- @field TicketExperation string Ticket expiration time.
--- @field User string P4 user.
--- @field AuthedBy string Type of ticket.

--- @class P4_Command_Login_Result_Pass_Success
--- @field TicketExperation string Ticket expiration time.
--- @field User string P4 user.

--- Depends on input options.
--- @alias P4_Command_Login_Result_Success P4_Command_Login_Result_Check_Success | P4_Command_Login_Result_Pass_Success

--- @class P4_Command_Login_Result_Error
--- @field error P4_Command_Result_Error Hold's error information.

--- @class P4_Command_Login_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Login_Result_Success | P4_Command_Login_Result_Error Hold's information about the result.

--- @class P4_Command_Login : P4_Command
--- @field opts P4_Command_Login_Options Command options.
local P4_Command_Login = {}

P4_Command_Login.__index = P4_Command_Login

setmetatable(P4_Command_Login, {__index = P4_Command})

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Login:_check_instance()
  assert(P4_Command_Login.is_instance(self) == true, "Not a P4 CL class instance")
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Parsed command result.
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Login_Result[] results Hold's the formatted command result.
---
--- @package
function P4_Command_Login:_process_response(sc)
  log.trace("P4_Command_Login: process_response")

  -- Call base to process the response since we should have one JSON table per file spec.
  local success, results = P4_Command._process_response(self, sc)

  --- @cast results P4_Command_Login_Result[]

  return success, results
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_Command_Login:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_Command_Login then
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

  log.trace("P4_Command_Login: new")

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

  --- @type P4_Command_Login
  local new = P4_Command:new(info)

  setmetatable(new, P4_Command_Login)

  if not opts.check then
    assert(opts.password, "Password is required for P4 login command")

    new.sys_opts["stdin"] = opts.password
  end

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Login_Result? result Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Login:run()
  self:_check_instance()

  local result = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    success, results = P4_Command_Login:_process_response(sc)
  end

  return success, result
end

return P4_Command_Login
