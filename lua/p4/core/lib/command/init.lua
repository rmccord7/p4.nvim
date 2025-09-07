local log = require("p4.log")
local notify = require("p4.notify")
local task = require("p4.task")

local p4_log = require("p4.core.log")

---@class P4_Command : table
---@field protected command string[] P4 command.
---@field protected sys_opts vim.SystemOpts Vim system options.
local P4_Command = {}

--- Creates a new P4 command.
---
--- @param command string[] P4 command
--- @return P4_Command P4_Command A new P4 command
function P4_Command:new(command)

  log.trace("P4_Command: new")

  P4_Command.__index = P4_Command

  local new = setmetatable({}, P4_Command)

  new.command = command

  new.sys_opts = {
    detach = false,
    text = true,
  }

  return new
end

--- Gets the command.
---
--- @return string[] command P4 command
function P4_Command:get()
  return self.command
end

--- Runs the P4 command asynchronously.
---
--- @return nio.control.Future future Future to wait on.
--- @see vim.system
--- @async
function P4_Command:run()

  log.trace("P4_Command: run")

  local nio = require("nio")
  local future = nio.control.future()

  local start_time = vim.uv.hrtime()

  nio.run(function()
    p4_log.command(self.command)

    local result = vim.system(self.command, self.sys_opts):wait()

    if result.code == 0 then

      log.debug("Command success")
      log.debug("Command elasped time: ", (vim.uv.hrtime() - start_time) / 1e6 .. " ms")
      p4_log.output(result.stdout)

      future.set(result)
    else
      local P4_Command_Login = require("p4.core.lib.command.login")

      -- Make sure we do not infinitely loop if user fails to enter the correct password.
      if getmetatable(self) ~= P4_Command_Login then

        -- If we failed because we are not logged in.
        if string.find(result.stderr, "Your session has expired, please login again.", 1, true) or
          string.find(result.stderr, "Perforce password (P4PASSWD) invalid or unset.", 1, true) then

          log.debug("Command failed: Not logged in")

          -- Get user password
          nio.fn.inputsave()
          local password = nio.fn.inputsecret("Password: ")
          nio.fn.inputrestore()

          --- @type P4_Command_Login_Options
          local cmd_opts = {
            password = password,
          }

          -- Login to the P4 server.
          local cmd = P4_Command_Login:new(cmd_opts)

          local success, _ = pcall(cmd:run().wait)

          -- Re-run the previous command.
          if success then

            log.trace("Re-trying previous command")

            success, result = pcall(self:run().wait)

            if success then
              log.debug("Command success")
              p4_log.output(result.stdout)

              future.set(result)
            end
          end
        end
      else
        log.error("P4 command failed. See `:P4CLog` for more info")
        p4_log.error(result.stderr)
        notify("P4 command failed. See `:P4CLog` for more info", vim.log.levels.ERROR)

        future.set_error(result)
      end
    end
  end, function(success, ...)
        task.complete(nil, success, ...)
  end)

  return future
end

return P4_Command
