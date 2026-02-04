local result = require("p4.api.result")

--- @class P4_API_Success : P4_API_Result
local P4_API_Success = {}

P4_API_Success.__index = P4_API_Success

setmetatable(P4_API_Success, result)

--- Wrapper function to check if a table is an instance of this class.
function P4_API_Success:_check_instance()
  assert(P4_API_Success.is_instance(self) == true, "Not a class instance")
end

--- Creates a new success result
---
--- @return P4_API_Success instance New class instance.
---
--- @nodiscard
function P4_API_Success:new()

  local new = result:new(P4_RESULT_CODE_SUCCESS)

  ---@cast new P4_API_Success

  setmetatable(new, result)

  return new
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_API_Success:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object and object.__index == P4_API_Success then
      return true
    end
  end

  return false
end

return P4_API_Success
