local log = require("p4.log")

--- @class P4_Revision : table
--- @field number string Revision number
--- @field cl P4_CL P4 CL
--- @field action string Action
--- @field date string Date
local P4_Revision = {}

P4_Revision.__index = P4_Revision

----TODO:  Do we need this enum below?

--- @enum P4_Revision_Action_Enum
P4_Revision.action_type = {
  ADD = 0,
  EDIT = 1,
  DELETE = 2,
  BRANCH = 3,
  IMPORT = 4,
  INTEGRATE = 5,
}

--- @class P4_New_Revision_Information
--- @field revision string Revision revision
--- @field cl P4_CL P4 CL info
--- @field action string Action
--- @field date string Date

--- Creates a new P4 revision.
---
--- @param new_revision_info P4_New_Revision_Information
--- @return P4_Revision revision New revisionL
--- @nodiscard
function P4_Revision:new(new_revision_info)

  log.trace("P4_Revision: new")

  local new = setmetatable({}, P4_Revision)

  new.number = new_revision_info.revision
  new.cl = new_revision_info.cl
  new.action = new_revision_info.action
  new.date = new_revision_info.date

  return new
end

-- --- Returns the action as a string.
-- ---
-- --- @return string action P4 action
-- --- @nodiscard
-- function P4_Revision:get_action_string()
--   if self.action == P4_Revision.action_type.ADD then
--     return "Add"
--   elseif self.action == P4_Revision.action_type.EDIT then
--     return "Edit"
--   elseif self.action == P4_Revision.action_type.DELETE then
--     return "Delete"
--   elseif self.action == P4_Revision.action_type.BRANCH then
--     return "Branch"
--   elseif self.action == P4_Revision.action_type.IMPORT then
--     return "Import"
--   else
--     return "Integrate"
--   end
-- end

return P4_Revision
