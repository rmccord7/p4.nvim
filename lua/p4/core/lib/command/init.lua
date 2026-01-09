local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")
local task = require("p4.task")

local p4_log = require("p4.core.log")
local p4_env = require("p4.core.env")

---@class P4_Command : table
---@field protected command string[] P4 command.
---@field protected sys_opts vim.SystemOpts Vim system options.
local P4_Command = {}

P4_Command.__index = P4_Command

--- Creates a new P4 command.
---
--- @param command string[] P4 command
--- @return P4_Command P4_Command A new P4 command
function P4_Command:new(command)

  log.trace("P4_Command: new")

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

--- Logs information for a command success.
---
--- @param result vim.SystemCompleted
--- @param command string
--- @param start_time integer
---
--- @async
local function log_command_success(result, command, start_time)
  log.fmt_debug("Command %s: success", command)
  log.debug("Command elasped time: ", (vim.uv.hrtime() - start_time) / 1e6 .. " ms")

  p4_log.output(result.stdout)
end

--- Logs information for a command failure.
---
--- @param result vim.SystemCompleted
--- @param command string
--- @param start_time integer
---
--- @async
local function log_command_failed(result, command, start_time)
  log.fmt_error("Command %s: failed. See `:P4 output` for more info", command)
  log.debug("Command elasped time: ", (vim.uv.hrtime() - start_time) / 1e6 .. " ms")

  p4_log.error(result.stderr)

  notify("Command " .. command .. " failed. See `:P4 output` for more info", vim.log.levels.ERROR)
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Command result.
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Result result Hold's the parsed result from the command output.
function P4_Command:_process_response(sc)
  log.trace("P4_Command (_process_response): Enter")

  local P4_Command_Result = require("p4.core.lib.command.result")

  ---@type P4_Command_Result
  local result = P4_Command_Result:new(sc)

  return true, result
end

--- Logs information for a command failure.
---
--- @param result vim.SystemCompleted
--- @param command string
--- @param start_time integer
--- @return vim.SystemCompleted result
---
--- @async
function P4_Command:_handle_login_failure(result, command, start_time)

  -- If we failed because we are not logged in.
  if string.find(result.stderr, "Your session has expired, please login again.", 1, true) or
    string.find(result.stderr, "Perforce password (P4PASSWD) invalid or unset.", 1, true) then

    log.debug("Not logged into P4 server.")

    -- Get user password
    nio.fn.inputsave()
    local password = nio.fn.inputsecret("Password: ")
    nio.fn.inputrestore()

    --- @type P4_Command_Login_Options
    local cmd_opts = {
      password = password,
    }

    local P4_Command_Login = require("p4.core.lib.command.login")

    -- Login to the P4 server.
    local cmd = P4_Command_Login:new(cmd_opts)

    local success = cmd:run()

    -- Re-run the previous command.
    if success then

      log.debug("Re-trying previous command.")

      -- Reset start time.
      start_time = vim.uv.hrtime()

      result = vim.system(self.command, self.sys_opts):wait()

      if result.code == 0 then

        log_command_success(result, command, start_time)
      else
        log_command_failed(result, command, start_time)
      end
    end
  else
    log_command_failed(result, command, start_time)
  end

  -- If we re-ran the command, then the previous result has changed.
  return result
end

--- Runs the P4 command asynchronously.
---
--- @return nio.control.Future future Future to wait on.
--- @see vim.system
--- @async
function P4_Command:run()

  log.trace("P4_Command: run")

  local future = nio.control.future()

  local start_time = vim.uv.hrtime()

  if p4_env.check() then

    nio.run(function()

      p4_log.command(self.command)

      local result = vim.system(self.command, self.sys_opts):wait()

      -- Actual command string is fourth element.
      local command = self.command[4]

      if result.code == 0 then
        log_command_success(result, command, start_time)
      else
        local P4_Command_Login = require("p4.core.lib.command.login")

        -- Make sure we do not infinitely loop if user fails to enter the correct password.
        if getmetatable(self) ~= P4_Command_Login then

          -- Try to login and then re-run the current command.
          result = self:_handle_login_failure(result, command, start_time)
        else
          log_command_failed(result, command, start_time)
        end

        if result.code == 0 then
          future.set(result)
        else
          future.set_error()
        end
      end
    end, function(success, ...)
      task.complete(nil, success, ...)
    end)
  else
    future.set_error()
  end

  return future
end

return P4_Command
