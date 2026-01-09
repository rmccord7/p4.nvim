local log = require("p4.log")
local notify = require("p4.notify")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Login_Options : table
--- @field check? boolean Checks if a user is logged in.
--- @field password? string Password for login. Required if check is nil or false.

--- @class P4_Command_Login_Result : boolean

--- @class P4_Command_Login : P4_Command
--- @field opts P4_Command_Login_Options Command options.
--- @field result P4_Command_Login_Result[] Parsed result list.
local P4_Command_Login = {}

P4_Command_Login.__index = P4_Command_Login

setmetatable(P4_Command_Login, {__index = P4_Command})

--- Creates the P4 command.
---
--- @param opts? P4_Command_Login_Options P4 command options
--- @return P4_Command_Login P4_Command_Opened A new current P4 client
function P4_Command_Login:new(opts)
  opts = opts or {}

  log.trace("P4_Command_Login: new")

  local command = {
    "p4",
    "-Mj",
    "-ztag",
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

  if not opts.check then
    assert(opts.password, "Password is required for P4 login command")

    new.sys_opts["stdin"] = opts.password
  end

  return new
end

--- Runs the P4 command.
---
--- @return P4_Command_Login_Result Result Indicates if the function was successful.
--- @async
function P4_Command_Login:run()

  local success, _ = pcall(P4_Command.run(self).wait)

  if success then
    notify("Login success")
  else
    notify("Login failed")
  end

  return success
end

return P4_Command_Login
