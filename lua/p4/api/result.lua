local log = require("p4.log")

---@alias P4_API_Result_Code integer

P4_RESULT_CODE_SUCCESS = 0
P4_RESULT_CODE_INTERNAL = 1
P4_RESULT_CODE_COMMAND_FAILED = 2
P4_RESULT_CODE_COMMAND_RESULT_PARSING_FAILED = 3
P4_RESULT_CODE_UNLIKELY = 4
P4_RESULT_CODE_FILE_NOT_IN_DEPOT = 5

---@enum P4_API_Result_Codes
local codes = {
  P4_RESULT_CODE_SUCCESS,
  P4_RESULT_CODE_INTERNAL,
  P4_RESULT_CODE_COMMAND_FAILED,
  P4_RESULT_CODE_COMMAND_RESULT_PARSING_FAILED,
  P4_RESULT_CODE_UNLIKELY,
  P4_RESULT_CODE_FILE_NOT_IN_DEPOT,
}

local code_strings = {
  "Success",
  "Internal",
  "Command failed",
  "Command result parsing failed",
  "Unlikely",
  "One or more file's are not in the depot",
}

--- @alias P4_Result P4_API_Success | P4_API_Error

--- @class P4_API_Result
--- @field protected code P4_API_Result_Code Result code.
local P4_API_Result = {
  code = P4_RESULT_CODE_UNLIKELY,
}

P4_API_Result.__index = P4_API_Result

--- Wrapper function to check if a table is an instance of this class.
function P4_API_Result:_check_instance()
  assert(P4_API_Result.is_instance(self) == true, "Not a class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_API_Result:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object.__index == P4_API_Result then
      return true
    end
  end

  return false
end

--- Creates a new P4 API result.
---
--- @param code P4_API_Result_Code Result code
--- @return P4_API_Result instance new instance.
---
--- @async
--- @nodiscard
function P4_API_Result:new(code)
  local new = setmetatable({}, P4_API_Result)

  -- Lua tables indexes from 1.
  assert(codes[code + 1] == code, "Unsupported result code")

  new.code = code

  return new
end

--- Returns the result code as a string.
---
--- @return P4_API_Result_Code code Result code.
function P4_API_Result:get_code()
  self:_check_instance()

  return self.code
end

--- Returns the result code as a string.
---
--- @return string string Code as a string.
function P4_API_Result:code_to_string()
  self:_check_instance()

  return code_strings[self.code + 1]
end

--- Logs the result.
function P4_API_Result:log()
  self:_check_instance()

  if self.code == P4_RESULT_CODE_SUCCESS then
    log.fmt_debug("Result: " .. self:code_to_string())
  else
    log.fmt_error("Result: " .. self:code_to_string())
  end
end

--- Prints the result.
function P4_API_Result:print()
  self:_check_instance()

  vim.print("Result: " .. self:code_to_string())
end

return P4_API_Result
