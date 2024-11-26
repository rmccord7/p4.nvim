local log = require("p4.log")
local notify = require("p4.notify")

local p4_log = require("p4.core.log")

---@class P4_Command : table
---@field protected command string[] P4 command.
---@field protected sys_opts vim.SystemOpts P4 command
local P4_Command = {}

--- Creates a new P4 command.
---
--- @param command string[] P4 command
--- @return P4_Command P4_Command A new P4 command
function P4_Command:new(command)

  P4_Command.__index = P4_Command

  local new = setmetatable({}, P4_Command)

  new.command = command

  new.sys_opts = {
    detach = false,
    text = true,
  }

  return new
end

--- Runs the P4 command asynchronously.
---
--- @return nio.control.Future future Future to wait on.
--- @see vim.system
--- @async
function P4_Command:run()

  local nio = require("nio")
  local future = nio.control.future()

  --- @param sc vim.SystemCompleted
  local on_exit = function(sc)
    if sc.code == 0 then

      log.debug("Command success")
      p4_log.output(sc.stdout)

      future.set(sc)
    else
      local P4_Command_Login = require("p4.core.lib.command.login")

      -- Make sure we do not infinitely loop if user fails to enter the correct password.
      if getmetatable(self) ~= P4_Command_Login:new() then

        -- If we failed because we are not logged in.
        if string.find(sc.stderr, "Your session has expired, please login again.", 1, true) or
          string.find(sc.stderr, "Perforce password (P4PASSWD) invalid or unset.", 1, true) then

          log.debug("Command failed: Not logged in")

          nio.run(function()

            -- Get user password
            nio.fn.inputsave()
            local password = nio.fn.inputsecret("Password: ")
            nio.fn.inputrestore()

            require("p4.core.lib.command.login")

            -- Login to the P4 server.
            local cmd = P4_Command_Login:new()

            cmd.sys_opts["stdin"] = password

            local success, _ = pcall(cmd:run():wait())

            -- Re-run the previous command.
            if success then

              log.debug("Re-try previous command")

              self:run()
            end
          end)
        end
      else
        log.error("P4 command failed. See `:P4CLog` for more info")
        p4_log.error(sc.stderr)
        notify("P4 command failed. See `:P4CLog` for more info", vim.log.levels.ERROR)

        future.set_error(sc)
      end
    end
  end

  p4_log.command(self.command)

  local ok, err = pcall(vim.system, self.command, self.sys_opts, on_exit)

  if not ok then

    ---@type vim.SystemCompleted
    local sc = {
      code = 99999,
      signal = 0,
      stderr = "Failed to invoke p4: " .. err,
    }

    on_exit(sc)
  end

  return future
end

--- Runs the P4 command synchronously.
---
--- @return vim.SystemCompleted Vim system complete object.
--- @see vim.system
function P4_Command:wait()
  p4_log.command(self.command)

  local sc = vim.system(self.command, self.sys_opts):wait()

  --- @cast sc vim.SystemCompleted

  if sc.code == 0 then
    self.output = sc.stdout

    p4_log.output(sc.stdout)
  else
    local P4_Command_Login = require("p4.core.lib.command.login")

    -- Make sure we do not infinitely loop if user fails to enter the correct password.
    if getmetatable(self) ~= P4_Command_Login:new() then

      -- If we failed because we are not logged in.
      if string.find(sc.stderr, "Your session has expired, please login again.", 1, true) or
        string.find(sc.stderr, "Perforce password (P4PASSWD) invalid or unset.", 1, true) then

          -- Get user password
          vim.fn.inputsave()
          local password = vim.fn.inputsecret("Password: ")
          vim.fn.inputrestore()

          require("p4.core.lib.command.login")

          -- Login to the P4 server.
          local cmd = P4_Command_Login:new()

          -- Update vim system options.
          cmd.sys_opts["stdin"] = password

          sc = cmd:wait()

          -- Login was successful so re-run the previous command.
          if sc.code == 0 then

            sc = self:wait()

          else
            log.error("P4 command failed. See `:P4CLog` for more info")
            p4_log.error(sc.stderr)
            notify("P4 command failed. See `:P4CLog` for more info", vim.log.levels.ERROR)
          end
      end
    else
      log.error("P4 command failed. See `:P4CLog` for more info")
      p4_log.error(sc.stderr)
      notify("P4 command failed. See `:P4CLog` for more info", vim.log.levels.ERROR)
    end
  end

  return sc
end

return P4_Command
