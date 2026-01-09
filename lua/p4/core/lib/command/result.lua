local log = require("p4.log")

---@class P4_Command_Result
---@field tables table[] Decoded JSON tables
local P4_Command_Result = {}

P4_Command_Result.__index = P4_Command_Result

--- Wrapper function to check if a table is an instance of this class.
function P4_Command_Result:_check_instance()
  assert(P4_Command_Result.is_instance(self) == true, "Not a P4 command result class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_Command_Result:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_Command_Result then
      return true
    end
  end

  return false
end

--- Creates a new P4 command result.
---
--- @param sc vim.SystemCompleted Command result.
--- @return P4_Command_Result P4_Command_Result A new P4 command result
function P4_Command_Result:new(sc)

  log.trace("P4_Command_Result: new")

  local new = setmetatable({}, P4_Command_Result)

  -- Output may contain multiple JSON entries separated by newlines.
  local json_output_list = vim.split(sc.stdout, "\n", {trimempty = true})

  -- For each entry we need to convert the JSON entry to a lua table for processing.
  for _,  json_output in ipairs(json_output_list) do

    local t = vim.json.decode(json_output)

    table.insert(new.tables, t)
  end

  return new
end

return P4_Command_Result
