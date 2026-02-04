--- @class P4_Path
local P4_Path = {}

P4_Path.__index = P4_Path

--- Wrapper function to check if a table is an instance of this class.
function P4_Path:_check_instance()
  assert(P4_Path.is_instance(self) == true, "Not a class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a P4 file list instance.
---
--- @nodiscard
function P4_Path:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object and object.__index == P4_Path then
      return true
    end
  end

  return false
end

--- Creates a new P4 file.
---
--- @return P4_Path P4_Path A new P4 file.
---
--- @nodiscard
function P4_Path:new()
  return setmetatable({}, P4_Path)
end

return P4_Path

