local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")
local task = require("p4.task")

local p4_log = require("p4.core.log")
local p4_env = require("p4.core.env")

--- @class P4_Command_Common_Result_Success : table<string, any>

--- @class P4_Command_Common_Result_Error
--- @field error P4_Command_Result_Error Hold's the error information.

--- @class P4_Command_Common_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Common_Result_Success | P4_Command_Common_Result_Error Hold's information about the result.

---@class P4_Command : table
---@field protected global_opts P4_Command_Global_Options
---@field protected command string[] P4 command.
---@field protected name string
---@field protected sys_opts vim.SystemOpts Vim system options.
local P4_Command = {}

P4_Command.__index = P4_Command

--- Logs information for a command success.
---
--- @param sc vim.SystemCompleted
--- @param command_name string
--- @param start_time integer
---
--- @async
local function log_command_success(sc, command_name, start_time)
  log.fmt_debug("Command %s: success", command_name)
  log.debug("Command elasped time: ", (vim.uv.hrtime() - start_time) / 1e6 .. " ms")

  p4_log.output(sc.stdout)
end

--- Logs information for a command failure.
---
--- @param sc vim.SystemCompleted
--- @param command_name string
--- @param start_time integer
---
--- @async
local function log_command_failed(sc, command_name, start_time)
  log.fmt_error("Command %s: failed. See `:P4 output` for more info", command_name)
  log.debug("Command elasped time: ", (vim.uv.hrtime() - start_time) / 1e6 .. " ms")

  p4_log.error(sc.stderr)

  notify("Command " .. command_name .. " failed. See `:P4 output` for more info", vim.log.levels.ERROR)
end

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command:_check_instance()
  assert(P4_Command.is_instance(self) == true, "Not a class instance")
end

--- Logs information for a formatted command.
---
--- @param start_time integer
---
--- @async
function P4_Command:_log_command_send(start_time)
  log.fmt_debug("Command %s: sent", start_time)
  log.debug("Command elasped time: ", (vim.uv.hrtime() - start_time) / 1e6 .. " ms")

  p4_log.command(self.command)
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Command result.
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Common_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command:_process_response(sc)
  log.trace("P4_Command (_process_response): Enter")

  local P4_Command_Result = require("p4.core.lib.command.result")

  --- Decode JSON output into lua tables
  --- @type P4_Command_Common_Result[]
  local results = {}

  ---@type P4_Command_Result
  local parsed_output = P4_Command_Result:new(sc)

  for _, t in ipairs(parsed_output.tables) do

    local error = false

    for key, _ in pairs(t) do
      if key:find("generic", 1, true) or
        key:find("severity", 1, true)then

        error = true

        local P4_Command_Result_Error = require("p4.core.lib.command.result_error")

        ---@type P4_Command_Common_Result_Error
        local new_error_result = {
          error = P4_Command_Result_Error:new(t)
        }

        ---@type P4_Command_Common_Result
        local new_result = {
          success = false,
          data = new_error_result
        }

        table.insert(results, new_result)
        break
      end
    end

    if not error then

        ---@type P4_Command_Common_Result
        local new_result = {
          success = true,
          data = t
        }

      table.insert(results, new_result)
    end
  end

  return true, results
end

--- Logs information for a command failure.
---
--- @param sc vim.SystemCompleted
--- @param start_time integer
--- @return vim.SystemCompleted sc
---
--- @package
--- @async
function P4_Command:_handle_login_failure(sc, start_time)

  log.trace("P4_Command: _handle_login_failure): Enter")

  local success, results = P4_Command._process_response(self, sc)

  --- @cast results P4_Command_Common_Result[]

  if success then

    assert(#results, "Unexpected number of results")

    if not results[1].success then

      if results[1].data.error:is_not_logged_in() then

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
        success, _ = P4_Command_Login:new(cmd_opts):run()

        -- Re-run the previous command.
        if success then

          log.debug("Re-trying previous command.")

          -- Reset start time.
          start_time = vim.uv.hrtime()

          sc = vim.system(self.command, self.sys_opts):wait()

          if sc.code == 0 then
            log_command_success(sc, self.name, start_time)
          else
            log_command_failed(sc, self.name, start_time)
          end
        end
      else
        log_command_failed(sc, self.name, start_time)
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

--- @class P4_Command_Global_Options
--- @field json boolean? Outputs json tagged output.
--- @field quiet boolean? Supresses informational messages and prints only warnings/errors.
--- @field user string? Run command under the specified user
--- @field client string? Run command under the specified client
local P4_Command_Global_Options = {
  json = true,
  quiet = false,
  user = nil,
  client = nil,
}

--- @class P4_Command_New
--- @field command string[]
--- @field name string
--- @field global_opts P4_Command_Global_Options?

--- Creates a new P4 command.
---
--- @param info P4_Command_New New P4 command.
--- @return P4_Command P4_Command A new P4 command
function P4_Command:new(info)
  log.trace("P4_Command: new")

  local new = setmetatable({}, P4_Command)

  new.command = {"p4"}
  new.name = info.name
  new.global_opts = vim.tbl_deep_extend("keep", info.global_opts or {}, P4_Command_Global_Options)

  if new.global_opts.json then
    vim.list_extend(new.command, {"-Mj", "-ztag"})
  end

  if new.global_opts.quiet then
    vim.list_extend(new.command, {"-q"})
  end

  if new.global_opts.user and new.global_opts.user:len() > 0 then
    vim.list_extend(new.command, {"-user " .. new.global_opts.user})
  end

  if new.global_opts.client and new.global_opts.client:len() > 0 then
    vim.list_extend(new.command, {"-client " .. new.global_opts.client})
  end

  vim.list_extend(new.command, info.command)

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
function P4_Command:get_command()
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

  if p4_env.check() then

    nio.run(function()

      local start_time = vim.uv.hrtime()

      self:_log_command_send(start_time)

      local sc = vim.system(self.command, self.sys_opts):wait()

      log.fmt_debug("System Complete: %s", sc)

      if sc.code == 0 then
        log_command_success(sc, self.name, start_time)
      else
        -- Make sure we do not infinitely loop if user fails to enter the correct password.
        local P4_Command_Login = require("p4.core.lib.command.login")

        if not P4_Command_Login.is_instance(self) then

          -- Try to login and then re-run the current command. This will override the current result.
          sc = self:_handle_login_failure(sc, start_time)

          log.fmt_debug("System Complete: %s", sc)
        else
          log_command_failed(sc, self.name, start_time)
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
