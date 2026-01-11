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

--- Logs information for a command success.
---
--- @param sc vim.SystemCompleted
--- @param command string
--- @param start_time integer
---
--- @async
local function log_command_success(sc, command, start_time)
  log.fmt_debug("Command %s: success", command)
  log.debug("Command elasped time: ", (vim.uv.hrtime() - start_time) / 1e6 .. " ms")

  p4_log.output(sc.stdout)
end

--- Logs information for a command failure.
---
--- @param sc vim.SystemCompleted
--- @param command string
--- @param start_time integer
---
--- @async
local function log_command_failed(sc, command, start_time)
  log.fmt_error("Command %s: failed. See `:P4 output` for more info", command)
  log.debug("Command elasped time: ", (vim.uv.hrtime() - start_time) / 1e6 .. " ms")

  p4_log.error(sc.stderr)

  notify("Command " .. command .. " failed. See `:P4 output` for more info", vim.log.levels.ERROR)
end

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command:_check_instance()
  assert(P4_Command.is_instance(self) == true, "Not a class instance")
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
--- @param sc vim.SystemCompleted
--- @param command string
--- @param start_time integer
--- @return vim.SystemCompleted sc
---
--- @package
--- @async
function P4_Command:_handle_login_failure(sc, command, start_time)

  log.trace("P4_Command: *_handle_login_failure): Enter")

  ---@type P4_Command_Result_Error[]
  local results = {}

  local success, parsed_output = P4_Command._process_response(self, sc)

  if success then

    assert(#parsed_output.tables >= 1)

    for _, t in ipairs(parsed_output.tables) do

      -- First table should have the login error and we don't need to parse any more json tables from the output.
      for key, _ in pairs(t) do
        if key:find("generic", 1, true) or
          key:find("severity", 1, true)then

          local P4_Command_Result_Error = require("p4.core.lib.command.result_error")
          P4_Command_Result_Error:new(t)
          break
        end
      end
    end

    if not vim.tbl_isempty(results) then

      if results[1]:is_not_logged_in() then

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

        success, result = cmd:run()

        -- Re-run the previous command.
        if success then

          log.debug("Re-trying previous command.")

          -- Reset start time.
          start_time = vim.uv.hrtime()

          sc = vim.system(self.command, self.sys_opts):wait()

          if sc.code == 0 then
            log_command_success(sc, command, start_time)
          else
            log_command_failed(sc, command, start_time)
          end
        end
      else
        log_command_failed(sc, command, start_time)
      end
    end
  end

  -- If we re-ran the command, then the previous result has changed.
  return sc
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_Command:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object.__index == P4_Command then
      return true
    end
  end

  return false
end

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

--TODO: Does need to be removed

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
  self:_check_instance()

  log.trace("P4_Command: run")

  local future = nio.control.future()

  local start_time = vim.uv.hrtime()

  if p4_env.check() then

    -- Actual command string is fourth element.
    local command = self.command[4]

    nio.run(function()

      local sc = vim.system(self.command, self.sys_opts):wait()

      log.fmt_debug("System Complete: %s", sc)

      if sc.code == 0 then
        log_command_success(sc, command, start_time)
      else
        -- Make sure we do not infinitely loop if user fails to enter the correct password.
        local P4_Command_Login = require("p4.core.lib.command.login")

        if not P4_Command_Login.is_instance(self) then

          -- Try to login and then re-run the current command. This will override the current result.
          sc = self:_handle_login_failure(sc, command, start_time)

          log.fmt_debug("System Complete: %s", sc)
        else
          log_command_failed(sc, command, start_time)
        end
      end

      if sc.code == 0 then
        future.set(sc)
      else
        future.set_error(sc)
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
