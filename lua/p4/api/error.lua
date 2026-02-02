local log = require("p4.log")
local notify = require("p4.notify")

local result = require("p4.api.result")

--- @class P4_API_Command_Error
--- @field name string Name of the command that failed.
--- @field command string[] The command that failed.
--- @field results P4_Command_Result_Error[] List of results.

--- @class P4_API_Error : P4_API_Result
--- @field data P4_API_Command_Error? Union of data based on the error code.
local P4_API_Error = {}

P4_API_Error.__index = P4_API_Error

setmetatable(P4_API_Error, result)

--- Wrapper function to check if a table is an instance of this class.
function P4_API_Error:_check_instance()
  assert(P4_API_Error.is_instance(self) == true, "Not a class instance")
end

--- Creates a new success result
---
--- @param code P4_API_Result_Code Result code
--- @param data P4_API_Command_Error? Union of data based on the error code.
---
--- @return P4_API_Error instance New class instance.
---
--- @nodiscard
function P4_API_Error:new(code, data)

  assert(code ~= P4_RESULT_CODE_SUCCESS, "Success result code cannot be used")

  local new = result:new(code)

  --- @cast new P4_API_Error
  setmetatable(new, P4_API_Error)

  if data then
    self.data = data
  end

  return new
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_API_Error:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object.__index == P4_API_Error then
      return true
    end
  end

  return false
end

--- Logs the result.
function P4_API_Error:log(_trace)
  self:_check_instance()

  if self.code == P4_RESULT_CODE_COMMAND_FAILED then
    local t = {
      code = self:code_to_string(),
      command = {
        name = self.data.name,
        string = vim.fn.join(self.data.command, " "),
      },
      self.data.results,
    }

    if _trace then
      t.trace = debug.traceback(3)
    end

    log.fmt_error("Error: %s", t)
  else
    log.fmt_error("Error: " .. self:code_to_string())
  end
end

--- Prints the result.
function P4_API_Error:print()
  self:_check_instance()

  if self.code == P4_RESULT_CODE_COMMAND_FAILED then

    local t = {
      code = self:code_to_string(),
      command = {
        name = self.data.name,
        string = vim.fn.join(self.data.command, " "),
      },
      self.data.results,
    }

    vim.print("Error: %s", t)
  else
    vim.print("Error: " .. self:code_to_string())
  end
end

--- Notify the result
function P4_API_Error:notify()
  self:_check_instance()

  notify(self:code_to_string())
end

return P4_API_Error
