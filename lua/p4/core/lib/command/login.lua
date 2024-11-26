--- @class P4_Command_Login_Options : table
--- @field check? boolean Just checks if a user is logged in.

--- @class P4_Command_Login_Result : table
--- @field result boolean Path of the file in the depot.

--- @class P4_Command_Login : P4_Command
--- @field opts P4_Command_Login_Options Command options.
--- @field result P4_Command_Login_Result[] Parsed result list.
local P4_Command_Login = {}

--- Creates the P4 command.
---
--- @param opts? P4_Command_Login_Options P4 command options
--- @return P4_Command_Login P4_Command_Opened A new current P4 client
function P4_Command_Login:new(opts)
  opts = opts or {}

  P4_Command_Login.__index = P4_Command_Login

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Login, {__index = P4_Command})

  local command = {
    "p4",
    "login",
  }

  if opts.check then

    local ext_cmd = {
      "-s",
    }

    vim.list_extend(command, ext_cmd)
  end

  --- @type P4_Command_Login
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Login)

  return new
end

return P4_Command_Login
