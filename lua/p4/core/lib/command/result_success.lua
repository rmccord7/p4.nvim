---@alias P4_JSON_Success_Table table<string, any>

---@class P4_Command_Result_Success
local P4_Command_Result_Success = {}

P4_Command_Result_Success.__index = P4_Command_Result_Success

--- Wrapper function to check if a table is an instance of this class.
function P4_Command_Result_Success:_check_instance()
  assert(P4_Command_Result_Success.is_instance(self) == true, "Not a P4 command result success class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_Command_Result_Success:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_Command_Result_Success then
      return true
    end
  end

  return false
end

--- Creates a new P4 command error result.
---
--- @param table P4_JSON_Success_Table
--- @return P4_Command_Result_Success P4_Command_Result_Success A new P4 command result
function P4_Command_Result_Success:new(table)

  local new = setmetatable(table, P4_Command_Result_Success)

  ---@cast new P4_Command_Result_Success
  return new
end

return P4_Command_Result_Success
